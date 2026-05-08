import SwiftUI
import ActiveJobsCore

struct SidebarView: View {
    let sections: [SidebarJobSection]
    @Binding var selectedJobID: String?
    let lastScannedDescription: String
    let isScanning: Bool

    private var visibleJobs: [SidebarJobSummary] {
        sections.flatMap(\.jobs)
    }

    private var statusSummary: String {
        let healths = visibleJobs.map(\.healthKind)
        let healthy = healths.filter { $0 == .alive }.count
        let attention = healths.filter { $0 == .failed || $0 == .stale }.count

        if attention > 0 {
            return "\(healthy) healthy • \(attention) need attention"
        }

        return "\(healthy) healthy"
    }

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 2) {
                    SidebarHeader(
                        jobCount: visibleJobs.count,
                        statusSummary: statusSummary
                    )
                    .padding(.horizontal, 8)
                    .padding(.bottom, 4)

                    ForEach(sections) { section in
                        SourceSectionHeader(section: section)

                        ForEach(section.jobs) { job in
                            SidebarJobRow(
                                job: job,
                                isSelected: selectedJobID == job.id
                            ) {
                                selectedJobID = job.id
                            }
                                .equatable()
                        }
                    }
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 10)
            }
            .scrollContentBackground(.hidden)
            .background(.regularMaterial)

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

private struct SidebarHeader: View {
    let jobCount: Int
    let statusSummary: String

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("\(jobCount) automations")
                .font(.caption)
                .fontWeight(.medium)
                .foregroundStyle(.secondary)
            Text(statusSummary)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct SourceSectionHeader: View {
    let section: SidebarJobSection

    var body: some View {
        Text("\(section.title) (\(section.visibleCount))")
            .font(.system(size: 11, weight: .semibold))
            .foregroundStyle(.secondary)
            .lineLimit(1)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
    }
}

private struct SidebarJobRow: View, Equatable {
    let job: SidebarJobSummary
    let isSelected: Bool
    let select: () -> Void

    var body: some View {
        Button(action: select) {
            HStack(spacing: 10) {
                HealthDot(kind: job.healthKind)

                VStack(alignment: .leading, spacing: 2) {
                    Text(job.displayName)
                        .foregroundStyle(.primary)
                        .lineLimit(1)

                    Text(job.subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }

                Spacer(minLength: 0)
            }
            .padding(.horizontal, 8)
            .frame(maxWidth: .infinity, minHeight: 38, alignment: .leading)
            .contentShape(Rectangle())
            .background(selectionBackground, in: RoundedRectangle(cornerRadius: 6))
        }
        .buttonStyle(.plain)
    }

    private var selectionBackground: Color {
        isSelected ? Color.accentColor.opacity(0.18) : .clear
    }

    nonisolated static func == (lhs: SidebarJobRow, rhs: SidebarJobRow) -> Bool {
        lhs.job == rhs.job && lhs.isSelected == rhs.isSelected
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
