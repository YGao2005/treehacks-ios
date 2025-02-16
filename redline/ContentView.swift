import SwiftUI

struct ContentView: View {
    let modelName: String
    let modelValue: Int
    @StateObject private var viewerState = ModelViewerState()
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var isAnimating = false
    @State private var pulseScale: CGFloat = 1.0
    @State private var scheduleText = ""
    @StateObject private var audioRecorder = AudioRecorder()
    @GestureState private var isPressed = false
    @State private var isRecordingActive = false
    
    var body: some View {
        ZStack {
            // Background color
            Color.black.edgesIgnoringSafeArea(.all)
            
            // Model viewer as background
            SimpleModelViewer(
                modelName: modelName,
                value: modelValue,
                errorMessage: $errorMessage,
                showError: $showError,
                viewerState: viewerState
            )
            .edgesIgnoringSafeArea(.all)
            .transition(.opacity)
            .padding(.bottom, 40)
            .ignoresSafeArea(.keyboard) // Ignore keyboard

            // Schedule interface
            if viewerState.isShowingSchedule {
                GeometryReader { geometry in
                    ScheduleView(
                        scheduleText: $scheduleText,
                        viewerState: viewerState
                    )
                    .position(
                        x: geometry.size.width / 2,
                        y: geometry.size.height / 2
                    )
                }
                .transition(.opacity)
                .ignoresSafeArea(.keyboard)
                .padding(.bottom, 90)
            }
            
            if(viewerState.isShowingWorkout) {
                GeometryReader { geometry in
                    WorkoutView(viewerState: viewerState)
                        .position(
                            x: geometry.size.width / 2,
                            y: geometry.size.height / 2
                        )
                }
                .transition(.opacity)
                .ignoresSafeArea(.keyboard)
                .padding(.bottom, 90)
            }
            
            // Similar modifications for other conditional views
            if(viewerState.isShowingDestressor) {
                GeometryReader { geometry in
                    DestressorView(viewerState: viewerState)
                        .position(
                            x: geometry.size.width / 2,
                            y: geometry.size.height / 2
                        )
                }
                .transition(.opacity)
                .ignoresSafeArea(.keyboard)
                .padding(.bottom, 90)
            }
            
            if viewerState.isShowingVoiceInput {
                GeometryReader { geometry in
                    VoiceInputView(viewerState: viewerState)
                        .position(
                            x: geometry.size.width / 2,
                            y: geometry.size.height / 2
                        )
                }
                .transition(.opacity)
                .ignoresSafeArea(.keyboard)
                .padding(.bottom, 90)
            }
            
            if viewerState.isShowingHeartRisk {
                GeometryReader { geometry in
                    HeartRiskView(viewerState: viewerState)
                        .position(
                            x: geometry.size.width / 2,
                            y: geometry.size.height / 2
                        )
                }
                .transition(.opacity)
                .ignoresSafeArea(.keyboard)
                .padding(.bottom, 90)
            }

            // Main content VStack
            VStack {
                // Title and stress score
                VStack(spacing: 8) {
                    Text("FlowState")
                        .font(.custom("Poppins-Regular", size: 40))
                        .foregroundColor(.white)
                        .overlay(
                            Text("FlowState")
                                .font(.custom("Poppins-Regular", size: 40))
                                .foregroundColor(.white.opacity(isAnimating ? 0.4 : 0.2))
                                .blur(radius: isAnimating ? 4 : 2)
                        )
                        .shadow(color: .white.opacity(isAnimating ? 0.4 : 0.2), radius: 5, x: 0, y: 0)
                    Text("Your stress score today is \(modelValue)")
                        .font(.custom("Poppins-Thin", size: 18))
                        .foregroundColor(.white.opacity(0.8))
                }
                .padding(.top, 60)
                .ignoresSafeArea(.keyboard)

                Spacer()

                // Button grid
                VStack(spacing: -10) {
                    HStack(spacing: 100) {
                        DestressorButton(viewerState: viewerState)
                        WorkoutButton(viewerState: viewerState)
                    }
                    HStack(spacing: 20) {
                        HeartRiskButton(viewerState: viewerState)
                        ScheduleButton(viewerState: viewerState)
                    }
                }
                .padding(.bottom, 20)
                .ignoresSafeArea(.keyboard)
            }
            .ignoresSafeArea(.keyboard)

            // Mic button
            GeometryReader { geometry in
                Button(action: {
                    withAnimation {
                        viewerState.isShowingVoiceInput.toggle()
                    }
                }) {
                    Image(systemName: "mic.fill")
                        .font(.system(size: 45))
                        .foregroundColor(.white)
                        .opacity(0.8)
                }
                .position(
                    x: geometry.size.width / 2,
                    y: geometry.size.height - 220
                )
            }
            .ignoresSafeArea(.keyboard)
        }
        .ignoresSafeArea(.keyboard)
    }
}

struct CircleButton: View {
    let systemName: String
    let label: String
    @ObservedObject var viewerState: ModelViewerState
    @State private var isAnimating = false
    @State private var pulseScale: CGFloat = 1.0
    @State private var isLoading = false

    func makeAPICall() async {
        do {
            DispatchQueue.main.async {
                viewerState.startLoadingRotation()
            }

            let url = URL(string: "https://api.example.com/endpoint")!
            let (_, _) = try await URLSession.shared.data(from: url)

            DispatchQueue.main.async {
                viewerState.stopLoadingRotation()
            }
        } catch {
            DispatchQueue.main.async {
                viewerState.stopLoadingRotation()
            }
        }
    }

    var body: some View {
        VStack {
            ZStack {
                Button(action: {
                    viewerState.rotateModel()
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
                                color: .white.opacity(0.5),
                                radius: 10,
                                x: 0,
                                y: 0
                            )

                        if isLoading {
                            ProgressView()
                                .progressViewStyle(
                                    CircularProgressViewStyle(tint: .white)
                                )
                                .scaleEffect(1.5)
                        } else {
                            Image(systemName: systemName)
                                .font(.system(size: 30))
                                .foregroundColor(.white)
                                .opacity(isAnimating ? 1 : 0.7)
                        }
                    }
                }
                .disabled(isLoading)
            }

            Text(label)
                .font(.caption)
                .foregroundColor(.white)
                .padding(.top, 4)
        }
        .padding()
        .onAppear {
            isAnimating = true
            withAnimation(
                Animation.easeInOut(duration: 2).repeatForever(
                    autoreverses: true)
            ) {
                pulseScale = 1.2
            }
        }
    }
}
