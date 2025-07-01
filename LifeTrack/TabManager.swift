import Foundation
import SwiftUI

class TabManager: ObservableObject {
    @Published var selectedTab: Int = 0
    
    func switchToTab(_ tab: Int) {
        selectedTab = tab
    }
} 