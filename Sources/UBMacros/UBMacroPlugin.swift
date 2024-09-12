//
//  UBMacroPlugin.swift
//  
//
//  Created by Matthias Felix on 20.09.2023.
//

import Foundation
import SwiftCompilerPlugin
import SwiftSyntaxMacros

@main
struct UBMacroPlugin: CompilerPlugin {
    let providingMacros: [Macro.Type] = [
        URLMacro.self,
        UBPrintMacroDebug.self,
        UBPrintMacroRelease.self,
        UBPrintErrorMacro.self
    ]
}
