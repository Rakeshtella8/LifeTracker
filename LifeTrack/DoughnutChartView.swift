import SwiftUI

struct DoughnutChartView: View {
    var value: Double // 0.0 to 1.0
    var title: String
    var color: Color
    
    var percentage: Int { Int((value * 100).rounded()) }
    
    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .stroke(Color(.systemGray5), lineWidth: 16)
                    .frame(width: 80, height: 80)
                Circle()
                    .trim(from: 0, to: value)
                    .stroke(color, style: StrokeStyle(lineWidth: 16, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .frame(width: 80, height: 80)
                Text("\(percentage)%")
                    .font(.title3).bold()
            }
            Text(title)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }
}

#Preview {
    HStack(spacing: 24) {
        DoughnutChartView(value: 0.7, title: "Habits", color: .blue)
        DoughnutChartView(value: 0.5, title: "Tasks", color: .green)
        DoughnutChartView(value: 0.2, title: "Budget", color: .red)
    }
} 