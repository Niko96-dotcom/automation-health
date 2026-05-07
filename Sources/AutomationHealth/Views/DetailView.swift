import AppKit
import SwiftUI
import ActiveJobsCore

struct DetailView: View {
    let job: JobPresentation?
    let errorMessage: String?

    var body: some View {
        Group {
            if let job {
                JobDetailContent(job: job)
            } else {
                EmptySelectionView(errorMessage: errorMessage)
            }
        }
    }
}

private struct JobDetailContent: View {
    let job: JobPresentation

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
                    text: job.job.definition.isEmpty ? "No definition text found." : job.job.definition,
                    monospaced: false
                )

                TextSection(
                    title: "What Happened Last Time",
                    systemImage: "waveform.path.ecg",
                    text: job.job.lastRunDetails ?? "No run output or log file found yet.",
                    monospaced: true
                )
            }
            .padding(.horizontal, 28)
            .padding(.vertical, 24)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top, spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(.tint.opacity(0.12))
                    Image(systemName: job.job.source == .hermesCron ? "calendar.badge.clock" : "gearshape.2")
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

                HealthPill(health: job.health)
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

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(title, systemImage: systemImage)
                .font(.headline)

            Text(text)
                .font(monospaced ? .system(.callout, design: .monospaced) : .callout)
                .textSelection(.enabled)
                .lineSpacing(monospaced ? 2 : 3)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(16)
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 8))
        }
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
                        Label("Reveal", systemImage: "magnifyingglass")
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
            Label("No Job Selected", systemImage: "calendar.badge.exclamationmark")
        } description: {
            if let errorMessage {
                Text(errorMessage)
            } else {
                Text("Refresh to scan launchd and Hermes cron jobs.")
            }
        }
    }
}
