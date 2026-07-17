import SwiftUI
#if canImport(WatchKit)
import WatchKit
#endif
#if canImport(HealthKit)
import HealthKit
#endif

public enum WatchHapticType {
    case click
    case success
    case failure
    case retry
}

public struct ContentView: View {
    @State private var pet = Pet.load()
    @State private var invertColors = false // true = Preto no Branco, false = Branco no Preto
    
    // Animation States
    @State private var frameIndex = 0
    @State private var isEating = false
    @State private var isCleaning = false
    @State private var showBroomOffset: CGFloat = 160
    
    // Navigation / Active Screens
    @State private var activeSheet: ActiveSheet? = nil
    
    // Digital Crown & HealthKit states
    @State private var focusedIndex = 0
    @State private var stepsUpdateCounter = 0
    
    #if canImport(HealthKit)
    private let healthStore = HKHealthStore()
    #endif
    
    // Timers
    private let animationTimer = Timer.publish(every: 0.8, on: .main, in: .common).autoconnect()
    private let gameTimer = Timer.publish(every: 1.0, on: .main, in: .common).autoconnect()
    
    public enum ActiveSheet: Identifiable {
        case status
        case minigame
        case battle
        case ciclopedia
        case multipeerBattle
        case selectEgg
        
        public var id: Int {
            switch self {
            case .status: return 0
            case .minigame: return 1
            case .battle: return 2
            case .ciclopedia: return 3
            case .multipeerBattle: return 4
            case .selectEgg: return 5
            }
        }
    }
    
    public init() {}
    
    // Theme colors
    private var pixelColor: Color {
        invertColors ? .black : .white
    }
    
    private var screenBackground: Color {
        invertColors ? .white : .black
    }
    
