import SwiftUI
import TerraiOS



// MARK: - Main View
struct HealthDashboardView: View {
    @ObservedObject var healthManager: HealthManager
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    connectionSection
                    
                    if healthManager.isConnected {
                        activityOverviewSection
                        workoutDetailsSection
                        sleepAnalysisSection
                        advancedMetricsSection
                    }
                }
                .padding()
            }
            .navigationTitle("Health Dashboard")
            .refreshable {
                if healthManager.isConnected {
                    healthManager.fetchAllData()
                }
            }
        }
    }
}

// MARK: - Section Components
extension HealthDashboardView {
    private var connectionSection: some View {
        ConnectionStatusCard(
            isConnected: healthManager.isConnected,
            isLoading: healthManager.isLoading,
            deviceName: healthManager.activityData?.data?.first?.device_data?.manufacturer,
            onConnect: healthManager.connectToAppleHealth
        )
    }
    
    private var activityOverviewSection: some View {
            DashboardSection(title: "Activity Overview", systemImage: "flame.fill") {
                if let activityData = healthManager.activityData?.data?.first {
                    VStack(alignment: .leading, spacing: 16) {
                        MetricRow(icon: "figure.walk",
                                 value: "\(activityData.distance_data?.summary?.steps ?? 0)",
                                 unit: "steps")
                        
                        MetricRow(icon: "figure.hiking",
                                 value: String(format: "%.1f",
                                             (activityData.distance_data?.summary?.distance_meters ?? 0) / 1000),
                                 unit: "km")
                        
                        MetricRow(icon: "clock.fill",
                                 value: "\(Int((activityData.active_durations_data?.activity_seconds ?? 0) / 60))",
                                 unit: "active minutes")
                        
                        MetricRow(icon: "flame.fill",
                                 value: String(format: "%.0f",
                                             activityData.calories_data?.total_burned_calories ?? 0),
                                 unit: "calories")
                    }
                } else {
                    Text("No activity data available")
                        .foregroundColor(.gray)
                }
            }
        }
        
        private var workoutDetailsSection: some View {
            DashboardSection(title: "Workout Details", systemImage: "figure.mixed.cardio") {
                if let activityData = healthManager.activityData?.data?.first {
                    VStack(alignment: .leading, spacing: 16) {
                        MetricRow(icon: "speedometer",
                                 value: String(format: "%.1f",
                                             activityData.movement_data?.avg_speed_meters_per_second ?? 0),
                                 unit: "m/s avg speed")
                        
                        if let heartRate = activityData.heart_rate_data?.summary {
                            MetricRow(icon: "heart.fill",
                                      value: String(format: "%.0f", heartRate.avg_hr_bpm ?? 0),
                                     unit: "avg bpm")
                            
                            MetricRow(icon: "waveform.path.ecg",
                                      value: String(format: "%.0f", heartRate.avg_hrv_sdnn ?? 0),
                                     unit: "ms HRV")
                        }
                        
                        MetricRow(icon: "bolt.circle.fill",
                                 value: String(format: "%.1f",
                                             activityData.power_data?.avg_watts ?? 0),
                                 unit: "avg watts")
                    }
                } else {
                    Text("No workout data available")
                        .foregroundColor(.gray)
                }
            }
        }
        
    private var sleepAnalysisSection: some View {
            DashboardSection(title: "Sleep Analysis", systemImage: "bed.double.fill") {
                if let sleepData = healthManager.sleepData?.data?.first,
                   let duration = sleepData.sleep_durations_data?.asleep {
                    VStack(alignment: .leading, spacing: 16) {
                        MetricRow(icon: "moon.zzz.fill",
                                 value: String(format: "%.1f",
                                             (duration.duration_asleep_state_seconds ?? 0) / 3600),
                                 unit: "hours total sleep")
                        
                        MetricRow(icon: "powersleep",
                                 value: String(format: "%.1f",
                                             (duration.duration_deep_sleep_state_seconds ?? 0) / 3600),
                                 unit: "hours deep sleep")
                        
                        MetricRow(icon: "sparkles",
                                 value: String(format: "%.1f",
                                             (duration.duration_REM_sleep_state_seconds ?? 0) / 3600),
                                 unit: "hours REM sleep")
                    }
                } else {
                    Text("No sleep data available")
                        .foregroundColor(.gray)
                }
            }
        }
        
