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
open class UBPushRegistrationManager: NSObject {
    /// The push token for this device, if any
    public var pushToken: String? {
        self.pushLocalStorage.pushToken
    }

    // The URL session to use, can be overwritten by the app
    open var session: UBURLSession {
        Networking.sharedSession
    }

    /// The url needed for the registration request
    private var registrationUrl: URL?

    /// Push local storage
    private var pushLocalStorage: UBPushRegistrationLocalStorage

    /// :nodoc:
    private var maxRegistrationAge: TimeInterval {
        2 * 7 * 24 * 60 * 60 // enforce new push registration every two weeks
    }

    /// :nodoc:
    private var task: UBURLDataTask?
    private var backgroundTask = UIBackgroundTaskIdentifier.invalid

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
            || (oldToken != nil && oldToken == pushToken && !self.pushLocalStorage.isValid) {
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
    public func invalidate(completion: ((Error?) -> Void)? = nil) {
        self.pushLocalStorage.isValid = false
        sendPushRegistration(completion: completion)
    }

    /// :nodoc:
    private func sendPushRegistration(completion: ((Error?) -> Void)? = nil) {
        guard let registrationRequest = pushRegistrationRequest else {
            completion?(UBPushManagerError.registrationRequestMissing)
            return
        }

        if backgroundTask == .invalid {
            backgroundTask = UIApplication.shared.beginBackgroundTask { [weak self] in
                guard let self = self else {
                    return
                }
                if self.backgroundTask != .invalid {
                    UIApplication.shared.endBackgroundTask(self.backgroundTask)
                }
            }
        }

        task = UBURLDataTask(request: registrationRequest, session: session)
        task?.addCompletionHandler(decoder: UBHTTPStringDecoder()) { [weak self] result, _, _, _ in
            guard let self = self else {
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
        
        if task != nil {
            modifyRegistrationDataTask(&task!)
        }
        
        task?.start()
        UBPushManager.logger.info("\(String(describing: self)) started")
    }

    /// The registration request sent to the server. Clients may override this property to
    /// implement a custom registration request
    open var pushRegistrationRequest: UBURLRequest? {
        guard
            let pushToken = self.pushLocalStorage.pushToken,
            let registrationUrl = self.registrationUrl else {
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
    func sendPushRegistrationIfOutdated() {
        if !self.pushLocalStorage.isValid {
            sendPushRegistration()
        } else {
            let justPushed = UBPushManager.shared.pushHandler.lastPushed.map { lastPushed in
                let fifteenSecondsAgo = Date(timeIntervalSinceNow: -15 * 60)
                return lastPushed > fifteenSecondsAgo
            } ?? false

            let outdated = -(self.pushLocalStorage.lastRegistrationDate?.timeIntervalSinceNow ?? 0) > maxRegistrationAge

            if outdated, !justPushed {
                invalidate()
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
