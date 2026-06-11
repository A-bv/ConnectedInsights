import XCTest
@testable import InstagramGraph

final class InstagramGraphClientTests: XCTestCase {

    func testFetchGraphData_whenResponseIs200_returnsData() async throws {
        let sut = InstagramGraphClient(session: FakeURLSession(
            result: .success((#"{"id":"123"}"#.data(using: .utf8)!, makeHTTPResponse(statusCode: 200)))
        ))

        let data = try await sut.fetchGraphData(from: "https://graph.facebook.com/v23.0/me")

        XCTAssertFalse(data.isEmpty)
    }

    func testFetchGraphData_whenURLIsInvalid_throwsInvalidURLError() async throws {
        let sut = InstagramGraphClient(session: FakeURLSession())

        // Empty string is one of the few inputs URL(string:) still rejects on modern Foundation.
        do {
            _ = try await sut.fetchGraphData(from: "")
            XCTFail("Expected invalidURL error")
        } catch let error as InstagramGraphServiceError {
            guard case .invalidURL = error else {
                XCTFail("Expected invalidURL, got \(error)")
                return
            }
        }
    }

    func testFetchGraphData_whenURLContainsToken_redactsTokenInInvalidURLError() async throws {
        let sut = InstagramGraphClient(session: FakeURLSession())

        // A scheme starting with a digit is rejected by URL(string:) per RFC 3986,
        // making this a reliable source of an invalid URL that also carries a token.
        do {
            _ = try await sut.fetchGraphData(from: "1nvalid://host?access_token=secret123")
            XCTFail("Expected invalidURL error")
        } catch let error as InstagramGraphServiceError {
            guard case .invalidURL(let urlString) = error else {
                XCTFail("Expected invalidURL, got \(error)")
                return
            }
            XCTAssertFalse(urlString.contains("secret123"))
            XCTAssertTrue(urlString.contains("<redacted>"))
        }
    }

    func testFetchGraphData_whenResponseIs401_throwsGraphHTTPError() async throws {
        let body = #"{"error":{"message":"Invalid token"}}"#.data(using: .utf8)!
        let sut = InstagramGraphClient(session: FakeURLSession(
            result: .success((body, makeHTTPResponse(statusCode: 401)))
        ))

        do {
            _ = try await sut.fetchGraphData(from: "https://graph.facebook.com/v23.0/me")
            XCTFail("Expected graphHTTPError")
        } catch let error as InstagramGraphServiceError {
            guard case .graphHTTPError(let statusCode, _) = error else {
                XCTFail("Expected graphHTTPError, got \(error)")
                return
            }
            XCTAssertEqual(statusCode, 401)
        }
    }

    func testFetchGraphData_whenResponseBodyIsEmpty_throwsEmptyResponseError() async throws {
        let sut = InstagramGraphClient(session: FakeURLSession(
            result: .success((Data(), makeHTTPResponse(statusCode: 200)))
        ))

        do {
            _ = try await sut.fetchGraphData(from: "https://graph.facebook.com/v23.0/me")
            XCTFail("Expected emptyResponse error")
        } catch let error as InstagramGraphServiceError {
            guard case .emptyResponse = error else {
                XCTFail("Expected emptyResponse, got \(error)")
                return
            }
        }
    }

    func testFetchGraphData_whenNetworkFails_throwsNetworkError() async throws {
        let sut = InstagramGraphClient(session: FakeURLSession(
            result: .failure(URLError(.notConnectedToInternet))
        ))

        do {
            _ = try await sut.fetchGraphData(from: "https://graph.facebook.com/v23.0/me")
            XCTFail("Expected networkError")
        } catch let error as InstagramGraphServiceError {
            guard case .networkError(let urlError) = error else {
                XCTFail("Expected networkError, got \(error)")
                return
            }
            XCTAssertEqual(urlError.code, .notConnectedToInternet)
        }
    }
}

private func makeHTTPResponse(statusCode: Int) -> HTTPURLResponse {
    HTTPURLResponse(
        url: URL(string: "https://graph.facebook.com")!,
        statusCode: statusCode,
        httpVersion: nil,
        headerFields: nil
    )!
}

private struct FakeURLSession: URLSessionDataFetching {
    var result: Result<(Data, URLResponse), Error> = .success((Data(), URLResponse()))

    func data(from url: URL) async throws -> (Data, URLResponse) {
        try result.get()
    }
}
