import SwiftUI
import Defaults

struct RedactionSettingsPane: View {
  @Default(.enableRedaction) var enableRedaction
  @Default(.redactionFilters) var redactionFilters
  @State private var showAddFilter = false
  @State private var newFilterPattern = ""
  @State private var newFilterReplacement = ""
  @State private var newFilterDescription = ""
  @State private var filterToDelete: RedactionFilter?

  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      Defaults.Toggle(key: .enableRedaction) {
        Text("EnableRedaction", tableName: "RedactionSettings")
      }
      Text("EnableRedactionDescription", tableName: "RedactionSettings")
        .fixedSize(horizontal: false, vertical: true)
        .foregroundStyle(.gray)
        .controlSize(.small)

      Divider()

      Text("Filters", tableName: "RedactionSettings")
        .font(.headline)

      if redactionFilters.isEmpty {
        Text("NoFiltersConfigured", tableName: "RedactionSettings")
          .foregroundStyle(.gray)
          .controlSize(.small)
      } else {
        VStack(spacing: 8) {
          ForEach($redactionFilters) { $filter in
            HStack(spacing: 8) {
            HStack(spacing: 8) {
              Toggle("", isOn: $filter.enabled)
                .labelsHidden()

              VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 4) {
                  Text(filter.description)
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundStyle(.gray)

                  if filter.isSystem {
                    Text("System", tableName: "RedactionSettings")
                      .font(.system(size: 9))
                      .foregroundStyle(.white)
                      .padding(.horizontal, 4)
                      .padding(.vertical, 2)
                      .background(Color.blue)
                      .cornerRadius(3)
                  }
                }

                Text(filter.pattern)
                  .font(.system(size: 9, design: .monospaced))
                  .foregroundStyle(.gray)
                  .lineLimit(1)
              }
              .frame(maxWidth: .infinity, alignment: .leading)

              if filter.isCustom {
                Button(action: { filterToDelete = filter }) {
                  Image(systemName: "trash")
                    .foregroundStyle(.red)
                }
                .buttonStyle(.plain)
                .help(Text("DeleteFilter", tableName: "RedactionSettings"))
              }
            }
            .padding(8)
            .background(Color.gray.opacity(0.1))
            .cornerRadius(4)
          }
        }
      }

      HStack {
        Button(action: { showAddFilter = true }) {
          HStack {
            Image(systemName: "plus")
            Text("AddCustomFilter", tableName: "RedactionSettings")
          }
        }

        Button(action: resetToDefaults) {
          Text("ResetToDefaults", tableName: "RedactionSettings")
        }

        Spacer()
      }

      if showAddFilter {
        VStack(alignment: .leading, spacing: 8) {
          Divider()

          Text("AddCustomFilter", tableName: "RedactionSettings")
            .font(.headline)

          VStack(alignment: .leading, spacing: 4) {
            Text("FilterDescription", tableName: "RedactionSettings")
              .font(.caption)
              .foregroundStyle(.gray)
            TextField("DescriptionPlaceholder", text: $newFilterDescription)
              .textFieldStyle(.roundedBorder)
          }

          VStack(alignment: .leading, spacing: 4) {
            Text("RegexPattern", tableName: "RedactionSettings")
              .font(.caption)
              .foregroundStyle(.gray)
            TextField("PatternPlaceholder", text: $newFilterPattern)
              .textFieldStyle(.roundedBorder)
          }

          VStack(alignment: .leading, spacing: 4) {
            Text("ReplacementText", tableName: "RedactionSettings")
              .font(.caption)
              .foregroundStyle(.gray)
            TextField("ReplacementPlaceholder", text: $newFilterReplacement)
              .textFieldStyle(.roundedBorder)
          }

          HStack(spacing: 8) {
            Button(action: saveCustomFilter) {
              Text("Save", tableName: "RedactionSettings")
            }
            .disabled(!isValidFilter())

            Button(action: { showAddFilter = false }) {
              Text("Cancel", tableName: "RedactionSettings")
            }

            Spacer()
          }
        }
        .padding(8)
        .background(Color.gray.opacity(0.05))
        .cornerRadius(4)
      }
    }
    .frame(minWidth: 350, maxWidth: 450)
    .padding()
    .alert(
      "Delete Filter?",
      isPresented: .constant(filterToDelete != nil),
      actions: {
        Button("Delete", role: .destructive) {
          if let filterToDelete {
            redactionFilters.removeAll { $0.id == filterToDelete.id }
          }
        }
        Button("Cancel", role: .cancel) {}
      },
      message: {
        Text("This action cannot be undone.", tableName: "RedactionSettings")
      }
    )
  }

  private func isValidFilter() -> Bool {
    !newFilterPattern.trimmingCharacters(in: .whitespaces).isEmpty &&
    !newFilterReplacement.trimmingCharacters(in: .whitespaces).isEmpty &&
    !newFilterDescription.trimmingCharacters(in: .whitespaces).isEmpty &&
    isValidRegex(newFilterPattern)
  }

  private func isValidRegex(_ pattern: String) -> Bool {
    do {
      _ = try NSRegularExpression(pattern: pattern, options: [])
      return true
    } catch {
      return false
    }
  }

  private func saveCustomFilter() {
    guard isValidFilter() else { return }

    let newFilter = RedactionFilter(
      id: UUID().uuidString,
      enabled: true,
      pattern: newFilterPattern,
      replacement: newFilterReplacement,
      description: newFilterDescription,
      isCustom: true
    )

    redactionFilters.append(newFilter)

    // Reset form
    newFilterPattern = ""
    newFilterReplacement = ""
    newFilterDescription = ""
    showAddFilter = false
  }

  private func resetToDefaults() {
    redactionFilters = RedactionFilter.defaultFiltersWithSystem()
  }
}

#Preview {
  RedactionSettingsPane()
    .environment(\.locale, .init(identifier: "en"))
}
