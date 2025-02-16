import SwiftUI
import SceneKit

class ModelViewerState: ObservableObject {
    @Published var isAnimating: Bool = false
    @Published var sceneView: SCNView?
    @Published var isLoading = false
    @Published var isRotating = false
    @Published var isShowingSchedule = false
    @Published var isShowingWorkout = false
    @Published var isBlinking = false
    @Published var isShowingDestressor = false
    @Published var isShowingVoiceInput = false
    @Published var isShowingHeartRisk = false
    private var originalRotation: Float = 0
    private var rotationTimer: Timer?
    private var blinkTimer: Timer?
    
    func startBlinkingAnimation() {
        guard !isBlinking,
              let sceneView = sceneView,
              let modelNode = sceneView.scene?.rootNode.childNodes.first(where: { node in
                  return node.geometry != nil || !node.childNodes.isEmpty
              }) else { return }
        
        isBlinking = true
        
        // Create a timer for continuous blinking
        blinkTimer = Timer.scheduledTimer(withTimeInterval: 1.5, repeats: true) { [weak self] _ in
            self?.toggleOpacity()
        }
        
        // Start first blink immediately
        toggleOpacity()
    }
    
    func stopBlinkingAnimation() {
        blinkTimer?.invalidate()
        blinkTimer = nil
        isBlinking = false
        
        // Reset opacity to fully visible
        guard let sceneView = sceneView,
              let modelNode = sceneView.scene?.rootNode.childNodes.first(where: { node in
                  return node.geometry != nil || !node.childNodes.isEmpty
              }) else { return }
        
        SCNTransaction.begin()
        SCNTransaction.animationDuration = 0.75
        modelNode.opacity = 1.0
        SCNTransaction.animationTimingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        SCNTransaction.commit()
    }
    
    private func toggleOpacity() {
        guard let sceneView = sceneView,
              let modelNode = sceneView.scene?.rootNode.childNodes.first(where: { node in
                  return node.geometry != nil || !node.childNodes.isEmpty
              }) else { return }
        
        SCNTransaction.begin()
        SCNTransaction.animationDuration = 0.75
        
        // Toggle between fully visible and semi-transparent
        modelNode.opacity = modelNode.opacity == 1.0 ? 0.1 : 1.0
        
        SCNTransaction.animationTimingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        SCNTransaction.commit()
    }
    
    func startLoadingRotation() {
        guard let sceneView = sceneView,
              let modelNode = sceneView.scene?.rootNode.childNodes.first(where: { node in
                  return node.geometry != nil || !node.childNodes.isEmpty
              }) else { return }
        
        // Store the original rotation
        originalRotation = modelNode.eulerAngles.y
        isLoading = true
        
        // Create a timer to continuously rotate the model
        rotationTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
            self?.rotateModel()
        }
        
        // Trigger first rotation immediately
        rotateModel()
    }
    
    func stopLoadingRotation() {
        rotationTimer?.invalidate()
        rotationTimer = nil
        isLoading = false
        
        // Return to original position
        guard let sceneView = sceneView,
              let modelNode = sceneView.scene?.rootNode.childNodes.first(where: { node in
                  return node.geometry != nil || !node.childNodes.isEmpty
              }) else { return }
        
        SCNTransaction.begin()
        SCNTransaction.animationDuration = 2.0
        modelNode.eulerAngles = SCNVector3(x: 0, y: originalRotation, z: 0)
        SCNTransaction.animationTimingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        SCNTransaction.commit()
    }
    
    
    func rotateModel() {
        guard !isAnimating,
              let sceneView = sceneView,
              let modelNode = sceneView.scene?.rootNode.childNodes.first(where: { node in
                  return node.geometry != nil || !node.childNodes.isEmpty
              }) else { return }
        
        isAnimating = true
        
        SCNTransaction.begin()
        SCNTransaction.animationDuration = 2.0
        
        let currentRotation = modelNode.eulerAngles.y
        modelNode.eulerAngles = SCNVector3(x: 0, y: currentRotation + Float.pi/2, z: 0)
        
        SCNTransaction.completionBlock = { [weak self] in
            self?.isAnimating = false
        }
        
        SCNTransaction.animationTimingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        SCNTransaction.commit()
    }
    
    func rotateBackModel() {
        guard !isAnimating,
              let sceneView = sceneView,
              let modelNode = sceneView.scene?.rootNode.childNodes.first(where: { node in
                  return node.geometry != nil || !node.childNodes.isEmpty
              }) else { return }
        
        isAnimating = true
        
        SCNTransaction.begin()
        SCNTransaction.animationDuration = 2.0
        
        let currentRotation = modelNode.eulerAngles.y
        modelNode.eulerAngles = SCNVector3(x: 0, y: currentRotation - Float.pi/2, z: 0)
        
        SCNTransaction.completionBlock = { [weak self] in
            self?.isAnimating = false
        }
        
        SCNTransaction.animationTimingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        SCNTransaction.commit()
    }
}
