import AppKit
import SwiftUI
import ActiveJobsCore
import AutomationHealthCore

struct ContentView: View {
    @ObservedObject var store: JobStore
    @ObservedObject var preferences: PreferencesStore
    @State private var searchText = ""
    @State private var manualRecordSheet: ManualRecordSheetState?

    private var filteredJobs: [JobPresentation] {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !query.isEmpty else {
            return store.jobs
        }

        return store.jobs.filter { $0.searchText.contains(query) }
    }

    private var hasSearchQuery: Bool {
        !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private var showsFilteredEmptyState: Bool {
        hasSearchQuery && filteredJobs.isEmpty
    }

    private var sidebarSections: [SidebarJobSection] {
        SidebarJobSection.sections(
            for: filteredJobs,
            groupingMode: preferences.groupingMode,
            collapseState: preferences.collapseState,
            hasSearchQuery: hasSearchQuery
        )
    }

    var body: some View {
        NavigationSplitView {
            SidebarView(
                sections: sidebarSections,
                showsFilteredEmptyState: showsFilteredEmptyState,
                groupingMode: $preferences.groupingMode,
                collapseState: $preferences.collapseState,
                hasSearchQuery: hasSearchQuery,
                selectedJobID: $store.selectedJobID,
                lastScannedDescription: store.lastScannedDescription,
                scanNotes: store.scanNotes,
                isScanning: store.isScanning,
                sidebarExpandAllOverride: $preferences.sidebarExpandAllOverride,
                requestJobListFocus: $preferences.requestJobListFocus
            )
            .searchable(text: $searchText, placement: .sidebar)
            .navigationSplitViewColumnWidth(min: 280, ideal: 340)
            .onChange(of: preferences.requestSearchFieldFocus) { _, shouldFocus in
                if shouldFocus {
                    focusSearchField()
                    preferences.requestSearchFieldFocus = false
                }
            }
            .onKeyPress(.escape) {
                if !searchText.isEmpty || NSEvent.modifierFlags.isEmpty {
                    searchText = ""
                    preferences.requestJobListFocus = true
                    return .handled
                }
                return .ignored
            }
        } detail: {
            DetailView(
                job: store.selectedJob,
                errorMessage: store.errorMessage,
                onEditManualRecord: openManualRecordEditor,
                onRemoveManualRecord: removeManualRecord
            )
        }
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                Button {
                    manualRecordSheet = .create()
                } label: {
                    Label("Add Manual Record", systemImage: "plus")
                }
                .help("Create an app-only record for an automation the scanner cannot prove.")
                .disabled(manualRecordSheet != nil)

                Button {
                    store.refresh()
                } label: {
                    Label("Rescan Inventory", systemImage: "arrow.clockwise")
                }
                .help("Scan supported automation inventory again.")
                .disabled(store.isScanning)
            }
        }
        .sheet(item: $manualRecordSheet) { sheetState in
            ManualRecordSheetView(
                state: sheetState,
                cancel: { manualRecordSheet = nil },
                submit: { mode, draft in
                    switch mode {
                    case .create:
                        store.addManualRecord(draft)
                    case let .edit(id):
                        store.updateManualRecord(id: id, draft: draft)
                    }
                    manualRecordSheet = nil
                }
            )
        }
    }

    private func focusSearchField() {
        guard let window = NSApp.keyWindow else { return }
        if let searchField = findSearchField(in: window.contentView) {
            window.makeFirstResponder(searchField)
        }
    }

    private func findSearchField(in view: NSView?) -> NSSearchField? {
        guard let view else { return nil }
        if let searchField = view as? NSSearchField {
            return searchField
        }
        for subview in view.subviews {
            if let found = findSearchField(in: subview) {
                return found
            }
        }
        return nil
    }

    private func openManualRecordEditor(_ job: JobPresentation) {
        guard let id = job.manualRecordID else {
            return
        }

        manualRecordSheet = .edit(id: id, job: job)
    }

    private func removeManualRecord(_ job: JobPresentation) {
        guard let id = job.manualRecordID else {
            return
        }

        store.removeManualRecord(id: id)
    }
}

