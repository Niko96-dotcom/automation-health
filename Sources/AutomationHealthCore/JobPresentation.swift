import Foundation
import ActiveJobsCore

public struct JobPresentation: Identifiable, Sendable {
    public let job: ScheduledJob
    public let id: String
    public let displayName: String
    public let sourceName: String
    public let confidenceName: String
    public let originName: String
    public let scheduleText: String
    public let lastRunText: String
    public let nextRunText: String
    public let sourceIconName: String
    public let definitionText: String
    public let lastOutputText: String
    public let revealActionLabel: String
    public let health: JobHealth
    public let searchText: String

    public init(job: ScheduledJob, now: Date = Date()) {
        let definitionText = Self.definitionText(for: job)
        let lastOutputText = Self.lastOutputText(for: job)

        self.job = job
        id = job.selectionID
        displayName = job.displayName
        sourceName = job.source.displayName
        confidenceName = job.confidence.displayName
        originName = job.origin.displayName
        scheduleText = job.humanScheduleDescription
        lastRunText = job.humanLastRunDescription(relativeTo: now)
        nextRunText = job.humanNextRunDescription(relativeTo: now)
        sourceIconName = Self.sourceIconName(for: job.source)
        self.definitionText = definitionText
        self.lastOutputText = lastOutputText
        revealActionLabel = job.source == .candidateScripts ? "Reveal Script" : "Reveal"
        health = job.health(relativeTo: now)
        searchText = [
            job.name,
            job.displayName,
            job.source.displayName,
            job.confidence.displayName,
            job.origin.displayName,
            job.schedule,
            job.humanScheduleDescription,
            job.command ?? "",
            job.definition,
            definitionText,
            job.detailPath ?? ""
        ].joined(separator: " ").lowercased()
    }

    public var manualRecordID: UUID? {
        guard job.source == .manualRecords,
              job.id.hasPrefix("manual-") else {
            return nil
        }

        let rawID = String(job.id.dropFirst("manual-".count))
        return UUID(uuidString: rawID)
    }

    private static func sourceIconName(for source: JobSource) -> String {
        switch source {
        case .launchd:
            "gearshape.2"
        case .hermesCron:
            "calendar.badge.clock"
        case .cron:
            "terminal"
        case .shortcuts:
            "command"
        case .automator:
            "wand.and.stars"
        case .candidateScripts:
            "doc.text.magnifyingglass"
        case .manualRecords:
            "square.and.pencil"
        }
    }

    private static func definitionText(for job: ScheduledJob) -> String {
        if !job.definition.isEmpty {
            return job.definition
        }

        switch job.source {
        case .candidateScripts:
            if let path = job.detailPath ?? job.command {
                return "Candidate script discovered at \(path)."
            }
        case .manualRecords:
            return "Manual app record: \(job.name)"
        default:
            break
        }

        return "No definition text found."
    }

    private static func lastOutputText(for job: ScheduledJob) -> String {
        switch job.source {
        case .candidateScripts:
            return "Candidate records do not include run output until a scheduler source proves execution."
        case .manualRecords:
            return "Manual records do not include run output."
        default:
            return job.lastRunDetails ?? "No run output or log file found yet."
        }
    }
}

public enum SidebarGroupingMode: String, CaseIterable, Identifiable, Sendable, Codable {
    case source
    case origin
    case health
    case trigger
    case confidence
    case schedule

    public static let defaultMode: SidebarGroupingMode = .source

    public var id: String { rawValue }

    public var label: String {
        switch self {
        case .source:
            "Source"
        case .origin:
            "Origin"
        case .health:
            "Health"
        case .trigger:
            "Trigger"
        case .confidence:
            "Confidence"
        case .schedule:
            "Schedule"
        }
    }
}

public enum SidebarTriggerKind: String, CaseIterable, Identifiable, Sendable {
    case timeBased
    case loginKeepAlive
    case fileQueue
    case registeredOnly
    case candidateScripts
    case manualUnspecified

    public var id: String { rawValue }

    public var title: String {
        switch self {
        case .timeBased:
            "Time-based"
        case .loginKeepAlive:
            "Login / Keep Alive"
        case .fileQueue:
            "File / Queue Trigger"
        case .registeredOnly:
            "Registered Only"
        case .candidateScripts:
            "Candidate Scripts"
        case .manualUnspecified:
            "Manual / Unspecified"
        }
    }
}

