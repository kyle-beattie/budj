//
//  StubTransport.swift
//  BudjTests
//

import Foundation
@testable import Budj

/// A transport that answers from a script and records what it was asked, so the
/// client's rules can be tested without a server.
@MainActor
final class StubTransport: HTTPTransport {
    /// Answers, in the order they will be given. A request that runs past the
    /// end of the script fails the test loudly rather than quietly succeeding.
    var answers: [Answer] = []

    private(set) var requests: [URLRequest] = []

    enum Answer {
        case status(Int, body: Data)
        case failure(any Error)

        static func json(_ status: Int, _ object: Any) -> Answer {
            .status(status, body: try! JSONSerialization.data(withJSONObject: object))
        }
    }

    func send(_ request: URLRequest) async throws -> (Data, HTTPURLResponse) {
        requests.append(request)

        guard !answers.isEmpty else {
            throw StubTransportError.ranOutOfAnswers(request.url?.path() ?? "?")
        }

        switch answers.removeFirst() {
        case let .status(code, body):
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: code,
                httpVersion: nil,
                headerFields: nil
            )!
            return (body, response)
        case let .failure(error):
            throw error
        }
    }

    // MARK: - Reading what happened

    func requests(toPathContaining fragment: String) -> [URLRequest] {
        requests.filter { $0.url?.path().contains(fragment) == true }
    }

    var buildHeaders: [String?] {
        requests.map { $0.value(forHTTPHeaderField: ClientBuildHeader.name) }
    }
}

enum StubTransportError: Error {
    case ranOutOfAnswers(String)
}
