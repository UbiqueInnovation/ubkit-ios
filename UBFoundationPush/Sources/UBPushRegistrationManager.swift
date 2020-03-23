//
//  UBPushRegistrationManager.swift
//  UBFoundation iOS
//
//  Created by Zeno Koller on 23.03.20.
//

import UIKit
import UBFoundation

/// Handles registration of push tokens on our server
/// Clients can either create a pushRegistrationManager with a `registrationUrl`"
///
///     let registrationManager = UBPushRegistrationManager(registrationUrl: registrationUrl)
///
/// or subclass `UBPushRegistrationManager`, overriding `pushRegistrationRequest` if they
/// require a custom registration request.
open class UBPushRegistrationManager {
    /// The push token for this device, if any
    public var pushToken: String? {
        UBPushLocalStorage.shared.pushToken
    }

    /// The url needed for the registration request
    private var registrationUrl: URL?

    /// :nodoc:
    private var maxRegistrationAge: TimeInterval {
        2 * 7 * 24 * 60 * 60 // enforce new push registration every two weeks
    }

    /// :nodoc:
    private var task: UBURLDataTask?

    // MARK: - Initialization

    /// Creates push registration manager for the provided `registrationUrl`
    public init(registrationUrl: URL? = nil) {
        self.registrationUrl = registrationUrl
    }

    /// Sets the push token for the device, which starts a push registration
    func setPushToken(_ pushToken: String?) {
        let oldToken = UBPushLocalStorage.shared.pushToken

        // we could receive the same push token again
        // only send registration if push token has changed
        if oldToken != nil || oldToken != pushToken {
            UBPushLocalStorage.shared.pushToken = pushToken
            invalidate()
        }
    }

    /// :nodoc:
    private func validate() {
        UBPushLocalStorage.shared.isValid = true
        UBPushLocalStorage.shared.lastRegistrationDate = Date()
    }

    /// :nodoc:
    private func invalidate() {
        UBPushLocalStorage.shared.isValid = false
        sendPushRegistration()
    }

    /// :nodoc:
    private func sendPushRegistration(completion: ((Error) -> Void)? = nil) {
        guard let registrationRequest = self.pushRegistrationRequest else {
            completion?(UBPushManagerError.registrationRequestMissing)
            return
        }

        var backgroundTask = UIBackgroundTaskIdentifier.invalid
        backgroundTask = UIApplication.shared.beginBackgroundTask {
            UIApplication.shared.endBackgroundTask(backgroundTask)
        }

        task = UBURLDataTask(request: registrationRequest)
        task?.addCompletionHandler(decoder: UBHTTPStringDecoder()) { [weak self] result, _, _, _ in
            guard let self = self else {
                return
            }

            switch result {
            case let .success(responseString):
                self.validate()

                UBPushManager.logger.info("\(String(describing: self)) ended with result: \(responseString)")

            case let .failure(error):
                completion?(error)

                UBPushManager.logger.info("\(String(describing: self)) ended with error: \(error.localizedDescription)")
            }

            if backgroundTask != .invalid {
                UIApplication.shared.endBackgroundTask(backgroundTask)
            }
        }
        task?.start()
        UBPushManager.logger.info("\(String(describing: self)) started")
    }

    /// The registration request sent to the server. Clients may override this property to
    /// implement a custom registration request
    open var pushRegistrationRequest: UBURLRequest? {
        guard
            let pushToken = UBPushLocalStorage.shared.pushToken,
            let registrationUrl = self.registrationUrl else {
            return nil
        }

        var request = UBURLRequest(url: registrationUrl, method: .post, timeoutInterval: 30.0)
        do {
            try request.setHTTPJSONBody(Request(deviceUUID: self.deviceUUID, pushToken: pushToken))
        } catch {
            UBPushManager.logger.error("Could not set push registration request body: \(error.localizedDescription)")
            return nil
        }
        return request
    }

    /// :nodoc:
    func sendPushRegistrationIfOutdated() {
        if !UBPushLocalStorage.shared.isValid {
            sendPushRegistration()
        } else {
            let justPushed = UBPushManager.shared.pushHandler.lastPushed.map { lastPushed in
                let fifteenSecondsAgo = Date(timeIntervalSinceNow: -15 * 60)
                return lastPushed > fifteenSecondsAgo
            } ?? false

            let outdated = -(UBPushLocalStorage.shared.lastRegistrationDate?.timeIntervalSinceNow ?? 0) > maxRegistrationAge

            if outdated, !justPushed {
                invalidate()
            }
        }
    }

    // MARK: - UUID

    /// :nodoc:
    private var deviceUUID: String {
        if let uuid = UBPushLocalStorage.shared.deviceUUID {
            return uuid
        } else {
            UBPushLocalStorage.shared.deviceUUID = UUID().uuidString
            return self.deviceUUID
        }
    }
}

// MARK: - Push Registration Request

private extension UBPushRegistrationManager {
    /// Data POSTed to the registrationUrl in the default implementation
    struct Request: Codable {
        let deviceUUID: String
        let pushToken: String
        let type = "IOS"
    }
}
