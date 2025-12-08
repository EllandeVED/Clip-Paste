import Foundation

struct FilenameTemplateContext {
    let date: Date
    let clipboardText: String?
    let clipboardName: String?
    let counter: Int
}

enum FilenameTemplate {
    static func expand(
        template: String,
        context: FilenameTemplateContext
    ) -> String {
        var result = template

        let formatter = DateFormatter()
        formatter.locale = Locale.current

        formatter.dateFormat = "yyyy-MM-dd"
        let dateString = formatter.string(from: context.date)

        formatter.dateFormat = "HH.mm.ss"
        let timeString = formatter.string(from: context.date)

        formatter.dateFormat = "yyyy-MM-dd HH.mm.ss"
        let dateTimeString = formatter.string(from: context.date)

        formatter.dateFormat = "EEEE"
        let weekdayString = formatter.string(from: context.date)

        let counterString = String(context.counter)

        let firstWords = makeFirstWords(from: context.clipboardText ?? "")

        var replacements: [String: String] = [
            "{date}": dateString,
            "{time}": timeString,
            "{datetime}": dateTimeString,
            "{weekday}": weekdayString,
            "{counter}": counterString,
            "{firstWords}": firstWords
        ]

        if let name = context.clipboardName, !name.isEmpty {
            let sanitizedName = sanitizeFilename(name)
            replacements["{name}"] = sanitizedName
        } else {
            replacements["{name}"] = ""
        }

        for (key, value) in replacements {
            result = result.replacingOccurrences(of: key, with: value)
        }

        result = sanitizeFilename(result)

        if result.isEmpty {
            result = "Untitled"
        }

        return result
    }

    private static func makeFirstWords(from text: String) -> String {
        if text.isEmpty {
            return ""
        }

        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            return ""
        }

        let words = trimmed.components(separatedBy: .whitespacesAndNewlines)
        let firstFive = words.prefix(5)
        let joined = firstFive.joined(separator: " ")

        let maxLength = 40
        let shortened: String
        if joined.count > maxLength {
            let index = joined.index(joined.startIndex, offsetBy: maxLength)
            shortened = String(joined[..<index])
        } else {
            shortened = joined
        }

        return sanitizeFilename(shortened)
    }

    private static func sanitizeFilename(_ name: String) -> String {
        let invalidCharacters = CharacterSet(charactersIn: "/:\\?%*|\"<>")
        let components = name.components(separatedBy: invalidCharacters)
        let sanitized = components.joined(separator: "-")

        let trimmed = sanitized.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed
    }
}
