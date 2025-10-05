// Views/PersonView.swift
import SwiftUI

struct PersonView: View {
    @ObservedObject var dataManager: EventDataManager
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                ForEach(dataManager.familyMembers()) { person in
                    PersonEventsView(dataManager: dataManager, person: person)
                }
            }
            .padding()
        }
    }
}

struct PersonEventsView: View {
    @ObservedObject var dataManager: EventDataManager
    let person: Person
    @State private var showingEditPerson = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Person header with edit button
            HStack {
                Circle()
                    .fill(person.color.color)
                    .frame(width: 20, height: 20)
                
                Text(person.name)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Text("\(personEvents.count) events")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Button(action: { showingEditPerson = true }) {
                    Image(systemName: "pencil")
                        .font(.caption)
                        .foregroundColor(.blue)
                }
            }
            
            // Events for this person
            if personEvents.isEmpty {
                Text("No events scheduled")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.leading, 28)
            } else {
                ForEach(personEvents) { event in
                    if let responsiblePerson = dataManager.getPerson(by: event.responsiblePersonId) {
                        EventRowView(
                            event: event,
                            responsiblePerson: responsiblePerson,
                            dataManager: dataManager
                        )
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .gray.opacity(0.2), radius: 2, x: 0, y: 1)
        .sheet(isPresented: $showingEditPerson) {
            EditPersonView(dataManager: dataManager, person: person)
        }
    }
    
    private var personEvents: [Event] {
        dataManager.eventsForPerson(person.id)
    }
}

struct EventRowView: View {
    let event: Event
    let responsiblePerson: Person
    @ObservedObject var dataManager: EventDataManager
    @State private var showingEditEvent = false
    
    var body: some View {
        HStack {
            Text(event.timeString)
                .font(.caption)
                .foregroundColor(.secondary)
                .frame(width: 60, alignment: .leading)
            
            VStack(alignment: .leading) {
                Text(event.eventName)
                    .font(.subheadline)
                    .foregroundColor(.primary)
                
                Text("Responsible: \(responsiblePerson.name)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Text(dayName(for: event.dayOfWeek))
                .font(.caption)
                .padding(6)
                .background(Color.gray.opacity(0.2))
                .cornerRadius(4)
            
            Button(action: { showingEditEvent = true }) {
                Image(systemName: "pencil")
                    .font(.caption)
                    .foregroundColor(.blue)
            }
        }
        .padding(.vertical, 4)
        .sheet(isPresented: $showingEditEvent) {
            EditEventView(dataManager: dataManager, event: event)
        }
    }
    
    private func dayName(for dayNumber: Int) -> String {
        let days = Calendar.current.shortWeekdaySymbols
        return days[dayNumber - 1]
    }
}
