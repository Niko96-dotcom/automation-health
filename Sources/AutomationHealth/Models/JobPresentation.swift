import Foundation
import ActiveJobsCore

struct JobPresentation: Identifiable, Sendable {
    let job: ScheduledJob
    let id: String
    let displayName: String
    let sourceName: String
    let scheduleText: String
    let lastRunText: String
    let nextRunText: String
    let health: JobHealth
    let searchText: String

    init(job: ScheduledJob, now: Date = Date()) {
        self.job = job
        id = job.selectionID
        displayName = job.displayName
        sourceName = job.source.displayName
        scheduleText = job.humanScheduleDescription
        lastRunText = job.humanLastRunDescription(relativeTo: now)
        nextRunText = job.humanNextRunDescription(relativeTo: now)
        health = job.health(relativeTo: now)
        searchText = [
            job.name,
            job.displayName,
            job.source.displayName,
            job.schedule,
            job.humanScheduleDescription,
            job.command ?? "",
            job.definition
        ].joined(separator: " ").lowercased()
    }
}

struct SidebarJobSummary: Identifiable, Hashable, Sendable {
    let id: String
    let displayName: String
    let subtitle: String
    let healthKind: JobHealthKind

    init(job: JobPresentation, includesSourceName: Bool = true) {
        id = job.id
        displayName = job.displayName
        healthKind = job.health.kind

        let detailText = job.job.nextRun != nil ? job.nextRunText : job.scheduleText
        subtitle = includesSourceName ? "\(job.sourceName) • \(detailText)" : detailText
    }
}

struct SidebarJobSection: Identifiable, Hashable, Sendable {
    let id: JobSource
    let source: JobSource
    let title: String
    let visibleCount: Int
    let jobs: [SidebarJobSummary]

    static func sections(for visibleJobs: [JobPresentation]) -> [SidebarJobSection] {
        JobSource.allCases.compactMap { source in
            let sourceJobs = visibleJobs.filter { $0.job.source == source }
            guard !sourceJobs.isEmpty else {
                return nil
            }

            return SidebarJobSection(
                id: source,
                source: source,
                title: source.displayName,
                visibleCount: sourceJobs.count,
                jobs: sourceJobs.map { SidebarJobSummary(job: $0, includesSourceName: false) }
            )
        }
    }
}
