//
//  UITableView+Helpers.swift
//  UBFoundation iOS
//
//  Created by Marco Zimmermann on 23.09.19.
//

import UIKit

// MARK: - Registering and Reusing Cells

/// A view that can be reused.
protocol ReusableView: AnyObject
{
    /// The reuse identifier of a view.
    ///
    /// The default implementation returns the name of the class.
    static var reuseIdentifier: String { get }
}

extension ReusableView where Self: UIView
{
    static var reuseIdentifier: String {
        return String(describing: self)
    }
}

extension UITableViewCell: ReusableView {}

extension UITableView
{
    /// Register a table view cell for reuse.
    ///
    /// - Parameter cellType: The class of the table view cell to register.
    func register<T: UITableViewCell>(_ cellType: T.Type) {
        self.register(T.self, forCellReuseIdentifier: T.reuseIdentifier)
    }

    /// Dequeue a reusable table view cell for displaying at a given index path.
    ///
    /// - Parameter indexPath: The index path where the cell will be placed.
    /// - Returns: A dequeued reusable cell.
    func dequeueReusableCell<T: UITableViewCell>(for indexPath: IndexPath) -> T {
        guard let cell = self.dequeueReusableCell(withIdentifier: T.reuseIdentifier, for: indexPath) as? T else {
            fatalError("Could not dequeue cell with identifier: \(T.reuseIdentifier)")
        }
        return cell
    }
}


// MARK: - Registering and Reusing Header and Footer Views

extension UITableViewHeaderFooterView: ReusableView {}

extension UITableView
{
    /// Register a view for reuse as header or footer view.
    ///
    /// - Parameter viewType: The class of the view to register.
    func register<T: UITableViewHeaderFooterView>(_ viewType: T.Type) {
        self.register(T.self, forHeaderFooterViewReuseIdentifier: T.reuseIdentifier)
    }

    /// Dequeue a reusable view for displaying as a header or footer view.
    ///
    /// - Returns: A dequeued reusable view.
    func dequeueReusableHeaderFooterView<T: UITableViewHeaderFooterView>() -> T {
        guard let view = self.dequeueReusableHeaderFooterView(withIdentifier: T.reuseIdentifier) as? T else {
            fatalError("Could not dequeue view with identifier: \(T.reuseIdentifier)")
        }
        return view
    }
}
