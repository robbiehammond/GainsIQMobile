import SwiftUI

struct DebugLogView: View {
    @StateObject private var debugLogger = DebugLogger.shared
    @State private var selectedLog: APILogEntry?
    
    var body: some View {
        NavigationView {
            List {
                if debugLogger.logs.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "network.slash")
                            .font(.system(size: 60))
                            .foregroundColor(.secondary)
                        
                        Text("No API calls yet")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        
                        Text("Make some API calls to see logs here")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 40)
                } else {
                    ForEach(debugLogger.logs) { log in
                        LogEntryRow(log: log)
                            .onTapGesture {
                                selectedLog = log
                            }
                    }
                }
            }
            .navigationTitle("API Debug Log")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Clear") {
                        debugLogger.clearLogs()
                    }
                    .disabled(debugLogger.logs.isEmpty)
                }
            }
            .sheet(item: $selectedLog) { log in
                LogDetailView(log: log)
            }
        }
    }
}

struct LogEntryRow: View {
    let log: APILogEntry
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(log.method)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(methodColor(log.method))
                    .foregroundColor(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 4))
                
                VStack(alignment: .leading, spacing: 1) {
                    Text(log.endpoint)
                        .font(.caption)
                        .foregroundColor(.primary)
                        .lineLimit(1)
                    
                    if !log.queryParameters.isEmpty {
                        Text(formatQueryParams(log.queryParameters))
                            .font(.caption2)
                            .foregroundColor(.blue)
                            .lineLimit(2)
                    }
                }
                
                Spacer()
                
                if let statusCode = log.responseStatusCode {
                    Text("\(statusCode)")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(log.statusColor)
                }
            }
            
            // Response preview
            if let responseBody = log.responseBody, !responseBody.isEmpty {
                Text(truncateResponse(responseBody))
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color(.systemGray6))
                    .cornerRadius(6)
                    .lineLimit(2)
            }
            
            HStack {
                Text(log.formattedTimestamp)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                if let duration = log.duration {
                    Text("\(Int(duration * 1000))ms")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.vertical, 4)
    }
    
    private func methodColor(_ method: String) -> Color {
        switch method {
        case "GET":
            return .blue
        case "POST":
            return .green
        case "PUT":
            return .orange
        case "DELETE":
            return .red
        default:
            return .gray
        }
    }
    
    private func formatQueryParams(_ params: [String: String]) -> String {
        let paramStrings = params.map { "\($0.key)=\($0.value)" }
        return "?" + paramStrings.joined(separator: "&")
    }
    
    private func truncateResponse(_ response: String) -> String {
        let maxLength = 100
        if response.count <= maxLength {
            return response
        }
        return String(response.prefix(maxLength)) + "..."
    }
}

struct LogDetailView: View {
    let log: APILogEntry
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Request Info
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Request")
                            .font(.headline)
                        
                        InfoRow(label: "Method", value: log.method)
                        InfoRow(label: "Endpoint", value: log.endpoint)
                        InfoRow(label: "Full URL", value: log.fullURL)
                        InfoRow(label: "Timestamp", value: log.formattedTimestamp)
                        
                        if let duration = log.duration {
                            InfoRow(label: "Duration", value: "\(Int(duration * 1000))ms")
                        }
                    }
                    
                    // Query Parameters
                    if !log.queryParameters.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Query Parameters")
                                .font(.headline)
                            
                            ForEach(log.queryParameters.sorted(by: { $0.key < $1.key }), id: \.key) { key, value in
                                InfoRow(label: key, value: value)
                            }
                        }
                    }
                    
                    // Request Headers
                    if !log.requestHeaders.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Request Headers")
                                .font(.headline)
                            
                            ForEach(log.requestHeaders.sorted(by: { $0.key < $1.key }), id: \.key) { key, value in
                                InfoRow(label: key, value: value)
                            }
                        }
                    }
                    
                    // Request Body
                    if let requestBody = log.requestBody, !requestBody.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Request Body")
                                .font(.headline)
                            
                            Text(formatJSON(requestBody))
                                .font(.system(.caption, design: .monospaced))
                                .padding()
                                .background(Color(.systemGray6))
                                .cornerRadius(8)
                        }
                    }
                    
                    // Response Info
                    if let statusCode = log.responseStatusCode {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Response")
                                .font(.headline)
                            
                            HStack {
                                Text("Status Code:")
                                    .foregroundColor(.secondary)
                                Text("\(statusCode)")
                                    .foregroundColor(log.statusColor)
                                    .fontWeight(.medium)
                            }
                        }
                    }
                    
                    // Response Headers
                    if let responseHeaders = log.responseHeaders, !responseHeaders.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Response Headers")
                                .font(.headline)
                            
                            ForEach(responseHeaders.sorted(by: { $0.key < $1.key }), id: \.key) { key, value in
                                InfoRow(label: key, value: value)
                            }
                        }
                    }
                    
                    // Response Body
                    if let responseBody = log.responseBody, !responseBody.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Response Body")
                                .font(.headline)
                            
                            Text(formatJSON(responseBody))
                                .font(.system(.caption, design: .monospaced))
                                .padding()
                                .background(Color(.systemGray6))
                                .cornerRadius(8)
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("API Call Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func formatJSON(_ string: String) -> String {
        guard let data = string.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data),
              let prettyData = try? JSONSerialization.data(withJSONObject: json, options: [.prettyPrinted]),
              let prettyString = String(data: prettyData, encoding: .utf8) else {
            return string
        }
        return prettyString
    }
}

struct InfoRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack(alignment: .top) {
            Text("\(label):")
                .foregroundColor(.secondary)
                .frame(width: 80, alignment: .leading)
            
            Text(value)
                .multilineTextAlignment(.leading)
            
            Spacer()
        }
    }
}

#Preview {
    DebugLogView()
}