    public var body: some View {
        TabView {
            // MARK: - TAB 1: Pet Room
            GeometryReader { geo in
                ZStack {
                    screenBackground
                        .edgesIgnoringSafeArea(.all)
                    
                    // Main layout
                    VStack(spacing: 2) {
                        // 1. Status Indicator Bar (Classic V-Pet LCD icons)
                        HStack(spacing: 12) {
                            // Food indicator
                            indicatorIcon(systemName: "fork.knife", active: pet.hunger > 1)
                            
                            // Strength indicator
                            indicatorIcon(systemName: "bolt.fill", active: pet.strength > 1)
                            
                            // Health indicator
                            indicatorIcon(systemName: "heart.fill", active: pet.health > 40)
                            
                            Spacer()
                            
                            // Weather indicator
                            Image(systemName: pet.weather.iconName)
                                .font(.system(.caption2))
                                .foregroundColor(pixelColor)
                            
                            // Attention needed flashing icon
                            if pet.attentionNeeded {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .font(.system(.caption2))
                                    .foregroundColor(frameIndex % 2 == 0 ? pixelColor : .clear)
                            }
                            
                            // Sick indicator
                            if pet.isSick {
                                Image(systemName: "skull.fill")
                                    .font(.system(.caption2))
                                    .foregroundColor(pixelColor)
                            }
                        }
                        .padding(.horizontal, 8)
                        .padding(.top, 4)
                        
                        // 2. Pet Screen Boundary Box
                        ZStack {
                            Rectangle()
                                .stroke(pixelColor, lineWidth: 2)
                            
                            // Pet render or Tombstone
                            if pet.isAlive {
                                if isEating {
                                    // Eating animation
                                    HStack(spacing: 8) {
                                        PixelSpriteView(frame: Sprites.animation(for: pet.stage, frameIndex: frameIndex), pixelColor: pixelColor)
                                            .frame(width: 44, height: 44)
                                            .offset(x: frameIndex % 2 == 0 ? 5 : -5)
                                        
                                        PixelSpriteView(frame: Sprites.meat, pixelColor: pixelColor)
                                            .frame(width: 20, height: 20)
                                            .scaleEffect(frameIndex % 2 == 0 ? 0.7 : 1.0)
                                    }
                                } else {
                                    // Normal sprite
                                    PixelSpriteView(frame: Sprites.animation(for: pet.stage, frameIndex: frameIndex), pixelColor: pixelColor)
                                        .frame(width: 50, height: 50)
                                        .offset(y: pet.isSleeping ? 10 : 0)
                                }
                            } else {
                                // Dead
                                PixelSpriteView(frame: Sprites.tombstone, pixelColor: pixelColor)
                                    .frame(width: 50, height: 50)
                            }
                            
                            // Render Poop if present
                            if pet.poopCount > 0 {
                                HStack(spacing: 2) {
                                    ForEach(0..<pet.poopCount, id: \.self) { _ in
                                        PixelSpriteView(frame: Sprites.poop, pixelColor: pixelColor)
                                            .frame(width: 14, height: 14)
                                    }
                                }
                                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
                                .padding(.trailing, 6)
                                .padding(.bottom, 6)
                            }
                            
                            // Broom sweep animation
                            if isCleaning {
                                Rectangle()
                                    .fill(pixelColor)
                                    .frame(width: 12, height: geo.size.height)
                                    .offset(x: showBroomOffset)
                            }
                            
                            // Weather particles overlay
                            if pet.isAlive && !pet.isSleeping {
                                Group {
                                    if pet.weather == .rainy {
                                        RainOverlayView(frameIndex: frameIndex, color: pixelColor)
                                    } else if pet.weather == .snowy {
                                        SnowOverlayView(frameIndex: frameIndex, color: pixelColor)
                                    } else if pet.weather == .sunny {
                                        SunOverlayView(color: pixelColor)
                                    }
                                }
                            }
                            
                            // Sleeping/Lights out overlay
                            if pet.isSleeping {
                                Color.black.opacity(0.85)
                                    .overlay(
                                        Text("ZZZ...")
                                            .font(.system(.body, design: .monospaced))
                                            .foregroundColor(.white)
                                    )
                            }
                        }
                        .frame(height: geo.size.height * 0.65)
                        .padding(.horizontal, 4)
                        
                        // 3. Mini status string
                        Text(petStatusText())
                            .font(.system(.caption2, design: .monospaced))
                            .foregroundColor(pixelColor)
                            .padding(.bottom, 2)
                    }
                }
            }
            
            // MARK: - TAB 2: Actions Menu
            ScrollView {
                VStack(spacing: 6) {
                    Text("AÇÕES")
                        .font(.system(.footnote, design: .monospaced))
                        .bold()
                        .foregroundColor(pixelColor)
                        .padding(.top, 4)
                    
                    let menuItems = getMenuItems()
                    ForEach(menuItems, id: \.id) { item in
                        let isFocused = focusedIndex == item.id
                        actionRow(title: item.title, icon: item.icon, isFocused: isFocused) {
                            item.action()
                        }
                    }
                }
                .padding(.horizontal, 6)
                #if os(watchOS)
                .focusable()
                .digitalCrownRotation(
                    Binding(
                        get: { Double(focusedIndex) },
                        set: { val in
                            let items = getMenuItems()
                            let newIndex = max(0, min(items.count - 1, Int(round(val))))
                            if newIndex != focusedIndex {
                                focusedIndex = newIndex
                                playHaptic(.click)
                            }
                        }
                    ),
                    from: 0.0,
                    through: Double(max(0, getMenuItems().count - 1)),
                    by: 1.0,
                    sensitivity: .medium,
                    isContinuous: false,
                    isHapticFeedbackEnabled: true
                )
                #endif
            }
            .background(screenBackground)
        }
        // Sub-sheets for active scenes
        .sheet(item: $activeSheet) { sheet in
            sheetView(for: sheet)
        }
        // Active Timers
        .onReceive(animationTimer) { _ in
            if pet.isAlive && !pet.isSleeping {
                frameIndex = (frameIndex + 1) % 2
            }
        }
        .onReceive(gameTimer) { now in
            let oldAttention = pet.attentionNeeded
            pet.updateState(currentTime: now)
            
            // Haptic on attention required
            if pet.attentionNeeded && !oldAttention {
                playHaptic(.retry)
            }
            
            // Periodically check/fetch HealthKit steps
            stepsUpdateCounter += 1
            if stepsUpdateCounter >= 15 {
                stepsUpdateCounter = 0
                fetchTodaySteps()
            }
            
            // Auto save periodically
            if frameIndex % 5 == 0 {
                pet.save()
            }
        }
        .onAppear {
            requestHealthKitAuth()
            fetchTodaySteps()
        }
    }
    
    // MARK: - Component Helpers
    
    private func indicatorIcon(systemName: String, active: Bool) -> some View {
        Image(systemName: systemName)
            .font(.system(.caption2))
            .foregroundColor(active ? pixelColor : pixelColor.opacity(0.2))
    }
    
