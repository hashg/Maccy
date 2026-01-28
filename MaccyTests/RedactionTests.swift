import XCTest
import Defaults
import Darwin
@testable import Maccy

class RedactionFilterTests: XCTestCase {
  override func tearDown() {
    super.tearDown()
    // Reset to default filters with system filters
    Defaults[.redactionFilters] = RedactionFilter.defaultFiltersWithSystem()
    Defaults[.enableRedaction] = false
  }

  func testDefaultFiltersExist() {
    let defaults = RedactionFilter.defaultFilters
    XCTAssertEqual(defaults.count, 6)
    
    let ids = defaults.map { $0.id }
    XCTAssertTrue(ids.contains("email"))
    XCTAssertTrue(ids.contains("phone_us"))
    XCTAssertTrue(ids.contains("ssn"))
    XCTAssertTrue(ids.contains("credit_card"))
    XCTAssertTrue(ids.contains("ip_address"))
    XCTAssertTrue(ids.contains("dob"))
  }

  func testEmailFilterPattern() {
    let emailFilter = RedactionFilter.email
    XCTAssertEqual(emailFilter.replacement, "[EMAIL]")
    XCTAssertEqual(emailFilter.description, "Email addresses")
  }

  func testPhoneFilterPattern() {
    let phoneFilter = RedactionFilter.phoneUS
    XCTAssertEqual(phoneFilter.replacement, "[PHONE]")
    XCTAssertEqual(phoneFilter.description, "US phone numbers")
  }

  func testSSNFilterPattern() {
    let ssnFilter = RedactionFilter.ssn
    XCTAssertEqual(ssnFilter.replacement, "[SSN]")
    XCTAssertEqual(ssnFilter.description, "Social Security Numbers")
  }

  func testCreditCardFilterPattern() {
    let ccFilter = RedactionFilter.creditCard
    XCTAssertEqual(ccFilter.replacement, "[CARD]")
    XCTAssertEqual(ccFilter.description, "Credit card numbers")
  }

  func testIPAddressFilterPattern() {
    let ipFilter = RedactionFilter.ipAddress
    XCTAssertEqual(ipFilter.replacement, "[IP]")
    XCTAssertEqual(ipFilter.description, "IP addresses")
  }

  func testDOBFilterPattern() {
    let dobFilter = RedactionFilter.dob
    XCTAssertEqual(dobFilter.replacement, "[DOB]")
    XCTAssertEqual(dobFilter.description, "Dates of birth")
  }

  func testFilterCodable() {
    let filter = RedactionFilter(
      id: "test",
      enabled: true,
      pattern: "\\d{3}",
      replacement: "[NUM]",
      description: "Test filter",
      isCustom: true
    )

    let encoder = JSONEncoder()
    let data = try! encoder.encode(filter)

    let decoder = JSONDecoder()
    let decodedFilter = try! decoder.decode(RedactionFilter.self, from: data)

    XCTAssertEqual(decodedFilter.id, filter.id)
    XCTAssertEqual(decodedFilter.enabled, filter.enabled)
    XCTAssertEqual(decodedFilter.pattern, filter.pattern)
    XCTAssertEqual(decodedFilter.replacement, filter.replacement)
    XCTAssertEqual(decodedFilter.description, filter.description)
    XCTAssertEqual(decodedFilter.isCustom, filter.isCustom)
  }

  func testFilterEquality() {
    let filter1 = RedactionFilter(
      id: "test",
      enabled: true,
      pattern: "test",
      replacement: "[TEST]",
      description: "Test"
    )
    let filter2 = RedactionFilter(
      id: "test",
      enabled: true,
      pattern: "test",
      replacement: "[TEST]",
      description: "Test"
    )

    XCTAssertEqual(filter1, filter2)
  }

  func testCustomFilterCreation() {
    let customFilter = RedactionFilter(
      id: UUID().uuidString,
      enabled: true,
      pattern: "\\d{4}-\\d{4}",
      replacement: "[CUSTOM]",
      description: "Custom Pattern",
      isCustom: true
    )

    XCTAssertTrue(customFilter.isCustom)
    XCTAssertEqual(customFilter.replacement, "[CUSTOM]")
  }

  func testDynamicUsernameFilter() {
    let usernameFilter = RedactionFilter.username
    XCTAssertEqual(usernameFilter.id, "username")
    XCTAssertEqual(usernameFilter.replacement, "[USERNAME]")
    XCTAssertTrue(usernameFilter.isSystem)
    XCTAssertTrue(usernameFilter.description.contains("Login name"))
    XCTAssertFalse(usernameFilter.pattern.isEmpty)
  }

  func testDynamicHomeDirectoryFilter() {
    let homeFilter = RedactionFilter.homeDirectory
    XCTAssertEqual(homeFilter.id, "home_directory")
    XCTAssertEqual(homeFilter.replacement, "[HOME]")
    XCTAssertTrue(homeFilter.isSystem)
    XCTAssertTrue(homeFilter.description.contains("Home directory"))
    XCTAssertFalse(homeFilter.pattern.isEmpty)
  }