public enum SidebarScheduleKind: String, CaseIterable, Identifiable, Sendable {
    case morning
    case afternoon
    case evening
    case night
    case hourly
    case daily
    case weekly
    case monthly
    case noScheduleEvidence

    public var id: String { rawValue }

    public var title: String {
        switch self {
        case .morning: "Morning (4 AM – 12 PM)"
        case .afternoon: "Afternoon (12 PM – 6 PM)"
        case .evening: "Evening (6 PM – 10 PM)"
        case .night: "Night (10 PM – 4 AM)"
        case .hourly: "Hourly"
        case .daily: "Daily"
        case .weekly: "Weekly"
        case .monthly: "Monthly"
        case .noScheduleEvidence: "No schedule evidence"
        }
    }
}

public struct SidebarSectionID: Hashable, Sendable, Codable {
    public let groupingMode: SidebarGroupingMode
    public let groupKey: String

    public init(groupingMode: SidebarGroupingMode, groupKey: String) {
        self.groupingMode = groupingMode
        self.groupKey = groupKey
    }
}

public struct SidebarCollapseState: Hashable, Sendable, Codable {
    public private(set) var collapsedSectionIDs: Set<SidebarSectionID>

    public init(collapsedSectionIDs: Set<SidebarSectionID> = []) {
        self.collapsedSectionIDs = collapsedSectionIDs
    }

    public func isCollapsed(_ sectionID: SidebarSectionID) -> Bool {
        collapsedSectionIDs.contains(sectionID)
    }

    public mutating func toggle(_ sectionID: SidebarSectionID) {
        if collapsedSectionIDs.contains(sectionID) {
            collapsedSectionIDs.remove(sectionID)
        } else {
            collapsedSectionIDs.insert(sectionID)
        }
    }

    public func isEffectivelyCollapsed(_ sectionID: SidebarSectionID, hasSearchQuery: Bool) -> Bool {
        !hasSearchQuery && isCollapsed(sectionID)
    }
}

public struct SidebarJobSummary: Identifiable, Hashable, Sendable {
    public let id: String
    public let displayName: String
    public let subtitle: String
    public let healthKind: JobHealthKind
    public let triggerKind: SidebarTriggerKind

    public init(job: JobPresentation, groupingMode: SidebarGroupingMode = .source) {
        id = job.id
        displayName = job.displayName
        healthKind = job.health.kind
        triggerKind = SidebarTriggerClassifier.kind(for: job)

        let detailText = job.job.nextRun != nil ? job.nextRunText : job.scheduleText
        switch groupingMode {
        case .source:
            subtitle = "\(job.confidenceName) - \(detailText)"
        case .origin, .health, .trigger, .schedule:
            subtitle = "\(job.sourceName) - \(job.confidenceName) - \(detailText)"
        case .confidence:
            subtitle = "\(job.sourceName) - \(detailText)"
        }
    }
}

public enum SidebarNavigationDirection: Sendable {
    case previous
    case next
}

public enum SidebarNavigation {
    public static func targetJobID(
        in sections: [SidebarJobSection],
        selectedJobID: String?,
        direction: SidebarNavigationDirection
    ) -> String? {
        let visibleIDs = sections.flatMap(\.jobs).map(\.id)
        guard !visibleIDs.isEmpty else {
            return nil
        }

        if let selectedJobID, let currentIndex = visibleIDs.firstIndex(of: selectedJobID) {
            switch direction {
            case .previous:
                return visibleIDs[max(currentIndex - 1, visibleIDs.startIndex)]
            case .next:
                return visibleIDs[min(currentIndex + 1, visibleIDs.index(before: visibleIDs.endIndex))]
            }
        }

        if let selectedJobID, let contextualTarget = targetFromHiddenSelection(
            in: sections,
            selectedJobID: selectedJobID,
            direction: direction
        ) {
            return contextualTarget
        }

        switch direction {
        case .previous:
            return visibleIDs.last
        case .next:
            return visibleIDs.first
        }
    }

    public static func typeToSelectMatch(
        for prefix: String,
        in sections: [SidebarJobSection]
    ) -> String? {
        let lowercased = prefix.lowercased()
        guard !lowercased.isEmpty else { return nil }

        let allVisible = sections.flatMap(\.jobs)
        return allVisible.first { $0.displayName.lowercased().hasPrefix(lowercased) }?.id
    }