    private func actionRow(title: String, icon: String, isFocused: Bool = false, action: @escaping () -> Void) -> some View {
        Button(action: {
            playHaptic(.click)
            action()
        }) {
            HStack {
                Image(systemName: icon)
                    .frame(width: 18)
                Text(title)
                    .font(.system(.caption, design: .monospaced))
                Spacer()
            }
            .foregroundColor(isFocused ? screenBackground : pixelColor)
            .padding(.vertical, 6)
            .padding(.horizontal, 8)
            .background(
                RoundedRectangle(cornerRadius: 4)
                    .fill(isFocused ? pixelColor : Color.clear)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 4)
                    .stroke(pixelColor, lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func speedSection() -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("VELOCIDADE SIMULAÇÃO:")
                .font(.system(.caption2, design: .monospaced))
                .foregroundColor(pixelColor)
                .bold()
                .padding(.top, 4)
            
            HStack(spacing: 4) {
                speedButton(label: "1x", multiplier: 1.0)
                speedButton(label: "60x", multiplier: 60.0)
                speedButton(label: "3600x", multiplier: 3600.0)
            }
        }
    }
    
    private func speedButton(label: String, multiplier: Double) -> some View {
        Button(action: {
            pet.timeMultiplier = multiplier
            pet.save()
        }) {
            Text(label)
                .font(.system(.caption2, design: .monospaced))
                .bold()
                .frame(maxWidth: .infinity)
                .padding(.vertical, 4)
                .background(
                    RoundedRectangle(cornerRadius: 3)
                        .fill(pet.timeMultiplier == multiplier ? pixelColor : Color.clear)
                )
                .foregroundColor(pet.timeMultiplier == multiplier ? screenBackground : pixelColor)
                .overlay(
                    RoundedRectangle(cornerRadius: 3)
                        .stroke(pixelColor, lineWidth: 1)
                )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func petStatusText() -> String {
        if !pet.isAlive {
            return "FALECIDO (R.I.P)"
        }
        if pet.stage.tier == .egg {
            return "CHOCANDO OVO..."
        }
        if pet.isSleeping {
            return "DORMINDO..."
        }
        if pet.isSick {
            return "DOENTE! CURAR!"
        }
        return "\(pet.stage.displayName) (Idade: \(pet.age))"
    }
    
    // MARK: - Action Animations
    
    private func triggerEat() {
        guard !isEating else { return }
        playHaptic(.click)
        isEating = true
        pet.feedMeal()
        pet.save()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            isEating = false
        }
    }
    
    private func triggerClean() {
        guard !isCleaning else { return }
        playHaptic(.click)
        isCleaning = true
        showBroomOffset = 80
        
        withAnimation(.linear(duration: 1.5)) {
            showBroomOffset = -80
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            isCleaning = false
            pet.cleanPoop()
            pet.save()
        }
    }
    
    // MARK: - Sheet Router
    
    @ViewBuilder
    private func sheetView(for sheet: ActiveSheet) -> some View {
        ZStack {
            screenBackground
                .edgesIgnoringSafeArea(.all)
            
            switch sheet {
            case .status:
                StatusDetailsView(pet: pet, pixelColor: pixelColor)
            case .minigame:
                MinigameView(pet: $pet, pixelColor: pixelColor) { success in
                    activeSheet = nil
                }
            case .battle:
                BattleView(pet: $pet, pixelColor: pixelColor) {
                    activeSheet = nil
                }
            case .ciclopedia:
                CiclopediaView(unlockedStages: pet.unlockedStages, pixelColor: pixelColor) {
                    activeSheet = nil
                }
            case .multipeerBattle:
                MultipeerBattleView(pet: $pet, pixelColor: pixelColor) {
                    activeSheet = nil
                }
            case .selectEgg:
                EggSelectionView(pixelColor: pixelColor) { selectedEgg in
                    pet = Pet.reset(stage: selectedEgg)
                    focusedIndex = 0
                    activeSheet = nil
                }
            }
        }
    }
    
    // MARK: - Menu Generation
    
    struct MenuItem {
        let id: Int
        let title: String
        let icon: String
        let action: () -> Void
    }
    
    private func getMenuItems() -> [MenuItem] {
        var items: [MenuItem] = []
        var nextId = 0
        
        if pet.isAlive {
            items.append(MenuItem(id: nextId, title: "Alimentar Refeição", icon: "fork.knife") {
                triggerEat()
            })
            nextId += 1
            
            items.append(MenuItem(id: nextId, title: "Alimentar Vitamina", icon: "pill.fill") {
                pet.feedVitamin()
                pet.save()
            })
            nextId += 1
            
            items.append(MenuItem(id: nextId, title: "Treinar Pet", icon: "bolt.fill") {
                activeSheet = .minigame
            })
            nextId += 1
            
            items.append(MenuItem(id: nextId, title: "Limpar Cocô", icon: "wand.and.stars") {
                triggerClean()
            })
            nextId += 1
            
            items.append(MenuItem(id: nextId, title: "Curar Doença", icon: "cross.fill") {
                pet.heal()
                pet.save()
            })
            nextId += 1
            
            items.append(MenuItem(id: nextId, title: "Luz: " + (pet.isSleeping ? "Ligar" : "Desligar"), icon: "lightbulb.fill") {
                pet.toggleSleep()
                pet.save()
            })
            nextId += 1
            
            items.append(MenuItem(id: nextId, title: "Batalha Local", icon: "sparkles") {
                activeSheet = .battle
            })
            nextId += 1
            
            items.append(MenuItem(id: nextId, title: "Batalha Bluetooth", icon: "antenna.radiowaves.left.and.right") {
                activeSheet = .multipeerBattle
            })
            nextId += 1
            
            items.append(MenuItem(id: nextId, title: "Ciclopédia", icon: "book.fill") {
                activeSheet = .ciclopedia
            })
            nextId += 1
        }
        
        items.append(MenuItem(id: nextId, title: "Status Detalhados", icon: "doc.text.fill") {
            activeSheet = .status
        })
        nextId += 1
        
        items.append(MenuItem(id: nextId, title: "Inverter Cores", icon: "circle.lefthalf.striped.horizontal") {
            invertColors.toggle()
        })
        nextId += 1
        
        items.append(MenuItem(id: nextId, title: pet.isAlive ? "Reiniciar Pet" : "Chocar Novo Ovo", icon: "arrow.clockwise") {
            activeSheet = .selectEgg
        })
        
        return items
    }
    
    // MARK: - HealthKit Helpers
    
    private func requestHealthKitAuth() {
        #if canImport(HealthKit)
        guard HKHealthStore.isHealthDataAvailable() else { return }
        
        guard let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount) else { return }
        let typesToRead: Set<HKObjectType> = [stepType]
        
        healthStore.requestAuthorization(toShare: nil, read: typesToRead) { success, error in
            if success {
                fetchTodaySteps()
            }
        }
        #endif
    }
    
    private func fetchTodaySteps() {
        #if canImport(HealthKit)
        guard HKHealthStore.isHealthDataAvailable() else { return }
        
        guard let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount) else { return }
        
        let calendar = Calendar.current
        let now = Date()
        let startOfDay = calendar.startOfDay(for: now)
        
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: now, options: .strictStartDate)
        
