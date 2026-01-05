import SwiftUI

/// Main playback view for sets/defense
struct PlaybackView: View {
    @StateObject var viewModel: PlaybackViewModel
    @Environment(\.dismiss) var dismiss

    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                // Header
                headerView

                // Court canvas
                ScrollView([.horizontal, .vertical], showsIndicators: false) {
                    if let currentStep = viewModel.currentStep {
                        CourtCanvasView(
                            step: currentStep,
                            focusPosition: viewModel.focusPosition,
                            canvasSize: CourtGeometry.idealCanvasSize(for: geometry.size.width)
                        )
                        .padding()
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color(uiColor: .systemGroupedBackground))

                // Step info
                stepInfoView

                // Controls
                controlsView
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                VStack(spacing: 2) {
                    Text(viewModel.title)
                        .font(.headline)
                    if let step = viewModel.currentStep {
                        Text(step.label)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
    }

    // MARK: - Header

    var headerView: some View {
        HStack {
            // Notes button
            Button(action: {
                // Show notes sheet
            }) {
                Label("Notes", systemImage: "note.text")
                    .font(.caption)
            }

            Spacer()

            // Film button
            Button(action: {
                // Show film sheet
            }) {
                Label("Film", systemImage: "film")
                    .font(.caption)
            }

            Spacer()

            // Step list button
            Button(action: {
                // Show step list sheet
            }) {
                Label("Steps", systemImage: "list.bullet")
                    .font(.caption)
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(Color(uiColor: .systemBackground))
    }

    // MARK: - Step Info

    var stepInfoView: some View {
        VStack(spacing: 8) {
            if let step = viewModel.currentStep {
                // Step label
                Text(step.label)
                    .font(.headline)

                // Step note (if exists)
                if let note = step.note {
                    Text(note)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color(uiColor: .secondarySystemGroupedBackground))
    }

    // MARK: - Controls

    var controlsView: some View {
        VStack(spacing: 16) {
            // Navigation buttons
            HStack(spacing: 24) {
                Button(action: {
                    viewModel.goToPreviousStep()
                }) {
                    Image(systemName: "chevron.left.circle.fill")
                        .font(.system(size: 48))
                        .foregroundColor(viewModel.canGoPrevious ? .orange : .gray)
                }
                .disabled(!viewModel.canGoPrevious)

                Text("\(viewModel.currentStepIndex + 1) / \(viewModel.steps.count)")
                    .font(.title3.bold())
                    .frame(minWidth: 60)

                Button(action: {
                    viewModel.goToNextStep()
                }) {
                    Image(systemName: "chevron.right.circle.fill")
                        .font(.system(size: 48))
                        .foregroundColor(viewModel.canGoNext ? .orange : .gray)
                }
                .disabled(!viewModel.canGoNext)
            }

            // Focus position selector
            HStack(spacing: 12) {
                Text("Focus:")
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                ForEach(1...5, id: \.self) { position in
                    Button(action: {
                        viewModel.toggleFocus(position: position)
                    }) {
                        Text("\(position)")
                            .font(.headline)
                            .frame(width: 44, height: 44)
                            .background(viewModel.focusPosition == position ? Color.orange : Color.gray.opacity(0.2))
                            .foregroundColor(viewModel.focusPosition == position ? .white : .primary)
                            .clipShape(Circle())
                    }
                }
            }
        }
        .padding()
        .background(Color(uiColor: .systemBackground))
    }
}
