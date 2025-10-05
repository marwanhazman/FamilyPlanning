// Models/Person.swift
import SwiftUI
import Foundation

struct Person: Identifiable, Codable, Hashable {
    var id: String
    var name: String
    var color: ColorCodable
    var isParent: Bool
    var userId: String
    
    init(id: String = UUID().uuidString, name: String, color: Color, isParent: Bool = false, userId: String) {
        self.id = id
        self.name = name
        self.color = ColorCodable(color: color)
        self.isParent = isParent
        self.userId = userId
    }
}

struct ColorCodable: Codable, Hashable {
    var red: Double
    var green: Double
    var blue: Double
    var alpha: Double
    
    init(red: Double, green: Double, blue: Double, alpha: Double) {
        self.red = red
        self.green = green
        self.blue = blue
        self.alpha = alpha
    }
    
    init(color: Color) {
        // Use a default color if conversion fails
        let defaultColor = UIColor.blue
        
        let uiColor = UIColor(color)
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        
        if uiColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha) {
            self.red = Double(red)
            self.green = Double(green)
            self.blue = Double(blue)
            self.alpha = Double(alpha)
        } else {
            // Fallback to default color
            defaultColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
            self.red = Double(red)
            self.green = Double(green)
            self.blue = Double(blue)
            self.alpha = Double(alpha)
        }
    }
    
    var color: Color {
        Color(red: red, green: green, blue: blue, opacity: alpha)
    }
}
