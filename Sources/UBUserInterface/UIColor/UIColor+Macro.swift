//
//  UIColor+Macro.swift
//
//
//  Created by Matthias Felix on 20.09.2023.
//

import Foundation

#if canImport(UIKit)

@freestanding(expression)
public macro UIColor(_ stringLiteral: String) -> URL = #externalMacro(module: "UBMacros", type: "UIColorMacro")

#endif
