import SwiftUI
import SceneKit

// First, create a class to manage the model view state
struct SimpleModelViewer: UIViewRepresentable {
    let modelName: String
    let value: Int
    @Binding var errorMessage: String
    @Binding var showError: Bool
    @ObservedObject var viewerState: ModelViewerState
    
    func makeUIView(context: Context) -> SCNView {
        let sceneView = SCNView()
        let scene = SCNScene()
        
        // Set the sceneView in the next runloop to avoid SwiftUI warning
        DispatchQueue.main.async {
            viewerState.sceneView = sceneView
        }
        
        // Basic setup
        //sceneView.allowsCameraControl = true
        sceneView.backgroundColor = .black
        
        // Create main directional light with increased intensity
        let mainLight = SCNNode()
        mainLight.light = SCNLight()
        mainLight.light?.type = .directional
        mainLight.light?.intensity = 400000
        mainLight.light?.orthographicScale = 50
        
        // Calculate color based on value with increased saturation
        let normalizedValue = CGFloat(max(0, min(100, value))) / 100.0
        let red = normalizedValue
        let blue = 1.0 - normalizedValue
        let lightColor = UIColor(red: red, green: 0, blue: blue, alpha: 1.0)
        mainLight.light?.color = lightColor
        
        // Position the main light
        mainLight.position = SCNVector3(x: 0, y: 200, z: 10)
        mainLight.eulerAngles = SCNVector3(x: -Float.pi/4, y: 0, z: 0)
        scene.rootNode.addChildNode(mainLight)
        
        // Rest of the lighting setup remains the same...
        
        // Load the USDZ model
        if let modelURL = Bundle.main.url(forResource: modelName, withExtension: "usdz") {
            do {
                let modelScene = try SCNScene(url: modelURL, options: [:])
                scene.rootNode.addChildNode(modelScene.rootNode)
            } catch {
                print("Error loading model: \(error)")
                DispatchQueue.main.async {
                    self.errorMessage = "Error loading model: \(error.localizedDescription)"
                    self.showError = true
                }
            }
        }
        
        sceneView.scene = scene
        return sceneView
    }
    
    func updateUIView(_ uiView: SCNView, context: Context) {
        // Update logic remains the same...
    }
}
