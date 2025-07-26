import Foundation
import SwiftUI

struct APILogEntry: Identifiable {
    let id = UUID()
    let timestamp: Date
    let method: String
    let endpoint: String
    let fullURL: String
    let queryParameters: [String: String]
    let requestHeaders: [String: String]
    let requestBody: String?
    let responseStatusCode: Int?
    let responseHeaders: [String: String]?
    let responseBody: String?
    let duration: TimeInterval?
    
    var formattedTimestamp: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss.SSS"
        return formatter.string(from: timestamp)
    }
    
    var statusColor: Color {
        guard let statusCode = responseStatusCode else { return .gray }
        switch statusCode {
        case 200...299:
            return .green
        case 400...499:
            return .orange
        case 500...599:
            return .red
        default:
            return .gray
        }
    }
}

class DebugLogger: ObservableObject {
    static let shared = DebugLogger()
    
    @Published var logs: [APILogEntry] = []
    private let maxLogs = 100
    
    private init() {}
    
    func logRequest(
        method: String,
        endpoint: String,
        fullURL: String,
        headers: [String: String],
        body: Data?
    ) -> UUID {
        let id = UUID()
        let bodyString = body.flatMap { String(data: $0, encoding: .utf8) }
        let queryParams = extractQueryParameters(from: fullURL)
        
        let logEntry = APILogEntry(
            timestamp: Date(),
            method: method,
            endpoint: endpoint,
            fullURL: fullURL,
            queryParameters: queryParams,
            requestHeaders: headers,
            requestBody: bodyString,
            responseStatusCode: nil,
            responseHeaders: nil,
            responseBody: nil,
            duration: nil
        )
        
        DispatchQueue.main.async {
            self.logs.insert(logEntry, at: 0)
            if self.logs.count > self.maxLogs {
                self.logs.removeLast()
            }
        }
        
        return id
    }
    
    func logResponse(
        for requestId: UUID,
        statusCode: Int,
        headers: [String: String],
        body: Data?,
        duration: TimeInterval
    ) {
        let bodyString = body.flatMap { String(data: $0, encoding: .utf8) }
        
        DispatchQueue.main.async {
            if let index = self.logs.firstIndex(where: { $0.id == requestId }) {
                let existingLog = self.logs[index]
                let updatedLog = APILogEntry(
                    timestamp: existingLog.timestamp,
                    method: existingLog.method,
                    endpoint: existingLog.endpoint,
                    fullURL: existingLog.fullURL,
                    queryParameters: existingLog.queryParameters,
                    requestHeaders: existingLog.requestHeaders,
                    requestBody: existingLog.requestBody,
                    responseStatusCode: statusCode,
                    responseHeaders: headers,
                    responseBody: bodyString,
                    duration: duration
                )
                self.logs[index] = updatedLog
            }
        }
    }
    
    func clearLogs() {
        DispatchQueue.main.async {
            self.logs.removeAll()
        }
    }
    
    private func extractQueryParameters(from urlString: String) -> [String: String] {
        guard let url = URL(string: urlString),
              let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let queryItems = components.queryItems else {
            return [:]
        }
        
        var parameters: [String: String] = [:]
        for item in queryItems {
            parameters[item.name] = item.value ?? ""
        }
        return parameters
    }
}