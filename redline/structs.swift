//
//  structs.swift
//  redline
//
//  Created by Yang Gao on 2/15/25.
//

struct ActivityData {
    let position_data: PositionData
    let device_data: DeviceData
    let movement_data: MovementData
    let active_durations_data: ActiveDurationsData
    let distance_data: DistanceData
    let metadata: Metadata
    let heart_rate_data: HeartRateData
    let calories_data: CaloriesData
    let power_data: PowerData
}

struct PositionData {
    let center_pos_lat_lng_deg: [Double]
    let start_pos_lat_lng_deg: [Double]
    let position_samples: [Double]
    let end_pos_lat_lng_deg: [Double]
}

struct DeviceData {
    let name: String
    let manufacturer: String
}

struct MovementData {
    let max_cadence_rpm: Double
    let avg_speed_meters_per_second: Double
    let max_speed_meters_per_second: Double
    let avg_cadence_rpm: Double
    let speed_samples: [Double]
}

struct ActiveDurationsData {
    let activity_seconds: Double
}

struct DistanceData {
    let summary: DistanceSummary
    let detailed: DetailedDistance
}

struct DistanceSummary {
    let elevation: [String: Double]
    let floors_climbed: Int
    let distance_meters: Double
    let steps: Int
    let swimming: SwimmingData
}

struct SwimmingData {
    let num_strokes: Int
}

struct DetailedDistance {
    let elevation_samples: [[String: Double]]
    let distance_samples: [[String: Double]]
}

struct Metadata {
    let type: Int
    let name: String
    let start_time: String
    let upload_type: Int
    let timestamp_localization: Int
    let summary_id: Int
    let end_time: String
}

struct HeartRateData {
    let summary: HeartRateSummary
    let detailed: DetailedHeartRate
}

struct HeartRateSummary {
    let max_hr_bpm: Double
    let min_hr_bpm: Double
    let avg_hr_bpm: Double
    let avg_hrv_sdnn: Double
}

struct DetailedHeartRate {
    let hr_samples: [Double]
    let hrv_samples_sdnn: [Double]
}

struct CaloriesData {
    let total_burned_calories: Double
    let BMR_calories: Double
    let net_activity_calories: Double
}

struct PowerData {
    let avg_watts: Double
    let max_watts: Double
    let power_samples: [Double]
}
