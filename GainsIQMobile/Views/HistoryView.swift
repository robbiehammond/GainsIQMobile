import SwiftUI

struct HistoryView: View {
    @StateObject private var viewModel: HistoryViewModel
    @StateObject private var userDefaults = UserDefaultsManager.shared
    
    init(apiClient: GainsIQAPIClient) {
        self._viewModel = StateObject(wrappedValue: HistoryViewModel(apiClient: apiClient))
    }
    
    var body: some View {
        VStack(spacing: 0) {
                // Date picker
                datePickerSection
                
                Divider()
                
                // Content
                if viewModel.isLoading {
                    loadingView
                } else if viewModel.hasDataForSelectedDate {
                    workoutsList
                } else {
                    emptyStateView
                }
        }
        .navigationTitle("History")
        .navigationBarTitleDisplayMode(.large)
        .task {
            await viewModel.loadSetsForDate(viewModel.selectedDate)
        }
        .onChange(of: viewModel.selectedDate) { newDate in
            Task {
                await viewModel.loadSetsForDate(newDate)
            }
        }
        .refreshable {
            await viewModel.loadSetsForDate(viewModel.selectedDate)
        }
        .alert("Error", isPresented: .constant(viewModel.errorMessage != nil)) {
                Button("OK") {
                    viewModel.errorMessage = nil
                }
            } message: {
                if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                }
            }
            .alert("Success", isPresented: $viewModel.showingSuccessMessage) {
                Button("OK") { }
            } message: {
                Text(viewModel.successMessage)
            }
        .sheet(isPresented: $viewModel.showingEditSheet) {
            editSetSheet
        }
    }
    
    // MARK: - View Components
    
    private var datePickerSection: some View {
        VStack(spacing: Constants.UI.Spacing.small) {
            Text("Select Date")
                .font(.headline)
                .foregroundColor(.primary)
            
            DatePicker(
                "Workout Date",
                selection: $viewModel.selectedDate,
                displayedComponents: .date
            )
            .datePickerStyle(CompactDatePickerStyle())
            .padding(.horizontal)
            
            // Stats for selected date
            if viewModel.hasDataForSelectedDate {
                HStack {
                    Text("Sets: \(viewModel.selectedDateSets.count)")
                    Spacer()
                    Text("Exercises: \(viewModel.uniqueExercisesCount)")
                    Spacer()
                    Text("Volume: \(String(format: "%.0f", viewModel.totalVolume)) \(viewModel.weightDisplayUnit)")
                }
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.horizontal)
            }
        }
        .padding(Constants.UI.Padding.medium)
        .background(Color(.systemGray6))
    }
    
    private var loadingView: some View {
        VStack(spacing: Constants.UI.Spacing.medium) {
            SwiftUI.ProgressView()
                .progressViewStyle(CircularProgressViewStyle())
                .scaleEffect(1.5)
            
            Text("Loading workouts...")
                .font(.headline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var emptyStateView: some View {
        VStack(spacing: Constants.UI.Spacing.large) {
            Image(systemName: "calendar.badge.exclamationmark")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            
            Text("No workouts found")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.secondary)
            
            Text("No workouts logged for \(viewModel.selectedDateString)")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
    
    private var workoutsList: some View {
        ScrollView {
            LazyVStack(spacing: Constants.UI.Spacing.medium) {
                ForEach(viewModel.selectedDateSets, id: \.id) { set in
                    workoutSetRow(set: set)
                }
            }
            .padding(Constants.UI.Padding.medium)
        }
    }
    
    private func workoutSetRow(set: WorkoutSet) -> some View {
        VStack(alignment: .leading, spacing: Constants.UI.Spacing.small) {
            // Header
            HStack {
                Text(set.exercise)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Text("Set #\(set.sets)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, Constants.UI.Padding.small)
                    .padding(.vertical, 2)
                    .background(Color(.systemGray5))
                    .cornerRadius(4)
            }
            
            // Details
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("\(set.reps) reps")
                        .font(.subheadline)
                        .foregroundColor(.primary)
                    
                    Text("\(String(format: "%.1f", set.weight)) \(viewModel.weightDisplayUnit)")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.blue)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 2) {
                    Text(set.formattedDate)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    if let weightModulation = set.weightModulation {
                        Text(weightModulation)
                            .font(.caption)
                            .foregroundColor(weightModulation.lowercased() == "cutting" ? .red : .blue)
                    }
                }
            }
            
            // Actions
            HStack {
                Button(action: {
                    viewModel.startEditing(set)
                }) {
                    HStack {
                        Image(systemName: "pencil")
                        Text("Edit")
                    }
                    .font(.caption)
                    .foregroundColor(.blue)
                }
                
                Spacer()
                
                Button(action: {
                    Task {
                        await viewModel.deleteSet(set)
                        if userDefaults.enableHaptics {
                            successHaptic()
                        }
                    }
                }) {
                    HStack {
                        Image(systemName: "trash")
                        Text("Delete")
                    }
                    .font(.caption)
                    .foregroundColor(.red)
                }
                .disabled(viewModel.isLoading)
            }
        }
        .padding(Constants.UI.Padding.medium)
        .background(Color(.systemGray6))
        .cornerRadius(Constants.UI.cornerRadius)
    }
    
    private var editSetSheet: some View {
        NavigationView {
            VStack(spacing: Constants.UI.Spacing.large) {
                if let editingSet = viewModel.editingSet {
                    Text("Edit Set")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .padding(.top)
                    
                    Text(editingSet.exercise)
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    VStack(spacing: Constants.UI.Spacing.medium) {
                        // Reps input
                        VStack(alignment: .leading, spacing: Constants.UI.Spacing.small) {
                            Text("Reps")
                                .font(.headline)
                                .foregroundColor(.primary)
                            
                            TextField("Enter reps", text: $viewModel.editReps)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .keyboardType(.numberPad)
                                .toolbar {
                                    ToolbarItemGroup(placement: .keyboard) {
                                        Spacer()
                                        Button("Done") {
                                            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                                        }
                                    }
                                }
                        }
                        
                        // Weight input
                        VStack(alignment: .leading, spacing: Constants.UI.Spacing.small) {
                            Text("Weight (\(viewModel.weightDisplayUnit))")
                                .font(.headline)
                                .foregroundColor(.primary)
                            
                            TextField("Enter weight", text: $viewModel.editWeight)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .keyboardType(.decimalPad)
                                .toolbar {
                                    ToolbarItemGroup(placement: .keyboard) {
                                        Spacer()
                                        Button("Done") {
                                            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                                        }
                                    }
                                }
                        }
                    }
                    .padding(.horizontal)
                    
                    Spacer()
                    
                    // Save button
                    Button(action: {
                        Task {
                            await viewModel.saveEdit()
                        }
                    }) {
                        HStack {
                            if viewModel.isLoading {
                                SwiftUI.ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .scaleEffect(0.8)
                            } else {
                                Image(systemName: "checkmark.circle.fill")
                            }
                            
                            Text("Save Changes")
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(viewModel.canSaveEdit ? Color.blue : Color.gray)
                        .foregroundColor(.white)
                        .cornerRadius(Constants.UI.cornerRadius)
                    }
                    .disabled(!viewModel.canSaveEdit)
                    .padding(.horizontal)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        viewModel.cancelEdit()
                    }
                }
            }
        }
    }
}

// MARK: - Preview

struct HistoryView_Previews: PreviewProvider {
    static var previews: some View {
        HistoryView(apiClient: GainsIQAPIClient(
            baseURL: Config.baseURL,
            apiKey: Config.apiKey,
            authService: AuthService()
        ))
    }
}