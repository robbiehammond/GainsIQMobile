import Foundation
import Network
import UIKit

class NetworkMonitor: ObservableObject {
    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "NetworkMonitor")
    
    @Published var isConnected = false
    @Published var connectionType: NWInterface.InterfaceType?
    
    init() {
        startMonitoring()
    }
    
    private func startMonitoring() {
        monitor.pathUpdateHandler = { [weak self] path in
            DispatchQueue.main.async {
                self?.isConnected = path.status == .satisfied
                self?.connectionType = path.availableInterfaces.first?.type
            }
        }
        monitor.start(queue: queue)
    }
    
    deinit {
        monitor.cancel()
    }
}

// MARK: - Retry Logic

class RetryManager {
    static func performWithRetry<T>(
        maxRetries: Int = 3,
        delay: TimeInterval = 1.0,
        operation: @escaping () async throws -> T
    ) async throws -> T {
        var lastError: Error?
        
        for attempt in 0..<maxRetries {
            do {
                return try await operation()
            } catch {
                lastError = error
                
                if attempt < maxRetries - 1 {
                    try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                }
            }
        }
        
        throw lastError ?? APIError.networkError(NSError(domain: "RetryManager", code: -1, userInfo: [NSLocalizedDescriptionKey: "All retry attempts failed"]))
    }
}

// MARK: - Request Logging

class RequestLogger {
    static let shared = RequestLogger()
    private init() {}
    
    func logRequest(_ request: URLRequest) {
        #if DEBUG
        print("🚀 API Request:")
        print("URL: \(request.url?.absoluteString ?? "Unknown")")
        print("Method: \(request.httpMethod ?? "Unknown")")
        print("Headers: \(request.allHTTPHeaderFields ?? [:])")
        
        if let body = request.httpBody,
           let bodyString = String(data: body, encoding: .utf8) {
            print("Body: \(bodyString)")
        }
        print("---")
        #endif
    }
    
    func logResponse(_ response: URLResponse?, data: Data?, error: Error?) {
        #if DEBUG
        print("📡 API Response:")
        
        if let httpResponse = response as? HTTPURLResponse {
            print("Status Code: \(httpResponse.statusCode)")
            print("Headers: \(httpResponse.allHeaderFields)")
        }
        
        if let data = data,
           let responseString = String(data: data, encoding: .utf8) {
            print("Response: \(responseString)")
        }
        
        if let error = error {
            print("Error: \(error.localizedDescription)")
        }
        print("---")
        #endif
    }
}

// MARK: - Cache Manager

class APICache {
    private let cache = NSCache<NSString, NSData>()
    private let cacheQueue = DispatchQueue(label: "APICache", attributes: .concurrent)
    
    static let shared = APICache()
    
    private init() {
        cache.totalCostLimit = 50 * 1024 * 1024 // 50MB
        cache.countLimit = 1000
    }
    
    func getData(for key: String) -> Data? {
        return cacheQueue.sync {
            cache.object(forKey: key as NSString) as Data?
        }
    }
    
    func setData(_ data: Data, for key: String) {
        cacheQueue.async(flags: .barrier) {
            self.cache.setObject(data as NSData, forKey: key as NSString)
        }
    }
    
    func removeData(for key: String) {
        cacheQueue.async(flags: .barrier) {
            self.cache.removeObject(forKey: key as NSString)
        }
    }
    
    func clearAll() {
        cacheQueue.async(flags: .barrier) {
            self.cache.removeAllObjects()
        }
    }
}

// MARK: - Background Task Manager

class BackgroundTaskManager {
    static let shared = BackgroundTaskManager()
    private var backgroundTask: UIBackgroundTaskIdentifier = .invalid
    
    private init() {}
    
    func beginBackgroundTask() {
        backgroundTask = UIApplication.shared.beginBackgroundTask {
            self.endBackgroundTask()
        }
    }
    
    func endBackgroundTask() {
        if backgroundTask != .invalid {
            UIApplication.shared.endBackgroundTask(backgroundTask)
            backgroundTask = .invalid
        }
    }
}

// MARK: - URLSession Extensions

extension URLSession {
    func dataTask(with request: URLRequest) async throws -> (Data, URLResponse) {
        RequestLogger.shared.logRequest(request)
        
        return try await withCheckedThrowingContinuation { continuation in
            let task = dataTask(with: request) { data, response, error in
                RequestLogger.shared.logResponse(response, data: data, error: error)
                
                if let error = error {
                    continuation.resume(throwing: error)
                } else if let data = data, let response = response {
                    continuation.resume(returning: (data, response))
                } else {
                    continuation.resume(throwing: APIError.noData)
                }
            }
            task.resume()
        }
    }
}

// MARK: - String Extensions for URL Encoding

extension String {
    var urlEncoded: String {
        return addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? self
    }
}