// Views/AddPersonView.swift
import SwiftUI

struct AddPersonView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var dataManager: EventDataManager
    
    @State private var name = ""
    @State private var selectedColor = Color.blue
    @State private var isParent = false
    
    private let availableColors: [Color] = [
        .red, .blue, .green, .orange, .purple, .pink, .yellow, .brown, .cyan, .mint
    ]
    
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
            }
            .navigationTitle("Add Family Member")
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
        let person = Person(name: name, color: selectedColor, isParent: isParent, userId: "")
        dataManager.addPerson(person)
        dismiss()
    }
}