    public static func typeToSelectNextMatch(
        for prefix: String,
        in sections: [SidebarJobSection],
        after currentID: String
    ) -> String? {
        let lowercased = prefix.lowercased()
        guard !lowercased.isEmpty else { return nil }

        let allVisible = sections.flatMap(\.jobs)
        let matchingIDs = allVisible
            .filter { $0.displayName.lowercased().hasPrefix(lowercased) }
            .map(\.id)

        guard !matchingIDs.isEmpty else { return nil }

        if let currentIndex = matchingIDs.firstIndex(of: currentID) {
            let nextIndex = currentIndex + 1
            if nextIndex < matchingIDs.endIndex {
                return matchingIDs[nextIndex]
            }
            return matchingIDs.first
        }

        return matchingIDs.first
    }

    public static func targetJobID(
        in visibleJobs: [SidebarJobSummary],
        selectedJobID: String?,
        direction: SidebarNavigationDirection
    ) -> String? {
        let section = SidebarJobSection(
            id: SidebarSectionID(groupingMode: .source, groupKey: "visible"),
            title: "Visible",
            visibleCount: visibleJobs.count,
            totalCount: visibleJobs.count,
            isPersistentlyCollapsed: false,
            isEffectivelyCollapsed: false,
            isCollapsed: false,
            jobs: visibleJobs,
            allJobs: visibleJobs,
            allJobIDs: visibleJobs.map(\.id)
        )
        return targetJobID(in: [section], selectedJobID: selectedJobID, direction: direction)
    }

    private static func targetFromHiddenSelection(
        in sections: [SidebarJobSection],
        selectedJobID: String,
        direction: SidebarNavigationDirection
    ) -> String? {
        let sectionInfos = sections.enumerated().map { index, section in
            SectionNavigationInfo(
                index: index,
                allJobIDs: section.allJobIDs,
                visibleJobIDs: section.jobs.map(\.id)
            )
        }

        guard let selectedSection = sectionInfos.first(where: { $0.allJobIDs.contains(selectedJobID) }),
              let selectedIndex = selectedSection.allJobIDs.firstIndex(of: selectedJobID) else {
            return nil
        }

        switch direction {
        case .next:
            if let target = selectedSection.allJobIDs[(selectedIndex + 1)...].first(where: { selectedSection.visibleJobIDs.contains($0) }) {
                return target
            }
            return sectionInfos[(selectedSection.index + 1)...].lazy
                .compactMap(\.visibleJobIDs.first)
                .first
        case .previous:
            if selectedIndex > selectedSection.allJobIDs.startIndex {
                let precedingIDs = selectedSection.allJobIDs[..<selectedIndex].reversed()
                if let target = precedingIDs.first(where: { selectedSection.visibleJobIDs.contains($0) }) {
                    return target
                }
            }
            if selectedSection.index > sectionInfos.startIndex {
                return sectionInfos[..<selectedSection.index].reversed().lazy
                    .compactMap(\.visibleJobIDs.last)
                    .first
            }
            return nil
        }
    }

    private struct SectionNavigationInfo {
        let index: Int
        let allJobIDs: [String]
        let visibleJobIDs: [String]
    }
}

public struct SidebarJobSection: Identifiable, Hashable, Sendable {
    public let id: SidebarSectionID
    public let title: String
    public let visibleCount: Int
    public let totalCount: Int
    public let isPersistentlyCollapsed: Bool
    public let isEffectivelyCollapsed: Bool
    public let isCollapsed: Bool
    public let jobs: [SidebarJobSummary]
    public let allJobs: [SidebarJobSummary]
    public let allJobIDs: [String]

    public init(
        id: SidebarSectionID,
        title: String,
        visibleCount: Int,
        totalCount: Int,
        isPersistentlyCollapsed: Bool,
        isEffectivelyCollapsed: Bool,
        isCollapsed: Bool,
        jobs: [SidebarJobSummary],
        allJobs: [SidebarJobSummary],
        allJobIDs: [String]
    ) {
        self.id = id
        self.title = title
        self.visibleCount = visibleCount
        self.totalCount = totalCount
        self.isPersistentlyCollapsed = isPersistentlyCollapsed
        self.isEffectivelyCollapsed = isEffectivelyCollapsed
        self.isCollapsed = isCollapsed
        self.jobs = jobs
        self.allJobs = allJobs
        self.allJobIDs = allJobIDs
    }

    public static func sections(for visibleJobs: [JobPresentation]) -> [SidebarJobSection] {
        sections(
            for: visibleJobs,
            groupingMode: .source,
            collapseState: SidebarCollapseState(),
            hasSearchQuery: false
        )
    }

