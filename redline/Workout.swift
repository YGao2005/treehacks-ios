import SwiftUI

struct WorkoutView: View {
    @ObservedObject var viewerState: ModelViewerState
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var showSuccess = false
    @State private var isAnimating = false
    @State private var opacity: Double = 0

    func submitWorkout() async {
        do {
            // First, get the workout plan
            guard let workoutUrl = URL(string: "http://10.32.81.229:5002/get_workout_plan") else {
                throw URLError(.badURL)
            }
            
            var workoutRequest = URLRequest(url: workoutUrl)
            workoutRequest.httpMethod = "POST"
            
            let (workoutData, workoutResponse) = try await URLSession.shared.data(for: workoutRequest)
            
            guard let httpWorkoutResponse = workoutResponse as? HTTPURLResponse,
                  (200...299).contains(httpWorkoutResponse.statusCode) else {
                throw URLError(.badServerResponse)
            }
            
            // Then, add the workout to calendar
            guard let calendarUrl = URL(string: "http://10.32.81.229:5002/add_workout_to_calendar") else {
                throw URLError(.badURL)
            }
            
            var calendarRequest = URLRequest(url: calendarUrl)
            calendarRequest.httpMethod = "POST"
            calendarRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
            calendarRequest.httpBody = workoutData
            
            let (_, calendarResponse) = try await URLSession.shared.data(for: calendarRequest)
            
            if let httpCalendarResponse = calendarResponse as? HTTPURLResponse,
               !(200...299).contains(httpCalendarResponse.statusCode) {
                DispatchQueue.main.async {
                    showError = true
                    errorMessage = "Failed to add workout to calendar"
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
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            viewerState.isShowingWorkout = false
        }
    }

    var body: some View {
        VStack(spacing: 20) {
            Button(action: {
                closeView()
                Task {
                    await submitWorkout()
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
        .onChange(of: viewerState.isShowingWorkout) { newValue in
            if !newValue {
                closeView()
            }
        }
    }
}

struct WorkoutButton: View {
    @ObservedObject var viewerState: ModelViewerState
    @State private var pulseScale: CGFloat = 1.0

    var body: some View {
        VStack {
            Button(action: {
                withAnimation {
                    viewerState.isShowingWorkout.toggle()
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

                    Image(systemName: "figure.run")
                        .font(.system(size: 30))
                        .foregroundColor(.white)
                }
            }

            Text("Workouts")
                .font(.caption)
                .foregroundColor(.white)
                .padding(.top, 4)
        }
        .padding()
        .onChange(of: viewerState.isShowingWorkout) { newValue in
            if newValue {
                viewerState.rotateModel()
            } else {
                viewerState.startBlinkingAnimation()
                DispatchQueue.main.asyncAfter(deadline: .now() + 6.0) {
                    viewerState.rotateBackModel()
                    viewerState.stopBlinkingAnimation()
                }
            }
        }
    }
}
