import Foundation

final class ExtensionScanner: Sendable {

    func scanAll() async -> [SystemExtension] {
        await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async { [self] in
                var results: [SystemExtension] = []
                results.append(contentsOf: self.scanPluginKit())
                results.append(contentsOf: self.scanSystemExtensions())

                // Filter out Apple extensions
                results = results.filter { !$0.bundleIdentifier.hasPrefix("com.apple.") }

                // Deduplicate by bundleIdentifier
                var seen = Set<String>()
                results = results.filter { ext in
                    if seen.contains(ext.bundleIdentifier) { return false }
                    seen.insert(ext.bundleIdentifier)
                    return true
                }

                continuation.resume(returning: results)
            }
        }
    }

    // MARK: - PluginKit

    func scanPluginKit() -> [SystemExtension] {
        let output = ShellCommand.run("/usr/bin/pluginkit", arguments: ["-mDvvv"])
        return parsePluginKitOutput(output)
    }

    func parsePluginKitOutput(_ output: String) -> [SystemExtension] {
        var extensions: [SystemExtension] = []
        let lines = output.components(separatedBy: "\n")

        // Header pattern: optional +/- flag, then spaces, then bundle.id(version)
        // Real output:  "+    com.example.ext(1.0)"  or  "-    com.example.ext(1.0)"
        //               or  "     com.example.ext(1.0)"
        let headerPattern = #"^([+\-]?)\s+([\w\.\-]+)\((.*?)\)\s*$"#
        let headerRegex = try! NSRegularExpression(pattern: headerPattern)

        var blockStarts: [(index: Int, flag: String, bundleID: String, version: String)] = []

        for (i, line) in lines.enumerated() {
            let range = NSRange(line.startIndex..., in: line)
            if let match = headerRegex.firstMatch(in: line, range: range) {
                let flag = String(line[Range(match.range(at: 1), in: line)!])
                let bundleID = String(line[Range(match.range(at: 2), in: line)!])
                var version = String(line[Range(match.range(at: 3), in: line)!])
                // Clean up "(null)" version
                if version == "(null)" || version == "null" { version = "" }
                blockStarts.append((i, flag, bundleID, version))
            }
        }

        for (blockIdx, block) in blockStarts.enumerated() {
            let startLine = block.index + 1
            let endLine = blockIdx + 1 < blockStarts.count ? blockStarts[blockIdx + 1].index : lines.count

            var fields: [String: String] = [:]
            for lineIdx in startLine..<endLine {
                let line = lines[lineIdx]
                if let eqRange = line.range(of: " = ") {
                    let key = line[line.startIndex..<eqRange.lowerBound].trimmingCharacters(in: .whitespaces)
                    let value = String(line[eqRange.upperBound...]).trimmingCharacters(in: .whitespaces)
                    if !key.isEmpty { fields[key] = value }
                }
            }

            let sdkValue = fields["SDK"] ?? ""
            // + or no flag = enabled, - = explicitly disabled
            let isEnabled = block.flag != "-"

            let ext = SystemExtension(
                id: block.bundleID,
                bundleIdentifier: block.bundleID,
                version: block.version,
                path: fields["Path"] ?? "",
                sdk: sdkValue,
                displayName: fields["Display Name"] ?? "",
                shortName: fields["Short Name"] ?? "",
                parentBundlePath: fields["Parent Bundle"] ?? "",
                parentName: fields["Parent Name"] ?? "",
                platform: fields["Platform"] ?? "",
                category: ExtensionCategory.from(sdk: sdkValue),
                isEnabled: isEnabled,
                source: .pluginKit
            )
            extensions.append(ext)
        }

        return extensions
    }

    // MARK: - System Extensions

    func scanSystemExtensions() -> [SystemExtension] {
        let output = ShellCommand.run("/usr/bin/systemextensionsctl", arguments: ["list"])
        return parseSystemExtensionsOutput(output)
    }

    func parseSystemExtensionsOutput(_ output: String) -> [SystemExtension] {
        var extensions: [SystemExtension] = []
        let lines = output.components(separatedBy: "\n")

        let sectionPattern = #"^---\s+com\.apple\.system_extension\.(\w+)"#
        let sectionRegex = try! NSRegularExpression(pattern: sectionPattern)

        let bundlePattern = #"^(\S+)\s+\(([^)]+)\)$"#
        let bundleRegex = try! NSRegularExpression(pattern: bundlePattern)

        var currentType = ""

        for line in lines {
            let lineRange = NSRange(line.startIndex..., in: line)

            if let sectionMatch = sectionRegex.firstMatch(in: line, range: lineRange) {
                currentType = String(line[Range(sectionMatch.range(at: 1), in: line)!])
                continue
            }

            // Tab-delimited: enabled\tactive\tteamID\t"bundleID (version)"\tname\t[state]
            let columns = line.components(separatedBy: "\t")
            guard columns.count >= 4 else { continue }

            var bundleID = ""
            var version = ""
            var name = ""
            var state = ""
            var enabledCol = ""

            if columns.count >= 6 {
                enabledCol = columns[0].trimmingCharacters(in: .whitespaces)
                // columns[1] is "active" - loaded in memory, NOT user-enabled
                let bundleCol = columns[3].trimmingCharacters(in: .whitespaces)
                name = columns[4].trimmingCharacters(in: .whitespaces)
                state = columns[5].trimmingCharacters(in: .whitespaces)
                    .replacingOccurrences(of: "[", with: "")
                    .replacingOccurrences(of: "]", with: "")

                let bundleRange = NSRange(bundleCol.startIndex..., in: bundleCol)
                if let m = bundleRegex.firstMatch(in: bundleCol, range: bundleRange) {
                    bundleID = String(bundleCol[Range(m.range(at: 1), in: bundleCol)!])
                    version = String(bundleCol[Range(m.range(at: 2), in: bundleCol)!])
                }
            }

            guard !bundleID.isEmpty else { continue }

            // Only use the "enabled" column (* = enabled) or check for "enabled" in state
            // Do NOT use the "active" column - that just means loaded in memory
            let isEnabled = enabledCol == "*" || state.hasSuffix("enabled")
            let category = ExtensionCategory.fromSystemExtension(type: currentType)

            let ext = SystemExtension(
                id: bundleID,
                bundleIdentifier: bundleID,
                version: version,
                path: "",
                sdk: "com.apple.system_extension.\(currentType)",
                displayName: name,
                shortName: name,
                parentBundlePath: "",
                parentName: "",
                platform: "macOS",
                category: category,
                isEnabled: isEnabled,
                source: .systemExtension
            )
            extensions.append(ext)
        }

        return extensions
    }
}