        let query = HKStatisticsQuery(quantityType: stepType, quantitySamplePredicate: predicate, options: .cumulativeSum) { _, result, error in
            guard let result = result, let sum = result.sumQuantity() else { return }
            
            let steps = Int(sum.doubleValue(for: HKUnit.count()))
            DispatchQueue.main.async {
                self.pet.applySteps(steps)
                self.pet.save()
            }
        }
        
        healthStore.execute(query)
        #endif
    }
    
    // MARK: - Haptic Helper
    
    private func playHaptic(_ type: WatchHapticType) {
        #if os(watchOS)
        let wkType: WKHapticType
        switch type {
        case .click: wkType = .click
        case .success: wkType = .success
        case .failure: wkType = .failure
        case .retry: wkType = .retry
        }
        WKInterfaceDevice.current().play(wkType)
        #endif
    }
}

// MARK: - Weather Particle Overlays

struct RainOverlayView: View {
    let frameIndex: Int
    let color: Color
    
    var body: some View {
        GeometryReader { geo in
            ZStack {
                Path { path in
                    path.move(to: CGPoint(x: 15, y: 10 + (frameIndex * 20)))
                    path.addLine(to: CGPoint(x: 12, y: 22 + (frameIndex * 20)))
                }
                .stroke(color, lineWidth: 1.5)
                
                Path { path in
                    path.move(to: CGPoint(x: 45, y: 25 + (((frameIndex + 1) % 2) * 20)))
                    path.addLine(to: CGPoint(x: 42, y: 37 + (((frameIndex + 1) % 2) * 20)))
                }
                .stroke(color, lineWidth: 1.5)
                
                Path { path in
                    path.move(to: CGPoint(x: 75, y: 5 + (frameIndex * 25)))
                    path.addLine(to: CGPoint(x: 72, y: 17 + (frameIndex * 25)))
                }
                .stroke(color, lineWidth: 1.5)
                
                Path { path in
                    path.move(to: CGPoint(x: 105, y: 15 + (((frameIndex + 1) % 2) * 25)))
                    path.addLine(to: CGPoint(x: 102, y: 27 + (((frameIndex + 1) % 2) * 25)))
                }
                .stroke(color, lineWidth: 1.5)
            }
        }
        .allowsHitTesting(false)
    }
}

