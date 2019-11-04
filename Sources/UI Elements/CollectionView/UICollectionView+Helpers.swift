//
//  UICollectionView+Helpers.swift
//  UBFoundation iOS
//
//  Created by Marco Zimmermann on 23.09.19.
//

import UIKit

extension UICollectionReusableView: UBReusableView {}

// MARK: - Registering and Reusing Cells
extension UICollectionView
{
    /// Register a collection view cell for reuse.
    ///
    /// - Parameter cellType: The class of the collection view cell to register.
    func ub_register<T: UICollectionViewCell>(_ cellType: T.Type) {
        self.register(T.self, forCellWithReuseIdentifier: T.ub_reuseIdentifier)
    }

    /// Dequeue a reusable colection view cell for displaying at a given index path.
    ///
    /// - Parameter indexPath: The index path where the cell will be placed.
    /// - Returns: A dequeued reusable cell.
    func ub_dequeueReusableCell<T: UICollectionViewCell>(for indexPath: IndexPath) -> T {
        guard let cell = self.dequeueReusableCell(withReuseIdentifier: T.ub_reuseIdentifier, for: indexPath) as? T else {
            fatalError("Could not dequeue cell with identifier: \(T.ub_reuseIdentifier)")
        }
        return cell
    }
}

// MARK: - Registering and Reusing Supplementary Views
extension UICollectionView
{
    func ub_register<T: UICollectionReusableView>(_ viewType: T.Type, forSupplementaryViewOfKind elementKind: String) {
        self.register(T.self, forSupplementaryViewOfKind: elementKind, withReuseIdentifier: T.ub_reuseIdentifier)
    }

    func ub_dequeueReusableSupplementaryView<T: UICollectionReusableView>(ofKind elementKind: String, for indexPath: IndexPath) -> T {
        guard let view = self.dequeueReusableSupplementaryView(ofKind: elementKind, withReuseIdentifier: T.ub_reuseIdentifier, for: indexPath) as? T else {
            fatalError("Could not dequeue supplementary view with identifier: \(T.ub_reuseIdentifier)")
        }
        return view
    }
}


// MARK: - Registering and Reusing Decoration Views

extension UICollectionViewLayout
{
    func ub_register<T: UICollectionReusableView>(_ viewType: T.Type) {
        self.register(T.self, forDecorationViewOfKind: T.ub_reuseIdentifier)
    }
}

extension UICollectionViewLayoutAttributes
{
    convenience init<T: UICollectionReusableView>(forDecorationViewOfType viewType: T.Type, with indexPath: IndexPath) {
        self.init(forDecorationViewOfKind: T.ub_reuseIdentifier, with: indexPath)
    }
}
