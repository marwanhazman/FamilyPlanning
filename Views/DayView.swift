// Views/DayView.swift
import SwiftUI

struct DayView: View {
    @ObservedObject var dataManager: EventDataManager
    @Binding var selectedDate: Date
    
    private let daysOfWeek = Calendar.current.shortWeekdaySymbols
    @State private var currentWeek: [Date] = []
    
    var body: some View {
        VStack {
            // Week selector
            HStack {
                ForEach(currentWeek, id: \.self) { date in
                    VStack {
                        Text(daysOfWeek[Calendar.current.component(.weekday, from: date) - 1])
                            .font(.caption)
                        Text("\(Calendar.current.component(.day, from: date))")
                            .font(.headline)
                            .padding(8)
                            .background(Calendar.current.isDate(date, inSameDayAs: selectedDate) ? Color.blue : Color.clear)
                            .foregroundColor(Calendar.current.isDate(date, inSameDayAs: selectedDate) ? .white : .primary)
                            .clipShape(Circle())
                    }
                    .onTapGesture {
                        selectedDate = date
                        print("Selected date: \(selectedDate)")
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .padding()
            .onAppear {
                updateWeek()
            }
            
            // Events for selected day
            let dayEvents = dataManager.eventsForDay(selectedDate)
            
            Text("Events for \(formattedDate(selectedDate)): \(dayEvents.count)")
                .font(.headline)
                .padding(.horizontal)
            
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 12) {
                    if dayEvents.isEmpty {
                        Text("No events for this day")
                            .foregroundColor(.secondary)
                            .padding()
                    } else {
                        ForEach(dayEvents) { event in
                            if let person = dataManager.getPerson(by: event.personId),
                               let responsiblePerson = dataManager.getPerson(by: event.responsiblePersonId) {
                                EventCardView(
                                    event: event,
                                    person: person,
                                    responsiblePerson: responsiblePerson,
                                    dataManager: dataManager
                                )
                            } else {
                                Text("Missing person data for event: \(event.eventName)")
                                    .foregroundColor(.red)
                                    .padding()
                            }
                        }
                    }
                }
                .padding()
            }
        }
    }
    
    private func updateWeek() {
        let calendar = Calendar.current
        let today = Date()
        let week = calendar.dateInterval(of: .weekOfYear, for: today)
        
        guard let firstDay = week?.start else { return }
        
        currentWeek = (0..<7).compactMap { day in
            calendar.date(byAdding: .day, value: day, to: firstDay)
        }
    }
    
    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
}
