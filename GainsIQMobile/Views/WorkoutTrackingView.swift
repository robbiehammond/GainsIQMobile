import SwiftUI

struct WorkoutTrackingView: View {
    @StateObject private var viewModel: WorkoutViewModel
    @StateObject private var userDefaults = UserDefaultsManager.shared
    @State private var showingAlert = false
    
    init(apiClient: GainsIQAPIClient) {
        self._viewModel = StateObject(wrappedValue: WorkoutViewModel(apiClient: apiClient))
    }
    
    var body: some View {
        ScrollView {
                VStack(spacing: Constants.UI.Spacing.large) {
                    // Header
                    headerSection
                    
                    // Main form
                    workoutForm
                    
                    // Action buttons
                    actionButtons
                    
                    // Add exercise section
                    addExerciseSection
                }
                .padding(Constants.UI.Padding.medium)
        }
        .navigationTitle("Workout Tracker")
        .navigationBarTitleDisplayMode(.large)
        .task {
            await viewModel.loadExercises()
        }
        .refreshable {
            await viewModel.loadExercises()
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
        .sheet(isPresented: $viewModel.showingAddExercise) {
            addExerciseSheet
        }
    }
    
    // MARK: - View Components
    
    private var headerSection: some View {
        VStack(spacing: Constants.UI.Spacing.small) {
            Text("Log Your Workout")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            
            HStack {
                Text("Phase:")
                    .foregroundColor(.secondary)
                
                Text(userDefaults.cuttingState.displayName)
                    .fontWeight(.medium)
                    .foregroundColor(userDefaults.cuttingState.isCutting ? .red : .blue)
                
                Spacer()
                
                Text("Unit:")
                    .foregroundColor(.secondary)
                
                Text(userDefaults.weightUnit.displayName)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
            }
            .font(.caption)
            .padding(.horizontal)
        }
    }
    
    private var workoutForm: some View {
        VStack(spacing: Constants.UI.Spacing.medium) {
            // Exercise selection
            exerciseSelector
            
            // Reps selection
            repsSelector
            
            // Weight input
            weightInput
            
            // Settings section
            settingsSection
        }
        .padding(Constants.UI.Padding.medium)
        .background(Color(.systemGray6))
        .cornerRadius(Constants.UI.cornerRadius)
    }
    
    private var exerciseSelector: some View {
        VStack(alignment: .leading, spacing: Constants.UI.Spacing.small) {
            Text("Exercise")
                .font(.headline)
                .foregroundColor(.primary)
            
            if viewModel.exercises.isEmpty {
                Text("Loading exercises...")
                    .foregroundColor(.secondary)
                    .italic()
            } else {
                VStack(spacing: Constants.UI.Spacing.small) {
                    // Search bar
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.secondary)
                        TextField("Search exercises...", text: $viewModel.searchText)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                    }
                    
                    // Selected exercise display
                    if !userDefaults.selectedExercise.isEmpty {
                        HStack {
                            Text("Selected:")
                                .foregroundColor(.secondary)
                            Text(userDefaults.selectedExercise)
                                .fontWeight(.medium)
                                .foregroundColor(.primary)
                            Spacer()
                            Button("Clear") {
                                userDefaults.selectedExercise = ""
                            }
                            .font(.caption)
                            .foregroundColor(.blue)
                        }
                        .padding(.horizontal, Constants.UI.Padding.small)
                        .padding(.vertical, Constants.UI.Padding.tiny)
                        .background(Color(.systemGray5))
                        .cornerRadius(6)
                    }
                    
                    // Exercise list
                    if !viewModel.searchText.isEmpty || userDefaults.selectedExercise.isEmpty {
                        ScrollView {
                            LazyVStack(spacing: Constants.UI.Spacing.tiny) {
                                ForEach(viewModel.filteredExercises, id: \.name) { exercise in
                                    Button(action: {
                                        userDefaults.selectedExercise = exercise.name
                                        viewModel.searchText = ""
                                    }) {
                                        HStack {
                                            Text(exercise.name)
                                                .foregroundColor(.primary)
                                            Spacer()
                                            if userDefaults.selectedExercise == exercise.name {
                                                Image(systemName: "checkmark")
                                                    .foregroundColor(.blue)
                                            }
                                        }
                                        .padding(.horizontal, Constants.UI.Padding.small)
                                        .padding(.vertical, Constants.UI.Padding.tiny)
                                        .background(Color(.systemBackground))
                                        .cornerRadius(6)
                                    }
                                }
                            }
                        }
                        .frame(maxHeight: 200)
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                    }
                }
            }
        }
    }
    
    private var repsSelector: some View {
        VStack(alignment: .leading, spacing: Constants.UI.Spacing.small) {
            Text("Reps")
                .font(.headline)
                .foregroundColor(.primary)
            
            Picker("Reps", selection: $viewModel.reps) {
                Text("Select Reps").tag("")
                ForEach(viewModel.repOptions, id: \.self) { rep in
                    Text(rep).tag(rep)
                }
            }
            .pickerStyle(MenuPickerStyle())
            .tint(.primary)
        }
    }
    
    private var weightInput: some View {
        VStack(alignment: .leading, spacing: Constants.UI.Spacing.small) {
            Text("Weight (\(viewModel.weightDisplayUnit))")
                .font(.headline)
                .foregroundColor(.primary)
            
            TextField("Enter weight", text: $viewModel.weight)
                .keyboardType(.decimalPad)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .toolbar {
                    ToolbarItemGroup(placement: .keyboard) {
                        Spacer()
                        Button("Done") {
                            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                        }
                    }
                }
                .onTapGesture {
                    if userDefaults.enableHaptics {
                        hapticFeedback()
                    }
                }
        }
    }
    
    private var settingsSection: some View {
        VStack(spacing: Constants.UI.Spacing.medium) {
            Divider()
            
            // Weight unit toggle
            HStack {
                Text("Weight Unit")
                    .font(.headline)
                
                Spacer()
                
                Picker("Weight Unit", selection: $userDefaults.weightUnit) {
                    ForEach(WeightUnit.allCases, id: \.self) { unit in
                        Text(unit.displayName).tag(unit)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .frame(width: 200)
            }
            
            // Cutting/Bulking toggle
            HStack {
                Text("Phase")
                    .font(.headline)
                
                Spacer()
                
                Picker("Phase", selection: $userDefaults.cuttingState) {
                    ForEach(CuttingState.allCases, id: \.self) { state in
                        Text(state.displayName).tag(state)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .frame(width: 200)
            }
            
            // Custom timestamp toggle
            HStack {
                Text("Custom Time")
                    .font(.headline)
                
                Spacer()
                
                Button(action: {
                    viewModel.toggleTimestampPicker()
                }) {
                    HStack {
                        Image(systemName: viewModel.showingTimestampPicker ? "clock.fill" : "clock")
                        Text(viewModel.showingTimestampPicker ? "Cancel" : "Set Time")
                    }
                    .font(.caption)
                    .foregroundColor(.blue)
                }
            }
            
            // Timestamp picker (when enabled)
            if viewModel.showingTimestampPicker {
                VStack(alignment: .leading, spacing: Constants.UI.Spacing.small) {
                    Text("Workout Time")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    DatePicker(
                        "Workout Time",
                        selection: Binding(
                            get: { viewModel.customTimestamp ?? Date() },
                            set: { viewModel.customTimestamp = $0 }
                        ),
                        displayedComponents: [.date, .hourAndMinute]
                    )
                    .datePickerStyle(CompactDatePickerStyle())
                    .labelsHidden()
                }
            }
        }
    }
    
    private var actionButtons: some View {
        VStack(spacing: Constants.UI.Spacing.medium) {
            // Log workout button
            Button(action: {
                Task {
                    await viewModel.logWorkout()
                    if userDefaults.enableHaptics {
                        successHaptic()
                    }
                }
            }) {
                HStack {
                    if viewModel.isLoading {
                        SwiftUI.ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(0.8)
                    } else {
                        Image(systemName: "plus.circle.fill")
                    }
                    
                    Text("Log Workout")
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(viewModel.canSubmit ? Color.blue : Color.gray)
                .foregroundColor(.white)
                .cornerRadius(Constants.UI.cornerRadius)
            }
            .disabled(!viewModel.canSubmit)
            
            // Secondary actions
            HStack(spacing: Constants.UI.Spacing.medium) {
                Button(action: {
                    Task {
                        await viewModel.popLastSet()
                    }
                }) {
                    HStack {
                        Image(systemName: "arrow.uturn.backward")
                        Text("Pop Last Set")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.orange)
                    .foregroundColor(.white)
                    .cornerRadius(Constants.UI.cornerRadius)
                }
                .disabled(viewModel.isLoading)
                
            }
        }
    }
    
    private var addExerciseSection: some View {
        VStack(spacing: Constants.UI.Spacing.medium) {
            Divider()
            
            Text("Don't see your exercise?")
                .font(.headline)
                .foregroundColor(.secondary)
            
            Button(action: {
                viewModel.showingAddExercise = true
            }) {
                HStack {
                    Image(systemName: "plus.circle")
                    Text("Add New Exercise")
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.green)
                .foregroundColor(.white)
                .cornerRadius(Constants.UI.cornerRadius)
            }
            .disabled(viewModel.isLoading)
        }
    }
    
    private var addExerciseSheet: some View {
        NavigationView {
            VStack(spacing: Constants.UI.Spacing.large) {
                Text("Add New Exercise")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .padding(.top)
                
                TextField("Exercise name", text: $viewModel.newExerciseName)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding(.horizontal)
                
                Spacer()
                
                Button(action: {
                    Task {
                        await viewModel.addExercise()
                    }
                }) {
                    HStack {
                        if viewModel.isLoading {
                            SwiftUI.ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(0.8)
                        } else {
                            Image(systemName: "plus.circle.fill")
                        }
                        
                        Text("Add Exercise")
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(!viewModel.newExerciseName.trimmed.isEmpty ? Color.green : Color.gray)
                    .foregroundColor(.white)
                    .cornerRadius(Constants.UI.cornerRadius)
                }
                .disabled(viewModel.newExerciseName.trimmed.isEmpty || viewModel.isLoading)
                .padding(.horizontal)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        viewModel.showingAddExercise = false
                        viewModel.newExerciseName = ""
                    }
                }
            }
        }
    }
}

// MARK: - Preview

struct WorkoutTrackingView_Previews: PreviewProvider {
    static var previews: some View {
        WorkoutTrackingView(apiClient: GainsIQAPIClient(
            baseURL: Constants.API.defaultBaseURL,
            apiKey: Config.apiKey
        ))
    }
}