struct SnowOverlayView: View {
    let frameIndex: Int
    let color: Color
    
    var body: some View {
        GeometryReader { geo in
            ZStack {
                Rectangle()
                    .fill(color)
                    .frame(width: 2, height: 2)
                    .position(x: 20 + CGFloat(frameIndex * 5), y: 15 + CGFloat(frameIndex * 15))
                
                Rectangle()
                    .fill(color)
                    .frame(width: 2, height: 2)
                    .position(x: 60 - CGFloat(frameIndex * 4), y: 5 + CGFloat(((frameIndex + 1) % 2) * 20))
                
                Rectangle()
                    .fill(color)
                    .frame(width: 2, height: 2)
                    .position(x: 90 + CGFloat(frameIndex * 3), y: 25 + CGFloat(frameIndex * 10))
            }
        }
        .allowsHitTesting(false)
    }
}

struct SunOverlayView: View {
    let color: Color
    
    var body: some View {
        GeometryReader { geo in
            ZStack {
                Circle()
                    .stroke(color, lineWidth: 1.5)
                    .frame(width: 12, height: 12)
                    .position(x: geo.size.width - 20, y: 15)
                
                Path { path in
                    path.move(to: CGPoint(x: geo.size.width - 20, y: 5))
                    path.addLine(to: CGPoint(x: geo.size.width - 20, y: 2))
                    
                    path.move(to: CGPoint(x: geo.size.width - 20, y: 25))
                    path.addLine(to: CGPoint(x: geo.size.width - 20, y: 28))
                    
                    path.move(to: CGPoint(x: geo.size.width - 30, y: 15))
                    path.addLine(to: CGPoint(x: geo.size.width - 33, y: 15))
                    
                    path.move(to: CGPoint(x: geo.size.width - 10, y: 15))
                    path.addLine(to: CGPoint(x: geo.size.width - 7, y: 15))
                }
                .stroke(color, lineWidth: 1)
            }
        }
        .allowsHitTesting(false)
    }
}

struct EggSelectionView: View {
    let pixelColor: Color
    let onSelect: (EvolutionStage) -> Void
    
    var body: some View {
        VStack(spacing: 8) {
            Text("ESCOLHA SEU OVO")
                .font(.system(size: 14, weight: .bold, design: .monospaced))
                .foregroundColor(pixelColor)
            
            ScrollView {
                VStack(spacing: 8) {
                    Button(action: { onSelect(.egg1) }) {
                        Text("🔥 OVO DE FOGO")
                            .font(.system(size: 11, design: .monospaced))
                            .foregroundColor(pixelColor)
                            .padding(.vertical, 6)
                            .frame(maxWidth: .infinity)
                            .border(pixelColor, width: 1)
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    Button(action: { onSelect(.egg2) }) {
                        Text("💧 OVO DE ÁGUA")
                            .font(.system(size: 11, design: .monospaced))
                            .foregroundColor(pixelColor)
                            .padding(.vertical, 6)
                            .frame(maxWidth: .infinity)
                            .border(pixelColor, width: 1)
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    Button(action: { onSelect(.egg3) }) {
                        Text("🌱 OVO DA NATUREZA")
                            .font(.system(size: 11, design: .monospaced))
                            .foregroundColor(pixelColor)
                            .padding(.vertical, 6)
                            .frame(maxWidth: .infinity)
                            .border(pixelColor, width: 1)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                .padding(.horizontal, 4)
            }
        }
        .padding()
    }
}

#Preview {
    ContentView()
}
