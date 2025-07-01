import SwiftUI

struct OptionsMenuView: View {
    let onEdit: () -> Void
    let onDelete: () -> Void
    
    var body: some View {
        Menu {
            Button(action: onEdit) {
                Label("Edit", systemImage: "pencil")
            }
            
            Button(action: onDelete) {
                Label("Delete", systemImage: "trash")
            }
            .foregroundColor(.red)
        } label: {
            Image(systemName: "ellipsis.circle")
                .font(.title2)
                .foregroundColor(.gray)
        }
    }
}

#Preview {
    OptionsMenuView(
        onEdit: { print("Edit tapped") },
        onDelete: { print("Delete tapped") }
    )
} 