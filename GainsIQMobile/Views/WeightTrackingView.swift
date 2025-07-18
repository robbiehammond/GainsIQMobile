import SwiftUI
import Charts

struct WeightTrackingView: View {
    @StateObject private var viewModel = WeightViewModel()
    @StateObject private var userDefaults = UserDefaultsManager.shared
    
    var body: some View {
        ScrollView {
                VStack(spacing: Constants.UI.Spacing.large) {
                    // Header section
                    headerSection
                    
                    // Weight input form
                    weightForm
                    
                    // Weight trend display
                    if let trend = viewModel.currentWeightTrend {
                        trendSection(trend: trend)
                    }
                    
                    // Weight progress chart
                    if viewModel.hasData {
                        chartSection
                    }
                    
                    // Recent entries
                    recentEntriesSection
                }
                .padding(Constants.UI.Padding.medium)
        }
        .navigationTitle("Weight Tracker")
        .navigationBarTitleDisplayMode(.large)
        .task {
            await viewModel.loadWeights()
        }
        .refreshable {
            await viewModel.loadWeights()
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
    }
    
    // MARK: - View Components
    
    private var headerSection: some View {
        VStack(spacing: Constants.UI.Spacing.small) {
            Text("Track Your Weight")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            
            HStack {
                Text("Unit:")
                    .foregroundColor(.secondary)
                
                Text(userDefaults.weightUnit.displayName)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                
                Spacer()
                
                if viewModel.hasData {
                    VStack(alignment: .trailing) {
                        Text("Entries: \(viewModel.weightEntries.count)")
                            .foregroundColor(.secondary)
                        Text("Avg: \(userDefaults.formatWeight(viewModel.averageWeight))")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .font(.caption)
            .padding(.horizontal)
        }
    }
    
    private var weightForm: some View {
        VStack(spacing: Constants.UI.Spacing.medium) {
            // Weight input
            VStack(alignment: .leading, spacing: Constants.UI.Spacing.small) {
                Text("Current Weight (\(viewModel.weightDisplayUnit))")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                HStack {
                    TextField("Enter weight", text: $viewModel.currentWeight)
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
                    
                    Button(action: {
                        Task {
                            await viewModel.logWeight()
                            if userDefaults.enableHaptics {
                                successHaptic()
                            }
                        }
                    }) {
                        HStack {
                            if viewModel.isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .scaleEffect(0.8)
                            } else {
                                Image(systemName: "plus.circle.fill")
                            }
                            Text("Log")
                                .fontWeight(.semibold)
                        }
                        .padding(.horizontal, Constants.UI.Padding.medium)
                        .padding(.vertical, Constants.UI.Padding.small)
                        .background(viewModel.canSubmit ? Color.blue : Color.gray)
                        .foregroundColor(.white)
                        .cornerRadius(Constants.UI.cornerRadius)
                    }
                    .disabled(!viewModel.canSubmit)
                }
            }
            
            // Delete recent button
            if viewModel.hasData {
                Button(action: {
                    Task {
                        await viewModel.deleteRecentWeight()
                    }
                }) {
                    HStack {
                        Image(systemName: "trash")
                        Text("Delete Recent")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.red.opacity(0.1))
                    .foregroundColor(.red)
                    .cornerRadius(Constants.UI.cornerRadius)
                    .overlay(
                        RoundedRectangle(cornerRadius: Constants.UI.cornerRadius)
                            .stroke(Color.red, lineWidth: 1)
                    )
                }
                .disabled(viewModel.isLoading)
            }
        }
        .padding(Constants.UI.Padding.medium)
        .background(Color(.systemGray6))
        .cornerRadius(Constants.UI.cornerRadius)
    }
    
    private func trendSection(trend: WeightTrend) -> some View {
        VStack(alignment: .leading, spacing: Constants.UI.Spacing.small) {
            HStack {
                Text("Weight Trend")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Spacer()
                
                // Confidence indicator
                HStack(spacing: 4) {
                    Circle()
                        .fill(confidenceColor(trend.confidence))
                        .frame(width: 8, height: 8)
                    Text(trend.confidenceLevel)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(trend.trendDescription)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(trend.isGaining ? .blue : trend.isLosing ? .red : .secondary)
                    
                    Text(trend.formattedWeeklyChange)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(trend.isGaining ? .blue : trend.isLosing ? .red : .secondary)
                    
                    if trend.filteredWeight > 0 {
                        Text("Current: \(userDefaults.formatWeight(Float(trend.filteredWeight)))")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                Image(systemName: trend.isGaining ? "arrow.up.right" : trend.isLosing ? "arrow.down.right" : "arrow.right")
                    .font(.title)
                    .foregroundColor(trend.isGaining ? .blue : trend.isLosing ? .red : .secondary)
            }
        }
        .padding(Constants.UI.Padding.medium)
        .background(Color(.systemGray6))
        .cornerRadius(Constants.UI.cornerRadius)
    }
    
    private func confidenceColor(_ confidence: Double) -> Color {
        switch confidence {
        case 0.8...1.0:
            return .green
        case 0.6..<0.8:
            return .yellow
        case 0.4..<0.6:
            return .orange
        default:
            return .red
        }
    }
    
    private var chartSection: some View {
        VStack(alignment: .leading, spacing: Constants.UI.Spacing.medium) {
            // Chart header with time range selector
            HStack {
                Text("Weight Progress")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Picker("Time Range", selection: $viewModel.selectedTimeRange) {
                    ForEach(ChartTimeRange.allCases, id: \.self) { range in
                        Text(range.displayName)
                            .tag(range)
                    }
                }
                .pickerStyle(MenuPickerStyle())
                .font(.caption)
            }
            
            // Chart
            if viewModel.chartData.isEmpty {
                Text("No data for selected time range")
                    .foregroundColor(.secondary)
                    .italic()
                    .frame(maxWidth: .infinity, alignment: .center)
                    .frame(height: 200)
            } else {
                Chart {
                    // Raw weight data points
                    ForEach(viewModel.chartData, id: \.timestamp) { dataPoint in
                        PointMark(
                            x: .value("Date", dataPoint.date),
                            y: .value("Weight", dataPoint.value)
                        )
                        .foregroundStyle(Color.blue.opacity(0.7))
                        .symbolSize(40)
                    }
                    
                    // Kalman filtered line of best fit
                    ForEach(viewModel.filteredChartData, id: \.timestamp) { dataPoint in
                        LineMark(
                            x: .value("Date", dataPoint.date),
                            y: .value("Filtered Weight", dataPoint.value)
                        )
                        .foregroundStyle(Color.green)
                        .lineStyle(StrokeStyle(lineWidth: 3))
                    }
                    
                    // Trend projection (if available)
                    if !viewModel.projectedTrendData.isEmpty {
                        ForEach(viewModel.projectedTrendData, id: \.timestamp) { trendPoint in
                            LineMark(
                                x: .value("Date", trendPoint.date),
                                y: .value("Trend", trendPoint.value)
                            )
                            .foregroundStyle(Color.orange)
                            .lineStyle(StrokeStyle(lineWidth: 2, dash: [5]))
                        }
                    }
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
                            if let weight = value.as(Double.self) {
                                Text("\(weight, specifier: "%.1f") \(viewModel.weightDisplayUnit)")
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
                        .fill(Color.blue.opacity(0.7))
                        .frame(width: 8, height: 8)
                    Text("Raw Data")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                HStack(spacing: 4) {
                    Rectangle()
                        .fill(Color.green)
                        .frame(width: 12, height: 2)
                    Text("Filtered")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                if !viewModel.projectedTrendData.isEmpty {
                    HStack(spacing: 4) {
                        Rectangle()
                            .fill(Color.orange)
                            .frame(width: 12, height: 2)
                        Text("Projection")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
            }
        }
        .padding(Constants.UI.Padding.medium)
        .background(Color(.systemGray6))
        .cornerRadius(Constants.UI.cornerRadius)
    }
    
    private var recentEntriesSection: some View {
        VStack(alignment: .leading, spacing: Constants.UI.Spacing.medium) {
            Text("Recent Entries")
                .font(.headline)
                .foregroundColor(.primary)
            
            if viewModel.recentEntries.isEmpty {
                Text("No weight entries yet")
                    .foregroundColor(.secondary)
                    .italic()
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            } else {
                LazyVStack(spacing: Constants.UI.Spacing.small) {
                    ForEach(viewModel.recentEntries, id: \.id) { entry in
                        weightEntryRow(entry: entry)
                    }
                }
            }
        }
        .padding(Constants.UI.Padding.medium)
        .background(Color(.systemGray6))
        .cornerRadius(Constants.UI.cornerRadius)
    }
    
    private func weightEntryRow(entry: WeightEntry) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(userDefaults.formatWeight(entry.weight))
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Text(entry.formattedDate)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Text(entry.date.timeAgo())
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, Constants.UI.Padding.small)
        .padding(.horizontal, Constants.UI.Padding.small)
        .background(Color(.systemBackground))
        .cornerRadius(Constants.UI.cornerRadius / 2)
    }
}

// MARK: - Preview

struct WeightTrackingView_Previews: PreviewProvider {
    static var previews: some View {
        WeightTrackingView()
    }
}