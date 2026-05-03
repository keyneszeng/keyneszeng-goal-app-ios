import Foundation

struct APIClient {
    var baseURL: URL = URL(string: "http://127.0.0.1:3000")!
    var userID: String = "demo-user"

    private let session: URLSession
    private let decoder: JSONDecoder
    private let encoder: JSONEncoder

    init(session: URLSession = .shared) {
        self.session = session
        decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let rawValue = try container.decode(String.self)
            if let date = ISO8601DateFormatter.withFractionalSeconds.date(from: rawValue) {
                return date
            }
            if let date = ISO8601DateFormatter.standard.date(from: rawValue) {
                return date
            }
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Invalid ISO8601 date")
        }
        encoder = JSONEncoder()
    }

    func fetchRoutines() async throws -> [KungFuRoutine] {
        let response: RoutinesResponse = try await get("/api/routines")
        return response.routines
    }

    func fetchCheckIns() async throws -> [CheckIn] {
        let response: CheckInsResponse = try await get("/api/checkins?userId=\(userID)")
        return response.checkIns
    }

    func createCheckIn(for routine: KungFuRoutine) async throws -> CheckIn {
        let payload = CreateCheckInRequest(userId: userID, routineId: routine.id)
        let response: CreateCheckInResponse = try await post("/api/checkins", body: payload)
        return response.checkIn
    }

    private func get<Response: Decodable>(_ path: String) async throws -> Response {
        let request = URLRequest(url: makeURL(path))
        return try await send(request)
    }

    private func post<Body: Encodable, Response: Decodable>(_ path: String, body: Body) async throws -> Response {
        var request = URLRequest(url: makeURL(path))
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "content-type")
        request.httpBody = try encoder.encode(body)
        return try await send(request)
    }

    private func makeURL(_ path: String) -> URL {
        URL(string: path, relativeTo: baseURL)!.absoluteURL
    }

    private func send<Response: Decodable>(_ request: URLRequest) async throws -> Response {
        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        guard (200..<300).contains(httpResponse.statusCode) else {
            throw APIError.requestFailed(httpResponse.statusCode)
        }
        return try decoder.decode(Response.self, from: data)
    }
}

enum APIError: LocalizedError {
    case invalidResponse
    case requestFailed(Int)

    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "服务响应异常"
        case .requestFailed(let statusCode):
            return "服务请求失败：\(statusCode)"
        }
    }
}

private struct RoutinesResponse: Decodable {
    let routines: [KungFuRoutine]
}

private struct CheckInsResponse: Decodable {
    let checkIns: [CheckIn]
}

private struct CreateCheckInRequest: Encodable {
    let userId: String
    let routineId: String
}

private struct CreateCheckInResponse: Decodable {
    let checkIn: CheckIn
}

private extension ISO8601DateFormatter {
    static let standard: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        return formatter
    }()

    static let withFractionalSeconds: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()
}
