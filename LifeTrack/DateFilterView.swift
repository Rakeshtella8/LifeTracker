import SwiftUI

enum DateFilterOption: String, CaseIterable, Identifiable {
    case today = "Today"
    case thisWeek = "This Week"
    case thisMonth = "This Month"
    case custom = "Custom"
    var id: String { self.rawValue }
}

struct DateFilterView: View {
    @Binding var startDate: Date
    @Binding var endDate: Date
    @State private var selectedOption: DateFilterOption = .today
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Picker("Date Range", selection: $selectedOption) {
                ForEach(DateFilterOption.allCases) { option in
                    Text(option.rawValue).tag(option)
                }
            }
            .pickerStyle(.segmented)
            .onChange(of: selectedOption) {
                updateDates(for: selectedOption)
            }
            if selectedOption == .custom {
                DatePicker("Start Date", selection: $startDate, displayedComponents: .date)
                DatePicker("End Date", selection: $endDate, displayedComponents: .date)
            }
        }
        .onAppear { updateDates(for: selectedOption) }
    }
    
    private func updateDates(for option: DateFilterOption) {
        let calendar = Calendar.current
        let now = Date()
        switch option {
        case .today:
            startDate = calendar.startOfDay(for: now)
            endDate = calendar.date(byAdding: .day, value: 1, to: startDate)!.addingTimeInterval(-1)
        case .thisWeek:
            let week = calendar.dateInterval(of: .weekOfYear, for: now)!
            startDate = week.start
            endDate = week.end.addingTimeInterval(-1)
        case .thisMonth:
            let month = calendar.dateInterval(of: .month, for: now)!
            startDate = month.start
            endDate = month.end.addingTimeInterval(-1)
        case .custom:
            break
        }
    }
}

#Preview {
    struct PreviewWrapper: View {
        @State var start = Date()
        @State var end = Date()
        var body: some View {
            DateFilterView(startDate: $start, endDate: $end)
        }
    }
    return PreviewWrapper()
} 