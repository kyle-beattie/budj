//
//  DebugStepSkip.swift
//  Budj
//

#if DEBUG
import SwiftUI

/// A way past a step whose real implementation is not built yet.
///
/// It is separate from the step's own primary action, and says what it is,
/// because a "Subscribe" button that silently advances without subscribing is a
/// screen that lies — and the lie survives long after the reason for it is
/// forgotten. The real action stays visible and disabled beside it, so what is
/// missing is obvious.
///
/// The whole file is inside `#if DEBUG`, so a release build has no such control
/// and no way past these steps except the real one.
struct DebugStepSkip: View {
    let title: String
    let action: () -> Void

    var body: some View {
        VStack(spacing: BudjSpacing.hair) {
            Button(title, action: action)
                .buttonStyle(.budjSecondary)

            Text("Debug build only. This step's real behaviour is not built yet.")
                .font(BudjTypography.caption)
                .foregroundStyle(BudjColor.textTertiary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
        }
    }
}

#Preview {
    DebugStepSkip(title: "Skip this step") {}
        .padding(BudjSpacing.loose)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(BudjColor.background)
}
#endif
