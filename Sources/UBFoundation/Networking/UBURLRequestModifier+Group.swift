//
//  UBURLRequestModifier+Group.swift
//  UBFoundation
//
//  Created by Joseph El Mallah on 01.04.19.
//

import Foundation

/// A group of request modifiers
public class UBURLRequestModifierGroup: UBURLRequestModifier {
    // - MARK: Properties

    /// :nodoc:
    private let serialModifiers = DispatchQueue(label: "Group Modifiers")
    /// :nodoc:
    private var _modifiers: [UBURLRequestModifier]
    /// The list of modifier in the group
    public var modifiers: [UBURLRequestModifier] {
        serialModifiers.sync {
            _modifiers
        }
    }

    // - MARK: Initializers

    /// Initializes the group with modifiers
    ///
    /// - Parameter modifiers: The list of modifiers to add in the group. Default to nothing
    public init(modifiers: [UBURLRequestModifier] = []) {
        _modifiers = modifiers
    }

    /// :nodoc:
    deinit {
        cancelCurrentModification()
    }

    /// Add a modifier to the group
    ///
    /// - Parameter modifier: The modifier to add
    public func append(_ modifier: UBURLRequestModifier) {
        serialModifiers.sync {
            _modifiers.append(modifier)
        }
    }

    /// Add a modifier to the group
    ///
    /// - Parameter modifier: The modifier to add
    @available(iOS 13.0, *)
    public func append(_ modifier: UBAsyncURLRequestModifier) {
        serialModifiers.sync {
            _modifiers.append(modifier)
        }
    }

    /// :nodoc:
    private let serialOperation = DispatchQueue(label: "Group Modifiers Operation")
    /// :nodoc:
    private var currentModification: Modification?
    /// Cancels the ongowing modification
    public func cancelCurrentModification() {
        serialOperation.sync {
            currentModification?.cancelled = true
        }
    }

    /// :nodoc:
    public func modifyRequest(_ originalRequest: UBURLRequest, completion: @escaping (Result<UBURLRequest, Error>) -> Void) {
        cancelCurrentModification()

        let newModification = Modification()
        var modifiers = ArraySlice<UBURLRequestModifier>()
        serialOperation.sync {
            currentModification = newModification
            modifiers = ArraySlice(self.modifiers)
        }
        recursiveModifyRequest(originalRequest, modification: newModification, modifiers: modifiers, completion: completion)
    }

    /// :nodoc:
    private func recursiveModifyRequest(_ originalRequest: UBURLRequest, modification: Modification, modifiers: ArraySlice<UBURLRequestModifier>, completion: @escaping (Result<UBURLRequest, Error>) -> Void) {
        guard modification.cancelled == false else {
            return
        }
        guard let modifier = modifiers.first else {
            completion(.success(originalRequest))
            return
        }

        modifier.modifyRequest(originalRequest) { result in
            switch result {
                case let .failure(error):
                    completion(.failure(error))
                case let .success(request):
                    self.recursiveModifyRequest(request, modification: modification, modifiers: modifiers.dropFirst(), completion: completion)
            }
        }
    }
}

extension UBURLRequestModifierGroup {
    /// This is used to convey cancellation information to the running task
    private class Modification {
        /// :nodoc
        private let serial = DispatchQueue(label: "Group Modifiers Modification Object")
        /// :nodoc
        private var _cancelled: Bool = false
        /// :nodoc
        var cancelled: Bool {
            get {
                serial.sync {
                    _cancelled
                }
            }
            set {
                serial.sync {
                    _cancelled = newValue
                }
            }
        }
    }
}
