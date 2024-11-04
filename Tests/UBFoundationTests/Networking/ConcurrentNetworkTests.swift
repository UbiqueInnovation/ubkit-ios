//
//  ConcurrentNetworkTests.swift
//
//
//  Created by Nicolas Märki on 16.05.22.
//

import UBFoundation
import UBLocalNetworking
import XCTest

@available(iOS 15.0.0, *)
@MainActor
class ConcurrentNetworkTests: XCTestCase {
    private let sampleUrl = URL(string: "http://mock.ubique.ch/user.json")!
    private lazy var sampleRequest = UBURLRequest(url: sampleUrl)

    private let cronUrl = URL(string: "http://mock.ubique.ch/cron.json")!
    private lazy var cronRequest = UBURLRequest(url: cronUrl)

    private var brokenSampleRequest: UBURLRequest {
        let url = URL(string: "https://not.a.mock.amazonaws.com/but/DOES_NOT_EXIST.json")!
        let request = UBURLRequest(url: url)
        return request
    }

    private struct User: Encodable {
        let name: String
    }

    private let sampleResponse = User(name: "Jhon")

    private let sharedSession: UBDataTaskURLSession = URLSession.shared

    private var fastCronSession: UBDataTaskURLSession {
        let cache = MeteoAutoRefreshCacheLogic()
        let conf = UBURLSessionConfiguration(cachingLogic: cache)
        let c = URLCache(memoryCapacity: 1024 * 1024 * 4, diskCapacity: 1024 * 1024 * 10, diskPath: "meteo")
        c.removeAllCachedResponses()
        conf.sessionConfiguration.urlCache = c
        conf.sessionConfiguration.protocolClasses = [LocalServerURLProtocol.self]
        let session = UBURLSession(configuration: conf)
        return session
    }

    override func setUp() {
        LocalServer.resumeLocalServerOnSharedSession()

        let responseProvider = try! BasicResponseProvider(rule: sampleUrl.absoluteString, encodable: sampleResponse)
        responseProvider.addToLocalServer()

        let cronResponseProvider = try! BasicResponseProvider(rule: cronUrl.absoluteString, body: "Hello, World!", header: BasicResponseProvider.Header(statusCode: 200, headerFields: [
            "x-amz-meta-backoff": "60",
            "x-amz-meta-cache": "max-age=300",
            "x-amz-version-id": "qSojcs_cgESN8uLviKqiyCiFauZY0kxw",
            "x-amz-meta-next-refresh": "Mon, 06 Feb 2023 14:06:01 GMT",
            "Date": UBBaseCachingLogic().dateFormatter.string(from: Date()),
        ]))
        cronResponseProvider.addToLocalServer()
    }

    override func tearDown() {
        LocalServer.removeAllResponseProviders()
        LocalServer.pauseLocalServer()
    }

    func testBasicRequest() async throws {
        let _ = await UBURLDataTask.with(session: sharedSession).loadOnce(request: sampleRequest, decoder: .passthrough)
    }

    func testBasicRequestWithUrl() async throws {
        let data1 = try await UBURLDataTask.with(session: sharedSession).loadOnce(url: sampleUrl, decoder: .passthrough).data
        let data2 = try await UBURLDataTask.with(session: sharedSession).loadOnce(request: sampleRequest, decoder: .passthrough).data
        XCTAssertEqual(data1, data2)
    }

    func testRepeatedRequestAsync() async throws {
        let _ = await UBURLDataTask.with(session: sharedSession).loadOnce(request: sampleRequest, decoder: .passthrough)
        let _ = await UBURLDataTask.with(session: sharedSession).loadOnce(request: sampleRequest, decoder: .passthrough)
    }

    func testRequestError() async throws {
        do {
            let _ = try await UBURLDataTask.with(session: sharedSession).loadOnce(request: brokenSampleRequest, decoder: .passthrough).data
            XCTFail("Should not reach this")
        } catch {
            // error is good
        }
    }

    func testCronStream() async throws {
        let task = UBURLDataTask(request: cronRequest, session: fastCronSession)
        var count = 0
        for try await _ in task.startStream(decoder: .passthrough) {
            count += 1
            if count >= 3 {
                return
            }
        }
    }

    func testRepeatingStream() async throws {
        let task = UBURLDataTask(request: cronRequest, session: fastCronSession)
        var count = 0
        for try await _ in task.startStream(decoder: .passthrough) {
            count += 1
            break
        }
        for try await _ in task.startStream(decoder: .passthrough) {
            count += 1
            break
        }
        XCTAssertEqual(count, 2)
    }

    func testTaskCancellation() throws {
        let exp1 = expectation(description: "After first result")
        let exp2 = expectation(description: "After cancel")

        let cache = MeteoAutoRefreshCacheLogic()
        let conf = UBURLSessionConfiguration(cachingLogic: cache)
        let c = URLCache(memoryCapacity: 1024 * 1024 * 4, diskCapacity: 1024 * 1024 * 10, diskPath: "meteo")
        c.removeAllCachedResponses()
        conf.sessionConfiguration.urlCache = c
        conf.sessionConfiguration.protocolClasses = [LocalServerURLProtocol.self]
        let session = UBURLSession(configuration: conf)

        let t = Task.detached {
            let task = UBURLDataTask(url: URL(string: "http://mock.ubique.ch/cron.json")!, session: session)
            for try await _ in task.startStream(decoder: .passthrough) {
                exp1.fulfill()
            }
            exp2.fulfill()
        }
        wait(for: [exp1], timeout: 30)
        t.cancel()
        wait(for: [exp2], timeout: 30)
    }
}

private class MeteoAutoRefreshCacheLogic: UBAutoRefreshCacheLogic, @unchecked Sendable {
    override var nextRefreshHeaderFieldName: [String] {
        ["x-amz-meta-next-refresh"]
    }

    override var backoffIntervalHeaderFieldName: [String] {
        ["x-amz-meta-backoff"]
    }

    override var expiresHeaderFieldName: [String] {
        ["x-amz-meta-best-before"]
    }

    override var cacheControlHeaderFieldName: [String] {
        ["x-amz-meta-cache"]
    }

    override var eTagHeaderFieldName: String {
        "Etag"
    }

    // scale relative time for faster unit test
    override func cachedResponseNextRefreshDate(_ allHeaderFields: [AnyHashable: Any], metrics: URLSessionTaskMetrics?, referenceDate: Date?) -> Date? {
        if let date = super.cachedResponseNextRefreshDate(allHeaderFields, metrics: metrics, referenceDate: referenceDate) {
            Date(timeIntervalSinceNow: date.timeIntervalSinceNow * 0.01)
        } else {
            nil
        }
    }
}
