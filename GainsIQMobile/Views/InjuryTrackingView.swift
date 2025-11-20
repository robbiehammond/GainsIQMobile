import SwiftUI

struct InjuryTrackingView: View {
    @StateObject private var viewModel: InjuryViewModel
    
    init(apiClient: GainsIQAPIClient) {
        self._viewModel = StateObject(wrappedValue: InjuryViewModel(apiClient: apiClient))
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: Constants.UI.Spacing.large) {
                injuryFormSection
                bodypartsSection
                injuriesSection
            }
            .padding(Constants.UI.Padding.medium)
        }
        .navigationTitle("Injury Tracker")
        .navigationBarTitleDisplayMode(.large)
        .task { await viewModel.loadAll() }
        .refreshable { await viewModel.loadAll() }
        .alert("Error", isPresented: .constant(viewModel.errorMessage != nil)) {
            Button("OK") { viewModel.errorMessage = nil }
        } message: {
            if let err = viewModel.errorMessage { Text(err) }
        }
        .alert("Success", isPresented: $viewModel.showingSuccessMessage) {
            Button("OK") {}
        } message: {
            Text(viewModel.successMessage)
        }
    }
    
    private var injuryFormSection: some View {
        VStack(alignment: .leading, spacing: Constants.UI.Spacing.medium) {
            Text("Log an Injury")
                .font(.headline)
                .foregroundColor(.primary)

            if viewModel.bodyparts.isEmpty {
                Text("Add a bodypart below to begin.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            } else {
                VStack(alignment: .leading, spacing: Constants.UI.Spacing.small) {
                    Text("Bodypart")
                        .font(.subheadline)
                        .foregroundColor(.primary)
                    Picker("Bodypart", selection: $viewModel.selectedLocation) {
                        ForEach(viewModel.bodyparts, id: \.self) { bp in
                            Text(bp).tag(bp)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                }
            }

            VStack(alignment: .leading, spacing: Constants.UI.Spacing.small) {
                Text("Details (optional)")
                    .font(.subheadline)
                    .foregroundColor(.primary)
                TextField("Describe the injury...", text: $viewModel.details, axis: .vertical)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .lineLimit(3, reservesSpace: true)
            }

            VStack(alignment: .leading, spacing: Constants.UI.Spacing.small) {
                Text("Start Date & Time")
                    .font(.subheadline)
                    .foregroundColor(.primary)
                DatePicker(
                    "Start",
                    selection: $viewModel.startDate,
                    in: ...Date(),
                    displayedComponents: [.date, .hourAndMinute]
                )
                .datePickerStyle(.compact)
            }

            Toggle("Active injury", isOn: $viewModel.isActive)

            Button(action: {
                Task { await viewModel.logInjury() }
            }) {
                HStack {
                    if viewModel.isLoading { ProgressView().scaleEffect(0.9) }
                    Image(systemName: "plus.circle.fill")
                    Text("Log Injury")
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, Constants.UI.Padding.small)
                .background(viewModel.canSubmit && !viewModel.bodyparts.isEmpty ? Color.blue : Color.gray)
                .foregroundColor(.white)
                .cornerRadius(Constants.UI.cornerRadius)
            }
            .disabled(!viewModel.canSubmit || viewModel.bodyparts.isEmpty)
        }
        .padding(Constants.UI.Padding.medium)
        .background(Color(.systemGray6))
        .cornerRadius(Constants.UI.cornerRadius)
    }
    
    private var bodypartsSection: some View {
        VStack(alignment: .leading, spacing: Constants.UI.Spacing.medium) {
            Text("Bodyparts")
                .font(.headline)
                .foregroundColor(.primary)

            HStack {
                TextField("Add bodypart (e.g. Shoulder)", text: $viewModel.newBodypart)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                Button(action: {
                    Task { await viewModel.addBodypart() }
                }) {
                    HStack {
                        Image(systemName: "plus")
                        Text("Add")
                    }
                    .padding(.horizontal, Constants.UI.Padding.small)
                    .padding(.vertical, 6)
                    .background(viewModel.newBodypart.trimmed.isEmpty ? Color.gray : Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                }
                .disabled(viewModel.newBodypart.trimmed.isEmpty)
            }

            if viewModel.bodyparts.isEmpty {
                Text("No bodyparts yet")
                    .foregroundColor(.secondary)
                    .italic()
            } else {
                VStack(spacing: 8) {
                    ForEach(viewModel.bodyparts, id: \.self) { bp in
                        HStack {
                            Text(bp)
                                .foregroundColor(.primary)
                            Spacer()
                            Button(role: .destructive) {
                                Task { await viewModel.deleteBodypart(bp) }
                            } label: {
                                Image(systemName: "trash")
                            }
                        }
                        .padding(.vertical, 6)
                        .padding(.horizontal, 8)
                        .background(Color(.systemBackground))
                        .cornerRadius(8)
                    }
                }
            }
        }
        .padding(Constants.UI.Padding.medium)
        .background(Color(.systemGray6))
        .cornerRadius(Constants.UI.cornerRadius)
    }
    
    private var injuriesSection: some View {
        VStack(alignment: .leading, spacing: Constants.UI.Spacing.medium) {
            Text("Active Injuries")
                .font(.headline)
                .foregroundColor(.primary)

            if viewModel.activeInjuries.isEmpty {
                Text("No active injuries")
                    .foregroundColor(.secondary)
                    .italic()
            } else {
                VStack(spacing: 8) {
                    ForEach(viewModel.activeInjuries, id: \.timestamp) { injury in
                        injuryRow(injury, actionLabel: "Mark Inactive", actionColor: .orange) {
                            Task { await viewModel.toggleActive(for: injury) }
                        }
                    }
                }
            }

            Divider().padding(.vertical, 4)

            Text("Past Injuries")
                .font(.headline)
                .foregroundColor(.primary)
            if viewModel.inactiveInjuries.isEmpty {
                Text("No past injuries")
                    .foregroundColor(.secondary)
                    .italic()
            } else {
                VStack(spacing: 8) {
                    ForEach(viewModel.inactiveInjuries, id: \.timestamp) { injury in
                        injuryRow(injury, actionLabel: "Mark Active", actionColor: .blue) {
                            Task { await viewModel.toggleActive(for: injury) }
                        }
                    }
                }
            }
        }
        .padding(Constants.UI.Padding.medium)
        .background(Color(.systemGray6))
        .cornerRadius(Constants.UI.cornerRadius)
    }
    
    private func injuryRow(_ injury: InjuryEntry, actionLabel: String, actionColor: Color, action: @escaping () -> Void) -> some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                Text(injury.location)
                    .font(.headline)
                    .foregroundColor(.primary)
                if let details = injury.details, !details.isEmpty {
                    Text(details)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                Text(injury.date.timeAgo())
                    .font(.caption)
                    .foregroundColor(.secondary)

                if let periods = injury.activePeriods, !periods.isEmpty {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Active Periods:")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        ForEach(periods, id: \.start) { p in
                            Text("• \(p.formattedRange)")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.top, 2)
                }
            }
            Spacer()
            Button(action: action) {
                Text(actionLabel)
                    .font(.caption)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(actionColor.opacity(0.1))
                    .foregroundColor(actionColor)
                    .cornerRadius(6)
                    .overlay(
                        RoundedRectangle(cornerRadius: 6).stroke(actionColor, lineWidth: 1)
                    )
            }
            .disabled(viewModel.isLoading)
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 8)
        .background(Color(.systemBackground))
        .cornerRadius(8)
    }
}

#Preview {
    InjuryTrackingView(apiClient: GainsIQAPIClient(
        baseURL: Constants.API.defaultBaseURL,
        apiKey: Config.apiKey
    ))
}
