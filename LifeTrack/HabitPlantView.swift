import SwiftUI

struct HabitPlantView: View {
    let streak: Int
    
    var plantImage: String {
        switch streak {
        case 0...2:
            return "leaf.fill"
        case 3...6:
            return "camera.macro" // Represents a growing plant
        default:
            return "tree.fill"
        }
    }
    
    var plantColor: Color {
        switch streak {
        case 0...2:
            return .green.opacity(0.6)
        case 3...6:
            return .green
        default:
            return .green.opacity(0.8) // Fixed opacity value
        }
    }
    
    var body: some View {
        Image(systemName: plantImage)
            .font(.title)
            .foregroundColor(plantColor)
            .frame(width: 40, height: 40)
            .background(plantColor.opacity(0.15))
            .clipShape(Circle())
    }
}

#Preview {
    HStack(spacing: 16) {
        HabitPlantView(streak: 1)
        HabitPlantView(streak: 4)
        HabitPlantView(streak: 10)
    }
} 