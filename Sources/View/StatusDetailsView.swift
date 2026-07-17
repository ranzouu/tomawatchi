import SwiftUI

public struct StatusDetailsView: View {
    public let pet: Pet
    public let pixelColor: Color
    
    @State private var currentPage = 0
    private let totalPages = 3
    
    public init(pet: Pet, pixelColor: Color) {
        self.pet = pet
        self.pixelColor = pixelColor
    }
    
    public var body: some View {
        VStack(spacing: 8) {
            // Page Title / Indicator
            HStack {
                Text("STATUS (\(currentPage + 1)/\(totalPages))")
                    .font(.system(.footnote, design: .monospaced))
                    .bold()
                Spacer()
            }
            .foregroundColor(pixelColor)
            .padding(.horizontal)
            
            // Content Card
            ZStack {
                if currentPage == 0 {
                    // Page 1: General Info
                    VStack(alignment: .leading, spacing: 6) {
                        statusLine(label: "NOME:", value: pet.name)
                        statusLine(label: "FASE:", value: pet.stage.displayName)
                        statusLine(label: "IDADE:", value: "\(pet.age) Dias")
                        statusLine(label: "PESO:", value: "\(pet.weight)g")
                    }
                } else if currentPage == 1 {
                    // Page 2: Hearts (Fome / Força)
                    VStack(spacing: 8) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("FOME:")
                                .font(.system(.caption, design: .monospaced))
                                .bold()
                            heartMeter(value: pet.hunger)
                        }
                        VStack(alignment: .leading, spacing: 2) {
                            Text("FORÇA:")
                                .font(.system(.caption, design: .monospaced))
                                .bold()
                            heartMeter(value: pet.strength)
                        }
                    }
                } else {
                    // Page 3: Stats & Combat
                    VStack(alignment: .leading, spacing: 6) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("ENERGIA:")
                                .font(.system(.caption, design: .monospaced))
                                .bold()
                            heartMeter(value: pet.energy)
                        }
                        statusLine(label: "SAÚDE:", value: "\(pet.health)%")
                        statusLine(label: "VITÓRIAS:", value: "\(pet.wins)")
                        statusLine(label: "DERROTAS:", value: "\(pet.losses)")
                    }
                }
            }
            .frame(maxHeight: .infinity)
            .foregroundColor(pixelColor)
            .padding(.horizontal)
            
            // Navigation Buttons
            HStack {
                Button(action: {
                    if currentPage > 0 { currentPage -= 1 }
                }) {
                    Text("<")
                        .font(.system(.body, design: .monospaced))
                        .bold()
                }
                .disabled(currentPage == 0)
                .buttonStyle(PlainButtonStyle())
                .foregroundColor(currentPage == 0 ? pixelColor.opacity(0.2) : pixelColor)
                
                Spacer()
                
                Button(action: {
                    if currentPage < totalPages - 1 { currentPage += 1 }
                }) {
                    Text(">")
                        .font(.system(.body, design: .monospaced))
                        .bold()
                }
                .disabled(currentPage == totalPages - 1)
                .buttonStyle(PlainButtonStyle())
                .foregroundColor(currentPage == totalPages - 1 ? pixelColor.opacity(0.2) : pixelColor)
            }
            .padding(.horizontal)
            .padding(.bottom, 4)
        }
    }
    
    private func statusLine(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.system(.body, design: .monospaced))
                .bold()
            Spacer()
            Text(value)
                .font(.system(.body, design: .monospaced))
        }
    }
    
    private func heartMeter(value: Int) -> some View {
        HStack(spacing: 4) {
            ForEach(0..<4) { index in
                PixelSpriteView(frame: Sprites.heart, pixelColor: pixelColor)
                    .frame(width: 14, height: 14)
                    .opacity(index < value ? 1.0 : 0.15)
            }
        }
    }
}
