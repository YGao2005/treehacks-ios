import SwiftUI
import TerraiOS

// Example view to display the data
struct HealthDataView: View {
    @ObservedObject var healthManager: HealthManager
    
    var body: some View {
        VStack {
            Button("Fetch Activity Data") {
                healthManager.fetchActivityData()
            }
            .padding()
            
            Button("Fetch Daily Data") {
                healthManager.fetchDailyData()
            }
            .padding()
            
            Button("Fetch Sleep Data") {
                healthManager.fetchSleepData()
            }
            .padding()
            
            // Display some of the fetched data
            if let activityData = healthManager.activityData {
                Text("Activity Data Retrieved")
                // Add specific activity data display here
            }
            
            if let dailyData = healthManager.dailyData {
                Text("Daily Data Retrieved")
                // Add specific daily data display here
            }
            
            if let sleepData = healthManager.sleepData {
                Text("Sleep Data Retrieved")
                // Add specific sleep data display here
            }
        }
    }
}
