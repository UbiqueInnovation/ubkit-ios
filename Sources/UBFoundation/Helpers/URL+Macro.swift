//
//  URL+Macro.swift
//
//
//  Created by Matthias Felix on 20.09.2023.
//

import Foundation

@freestanding(expression)
public macro URL(_ stringLiteral: String) -> URL = #externalMacro(module: "UBMacros", type: "URLMacro")
