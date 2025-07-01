import SwiftUI

struct AppIconGenerator: View {
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                gradient: Gradient(colors: [Color.blue, Color.purple]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
            // Main icon elements
            VStack(spacing: 8) {
                // Top row - Habit tracking (checkmarks)
                HStack(spacing: 12) {
                    Circle()
                        .fill(Color.green)
                        .frame(width: 20, height: 20)
                        .overlay(
                            Image(systemName: "checkmark")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(.white)
                        )
                    
                    Circle()
                        .fill(Color.green)
                        .frame(width: 20, height: 20)
                        .overlay(
                            Image(systemName: "checkmark")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(.white)
                        )
                    
                    Circle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 20, height: 20)
                        .overlay(
                            Image(systemName: "circle")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(.white)
                        )
                }
                
                // Middle row - Task tracking (list)
                HStack(spacing: 8) {
                    Rectangle()
                        .fill(Color.orange)
                        .frame(width: 4, height: 16)
                    
                    Rectangle()
                        .fill(Color.orange)
                        .frame(width: 4, height: 12)
                    
                    Rectangle()
                        .fill(Color.orange)
                        .frame(width: 4, height: 18)
                }
                
                // Bottom row - Budget tracking (chart)
                HStack(spacing: 6) {
                    Rectangle()
                        .fill(Color.red)
                        .frame(width: 8, height: 12)
                    
                    Rectangle()
                        .fill(Color.red)
                        .frame(width: 8, height: 16)
                    
                    Rectangle()
                        .fill(Color.red)
                        .frame(width: 8, height: 8)
                    
                    Rectangle()
                        .fill(Color.red)
                        .frame(width: 8, height: 14)
                }
            }
            .padding(40)
        }
        .frame(width: 1024, height: 1024)
        .clipped()
    }
}

#Preview {
    AppIconGenerator()
        .frame(width: 200, height: 200)
        .clipShape(RoundedRectangle(cornerRadius: 40))
} 