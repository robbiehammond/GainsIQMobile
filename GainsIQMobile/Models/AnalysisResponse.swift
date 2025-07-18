import Foundation

// Backend returns analysis as a simple map with "analysis" key
struct AnalysisResponse: Codable {
    let analysis: String
    
    enum CodingKeys: String, CodingKey {
        case analysis
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        analysis = try container.decode(String.self, forKey: .analysis)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(analysis, forKey: .analysis)
    }
}

// Convert to our internal Analysis model
extension AnalysisResponse {
    func toAnalysis() -> Analysis {
        return Analysis(
            timestamp: Int64(Date().timeIntervalSince1970),
            content: analysis
        )
    }
}