    public static func sections(
        for visibleJobs: [JobPresentation],
        groupingMode: SidebarGroupingMode,
        collapseState: SidebarCollapseState,
        hasSearchQuery: Bool
    ) -> [SidebarJobSection] {
        groupDefinitions(for: groupingMode).compactMap { definition in
            let groupedJobs = visibleJobs.filter { definition.matches($0) }
            guard !groupedJobs.isEmpty else {
                return nil
            }

            let isCollapsed = collapseState.isEffectivelyCollapsed(definition.id, hasSearchQuery: hasSearchQuery)
            let isPersistentlyCollapsed = collapseState.isCollapsed(definition.id)
            let summaries = groupedJobs.map { SidebarJobSummary(job: $0, groupingMode: groupingMode) }

            return SidebarJobSection(
                id: definition.id,
                title: definition.title,
                visibleCount: groupedJobs.count,
                totalCount: groupedJobs.count,
                isPersistentlyCollapsed: isPersistentlyCollapsed,
                isEffectivelyCollapsed: isCollapsed,
                isCollapsed: isCollapsed,
                jobs: isCollapsed ? [] : summaries,
                allJobs: summaries,
                allJobIDs: summaries.map(\.id)
            )
        }
    }

    private static func groupDefinitions(for groupingMode: SidebarGroupingMode) -> [SidebarGroupDefinition] {
        switch groupingMode {
        case .source:
            return JobSource.allCases.map { source in
                SidebarGroupDefinition(
                    id: SidebarSectionID(groupingMode: groupingMode, groupKey: source.rawValue),
                    title: source.displayName,
                    matches: { $0.job.source == source }
                )
            }
        case .origin:
            return JobOrigin.allCases.map { origin in
                SidebarGroupDefinition(
                    id: SidebarSectionID(groupingMode: groupingMode, groupKey: origin.rawValue),
                    title: origin.displayName,
                    matches: { $0.job.origin == origin }
                )
            }
        case .health:
            return [
                (.failed, "Needs attention"),
                (.stale, "Stale"),
                (.waiting, "Waiting"),
                (.alive, "Alive"),
                (.unknown, "Unknown")
            ].map { kind, title in
                SidebarGroupDefinition(
                    id: SidebarSectionID(groupingMode: groupingMode, groupKey: kind.rawValue),
                    title: title,
                    matches: { $0.health.kind == kind }
                )
            }
        case .trigger:
            return SidebarTriggerKind.allCases.map { trigger in
                SidebarGroupDefinition(
                    id: SidebarSectionID(groupingMode: groupingMode, groupKey: trigger.rawValue),
                    title: trigger.title,
                    matches: { SidebarTriggerClassifier.kind(for: $0) == trigger }
                )
            }
        case .confidence:
            return JobConfidence.allCases.map { confidence in
                SidebarGroupDefinition(
                    id: SidebarSectionID(groupingMode: groupingMode, groupKey: confidence.rawValue),
                    title: confidence.displayName,
                    matches: { $0.job.confidence == confidence }
                )
            }
        case .schedule:
            return SidebarScheduleKind.allCases.map { kind in
                SidebarGroupDefinition(
                    id: SidebarSectionID(groupingMode: groupingMode, groupKey: kind.rawValue),
                    title: kind.title,
                    matches: { SidebarScheduleClassifier.kind(for: $0) == kind }
                )
            }
        }
    }
}

private struct SidebarGroupDefinition {
    let id: SidebarSectionID
    let title: String
    let matches: @Sendable (JobPresentation) -> Bool
}

private enum SidebarTriggerClassifier {
    static func kind(for job: JobPresentation) -> SidebarTriggerKind {
        if job.job.confidence == .candidate || job.job.source == .candidateScripts {
            return .candidateScripts
        }

        if job.job.confidence == .manual || job.job.source == .manualRecords {
            return .manualUnspecified
        }

        let schedule = job.job.schedule.trimmingCharacters(in: .whitespacesAndNewlines)
        let humanSchedule = job.scheduleText.trimmingCharacters(in: .whitespacesAndNewlines)
        let evidenceText = "\(schedule) \(humanSchedule)"
        let lowercasedEvidence = evidenceText.lowercased()

        if job.job.confidence == .registered && !hasDirectScheduleEvidence(job: job, rawSchedule: schedule, humanSchedule: humanSchedule) {
            return .registeredOnly
        }

        if lowercasedEvidence.contains("watch")
            || lowercasedEvidence.contains("watched files")
            || lowercasedEvidence.contains("queue")
            || lowercasedEvidence.contains("files are queued") {
            return .fileQueue
        }

        if lowercasedEvidence.contains("login")
            || lowercasedEvidence.contains("keep alive")
            || lowercasedEvidence.contains("runatload")
            || lowercasedEvidence.contains("stays running") {
            return .loginKeepAlive
        }

        if hasDirectScheduleEvidence(job: job, rawSchedule: schedule, humanSchedule: humanSchedule) {
            return .timeBased
        }

        return .manualUnspecified
    }

