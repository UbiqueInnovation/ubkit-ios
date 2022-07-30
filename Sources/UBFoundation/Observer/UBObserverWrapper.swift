//
//  UBObserver.swift
//  
//
//  Created by Zeno Koller on 18.07.22.
//

import Foundation

/// Helper class for block-based observers which automatically removes the observer on deinit,
/// removing the need to manually remove the observer for the caller
public class UBObserver {
    var observer: Any?
    public init(forName name: Notification.Name, object: Any? = nil, queue: OperationQueue? = nil, block: @escaping (Notification) -> Void) {
        observer = NotificationCenter.default.addObserver(forName: name, object: object, queue: queue, using: block)
    }
    deinit {
        if let observer = observer {
            NotificationCenter.default.removeObserver(observer)
        }
    }
}