  func testDynamicHostnameFilter() {
    let hostnameFilter = RedactionFilter.hostname
    XCTAssertEqual(hostnameFilter.id, "hostname")
    XCTAssertEqual(hostnameFilter.replacement, "[HOSTNAME]")
    XCTAssertTrue(hostnameFilter.isSystem)
    XCTAssertTrue(hostnameFilter.description.contains("Hostname"))
    XCTAssertFalse(hostnameFilter.pattern.isEmpty)
  }

  func testDefaultFiltersWithSystem() {
    let allFilters = RedactionFilter.defaultFiltersWithSystem()
    XCTAssertEqual(allFilters.count, 9)

    let ids = allFilters.map { $0.id }
    XCTAssertTrue(ids.contains("email"))
    XCTAssertTrue(ids.contains("phone_us"))
    XCTAssertTrue(ids.contains("ssn"))
    XCTAssertTrue(ids.contains("credit_card"))
    XCTAssertTrue(ids.contains("ip_address"))
    XCTAssertTrue(ids.contains("dob"))
    XCTAssertTrue(ids.contains("username"))
    XCTAssertTrue(ids.contains("home_directory"))
    XCTAssertTrue(ids.contains("hostname"))

    let systemFilters = allFilters.filter { $0.isSystem }
    XCTAssertEqual(systemFilters.count, 3)
  }
}

class TextRedactorTests: XCTestCase {
  override func tearDown() {
    super.tearDown()
    Defaults[.enableRedaction] = false
    Defaults[.redactionFilters] = RedactionFilter.defaultFiltersWithSystem()
  }

  func testRedactEmail() {
    Defaults[.enableRedaction] = true
    let redactor = TextRedactor.shared

    let text = "Contact me at john@example.com for details"
    let redacted = redactor.redact(text)

    XCTAssertTrue(redacted.contains("[EMAIL]"))
    XCTAssertFalse(redacted.contains("john@example.com"))
  }

  func testRedactPhoneNumber() {
    Defaults[.enableRedaction] = true
    let redactor = TextRedactor.shared

    let text = "Call me at 555-123-4567"
    let redacted = redactor.redact(text)

    XCTAssertTrue(redacted.contains("[PHONE]"))
    XCTAssertFalse(redacted.contains("555-123-4567"))
  }

  func testRedactSSN() {
    Defaults[.enableRedaction] = true
    let redactor = TextRedactor.shared

    let text = "My SSN is 123-45-6789"
    let redacted = redactor.redact(text)

    XCTAssertTrue(redacted.contains("[SSN]"))
    XCTAssertFalse(redacted.contains("123-45-6789"))
  }

  func testRedactIPAddress() {
    Defaults[.enableRedaction] = true
    let redactor = TextRedactor.shared

    let text = "Server IP is 192.168.1.1"
    let redacted = redactor.redact(text)

    XCTAssertTrue(redacted.contains("[IP]"))
    XCTAssertFalse(redacted.contains("192.168.1.1"))
  }

  func testRedactCreditCard() {
    Defaults[.enableRedaction] = true
    let redactor = TextRedactor.shared

    let text = "Card: 1234-5678-9012-3456"
    let redacted = redactor.redact(text)

    XCTAssertTrue(redacted.contains("[CARD]"))
    XCTAssertFalse(redacted.contains("1234-5678-9012-3456"))
  }

  func testRedactDateOfBirth() {
    Defaults[.enableRedaction] = true
    let redactor = TextRedactor.shared

    let text = "Born on 12/25/1990"
    let redacted = redactor.redact(text)

    XCTAssertTrue(redacted.contains("[DOB]"))
    XCTAssertFalse(redacted.contains("12/25/1990"))
  }

  func testMultipleMatches() {
    Defaults[.enableRedaction] = true
    let redactor = TextRedactor.shared

    let text = "Email john@test.com and jane@test.com"
    let redacted = redactor.redact(text)

    let emailCount = redacted.components(separatedBy: "[EMAIL]").count - 1
    XCTAssertEqual(emailCount, 2)
  }

  func testDisabledFilter() {
    Defaults[.enableRedaction] = true
    var filters = Defaults[.redactionFilters]
    filters[0].enabled = false
    Defaults[.redactionFilters] = filters

    let redactor = TextRedactor.shared
    let text = "Contact john@example.com"
    let redacted = redactor.redact(text)

    XCTAssertFalse(redacted.contains("[EMAIL]"))
    XCTAssertTrue(redacted.contains("john@example.com"))
  }

  func testRedactIfEnabledWhenDisabled() {
    Defaults[.enableRedaction] = false
    let redactor = TextRedactor.shared

    let text = "Email john@example.com"
    let redacted = redactor.redactIfEnabled(text)

    XCTAssertEqual(text, redacted)
  }

