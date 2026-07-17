import SwiftUI

public struct BattleView: View {
    @Binding public var pet: Pet
    public let pixelColor: Color
    public let onComplete: () -> Void
    
    @State private var opponentName = "Carregando..."
    @State private var isFighting = false
    @State private var showResult = false
    @State private var victory = false
    
    // Animation offsets
    @State private var petOffset: CGFloat = -40
    @State private var opponentOffset: CGFloat = 40
    @State private var showSword = false
    @State private var frameToggler = 0
    @State private var opponentStage: EvolutionStage = .tomaDrake
    
    public init(pet: Binding<Pet>, pixelColor: Color, onComplete: @escaping () -> Void) {
        self._pet = pet
        self.pixelColor = pixelColor
        self.onComplete = onComplete
    }
    
    public var body: some View {
        VStack(spacing: 4) {
            Text("BATALHA!")
                .font(.system(.caption, design: .monospaced))
                .bold()
                .foregroundColor(pixelColor)
            
            if !isFighting && !showResult {
                // Intro Screen
                VStack(spacing: 8) {
                    Text("UM ADVERSÁRIO")
                        .font(.system(.footnote, design: .monospaced))
                        .foregroundColor(pixelColor)
                    Text("APARECEU!")
                        .font(.system(.footnote, design: .monospaced))
                        .foregroundColor(pixelColor)
                        .bold()
                    
                    Text(opponentName)
                        .font(.system(.body, design: .monospaced))
                        .bold()
                        .foregroundColor(pixelColor)
                        .padding(.vertical, 4)
                    
                    Button(action: {
                        startFight()
                    }) {
                        Text("LUTAR")
                            .font(.system(.body, design: .monospaced))
                            .bold()
                            .padding(.horizontal)
                            .frame(maxWidth: .infinity)
                            .background(pixelColor)
                            .foregroundColor(pixelColor == .black ? .white : .black)
                            .cornerRadius(4)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                .frame(maxHeight: .infinity)
                .onAppear {
                    setupOpponent()
                }
            } else if isFighting {
                // Battle Animation Screen
                VStack {
                    Spacer()
                    
                    ZStack {
                        // Pet Sprite
                        PixelSpriteView(frame: Sprites.animation(for: pet.stage, frameIndex: frameToggler), pixelColor: pixelColor)
                            .frame(width: 48, height: 48)
                            .offset(x: petOffset)
                        
                        // Opponent Sprite
                        PixelSpriteView(frame: Sprites.animation(for: opponentStage, frameIndex: frameToggler + 1), pixelColor: pixelColor)
                            .frame(width: 48, height: 48)
                            .offset(x: opponentOffset)
                            .scaleEffect(x: -1, y: 1) // Mirrored
                        
                        // Hit indicator (Swords)
                        if showSword {
                            PixelSpriteView(frame: Sprites.sword, pixelColor: pixelColor)
                                .frame(width: 32, height: 32)
                        }
                    }
                    .frame(height: 80)
                    
                    Spacer()
                    
                    Text("LUTANDO...")
                        .font(.system(.footnote, design: .monospaced))
                        .foregroundColor(pixelColor)
                }
                .frame(maxHeight: .infinity)
            } else {
                // Result Screen
                VStack(spacing: 6) {
                    Text(victory ? "VITÓRIA!" : "DERROTA!")
                        .font(.system(.title3, design: .monospaced))
                        .bold()
                        .foregroundColor(pixelColor)
                    
                    if victory {
                        Text("+1 Força / -1 Energia")
                            .font(.system(.footnote, design: .monospaced))
                            .foregroundColor(pixelColor)
                        
                        PixelSpriteView(frame: Sprites.heart, pixelColor: pixelColor)
                            .frame(width: 28, height: 28)
                    } else {
                        Text("-15 Saúde / -2 Energia")
                            .font(.system(.footnote, design: .monospaced))
                            .foregroundColor(pixelColor)
                        
                        PixelSpriteView(frame: Sprites.skull, pixelColor: pixelColor)
                            .frame(width: 28, height: 28)
                    }
                    
                    Button(action: {
                        onComplete()
                    }) {
                        Text("VOLTAR")
                            .font(.system(.body, design: .monospaced))
                            .bold()
                            .padding(.horizontal)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .foregroundColor(pixelColor)
                    .padding(.top, 4)
                }
                .frame(maxHeight: .infinity)
            }
        }
    }
    
    private func setupOpponent() {
        let opponentStages: [EvolutionStage] = [
            .tomaDrake, .tomaFlaris, .tomaIgnis, .tomaCoal,
            .drakeLord, .pyroBeast, .shadowDrake,
            .kaiserDrake, .kaiserBeast, .diabloDrake
        ]
        opponentStage = opponentStages.randomElement() ?? .tomaDrake
        
        let names = [
            "Agumon", "Devimon", "Greymon", "Numemon", 
            "Sukamon", "Betamon", "Kabuterimon", "MetalGreymon"
        ]
        let name = names.randomElement() ?? "Challenger"
        opponentName = "\(opponentStage.displayName) \(name)"
    }
    
    private func startFight() {
        isFighting = true
        petOffset = -40
        opponentOffset = 40
        showSword = false
        
        // Execute the actual battle logic instantly
        let fightResult = pet.startBattle()
        victory = fightResult.victory
        pet.save()
        
        // Run animation sequence
        animateRound(round: 1)
    }
    
    private func animateRound(round: Int) {
        // Toggle sprites walking/moving
        frameToggler += 1
        
        withAnimation(.easeInOut(duration: 0.3)) {
            // Slide to center
            petOffset = -15
            opponentOffset = 15
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            showSword = true
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                showSword = false
                
                withAnimation(.easeInOut(duration: 0.2)) {
                    // Knock back
                    petOffset = -35
                    opponentOffset = 35
                }
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    if round < 3 {
                        animateRound(round: round + 1)
                    } else {
                        // End battle animation
                        withAnimation {
                            isFighting = false
                            showResult = true
                            // Knock down loser
                            if victory {
                                opponentOffset = 70
                            } else {
                                petOffset = -70
                            }
                        }
                    }
                }
            }
        }
    }
}
