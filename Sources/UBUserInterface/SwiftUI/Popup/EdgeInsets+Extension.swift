//
//  EdgeInsets+Extension.swift
//
//
//  Created by Matthias Felix on 27.09.22.
//

#if arch(arm64) || arch(x86_64)

    import SwiftUI

    @available(iOS 13.0, *)
    public extension EdgeInsets {
        static let zero = EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0)
    }

#endif
