//
//  URLSessionDataTaskMock.swift
//  UBFoundation
//
//  Created by Joseph El Mallah on 22.03.19.
//

import Foundation

class URLSessionDataTaskMock: URLSessionDataTask {
    var completionHandler: (Data?, URLResponse?, Error?) -> Void
    var config: Configuration
    var timeoutInterval: TimeInterval

    init(config: Configuration, timeoutInterval: TimeInterval, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) {
        self.completionHandler = completionHandler
        self.config = config
        self.timeoutInterval = timeoutInterval
        super.init()
    }

    private var _taskDescription: String?
    override var taskDescription: String? {
        get {
            return _taskDescription
        }
        set {
            _taskDescription = newValue
        }
    }

    private var _state: URLSessionTask.State = .suspended {
        willSet {
            willChangeValue(for: \.state)
        }
        didSet {
            switch _state {
            case .running:
                timeoutTimer = Timer(timeInterval: timeoutInterval, repeats: false, block: { [weak self] _ in
                    self?.completionHandler(nil, nil, NSError(domain: NSURLErrorDomain, code: NSURLErrorTimedOut, userInfo: [NSLocalizedDescriptionKey: "Request Timedout"]))
                    self?.activeTimer?.invalidate()
                    self?._state = .completed
                })
                RunLoop.main.add(timeoutTimer!, forMode: RunLoop.Mode.common)
            case .canceling, .completed, .suspended:
                timeoutTimer?.invalidate()
            }
            didChangeValue(for: \.state)
        }
    }

    private var _progress = Progress(totalUnitCount: 100)

    override var progress: Progress {
        return _progress
    }

    override var state: URLSessionTask.State {
        return _state
    }

    private var timeoutTimer: Timer?
    private var waiting: Bool = false
    override func resume() {
        guard _state == .suspended, waiting == false else {
            return
        }
        waiting = true
        let t = Timer(timeInterval: config.idleWaitTime, repeats: false) { [weak self] _ in
            guard let self = self else {
                return
            }
            self.waiting = false
            self._state = .running
            self.simulateNetworking(config: self.config)
        }
        activeTimer = t
        RunLoop.main.add(t, forMode: RunLoop.Mode.common)
    }

    override func cancel() {
        guard _state == .running || _state == .suspended else {
            return
        }
        _state = .canceling
        activeTimer?.invalidate()
        completionHandler(nil, nil, NSError(domain: NSURLErrorDomain, code: NSURLErrorCancelled, userInfo: [NSLocalizedDescriptionKey: "Request Cancelled"]))
    }

    private var activeTimer: Timer?
    private func simulateNetworking(config: Configuration) {
        assert(_state == .running)
        let t = Timer(timeInterval: 1, repeats: false) { [weak self] _ in
            guard config.error == nil else {
                self?.completionHandler(nil, config.response, config.error)
                self?._state = .completed
                return
            }
            let initialValue: Int64 = Int64(config.progressUpdateCount)
            var counter: Int64 = 0
            let m = Timer(timeInterval: TimeInterval(config.transferDuration / TimeInterval(initialValue)), repeats: true, block: { [weak self] timer in
                counter += 1
                if counter <= initialValue {
                    self?._progress.completedUnitCount = Int64((Float(counter) / Float(initialValue)) * 100)
                    return
                }
                timer.invalidate()
                self?.completionHandler(config.data, config.response, nil)
                self?._state = .completed
            })
            self?.activeTimer = m
            RunLoop.main.add(m, forMode: RunLoop.Mode.common)
        }
        activeTimer = t
        RunLoop.main.add(t, forMode: RunLoop.Mode.common)
    }
}

extension URLSessionDataTaskMock {
    struct Configuration {
        let idleWaitTime: TimeInterval
        let latency: TimeInterval
        let transferDuration: TimeInterval
        let progressUpdateCount: Int
        let data: Data?
        let response: URLResponse?
        let error: Error?
    }
}
