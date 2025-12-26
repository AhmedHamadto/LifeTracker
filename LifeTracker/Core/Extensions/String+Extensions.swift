import Foundation

extension String {
    /// Trims whitespace and newlines
    var trimmed: String {
        trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// Checks if string is empty after trimming
    var isBlank: Bool {
        trimmed.isEmpty
    }

    /// Returns nil if string is blank, otherwise returns trimmed string
    var nilIfBlank: String? {
        isBlank ? nil : trimmed
    }

    /// Capitalizes the first letter only
    var capitalizedFirst: String {
        prefix(1).capitalized + dropFirst()
    }

    /// Converts to a valid filename
    var asFilename: String {
        let invalidCharacters = CharacterSet(charactersIn: ":/\\?%*|\"<>")
        return components(separatedBy: invalidCharacters).joined(separator: "_")
    }

    /// Truncates string to specified length with ellipsis
    func truncated(to length: Int, trailing: String = "…") -> String {
        if count <= length {
            return self
        }
        return String(prefix(length)) + trailing
    }

    /// Checks if string contains another string (case insensitive)
    func containsIgnoringCase(_ string: String) -> Bool {
        range(of: string, options: .caseInsensitive) != nil
    }

    /// Returns initials from a name
    var initials: String {
        let components = split(separator: " ")
        let initials = components.prefix(2).compactMap { $0.first }
        return String(initials).uppercased()
    }

    /// Validates email format
    var isValidEmail: Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        return NSPredicate(format: "SELF MATCHES %@", emailRegex).evaluate(with: self)
    }

    /// Extracts numbers from string
    var extractedNumbers: String {
        components(separatedBy: CharacterSet.decimalDigits.inverted).joined()
    }

    /// Converts string to URL if valid
    var asURL: URL? {
        URL(string: self)
    }
}

// MARK: - Localization

extension String {
    var localized: String {
        NSLocalizedString(self, comment: "")
    }

    func localized(with arguments: CVarArg...) -> String {
        String(format: localized, arguments: arguments)
    }
}

// MARK: - Optional String

extension Optional where Wrapped == String {
    var orEmpty: String {
        self ?? ""
    }

    var isNilOrEmpty: Bool {
        self?.isEmpty ?? true
    }

    var isNilOrBlank: Bool {
        self?.isBlank ?? true
    }
}
