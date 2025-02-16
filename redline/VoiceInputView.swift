import SwiftUI
import AVFoundation
import Speech

struct VoiceInputView: View {
    @ObservedObject var viewerState: ModelViewerState
    @StateObject private var audioRecorder = AudioRecorder()
    @State private var editableText = ""
    @State private var submittedScheduleText = "Schedule a dinner on February 19th from 6:30PM to 7:30PM with my mom"
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var showSuccess = false
    @State private var isAnimating = false
    @State private var pulseScale: CGFloat = 1.0
    @State private var opacity: Double = 0
    @GestureState private var isPressed = false
    
    func submitVoiceInput() async {
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
        editableText = ""
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            viewerState.isShowingVoiceInput = false
        }
    }
    
    var body: some View {
        VStack(spacing: 20) {
            // Glassmorphic TextField
            ZStack {
                RoundedRectangle(cornerRadius: 15)
                    .fill(Color.white.opacity(0.1))
                    .frame(width: 300, height: 60)
                    .blur(radius: 3)
                
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
                
                TextField("Speak or type your message...", text: $editableText)
                    .foregroundColor(.white)
                    .padding(.horizontal)
                    .frame(width: 280)
            }
            .scaleEffect(pulseScale)
            
            HStack(spacing: 40) {
                // Record Button
                ZStack {
                    Circle()
                        .fill(Color.clear)
                        .frame(width: 90, height: 90)
                    
                    Button(action: {
                        print("Button tapped")
                    }) {
                        ZStack {
                            Circle()
                                .stroke(
                                    audioRecorder.isRecording ? Color.red.opacity(0.6) : Color.white.opacity(0.3),
                                    lineWidth: 2
                                )
                                .frame(width: 80, height: 80)
                                .blur(radius: 5)
                            
                            Circle()
                                .stroke(
                                    audioRecorder.isRecording ? Color.red.opacity(0.8) : Color.white.opacity(0.6),
                                    lineWidth: 3
                                )
                                .frame(width: 90, height: 90)
                                .blur(radius: 4)
                                .overlay(
                                    Circle()
                                        .stroke(
                                            LinearGradient(
                                                gradient: Gradient(colors: [
                                                    (audioRecorder.isRecording ? Color.red : Color.white).opacity(0),
                                                    (audioRecorder.isRecording ? Color.red : Color.white).opacity(0.5),
                                                    (audioRecorder.isRecording ? Color.red : Color.white).opacity(0.8),
                                                    (audioRecorder.isRecording ? Color.red : Color.white).opacity(0.5),
                                                    (audioRecorder.isRecording ? Color.red : Color.white).opacity(0),
                                                ]),
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            ),
                                            lineWidth: 3
                                        )
                                )
                            
                            if audioRecorder.isRecording {
                                Circle()
                                    .fill(Color.red)
                                    .frame(width: 12, height: 12)
                                    .offset(x: 30, y: -30)
                                    .opacity(isAnimating ? 1 : 0.5)
                                    .animation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true), value: isAnimating)
                            }
                            
                            VStack(spacing: 4) {
                                Image(systemName: "mic.fill")
                                    .font(.system(size: 30))
                                    .foregroundColor(audioRecorder.isRecording ? .red : .white)
                                    .opacity(isPressed ? 0.4 : 0.8)
                            }
                        }
                    }
                    .simultaneousGesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { _ in
                                if !audioRecorder.isRecording {
                                    audioRecorder.startRecording()
                                }
                            }
                            .onEnded { _ in
                                // Save the current transcribed text before stopping
                                let finalText = audioRecorder.transcribedText
                                audioRecorder.stopRecording()
                                // Update the editableText after a brief delay
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                    editableText = finalText
                                }
                            }
                    )
                }
                
                // Submit Button
                ZStack {
                    Circle()
                        .fill(Color.clear)
                        .frame(width: 90, height: 90)
                    
                    Button(action: {
                        closeView()
                        Task {
                            await submitVoiceInput()
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
                    .disabled(editableText.isEmpty)
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
            withAnimation(.easeIn(duration: 0.3)) {
                opacity = 1
            }
            withAnimation(Animation.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
                isAnimating = true
                pulseScale = 1.02
            }
        }
        .onChange(of: audioRecorder.transcribedText) { newValue in
            // Update editableText while recording
            if audioRecorder.isRecording {
                editableText = newValue
            }
        }
    }
}
