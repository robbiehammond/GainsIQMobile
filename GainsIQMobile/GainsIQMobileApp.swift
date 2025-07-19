//
//  GainsIQMobileApp.swift
//  GainsIQMobile
//
//  Created by Robert Hammond on 7/17/25.
//

import SwiftUI

@main
struct GainsIQMobileApp: App {
    @StateObject private var authViewModel = AuthViewModel()
    
    var body: some Scene {
        WindowGroup {
            Group {
                if authViewModel.isLoading {
                    SplashView()
                } else if authViewModel.isAuthenticated {
                    MainTabView()
                        .environmentObject(authViewModel)
                } else {
                    LoginView()
                        .environmentObject(authViewModel)
                }
            }
        }
    }
}

struct SplashView: View {
    var body: some View {
        VStack {
            Image(systemName: "dumbbell.fill")
                .font(.system(size: 80))
                .foregroundColor(.blue)
            
            Text("GainsIQ")
                .font(.largeTitle)
                .fontWeight(.bold)
                .padding(.top)
            
            SwiftUI.ProgressView()
                .padding(.top)
        }
    }
}
