import Foundation
import ActiveJobsCore

struct JobPresentation: Identifiable, Hashable, Sendable {
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
