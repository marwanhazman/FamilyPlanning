// Views/ParentView.swift
import SwiftUI

struct ParentView: View {
    @ObservedObject var dataManager: EventDataManager
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                ForEach(dataManager.parents()) { parent in
                    ParentEventsView(dataManager: dataManager, parent: parent)
                }
            }
            .padding()
        }
    }
}

struct ParentEventsView: View {
    @ObservedObject var dataManager: EventDataManager
    let parent: Person
    @State private var showingEditParent = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Parent header with edit button
            HStack {
                Circle()
                    .fill(parent.color.color)
                    .frame(width: 20, height: 20)
                
                Text(parent.name)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Text("\(parentEvents.count) responsibilities")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Button(action: { showingEditParent = true }) {
                    Image(systemName: "pencil")
                        .font(.caption)
                        .foregroundColor(.blue)
                }
            }
            
            // Events this parent is responsible for
            if parentEvents.isEmpty {
                Text("No responsibilities scheduled")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.leading, 28)
            } else {
                ForEach(parentEvents) { event in
                    if let person = dataManager.getPerson(by: event.personId) {
                        ParentEventRowView(
                            event: event,
                            person: person,
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
        .sheet(isPresented: $showingEditParent) {
            EditPersonView(dataManager: dataManager, person: parent)
        }
    }
    
    private var parentEvents: [Event] {
        dataManager.eventsForParent(parent.id)
    }
}

struct ParentEventRowView: View {
    let event: Event
    let person: Person
    @ObservedObject var dataManager: EventDataManager
    @State private var showingEditEvent = false
    
    var body: some View {
        HStack {
            Circle()
                .fill(person.color.color)
                .frame(width: 12, height: 12)
            
            Text(person.name)
                .font(.subheadline)
                .foregroundColor(.primary)
                .frame(width: 80, alignment: .leading)
            
            VStack(alignment: .leading) {
                Text(event.eventName)
                    .font(.subheadline)
                    .foregroundColor(.primary)
                
                Text(event.timeString)
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
