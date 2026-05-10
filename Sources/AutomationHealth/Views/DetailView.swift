import AppKit
import SwiftUI
import ActiveJobsCore
import AutomationHealthCore

struct DetailView: View {
    let job: JobPresentation?
    let errorMessage: String?
    let onEditManualRecord: (JobPresentation) -> Void
    let onRemoveManualRecord: (JobPresentation) -> Void

    var body: some View {
        Group {
            if let job {
                JobDetailContent(
                    job: job,
                    onEditManualRecord: onEditManualRecord,
                    onRemoveManualRecord: onRemoveManualRecord
                )
            } else {
                EmptySelectionView(errorMessage: errorMessage)
            }
        }
    }
}

private struct JobDetailContent: View {
    let job: JobPresentation
    let onEditManualRecord: (JobPresentation) -> Void
    let onRemoveManualRecord: (JobPresentation) -> Void
    @State private var showsRemoveConfirmation = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                header

                StatusOverview(job: job)

                if let command = job.job.command {
                    DisclosureGroup {
                        TechnicalDetails(job: job, command: command)
                    } label: {
                        Label("Technical Details", systemImage: "wrench.and.screwdriver")
                            .font(.headline)
                    }
                    .padding(.top, 4)
                }

                TextSection(
                    title: "Configured Task",
                    systemImage: "text.alignleft",
                    text: job.definitionText,
                    monospaced: false
                )

                TextSection(
                    title: "What Happened Last Time",
                    systemImage: "waveform.path.ecg",
                    text: job.lastOutputText,
                    monospaced: true
                )
            }
            .padding(.horizontal, 28)
            .padding(.vertical, 24)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .confirmationDialog(
            "Remove Manual Record?",
            isPresented: $showsRemoveConfirmation,
            titleVisibility: .visible
        ) {
            Button("Remove Manual Record", role: .destructive) {
                onRemoveManualRecord(job)
            }

            Button("Keep Manual Record", role: .cancel) {}
        } message: {
            Text("This removes the app-only record from Automation Health. Scheduler files, scripts, Shortcuts, Automator workflows, cron entries, launchd plists, and Hermes metadata are not changed.")
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top, spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(.tint.opacity(0.12))
                    Image(systemName: job.sourceIconName)
                        .font(.title3)
                        .foregroundStyle(.tint)
                }
                .frame(width: 42, height: 42)

                VStack(alignment: .leading, spacing: 4) {
                    Text(job.displayName)
                        .font(.title)
                        .fontWeight(.semibold)
                        .textSelection(.enabled)

                    Text(job.job.name)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .textSelection(.enabled)
                }

                Spacer(minLength: 16)

                VStack(alignment: .trailing, spacing: 8) {
                    HealthPill(health: job.health)

                    if job.job.source == .manualRecords {
                        HStack(spacing: 8) {
                            Button {
                                onEditManualRecord(job)
                            } label: {
                                Label("Edit Manual Record", systemImage: "square.and.pencil")
                            }

                            Button(role: .destructive) {
                                showsRemoveConfirmation = true
                            } label: {
                                Label("Remove Manual Record", systemImage: "trash")
                            }
                        }
                        .controlSize(.small)
                    }
                }
            }
        }
    }
}

private struct StatusOverview: View {
    let job: JobPresentation

    var body: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 190), spacing: 12)], alignment: .leading, spacing: 12) {
            StatusCard(
                title: "Health",
                value: job.health.label,
                detail: job.health.detail,
                systemImage: "heart.text.square",
                tint: color(for: job.health.kind)
            )

            StatusCard(
                title: "Confidence",
                value: job.confidenceName,
                detail: job.job.confidence.description,
                systemImage: "checkmark.seal",
                tint: .green
            )

            StatusCard(
                title: "Origin",
                value: job.originName,
                detail: "Source-independent ownership/origin",
                systemImage: "person.crop.circle.badge.questionmark",
                tint: .indigo
            )

            StatusCard(
                title: "Next Run",
                value: job.nextRunText,
                detail: job.scheduleText,
                systemImage: "calendar.badge.clock",
                tint: .blue
            )

            StatusCard(
                title: "Last Run",
                value: job.lastRunText,
                detail: job.job.lastStatus.map { "Finished with \($0)" } ?? "No result code",
                systemImage: "clock.arrow.circlepath",
                tint: .teal
            )

            StatusCard(
                title: "Source",
                value: job.sourceName,
                detail: job.job.state,
                systemImage: "shippingbox",
                tint: .purple
            )
        }
    }

    private func color(for kind: JobHealthKind) -> Color {
        switch kind {
        case .alive:
            .green
        case .waiting:
            .blue
        case .stale:
            .orange
        case .failed:
            .red
        case .unknown:
            .gray
        }
    }
}

