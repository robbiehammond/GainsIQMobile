import SwiftUI
import Charts
import DGCharts

struct ProgressChartsView: View {
    @StateObject private var viewModel: ProgressViewModel
    @StateObject private var userDefaults = UserDefaultsManager.shared
    @State private var selectedDataPoint: ExerciseProgressDataPoint?
    @State private var selectedDate: Date?
    
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
                
                HStack {
                    Text(viewModel.progressSummary)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    // Debug button to test detail view
                    if !viewModel.chartData.isEmpty {
                        Button("Test Detail") {
                            selectedDataPoint = viewModel.chartData.first
                        }
                        .font(.caption2)
                        .foregroundColor(.blue)
                    }
                }
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
        CombinedChartView(
            chartData: viewModel.chartData,
            selectedDataPoint: $selectedDataPoint,
            userDefaults: userDefaults
        )
        .frame(height: 280)
        .cornerRadius(12)
        .onChange(of: selectedDataPoint) { newSelection in
            // This will trigger the chart to update its highlight
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
            .symbolSize(isDataPointSelected(dataPoint) ? 80 : 60)
            
            PointMark(
                x: .value("Date", dataPoint.date),
                y: .value("Value", chartValue(for: dataPoint))
            )
            .foregroundStyle(dataPoint.isFromCuttingPhase ? Color.red : Color.blue)
            .symbolSize(40)
            .opacity(0)
            
            // Highlight ring for selected data point
            if isDataPointSelected(dataPoint) {
                PointMark(
                    x: .value("Date", dataPoint.date),
                    y: .value("Value", chartValue(for: dataPoint))
                )
                .foregroundStyle(.yellow)
                .symbolSize(100)
                .opacity(0.3)
            }
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
        .overlay(
            GeometryReader { geometry in
                Rectangle()
                    .fill(Color.clear)
                    .contentShape(Rectangle())
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onEnded { value in
                                handleChartTap(at: value.location, geometry: geometry)
                            }
                    )
            }
        )
    }
    
    private var chartLegend: some View {
        HStack(spacing: Constants.UI.Spacing.medium) {
            if viewModel.chartType == .combined {
                HStack(spacing: 4) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color.blue.opacity(0.7))
                        .frame(width: 12, height: 8)
                    Text("Weight (Left Axis)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                HStack(spacing: 4) {
                    Circle()
                        .fill(.orange)
                        .frame(width: 8, height: 8)
                    Text("Reps (Right Axis)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                HStack(spacing: 4) {
                    Circle()
                        .fill(Color.red.opacity(0.7))
                        .frame(width: 6, height: 6)
                    Text("Cutting")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    
                    Circle()
                        .fill(Color.blue.opacity(0.7))
                        .frame(width: 6, height: 6)
                    Text("Bulking")
                        .font(.caption2)
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
        let setsForDate = viewModel.getSetsForDate(point.date)
        print("Showing detail for point: \(point.date), found \(setsForDate.count) sets")
        
        return VStack(spacing: 8) {
            // Header with navigation
            HStack {
                // Left navigation button
                Button(action: navigateToPreviousDataPoint) {
                    Image(systemName: "chevron.left")
                        .font(.title2)
                        .foregroundColor(canNavigateLeft ? .blue : .gray)
                }
                .disabled(!canNavigateLeft)
                
                Spacer()
                
                VStack(alignment: .center, spacing: 2) {
                    Text("📅 \(point.date, format: .dateTime.month(.abbreviated).day().year())")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    Text("\(userDefaults.selectedExercise)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Right navigation button
                Button(action: navigateToNextDataPoint) {
                    Image(systemName: "chevron.right")
                        .font(.title2)
                        .foregroundColor(canNavigateRight ? .blue : .gray)
                }
                .disabled(!canNavigateRight)
                
                // Close button
                Button("✕") {
                    selectedDataPoint = nil
                }
                .font(.title3)
                .foregroundColor(.secondary)
                .padding(.leading, 8)
            }
            
            Divider()
            
            // Summary Stats
            HStack(spacing: Constants.UI.Spacing.medium) {
                StatMiniCard(title: "Avg Weight", value: String(format: "%.1f %@", point.averageWeight, viewModel.weightDisplayUnit), color: .blue)
                StatMiniCard(title: "Avg Reps", value: String(format: "%.1f", point.averageReps), color: .orange)
                StatMiniCard(title: "Total Sets", value: "\(point.setCount)", color: .green)
                StatMiniCard(title: "Est 1RM", value: String(format: "%.1f %@", point.estimated1RM, viewModel.weightDisplayUnit), color: .purple)
            }
            
            if !setsForDate.isEmpty {
                Divider()
                
                // Individual Sets
                VStack(alignment: .leading, spacing: 6) {
                    Text("Individual Sets")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.secondary)
                    
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible()),
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 4) {
                        // Header
                        Text("Set")
                            .font(.caption2)
                            .fontWeight(.medium)
                            .foregroundColor(.secondary)
                        Text("Weight")
                            .font(.caption2)
                            .fontWeight(.medium)
                            .foregroundColor(.secondary)
                        Text("Reps")
                            .font(.caption2)
                            .fontWeight(.medium)
                            .foregroundColor(.secondary)
                        Text("1RM")
                            .font(.caption2)
                            .fontWeight(.medium)
                            .foregroundColor(.secondary)
                        
                        // Individual sets data
                        ForEach(Array(setsForDate.enumerated()), id: \.offset) { index, set in
                            Text("\(index + 1)")
                                .font(.caption2)
                                .foregroundColor(.primary)
                            
                            Text(String(format: "%.1f", set.weight))
                                .font(.caption2)
                                .fontWeight(.medium)
                                .foregroundColor(.primary)
                            
                            Text(set.reps)
                                .font(.caption2)
                                .fontWeight(.medium)
                                .foregroundColor(.primary)
                            
                            Text(String(format: "%.0f", set.estimated1RM))
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            
            // Phase indicator
            HStack {
                Spacer()
                HStack(spacing: 4) {
                    Circle()
                        .fill(point.isFromCuttingPhase ? .red : .blue)
                        .frame(width: 6, height: 6)
                    Text(point.isFromCuttingPhase ? "Cutting Phase" : "Bulking Phase")
                        .font(.caption2)
                        .foregroundColor(point.isFromCuttingPhase ? .red : .blue)
                }
                Spacer()
            }
        }
        .padding(Constants.UI.Padding.medium)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
    
    // MARK: - Helper Methods
    
    private func isDataPointSelected(_ dataPoint: ExerciseProgressDataPoint) -> Bool {
        guard let selectedPoint = selectedDataPoint else { return false }
        return Calendar.current.isDate(dataPoint.date, inSameDayAs: selectedPoint.date)
    }
    
    private var canNavigateLeft: Bool {
        guard let selectedPoint = selectedDataPoint,
              let currentIndex = viewModel.chartData.firstIndex(where: { $0.date == selectedPoint.date }) else {
            return false
        }
        return currentIndex > 0
    }
    
    private var canNavigateRight: Bool {
        guard let selectedPoint = selectedDataPoint,
              let currentIndex = viewModel.chartData.firstIndex(where: { $0.date == selectedPoint.date }) else {
            return false
        }
        return currentIndex < viewModel.chartData.count - 1
    }
    
    private func navigateToPreviousDataPoint() {
        guard let selectedPoint = selectedDataPoint,
              let currentIndex = viewModel.chartData.firstIndex(where: { $0.date == selectedPoint.date }),
              currentIndex > 0 else {
            return
        }
        
        selectedDataPoint = viewModel.chartData[currentIndex - 1]
        
        // Haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
    }
    
    private func navigateToNextDataPoint() {
        guard let selectedPoint = selectedDataPoint,
              let currentIndex = viewModel.chartData.firstIndex(where: { $0.date == selectedPoint.date }),
              currentIndex < viewModel.chartData.count - 1 else {
            return
        }
        
        selectedDataPoint = viewModel.chartData[currentIndex + 1]
        
        // Haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
    }
    
    private func handleChartTap(at location: CGPoint, geometry: GeometryProxy) {
        guard !viewModel.chartData.isEmpty else { 
            print("No chart data available")
            return 
        }
        
        let chartFrame = geometry.frame(in: .local)
        
        // Account for axis margins - charts typically have margins for labels
        let leftMargin: CGFloat = 40  // Space for Y-axis labels
        let rightMargin: CGFloat = 20 // Right padding
        let topMargin: CGFloat = 20   // Top padding
        let bottomMargin: CGFloat = 40 // Space for X-axis labels
        
        // Calculate the actual plot area
        let plotAreaX = leftMargin
        let plotAreaWidth = chartFrame.width - leftMargin - rightMargin
        let plotAreaY = topMargin
        let plotAreaHeight = chartFrame.height - topMargin - bottomMargin
        
        // Check if touch is within the plot area
        guard location.x >= plotAreaX && location.x <= plotAreaX + plotAreaWidth &&
              location.y >= plotAreaY && location.y <= plotAreaY + plotAreaHeight else {
            print("Touch outside plot area at: \(location)")
            return
        }
        
        // Calculate relative position within the plot area
        let relativeX = (location.x - plotAreaX) / plotAreaWidth
        
        print("Chart frame: \(chartFrame)")
        print("Plot area: x=\(plotAreaX), width=\(plotAreaWidth)")
        print("Tapped at: \(location), relative: \(relativeX)")
        
        // Ensure we're within bounds
        guard relativeX >= 0 && relativeX <= 1 else { 
            print("Relative X outside bounds: \(relativeX)")
            return 
        }
        
        // Find the closest data point
        let dataCount = viewModel.chartData.count
        guard dataCount > 0 else { return }
        
        // For better accuracy, find the closest point by calculating distance to each
        var closestIndex = 0
        var minDistance: CGFloat = CGFloat.greatestFiniteMagnitude
        
        for (index, _) in viewModel.chartData.enumerated() {
            let dataPointX = CGFloat(index) / CGFloat(dataCount - 1)
            let distance = abs(dataPointX - relativeX)
            
            if distance < minDistance {
                minDistance = distance
                closestIndex = index
            }
        }
        
        let dataPoint = viewModel.chartData[closestIndex]
        selectedDataPoint = dataPoint
        
        print("Selected data point \(closestIndex) for date: \(dataPoint.date)")
        
        // Haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
    }
    
    
    private func handleChartTapFallback(at location: CGPoint) {
        guard !viewModel.chartData.isEmpty else { return }
        
        // Fallback to old method
        let chartWidth: CGFloat = 280
        let relativeX = location.x / chartWidth
        guard relativeX >= 0 && relativeX <= 1 else { return }
        
        let dataIndex = Int(relativeX * CGFloat(viewModel.chartData.count - 1))
        let clampedIndex = max(0, min(dataIndex, viewModel.chartData.count - 1))
        selectedDataPoint = viewModel.chartData[clampedIndex]
        
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
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

struct StatMiniCard: View {
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 2) {
            Text(title)
                .font(.caption2)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Text(value)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(color)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 4)
        .background(color.opacity(0.1))
        .cornerRadius(6)
    }
}

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

// MARK: - Combined Chart Implementation

struct CombinedChartView: UIViewRepresentable {
    let chartData: [ExerciseProgressDataPoint]
    @Binding var selectedDataPoint: ExerciseProgressDataPoint?
    let userDefaults: UserDefaultsManager
    
    func makeUIView(context: Context) -> DGCharts.CombinedChartView {
        let chart = DGCharts.CombinedChartView()
        configureChart(chart)
        chart.delegate = context.coordinator
        return chart
    }
    
    func updateUIView(_ uiView: DGCharts.CombinedChartView, context: Context) {
        updateChartData(uiView)
        updateSelection(uiView)
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    private func configureChart(_ chart: DGCharts.CombinedChartView) {
        // General chart configuration
        chart.backgroundColor = UIColor.systemGray6
        chart.gridBackgroundColor = UIColor.systemBackground
        chart.borderColor = UIColor.systemGray4
        chart.borderLineWidth = 1.0
        chart.drawGridBackgroundEnabled = true
        chart.dragEnabled = true
        chart.setScaleEnabled(false)
        chart.pinchZoomEnabled = false
        chart.highlightPerTapEnabled = true
        chart.highlightPerDragEnabled = false
        
        // Configure axes
        let xAxis = chart.xAxis
        xAxis.labelPosition = .bottom
        xAxis.drawGridLinesEnabled = true
        xAxis.gridColor = UIColor.systemGray4
        xAxis.gridLineWidth = 0.5
        xAxis.labelTextColor = UIColor.secondaryLabel
        xAxis.valueFormatter = DateAxisValueFormatter()
        
        let leftAxis = chart.leftAxis
        leftAxis.drawGridLinesEnabled = true
        leftAxis.gridColor = UIColor.systemGray4
        leftAxis.gridLineWidth = 0.5
        leftAxis.labelTextColor = UIColor.secondaryLabel
        leftAxis.axisMinimum = 0
        
        let rightAxis = chart.rightAxis
        rightAxis.drawGridLinesEnabled = false
        rightAxis.drawLabelsEnabled = true
        rightAxis.labelTextColor = UIColor.systemOrange
        rightAxis.axisMinimum = 0
        
        // Configure legend
        let legend = chart.legend
        legend.horizontalAlignment = .left
        legend.verticalAlignment = .bottom
        legend.orientation = .horizontal
        legend.drawInside = false
        legend.form = .line
        legend.formSize = 12
        legend.textColor = UIColor.label
    }
    
    private func updateChartData(_ chart: DGCharts.CombinedChartView) {
        guard !chartData.isEmpty else {
            chart.data = nil
            return
        }
        
        print("Updating chart with \(chartData.count) data points:")
        chartData.enumerated().forEach { index, point in
            print("Index \(index): \(point.date), weight: \(point.averageWeight), reps: \(point.averageReps)")
        }
        
        let combinedData = DGCharts.CombinedChartData()
        
        // Create bar data for average weight
        var barEntries: [BarChartDataEntry] = []
        var lineEntries: [ChartDataEntry] = []
        
        for (index, dataPoint) in chartData.enumerated() {
            let xValue = Double(index)
            
            // Bar entry for weight
            let barEntry = BarChartDataEntry(x: xValue, y: dataPoint.averageWeight)
            barEntries.append(barEntry)
            
            // Line entry for reps
            let lineEntry = ChartDataEntry(x: xValue, y: dataPoint.averageReps)
            lineEntries.append(lineEntry)
        }
        
        // Configure bar data set (Weight)
        let barDataSet = BarChartDataSet(entries: barEntries, label: "Avg Weight (\(userDefaults.weightUnit.abbreviation))")
        barDataSet.colors = chartData.map { dataPoint in
            dataPoint.isFromCuttingPhase ? 
                UIColor.systemRed.withAlphaComponent(0.7) : 
                UIColor.systemBlue.withAlphaComponent(0.7)
        }
        barDataSet.valueTextColor = UIColor.clear // Hide values on bars
        barDataSet.highlightEnabled = true
        barDataSet.highlightColor = UIColor.systemYellow
        barDataSet.highlightAlpha = 0.3
        
        let barData = BarChartData(dataSet: barDataSet)
        barData.barWidth = 0.6
        combinedData.barData = barData
        
        // Configure line data set (Reps)
        let lineDataSet = LineChartDataSet(entries: lineEntries, label: "Avg Reps")
        lineDataSet.axisDependency = .right
        lineDataSet.colors = [UIColor.systemOrange]
        lineDataSet.lineWidth = 3.0
        lineDataSet.circleRadius = 5.0
        lineDataSet.circleHoleRadius = 3.0
        lineDataSet.circleColors = [UIColor.systemOrange]
        lineDataSet.circleHoleColor = UIColor.systemBackground
        lineDataSet.valueTextColor = UIColor.clear // Hide values on points
        lineDataSet.mode = .cubicBezier // Smooth line
        lineDataSet.cubicIntensity = 0.2
        lineDataSet.highlightEnabled = true
        lineDataSet.highlightColor = UIColor.systemYellow
        lineDataSet.highlightLineWidth = 2.0
        
        let lineData = LineChartData(dataSet: lineDataSet)
        combinedData.lineData = lineData
        
        // Set up x-axis labels
        let xAxis = chart.xAxis
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MM/dd"
        xAxis.valueFormatter = IndexAxisValueFormatter(values: chartData.map { 
            dateFormatter.string(from: $0.date)
        })
        xAxis.granularity = 1
        xAxis.labelCount = min(6, chartData.count)
        
        // Auto-scale axes
        let weights = chartData.map { $0.averageWeight }
        let reps = chartData.map { $0.averageReps }
        
        chart.leftAxis.axisMaximum = (weights.max() ?? 100) * 1.1
        chart.rightAxis.axisMaximum = (reps.max() ?? 20) * 1.1
        
        chart.data = combinedData
        chart.animate(xAxisDuration: 0.8, yAxisDuration: 0.8)
    }
    
    private func updateSelection(_ chart: DGCharts.CombinedChartView) {
        guard let selectedPoint = selectedDataPoint,
              let index = chartData.firstIndex(where: { Calendar.current.isDate($0.date, inSameDayAs: selectedPoint.date) }) else {
            chart.highlightValues(nil)
            return
        }
        
        // Highlight the selected data point
        let highlight = Highlight(x: Double(index), dataSetIndex: 0, stackIndex: -1)
        chart.highlightValues([highlight])
    }
    
    class Coordinator: NSObject, ChartViewDelegate {
        let parent: CombinedChartView
        
        init(_ parent: CombinedChartView) {
            self.parent = parent
        }
        
        func chartValueSelected(_ chartView: ChartViewBase, entry: ChartDataEntry, highlight: Highlight) {
            let index = Int(entry.x)
            guard index >= 0 && index < parent.chartData.count else { 
                print("Invalid index: \(index), chartData count: \(parent.chartData.count)")
                return 
            }
            
            let selectedPoint = parent.chartData[index]
            parent.selectedDataPoint = selectedPoint
            
            print("Selected point at index \(index): \(selectedPoint.date), weight: \(selectedPoint.averageWeight), reps: \(selectedPoint.averageReps)")
            
            // Haptic feedback
            let impactFeedback = UIImpactFeedbackGenerator(style: .light)
            impactFeedback.impactOccurred()
        }
        
        func chartValueNothingSelected(_ chartView: ChartViewBase) {
            parent.selectedDataPoint = nil
        }
    }
}

// MARK: - Custom Value Formatters

class DateAxisValueFormatter: AxisValueFormatter {
    func stringForValue(_ value: Double, axis: AxisBase?) -> String {
        return String(format: "%.0f", value)
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
