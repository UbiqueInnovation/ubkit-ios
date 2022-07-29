import ArgumentParser
import Foundation

// MARK: - UBSwiftFormatTool

/// A command line tool that formats the given directories using SwiftFormat
@main
struct UBSwiftFormatTool: ParsableCommand {

    // MARK: Internal

    @Argument(help: "The directories to format")
    var directories: [String]

    @Option(help: "The absolute path to a SwiftFormat binary")
    var swiftFormatPath: String

    @Option(help: "The absolute path to use for SwiftFormat's cache")
    var swiftFormatCachePath: String?

    @Flag(help: "When true, logs the commands that are executed")
    var log = false

    @Option(help: "The absolute path to the SwiftFormat config file")
    var swiftFormatConfig = Bundle.module.path(forResource: "UB", ofType: "swiftformat")!

    @Option(help: "The project's minimum Swift version")
    var swiftVersion: String?

    mutating func run() throws {
        try swiftFormat.run()
        swiftFormat.waitUntilExit()

        if log {
            log(swiftFormat.shellCommand)
            log("SwiftFormat ended with exit code \(swiftFormat.terminationStatus)")
        }

        if swiftFormat.terminationStatus == SwiftFormatExitCode.failure
        {
            throw ExitCode.failure
        }

        // Any other non-success exit code is an unknown failure
        if swiftFormat.terminationStatus != EXIT_SUCCESS {
            throw ExitCode(swiftFormat.terminationStatus)
        }
    }

    // MARK: Private

    private lazy var swiftFormat: Process = {
        var arguments = directories + [
            "--config", swiftFormatConfig,
        ]

        if let swiftFormatCachePath = swiftFormatCachePath {
            arguments += ["--cache", swiftFormatCachePath]
        }

        if let swiftVersion = swiftVersion {
            arguments += ["--swiftversion", swiftVersion]
        }

        let swiftFormat = Process()
        swiftFormat.launchPath = swiftFormatPath
        swiftFormat.arguments = arguments
        return swiftFormat
    }()

    private func log(_ string: String) {
        // swiftlint:disable:next no_direct_standard_out_logs
        print(string)
    }

}

extension Process {
    var shellCommand: String {
        let launchPath = launchPath ?? ""
        let arguments = arguments ?? []
        return "\(launchPath) \(arguments.joined(separator: " "))"
    }
}

// MARK: - SwiftFormatExitCode

/// Known exit codes used by SwiftFormat
enum SwiftFormatExitCode {
    static let failure: Int32 = 1
}
