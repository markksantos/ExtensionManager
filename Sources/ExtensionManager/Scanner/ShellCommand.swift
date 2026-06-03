import Foundation

struct ShellCommand {
    /// Run a shell command and return its stdout output.
    /// If the command fails, the error is logged to stderr but the
    /// function returns an empty string — callers should not depend
    /// on stderr text being returned (they can observe log output).
    static func run(_ command: String, arguments: [String] = []) -> String {
        let process = Process()
        let outPipe = Pipe()
        let errPipe = Pipe()
        process.executableURL = URL(fileURLWithPath: command)
        process.arguments = arguments
        process.standardOutput = outPipe
        process.standardError = errPipe
        try? process.run()

         // Read data BEFORE waitUntilExit to avoid pipe buffer deadlock
         // (pluginkit output can exceed the 64KB pipe buffer)
        let outData = outPipe.fileHandleForReading.readDataToEndOfFile()
        let errData = errPipe.fileHandleForReading.readDataToEndOfFile()
        process.waitUntilExit()

         // Log errors to stderr for debugging; callers don't parse this.
        if process.terminationStatus != 0, let err = String(data: errData, encoding: .utf8), !err.isEmpty {
            fputs("ShellCommand[\(command)]: \(err)", stderr)
        }

        return String(data: outData, encoding: .utf8) ?? ""
     }

    /// Run a command through /bin/bash -c
    static func bash(_ command: String) -> String {
        run("/bin/bash", arguments: ["-c", command])
     }
}