private struct StatusCard: View {
    let title: String
    let value: String
    let detail: String
    let systemImage: String
    let tint: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 7) {
                Image(systemName: systemImage)
                    .foregroundStyle(tint)
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Text(value)
                .font(.headline)
                .lineLimit(2)
                .textSelection(.enabled)

            Text(detail)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(2)
        }
        .padding(14)
        .frame(maxWidth: .infinity, minHeight: 118, alignment: .topLeading)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 8))
    }
}

private struct TextSection: View {
    let title: String
    let systemImage: String
    let text: String
    var monospaced = false
    private let maximumAccessibilityCharacters = 800

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(title, systemImage: systemImage)
                .font(.headline)

            if monospaced {
                ReadOnlyLogTextView(text: text)
                    .frame(maxWidth: .infinity, minHeight: 180, idealHeight: 260, maxHeight: 320)
                    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 8))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .accessibilityLabel(accessibilityText)
            } else {
                Text(text)
                    .font(.callout)
                    .textSelection(.enabled)
                    .lineSpacing(3)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(16)
                    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 8))
                    .accessibilityLabel(accessibilityText)
            }
        }
    }

    private var accessibilityText: String {
        guard text.count > maximumAccessibilityCharacters else {
            return text
        }

        let preview = String(text.prefix(maximumAccessibilityCharacters))
        return "\(title): \(preview)..."
    }
}

private struct ReadOnlyLogTextView: NSViewRepresentable {
    let text: String

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeNSView(context: Context) -> NSScrollView {
        let scrollView = NSScrollView()
        scrollView.drawsBackground = false
        scrollView.hasVerticalScroller = true
        scrollView.borderType = .noBorder

        let textView = NSTextView()
        textView.isEditable = false
        textView.isSelectable = true
        textView.drawsBackground = false
        textView.font = .monospacedSystemFont(ofSize: 12, weight: .regular)
        textView.textColor = .labelColor
        textView.textContainerInset = NSSize(width: 12, height: 10)
        textView.isHorizontallyResizable = false
        textView.isVerticallyResizable = true
        textView.textContainer?.widthTracksTextView = true
        textView.textContainer?.containerSize = NSSize(
            width: scrollView.contentSize.width,
            height: .greatestFiniteMagnitude
        )

        scrollView.documentView = textView
        context.coordinator.textView = textView
        return scrollView
    }

    func updateNSView(_ scrollView: NSScrollView, context: Context) {
        guard let textView = context.coordinator.textView ?? scrollView.documentView as? NSTextView else {
            return
        }

        if textView.string != text {
            textView.string = text
            textView.scrollToBeginningOfDocument(nil)
        }

        textView.font = .monospacedSystemFont(ofSize: 12, weight: .regular)
        textView.textColor = .labelColor
    }

    final class Coordinator {
        weak var textView: NSTextView?
    }
}

private struct HealthPill: View {
    let health: JobHealth

    var body: some View {
        HStack(spacing: 7) {
            HealthDot(kind: health.kind)
            Text(health.label)
                .font(.callout)
                .fontWeight(.medium)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 7)
        .background(.regularMaterial, in: Capsule())
        .help(health.detail)
    }
}

private struct TechnicalDetails: View {
    let job: JobPresentation
    let command: String

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            DetailLine(label: "Command", value: command, monospaced: true)
            DetailLine(label: "Raw schedule", value: job.job.schedule, monospaced: true)
            DetailLine(label: "Raw state", value: job.job.state, monospaced: false)
            if let detailPath = job.job.detailPath {
                HStack(alignment: .firstTextBaseline, spacing: 12) {
                    DetailLine(label: "Output path", value: detailPath, monospaced: true)
                    Button {
                        NSWorkspace.shared.activateFileViewerSelecting([URL(fileURLWithPath: detailPath)])
                    } label: {
                        Label(job.revealActionLabel, systemImage: "magnifyingglass")
                    }
                    .controlSize(.small)
                }
            }
        }
        .padding(14)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 8))
    }
}

private struct DetailLine: View {
    let label: String
    let value: String
    let monospaced: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(monospaced ? .system(.callout, design: .monospaced) : .callout)
                .textSelection(.enabled)
        }
    }
}

private struct EmptySelectionView: View {
    let errorMessage: String?

    var body: some View {
        ContentUnavailableView {
            Label("No automation records yet", systemImage: "calendar.badge.exclamationmark")
        } description: {
            if let errorMessage {
                Text("Inventory scan failed. Review scan notes, confirm local permissions, then rescan. \(errorMessage)")
            } else {
                Text("Rescan supported inventory or add a manual record for an automation the scanner cannot prove.")
            }
        }
    }
}