    private static func hasDirectScheduleEvidence(job: JobPresentation, rawSchedule: String, humanSchedule: String) -> Bool {
        job.job.nextRun != nil
            || isFiveFieldCron(rawSchedule)
            || isSpecialCronToken(rawSchedule)
            || isClockTime(rawSchedule)
            || beginsWithTimeDescription(humanSchedule)
    }

    private static func isFiveFieldCron(_ value: String) -> Bool {
        let parts = value.split(separator: " ")
        guard parts.count == 5 else {
            return false
        }

        return parts.allSatisfy { part in
            part.allSatisfy { character in
                character.isNumber || ["*", "/", ",", "-", "?"].contains(character)
            }
        }
    }

    private static func isSpecialCronToken(_ value: String) -> Bool {
        let lowercased = value.lowercased()
        return [
            "@annually",
            "@yearly",
            "@monthly",
            "@weekly",
            "@daily",
            "@midnight",
            "@hourly"
        ].contains(lowercased)
    }

    private static func isClockTime(_ value: String) -> Bool {
        value
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .contains { part in
                let pieces = part.split(separator: ":")
                guard pieces.count == 2, let hour = Int(pieces[0]), let minute = Int(pieces[1]) else {
                    return false
                }
                return (0...23).contains(hour) && (0...59).contains(minute)
            }
    }

    private static func beginsWithTimeDescription(_ value: String) -> Bool {
        let lowercased = value.lowercased()
        let weekdayPrefixes = [
            "monday",
            "tuesday",
            "wednesday",
            "thursday",
            "friday",
            "saturday",
            "sunday"
        ]

        return lowercased.hasPrefix("daily")
            || lowercased.hasPrefix("every")
            || lowercased.hasPrefix("monthly")
            || weekdayPrefixes.contains { lowercased.hasPrefix($0) }
    }
}

private enum SidebarScheduleClassifier {
    static func kind(for job: JobPresentation) -> SidebarScheduleKind {
        guard job.job.confidence == .scheduled else {
            return .noScheduleEvidence
        }

        if let nextRun = job.job.nextRun {
            let hour = Calendar.current.component(.hour, from: nextRun)
            if let kind = timeOfDayKind(forHour: hour) {
                return kind
            }
        }

        if let clockHour = firstClockHour(from: job.job.schedule) {
            if let kind = timeOfDayKind(forHour: clockHour) {
                return kind
            }
        }

        let lowercased = job.scheduleText.lowercased()
        if lowercased.contains("every hour") || lowercased.contains("hourly") {
            return .hourly
        }
        if lowercased.contains("every day") || lowercased.contains("daily") {
            return .daily
        }
        if lowercased.contains("every week") || lowercased.contains("weekly") {
            return .weekly
        }
        if lowercased.contains("every month") || lowercased.contains("monthly") {
            return .monthly
        }

        return .noScheduleEvidence
    }

    private static func timeOfDayKind(forHour hour: Int) -> SidebarScheduleKind? {
        switch hour {
        case 4..<12: return .morning
        case 12..<18: return .afternoon
        case 18..<22: return .evening
        default: return .night
        }
    }

    private static func firstClockHour(from schedule: String) -> Int? {
        let pattern = "\\b(\\d{1,2}):(\\d{2})\\b"
        guard let regex = try? NSRegularExpression(pattern: pattern) else {
            return nil
        }
        let range = NSRange(schedule.startIndex..<schedule.endIndex, in: schedule)
        guard let match = regex.firstMatch(in: schedule, range: range),
              match.numberOfRanges > 1,
              let swiftRange = Range(match.range(at: 1), in: schedule)
        else {
            return nil
        }
        let hourString = String(schedule[swiftRange])
        guard let hour = Int(hourString), (0..<24).contains(hour) else {
            return nil
        }
        return hour
    }
}
