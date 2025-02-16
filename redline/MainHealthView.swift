////
////  MainHealthView.swift
////  redline
////
////  Created by Yang Gao on 2/15/25.
////
//import SwiftUI
//
//struct MainHealthView: View {
//    @ObservedObject var healthManager: HealthManager
//    
//    var body: some View {
//        NavigationStack {
//            if healthManager.isConnected {
//                HealthDashboardView(healthManager: healthManager)
//            } else {
//                HealthConnectView(healthManager: healthManager)
//            }
//        }
//    }
//}
