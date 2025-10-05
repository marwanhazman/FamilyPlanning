// Models/Event.swift
import Foundation

struct Event: Identifiable, Codable {
    var id: String
    var personId: String
    var eventName: String
    var date: Date
    var responsiblePersonId: String
    var dayOfWeek: Int
    var userId: String
    var isRecurring: Bool
    var recurrenceEndDate: Date? // Optional end date for recurrence
    
    init(id: String = UUID().uuidString,
         personId: String,
         eventName: String,
         date: Date,
         responsiblePersonId: String,
         userId: String,
         isRecurring: Bool = true,
         recurrenceEndDate: Date? = nil) {
        self.id = id
        self.personId = personId
        self.eventName = eventName
        self.date = date
        self.responsiblePersonId = responsiblePersonId
        self.userId = userId
        self.isRecurring = isRecurring
        self.recurrenceEndDate = recurrenceEndDate
        
        let calendar = Calendar.current
        self.dayOfWeek = calendar.component(.weekday, from: date)
    }
    
    var timeString: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    // Generate all occurrences for a given date range
    func occurrences(for date: Date) -> [Date] {
        guard isRecurring else { return [date] }
        
        let calendar = Calendar.current
        var occurrences: [Date] = []
        
        // Get the time components from the original event
        let timeComponents = calendar.dateComponents([.hour, .minute], from: date)
        
        // Create date for the target day with the same time
        var targetDateComponents = calendar.dateComponents([.year, .month, .day], from: date)
        targetDateComponents.hour = timeComponents.hour
        targetDateComponents.minute = timeComponents.minute
        
        if let targetDate = calendar.date(from: targetDateComponents) {
            occurrences.append(targetDate)
        }
        
        return occurrences
    }
}
