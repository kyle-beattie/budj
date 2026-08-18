//
//  BudjTextField.swift
//  Budj
//

import SwiftUI

/// A labelled field with room for an error underneath.
///
/// The error is part of the component rather than something each screen lays out
/// for itself, so a message can never appear somewhere a person will not look
/// for it — and the field's border changes with it, so the error is not carried
/// by colour alone.
struct BudjTextField: View {
    let label: String
    let placeholder: String
    @Binding var text: String

    var isSecure = false
    var error: String?
    var textContentType: UITextContentType?
    var keyboardType: UIKeyboardType = .default
    var submitLabel: SubmitLabel = .next
    var onSubmit: () -> Void = {}

    @FocusState private var isFocused: Bool

    private var hasError: Bool { error != nil }

    var body: some View {
        VStack(alignment: .leading, spacing: BudjSpacing.hair) {
            Text(label)
                .font(BudjTypography.caption)
                .foregroundStyle(BudjColor.textSecondary)

            field
                .font(BudjTypography.body)
                .foregroundStyle(BudjColor.textPrimary)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .textContentType(textContentType)
                .keyboardType(keyboardType)
                .submitLabel(submitLabel)
                .onSubmit(onSubmit)
                .focused($isFocused)
                .padding(.vertical, BudjSpacing.regular)
                .padding(.horizontal, BudjSpacing.regular)
                .background(BudjColor.raised, in: .rect(cornerRadius: BudjRadius.medium))
                .overlay {
                    RoundedRectangle(cornerRadius: BudjRadius.medium)
                        .strokeBorder(borderColour, lineWidth: hasError || isFocused ? 2 : 1)
                }
                .animation(BudjMotion.standard, value: isFocused)
                .animation(BudjMotion.standard, value: hasError)

            if let error {
                Label(error, systemImage: "exclamationmark.circle.fill")
                    .font(BudjTypography.caption)
                    .foregroundStyle(BudjColor.danger)
                    .transition(.opacity)
            }
        }
        .accessibilityElement(children: .contain)
    }

    @ViewBuilder
    private var field: some View {
        if isSecure {
            SecureField(placeholder, text: $text)
        } else {
            TextField(placeholder, text: $text)
        }
    }

    private var borderColour: Color {
        if hasError { BudjColor.danger }
        else if isFocused { BudjColor.borderStrong }
        else { BudjColor.borderSubtle }
    }
}

#Preview("States") {
    @Previewable @State var empty = ""
    @Previewable @State var filled = "someone@example.com"
    @Previewable @State var secret = "hunter22"

    VStack(spacing: BudjSpacing.loose) {
        BudjTextField(
            label: "Email",
            placeholder: "you@example.com",
            text: $empty,
            textContentType: .emailAddress,
            keyboardType: .emailAddress
        )
        BudjTextField(label: "Email", placeholder: "you@example.com", text: $filled)
        BudjTextField(
            label: "Email",
            placeholder: "you@example.com",
            text: $filled,
            error: "Enter an email address"
        )
        BudjTextField(label: "Password", placeholder: "At least 8 characters", text: $secret, isSecure: true)
    }
    .padding(BudjSpacing.loose)
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(BudjColor.background)
}
