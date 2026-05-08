import SwiftUI
import ActiveJobsCore

private enum SidebarFocusTarget: Hashable {
    case jobList
}

struct SidebarView: View {
    let sections: [SidebarJobSection]
    let showsFilteredEmptyState: Bool
    @Binding var selectedJobID: String?
    let lastScannedDescription: String
    let isScanning: Bool
    @State private var keyboardNavigationTargetID: String?
    @FocusState private var focusedTarget: SidebarFocusTarget?

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
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 2) {
                        SidebarHeader(
                            jobCount: visibleJobs.count,
                            statusSummary: statusSummary
                        )
                        .padding(.horizontal, 8)
                        .padding(.bottom, 4)

                        if showsFilteredEmptyState {
                            FilteredSidebarEmptyState()
                        }

                        ForEach(sections) { section in
                            SourceSectionHeader(section: section)

                            ForEach(section.jobs) { job in
                                SidebarJobRow(
                                    job: job,
                                    isSelected: selectedJobID == job.id
                                ) {
                                    select(job)
                                }
                                .equatable()
                                .id(job.id)
                            }
                        }
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 10)
                }
                .scrollContentBackground(.hidden)
                .background(.regularMaterial)
                .accessibilityLabel("Automation list")
                .focusable()
                .focused($focusedTarget, equals: .jobList)
                .onKeyPress(.downArrow) { navigate(.next) }
                .onKeyPress(.upArrow) { navigate(.previous) }
                .onChange(of: keyboardNavigationTargetID) { _, targetID in
                    guard let targetID else {
                        return
                    }

                    proxy.scrollTo(targetID, anchor: nil)
                    keyboardNavigationTargetID = nil
                }
            }

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

    private func select(_ job: SidebarJobSummary) {
        selectedJobID = job.id
        focusedTarget = .jobList
    }

    private func navigate(_ direction: SidebarNavigationDirection) -> KeyPress.Result {
        guard focusedTarget == .jobList else {
            return .ignored
        }

        guard let targetID = SidebarNavigation.targetJobID(in: visibleJobs, selectedJobID: selectedJobID, direction: direction) else {
            return .ignored
        }

        keyboardNavigationTargetID = targetID

        if targetID == selectedJobID {
            return .handled
        }

        selectedJobID = targetID
        return .handled
    }
}

private struct FilteredSidebarEmptyState: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("No matching automations")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(.primary)

            Text("Try a different search.")
                .font(.system(size: 12))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 8)
        .padding(.vertical, 24)
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
        VStack(alignment: .leading, spacing: 4) {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text(section.title)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)

                Spacer(minLength: 8)

                Text("\(section.visibleCount)")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .monospacedDigit()
            }

            Divider()
                .opacity(0.35)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
    }
}

private struct SidebarJobRow: View, Equatable {
    let job: SidebarJobSummary
    let isSelected: Bool
    let select: () -> Void
    @State private var isHovered = false

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
            .background(rowBackground, in: RoundedRectangle(cornerRadius: 6))
        }
        .buttonStyle(.plain)
        .onHover { isHovered = $0 }
    }

    private var rowBackground: Color {
        if isSelected {
            return Color.accentColor.opacity(0.18)
        }

        return isHovered ? Color.primary.opacity(0.06) : .clear
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
