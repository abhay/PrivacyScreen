import SwiftUI

// MARK: - DemoCaptionOverlay

/// Full-width caption bar pinned to the bottom edge of the screen during demo mode.
struct DemoCaptionOverlay: View {
    let caption: DemoCaption

    var body: some View {
        VStack {
            Spacer()

            if !caption.isEmpty {
                VStack(spacing: 4) {
                    Text(caption.title)
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)

                    Text(caption.subtitle)
                        .font(.system(size: 15, weight: .medium, design: .rounded))
                        .foregroundStyle(.white.opacity(0.7))
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal, 24)
                .padding(.top, 20)
                .padding(.bottom, 54)
                .frame(maxWidth: .infinity)
                .background(.black.opacity(0.8))
                .transition(.opacity.combined(with: .move(edge: .bottom)))
            }
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
        .animation(.easeInOut(duration: 0.3), value: caption)
    }
}
