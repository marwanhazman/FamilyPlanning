// Views/ContentView.swift
import SwiftUI

enum ViewMode {
    case day, person, parent, month
}

struct ContentView: View {
    @StateObject private var dataManager = EventDataManager()
    @StateObject private var authManager = AuthManager.shared
    @State private var selectedViewMode: ViewMode = .day
    @State private var showingAddPerson = false
    @State private var showingAddEvent = false
    @State private var selectedDate = Date()
    
    var body: some View {
        Group {
            if authManager.isAuthenticated {
                mainAppView
            } else {
                LoginView()
            }
        }
    }
    
    private var mainAppView: some View {
        NavigationView {
            VStack {
                // View Mode Picker
                Picker("View Mode", selection: $selectedViewMode) {
                    Text("Day View").tag(ViewMode.day)
                    Text("Person View").tag(ViewMode.person)
                    Text("Parent View").tag(ViewMode.parent)
                    Text("Month View").tag(ViewMode.month)
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding()
                
                // Content based on selected view mode
                Group {
                    switch selectedViewMode {
                    case .day:
                        DayView(dataManager: dataManager, selectedDate: $selectedDate)
                    case .person:
                        PersonView(dataManager: dataManager)
                    case .parent:
                        ParentView(dataManager: dataManager)
                    case .month:
                        MonthlyCalendarView(dataManager: dataManager)
                    }
                }
                
                Spacer()
            }
            .navigationTitle("Family Events")
            .toolbar {
                ToolbarItemGroup(placement: .navigationBarLeading) {
                    Button("Sign Out") {
                        authManager.signOut()
                    }
                    .foregroundColor(.red)
                }
                
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    Button(action: { showingAddPerson = true }) {
                        Image(systemName: "person.badge.plus")
                    }
                    
                    Button(action: { showingAddEvent = true }) {
                        Image(systemName: "calendar.badge.plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddPerson) {
                AddPersonView(dataManager: dataManager)
            }
            .sheet(isPresented: $showingAddEvent) {
                AddEventView(dataManager: dataManager)
            }
        }
    }
}
