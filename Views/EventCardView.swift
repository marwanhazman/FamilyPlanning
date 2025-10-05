// Views/EventCardView.swift
import SwiftUI

struct EventCardView: View {
    let event: Event
    let person: Person
    let responsiblePerson: Person
    @ObservedObject var dataManager: EventDataManager
    @State private var showingEditEvent = false
    
    var body: some View {
        HStack {
            // Color indicator with recurring icon
            VStack {
                if event.isRecurring {
                    Image(systemName: "repeat.circle.fill")
                        .font(.caption)
                        .foregroundColor(.blue)
                } else {
                    Rectangle()
                        .fill(person.color.color)
                        .frame(width: 4)
                        .cornerRadius(2)
                }
            }
            .frame(width: 20)
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Circle()
                        .fill(person.color.color)
                        .frame(width: 12, height: 12)
                    
                    Text(person.name)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    Text(event.timeString)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Button(action: { showingEditEvent = true }) {
                        Image(systemName: "pencil")
                            .font(.caption)
                            .foregroundColor(.blue)
                    }
                }
                
                HStack {
                    Text(event.eventName)
                        .font(.subheadline)
                        .foregroundColor(.primary)
                    
                    if event.isRecurring {
                        Image(systemName: "repeat")
                            .font(.caption2)
                            .foregroundColor(.blue)
                    }
                }
                
                HStack {
                    Image(systemName: "person.fill")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    
                    Text("Responsible: \(responsiblePerson.name)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    if event.isRecurring {
                        Text("• Weekly")
                            .font(.caption)
                            .foregroundColor(.blue)
                    }
                }
            }
            .padding(.vertical, 8)
            
            Spacer()
        }
        .padding(.horizontal, 12)
        .background(Color(.systemBackground))
        .cornerRadius(8)
        .shadow(color: .gray.opacity(0.2), radius: 2, x: 0, y: 1)
        .sheet(isPresented: $showingEditEvent) {
            EditEventView(dataManager: dataManager, event: event)
        }
    }
}
