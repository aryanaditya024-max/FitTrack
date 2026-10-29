import SwiftUI

public struct SettingsView: View {
    @StateObject private var viewModel: SettingsViewModel
    @StateObject private var authViewModel = AuthViewModel()
    @State private var showingAuthSheet: Bool = false
    
    public init(viewModel: SettingsViewModel = SettingsViewModel()) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }
    
    public var body: some View {
        NavigationStack {
            Form {
                // Unit Preferences Section
                Section("Units & Measurements") {
                    Toggle("Imperial Units (Miles / Lbs)", isOn: $viewModel.isImperialUnits)
                    
                    HStack {
                        Text("Current Distance Unit")
                            .foregroundColor(.secondary)
                        Spacer()
                        Text(viewModel.isImperialUnits ? "Miles (mi)" : "Kilometers (km)")
                            .foregroundColor(.primary)
                    }
                    .font(.footnote)
                }
                
                // Reminders & Notifications Section
                Section("Reminders & Notifications") {
                    Toggle("Daily Inactivity Reminder", isOn: $viewModel.dailyRemindersEnabled)
                    
                    if viewModel.dailyRemindersEnabled {
                        DatePicker(
                            "Reminder Time",
                            selection: $viewModel.reminderTime,
                            displayedComponents: .hourAndMinute
                        )
                    }
                }
                
                // Cloud & Storage Section
                Section("Data Storage & Cloud Sync") {
                    HStack {
                        Image(systemName: "internaldrive.fill")
                            .foregroundColor(.blue)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Local-First Storage")
                                .font(.subheadline)
                                .fontWeight(.medium)
                            Text("All workouts and metrics are securely saved on your device using Core Data.")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Toggle("Cloud Sync (Supabase)", isOn: $viewModel.cloudSyncEnabled)
                    
                    if authViewModel.isAuthenticated {
                        HStack {
                            Image(systemName: "person.crop.circle.badge.checkmark")
                                .foregroundColor(.green)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Cloud Account")
                                    .font(.subheadline)
                                Text(authViewModel.currentUserEmail ?? "Connected")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            Button("Sign Out", role: .destructive) {
                                Task { await authViewModel.signOut() }
                            }
                            .font(.caption)
                        }
                    } else {
                        Button {
                            showingAuthSheet = true
                        } label: {
                            Label("Sign In / Register with Cloud", systemImage: "person.crop.circle.badge.plus")
                                .font(.subheadline)
                        }
                    }
                }
                
                // About Section
                Section("About FitTrack") {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.0 (Build 1)")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("Architecture")
                        Spacer()
                        Text("MVVM + Core Data + HealthKit")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("Settings")
            .sheet(isPresented: $showingAuthSheet) {
                AuthView()
            }
        }
    }
}
