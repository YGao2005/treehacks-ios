import SwiftUI
import TerraiOS

class HealthManager: ObservableObject {
    var terra: TerraManager?
    @Published var isConnected = false
    @Published var isLoading = false
    @Published var activityData: TerraActivityDataPayloadModel?
    @Published var dailyData: TerraDailyDataPayloadModel?
    @Published var sleepData: TerraSleepDataPayloadModel?
    @Published var error: String?

    // Add state tracking for fetching operations
    @Published private var isFetchingActivity = false
    @Published private var isFetchingDaily = false
    @Published private var isFetchingSleep = false

    func setTerraManager(_ manager: TerraManager?) {
        self.terra = manager
        // Check connection status when manager is set
    }

    func fetchAuthToken() async throws -> String {
        let url = URL(
            string: "https://api.tryterra.co/v2/auth/generateAuthToken")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue(
            "S8aYjRBrGviBP7qjNu32dCUuQTGLtCHC", forHTTPHeaderField: "x-api-key")
        request.addValue(
            "4actk-temp-testing-p3OyGGA8Z7", forHTTPHeaderField: "dev-id")

        do {
            let (data, httpResponse) = try await URLSession.shared.data(
                for: request)

            // Check HTTP response
            guard let httpResponse = httpResponse as? HTTPURLResponse else {
                throw NSError(
                    domain: "HealthManager", code: -1,
                    userInfo: [NSLocalizedDescriptionKey: "Invalid response"])
            }

            guard httpResponse.statusCode == 200 else {
                throw NSError(
                    domain: "HealthManager", code: httpResponse.statusCode,
                    userInfo: [
                        NSLocalizedDescriptionKey:
                            "Server returned status code \(httpResponse.statusCode)"
                    ])
            }

            let tokenResponse = try JSONDecoder().decode(
                AuthResponse.self, from: data)
            return tokenResponse.token
        } catch {
            print("Auth token fetch error: \(error)")
            throw error
        }
    }

    func connectToAppleHealth() {
        guard let terra = terra else {
            DispatchQueue.main.async {
                self.error = "Terra manager not initialized"
            }
            return
        }

        Task {
            do {
                await MainActor.run {
                    self.isLoading = true
                    self.error = nil
                }

                let token = try await fetchAuthToken()
                print("Got token: \(token)")

                // Define required permissions
                let permissions: Set<CustomPermissions> = []

                await MainActor.run {
                    terra.initConnection(
                        type: .APPLE_HEALTH,
                        token: token,
                        customReadTypes: permissions,
                        schedulerOn: true
                    ) { [weak self] success, error in
                        DispatchQueue.main.async {
                            self?.isLoading = false
                            self?.isConnected = success

                            if success {
                                self?.fetchAllData()
                            } else if let error = error {
                                self?.error = "Connection failed: \(error)"
                            }
                        }
                    }
                }
            } catch {
                await MainActor.run {
                    self.isLoading = false
                    self.error =
                        "Failed to fetch auth token: \(error.localizedDescription)"
                }
            }
        }
    }

    public func fetchAllData() {
        guard !isFetchingActivity && !isFetchingDaily && !isFetchingSleep else {
            print("Fetch already in progress")
            return
        }

        fetchActivityData()
        fetchDailyData()
        fetchSleepData()
    }

    func fetchActivityData() {
        guard let terra = terra else {
            self.error = "Terra manager not initialized"
            return
        }

        guard isConnected else {
            self.error = "Not connected to Apple Health"
            return
        }

        isFetchingActivity = true

        let endDate = Date()
        let startDate = Calendar.current.date(
            byAdding: .day, value: -31, to: endDate)!

        print("Fetching activity data from \(startDate) to \(endDate)")

        terra.getActivity(
            type: .APPLE_HEALTH,
            startDate: startDate,
            endDate: endDate,
            toWebhook: false
        ) { [weak self] success, payload, error in
            DispatchQueue.main.async {
                self?.isFetchingActivity = false

                if success, let payload = payload {
                    print("Received activity payload: \(payload)")
                    self?.activityData = payload
                } else if let error = error {
                    self?.error = "Activity fetch error: \(error)"
                    print("Activity fetch error: \(error)")
                } else {
                    self?.error = "Activity fetch failed with no error details"
                }
            }
        }
    }

    func fetchDailyData() {
        guard let terra = terra else {
            self.error = "Terra manager not initialized"
            return
        }

        guard isConnected else {
            self.error = "Not connected to Apple Health"
            return
        }

        isFetchingDaily = true

        let endDate = Date()
        let startDate = Calendar.current.date(
            byAdding: .day, value: -31, to: endDate)!

        print("Fetching daily data from \(startDate) to \(endDate)")

        terra.getDaily(
            type: .APPLE_HEALTH,
            startDate: startDate,
            endDate: endDate,
            toWebhook: false
        ) { [weak self] success, payload, error in
            DispatchQueue.main.async {
                self?.isFetchingDaily = false

                if success, let payload = payload {
                    print("Received daily payload: \(payload)")
                    self?.dailyData = payload
                } else if let error = error {
                    self?.error = "Daily fetch error: \(error)"
                    print("Daily fetch error: \(error)")
                } else {
                    self?.error = "Daily fetch failed with no error details"
                }
            }
        }
    }

    func fetchSleepData() {
        guard let terra = terra else {
            self.error = "Terra manager not initialized"
            return
        }

        guard isConnected else {
            self.error = "Not connected to Apple Health"
            return
        }

        isFetchingSleep = true

        let endDate = Date()
        let startDate = Calendar.current.date(
            byAdding: .day, value: -31, to: endDate)!

        print("Fetching sleep data from \(startDate) to \(endDate)")

        terra.getSleep(
            type: .APPLE_HEALTH,
            startDate: startDate,
            endDate: endDate,
            toWebhook: false
        ) { [weak self] success, payload, error in
            DispatchQueue.main.async {
                self?.isFetchingSleep = false

                if success, let payload = payload {
                    print("Received sleep payload: \(payload)")
                    self?.sleepData = payload
                } else if let error = error {
                    self?.error = "Sleep fetch error: \(error)"
                    print("Sleep fetch error: \(error)")
                } else {
                    self?.error = "Sleep fetch failed with no error details"
                }
            }
        }
    }
}

// Add this struct to decode the API response
struct AuthResponse: Codable {
    let status: String
    let token: String
    let expires_in: Int

    enum CodingKeys: String, CodingKey {
        case status
        case token
        case expires_in = "expires_in"
    }
}

// Update the HealthConnectView to show any loading states
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
                    healthManager.connectToAppleHealth()
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
}
