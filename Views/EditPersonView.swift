// Views/EditPersonView.swift
import SwiftUI

struct EditPersonView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var dataManager: EventDataManager
    let person: Person
    
    @State private var name: String
    @State private var selectedColor: Color
    @State private var isParent: Bool
    
    private let availableColors: [Color] = [
        .red, .blue, .green, .orange, .purple, .pink, .yellow, .brown, .cyan, .mint
    ]
    
    init(dataManager: EventDataManager, person: Person) {
        self.dataManager = dataManager
        self.person = person
        self._name = State(initialValue: person.name)
        self._selectedColor = State(initialValue: person.color.color)
        self._isParent = State(initialValue: person.isParent)
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Person Details")) {
                    TextField("Name", text: $name)
                    
                    Toggle("Is Parent", isOn: $isParent)
                }
                
                Section(header: Text("Color")) {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 5), spacing: 10) {
                        ForEach(availableColors, id: \.self) { color in
                            Circle()
                                .fill(color)
                                .frame(width: 30, height: 30)
                                .overlay(
                                    Circle()
                                        .stroke(Color.primary, lineWidth: selectedColor == color ? 3 : 0)
                                )
                                .onTapGesture {
                                    selectedColor = color
                                }
                        }
                    }
                    .padding(.vertical, 8)
                }
                
                // Remove the delete section since we can't check eventsForPerson with non-optional id
                Section {
                    Button("Delete Person", role: .destructive) {
                        dataManager.removePerson(person)
                        dismiss()
                    }
                }
            }
            .navigationTitle("Edit Person")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        savePerson()
                    }
                    .disabled(name.isEmpty)
                }
            }
        }
    }
    
    private func savePerson() {
        let updatedPerson = Person(
            id: person.id,
            name: name,
            color: selectedColor,
            isParent: isParent,
            userId: person.userId
        )
        dataManager.updatePerson(updatedPerson)
        dismiss()
    }
}
