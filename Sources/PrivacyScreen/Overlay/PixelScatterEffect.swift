import SwiftUI

// MARK: - PixelScatterEffect

/// Animated black pixel grid effect drawn using Canvas.
///
/// Creates a pseudorandom checkerboard of black rectangles with a shimmer animation,
/// used as part of the full-screen privacy shield overlay.
struct PixelScatterEffect: View {

    /// Controls the density of pixels (0.0 to 1.0).
    var density: Double = 0.6

    /// Size of each pixel cell.
    var cellSize: CGFloat = 4

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30.0)) { timeline in
            Canvas { context, size in
                let time = timeline.date.timeIntervalSinceReferenceDate
                let cols = Int(size.width / cellSize)
                let rows = Int(size.height / cellSize)

                for row in 0..<rows {
                    for col in 0..<cols {
                        // Pseudorandom based on position + time for shimmer
                        let seed = Double(row * 7919 + col * 6271)
                        let phase = sin(seed * 0.001 + time * 2.0)
                        let threshold = density + phase * 0.15

                        // Hash function for stable randomness per cell
                        let hash = sin(seed * 0.00137 + 0.7) * 43758.5453
                        let random = hash - Double(Int(hash))

                        if random < threshold {
                            let rect = CGRect(
                                x: CGFloat(col) * cellSize,
                                y: CGFloat(row) * cellSize,
                                width: cellSize,
                                height: cellSize
                            )
                            // Vary opacity slightly for shimmer effect
                            let opacity = 0.7 + 0.3 * sin(seed * 0.0013 + time * 3.0)
                            context.opacity = opacity
                            context.fill(
                                Path(rect),
                                with: .color(.black)
                            )
                        }
                    }
                }
            }
        }
        .allowsHitTesting(false)
    }
}
