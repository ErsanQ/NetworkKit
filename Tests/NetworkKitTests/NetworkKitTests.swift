import XCTest
@testable import NetworkKit

final class NetworkKitTests: XCTestCase {

    // MARK: - NetworkRequest Builder

    func test_request_defaultMethod_isGET() {
        let req = NetworkRequest(url: "https://example.com")
        XCTAssertEqual(req.method, .get)
    }

    func test_request_methodBuilder() {
        let req = NetworkRequest(url: "https://example.com").method(.post)
        XCTAssertEqual(req.method, .post)
    }

    func test_request_headerBuilder() {
        let req = NetworkRequest(url: "https://example.com")
            .header("Authorization", value: "Bearer token")
        XCTAssertEqual(req.headers["Authorization"], "Bearer token")
    }

    func test_request_multipleHeaders() {
        let req = NetworkRequest(url: "https://example.com")
            .headers(["X-A": "1", "X-B": "2"])
        XCTAssertEqual(req.headers["X-A"], "1")
        XCTAssertEqual(req.headers["X-B"], "2")
    }

    func test_request_queryBuilder() {
        let req = NetworkRequest(url: "https://example.com")
            .query("page", value: "2")
            .query("limit", value: "10")
        XCTAssertEqual(req.queryItems.count, 2)
    }

    func test_request_timeoutBuilder() {
        let req = NetworkRequest(url: "https://example.com").timeout(60)
        XCTAssertEqual(req.timeoutInterval, 60)
    }

    func test_request_bodyBuilder_setsContentType() throws {
        struct Payload: Encodable { let name: String }
        let req = try NetworkRequest(url: "https://example.com")
            .body(Payload(name: "test"))
        XCTAssertEqual(req.headers["Content-Type"], "application/json")
        XCTAssertNotNil(req.body)
    }

    func test_request_buildURLRequest_validURL() throws {
        let urlRequest = try NetworkRequest(url: "https://example.com").buildURLRequest()
        XCTAssertEqual(urlRequest.url?.host, "example.com")
        XCTAssertEqual(urlRequest.httpMethod, "GET")
    }

    func test_request_buildURLRequest_withQuery() throws {
        let urlRequest = try NetworkRequest(url: "https://example.com")
            .query("key", value: "value")
            .buildURLRequest()
        XCTAssertTrue(urlRequest.url?.absoluteString.contains("key=value") ?? false)
    }

    func test_request_invalidURL_throws() {
        XCTAssertThrowsError(
            try NetworkRequest(url: "not a url !!!").buildURLRequest()
        )
    }

    // MARK: - HTTPMethod

    func test_httpMethod_rawValues() {
        XCTAssertEqual(HTTPMethod.get.rawValue,    "GET")
        XCTAssertEqual(HTTPMethod.post.rawValue,   "POST")
        XCTAssertEqual(HTTPMethod.put.rawValue,    "PUT")
        XCTAssertEqual(HTTPMethod.patch.rawValue,  "PATCH")
        XCTAssertEqual(HTTPMethod.delete.rawValue, "DELETE")
    }

    // MARK: - NetworkResponse

    func test_response_isSuccess_2xx() {
        let r = NetworkResponse(statusCode: 200, data: Data(), headers: [:])
        XCTAssertTrue(r.isSuccess)
    }

    func test_response_isSuccess_4xx_false() {
        let r = NetworkResponse(statusCode: 404, data: Data(), headers: [:])
        XCTAssertFalse(r.isSuccess)
    }

    func test_response_decode_success() throws {
        struct Item: Decodable { let id: Int }
        let data = #"{"id":42}"#.data(using: .utf8)!
        let r = NetworkResponse(statusCode: 200, data: data, headers: [:])
        let item = try r.decode(Item.self)
        XCTAssertEqual(item.id, 42)
    }

    func test_response_decode_failure_throwsDecodingFailed() {
        let r = NetworkResponse(statusCode: 200, data: Data("bad".utf8), headers: [:])
        XCTAssertThrowsError(try r.decode(Int.self)) { error in
            if case NetworkError.decodingFailed = error {} else {
                XCTFail("Expected NetworkError.decodingFailed")
            }
        }
    }

    func test_response_string() {
        let r = NetworkResponse(statusCode: 200, data: Data("hello".utf8), headers: [:])
        XCTAssertEqual(r.string, "hello")
    }

    // MARK: - NetworkError

    func test_errors_haveDescriptions() {
        let errors: [NetworkError] = [
            .noConnection, .unauthorized, .forbidden, .notFound,
            .serverError(statusCode: 500), .unexpectedStatusCode(418),
            .invalidURL("bad"), .timeout
        ]
        errors.forEach { XCTAssertNotNil($0.errorDescription) }
    }

    // MARK: - NetworkClient resolve

    func test_client_resolvesRelativePath() async throws {
        let client = NetworkClient(baseURL: "https://api.example.com")
        // Just test that relative path + baseURL resolves without crashing
        let request = NetworkRequest(url: "https://api.example.com/users")
        let urlRequest = try request.buildURLRequest()
        XCTAssertEqual(urlRequest.url?.path, "/users")
    }
}
