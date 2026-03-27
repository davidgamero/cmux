import AppKit
import Foundation

enum LinkHintsEditor: String, CaseIterable, Identifiable {
    case systemDefault
    case vscode
    case cursor
    case zed
    case neovim
    case sublimeText
    case custom

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .systemDefault:
            return String(localized: "linkHints.editor.systemDefault", defaultValue: "System Default")
        case .vscode:
            return "Visual Studio Code"
        case .cursor:
            return "Cursor"
        case .zed:
            return "Zed"
        case .neovim:
            var args = [String]()
            if let line { args.append("+\(line)") }
            args.append(file)
            return ("nvim", args)
        case .sublimeText:
            return "Sublime Text"
        case .custom:
            return String(localized: "linkHints.editor.custom", defaultValue: "Custom Command")
        }
    }

    func openCommand(file: String, line: Int?, col: Int?) -> (executable: String, arguments: [String])? {
        switch self {
        case .systemDefault:
            return nil
        case .vscode:
            var target = file
            if let line { target += ":\(line)" }
            if let line, let col { target = "\(file):\(line):\(col)" }
            return ("code", ["--goto", target])
        case .cursor:
            var target = file
            if let line { target += ":\(line)" }
            if let line, let col { target = "\(file):\(line):\(col)" }
            return ("cursor", ["--goto", target])
        case .zed:
            var target = file
            if let line { target += ":\(line)" }
            if let line, let col { target = "\(file):\(line):\(col)" }
            return ("zed", [target])
        case .neovim:
            return nil  // Handled specially — opens in a new cmux tab
        case .sublimeText:
            var target = file
            if let line { target += ":\(line)" }
            if let line, let col { target = "\(file):\(line):\(col)" }
            return ("subl", [target])
        case .custom:
            return nil
        }
    }
}

enum LinkHintsEditorSettings {
    static let editorKey = "linkHintsEditor"
    static let customCommandKey = "linkHintsEditorCustomCommand"
    static let defaultEditor: LinkHintsEditor = .systemDefault
    static let defaultCustomCommand = ""

    static func currentEditor(defaults: UserDefaults = .standard) -> LinkHintsEditor {
        guard let raw = defaults.string(forKey: editorKey),
              let editor = LinkHintsEditor(rawValue: raw) else {
            return defaultEditor
        }
        return editor
    }

    static func currentCustomCommand(defaults: UserDefaults = .standard) -> String {
        defaults.string(forKey: customCommandKey) ?? defaultCustomCommand
    }

    static func openFile(path: String, line: Int?, col: Int?) {
        let editor = currentEditor()

        if editor == .custom {
            let template = currentCustomCommand()
            guard !template.isEmpty else { return }
            let expanded = template
                .replacingOccurrences(of: "{file}", with: path)
                .replacingOccurrences(of: "{line}", with: line.map(String.init) ?? "1")
                .replacingOccurrences(of: "{col}", with: col.map(String.init) ?? "1")
            let parts = expanded.components(separatedBy: " ")
            guard let executable = parts.first else { return }
            let args = Array(parts.dropFirst())
            launchProcess(executable: executable, arguments: args)
            return
        }

        if let command = editor.openCommand(file: path, line: line, col: col) {
            launchProcess(executable: command.executable, arguments: command.arguments)
            return
        }

        let fileURL = URL(fileURLWithPath: path)
        NSWorkspace.shared.open(fileURL)
    }

    private static func launchProcess(executable: String, arguments: [String]) {
        let task = Process()
        if executable.hasPrefix("/") {
            task.executableURL = URL(fileURLWithPath: executable)
            task.arguments = arguments
        } else {
            task.executableURL = URL(fileURLWithPath: "/usr/bin/env")
            task.arguments = [executable] + arguments
        }
        try? task.run()
    }
}
