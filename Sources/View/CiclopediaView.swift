import SwiftUI

public struct CiclopediaView: View {
    public let unlockedStages: Set<EvolutionStage>
    public let pixelColor: Color
    public let onBack: () -> Void
    
    public init(unlockedStages: Set<EvolutionStage>, pixelColor: Color, onBack: @escaping () -> Void) {
        self.unlockedStages = unlockedStages
        self.pixelColor = pixelColor
        self.onBack = onBack
    }
    
    public var body: some View {
        VStack(spacing: 4) {
            // Header
            HStack {
                Text("ALBUM")
                    .font(.system(.footnote, design: .monospaced))
                    .bold()
                Spacer()
                Text("\(unlockedStages.count)/\(EvolutionStage.allCases.count)")
                    .font(.system(.footnote, design: .monospaced))
            }
            .foregroundColor(pixelColor)
            .padding(.horizontal)
            .padding(.top, 4)
            
            // List of stages
            List {
                ForEach(EvolutionStage.allCases, id: \.self) { stage in
                    let isUnlocked = unlockedStages.contains(stage)
                    HStack(spacing: 8) {
                        // Sprite
                        if isUnlocked {
                            PixelSpriteView(frame: Sprites.animation(for: stage, frameIndex: 0), pixelColor: pixelColor)
                                .frame(width: 36, height: 36)
                        } else {
                            // Question mark or faint placeholder silhouette
                            ZStack {
                                PixelSpriteView(frame: Sprites.animation(for: stage, frameIndex: 0), pixelColor: pixelColor.opacity(0.12))
                                Text("?")
                                    .font(.system(.headline, design: .monospaced))
                                    .bold()
                                    .foregroundColor(pixelColor)
                             }
                            .frame(width: 36, height: 36)
                        }
                        
                        VStack(alignment: .leading) {
                            Text(isUnlocked ? stage.displayName : "BLOQUEADO")
                                .font(.system(.caption, design: .monospaced))
                                .bold()
                                .foregroundColor(pixelColor)
                            Text(stageDescription(stage: stage))
                                .font(.system(.footnote, design: .monospaced))
                                .foregroundColor(pixelColor.opacity(isUnlocked ? 0.7 : 0.3))
                                .lineLimit(1)
                        }
                        Spacer()
                    }
                    .padding(.vertical, 2)
                    .listRowBackground(Color.clear)
                }
            }
            .listStyle(PlainListStyle())
            
            // Back button
            Button(action: onBack) {
                Text("VOLTAR")
                    .font(.system(.body, design: .monospaced))
                    .bold()
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 4)
            }
            .buttonStyle(PlainButtonStyle())
            .foregroundColor(pixelColor)
            .padding(.horizontal)
            .padding(.bottom, 2)
        }
    }
    
    private func stageDescription(stage: EvolutionStage) -> String {
        switch stage.tier {
        case .egg:
            return "Um ovo quente e cheio de energia."
        case .baby:
            return "Muito pequeno, faminto e barulhento."
        case .child:
            return "Jovem e ávido por treinos ativos."
        case .adult:
            return "Guerreiro crescido da linhagem de fogo."
        case .perfect:
            return "A evolução perfeita e absoluta."
        }
    }
}
