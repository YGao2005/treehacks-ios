import SwiftUI

struct DestressorView: View {
    @ObservedObject var viewerState: ModelViewerState
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var showSuccess = false
    @State private var isAnimating = false
    @State private var opacity: Double = 0

    func submitDestressor() async {
        do {
            // First, get the destressor plan
            guard let destressorUrl = URL(string: "http://10.32.81.229:5002/get_destresser_recommendations") else {
                throw URLError(.badURL)
            }
            
            // Create the JSON payload
            let payload = [
                "stress_level": 5,  // You might want to make this dynamic
                "available_time": 30,  // Time in minutes
                "preferred_activities": ["meditation", "exercise", "reading"]  // Example activities
            ] as [String: Any]
            
            // Convert payload to JSON data
            let jsonData = try JSONSerialization.data(withJSONObject: payload)
            
            var destressorRequest = URLRequest(url: destressorUrl)
            destressorRequest.httpMethod = "POST"
            destressorRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
            destressorRequest.httpBody = jsonData
            
            let (destressorData, destressorResponse) = try await URLSession.shared.data(for: destressorRequest)
            
            guard let httpDestressorResponse = destressorResponse as? HTTPURLResponse,
                  (200...299).contains(httpDestressorResponse.statusCode) else {
                throw URLError(.badServerResponse)
            }
            
            // Verify we can parse the response
            guard let recommendations = try? JSONSerialization.jsonObject(with: destressorData) as? [[String: Any]] else {
                throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid response format"])
            }
            
            // Then, add the destressor to calendar
            guard let calendarUrl = URL(string: "http://10.32.81.229:5002/add_destresser_to_calendar") else {
                throw URLError(.badURL)
            }
            
            // Format date in required format (YYYY-MM-DDTHH:MM:SS)
            let dateFormatter = DateFormatter()
            func generateRandomTime() -> String {
                let now = Date()
                let oneWeekFromNow = Calendar.current.date(byAdding: .day, value: 7, to: now)!
                
                // Generate random time between now and next week
                let randomTimeInterval = TimeInterval.random(
                    in: now.timeIntervalSinceNow...oneWeekFromNow.timeIntervalSinceNow
                )
                let randomDate = Date(timeIntervalSinceNow: randomTimeInterval)
                
                // Format the date
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
                return dateFormatter.string(from: randomDate)
            }
            
            let dateString = generateRandomTime()

            // Create calendar request payload
            let calendarPayload: [String: Any] = [
                "destresser_data": recommendations,
                "date_time": dateString
            ]
            
            // Convert calendar payload to JSON data
            let calendarJsonData = try JSONSerialization.data(withJSONObject: calendarPayload)
            
            var calendarRequest = URLRequest(url: calendarUrl)
            calendarRequest.httpMethod = "POST"
            calendarRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
            calendarRequest.httpBody = calendarJsonData  // Using the wrapped payload
            
            let (calendarData, calendarResponse) = try await URLSession.shared.data(for: calendarRequest)
            
            if let httpCalendarResponse = calendarResponse as? HTTPURLResponse,
               !(200...299).contains(httpCalendarResponse.statusCode) {
                // Print the request payload
                if let requestPayload = String(data: destressorData, encoding: .utf8) {
                    print("Request Payload:")
                    print(requestPayload)
                }
                
                // Get and print error response
                let errorData = try? JSONSerialization.jsonObject(with: calendarData) as? [String: Any]
                print("Error Response Data:", errorData ?? "No error data")
                print("Status Code:", httpCalendarResponse.statusCode)
                
                DispatchQueue.main.async {
                    showError = true
                    errorMessage = "Failed to add destressor to calendar (Status: \(httpCalendarResponse.statusCode))"
                }
            }
        } catch {
            print("Error details:", error)
            if let urlError = error as? URLError {
                print("URL Error Code:", urlError.code.rawValue)
            }
            
            DispatchQueue.main.async {
                showError = true
                errorMessage = "\(error.localizedDescription) (Details logged to console)"
            }
        }
    }
    
    func closeView() {
        withAnimation(.easeOut(duration: 0.3)) {
            opacity = 0
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            viewerState.isShowingDestressor = false
        }
    }

    var body: some View {
        VStack(spacing: 20) {
            Button(action: {
                closeView()
                Task {
                    await submitDestressor()
                    DispatchQueue.main.async {
                        showSuccess = true
                    }
                }
            }) {
                ZStack {
                    Circle()
                        .stroke(Color.white.opacity(0.3), lineWidth: 2)
                        .frame(width: 80, height: 80)
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
                    
                    VStack(spacing: 4) {
                        Image(systemName: "leaf.circle")
                            .font(.system(size: 30))
                            .foregroundColor(.white)
                            .opacity(isAnimating ? 1 : 0.7)
                        
                        Text("Submit")
                            .font(.caption)
                            .foregroundColor(.white)
                    }
                }
            }
        }
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
            withAnimation(Animation.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
                isAnimating = true
            }
        }
        .onChange(of: viewerState.isShowingDestressor) { newValue in
            if !newValue {
                closeView()
            }
        }
    }
}

struct DestressorButton: View {
    @ObservedObject var viewerState: ModelViewerState
    @State private var pulseScale: CGFloat = 1.0

    var body: some View {
        VStack {
            Button(action: {
                withAnimation {
                    viewerState.isShowingDestressor.toggle()
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
                        .shadow(
                            color: .white.opacity(0.5), radius: 10, x: 0, y: 0)

                    Image(systemName: "leaf")
                        .font(.system(size: 30))
                        .foregroundColor(.white)
                }
            }

            Text("Destressor")
                .font(.caption)
                .foregroundColor(.white)
                .padding(.top, 4)
        }
        .padding()
        .onChange(of: viewerState.isShowingDestressor) { newValue in
            if newValue {
                viewerState.rotateModel()
            } else {
                viewerState.startBlinkingAnimation()
                DispatchQueue.main.asyncAfter(deadline: .now() + 8.0) {
                    viewerState.rotateBackModel()
                    viewerState.stopBlinkingAnimation()
                }
            }
        }
    }
}
