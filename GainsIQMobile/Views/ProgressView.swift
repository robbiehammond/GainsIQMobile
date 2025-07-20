import SwiftUI
import Charts

struct ProgressChartsView: View {
    @StateObject private var viewModel: ProgressViewModel
    @StateObject private var userDefaults = UserDefaultsManager.shared
    @State private var selectedDataPoint: ExerciseProgressDataPoint?
    
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
                if viewModel.chartType == .combined {
                    combinedChart
                } else {
                    standardChart
                }
            }
            
            // Chart legend and data point info
            VStack(spacing: Constants.UI.Spacing.small) {
                if let selectedPoint = selectedDataPoint {
                    dataPointDetail(for: selectedPoint)
                } else {
                    chartLegend
                }
                
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
    
    // MARK: - Chart Views
    
    private var combinedChart: some View {
        Chart(viewModel.chartData, id: \.date) { dataPoint in
            // Bar chart for normalized weight
            BarMark(
                x: .value("Date", dataPoint.date),
                y: .value("Weight", normalizedWeight(dataPoint.averageWeight))
            )
            .foregroundStyle(
                LinearGradient(
                    gradient: Gradient(colors: [
                        dataPoint.isFromCuttingPhase ? .red.opacity(0.7) : .blue.opacity(0.7),
                        dataPoint.isFromCuttingPhase ? .red.opacity(0.3) : .blue.opacity(0.3)
                    ]),
                    startPoint: .bottom,
                    endPoint: .top
                )
            )
            .opacity(0.8)
            
            // Line chart for normalized reps
            LineMark(
                x: .value("Date", dataPoint.date),
                y: .value("Reps", normalizedReps(dataPoint.averageReps))
            )
            .foregroundStyle(.orange)
            .lineStyle(StrokeStyle(lineWidth: 3))
            .symbol(.circle)
            .symbolSize(60)
        }
        .frame(height: 280)
        .chartXScale(domain: viewModel.chartTimeRange)
        .chartYScale(domain: 0...100) // Fixed 0-100 scale for normalized values
        .chartXAxis {
            AxisMarks(values: .automatic(desiredCount: 5)) { _ in
                AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [2, 4]))
                    .foregroundStyle(.secondary.opacity(0.3))
                AxisValueLabel(format: .dateTime.month(.abbreviated).day())
                    .foregroundStyle(.secondary)
            }
        }
        .chartYAxis {
            AxisMarks(values: [0, 25, 50, 75, 100]) { _ in
                AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [2, 4]))
                    .foregroundStyle(.secondary.opacity(0.3))
                // Remove axis labels by not providing AxisValueLabel
            }
        }
        .chartPlotStyle { plotArea in
            plotArea
                .background(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color(.systemGray6).opacity(0.1),
                            Color(.systemGray6).opacity(0.3)
                        ]),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .cornerRadius(12)
        }
        .chartBackground { chartProxy in
            GeometryReader { geometry in
                Rectangle()
                    .fill(Color.clear)
                    .contentShape(Rectangle())
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onEnded { value in
                                handleChartTap(at: value.location, in: geometry, chartProxy: chartProxy)
                            }
                    )
            }
        }
    }
    
    private var standardChart: some View {
        Chart(viewModel.chartData, id: \.date) { dataPoint in
            LineMark(
                x: .value("Date", dataPoint.date),
                y: .value("Value", chartValue(for: dataPoint))
            )
            .foregroundStyle(
                LinearGradient(
                    gradient: Gradient(colors: [
                        dataPoint.isFromCuttingPhase ? .red : .blue,
                        dataPoint.isFromCuttingPhase ? .red.opacity(0.6) : .blue.opacity(0.6)
                    ]),
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .lineStyle(StrokeStyle(lineWidth: 3))
            .symbol(.circle)
            .symbolSize(60)
            
            PointMark(
                x: .value("Date", dataPoint.date),
                y: .value("Value", chartValue(for: dataPoint))
            )
            .foregroundStyle(dataPoint.isFromCuttingPhase ? Color.red : Color.blue)
            .symbolSize(40)
            .opacity(0)
        }
        .frame(height: 280)
        .chartXScale(domain: viewModel.chartTimeRange)
        .chartYScale(domain: viewModel.chartYAxisRange)
        .chartXAxis {
            AxisMarks(values: .automatic(desiredCount: 5)) { _ in
                AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [2, 4]))
                    .foregroundStyle(.secondary.opacity(0.3))
                AxisValueLabel(format: .dateTime.month(.abbreviated).day())
                    .foregroundStyle(.secondary)
            }
        }
        .chartYAxis {
            AxisMarks(values: .automatic(desiredCount: 6)) { value in
                AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [2, 4]))
                    .foregroundStyle(.secondary.opacity(0.3))
                AxisValueLabel {
                    if let val = value.as(Double.self) {
                        Text(formatAxisValue(val))
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .chartPlotStyle { plotArea in
            plotArea
                .background(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color(.systemGray6).opacity(0.1),
                            Color(.systemGray6).opacity(0.3)
                        ]),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .cornerRadius(12)
        }
        .onTapGesture { location in
            handleChartTap(at: location)
        }
    }
    
    private var chartLegend: some View {
        HStack(spacing: Constants.UI.Spacing.medium) {
            if viewModel.chartType == .combined {
                HStack(spacing: 4) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(LinearGradient(
                            gradient: Gradient(colors: [.blue.opacity(0.7), .blue.opacity(0.3)]),
                            startPoint: .top,
                            endPoint: .bottom
                        ))
                        .frame(width: 12, height: 8)
                    Text("Avg Weight")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                HStack(spacing: 4) {
                    Circle()
                        .stroke(.orange, lineWidth: 2)
                        .fill(.orange.opacity(0.3))
                        .frame(width: 8, height: 8)
                    Text("Avg Reps")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            } else {
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
            }
            
            Spacer()
        }
    }
    
    private func dataPointDetail(for point: ExerciseProgressDataPoint) -> some View {
        VStack(spacing: 4) {
            HStack {
                Text("📅 \(point.date, format: .dateTime.month(.abbreviated).day().year())")
                    .font(.caption)
                    .fontWeight(.medium)
                
                Spacer()
                
                Button("✕") {
                    selectedDataPoint = nil
                }
                .font(.caption)
                .foregroundColor(.secondary)
            }
            
            HStack(spacing: Constants.UI.Spacing.medium) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Avg Weight")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    Text(String(format: "%.1f %@", point.averageWeight, viewModel.weightDisplayUnit))
                        .font(.caption)
                        .fontWeight(.semibold)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Avg Reps")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    Text(String(format: "%.1f", point.averageReps))
                        .font(.caption)
                        .fontWeight(.semibold)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Sets")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    Text("\(point.setCount)")
                        .font(.caption)
                        .fontWeight(.semibold)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Phase")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    Text(point.isFromCuttingPhase ? "Cutting" : "Bulking")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(point.isFromCuttingPhase ? .red : .blue)
                }
                
                Spacer()
            }
        }
        .padding(.horizontal, Constants.UI.Padding.small)
        .padding(.vertical, 6)
        .background(Color(.systemBackground))
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
        )
    }
    
    // MARK: - Helper Methods
    
    private func handleChartTap(at location: CGPoint, in geometry: GeometryProxy, chartProxy: ChartProxy) {
        let frame = geometry[chartProxy.plotAreaFrame]
        let origin = geometry[chartProxy.plotAreaFrame].origin
        
        // Calculate relative position within the plot area
        let relativeX = (location.x - origin.x) / frame.width
        
        guard !viewModel.chartData.isEmpty, relativeX >= 0, relativeX <= 1 else { return }
        
        // Find the closest data point
        let dataIndex = Int(relativeX * CGFloat(viewModel.chartData.count - 1))
        let clampedIndex = max(0, min(dataIndex, viewModel.chartData.count - 1))
        
        selectedDataPoint = viewModel.chartData[clampedIndex]
        
        // Haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
    }
    
    // Add fallback for standard charts
    private func handleChartTap(at location: CGPoint) {
        // Simple fallback for standard charts
        let chartWidth: CGFloat = 280
        let relativeX = location.x / chartWidth
        
        guard !viewModel.chartData.isEmpty else { return }
        
        let dataIndex = Int(relativeX * CGFloat(viewModel.chartData.count))
        let clampedIndex = max(0, min(dataIndex, viewModel.chartData.count - 1))
        
        selectedDataPoint = viewModel.chartData[clampedIndex]
        
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
    }
    
    // Normalize weight values to 0-100 scale based on min/max in dataset
    private func normalizedWeight(_ weight: Double) -> Double {
        guard !viewModel.chartData.isEmpty else { return 50 }
        
        let weights = viewModel.chartData.map { $0.averageWeight }
        let minWeight = weights.min() ?? 0
        let maxWeight = weights.max() ?? weight
        
        guard maxWeight > minWeight else { return 50 }
        
        // Normalize to 20-80 range to leave room for reps line
        let normalizedValue = ((weight - minWeight) / (maxWeight - minWeight)) * 60 + 20
        return normalizedValue
    }
    
    // Normalize reps values to 0-100 scale based on min/max in dataset
    private func normalizedReps(_ reps: Double) -> Double {
        guard !viewModel.chartData.isEmpty else { return 50 }
        
        let allReps = viewModel.chartData.map { $0.averageReps }
        let minReps = allReps.min() ?? 0
        let maxReps = allReps.max() ?? reps
        
        guard maxReps > minReps else { return 50 }
        
        // Normalize to 20-80 range to match weight normalization
        let normalizedValue = ((reps - minReps) / (maxReps - minReps)) * 60 + 20
        return normalizedValue
    }
    
    private func chartValue(for dataPoint: ExerciseProgressDataPoint) -> Double {
        switch viewModel.chartType {
        case .maxWeight:
            return dataPoint.maxWeight
        case .averageWeight:
            return dataPoint.averageWeight
        case .estimated1RM:
            return dataPoint.estimated1RM
        case .combined:
            return dataPoint.averageWeight // Default fallback
        }
    }
    
    private func formatAxisValue(_ value: Double) -> String {
        switch viewModel.chartType {
        case .maxWeight, .averageWeight, .estimated1RM:
            return String(format: "%.1f %@", value, viewModel.weightDisplayUnit)
        case .combined:
            return String(format: "%.1f", value)
        }
    }
    
    private func formatCombinedAxisValue(_ value: Double) -> String {
        // No longer used since we removed axis labels
        return ""
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
