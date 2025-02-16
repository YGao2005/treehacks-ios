import SwiftUI

struct HeartRiskResponse: Codable {
    let prediction: String
    let probabilities: [Double]
    let status: String
}

struct HeartRiskView: View {
    @ObservedObject var viewerState: ModelViewerState
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var isLoading = false
    @State private var showResult = false
    @State private var predictionResult: HeartRiskResponse?
    @State private var isAnimating = false
    @State private var pulseScale: CGFloat = 1.0
    @State private var opacity: Double = 0
    
    private func getHealthMessage(_ prediction: String) -> String {
        return prediction == "1" ? "Your heart health needs attention" : "Your heart health is regular"
    }
    
    private func calculateHealthScore(_ probability: Double) -> Int {
        return Int(100 - (probability * 100))
    }
    
    func checkHeartRisk() async {
        isLoading = true
        do {
            guard let predictionUrl = URL(string: "http://10.32.81.229:5002/heart_disease_prediction") else {
                throw URLError(.badURL)
            }
            
            var predictionRequest = URLRequest(url: predictionUrl)
            predictionRequest.httpMethod = "POST"
            predictionRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
            
            let body: [String: Any] = [:]
            predictionRequest.httpBody = try JSONSerialization.data(withJSONObject: body)
            
            let (data, predictionResponse) = try await URLSession.shared.data(for: predictionRequest)
            
            guard let httpPredictionResponse = predictionResponse as? HTTPURLResponse,
                  (200...299).contains(httpPredictionResponse.statusCode) else {
                throw URLError(.badServerResponse)
            }

            let decodedResponse = try JSONDecoder().decode(HeartRiskResponse.self, from: data)
            
            DispatchQueue.main.async {
                predictionResult = decodedResponse
                showResult = true
                isLoading = false
            }
        } catch {
            DispatchQueue.main.async {
                isLoading = false
                showError = true
                errorMessage = error.localizedDescription
            }
        }
    }
    
    func closeView() {
        withAnimation(.easeOut(duration: 0.3)) {
            opacity = 0
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            viewerState.isShowingHeartRisk = false
        }
    }

    var body: some View {
        VStack(spacing: 24) {
            if let result = predictionResult {
                // Health Status Card
                VStack(spacing: 16) {
                    Text(getHealthMessage(result.prediction))
                        .font(.title2)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                    
                    // Health Score Circle
                    ZStack {
                        Circle()
                            .stroke(Color.white.opacity(0.2), lineWidth: 10)
                            .frame(width: 120, height: 120)
                        
                        Circle()
                            .trim(from: 0, to: CGFloat(calculateHealthScore(result.probabilities[1])) / 100)
                            .stroke(
                                LinearGradient(
                                    gradient: Gradient(colors: [Color.green.opacity(0.8), Color.blue.opacity(0.8)]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                style: StrokeStyle(lineWidth: 10, lineCap: .round)
                            )
                            .frame(width: 120, height: 120)
                            .rotationEffect(.degrees(-90))
                        
                        VStack {
                            Text("\(calculateHealthScore(result.probabilities[1]))")
                                .font(.system(size: 36, weight: .bold))
                                .foregroundColor(.white)
                            Text("Health Score")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.8))
                        }
                    }
                    .padding(.vertical, 8)
                }
                .frame(maxWidth: .infinity)
                .padding(24)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color.black.opacity(0.3))
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(Color.white.opacity(0.2), lineWidth: 1)
                        )
                )
                .shadow(color: .black.opacity(0.2), radius: 10)
            }
            
            // Check Button - Only show if no result yet
            if predictionResult == nil {
                Button(action: {
                    Task {
                        await checkHeartRisk()
                    }
                }) {
                    ZStack {
                        if isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(1.5)
                        } else {
                            HStack(spacing: 8) {
                                Image(systemName: "heart.fill")
                                    .font(.system(size: 20))
                                Text("Check Health")
                                    .font(.headline)
                            }
                            .foregroundColor(.white)
                            .padding(.horizontal, 24)
                            .padding(.vertical, 12)
                            .background(
                                Capsule()
                                    .fill(Color.blue.opacity(0.3))
                                    .overlay(
                                        Capsule()
                                            .stroke(Color.white.opacity(0.3), lineWidth: 1)
                                    )
                            )
                        }
                    }
                }
                .disabled(isLoading)
            }
        }
        .padding(24)
        .frame(maxWidth: 400)
        .opacity(opacity)
        .alert("Error", isPresented: $showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
        .onAppear {
            viewerState.rotateModel()
            withAnimation(.easeIn(duration: 0.3)) {
                opacity = 1
            }
        }
        .onChange(of: viewerState.isShowingHeartRisk) { newValue in
            if !newValue {
                closeView()
            }
        }
    }
}

struct HeartRiskButton: View {
    @ObservedObject var viewerState: ModelViewerState
    @State private var pulseScale: CGFloat = 1.0

    var body: some View {
        VStack {
            Button(action: {
                withAnimation {
                    viewerState.isShowingHeartRisk.toggle()
                }
            }) {
                ZStack {
                    Circle()
                        .stroke(Color.white.opacity(0.3), lineWidth: 2)
                        .frame(width: 80, height: 80)
                        .scaleEffect(pulseScale)
                        .blur(radius: 5)

                    Circle()
                        .stroke(Color.white.opacity(0.6), lineWidth: 3)
                        .frame(width: 90, height: 90)
                        .blur(radius: 4)
                        .overlay(
                            Circle()
                                .stroke(
                                    LinearGradient(
                                        gradient: Gradient(colors: [
                                            Color.white.opacity(0),
                                            Color.white.opacity(0.5),
                                            Color.white.opacity(0.8),
                                            Color.white.opacity(0.5),
                                            Color.white.opacity(0),
                                        ]),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 3
                                )
                        )
                        .shadow(color: .white.opacity(0.5), radius: 10, x: 0, y: 0)

                    Image(systemName: "heart.fill")
                        .font(.system(size: 30))
                        .foregroundColor(.white)
                }
            }

            Text("Heart Risk")
                .font(.caption)
                .foregroundColor(.white)
                .padding(.top, 4)
        }
        .padding()
        .onChange(of: viewerState.isShowingHeartRisk) { newValue in
            if newValue {
                viewerState.rotateModel()
            } else {
                viewerState.startBlinkingAnimation()
                DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                    viewerState.rotateBackModel()
                    viewerState.stopBlinkingAnimation()
                }
            }
        }
    }
}
