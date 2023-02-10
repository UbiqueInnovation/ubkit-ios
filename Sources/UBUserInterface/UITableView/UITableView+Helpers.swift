//
//  UITableView+Helpers.swift
//  UBFoundation iOS
//
//  Created by Marco Zimmermann on 23.09.19.
//

import UIKit

// MARK: - Registering and Reusing Cells

/// A view that can be reused.
protocol UBReusableView: AnyObject {
    /// The reuse identifier of a view.
    ///
    /// The default implementation returns the name of the class.
    static var ub_reuseIdentifier: String { get }
}

extension UBReusableView where Self: UIView {
    static var ub_reuseIdentifier: String {
        String(describing: self)
    }
}

extension UITableViewCell: UBReusableView {}

public extension UITableView {
    /// Register a table view cell for reuse.
    ///
    /// - Parameter cellType: The class of the table view cell to register.
    func ub_register<T: UITableViewCell>(_: T.Type) {
        register(T.self, forCellReuseIdentifier: T.ub_reuseIdentifier)
    }

    /// Dequeue a reusable table view cell for displaying at a given index path.
    ///
    /// - Parameter indexPath: The index path where the cell will be placed.
    /// - Returns: A dequeued reusable cell.
    func ub_dequeueReusableCell<T: UITableViewCell>(for indexPath: IndexPath) -> T {
        guard let cell = dequeueReusableCell(withIdentifier: T.ub_reuseIdentifier, for: indexPath) as? T else {
            fatalError("Could not dequeue cell with identifier: \(T.ub_reuseIdentifier)")
        }
        return cell
    }
}

// MARK: - Registering and Reusing Header and Footer Views

extension UITableViewHeaderFooterView: UBReusableView {}

public extension UITableView {
    /// Register a view for reuse as header or footer view.
    ///
    /// - Parameter viewType: The class of the view to register.
    func ub_register<T: UITableViewHeaderFooterView>(_: T.Type) {
        register(T.self, forHeaderFooterViewReuseIdentifier: T.ub_reuseIdentifier)
    }

    /// Dequeue a reusable view for displaying as a header or footer view.
    ///
    /// - Returns: A dequeued reusable view.
    func ub_dequeueReusableHeaderFooterView<T: UITableViewHeaderFooterView>() -> T {
        guard let view = dequeueReusableHeaderFooterView(withIdentifier: T.ub_reuseIdentifier) as? T else {
            fatalError("Could not dequeue view with identifier: \(T.ub_reuseIdentifier)")
        }
        return view
    }
}
