//
//  UBPushRegistrationManager.swift
//  UBFoundation iOS
//
//  Created by Zeno Koller on 23.03.20.
//

import UBFoundation
import UIKit

/// Handles registration of push tokens on our server
/// Clients can either create a pushRegistrationManager with a `registrationUrl`"
///
///     let registrationManager = UBPushRegistrationManager(registrationUrl: registrationUrl)
///
/// or subclass `UBPushRegistrationManager`, overriding `pushRegistrationRequest` if they
/// require a custom registration request.
@MainActor
open class UBPushRegistrationManager: NSObject {
    /// The push token for this device, if any
    public var pushToken: String? {
        self.pushLocalStorage.pushToken
    }

    // The URL session to use, can be overwritten by the app
    open var session: UBURLSession {
        .sharedSession
    }

    /// The url needed for the registration request
    private var registrationUrl: URL?

    /// Push local storage
    private var pushLocalStorage: UBPushRegistrationLocalStorage

    /// :nodoc:
    private var maxRegistrationAge: TimeInterval {
        2 * 7 * 24 * 60 * 60  // enforce new push registration every two weeks
    }

    /// :nodoc:
    private var task: UBURLDataTask?
    private var backgroundTask = UIBackgroundTaskIdentifier.invalid
    private let registrationQueue = DispatchQueue(label: "UBPushRegistrationManager.registrationQueue")

    // MARK: - Initialization

    /// Creates push registration manager for the provided `registrationUrl`
    public init(pushLocalStorage: UBPushRegistrationLocalStorage? = nil, registrationUrl: URL? = nil) {
        self.pushLocalStorage = pushLocalStorage ?? UBPushRegistrationStandardLocalStorage.shared
        self.registrationUrl = registrationUrl

        super.init()
    }

    /// Sets the push token for the device, which starts a push registration
    func setPushToken(_ pushToken: String?) {
        let oldToken = self.pushLocalStorage.pushToken

        // we could receive the same push token again
        // only send registration if push token has changed
        if (oldToken == nil && pushToken != nil)
            || (oldToken != nil && oldToken != pushToken)
            || (oldToken != nil && oldToken == pushToken && !self.pushLocalStorage.isValid)
        {
            self.pushLocalStorage.pushToken = pushToken
            invalidate()
        }
    }

    /// :nodoc:
    public func validate() {
        self.pushLocalStorage.isValid = true
        self.pushLocalStorage.lastRegistrationDate = Date()
    }

    /// :nodoc:
    public func invalidate(completion: (@Sendable (Error?) -> Void)? = nil) {
        self.pushLocalStorage.isValid = false
        sendPushRegistrationIfOutdated(completion: completion)
    }

    open func sendPushRegistrationRequest(completion: (@escaping @Sendable (Result<String, Error>) -> Void)) {
        guard let registrationRequest = pushRegistrationRequest else {
            completion(.failure(UBPushManagerError.registrationRequestMissing))
            return
        }

        task = UBURLDataTask(request: registrationRequest, session: session)
        task?
            .addCompletionHandler(decoder: UBHTTPStringDecoder()) { result, _, _, _ in
                switch result {
                    case .success(let value): completion(.success(value))
                    case .failure(let error): completion(.failure(error))
                }
            }

        if task != nil {
            modifyRegistrationDataTask(&task!)
        }

        task?.start()
    }

    /// :nodoc:
    private func sendPushRegistration(completion: (@Sendable (Error?) -> Void)? = nil) {
        if backgroundTask == .invalid {
            backgroundTask = UIApplication.shared.beginBackgroundTask { [weak self] in
                guard let self else {
                    return
                }
                if self.backgroundTask != .invalid {
                    UIApplication.shared.endBackgroundTask(self.backgroundTask)
                }
            }
        }

        sendPushRegistrationRequest { [weak self] result in
            MainActor.assumeIsolated {
                guard let self else {
                    return
                }

                switch result {
                    case let .success(responseString):
                        self.validate()
                        completion?(nil)

                        UBPushManager.logger.info("\(String(describing: self)) ended with result: \(responseString)")

                    case let .failure(error):
                        completion?(error)

                        UBPushManager.logger.info("\(String(describing: self)) ended with error: \(error.localizedDescription)")
                }

                if self.backgroundTask != .invalid {
                    UIApplication.shared.endBackgroundTask(self.backgroundTask)
                }
            }
        }

        UBPushManager.logger.info("\(String(describing: self)) started")
    }

    /// The registration request sent to the server. Clients may override this property to
    /// implement a custom registration request
    open var pushRegistrationRequest: UBURLRequest? {
        guard
            let pushToken = self.pushLocalStorage.pushToken,
            let registrationUrl = self.registrationUrl
        else {
            return nil
        }

        var request = UBURLRequest(url: registrationUrl, method: .post, timeoutInterval: 30.0)
        do {
            try request.setHTTPJSONBody(Request(deviceUUID: pushDeviceUUID, pushToken: pushToken))
        } catch {
            UBPushManager.logger.error("Could not set push registration request body: \(error.localizedDescription)")
            return nil
        }
        return request
    }

    /// This method can be overwritten by subclasses to modify the data task
    /// for the registration request, e.g. to add request modifiers. It will be called
    /// each time the push registration is triggered, right before the task is started.
    open func modifyRegistrationDataTask(_ task: inout UBURLDataTask) {}

    /// :nodoc:
    func sendPushRegistrationIfOutdated(completion: (@Sendable (Error?) -> Void)? = nil) {
        DispatchQueue.global(qos: .utility)
            .async { [weak self] in
                guard let self else { return }

                // Serialize registration to avoid running multiple requests in parallel
                registrationQueue.sync {

                    var lastPushed: Date?
                    var lastRegistrationDate: Date?
                    var maxRegistrationAge: TimeInterval?
                    var isValid = false

                    DispatchQueue.main.sync {
                        lastPushed = UBPushManager.shared.pushHandler.lastPushed
                        lastRegistrationDate = self.pushLocalStorage.lastRegistrationDate
                        maxRegistrationAge = self.maxRegistrationAge
                        isValid = self.pushLocalStorage.isValid
                    }

                    let justPushed =
                        lastPushed.map { lastPushed in
                            let fifteenSecondsAgo = Date(timeIntervalSinceNow: -15 * 60)
                            return lastPushed > fifteenSecondsAgo
                        } ?? false

                    let outdated = -(lastRegistrationDate?.timeIntervalSinceNow ?? 0) > maxRegistrationAge!

                    // Only act if registration is invalid or needs to be refreshed (which we ignore if we just received a push recently)
                    if !isValid || outdated, !justPushed {

                        let done = DispatchSemaphore(value: 0)

                        DispatchQueue.main.async {
                            self.sendPushRegistration { error in
                                DispatchQueue.main.async {
                                    completion?(error)
                                }

                                done.signal()
                            }
                        }
  
                        // Wait until push registration request has finished
                        done.wait()
                    } else {
                        // Everything up to date, nothing to do
                        DispatchQueue.main.async {
                            completion?(nil)
                        }
                    }

                }
            }
    }

    // MARK: - UUID

    /// :nodoc:
    open var pushDeviceUUID: String {
        UBDeviceUUID.getUUID()
    }

    open var isValid: Bool {
        self.pushLocalStorage.isValid
    }
}

// MARK: - Push Registration Request

private extension UBPushRegistrationManager {
    /// Data POSTed to the registrationUrl in the default implementation
    struct Request: Codable {
        let deviceUUID: String
        let pushToken: String
        var type = "IOS"
    }
}