        private var advancedMetricsSection: some View {
            DashboardSection(title: "Advanced Metrics", systemImage: "chart.bar.fill") {
                if let activityData = healthManager.activityData?.data?.first {
                    VStack(alignment: .leading, spacing: 16) {
                        if let strain = activityData.strain_data?.strain_level {
                            MetricRow(icon: "waveform.path.ecg",
                                     value: String(format: "%.1f", strain),
                                     unit: "strain level")
                        }
                        
                        if let oxygen = activityData.oxygen_data?.avg_saturation_percentage {
                            MetricRow(icon: "lungs.fill",
                                     value: String(format: "%.1f", oxygen),
                                     unit: "% O₂")
                        }
                        
                        if activityData.strain_data?.strain_level == nil &&
                           activityData.oxygen_data?.avg_saturation_percentage == nil {
                            Text("No advanced metrics available")
                                .foregroundColor(.gray)
                        }
                    }
                } else {
                    Text("No advanced metrics available")
                        .foregroundColor(.gray)
                }
            }
        }

}

// MARK: - Reusable Components
struct ConnectionStatusCard: View {
    let isConnected: Bool
    let isLoading: Bool
    let deviceName: String?
    let onConnect: () -> Void
    
    var body: some View {
        Group {
            if isConnected {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    Text("Connected to \(deviceName ?? "Device")")
                }
                .padding()
                .background(Color.green.opacity(0.1))
                .cornerRadius(10)
            } else {
                VStack {
                    if isLoading {
                        ProgressView()
                            .padding()
                        Text("Connecting...")
                    } else {
                        Button(action: onConnect) {
                            HStack {
                                Image(systemName: "link")
                                Text("Connect to Health")
                            }
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                        }
                    }
                }
            }
        }
    }
}

struct DashboardSection<Content: View>: View {
    let title: String
    let systemImage: String
    @ViewBuilder let content: () -> Content
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: systemImage)
                    .foregroundColor(.blue)
                Text(title)
                    .font(.headline)
            }
            
            content()
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
    }
}

struct MetricRow: View {
    let icon: String
    let value: String
    let unit: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.blue)
                .frame(width: 20)
            
            Text(value)
                .font(.headline)
            
            Text(unit)
                .foregroundColor(.gray)
        }
    }
}

