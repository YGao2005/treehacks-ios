import SwiftUI

struct ScheduleView: View {
    @Binding var scheduleText: String
    @ObservedObject var viewerState: ModelViewerState
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var showSuccess = false
    @State private var submittedScheduleText = ""
    @State private var isAnimating = false
    @State private var pulseScale: CGFloat = 1.0
    @State private var opacity: Double = 0  // Start invisible for fade in

    func submitSchedule() async {
        do {
            guard let url = URL(string: "http://10.32.81.229:5002/create-event")
            else {
                throw URLError(.badURL)
            }

            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")

            let body = ["user_input": submittedScheduleText]
            request.httpBody = try JSONEncoder().encode(body)

            let (_, response) = try await URLSession.shared.data(for: request)

            if let httpResponse = response as? HTTPURLResponse,
                !(200...299).contains(httpResponse.statusCode)
            {
                DispatchQueue.main.async {
                    showError = true
                    errorMessage = "Failed to submit schedule"
                }
            }
        } catch {
            DispatchQueue.main.async {
                showError = true
                errorMessage = error.localizedDescription
            }
        }
    }
    
    func closeView() {
        withAnimation(.easeOut(duration: 0.3)) {
            opacity = 0
        }
        
        // Delay the actual closing to allow fade out animation to complete
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            viewerState.isShowingSchedule = false
        }
    }

    var body: some View {
        VStack(spacing: 20) {
            // Glassmorphic TextField
            ZStack {
                // Blurred background
                RoundedRectangle(cornerRadius: 15)
                    .fill(Color.white.opacity(0.1))
                    .frame(width: 300, height: 60)
                    .blur(radius: 3)
                
                // Gradient border
                RoundedRectangle(cornerRadius: 15)
                    .stroke(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color.white.opacity(0.2),
                                Color.white.opacity(0.5),
                                Color.white.opacity(0.8),
                                Color.white.opacity(0.5),
                                Color.white.opacity(0.2),
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 2
                    )
                    .frame(width: 300, height: 60)
                    .shadow(color: .white.opacity(0.3), radius: 10, x: 0, y: 0)
                
                TextField("Enter schedule details...", text: $scheduleText)
                    .foregroundColor(.white)
                    .padding(.horizontal)
                    .frame(width: 280)
            }
            .scaleEffect(pulseScale)
            
            // Glassmorphic Submit Button
            Button(action: {
                submittedScheduleText = scheduleText
                closeView()
                
                Task {
                    await submitSchedule()
                    DispatchQueue.main.async {
                        showSuccess = true
                    }
                }
                scheduleText = ""
            }) {
                ZStack {
                    // Base circle with blur
                    Circle()
                        .stroke(Color.white.opacity(0.3), lineWidth: 2)
                        .frame(width: 80, height: 80)
                        .blur(radius: 5)
                    
                    // Outer glowing circle
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
                    
                    // Icon and text
                    VStack(spacing: 4) {
                        Image(systemName: "checkmark.circle")
                            .font(.system(size: 30))
                            .foregroundColor(.white)
                            .opacity(isAnimating ? 1 : 0.7)
                        
                        Text("Submit")
                            .font(.caption)
                            .foregroundColor(.white)
                    }
                }
            }
            .disabled(scheduleText.isEmpty)
        }
        .opacity(opacity)  // Controlled opacity for fade in/out
        .alert("Error", isPresented: $showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
        .onAppear {
            viewerState.rotateModel()
            // Fade in when appearing
            withAnimation(.easeIn(duration: 0.3)) {
                opacity = 1
            }
            withAnimation(Animation.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
                isAnimating = true
                pulseScale = 1.02
            }
        }
        .onChange(of: viewerState.isShowingSchedule) { newValue in
            if !newValue {
                closeView()
            }
        }
    }
}

struct ScheduleButton: View {
    @ObservedObject var viewerState: ModelViewerState
    @State private var pulseScale: CGFloat = 1.0

    var body: some View {
        VStack {
            Button(action: {
                withAnimation {
                    viewerState.isShowingSchedule.toggle()
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

                    Image(systemName: "calendar")
                        .font(.system(size: 30))
                        .foregroundColor(.white)
                }
            }

            Text("Schedule")
                .font(.caption)
                .foregroundColor(.white)
                .padding(.top, 4)
        }
        .padding()
        .onChange(of: viewerState.isShowingSchedule) { newValue in
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
