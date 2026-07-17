import SwiftUI

public struct PixelSprite: Shape {
    public let frame: Sprites.Frame
    
    public func path(in rect: CGRect) -> Path {
        var path = Path()
        let rows = frame.count
        guard rows > 0 else { return path }
        let cols = frame[0].count
        guard cols > 0 else { return path }
        
        let cellWidth = rect.width / CGFloat(cols)
        let cellHeight = rect.height / CGFloat(rows)
        
        for r in 0..<rows {
            let rowString = frame[r]
            let characters = Array(rowString)
            for c in 0..<min(cols, characters.count) {
                if characters[c] == "X" {
                    let pixelRect = CGRect(
                        x: CGFloat(c) * cellWidth,
                        y: CGFloat(r) * cellHeight,
                        width: cellWidth,
                        height: cellHeight
                    )
                    path.addRect(pixelRect)
                }
            }
        }
        return path
    }
}

public struct PixelSpriteView: View {
    public let frame: Sprites.Frame
    public let pixelColor: Color
    public let backgroundColor: Color
    
    public init(frame: Sprites.Frame, pixelColor: Color = .primary, backgroundColor: Color = .clear) {
        self.frame = frame
        self.pixelColor = pixelColor
        self.backgroundColor = backgroundColor
    }
    
    public var body: some View {
        ZStack {
            backgroundColor
            PixelSprite(frame: frame)
                .fill(pixelColor)
        }
        .aspectRatio(1.0, contentMode: .fit)
    }
}

#Preview {
    PixelSpriteView(frame: Sprites.flapor1, pixelColor: .black, backgroundColor: .white)
        .frame(width: 100, height: 100)
}
