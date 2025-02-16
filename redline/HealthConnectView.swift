import SwiftUI
import TerraiOS

class HealthManager: ObservableObject {
    var terra: TerraManager?
    @Published var isConnected = false
    @Published var isLoading = false
    
    // Individual metric payloads
    @Published var activityPayload: TerraActivityDataPayloadModel?
    @Published var dailyPayload: TerraDailyDataPayloadModel?
    @Published var sleepPayload: TerraSleepDataPayloadModel?
    @Published var error: String?
    
    private func fetchAuthToken() async throws -> String {
        let url = URL(string: "https://api.tryterra.co/v2/auth/generateAuthToken")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("S8aYjRBrGviBP7qjNu32dCUuQTGLtCHC", forHTTPHeaderField: "x-api-key")
        request.addValue("4actk-temp-testing-p3OyGGA8Z7", forHTTPHeaderField: "dev-id")

        let (data, _) = try await URLSession.shared.data(for: request)
        let response = try JSONDecoder().decode(AuthResponse.self, from: data)
        return response.token
    }
    
    func connectToAppleHealth() async throws {
        guard let terra = terra else {
            throw NSError(domain: "HealthManager", code: -1, userInfo: [NSLocalizedDescriptionKey: "Terra manager not initialized"])
        }
        
        let token = try await fetchAuthToken()
        
        return try await withCheckedThrowingContinuation { continuation in
            terra.initConnection(
                type: .APPLE_HEALTH,
                token: token,
                customReadTypes: [],
                schedulerOn: true
            ) { success, error in
                if success {
                    self.isConnected = true
                    continuation.resume()
                } else {
                    continuation.resume(throwing: error ?? NSError(domain: "HealthManager", code: -1, userInfo: [NSLocalizedDescriptionKey: "Connection failed"]))
                }
            }
        }
    }
    
    func fetchActivity(startDate: Date, endDate: Date) async throws -> TerraActivityDataPayloadModel {
        guard let terra = terra, isConnected else {
            throw NSError(domain: "HealthManager", code: -1, userInfo: [NSLocalizedDescriptionKey: "Not connected to Apple Health"])
        }
        
        return try await withCheckedThrowingContinuation { continuation in
            terra.getActivity(
                type: .APPLE_HEALTH,
                startDate: startDate,
                endDate: endDate,
                toWebhook: false
            ) { success, payload, error in
                if let payload = payload {
                    continuation.resume(returning: payload)
                } else {
                    continuation.resume(throwing: error ?? NSError(domain: "HealthManager", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to fetch activity data"]))
                }
            }
        }
    }
    
    func fetchDaily(startDate: Date, endDate: Date) async throws -> TerraDailyDataPayloadModel {
        guard let terra = terra, isConnected else {
            throw NSError(domain: "HealthManager", code: -1, userInfo: [NSLocalizedDescriptionKey: "Not connected to Apple Health"])
        }
        
        return try await withCheckedThrowingContinuation { continuation in
            terra.getDaily(
                type: .APPLE_HEALTH,
                startDate: startDate,
                endDate: endDate,
                toWebhook: false
            ) { success, payload, error in
                if let payload = payload {
                    continuation.resume(returning: payload)
                } else {
                    continuation.resume(throwing: error ?? NSError(domain: "HealthManager", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to fetch daily data"]))
                }
            }
        }
    }
    
    func fetchSleep(startDate: Date, endDate: Date) async throws -> TerraSleepDataPayloadModel {
        guard let terra = terra, isConnected else {
            throw NSError(domain: "HealthManager", code: -1, userInfo: [NSLocalizedDescriptionKey: "Not connected to Apple Health"])
        }
        
        return try await withCheckedThrowingContinuation { continuation in
            terra.getSleep(
                type: .APPLE_HEALTH,
                startDate: startDate,
                endDate: endDate,
                toWebhook: false
            ) { success, payload, error in
                if let payload = payload {
                    continuation.resume(returning: payload)
                } else {
                    continuation.resume(throwing: error ?? NSError(domain: "HealthManager", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to fetch sleep data"]))
                }
            }
        }
    }
}

// View for health connection
struct HealthConnectView: View {
    @ObservedObject var healthManager: HealthManager
    @State private var showError = false
    @State private var errorMessage = ""
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "heart.circle.fill")
                .font(.system(size: 60))
                .foregroundColor(.blue)
            
            Text("Connect Your Health Data")
                .font(.title2)
                .fontWeight(.bold)
            
            Text("Access your health and fitness data to track your progress")
                .multilineTextAlignment(.center)
                .foregroundColor(.gray)
                .padding(.horizontal)
            
            if healthManager.isLoading {
                VStack(spacing: 12) {
                    ProgressView()
                        .scaleEffect(1.2)
                    Text("Connecting...")
                        .foregroundColor(.gray)
                }
                .padding()
            } else {
                Button(action: {
                    Task {
                        await connect()
                    }
                }) {
                    HStack {
                        Image(systemName: "link")
                        Text("Connect to Apple Health")
                    }
                    .frame(minWidth: 200)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
            }
        }
        .padding()
        .alert("Connection Error", isPresented: $showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
    }
    
    private func connect() async {
        do {
            await MainActor.run { healthManager.isLoading = true }
            try await healthManager.connectToAppleHealth()
        } catch {
            await MainActor.run {
                errorMessage = error.localizedDescription
                showError = true
            }
        }
        await MainActor.run { healthManager.isLoading = false }
    }
}

// Helper struct for auth response
struct AuthResponse: Codable {
    let status: String
    let token: String
    let expires_in: Int
}
