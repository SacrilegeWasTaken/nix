import ApplicationServices
import Foundation

enum ScreenToolError: Error, CustomStringConvertible {
    case usage
    case invalidCoordinates
    case eventCreationFailed
    case screenshotFailed

    var description: String {
        switch self {
        case .usage:
            return "Usage: screen-tool screenshot [path] | click <x> <y>"
        case .invalidCoordinates:
            return "Coordinates must be integers inside the main display."
        case .eventCreationFailed:
            return "Could not create a mouse event. Check Accessibility permission."
        case .screenshotFailed:
            return "Could not capture the screen. Check Screen Recording permission."
        }
    }
}

func run(_ arguments: [String]) throws {
    guard let command = arguments.first else {
        throw ScreenToolError.usage
    }

    switch command {
    case "screenshot":
        guard arguments.count <= 2 else { throw ScreenToolError.usage }
        let path = arguments.count == 2
            ? arguments[1]
            : "/tmp/screen-tool-\(UUID().uuidString).png"
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/sbin/screencapture")
        process.arguments = ["-x", path]
        try process.run()
        process.waitUntilExit()
        guard process.terminationStatus == 0 else {
            throw ScreenToolError.screenshotFailed
        }
        print(path)
    case "click":
        guard arguments.count == 3,
              let x = Double(arguments[1]),
              let y = Double(arguments[2]) else {
            throw ScreenToolError.usage
        }
        let bounds = CGDisplayBounds(CGMainDisplayID())
        let point = CGPoint(x: x, y: y)
        guard bounds.contains(point) else {
            throw ScreenToolError.invalidCoordinates
        }
        guard let down = CGEvent(
            mouseEventSource: nil,
            mouseType: .leftMouseDown,
            mouseCursorPosition: point,
            mouseButton: .left
        ), let up = CGEvent(
            mouseEventSource: nil,
            mouseType: .leftMouseUp,
            mouseCursorPosition: point,
            mouseButton: .left
        ) else {
            throw ScreenToolError.eventCreationFailed
        }
        down.post(tap: .cghidEventTap)
        up.post(tap: .cghidEventTap)
        print("Clicked at (\(Int(x)), \(Int(y))).")
    default:
        throw ScreenToolError.usage
    }
}

do {
    try run(Array(CommandLine.arguments.dropFirst()))
} catch {
    fputs("screen-tool: \(error)\n", stderr)
    exit(EXIT_FAILURE)
}
