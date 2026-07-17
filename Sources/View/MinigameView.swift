import SwiftUI

public struct MinigameView: View {
    @Binding public var pet: Pet
    public let pixelColor: Color
    public let onComplete: (Bool) -> Void
    
    @State private var gameStarted = false
    @State private var countdown = 3
    @State private var power: CGFloat = 0.0
    @State private var timeLeft: Double = 5.0
    @State private var timer: Timer? = nil
    @State private var countdownTimer: Timer? = nil
    @State private var resultMessage: String? = nil
    @State private var isSuccess = false
    
    public init(pet: Binding<Pet>, pixelColor: Color, onComplete: @escaping (Bool) -> Void) {
        self._pet = pet
        self.pixelColor = pixelColor
        self.onComplete = onComplete
    }
    
    public var body: some View {
        VStack(spacing: 8) {
            Text("TREINAR!")
                .font(.system(.caption, design: .monospaced))
                .bold()
                .foregroundColor(pixelColor)
            
            if !gameStarted {
                // Countdown screen
                VStack(spacing: 12) {
                    Text(countdown > 0 ? "\(countdown)" : "JÁ!")
                        .font(.system(.title, design: .monospaced))
                        .bold()
                        .foregroundColor(pixelColor)
                    
                    Text("Prepara-se para apertar!")
                        .font(.system(.footnote, design: .monospaced))
                        .foregroundColor(pixelColor)
                        .multilineTextAlignment(.center)
                }
                .frame(maxHeight: .infinity)
                .onAppear {
                    startCountdown()
                }
            } else if let result = resultMessage {
                // Game Over screen
                VStack(spacing: 12) {
                    Text(result)
                        .font(.system(.title2, design: .monospaced))
                        .bold()
                        .foregroundColor(pixelColor)
                    
                    if isSuccess {
                        PixelSpriteView(frame: Sprites.heart, pixelColor: pixelColor)
                            .frame(width: 32, height: 32)
                    } else {
                        PixelSpriteView(frame: Sprites.skull, pixelColor: pixelColor)
                            .frame(width: 32, height: 32)
                    }
                    
                    Button(action: {
                        onComplete(isSuccess)
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
            } else {
                // Game Play screen
                VStack(spacing: 8) {
                    // Time Left
                    Text(String(format: "TEMPO: %.1fs", timeLeft))
                        .font(.system(.body, design: .monospaced))
                        .foregroundColor(pixelColor)
                    
                    // Power Bar (Pixelated look)
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            // Outer Border
                            Rectangle()
                                .stroke(pixelColor, lineWidth: 2)
                            
                            // Filled Bar
                            Rectangle()
                                .fill(pixelColor)
                                .frame(width: geo.size.width * power)
                                .padding(2)
                        }
                    }
                    .frame(height: 20)
                    .padding(.horizontal)
                    
                    Spacer()
                    
                    // Tap Button
                    Button(action: {
                        tapPower()
                    }) {
                        Text("APERTAR!")
                            .font(.system(.body, design: .monospaced))
                            .bold()
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(pixelColor)
                            .foregroundColor(pixelColor == .black ? .white : .black)
                            .cornerRadius(4)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                .frame(maxHeight: .infinity)
            }
        }
        .onDisappear {
            cleanupTimers()
        }
    }
    
    private func startCountdown() {
        countdownTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            if countdown > 1 {
                countdown -= 1
            } else if countdown == 1 {
                countdown = 0 // Displays "JÁ!"
            } else {
                countdownTimer?.invalidate()
                gameStarted = true
                startSimulation()
            }
        }
    }
    
    private func startSimulation() {
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            timeLeft = max(0.0, timeLeft - 0.1)
            
            // Decaimento natural do poder
            power = max(0.0, power - 0.015)
            
            if timeLeft <= 0 {
                endGame(success: false)
            }
        }
    }
    
    private func tapPower() {
        guard gameStarted && resultMessage == nil else { return }
        power = min(1.0, power + 0.08)
        
        if power >= 1.0 {
            endGame(success: true)
        }
    }
    
    private func endGame(success: Bool) {
        cleanupTimers()
        isSuccess = success
        resultMessage = success ? "SUCESSO!" : "FALHOU!"
        
        // Aplica o resultado do treino ao pet
        pet.train(success: success)
        pet.save()
    }
    
    private func cleanupTimers() {
        timer?.invalidate()
        timer = nil
        countdownTimer?.invalidate()
        countdownTimer = nil
    }
}
