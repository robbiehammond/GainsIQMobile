import SwiftUI
import Charts

struct ProgressChartsView: View {
    @StateObject private var viewModel: ProgressViewModel
    @StateObject private var userDefaults = UserDefaultsManager.shared
    
    init(apiClient: GainsIQAPIClient) {
        self._viewModel = StateObject(wrappedValue: ProgressViewModel(apiClient: apiClient))
    }
    
    var body: some View {
        ScrollView {
                VStack(spacing: Constants.UI.Spacing.large) {
                    // Header section
                    headerSection
                    
                    // Exercise selector
                    exerciseSelector
                    
                    // Progress chart
                    if viewModel.hasData {
                        chartSection
                    } else if viewModel.hasSelectedExercise {
                        emptyStateView
                    }
                    
                    // Progress summary
                    if viewModel.hasData {
                        summarySection
                    }
                }
                .padding(Constants.UI.Padding.medium)
        }
        .navigationTitle("Progress")
        .navigationBarTitleDisplayMode(.large)
        .task {
            await viewModel.loadExercises()
        }
        .refreshable {
            await viewModel.loadProgressData()
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
    }
    
    // MARK: - View Components
    
    private var headerSection: some View {
        VStack(spacing: Constants.UI.Spacing.small) {
            Text("Exercise Progress")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            
            if viewModel.hasSelectedExercise {
                HStack {
                    Text("Exercise:")
                        .foregroundColor(.secondary)
                    
                    Text(userDefaults.selectedExercise)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    Text("Unit: \(viewModel.weightDisplayUnit)")
                        .foregroundColor(.secondary)
                }
                .font(.caption)
                .padding(.horizontal)
            }
        }
    }
    
    private var exerciseSelector: some View {
        VStack(alignment: .leading, spacing: Constants.UI.Spacing.small) {
            Text("Select Exercise")
                .font(.headline)
                .foregroundColor(.primary)
            
            if viewModel.exercises.isEmpty {
                Text("Loading exercises...")
                    .foregroundColor(.secondary)
                    .italic()
            } else {
                Picker("Exercise", selection: $userDefaults.selectedExercise) {
                    Text("Select Exercise").tag("")
                    ForEach(viewModel.exercises, id: \.name) { exercise in
                        Text(exercise.name).tag(exercise.name)
                    }
                }
                .pickerStyle(MenuPickerStyle())
                .tint(.primary)
                .onChange(of: userDefaults.selectedExercise) { newExercise in
                    viewModel.changeExercise(newExercise)
                }
            }
        }
        .padding(Constants.UI.Padding.medium)
        .background(Color(.systemGray6))
        .cornerRadius(Constants.UI.cornerRadius)
    }
    
    private var chartSection: some View {
        VStack(alignment: .leading, spacing: Constants.UI.Spacing.medium) {
            // Chart controls
            HStack {
                Text(viewModel.chartTitle)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Menu("Chart Type") {
                    ForEach(ProgressChartType.allCases, id: \.self) { type in
                        Button(type.displayName) {
                            viewModel.changeChartType(type)
                        }
                    }
                }
                .font(.caption)
                .foregroundColor(.blue)
            }
            
            // Time range selector
            HStack {
                Text("Time Range:")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Picker("Time Range", selection: $viewModel.selectedTimeRange) {
                    ForEach(ChartTimeRange.allCases, id: \.self) { range in
                        Text(range.displayName)
                            .tag(range)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .onChange(of: viewModel.selectedTimeRange) { newRange in
                    viewModel.changeTimeRange(newRange)
                }
            }
            
            // Chart
            if viewModel.chartData.isEmpty {
                Text("No data for selected time range")
                    .foregroundColor(.secondary)
                    .italic()
                    .frame(maxWidth: .infinity, alignment: .center)
                    .frame(height: 200)
            } else {
                Chart(viewModel.chartData, id: \.date) { dataPoint in
                    LineMark(
                        x: .value("Date", dataPoint.date),
                        y: .value("Value", chartValue(for: dataPoint))
                    )
                    .foregroundStyle(dataPoint.isFromCuttingPhase ? Color.red : Color.blue)
                    .symbol(.circle)
                    .symbolSize(50)
                    
                    PointMark(
                        x: .value("Date", dataPoint.date),
                        y: .value("Value", chartValue(for: dataPoint))
                    )
                    .foregroundStyle(dataPoint.isFromCuttingPhase ? Color.red : Color.blue)
                    .symbolSize(30)
                }
                .frame(height: 250)
                .chartXScale(domain: viewModel.chartTimeRange)
                .chartYScale(domain: viewModel.chartYAxisRange)
                .chartXAxis {
                    AxisMarks(values: .automatic(desiredCount: 5)) { _ in
                        AxisGridLine()
                        AxisValueLabel(format: .dateTime.month(.abbreviated).day())
                    }
                }
                .chartYAxis {
                    AxisMarks(values: .automatic(desiredCount: 6)) { value in
                        AxisGridLine()
                        AxisValueLabel {
                            if let val = value.as(Double.self) {
                                Text(formatAxisValue(val))
                            }
                        }
                    }
                }
                .chartPlotStyle { plotArea in
                    plotArea
                        .background(Color(.systemGray6).opacity(0.3))
                        .cornerRadius(8)
                }
            }
            
            // Chart legend
            HStack(spacing: Constants.UI.Spacing.medium) {
                HStack(spacing: 4) {
                    Circle()
                        .fill(Color.blue)
                        .frame(width: 8, height: 8)
                    Text("Bulking")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                HStack(spacing: 4) {
                    Circle()
                        .fill(Color.red)
                        .frame(width: 8, height: 8)
                    Text("Cutting")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Text(viewModel.progressSummary)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(Constants.UI.Padding.medium)
        .background(Color(.systemGray6))
        .cornerRadius(Constants.UI.cornerRadius)
    }
    
    private var summarySection: some View {
        VStack(alignment: .leading, spacing: Constants.UI.Spacing.medium) {
            Text("Progress Summary")
                .font(.headline)
                .foregroundColor(.primary)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: Constants.UI.Spacing.medium) {
                StatCard(
                    title: "Total Workouts",
                    value: "\(viewModel.totalWorkouts)",
                    icon: "calendar"
                )
                
                StatCard(
                    title: "Total Sets",
                    value: "\(viewModel.totalSets)",
                    icon: "list.number"
                )
                
                StatCard(
                    title: "Total Volume",
                    value: String(format: "%.0f %@", viewModel.totalVolume, viewModel.weightDisplayUnit),
                    icon: "scalemass"
                )
                
                StatCard(
                    title: "Current Max",
                    value: String(format: "%.1f %@", viewModel.currentMaxWeight, viewModel.weightDisplayUnit),
                    icon: "trophy"
                )
            }
        }
        .padding(Constants.UI.Padding.medium)
        .background(Color(.systemGray6))
        .cornerRadius(Constants.UI.cornerRadius)
    }
    
    private var emptyStateView: some View {
        VStack(spacing: Constants.UI.Spacing.large) {
            Image(systemName: "chart.line.uptrend.xyaxis")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            
            Text("No Data Available")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.secondary)
            
            Text("Start logging workouts for \(userDefaults.selectedExercise) to see your progress here")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .frame(maxWidth: .infinity)
        .padding(Constants.UI.Padding.large)
        .background(Color(.systemGray6))
        .cornerRadius(Constants.UI.cornerRadius)
    }
    
    // MARK: - Helper Methods
    
    private func chartValue(for dataPoint: ExerciseProgressDataPoint) -> Double {
        switch viewModel.chartType {
        case .maxWeight:
            return dataPoint.maxWeight
        case .averageWeight:
            return dataPoint.averageWeight
        case .estimated1RM:
            return dataPoint.estimated1RM
        }
    }
    
    private func formatAxisValue(_ value: Double) -> String {
        switch viewModel.chartType {
        case .maxWeight, .averageWeight, .estimated1RM:
            return String(format: "%.1f %@", value, viewModel.weightDisplayUnit)
        }
    }
}

// MARK: - Supporting Views

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    
    var body: some View {
        VStack(spacing: Constants.UI.Spacing.small) {
            HStack {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(.blue)
                
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text(value)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(Constants.UI.Padding.small)
        .background(Color(.systemBackground))
        .cornerRadius(Constants.UI.cornerRadius / 2)
    }
}

// MARK: - Preview

struct ProgressChartsView_Previews: PreviewProvider {
    static var previews: some View {
        ProgressChartsView(apiClient: GainsIQAPIClient(
            baseURL: Constants.API.defaultBaseURL,
            apiKey: Config.apiKey,
            authService: AuthService()
        ))
    }
}
