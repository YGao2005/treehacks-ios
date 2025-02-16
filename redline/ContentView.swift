import TerraiOS
import SwiftUI


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

import SceneKit
import RealityKit
import Metal


struct SimpleModelViewer: UIViewRepresentable {
    let modelName: String
    @Binding var errorMessage: String
    @Binding var showError: Bool
    
    func makeUIView(context: Context) -> SCNView {
        let sceneView = SCNView()
        
        // Create empty scene with basic lighting
        let scene = SCNScene()
        let ambientLight = SCNNode()
        ambientLight.light = SCNLight()
        ambientLight.light?.type = .ambient
        ambientLight.light?.intensity = 100
        scene.rootNode.addChildNode(ambientLight)
        
        // Debug logging for bundle path
        if let bundlePath = Bundle.main.resourcePath {
            print("Bundle resource path: \(bundlePath)")
        }
        
        // Debug logging for model file
        let fileManager = FileManager.default
        if let modelURL = Bundle.main.url(forResource: modelName, withExtension: "usdz") {
            print("Model URL found: \(modelURL)")
            
            // Check if file exists
            if fileManager.fileExists(atPath: modelURL.path) {
                print("File exists at path")
                
                // Try to load model
                do {
                    let modelScene = try SCNScene(url: modelURL, options: [:])
                    print("Successfully loaded model scene")
                    
                    // Get all child nodes
                    let modelNodes = modelScene.rootNode.childNodes
                    print("Found \(modelNodes.count) nodes in model")
                    
                    // Add them to our empty scene
                    modelNodes.forEach { node in
                        scene.rootNode.addChildNode(node)
                    }
                } catch {
                    print("Error loading model scene: \(error)")
                    DispatchQueue.main.async {
                        self.errorMessage = "Error loading model: \(error.localizedDescription)"
                        self.showError = true
                    }
                }
            } else {
                print("File does not exist at path: \(modelURL.path)")
                DispatchQueue.main.async {
                    self.errorMessage = "File not found at path: \(modelURL.path)"
                    self.showError = true
                }
            }
        } else {
            print("Could not construct URL for model: \(modelName).usdz")
            DispatchQueue.main.async {
                self.errorMessage = "Model file not found in bundle: \(modelName).usdz"
                self.showError = true
            }
        }
        
        // Configure view
        sceneView.scene = scene
        sceneView.backgroundColor = .black
        sceneView.autoenablesDefaultLighting = true
        sceneView.allowsCameraControl = true
        
        // Add gesture recognizers
        let panGesture = UIPanGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handlePan(_:)))
        sceneView.addGestureRecognizer(panGesture)
        
        let pinchGesture = UIPinchGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handlePinch(_:)))
        sceneView.addGestureRecognizer(pinchGesture)
        
        return sceneView
    }
    func updateUIView(_ uiView: SCNView, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject {
        var parent: SimpleModelViewer
        
        init(_ parent: SimpleModelViewer) {
            self.parent = parent
        }
        
        @objc func handlePan(_ gesture: UIPanGestureRecognizer) {
            guard let sceneView = gesture.view as? SCNView else { return }
            let translation = gesture.translation(in: sceneView)
            
            let rotationY = Float(translation.x) * 0.01
            let rotationX = Float(translation.y) * 0.01
            
            sceneView.scene?.rootNode.childNodes.forEach { node in
                node.rotation = SCNVector4(1, 0, 0, rotationX)
                node.rotation = SCNVector4(0, 1, 0, rotationY)
            }
            
            gesture.setTranslation(.zero, in: sceneView)
        }
        
        @objc func handlePinch(_ gesture: UIPinchGestureRecognizer) {
            guard let sceneView = gesture.view as? SCNView else { return }
            let scale = Float(gesture.scale)
            
            sceneView.scene?.rootNode.childNodes.forEach { node in
                node.scale = SCNVector3(scale, scale, scale)
            }
            
            gesture.scale = 1.0
        }
    }
}

// Main View
struct ContentView: View {
    let modelName: String
    @State private var showError = false
    @State private var errorMessage = ""
    
    var body: some View {
        ZStack {
            SimpleModelViewer(modelName: modelName,
                            errorMessage: $errorMessage,
                            showError: $showError)
                .edgesIgnoringSafeArea(.all)
                .onAppear {
                    validateModel()
                }
            
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
    
    private func validateModel() {
        // Check if file exists in bundle
        if let resourcePath = Bundle.main.resourcePath {
            print("Checking resource path: \(resourcePath)")
            
            // List all files in bundle for debugging
            do {
                let files = try FileManager.default.contentsOfDirectory(atPath: resourcePath)
                print("Files in bundle:")
                files.forEach { print($0) }
            } catch {
                print("Error listing bundle contents: \(error)")
            }
        }
        
        // Validate model file
        guard let url = Bundle.main.url(forResource: modelName, withExtension: "usdz") else {
            showError = true
            errorMessage = "Model file not found in bundle: \(modelName).usdz"
            return
        }
        
        do {
            let data = try Data(contentsOf: url)
            if data.isEmpty {
                showError = true
                errorMessage = "Model file is empty"
            }
        } catch {
            showError = true
            errorMessage = "Error loading model: \(error.localizedDescription)"
        }
    }
}