  func testRedactIfEnabledWhenEnabled() {
    Defaults[.enableRedaction] = true
    let redactor = TextRedactor.shared

    let text = "Email john@example.com"
    let redacted = redactor.redactIfEnabled(text)

    XCTAssertTrue(redacted.contains("[EMAIL]"))
  }

  func testCustomFilter() {
    Defaults[.enableRedaction] = true
    let customFilter = RedactionFilter(
      id: "custom_test",
      enabled: true,
      pattern: "\\b(SECRET|CONFIDENTIAL)\\b",
      replacement: "[REDACTED]",
      description: "Secret words",
      isCustom: true
    )

    var filters = Defaults[.redactionFilters]
    filters.append(customFilter)
    Defaults[.redactionFilters] = filters

    let redactor = TextRedactor.shared
    let text = "This is SECRET information"
    let redacted = redactor.redact(text)

    XCTAssertTrue(redacted.contains("[REDACTED]"))
    XCTAssertFalse(redacted.contains("SECRET"))
  }

  func testInvalidRegexPattern() {
    Defaults[.enableRedaction] = true
    let invalidFilter = RedactionFilter(
      id: "invalid",
      enabled: true,
      pattern: "[invalid(regex",
      replacement: "[X]",
      description: "Invalid pattern"
    )

    var filters = Defaults[.redactionFilters]
    filters.append(invalidFilter)
    Defaults[.redactionFilters] = filters

    let redactor = TextRedactor.shared
    let text = "Some text"
    // Should not crash and should return original text
    let redacted = redactor.redact(text)
    XCTAssertEqual(text, redacted)
  }

  func testPreservesNonMatchingText() {
    Defaults[.enableRedaction] = true
    let redactor = TextRedactor.shared

    let text = "This is safe text without sensitive data"
    let redacted = redactor.redact(text)

    XCTAssertEqual(text, redacted)
  }

  func testEmptyText() {
    Defaults[.enableRedaction] = true
    let redactor = TextRedactor.shared

    let text = ""
    let redacted = redactor.redact(text)

    XCTAssertEqual(text, redacted)
  }

  func testMultipleFilterTypes() {
    Defaults[.enableRedaction] = true
    let redactor = TextRedactor.shared

    let text = "Email: john@example.com, Phone: 555-1234, SSN: 123-45-6789, IP: 10.0.0.1"
    let redacted = redactor.redact(text)

    XCTAssertTrue(redacted.contains("[EMAIL]"))
    XCTAssertTrue(redacted.contains("[PHONE]"))
    XCTAssertTrue(redacted.contains("[SSN]"))
    XCTAssertTrue(redacted.contains("[IP]"))

    XCTAssertFalse(redacted.contains("john@example.com"))
    XCTAssertFalse(redacted.contains("555-1234"))
    XCTAssertFalse(redacted.contains("123-45-6789"))
    XCTAssertFalse(redacted.contains("10.0.0.1"))
  }

  func testRedactUsername() {
    Defaults[.enableRedaction] = true
    let redactor = TextRedactor.shared
    let usernameFilter = RedactionFilter.username

    // Add username filter if not already there
    var filters = Defaults[.redactionFilters]
    if !filters.contains(where: { $0.id == "username" }) {
      filters.append(usernameFilter)
      Defaults[.redactionFilters] = filters
    }

    let currentUser = NSUserName()
    let text = "User \(currentUser) logged in"
    let redacted = redactor.redact(text)

    XCTAssertTrue(redacted.contains("[USERNAME]"))
    XCTAssertFalse(redacted.contains(currentUser))
  }

  func testRedactHomeDirectory() {
    Defaults[.enableRedaction] = true
    let redactor = TextRedactor.shared
    let homeFilter = RedactionFilter.homeDirectory

    // Add home filter if not already there
    var filters = Defaults[.redactionFilters]
    if !filters.contains(where: { $0.id == "home_directory" }) {
      filters.append(homeFilter)
      Defaults[.redactionFilters] = filters
    }

    let homeDir = NSHomeDirectory()
    let text = "File stored at \(homeDir)/Documents/file.txt"
    let redacted = redactor.redact(text)

    XCTAssertTrue(redacted.contains("[HOME]"))
    XCTAssertFalse(redacted.contains(homeDir))
  }

  func testRedactHostname() {
    Defaults[.enableRedaction] = true
    let redactor = TextRedactor.shared
    let hostnameFilter = RedactionFilter.hostname

    // Add hostname filter if not already there
    var filters = Defaults[.redactionFilters]
    if !filters.contains(where: { $0.id == "hostname" }) {
      filters.append(hostnameFilter)
      Defaults[.redactionFilters] = filters
    }

    let hostname = Host.current().localizedName ?? ProcessInfo.processInfo.hostName
    let text = "Connected to \(hostname)"
    let redacted = redactor.redact(text)

    XCTAssertTrue(redacted.contains("[HOSTNAME]"))
    XCTAssertFalse(redacted.contains(hostname))
  }
}

