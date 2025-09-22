import Foundation
import SwiftUI

@MainActor
class InjuryViewModel: ObservableObject {
    @Published var injuries: [InjuryEntry] = []
    @Published var bodyparts: [String] = []
    @Published var selectedLocation: String = ""
    @Published var details: String = ""
    @Published var isActive: Bool = true
    @Published var startDate: Date = Date()
    
    @Published var newBodypart: String = ""
    
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var showingSuccessMessage: Bool = false
    @Published var successMessage: String = ""
    
    private let apiClient: GainsIQAPIClient
    
    init(apiClient: GainsIQAPIClient) {
        self.apiClient = apiClient
    }
    
    // MARK: - Loaders
    
    func loadAll() async {
        isLoading = true
        errorMessage = nil
        do {
            async let parts = apiClient.getBodyparts()
            async let inj = apiClient.getInjuries()
            let (bp, list) = try await (parts, inj)
            self.bodyparts = bp.sorted()
            self.injuries = list.sorted { $0.timestamp > $1.timestamp }
            if self.selectedLocation.isEmpty, let first = self.bodyparts.first {
                self.selectedLocation = first
            }
        } catch {
            self.errorMessage = error.localizedDescription
        }
        isLoading = false
    }
    
    func reloadInjuries() async {
        do {
            let list = try await apiClient.getInjuries()
            self.injuries = list.sorted { $0.timestamp > $1.timestamp }
        } catch {
            self.errorMessage = error.localizedDescription
        }
    }
    
    func reloadBodyparts() async {
        do {
            let parts = try await apiClient.getBodyparts()
            self.bodyparts = parts.sorted()
            if self.selectedLocation.isEmpty, let first = self.bodyparts.first {
                self.selectedLocation = first
            }
        } catch {
            self.errorMessage = error.localizedDescription
        }
    }
    
    // MARK: - Actions
    
    func logInjury() async {
        guard !selectedLocation.trimmed.isEmpty else {
            errorMessage = "Please select a bodypart"
            return
        }
        isLoading = true
        errorMessage = nil
        do {
            let req = InjuryRequest(
                timestamp: startDate.unixTimestamp,
                location: selectedLocation.trimmed,
                details: details.trimmed.isEmpty ? nil : details.trimmed,
                active: isActive
            )
            try await apiClient.logInjury(req)
            successMessage = "Injury logged successfully!"
            showingSuccessMessage = true
            // reset details but keep selection
            details = ""
            isActive = true
            startDate = Date()
            await reloadInjuries()
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
    
    func toggleActive(for injury: InjuryEntry) async {
        isLoading = true
        errorMessage = nil
        do {
            try await apiClient.setInjuryActive(timestamp: injury.timestamp, active: !injury.active)
            await reloadInjuries()
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
    
    func addBodypart() async {
        let loc = newBodypart.trimmed
        guard !loc.isEmpty else { return }
        isLoading = true
        errorMessage = nil
        do {
            try await apiClient.addBodypart(loc)
            successMessage = "Bodypart added"
            showingSuccessMessage = true
            newBodypart = ""
            await reloadBodyparts()
            selectedLocation = loc
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
    
    func deleteBodypart(_ location: String) async {
        isLoading = true
        errorMessage = nil
        do {
            try await apiClient.deleteBodypart(location)
            successMessage = "Bodypart deleted"
            showingSuccessMessage = true
            await reloadBodyparts()
            if selectedLocation == location {
                selectedLocation = bodyparts.first ?? ""
            }
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
    
    // MARK: - Computed
    
    var activeInjuries: [InjuryEntry] {
        injuries.filter { $0.active }
    }
    
    var inactiveInjuries: [InjuryEntry] {
        injuries.filter { !$0.active }
    }
    
    var canSubmit: Bool {
        !selectedLocation.trimmed.isEmpty && !isLoading
    }
}
