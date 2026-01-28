import Foundation
import Defaults

class TextRedactor {
  static let shared = TextRedactor()

  func redact(_ text: String) -> String {
    var result = text
    let filters = Defaults[.redactionFilters].filter { $0.enabled }

    for filter in filters {
      do {
        let regex = try NSRegularExpression(pattern: filter.pattern, options: [])
        let range = NSRange(result.startIndex..., in: result)
        result = regex.stringByReplacingMatches(in: result, options: [], range: range, withTemplate: filter.replacement)
      } catch {
        // If regex is invalid, skip this filter
        continue
      }
    }

    return result
  }

  func redactIfEnabled(_ text: String) -> String {
    guard Defaults[.enableRedaction] else { return text }
    return redact(text)
  }
}
