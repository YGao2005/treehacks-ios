import TerraiOS
import SwiftUI
import SceneKit
import RealityKit
import Metal

class AppState: ObservableObject {
    @Published var terra: TerraManager?
    @Published var isInitialized = false
    
    func initializeTerra() {
        Terra.instance(devId: "4actk-temp-testing-p3OyGGA8Z7", referenceId: "USER_REF_ID") { [weak self] manager, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("Terra initialization failed: \(error)")
                    return
                }
                self?.terra = manager
                self?.isInitialized = true
            }
        }
    }
}

struct SimpleModelViewer: UIViewRepresentable {
    let modelName: String
    let value: Int  // Value from 0 to 100
    @Binding var errorMessage: String
    @Binding var showError: Bool
    
    func makeUIView(context: Context) -> SCNView {
        let sceneView = SCNView()
        let scene = SCNScene()
        
        // Basic setup
        //sceneView.allowsCameraControl = true
        sceneView.backgroundColor = .black
        
        // Create main directional light
        let mainLight = SCNNode()
        mainLight.light = SCNLight()
        mainLight.light?.type = .directional
        mainLight.light?.intensity = 6000
        mainLight.light?.orthographicScale = 30  // Wider light spread
        
        // Calculate color based on value (red to green)
        let normalizedValue = CGFloat(max(0, min(100, value))) / 100.0
        let red = 1.0 - normalizedValue
        let green = normalizedValue
        let lightColor = UIColor(red: red, green: green, blue: 0, alpha: 1.0)
        mainLight.light?.color = lightColor
        
        // Position the main light
        mainLight.position = SCNVector3(x: 0, y: 200, z: 10)
        mainLight.eulerAngles = SCNVector3(x: -Float.pi/4, y: 0, z: 0)
        scene.rootNode.addChildNode(mainLight)
        
        // Create secondary directional light
        let secondaryLight = SCNNode()
        secondaryLight.light = SCNLight()
        secondaryLight.light?.type = .directional
        secondaryLight.light?.intensity = 5500
        secondaryLight.light?.orthographicScale = 30
        secondaryLight.light?.color = lightColor
        
        // Position the secondary light from a different angle
        secondaryLight.position = SCNVector3(x: -10, y: 8, z: -5)
        secondaryLight.look(at: SCNVector3(0, 0, 0))  // Point towards center
        scene.rootNode.addChildNode(secondaryLight)
        
        // Add ambient light for base illumination
        let ambientLight = SCNNode()
        ambientLight.light = SCNLight()
        ambientLight.light?.type = .ambient
        ambientLight.light?.intensity = 1000  // Increased ambient light intensity
        scene.rootNode.addChildNode(ambientLight)
        
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
        // Update light color if needed
        // Update all directional lights
        let normalizedValue = CGFloat(max(0, min(100, value))) / 100.0
        let red = 1.0 - normalizedValue
        let green = normalizedValue
        let newColor = UIColor(red: red, green: green, blue: 0, alpha: 1.0)
        
        uiView.scene?.rootNode.childNodes.forEach { node in
            if node.light?.type == .directional {
                node.light?.color = newColor
            }
        }
    }
}

struct ContentView: View {
    let modelName: String
    @State private var value: Int = 50  // Default value
    @State private var showError = false
    @State private var errorMessage = ""
    
    var body: some View {
        VStack {
            SimpleModelViewer(modelName: modelName,
                            value: value,
                            errorMessage: $errorMessage,
                            showError: $showError)
                .edgesIgnoringSafeArea(.all)
            
            Slider(value: Binding(
                get: { Double(value) },
                set: { value = Int($0) }
            ), in: 0...100, step: 1)
            .padding()
            
            Text("Value: \(value)")
                .foregroundColor(.white)
                .padding(.bottom)
            
            if showError {
                VStack {
                    Text("Error Loading Model")
                        .font(.headline)
                        .foregroundColor(.red)
                    Text(errorMessage)
                        .font(.subheadline)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                        .padding()
                }
                .background(Color.black.opacity(0.7))
                .cornerRadius(10)
                .padding()
            }
        }
    }
}
