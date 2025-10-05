// Managers/EventDataManager.swift
import Foundation
import SwiftUI
import UserNotifications
import FirebaseFirestore
import FirebaseAuth

class EventDataManager: ObservableObject {
    @Published var people: [Person] = []
    @Published var events: [Event] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let db = Firestore.firestore()
    private var authManager = AuthManager.shared
    private var peopleListener: ListenerRegistration?
    private var eventsListener: ListenerRegistration?
    
    // Fallback to local storage if Firebase fails
    private let peopleKey = "savedPeople"
    private let eventsKey = "savedEvents"
    private var useLocalStorage = false
    
    init() {
        setupAuthListener()
        setupNotificationPermission()
    }
    
    private func setupAuthListener() {
        _ = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            if let user = user {
                print("User authenticated: \(user.uid)")
                self?.setupFirebaseListeners(userId: user.uid)
            } else {
                print("No user authenticated, using local storage")
                self?.useLocalStorage = true
                self?.removeFirebaseListeners()
                self?.loadLocalData()
            }
        }
    }
    
    private func setupFirebaseListeners(userId: String) {
        useLocalStorage = false
        
        // Listen for people
        peopleListener = db.collection("people")
            .whereField("userId", isEqualTo: userId)
            .addSnapshotListener { [weak self] snapshot, error in
                if let error = error {
                    print("Error fetching people: \(error.localizedDescription)")
                    self?.errorMessage = "Failed to load people: \(error.localizedDescription)"
                    self?.useLocalStorage = true
                    self?.loadLocalData()
                    return
                }
                
                guard let documents = snapshot?.documents else {
                    print("No people documents found")
                    return
                }
                
                print("Loaded \(documents.count) people from Firebase")
                
                self?.people = documents.compactMap { document -> Person? in
                    let data = document.data()
                    guard let name = data["name"] as? String,
                          let isParent = data["isParent"] as? Bool,
                          let userId = data["userId"] as? String,
                          let colorData = data["color"] as? [String: Double],
                          let red = colorData["red"],
                          let green = colorData["green"],
                          let blue = colorData["blue"],
                          let alpha = colorData["alpha"] else {
                        print("Invalid person data: \(data)")
                        return nil
                    }
                    
                    let colorCodable = ColorCodable(red: red, green: green, blue: blue, alpha: alpha)
                    return Person(
                        id: document.documentID,
                        name: name,
                        color: colorCodable.color,
                        isParent: isParent,
                        userId: userId
                    )
                }
                
                // Save to local storage as backup
                self?.saveLocalData()
            }
        
        // Listen for events
        eventsListener = db.collection("events")
            .whereField("userId", isEqualTo: userId)
            .addSnapshotListener { [weak self] snapshot, error in
                if let error = error {
                    print("Error fetching events: \(error.localizedDescription)")
                    self?.errorMessage = "Failed to load events: \(error.localizedDescription)"
                    return
                }
                
                guard let documents = snapshot?.documents else {
                    print("No event documents found")
                    return
                }
                
                print("Loaded \(documents.count) events from Firebase")
                
                self?.events = documents.compactMap { document -> Event? in
                    let data = document.data()
                    guard let personId = data["personId"] as? String,
                          let eventName = data["eventName"] as? String,
                          let timestamp = data["date"] as? Timestamp,
                          let responsiblePersonId = data["responsiblePersonId"] as? String,
                          let userId = data["userId"] as? String,
                          let dayOfWeek = data["dayOfWeek"] as? Int else {
                        print("Invalid event data: \(data)")
                        return nil
                    }
                    
                    return Event(
                        id: document.documentID,
                        personId: personId,
                        eventName: eventName,
                        date: timestamp.dateValue(),
                        responsiblePersonId: responsiblePersonId,
                        userId: userId
                    )
                }
                
                // Save to local storage as backup
                self?.saveLocalData()
            }
    }
    
    private func removeFirebaseListeners() {
        peopleListener?.remove()
        eventsListener?.remove()
        peopleListener = nil
        eventsListener = nil
    }
    
    // MARK: - Notification Permission
    private func setupNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if granted {
                print("Notification permission granted")
            } else if let error = error {
                print("Notification permission error: \(error)")
            }
        }
    }
    
    // MARK: - People Management
    func addPerson(_ person: Person) {
        if useLocalStorage {
            // Use local storage
            people.append(person)
            saveLocalData()
            return
        }
        
        guard let userId = Auth.auth().currentUser?.uid else {
            errorMessage = "Not authenticated"
            return
        }
        
        let colorData: [String: Double] = [
            "red": person.color.red,
            "green": person.color.green,
            "blue": person.color.blue,
            "alpha": person.color.alpha
        ]
        
        let data: [String: Any] = [
            "name": person.name,
            "color": colorData,
            "isParent": person.isParent,
            "userId": userId
        ]
        
        db.collection("people").addDocument(data: data) { [weak self] error in
            if let error = error {
                print("Error adding person to Firebase: \(error)")
                self?.errorMessage = "Failed to add person: \(error.localizedDescription)"
                // Fallback to local storage
                self?.people.append(person)
                self?.saveLocalData()
            } else {
                print("Person added successfully to Firebase")
            }
        }
    }
    
    func updatePerson(_ person: Person) {
        if useLocalStorage {
            if let index = people.firstIndex(where: { $0.id == person.id }) {
                people[index] = person
                saveLocalData()
            }
            return
        }
        
        let personId = person.id
        
        let colorData: [String: Double] = [
            "red": person.color.red,
            "green": person.color.green,
            "blue": person.color.blue,
            "alpha": person.color.alpha
        ]
        
        let data: [String: Any] = [
            "name": person.name,
            "color": colorData,
            "isParent": person.isParent,
            "userId": person.userId
        ]
        
        db.collection("people").document(personId).setData(data) { [weak self] error in
            if let error = error {
                print("Error updating person: \(error)")
                self?.errorMessage = "Failed to update person: \(error.localizedDescription)"
            }
        }
    }
    
    func removePerson(_ person: Person) {
        if useLocalStorage {
            people.removeAll { $0.id == person.id }
            events.removeAll { $0.personId == person.id }
            saveLocalData()
            return
        }
        
        let personId = person.id
        
        // Remove person
        db.collection("people").document(personId).delete()
        
        // Remove associated events
        let eventsToDelete = events.filter { $0.personId == personId }
        for event in eventsToDelete {
            removeEvent(event)
        }
    }
    
    // MARK: - Event Management
    func addEvent(_ event: Event) {
        if useLocalStorage {
            events.append(event)
            scheduleNotification(for: event)
            saveLocalData()
            return
        }
        
        guard let userId = Auth.auth().currentUser?.uid else {
            errorMessage = "Not authenticated"
            return
        }
        
        let data: [String: Any] = [
            "personId": event.personId,
            "eventName": event.eventName,
            "date": Timestamp(date: event.date),
            "responsiblePersonId": event.responsiblePersonId,
            "dayOfWeek": event.dayOfWeek,
            "userId": userId
        ]
        
        db.collection("events").addDocument(data: data) { [weak self] error in
            if let error = error {
                print("Error adding event to Firebase: \(error)")
                self?.errorMessage = "Failed to add event: \(error.localizedDescription)"
                // Fallback to local storage
                self?.events.append(event)
                self?.scheduleNotification(for: event)
                self?.saveLocalData()
            } else {
                print("Event added successfully to Firebase")
                self?.scheduleNotification(for: event)
            }
        }
    }
    
    func updateEvent(_ event: Event) {
        if useLocalStorage {
            if let index = events.firstIndex(where: { $0.id == event.id }) {
                removeNotification(for: events[index])
                events[index] = event
                scheduleNotification(for: event)
                saveLocalData()
            }
            return
        }
        
        let eventId = event.id
        
        let data: [String: Any] = [
            "personId": event.personId,
            "eventName": event.eventName,
            "date": Timestamp(date: event.date),
            "responsiblePersonId": event.responsiblePersonId,
            "dayOfWeek": event.dayOfWeek,
            "userId": event.userId
        ]
        
        db.collection("events").document(eventId).setData(data) { [weak self] error in
            if let error = error {
                print("Error updating event: \(error)")
                self?.errorMessage = "Failed to update event: \(error.localizedDescription)"
            } else {
                self?.scheduleNotification(for: event)
            }
        }
    }
    
    func removeEvent(_ event: Event) {
        if useLocalStorage {
            events.removeAll { $0.id == event.id }
            removeNotification(for: event)
            saveLocalData()
            return
        }
        
        let eventId = event.id
        
        db.collection("events").document(eventId).delete()
        removeNotification(for: event)
    }
    
    // MARK: - Query Methods
    func getPerson(by id: String) -> Person? {
        people.first { $0.id == id }
    }
    
    func familyMembers() -> [Person] {
        people.filter { !$0.isParent }
    }
    
    func parents() -> [Person] {
        people.filter { $0.isParent }
    }
    
    func eventsForPerson(_ personId: String) -> [Event] {
        events.filter { $0.personId == personId }.sorted { $0.date < $1.date }
    }
    
    func eventsForDay(_ date: Date) -> [Event] {
        let calendar = Calendar.current
        let targetDayOfWeek = calendar.component(.weekday, from: date)
        
        let dayEvents = events.filter { event in
            // Check if event occurs on this day of week (for recurring)
            event.dayOfWeek == targetDayOfWeek
        }.sorted { $0.date < $1.date }
        
        print("Found \(dayEvents.count) events for day \(targetDayOfWeek) on date \(date)")
        return dayEvents
    }
    
    func eventsForParent(_ parentId: String) -> [Event] {
        events.filter { $0.responsiblePersonId == parentId }.sorted { $0.date < $1.date }
    }
    
    func eventsForMonth(_ date: Date) -> [Date: [Event]] {
        let calendar = Calendar.current
        let range = calendar.range(of: .day, in: .month, for: date)!
        let monthDates = range.compactMap { day -> Date? in
            calendar.date(bySetting: .day, value: day, of: date)
        }
        
        var eventsByDate: [Date: [Event]] = [:]
        for date in monthDates {
            eventsByDate[date] = eventsForDay(date)
        }
        return eventsByDate
    }
    
    // MARK: - Notifications
    private func scheduleNotification(for event: Event) {
        guard let person = getPerson(by: event.personId),
              let responsiblePerson = getPerson(by: event.responsiblePersonId) else { return }
        
        let content = UNMutableNotificationContent()
        content.title = "Upcoming Event: \(event.eventName)"
        content.body = "\(person.name)'s event - Responsible: \(responsiblePerson.name)"
        content.sound = .default
        
        // Schedule notification 15 minutes before event
        let notificationDate = event.date.addingTimeInterval(-15 * 60)
        let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: notificationDate)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        
        let request = UNNotificationRequest(
            identifier: event.id,
            content: content,
            trigger: trigger
        )
        
        UNUserNotificationCenter.current().add(request)
    }
    
    private func removeNotification(for event: Event) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [event.id])
    }
    
    // MARK: - Local Storage Fallback
    private func saveLocalData() {
        if let encodedPeople = try? JSONEncoder().encode(people) {
            UserDefaults.standard.set(encodedPeople, forKey: peopleKey)
        }
        if let encodedEvents = try? JSONEncoder().encode(events) {
            UserDefaults.standard.set(encodedEvents, forKey: eventsKey)
        }
    }
    
    private func loadLocalData() {
        if let data = UserDefaults.standard.data(forKey: peopleKey),
           let decoded = try? JSONDecoder().decode([Person].self, from: data) {
            people = decoded
        }
        if let data = UserDefaults.standard.data(forKey: eventsKey),
           let decoded = try? JSONDecoder().decode([Event].self, from: data) {
            events = decoded
        }
    }
}