private enum ManualRecordSheetMode: Hashable {
    case create
    case edit(UUID)
}

private struct ManualRecordSheetState: Identifiable, Hashable {
    let id = UUID()
    let mode: ManualRecordSheetMode
    let title: String
    let primaryActionTitle: String
    let secondaryActionTitle: String
    let validationMessage: String
    let name: String
    let origin: JobOrigin
    let scheduleDescription: String
    let command: String
    let notes: String

    static func create() -> ManualRecordSheetState {
        ManualRecordSheetState(
            mode: .create,
            title: "Add Manual Record",
            primaryActionTitle: "Create Manual Record",
            secondaryActionTitle: "Discard Manual Record",
            validationMessage: "Name is required before this manual record can be added.",
            name: "",
            origin: .unknown,
            scheduleDescription: "",
            command: "",
            notes: ""
        )
    }

    static func edit(id: UUID, job: JobPresentation) -> ManualRecordSheetState {
        let fallbackDefinition = "Manual app record: \(job.job.name)"
        let scheduleDescription = job.job.schedule == ScheduledJob.manualDefaultScheduleDescription ? "" : job.job.schedule

        return ManualRecordSheetState(
            mode: .edit(id),
            title: "Edit Manual Record",
            primaryActionTitle: "Update Manual Record",
            secondaryActionTitle: "Discard Changes",
            validationMessage: "Name is required before this manual record can be updated.",
            name: job.job.name,
            origin: job.job.origin,
            scheduleDescription: scheduleDescription,
            command: job.job.command ?? "",
            notes: job.job.definition == fallbackDefinition ? "" : job.job.definition
        )
    }
}

private struct ManualRecordSheetView: View {
    let state: ManualRecordSheetState
    let cancel: () -> Void
    let submit: (ManualRecordSheetMode, ManualRecordDraft) -> Void

    @State private var name: String
    @State private var origin: JobOrigin
    @State private var scheduleDescription: String
    @State private var command: String
    @State private var notes: String

    init(
        state: ManualRecordSheetState,
        cancel: @escaping () -> Void,
        submit: @escaping (ManualRecordSheetMode, ManualRecordDraft) -> Void
    ) {
        self.state = state
        self.cancel = cancel
        self.submit = submit
        _name = State(initialValue: state.name)
        _origin = State(initialValue: state.origin)
        _scheduleDescription = State(initialValue: state.scheduleDescription)
        _command = State(initialValue: state.command)
        _notes = State(initialValue: state.notes)
    }

    private var trimmedName: String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var draft: ManualRecordDraft {
        ManualRecordDraft(
            name: name,
            origin: origin,
            scheduleDescription: scheduleDescription,
            command: command,
            notes: notes
        )
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(state.title)
                .font(.system(size: 18, weight: .semibold))

            Form {
                TextField("Name", text: $name, prompt: Text("Weekly cleanup reminder"))

                Picker("Origin", selection: $origin) {
                    ForEach(JobOrigin.allCases) { origin in
                        Text(origin.displayName).tag(origin)
                    }
                }

                TextField("Schedule description", text: $scheduleDescription, prompt: Text("Every Friday morning"))
                TextField("Command or path", text: $command, prompt: Text("Optional command, app, or file path"))

                LabeledContent("Notes") {
                    TextEditor(text: $notes)
                        .font(.body)
                        .frame(minHeight: 110)
                        .overlay(alignment: .topLeading) {
                            if notes.isEmpty {
                                Text("What this automation does and where you track it")
                                    .foregroundStyle(.tertiary)
                                    .padding(.top, 8)
                                    .padding(.leading, 5)
                                    .allowsHitTesting(false)
                            }
                        }
                }
            }
            .formStyle(.grouped)

            if trimmedName.isEmpty {
                Text(state.validationMessage)
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
            }

            HStack {
                Button(state.secondaryActionTitle, role: .cancel, action: cancel)

                Spacer()

                Button(state.primaryActionTitle) {
                    submit(state.mode, draft)
                }
                .keyboardShortcut(.defaultAction)
                .disabled(trimmedName.isEmpty)
            }
        }
        .padding(24)
        .frame(width: 520)
    }
}
