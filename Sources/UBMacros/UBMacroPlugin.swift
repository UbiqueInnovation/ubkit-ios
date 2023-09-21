//
//  File.swift
//  
//
//  Created by Matthias Felix on 20.09.2023.
//

import Foundation
import SwiftCompilerPlugin
import SwiftSyntaxMacros

@main
struct UBMacroPlugin: CompilerPlugin {
#if canImport(UIKit)
    let providingMacros: [Macro.Type] = [
        URLMacro.self,
        UIColorMacro.self,
    ]
#else
    let providingMacros: [Macro.Type] = [
        URLMacro.self,
    ]
#endif
}
