// Views/EditEventView.swift
import SwiftUI

struct EditEventView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var dataManager: EventDataManager
    var event: Event?
    
    @State private var selectedPersonId: String?
    @State private var eventName = ""
    @State private var eventDate = Date()
    @State private var selectedResponsiblePersonId: String?
    @State private var selectedDays: Set<Int> = []
    
    private let daysOfWeek = Calendar.current.weekdaySymbols
    
    init(dataManager: EventDataManager, event: Event? = nil) {
        self.dataManager = dataManager
        self.event = event
        
        if let event = event {
            _selectedPersonId = State(initialValue: event.personId)
            _eventName = State(initialValue: event.eventName)
            _eventDate = State(initialValue: event.date)
            _selectedResponsiblePersonId = State(initialValue: event.responsiblePersonId)
            _selectedDays = State(initialValue: [event.dayOfWeek])
        }
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Event Details")) {
                    Picker("Family Member", selection: $selectedPersonId) {
                        Text("Select a person").tag(nil as String?)
                        ForEach(dataManager.familyMembers()) { person in
                            HStack {
                                Circle()
                                    .fill(person.color.color)
                                    .frame(width: 12, height: 12)
                                Text(person.name)
                            }
                            .tag(person.id as String?)
                        }
                    }
                    
                    TextField("Event Name", text: $eventName)
                    
                    DatePicker("Time", selection: $eventDate, displayedComponents: .hourAndMinute)
                    
                    Picker("Responsible Parent", selection: $selectedResponsiblePersonId) {
                        Text("Select responsible parent").tag(nil as String?)
                        ForEach(dataManager.parents()) { parent in
                            Text(parent.name).tag(parent.id as String?)
                        }
                    }
                }
                
                Section(header: Text("Recurring Days (Weekly)")) {
                    ForEach(1...7, id: \.self) { day in
                        HStack {
                            Text(daysOfWeek[day - 1])
                            Spacer()
                            Image(systemName: selectedDays.contains(day) ? "checkmark.circle.fill" : "circle")
                                .foregroundColor(selectedDays.contains(day) ? .blue : .gray)
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            if selectedDays.contains(day) {
                                selectedDays.remove(day)
                            } else {
                                selectedDays.insert(day)
                            }
                        }
                    }
                }
                
                if let event = event {
                    Section {
                        Button("Delete Event", role: .destructive) {
                            dataManager.removeEvent(event)
                            dismiss()
                        }
                    }
                }
            }
            .navigationTitle(event == nil ? "Add Event" : "Edit Event")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(event == nil ? "Add" : "Save") {
                        saveEvent()
                    }
                    .disabled(!isFormValid)
                }
            }
        }
    }
    
    private var isFormValid: Bool {
        !eventName.isEmpty &&
        selectedPersonId != nil &&
        selectedResponsiblePersonId != nil &&
        !selectedDays.isEmpty
    }
    
    private func saveEvent() {
        guard let personId = selectedPersonId,
              let responsiblePersonId = selectedResponsiblePersonId else { return }
        
        if let existingEvent = event {
            // Update existing event - for simplicity, we'll remove and recreate
            dataManager.removeEvent(existingEvent)
        }
        
        // Create one event for each selected day (all recurring by default)
        for day in selectedDays {
            let calendar = Calendar.current
            var components = calendar.dateComponents([.hour, .minute], from: eventDate)
            components.weekday = day
            
            if let date = calendar.nextDate(after: Date(), matching: components, matchingPolicy: .nextTime) {
                let event = Event(
                    personId: personId,
                    eventName: eventName,
                    date: date,
                    responsiblePersonId: responsiblePersonId,
                    userId: ""
                )
                dataManager.addEvent(event)
            }
        }
        
        dismiss()
    }
}
