import SwiftUI
import AVFoundation

/// Audio recorder view using AVAudioRecorder
struct AudioRecorderView: View {
    let onRecordingComplete: (URL) -> Void

    @StateObject private var recorder = AudioRecorder()
    @State private var showPermissionAlert: Bool = false

    var body: some View {
        VStack(spacing: 24) {
            // Waveform visualization (simplified)
            if recorder.isRecording {
                WaveformView(amplitude: recorder.currentAmplitude)
                    .frame(height: 100)
            } else {
                Image(systemName: "waveform")
                    .font(.system(size: 64))
                    .foregroundColor(.gray.opacity(0.3))
                    .frame(height: 100)
            }

            // Timer
            Text(recorder.formattedDuration)
                .font(.system(.title, design: .monospaced))
                .foregroundColor(recorder.isRecording ? .red : .primary)

            // Controls
            HStack(spacing: 48) {
                // Record/Stop button
                Button(action: {
                    if recorder.isRecording {
                        recorder.stopRecording()
                        if let url = recorder.recordingURL {
                            onRecordingComplete(url)
                        }
                    } else {
                        Task {
                            let hasPermission = await recorder.requestPermission()
                            if hasPermission {
                                recorder.startRecording()
                            } else {
                                showPermissionAlert = true
                            }
                        }
                    }
                }) {
                    Image(systemName: recorder.isRecording ? "stop.circle.fill" : "record.circle")
                        .font(.system(size: 64))
                        .foregroundColor(recorder.isRecording ? .red : .orange)
                }

                // Cancel button (only when recording)
                if recorder.isRecording {
                    Button(action: {
                        recorder.cancelRecording()
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 48))
                            .foregroundColor(.gray)
                    }
                }
            }

            // Instructions
            Text(recorder.isRecording ? "Tap stop when finished" : "Tap to start recording")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .alert("Microphone Permission Required", isPresented: $showPermissionAlert) {
            Button("Settings", action: {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            })
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Please enable microphone access in Settings to record audio notes.")
        }
    }
}

// MARK: - Audio Recorder

class AudioRecorder: NSObject, ObservableObject, AVAudioRecorderDelegate {

    @Published var isRecording: Bool = false
    @Published var currentAmplitude: CGFloat = 0.0
    @Published var recordingDuration: TimeInterval = 0.0

    private var audioRecorder: AVAudioRecorder?
    private var amplitudeTimer: Timer?
    private(set) var recordingURL: URL?

    var formattedDuration: String {
        let minutes = Int(recordingDuration) / 60
        let seconds = Int(recordingDuration) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    // MARK: - Permission

    func requestPermission() async -> Bool {
        return await withCheckedContinuation { continuation in
            AVAudioSession.sharedInstance().requestRecordPermission { granted in
                continuation.resume(returning: granted)
            }
        }
    }

    // MARK: - Recording

    func startRecording() {
        let audioSession = AVAudioSession.sharedInstance()

        do {
            try audioSession.setCategory(.playAndRecord, mode: .default)
            try audioSession.setActive(true)

            // Create recording URL
            let fileName = "recording_\(UUID().uuidString).m4a"
            let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)

            // Configure recorder
            let settings: [String: Any] = [
                AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
                AVSampleRateKey: 44100.0,
                AVNumberOfChannelsKey: 1,
                AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
            ]

            audioRecorder = try AVAudioRecorder(url: tempURL, settings: settings)
            audioRecorder?.delegate = self
            audioRecorder?.isMeteringEnabled = true
            audioRecorder?.record()

            recordingURL = tempURL
            isRecording = true
            recordingDuration = 0.0

            // Start amplitude monitoring
            startAmplitudeMonitoring()

        } catch {
            print("Failed to start recording: \(error)")
        }
    }

    func stopRecording() {
        audioRecorder?.stop()
        amplitudeTimer?.invalidate()
        isRecording = false

        do {
            try AVAudioSession.sharedInstance().setActive(false)
        } catch {
            print("Failed to deactivate audio session: \(error)")
        }
    }

    func cancelRecording() {
        audioRecorder?.stop()
        amplitudeTimer?.invalidate()
        isRecording = false
        recordingURL = nil

        do {
            try AVAudioSession.sharedInstance().setActive(false)
        } catch {
            print("Failed to deactivate audio session: \(error)")
        }
    }

    // MARK: - Amplitude Monitoring

    private func startAmplitudeMonitoring() {
        amplitudeTimer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { [weak self] _ in
            guard let self = self, let recorder = self.audioRecorder else { return }

            recorder.updateMeters()
            let power = recorder.averagePower(forChannel: 0)

            // Convert dB to 0-1 range
            let minDb: Float = -60.0
            let amplitude = max(0, (power - minDb) / abs(minDb))

            DispatchQueue.main.async {
                self.currentAmplitude = CGFloat(amplitude)
                self.recordingDuration = recorder.currentTime
            }
        }
    }

    // MARK: - AVAudioRecorderDelegate

    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        if !flag {
            recordingURL = nil
        }
    }
}

// MARK: - Waveform View

struct WaveformView: View {
    let amplitude: CGFloat

    var body: some View {
        GeometryReader { geometry in
            HStack(spacing: 4) {
                ForEach(0..<40, id: \.self) { index in
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color.red)
                        .frame(width: 3)
                        .frame(height: waveHeight(for: index, in: geometry.size.height))
                        .animation(.easeInOut(duration: 0.1), value: amplitude)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    private func waveHeight(for index: Int, in maxHeight: CGFloat) -> CGFloat {
        let base: CGFloat = 10
        let variation = sin(Double(index) * 0.5 + Double(amplitude) * 10) * amplitude * maxHeight * 0.5
        return base + variation
    }
}

#Preview("Audio Recorder - Idle") {
    AudioRecorderView { url in
        print("Recording saved: \(url)")
    }
}

#Preview("Waveform - Low Amplitude") {
    WaveformView(amplitude: 0.3)
        .frame(height: 100)
        .padding()
}

#Preview("Waveform - High Amplitude") {
    WaveformView(amplitude: 0.9)
        .frame(height: 100)
        .padding()
}
