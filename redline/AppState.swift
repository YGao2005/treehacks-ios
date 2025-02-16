import SwiftUI
import TerraiOS

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
