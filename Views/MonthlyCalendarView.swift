import SwiftUI

struct MonthlyCalendarView: View {
    @ObservedObject var dataManager: EventDataManager
    @State private var currentDate = Date()
    @State private var selectedDate: Date?
    
    private let calendar = Calendar.current
    
    var body: some View {
        VStack {
            // Month header with navigation
            HStack {
                Button(action: previousMonth) {
                    Image(systemName: "chevron.left")
                        .font(.title2)
                }
                
                Spacer()
                
                Text(monthYearString)
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Button(action: nextMonth) {
                    Image(systemName: "chevron.right")
                        .font(.title2)
                }
            }
            .padding()
            
            // Calendar grid
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 8) {
                ForEach(daysInMonth, id: \.self) { date in
                    if calendar.isDate(date, equalTo: currentDate, toGranularity: .month) {
                        CalendarDayView(
                            date: date,
                            events: dataManager.eventsForDay(date),
                            isSelected: selectedDate.map { calendar.isDate($0, inSameDayAs: date) } ?? false,
                            isToday: calendar.isDateInToday(date)
                        )
                        .onTapGesture {
                            selectedDate = date
                        }
                    } else {
                        // Empty cell for days outside current month
                        Text("")
                            .frame(height: 40)
                    }
                }
            }
            .padding(.horizontal)
            
            // Selected day events
            if let selectedDate = selectedDate {
                VStack(alignment: .leading) {
                    Text("Events for \(formattedDate(selectedDate))")
                        .font(.headline)
                        .padding(.horizontal)
                    
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 12) {
                            let dayEvents = dataManager.eventsForDay(selectedDate)
                            
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
                                    }
                                }
                            }
                        }
                        .padding()
                    }
                }
            }
            
            Spacer()
        }
    }
    
    private var monthYearString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: currentDate)
    }
    
    private var daysInMonth: [Date] {
        guard let monthInterval = calendar.dateInterval(of: .month, for: currentDate) else {
            return []
        }
        
        var dates: [Date] = []
        var currentDate = monthInterval.start
        
        // Add days from previous month to fill first week
        let firstWeekday = calendar.component(.weekday, from: currentDate)
        for _ in 1..<firstWeekday {
            guard let previousDate = calendar.date(byAdding: .day, value: -1, to: currentDate) else { break }
            currentDate = previousDate
        }
        currentDate = monthInterval.start
        
        while currentDate < monthInterval.end {
            dates.append(currentDate)
            guard let nextDate = calendar.date(byAdding: .day, value: 1, to: currentDate) else { break }
            currentDate = nextDate
        }
        
        return dates
    }
    
    private func previousMonth() {
        currentDate = calendar.date(byAdding: .month, value: -1, to: currentDate) ?? currentDate
    }
    
    private func nextMonth() {
        currentDate = calendar.date(byAdding: .month, value: 1, to: currentDate) ?? currentDate
    }
    
    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
}

struct CalendarDayView: View {
    let date: Date
    let events: [Event]
    let isSelected: Bool
    let isToday: Bool
    
    private let calendar = Calendar.current
    
    var body: some View {
        VStack(spacing: 2) {
            Text("\(calendar.component(.day, from: date))")
                .font(.system(size: 16, weight: isToday ? .bold : .regular))
                .foregroundColor(textColor)
                .frame(width: 32, height: 32)
                .background(background)
                .clipShape(Circle())
            
            // Event indicators
            if !events.isEmpty {
                HStack(spacing: 2) {
                    ForEach(Array(events.prefix(3)), id: \.id) { _ in
                        Circle()
                            .fill(Color.blue)
                            .frame(width: 4, height: 4)
                    }
                }
            }
        }
        .frame(height: 50)
    }
    
    private var textColor: Color {
        if isSelected {
            return .white
        } else if isToday {
            return .white
        } else {
            return .primary
        }
    }
    
    private var background: Color {
        if isSelected {
            return .blue
        } else if isToday {
            return .red
        } else {
            return .clear
        }
    }
}
