import SwiftUI
import ActiveJobsCore

struct SidebarView: View {
    let jobs: [JobPresentation]
    @Binding var selectedJobID: String?
    let lastScannedDescription: String
    let isScanning: Bool

    private var statusSummary: String {
        let healths = jobs.map { $0.health.kind }
        let healthy = healths.filter { $0 == .alive }.count
        let attention = healths.filter { $0 == .failed || $0 == .stale }.count

        if attention > 0 {
            return "\(healthy) healthy • \(attention) need attention"
        }

        return "\(healthy) healthy"
    }

    var body: some View {
        VStack(spacing: 0) {
            List(selection: $selectedJobID) {
                Section {
                    ForEach(jobs) { job in
                        SidebarJobRow(job: job)
                            .tag(job.id)
                    }
                } header: {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("\(jobs.count) automations")
                        Text(statusSummary)
                            .font(.caption2)
                            .textCase(nil)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .listStyle(.sidebar)

            Divider()

            HStack(spacing: 8) {
                if isScanning {
                    ProgressView()
                        .controlSize(.small)
                } else {
                    Image(systemName: "clock.arrow.circlepath")
                        .foregroundStyle(.secondary)
                }

                Text(lastScannedDescription)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)

                Spacer()
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
        }
    }
}

private struct SidebarJobRow: View {
    let job: JobPresentation

    var body: some View {
        HStack(spacing: 10) {
            HealthDot(kind: job.health.kind)

            VStack(alignment: .leading, spacing: 2) {
                Text(job.displayName)
                    .lineLimit(1)

                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
        }
        .padding(.vertical, 2)
    }

    private var subtitle: String {
        if job.job.nextRun != nil {
            return "\(job.sourceName) • \(job.nextRunText)"
        }
        return "\(job.sourceName) • \(job.scheduleText)"
    }
}

struct HealthDot: View {
    let kind: JobHealthKind

    var body: some View {
        Circle()
            .fill(color)
            .frame(width: 9, height: 9)
            .overlay {
                Circle()
                    .stroke(.primary.opacity(0.12), lineWidth: 1)
            }
            .frame(width: 16)
            .help(helpText)
    }

    private var color: Color {
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

    private var helpText: String {
        switch kind {
        case .alive:
            "Alive"
        case .waiting:
            "Waiting for first run"
        case .stale:
            "Stale"
        case .failed:
            "Needs attention"
        case .unknown:
            "Unknown"
        }
    }
}
