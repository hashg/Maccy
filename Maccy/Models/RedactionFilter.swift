import Foundation
import Darwin

struct RedactionFilter: Codable, Identifiable, Equatable {
  var id: String
  var enabled: Bool
  var pattern: String
  var replacement: String
  var description: String
  var isCustom: Bool = false
  var isSystem: Bool = false

  enum CodingKeys: String, CodingKey {
    case id
    case enabled
    case pattern
    case replacement
    case description
    case isCustom
    case isSystem
  }

  init(
    id: String,
    enabled: Bool,
    pattern: String,
    replacement: String,
    description: String,
    isCustom: Bool = false,
    isSystem: Bool = false
  ) {
    self.id = id
    self.enabled = enabled
    self.pattern = pattern
    self.replacement = replacement
    self.description = description
    self.isCustom = isCustom
    self.isSystem = isSystem
  }

  // Predefined filters
  static let email = RedactionFilter(
    id: "email",
    enabled: true,
    pattern: "[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}",
    replacement: "[EMAIL]",
    description: "Email addresses"
  )

  static let phoneUS = RedactionFilter(
    id: "phone_us",
    enabled: true,
    pattern: "\\b(\\+1[-\\.\\s]?)?\\(?[0-9]{3}\\)?[-\\.\\s]?[0-9]{3}[-\\.\\s]?[0-9]{4}\\b",
    replacement: "[PHONE]",
    description: "US phone numbers"
  )

  static let ssn = RedactionFilter(
    id: "ssn",
    enabled: true,
    pattern: "\\b[0-9]{3}-[0-9]{2}-[0-9]{4}\\b",
    replacement: "[SSN]",
    description: "Social Security Numbers"
  )

  static let creditCard = RedactionFilter(
    id: "credit_card",
    enabled: true,
    pattern: "\\b[0-9]{4}[-\\s]?[0-9]{4}[-\\s]?[0-9]{4}[-\\s]?[0-9]{4}\\b",
    replacement: "[CARD]",
    description: "Credit card numbers"
  )

  static let ipAddress = RedactionFilter(
    id: "ip_address",
    enabled: true,
    pattern: "\\b\\d{1,3}\\.\\d{1,3}\\.\\d{1,3}\\.\\d{1,3}\\b",
    replacement: "[IP]",
    description: "IP addresses"
  )

  static let dob = RedactionFilter(
    id: "dob",
    enabled: true,
    pattern: "\\b(0?[1-9]|1[0-2])[-/](0?[1-9]|[12][0-9]|3[01])[-/](19|20)\\d{2}\\b",
    replacement: "[DOB]",
    description: "Dates of birth"
  )

  // Dynamic system-based filters
  static var username: RedactionFilter {
    let userName = NSUserName()
    return RedactionFilter(
      id: "username",
      enabled: true,
      pattern: "\\b\(NSRegularExpression.escapedPattern(for: userName))\\b",
      replacement: "[USERNAME]",
      description: "Login name (\(userName))",
      isSystem: true
    )
  }

  static var homeDirectory: RedactionFilter {
    let homeDir = NSHomeDirectory()
    return RedactionFilter(
      id: "home_directory",
      enabled: true,
      pattern: NSRegularExpression.escapedPattern(for: homeDir),
      replacement: "[HOME]",
      description: "Home directory (\(homeDir))",
      isSystem: true
    )
  }

  static var hostname: RedactionFilter {
    let hostname = Host.current().localizedName ?? ProcessInfo.processInfo.hostName
    let shortHostname = hostname.components(separatedBy: ".").first ?? hostname
    let hostnameEscaped = NSRegularExpression.escapedPattern(for: hostname)
    let shortHostnameEscaped = NSRegularExpression.escapedPattern(for: shortHostname)
    return RedactionFilter(
      id: "hostname",
      enabled: true,
      pattern: "\\b(\(hostnameEscaped)|\(shortHostnameEscaped))\\b",
      replacement: "[HOSTNAME]",
      description: "Hostname (\(shortHostname))",
      isSystem: true
    )
  }

  static let defaultFilters: [RedactionFilter] = [
    .email,
    .phoneUS,
    .ssn,
    .creditCard,
    .ipAddress,
    .dob
  ]

  static func defaultFiltersWithSystem() -> [RedactionFilter] {
    return defaultFilters + [.username, .homeDirectory, .hostname]
  }
}
