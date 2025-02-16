//
//  BloomEffect.metal
//  redline
//
//  Created by Yang Gao on 2/16/25.
//

#include <metal_stdlib>
using namespace metal;

// Vertex shader output
struct VertexOut {
    float4 position [[position]];
    float2 texCoords;
};

// Brightness threshold for bloom
constant float brightnessThreshold = 0.4;

// Gaussian blur weights
constant float weights[5] = { 0.4, 0.25, 0.15, 0.10, 0.05 };

// Fragment shader for extracting bright areas
fragment float4 extractBrightAreas(VertexOut in [[stage_in]],
                                    texture2d<float> inputTexture [[texture(0)]]) {
    constexpr sampler textureSampler(mag_filter::linear, min_filter::linear);
    float3 color = inputTexture.sample(textureSampler, in.texCoords).rgb;
    
    // Extract bright areas
    float brightness = dot(color, float3(0.2126, 0.7152, 0.0722));
    if (brightness > brightnessThreshold) {
        return float4(color, 1.0);
    } else {
        return float4(0.0);
    }
}

// Fragment shader for applying Gaussian blur
fragment float4 applyBlur(VertexOut in [[stage_in]],
                         texture2d<float> inputTexture [[texture(0)]],
                         constant bool& horizontal [[buffer(0)]]) {  // Changed from bool to uint
    constexpr sampler textureSampler(mag_filter::linear, min_filter::linear);
    float2 texOffset = 1.0 / float2(inputTexture.get_width(), inputTexture.get_height());
    float3 result = inputTexture.sample(textureSampler, in.texCoords).rgb * weights[0];
    
    if (horizontal != 0) {  // Modified condition to check for non-zero
        for (int i = 1; i < 5; ++i) {
            result += inputTexture.sample(textureSampler, in.texCoords + float2(texOffset.x * i, 0.0)).rgb * weights[i];
            result += inputTexture.sample(textureSampler, in.texCoords - float2(texOffset.x * i, 0.0)).rgb * weights[i];
        }
    } else {
        for (int i = 1; i < 5; ++i) {
            result += inputTexture.sample(textureSampler, in.texCoords + float2(0.0, texOffset.y * i)).rgb * weights[i];
            result += inputTexture.sample(textureSampler, in.texCoords - float2(0.0, texOffset.y * i)).rgb * weights[i];
        }
    }
    
    return float4(result, 1.0);
}

// Fragment shader for combining the original scene with the blurred bright areas
fragment float4 combineBloom(VertexOut in [[stage_in]],
                             texture2d<float> sceneTexture [[texture(0)]],
                             texture2d<float> bloomTexture [[texture(1)]]) {
    constexpr sampler textureSampler(mag_filter::linear, min_filter::linear);
    float3 sceneColor = sceneTexture.sample(textureSampler, in.texCoords).rgb;
    float3 bloomColor = bloomTexture.sample(textureSampler, in.texCoords).rgb;
    
    float bloomIntensity = 4.0;  // Increase this value for stronger bloom
    return float4(sceneColor + (bloomColor * bloomIntensity), 1.0);
}
