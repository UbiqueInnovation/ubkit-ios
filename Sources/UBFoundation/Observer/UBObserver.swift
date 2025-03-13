import Foundation

public extension NotificationCenter {
    /// Adds an entry to the notification center to receive notifications that passed to the provided block. This is a managed observation
    /// that will be ended as soon as the reference returned object is deallocated.
    ///
    /// If a notification triggers more than one observer block, the blocks can all execute concurrently (but on their queue or on the current thread).
    ///
    /// - Note: You need to hold to the reference returned otherwise the observation is terminated
    /// - Parameters:
    ///   - name: The name of the notification to register for delivery to the observer block. Specify a notification name to deliver only entries with this notification name.
    ///   When nil, the sender doesn’t use notification names as criteria for delivery.
    ///   - object: The object that sends notifications to the observer block. Specify a sender to deliver only notifications from this sender.
    ///   When nil, the notification center doesn’t use the sender as criteria for the delivery.
    ///   - queue: The operation queue where the block runs.
    ///   When nil, the block runs synchronously on the posting thread.
    ///   - block: The block that executes when receiving a notification.
    ///   The notification center copies the block. The notification center strongly holds the copied block until you remove the observer registration.
    ///   The block takes one argument: the notification.
    /// - Returns: An opaque object to act as the observer. You must strongly holds to this return value unless it will be deallocated and the observation is removed.
    func addUBObserver(forName name: NSNotification.Name?, object: Any? = nil, queue: OperationQueue? = .main, using block: @escaping @Sendable (Notification) -> Void) -> Any {
        let reference = self.addObserver(forName: name, object: object, queue: queue, using: block)
        let token = NotificationCenterObservationHolder(reference: reference, notificationCenter: self)
        return token
    }
}

/// An opaque object that cancels a notification when it's deallocated
private class NotificationCenterObservationHolder {
    let reference: Any?
    let notificationCenter: NotificationCenter

    init(reference: Any?, notificationCenter: NotificationCenter) {
        self.reference = reference
        self.notificationCenter = notificationCenter
    }

    deinit {
        if let reference {
            notificationCenter.removeObserver(reference)
        }
    }
}