//struct HealthDashboardView: View {
//    @ObservedObject var healthManager: HealthManager
//    
//    var body: some View {
//        NavigationView {
//            ScrollView {
//                VStack(spacing: 20) {
//                    connectionSection
//                    
//                    if healthManager.isConnected {
//                        dataSection
//                    }
//                }
//                .padding()
//            }
//            .navigationTitle("Health Dashboard")
//            .refreshable {
//                if healthManager.isConnected {
//                    healthManager.fetchAllData()
//                }
//            }
//        }
//    }
//    
//    private var connectionSection: some View {
//        Group {
//            if healthManager.isConnected {
//                HStack {
//                    Image(systemName: "checkmark.circle.fill")
//                        .foregroundColor(.green)
//                    Text("Connected to \(healthManager.activityData?.data?.first?.device_data?.manufacturer ?? "Device")")
//                }
//                .padding()
//                .background(Color.green.opacity(0.1))
//                .cornerRadius(10)
//            } else {
//                VStack {
//                    if healthManager.isLoading {
//                        ProgressView()
//                            .padding()
//                        Text("Connecting...")
//                    } else {
//                        Button(action: {
//                            healthManager.connectToAppleHealth()
//                        }) {
//                            HStack {
//                                Image(systemName: "link")
//                                Text("Connect to Health")
//                            }
//                            .padding()
//                            .background(Color.blue)
//                            .foregroundColor(.white)
//                            .cornerRadius(10)
//                        }
//                    }
//                }
//            }
//        }
//    }
//    
//    private var dataSection: some View {
//        VStack(spacing: 20) {
//            // Activity Summary Card
//            DataCard(title: "Today's Activity", systemImage: "flame.fill") {
//                VStack(alignment: .leading, spacing: 8) {
//                    if let activityData = healthManager.activityData?.data?.first {
//                        if let steps = activityData.distance_data?.summary?.steps {
//                            MetricRow(icon: "figure.walk",
//                                      value: "\(steps)",
//                                      unit: "steps")
//                        }
//                        
//                        if let distance = activityData.distance_data?.summary?.distance_meters {
//                            MetricRow(icon: "figure.hiking",
//                                      value: String(format: "%.1f", distance/1000),
//                                      unit: "km")
//                        }
//                        
//                        if let activeSeconds = activityData.active_durations_data?.activity_seconds {
//                            MetricRow(icon: "clock.fill",
//                                      value: "\(Int(activeSeconds/60))",
//                                      unit: "active minutes")
//                        }
//                        
//                        if let calories = activityData.calories_data?.total_burned_calories {
//                            MetricRow(icon: "bolt.fill",
//                                      value: String(format: "%.0f", calories),
//                                      unit: "calories")
//                        }
//                        
//                        if let avgHR = activityData.heart_rate_data?.summary?.avg_hr_bpm {
//                            MetricRow(icon: "heart.fill",
//                                      value: String(format: "%.0f", avgHR),
//                                      unit: "bpm")
//                        }
//                    }
//                }
//            }
//            
//            // Activity Details Card
//            DataCard(title: "Activity Details", systemImage: "sun.max.fill") {
//                if let activityData = healthManager.activityData?.data?.first {
//                    VStack(alignment: .leading, spacing: 8) {
//                        if let avgSpeed = activityData.movement_data?.avg_speed_meters_per_second {
//                            MetricRow(icon: "speedometer",
//                                      value: String(format: "%.1f", avgSpeed),
//                                      unit: "m/s avg speed")
//                        }
//                        
//                        if let minHR = activityData.heart_rate_data?.summary?.min_hr_bpm {
//                            MetricRow(icon: "heart.circle.fill",
//                                      value: String(format: "%.0f", minHR),
//                                      unit: "min HR")
//                        }
//                        
//                        if let avgPower = activityData.power_data?.avg_watts {
//                            MetricRow(icon: "bolt.circle.fill",
//                                      value: String(format: "%.1f", avgPower),
//                                      unit: "avg watts")
//                        }
//                        
//                        if let energyData = activityData.energy_data?.energy_kilojoules {
//                            MetricRow(icon: "flame.fill",
//                                      value: String(format: "%.0f", energyData),
//                                      unit: "kJ")
//                        }
//                        
//                        if let met = activityData.MET_data?.avg_level {
//                            MetricRow(icon: "figure.mixed.cardio",
//                                      value: String(format: "%.1f", met),
//                                      unit: "avg MET")
//                        }
//                    }
//                }
//            }
//            
//            // Additional Metrics Card
//            DataCard(title: "Advanced Metrics", systemImage: "chart.bar.fill") {
//                if let activityData = healthManager.activityData?.data?.first {
//                    VStack(alignment: .leading, spacing: 8) {
//                        if let strain = activityData.strain_data?.strain_level {
//                            MetricRow(icon: "waveform.path.ecg",
//                                      value: String(format: "%.1f", strain),
//                                      unit: "strain level")
//                        }
//                        
//                        if let tss = activityData.TSS_data?.TSS_samples {
//                            MetricRow(icon: "chart.bar",
//                                      value: String(format: "%.0f", tss),
//                                      unit: "TSS score")
//                        }
//                        
//                        if let work = activityData.work_data?.work_kilojoules {
//                            MetricRow(icon: "figure.strengthtraining.traditional",
//                                      value: String(format: "%.0f", work),
//                                      unit: "kJ work")
//                        }
//                        
//                        if let oxygen = activityData.oxygen_data?.avg_saturation_percentage {
//                            MetricRow(icon: "lungs.fill",
//                                      value: String(format: "%.1f", oxygen),
//                                      unit: "% O₂")
//                        }
//                    }
//                }
//            }
//        }
//    }
//    
//    private var sleepSection: some View {
//        VStack(spacing: 20) {
//            // Sleep Summary Card
//            DataCard(title: "Sleep Overview", systemImage: "bed.double.fill") {
//                if let sleepData = healthManager.sleepData?.data?.first {
//                    VStack(alignment: .leading, spacing: 8) {
//                        if let duration = sleepData.sleep_durations_data {
//                            if let asleep = duration.asleep {
//                                if let totalSleep = asleep.duration_asleep_state_seconds {
//                                    MetricRow(icon: "moon.zzz.fill",
//                                              value: String(format: "%.1f", totalSleep/3600),
//                                              unit: "hours total sleep")
//                                }
//                                
//                                if let deepSleep = asleep.duration_deep_sleep_state_seconds {
//                                    MetricRow(icon: "powersleep",
//                                              value: String(format: "%.1f", deepSleep/3600),
//                                              unit: "hours deep sleep")
//                                }
//                                
//                                if let remSleep = asleep.duration_REM_sleep_state_seconds {
//                                    MetricRow(icon: "sparkles",
//                                              value: String(format: "%.1f", remSleep/3600),
//                                              unit: "hours REM sleep")
//                                }
//                            }
//                            
//                            if let efficiency = duration.sleep_efficiency {
//                                MetricRow(icon: "chart.bar.fill",
//                                          value: String(format: "%.0f", efficiency),
//                                          unit: "% efficiency")
//                            }
//                        }
//                    }
//                }
//            }
//            
//            // Sleep Quality Card
//            DataCard(title: "Sleep Quality", systemImage: "heart.fill") {
//                if let sleepData = healthManager.sleepData?.data?.first {
//                    VStack(alignment: .leading, spacing: 8) {
//                        if let heartRate = sleepData.heart_rate_data?.summary {
//                            if let avgHR = heartRate.avg_hr_bpm {
//                                MetricRow(icon: "heart.fill",
//                                          value: String(format: "%.0f", avgHR),
//                                          unit: "avg bpm")
//                            }
//                            
//                            if let minHR = heartRate.min_hr_bpm {
//                                MetricRow(icon: "heart.slash.fill",
//                                          value: String(format: "%.0f", minHR),
//                                          unit: "min bpm")
//                            }
//                            
//                            if let hrvSDNN = heartRate.avg_hrv_sdnn {
//                                MetricRow(icon: "waveform.path.ecg",
//                                          value: String(format: "%.0f", hrvSDNN),
//                                          unit: "ms HRV")
//                            }
//                        }
//                        
//                        if let respiration = sleepData.respiration_data?.breaths_data {
//                            if let avgBreaths = respiration.avg_breaths_per_min {
//                                MetricRow(icon: "lungs.fill",
//                                          value: String(format: "%.1f", avgBreaths),
//                                          unit: "breaths/min")
//                            }
//                        }
//                    }
//                }
//            }
//            
//            // Sleep Environment Card
//            DataCard(title: "Sleep Environment", systemImage: "thermometer") {
//                if let sleepData = healthManager.sleepData?.data?.first {
//                    VStack(alignment: .leading, spacing: 8) {
//                        if let tempData = sleepData.temperature_data {
//                            if let tempDelta = tempData.delta {
//                                MetricRow(icon: "thermometer",
//                                          value: String(format: "%.1f", tempDelta),
//                                          unit: "°C temp change")
//                            }
//                        }
//                        
//                        if let respiration = sleepData.respiration_data?.snoring_data {
//                            if let snoringEvents = respiration.num_snoring_events {
//                                MetricRow(icon: "zzz",
//                                          value: "\(snoringEvents)",
//                                          unit: "snoring events")
//                            }
//                            
//                            if let snoringDuration = respiration.total_snoring_duration_seconds {
//                                MetricRow(icon: "timer",
//                                          value: String(format: "%.0f", snoringDuration/60),
//                                          unit: "min snoring")
//                            }
//                        }
//                    }
//                }
//            }
//        }
//    }
//    
//    private var dailySection: some View {
//            VStack(spacing: 20) {
//                // Daily Activity Summary Card
//                DataCard(title: "Daily Summary", systemImage: "figure.walk") {
//                    if let dailyData = healthManager.dailyData?.data?.first {
//                        VStack(alignment: .leading, spacing: 8) {
//                            if let distance = dailyData.distance_data {
//                                if let steps = distance.steps {
//                                    MetricRow(icon: "figure.walk",
//                                            value: String(format: "%.0f", steps),
//                                            unit: "steps")
//                                }
//                                
//                                if let distanceMeters = distance.distance_meters {
//                                    MetricRow(icon: "figure.hiking",
//                                            value: String(format: "%.1f", distanceMeters/1000),
//                                            unit: "km")
//                                }
//                                
//                                if let floors = distance.floors_climbed {
//                                    MetricRow(icon: "stairs",
//                                            value: String(format: "%.0f", floors),
//                                            unit: "floors climbed")
//                                }
//                            }
//                            
//                            if let calories = dailyData.calories_data?.total_burned_calories {
//                                MetricRow(icon: "flame.fill",
//                                        value: String(format: "%.0f", calories),
//                                        unit: "calories burned")
//                            }
//                        }
//                    }
//                }
//                
//                // Heart Rate & Activity Zones Card
//                DataCard(title: "Heart Rate & Activity", systemImage: "heart.circle.fill") {
//                    if let dailyData = healthManager.dailyData?.data?.first {
//                        VStack(alignment: .leading, spacing: 8) {
//                            if let heartRate = dailyData.heart_rate_data?.summary {
//                                if let avgHR = heartRate.avg_hr_bpm {
//                                    MetricRow(icon: "heart.fill",
//                                            value: String(format: "%.0f", avgHR),
//                                            unit: "avg bpm")
//                                }
//                                
//                                if let restingHR = heartRate.resting_hr_bpm {
//                                    MetricRow(icon: "heart.slash.fill",
//                                            value: String(format: "%.0f", restingHR),
//                                            unit: "resting bpm")
//                                }
//                            }
//                            
//                            if let active = dailyData.active_durations_data {
//                                if let activeMinutes = active.activity_seconds {
//                                    MetricRow(icon: "figure.run",
//                                            value: String(format: "%.0f", activeMinutes/60),
//                                            unit: "active minutes")
//                                }
//                                
//                                if let vigorous = active.vigorous_intensity_seconds {
//                                    MetricRow(icon: "bolt.fill",
//                                            value: String(format: "%.0f", vigorous/60),
//                                            unit: "vigorous minutes")
//                                }
//                            }
//                        }
//                    }
//                }
//                
//                // Stress & Recovery Card
//                DataCard(title: "Stress & Recovery", systemImage: "brain.head.profile") {
//                    if let dailyData = healthManager.dailyData?.data?.first {
//                        VStack(alignment: .leading, spacing: 8) {
//                            if let stress = dailyData.stress_data {
//                                if let avgStress = stress.avg_stress_level {
//                                    MetricRow(icon: "brain",
//                                            value: String(format: "%.1f", avgStress),
//                                            unit: "avg stress")
//                                }
//                                
//                                if let restStress = stress.rest_stress_duration_seconds {
//                                    MetricRow(icon: "leaf.fill",
//                                            value: String(format: "%.0f", restStress/3600),
//                                            unit: "hrs rest")
//                                }
//                            }
//                            
//                            if let scores = dailyData.scores {
//                                if let recovery = scores.recovery {
//                                    MetricRow(icon: "battery.100.bolt",
//                                            value: String(format: "%.0f", recovery),
//                                            unit: "recovery score")
//                                }
//                            }
//                            
//                            if let strain = dailyData.strain_data?.strain_level {
//                                MetricRow(icon: "chart.line.uptrend.xyaxis",
//                                        value: String(format: "%.1f", strain),
//                                        unit: "strain level")
//                            }
//                        }
//                    }
//                }
//            }
//        }
//
//}
struct DataCard<Content: View>: View {
    let title: String
    let systemImage: String
    @ViewBuilder let content: () -> Content
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: systemImage)
                    .foregroundColor(.blue)
                Text(title)
                    .font(.headline)
            }
            
            content()
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
    }
}

//struct MetricRow: View {
//    let icon: String
//    let value: String
//    let unit: String
//    
//    var body: some View {
//        HStack(spacing: 12) {
//            Image(systemName: icon)
//                .foregroundColor(.blue)
//                .frame(width: 20)
//            
//            Text(value)
//                .font(.headline)
//            
//            Text(unit)
//                .foregroundColor(.gray)
//        }
//    }
//}
