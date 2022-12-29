//
//  UICollectionView+Helpers.swift
//  UBFoundation iOS
//
//  Created by Marco Zimmermann on 23.09.19.
//
#if os(iOS) || os(tvOS) || os(watchOS)

import UIKit

extension UICollectionReusableView: UBReusableView {}

// MARK: - Registering and Reusing Cells

public extension UICollectionView {
    /// Register a collection view cell for reuse.
    ///
    /// - Parameter cellType: The class of the collection view cell to register.
    func ub_register<T: UICollectionViewCell>(_: T.Type) {
        register(T.self, forCellWithReuseIdentifier: T.ub_reuseIdentifier)
    }

    /// Dequeue a reusable colection view cell for displaying at a given index path.
    ///
    /// - Parameter indexPath: The index path where the cell will be placed.
    /// - Returns: A dequeued reusable cell.
    func ub_dequeueReusableCell<T: UICollectionViewCell>(for indexPath: IndexPath) -> T {
        guard let cell = dequeueReusableCell(withReuseIdentifier: T.ub_reuseIdentifier, for: indexPath) as? T else {
            fatalError("Could not dequeue cell with identifier: \(T.ub_reuseIdentifier)")
        }
        return cell
    }
}

// MARK: - Registering and Reusing Supplementary Views

public extension UICollectionView {
    func ub_register<T: UICollectionReusableView>(_: T.Type, forSupplementaryViewOfKind elementKind: String) {
        register(T.self, forSupplementaryViewOfKind: elementKind, withReuseIdentifier: T.ub_reuseIdentifier)
    }

    func ub_dequeueReusableSupplementaryView<T: UICollectionReusableView>(ofKind elementKind: String, for indexPath: IndexPath) -> T {
        guard let view = dequeueReusableSupplementaryView(ofKind: elementKind, withReuseIdentifier: T.ub_reuseIdentifier, for: indexPath) as? T else {
            fatalError("Could not dequeue supplementary view with identifier: \(T.ub_reuseIdentifier)")
        }
        return view
    }
}

// MARK: - Registering and Reusing Decoration Views

public extension UICollectionViewLayout {
    func ub_register<T: UICollectionReusableView>(_: T.Type) {
        register(T.self, forDecorationViewOfKind: T.ub_reuseIdentifier)
    }
}

public extension UICollectionViewLayoutAttributes {
    convenience init<T: UICollectionReusableView>(forDecorationViewOfType _: T.Type, with indexPath: IndexPath) {
        self.init(forDecorationViewOfKind: T.ub_reuseIdentifier, with: indexPath)
    }
}
#endif
