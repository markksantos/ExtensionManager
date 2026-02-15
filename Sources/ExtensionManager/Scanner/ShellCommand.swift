import Foundation

struct ShellCommand {
    /// Run a shell command and return its stdout output
    static func run(_ command: String, arguments: [String] = []) -> String {
        let process = Process()
        let pipe = Pipe()
        process.executableURL = URL(fileURLWithPath: command)
        process.arguments = arguments
        process.standardOutput = pipe
        process.standardError = FileHandle.nullDevice
        try? process.run()
        // Read data BEFORE waitUntilExit to avoid pipe buffer deadlock
        // (pluginkit output can exceed the 64KB pipe buffer)
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        process.waitUntilExit()
        return String(data: data, encoding: .utf8) ?? ""
    }

    /// Run a command through /bin/bash -c
    static func bash(_ command: String) -> String {
        run("/bin/bash", arguments: ["-c", command])
    }
}
