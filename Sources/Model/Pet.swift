import Foundation

public enum Weather: String, Codable, CaseIterable {
    case sunny = "Ensolarado"
    case rainy = "Chuvoso"
    case snowy = "Nevando"
    
    public var iconName: String {
        switch self {
        case .sunny: return "sun.max.fill"
        case .rainy: return "cloud.rain.fill"
        case .snowy: return "snowflake"
        }
    }
}

public struct Pet: Codable, Equatable {
    // MARK: - Core Properties
    public var name: String
    public var stage: EvolutionStage
    public var age: Int // Em "dias" de jogo
    public var weight: Int // Em gramas
    
    // MARK: - Attributes (0 a 4)
    public var hunger: Int
    public var strength: Int
    public var energy: Int
    public var health: Int // 0 a 100
    public var poopCount: Int
    
    // MARK: - States
    public var isSick: Bool
    public var isSleeping: Bool
    public var isAlive: Bool
    public var careMistakes: Int
    public var wins: Int
    public var losses: Int
    
    // MARK: - Simulation Timing
    public var lastUpdateTime: Date
    public var evolutionSeconds: Double // Tempo decorrido no estágio atual em segundos de jogo
    public var timeMultiplier: Double // Multiplicador de tempo (1.0 = real, 60.0 = rápido, 3600.0 = super rápido)
    
    // MARK: - Time Trackers
    public var hungerZeroSeconds: Double
    public var dirtySeconds: Double
    public var sickSeconds: Double
    
    // MARK: - Game Design Additions
    public var unlockedStages: Set<EvolutionStage>
    public var stepsApplied: Int
    public var weather: Weather
    public var weatherSeconds: Double
    
    // MARK: - Initializer
    public init(name: String = "Toma", stage: EvolutionStage = .egg1, timeMultiplier: Double = 1.0) {
        self.name = name
        self.stage = stage
        self.age = 0
        self.weight = 5
        self.hunger = 2
        self.strength = 1
        self.energy = 4
        self.health = 100
        self.poopCount = 0
        self.isSick = false
        self.isSleeping = false
        self.isAlive = true
        self.careMistakes = 0
        self.wins = 0
        self.losses = 0
        self.lastUpdateTime = Date()
        self.evolutionSeconds = 0
        self.timeMultiplier = timeMultiplier
        self.hungerZeroSeconds = 0
        self.dirtySeconds = 0
        self.sickSeconds = 0
        self.unlockedStages = [stage]
        self.stepsApplied = 0
        self.weather = .sunny
        self.weatherSeconds = 0
    }
    
    // MARK: - Core Actions
    
    public mutating func feedMeal() {
        guard isAlive && !isSleeping else { return }
        if hunger < 4 {
            hunger += 1
            weight += 1
        }
        checkAttention()
    }
    
    public mutating func feedVitamin() {
        guard isAlive && !isSleeping else { return }
        if strength < 4 {
            strength += 1
            weight += 2
        }
        // Vitamina em excesso pode deixar doente
        if strength == 4 && Double.random(in: 0...1) < 0.2 {
            isSick = true
        }
        checkAttention()
    }
    
    public mutating func cleanPoop() {
        guard isAlive && !isSleeping else { return }
        if poopCount > 0 {
            poopCount = 0
            dirtySeconds = 0
        }
    }
    
    public mutating func heal() {
        guard isAlive && !isSleeping else { return }
        if isSick {
            isSick = false
            sickSeconds = 0
            health = min(health + 20, 100)
        }
    }
    
    public mutating func toggleSleep() {
        guard isAlive else { return }
        isSleeping.toggle()
        if isSleeping {
            // Dormir recupera energia
            energy = 4
        }
    }
    
    public mutating func train(success: Bool) {
        guard isAlive && !isSleeping && !isSick else { return }
        guard energy > 0 else { return }
        
        energy -= 1
        if success {
            if strength < 4 {
                strength += 1
            }
            weight = max(5, weight - 1)
        } else {
            weight = max(5, weight - 2)
        }
        checkAttention()
    }
    
    public mutating func startBattle() -> (victory: Bool, opponentName: String) {
        guard isAlive && !isSleeping && !isSick else { return (false, "Nenhum") }
        
        let opponents = ["Wild Botamon", "Aggro Agumon", "Dark Devimon", "Wild Greymon", "Numemon", "Sukamon"]
        let opponentName = opponents.randomElement() ?? "Challenger"
        
        // Fator de força baseado na evolução e strength
        let basePower = getBasePower()
        let petPower = basePower + Double(strength) * 10.0
        let opponentPower = Double.random(in: 10...80)
        
        let victory = petPower >= opponentPower
        if victory {
            wins += 1
            energy = max(0, energy - 1)
            strength = min(4, strength + 1)
        } else {
            losses += 1
            energy = max(0, energy - 2)
            health = max(0, health - 15)
        }
        
        if health <= 0 {
            isAlive = false
        }
        
        return (victory, opponentName)
    }
    
    private func getBasePower() -> Double {
        switch stage.tier {
        case .egg: return 0.0
        case .baby: return 10.0
        case .child: return 30.0
        case .adult: return 50.0
        case .perfect: return 90.0
        }
    }
    
    // MARK: - Attention Check
    public var attentionNeeded: Bool {
        guard isAlive else { return false }
        if stage.tier == .egg { return false }
        return hunger <= 1 || strength <= 1 || poopCount > 0 || isSick || (isSleeping && health < 50)
    }
    
    private mutating func checkAttention() {}
    
    // MARK: - Simulation Update Loop
    
    public mutating func updateState(currentTime: Date = Date()) {
        guard isAlive else { return }
        
        let realTimeElapsed = currentTime.timeIntervalSince(lastUpdateTime)
        let gameTimeElapsed = realTimeElapsed * timeMultiplier
        
        // Atualiza a hora da última simulação
        lastUpdateTime = currentTime
        
        if stage.tier == .egg {
            evolutionSeconds += gameTimeElapsed
            if evolutionSeconds >= 60.0 { // Ovo choca em 60 segundos de jogo
                evolve()
            }
            return
        }
        
        // Simular o passar do tempo
        // Atualiza clima (muda a cada 4 horas de jogo / 14400 segundos)
        weatherSeconds += gameTimeElapsed
        if weatherSeconds >= 14400.0 {
            weatherSeconds = 0
            weather = Weather.allCases.randomElement() ?? .sunny
        }
        
        // 1. Envelhecimento (1 dia de jogo = 86400 segundos de jogo)
        evolutionSeconds += gameTimeElapsed
        let daysPassed = Int(evolutionSeconds / 86400.0)
        if daysPassed > 0 {
            age += daysPassed
        }
        
        // 2. Fome decai (1 nível a cada 1800 segundos de jogo / 30 minutos)
        // Se estiver nevando, a fome decai 1.5x mais rápido
        let hungerMultiplier = (weather == .snowy) ? 1.5 : 1.0
        let hungerDecayRate = 1800.0 / hungerMultiplier
        let hungerDecaySteps = Int(gameTimeElapsed / hungerDecayRate)
        if hungerDecaySteps > 0 {
            hunger = max(0, hunger - hungerDecaySteps)
        }
        
        // 3. Força decai (1 nível a cada 3600 segundos de jogo / 1 hora)
        let strengthDecayRate = 3600.0
        let strengthDecaySteps = Int(gameTimeElapsed / strengthDecayRate)
        if strengthDecaySteps > 0 {
            strength = max(0, strength - strengthDecaySteps)
        }
        
        // 4. Energia
        if isSleeping {
            // Dormir recupera 1 energia por hora (3600 segundos)
            let energyGain = Int(gameTimeElapsed / 3600.0)
            if energyGain > 0 {
                energy = min(4, energy + energyGain)
            }
        } else {
            // Acordado gasta 1 energia a cada 7200 segundos (2 horas)
            // Se estiver chovendo, energia decai 1.5x mais rápido
            let energyMultiplier = (weather == .rainy) ? 1.5 : 1.0
            let energyDecayRate = 7200.0 / energyMultiplier
            let energyDecaySteps = Int(gameTimeElapsed / energyDecayRate)
            if energyDecaySteps > 0 {
                energy = max(0, energy - energyDecaySteps)
            }
        }
        
        // 5. Cocô gerado a cada 7200 segundos se alimentado
        let poopRate = 7200.0
        let poopSteps = Int(gameTimeElapsed / poopRate)
        if poopSteps > 0 && hunger > 0 {
            poopCount = min(4, poopCount + poopSteps)
        }
        
        // 6. Doenças e Erros de Cuidado
        // Se a fome for zero, conta tempo e perde saúde
        if hunger == 0 {
            hungerZeroSeconds += gameTimeElapsed
            if hungerZeroSeconds >= 1800.0 {
                careMistakes += 1
                health = max(0, health - 10)
                hungerZeroSeconds = 0 // reseta para o próximo ciclo
            }
        } else {
            hungerZeroSeconds = 0
        }
        
        // Se houver sujeira/cocô, conta tempo e aumenta chance de doença
        if poopCount > 0 {
            dirtySeconds += gameTimeElapsed
            if dirtySeconds >= 3600.0 {
                careMistakes += 1
                isSick = true
                health = max(0, health - 5)
                dirtySeconds = 0
            }
        } else {
            dirtySeconds = 0
        }
        
        // Se estiver doente, perde saúde
        if isSick {
            sickSeconds += gameTimeElapsed
            if sickSeconds >= 3600.0 {
                health = max(0, health - 10)
                sickSeconds = 0
            }
        } else {
            sickSeconds = 0
        }
        
        // Morte por falta de saúde
        if health <= 0 {
            isAlive = false
            return
        }
        
        // 7. Checa evolução
        checkEvolutionConditions()
    }
    
    private mutating func checkEvolutionConditions() {
        switch stage.tier {
        case .baby:
            // Bebê vira criança em 600 segundos (10 minutos)
            if evolutionSeconds >= 600.0 {
                evolve()
            }
        case .child:
            // Criança vira adulto em 3600 segundos (1 hora)
            if evolutionSeconds >= 3600.0 {
                evolve()
            }
        case .adult:
            // Adulto evolui para Perfeito em 7200 segundos (2 horas)
            if evolutionSeconds >= 7200.0 {
                // Precisa ter lutado bastante (vitórias > 5 e percentual > 60%)
                let totalBattles = wins + losses
                let winRate = totalBattles > 0 ? Double(wins) / Double(totalBattles) : 0.0
                if wins >= 5 && winRate >= 0.6 {
                    evolve()
                }
            }
        case .perfect, .egg:
            break
        }
    }
    
    private mutating func evolve() {
        evolutionSeconds = 0 // Reseta o contador para o novo estágio
        
        switch stage {
        // === OVO 1 (FOGO/DRAGÃO) ===
        case .egg1:
            stage = Double.random(in: 0...1) < 0.5 ? .flapor : .pyrop
            weight = 6
        case .flapor:
            stage = hunger >= 3 ? .tomaDrake : .tomaFlaris
            weight = 15
        case .pyrop:
            stage = strength >= 2 ? .tomaIgnis : .tomaCoal
            weight = 15
        case .tomaDrake:
            if careMistakes <= 1 {
                stage = .drakeLord
                weight = 30
            } else if careMistakes >= 4 {
                stage = .shadowDrake
                weight = 25
            } else {
                stage = .pyroBeast
                weight = 28
            }
        case .tomaFlaris:
            if careMistakes <= 1 {
                stage = .solPhoenix
                weight = 30
            } else if careMistakes >= 4 {
                stage = .doomPhoenix
                weight = 25
            } else {
                stage = .gryphFlame
                weight = 28
            }
        case .tomaIgnis:
            if careMistakes <= 1 {
                stage = .ignisShaman
                weight = 30
            } else if careMistakes >= 4 {
                stage = .venomCinder
                weight = 25
            } else {
                stage = .lavaRex
                weight = 28
            }
        case .tomaCoal:
            if careMistakes <= 1 {
                stage = .coalTitan
                weight = 30
            } else if careMistakes >= 4 {
                stage = .slagPile
                weight = 25
            } else {
                stage = .sulfurHound
                weight = 28
            }
        case .drakeLord: stage = .kaiserDrake; weight = 40
        case .pyroBeast: stage = .kaiserBeast; weight = 40
        case .shadowDrake: stage = .diabloDrake; weight = 40
        case .solPhoenix: stage = .astroPhoenix; weight = 40
        case .gryphFlame: stage = .gryphOverlord; weight = 40
        case .doomPhoenix: stage = .necroPhoenix; weight = 40
        case .ignisShaman: stage = .ignisArchmage; weight = 40
        case .lavaRex: stage = .titanosaurus; weight = 40
        case .venomCinder: stage = .basiliskFlame; weight = 40
        case .coalTitan: stage = .omegaTitan; weight = 40
        case .sulfurHound: stage = .cerberusSulfur; weight = 40
        case .slagPile: stage = .plutoSlag; weight = 40

        // === OVO 2 (ÁGUA/GELO) ===
        case .egg2:
            stage = Double.random(in: 0...1) < 0.5 ? .bubble : .drop
            weight = 6
        case .bubble:
            stage = hunger >= 3 ? .aquapup : .finlet
            weight = 15
        case .drop:
            stage = strength >= 2 ? .shelly : .jelly
            weight = 15
        case .aquapup:
            if careMistakes <= 1 {
                stage = .tsunamihound
                weight = 30
            } else if careMistakes >= 4 {
                stage = .deepmaw
                weight = 25
            } else {
                stage = .wavecrest
                weight = 28
            }
        case .finlet:
            if careMistakes <= 1 {
                stage = .aquapegasus
                weight = 30
            } else if careMistakes >= 4 {
                stage = .abysssark
                weight = 25
            } else {
                stage = .coralfin
                weight = 28
            }
        case .shelly:
            if careMistakes <= 1 {
                stage = .tortureshield
                weight = 30
            } else if careMistakes >= 4 {
                stage = .toxicshell
                weight = 25
            } else {
                stage = .reefkraken
                weight = 28
            }
        case .jelly:
            if careMistakes <= 1 {
                stage = .hydromage
                weight = 30
            } else if careMistakes >= 4 {
                stage = .poisonjelly
                weight = 25
            } else {
                stage = .mistwolf
                weight = 28
            }
        case .tsunamihound: stage = .neptunehound; weight = 40
        case .wavecrest: stage = .oceanking; weight = 40
        case .deepmaw: stage = .leviathan; weight = 40
        case .aquapegasus: stage = .poseidonwing; weight = 40
        case .coralfin: stage = .coralemperor; weight = 40
        case .abysssark: stage = .krakenabyss; weight = 40
        case .tortureshield: stage = .aegistortoise; weight = 40
        case .reefkraken: stage = .abyssalkraken; weight = 40
        case .toxicshell: stage = .nukelist; weight = 40
        case .hydromage: stage = .poseidonmage; weight = 40
        case .mistwolf: stage = .fenrirmist; weight = 40
        case .poisonjelly: stage = .hadesjelly; weight = 40

        // === OVO 3 (PLANTA/NATUREZA) ===
        case .egg3:
            stage = Double.random(in: 0...1) < 0.5 ? .seed : .leaf
            weight = 6
        case .seed:
            stage = hunger >= 3 ? .sprout : .thorn
            weight = 15
        case .leaf:
            stage = strength >= 2 ? .flutter : .twig
            weight = 15
        case .sprout:
            if careMistakes <= 1 {
                stage = .woodtitan
                weight = 30
            } else if careMistakes >= 4 {
                stage = .thornviper
                weight = 25
            } else {
                stage = .canopybeast
                weight = 28
            }
        case .thorn:
            if careMistakes <= 1 {
                stage = .bloomdrake
                weight = 30
            } else if careMistakes >= 4 {
                stage = .sporefungus
                weight = 25
            } else {
                stage = .cactusthorn
                weight = 28
            }
        case .flutter:
            if careMistakes <= 1 {
                stage = .sylvanfly
                weight = 30
            } else if careMistakes >= 4 {
                stage = .waspvenom
                weight = 25
            } else {
                stage = .junglehunter
                weight = 28
            }
        case .twig:
            if careMistakes <= 1 {
                stage = .treemage
                weight = 30
            } else if careMistakes >= 4 {
                stage = .rotwight
                weight = 25
            } else {
                stage = .rootbeast
                weight = 28
            }
        case .woodtitan: stage = .yggdrasiltitan; weight = 40
        case .canopybeast: stage = .forestguardian; weight = 40
        case .thornviper: stage = .basiliskwood; weight = 40
        case .bloomdrake: stage = .quetzalcoatl; weight = 40
        case .cactusthorn: stage = .megacactus; weight = 40
        case .sporefungus: stage = .toxicspore; weight = 40
        case .sylvanfly: stage = .monarchfly; weight = 40
        case .junglehunter: stage = .pantherjungle; weight = 40
        case .waspvenom: stage = .hornetempress; weight = 40
        case .treemage: stage = .druidarchmage; weight = 40
        case .rootbeast: stage = .gaiaelemental; weight = 40
        case .rotwight: stage = .necrorot; weight = 40

        case .kaiserDrake, .kaiserBeast, .diabloDrake, .astroPhoenix, .gryphOverlord, .necroPhoenix, .ignisArchmage, .titanosaurus, .basiliskFlame, .omegaTitan, .cerberusSulfur, .plutoSlag,
             .neptunehound, .oceanking, .leviathan, .poseidonwing, .coralemperor, .krakenabyss, .aegistortoise, .abyssalkraken, .nukelist, .poseidonmage, .fenrirmist, .hadesjelly,
             .yggdrasiltitan, .forestguardian, .basiliskwood, .quetzalcoatl, .megacactus, .toxicspore, .monarchfly, .pantherjungle, .hornetempress, .druidarchmage, .gaiaelemental, .necrorot:
            break
        }
        
        // Recupera vida na evolução
        health = 100
        isSick = false
        
        // Desbloqueia a nova forma no álbum
        unlockedStages.insert(stage)
    }
    
    // MARK: - HealthKit Steps Integration
    
    public mutating func applySteps(_ totalSteps: Int) {
        guard isAlive && stage.tier != .egg else { return }
        
        // Se for a primeira inicialização ou passos reiniciados
        if stepsApplied > totalSteps {
            stepsApplied = totalSteps
            return
        }
        
        let newSteps = totalSteps - stepsApplied
        guard newSteps >= 1000 else { return }
        
        let bonuses = newSteps / 1000
        stepsApplied += bonuses * 1000
        
        // A cada 1000 passos:
        // 1. Cura 5 de saúde
        health = min(100, health + (5 * bonuses))
        
        // 2. Limpa cocôs (walked off!)
        if poopCount > 0 {
            poopCount = max(0, poopCount - bonuses)
        }
        
        // 3. Aumenta energia
        energy = min(4, energy + bonuses)
        
        // 4. Ajuda a curar doença (20% de chance por bônus)
        if isSick {
            for _ in 0..<bonuses {
                if Double.random(in: 0...1) < 0.20 {
                    isSick = false
                    sickSeconds = 0
                    break
                }
            }
        }
        
        // 5. Queima calorias (perda de peso)
        weight = max(5, weight - bonuses)
    }
    
    // MARK: - Persistence
    
    public static func load() -> Pet {
        if let data = UserDefaults.standard.data(forKey: "TomaWatchi_PetState") {
            do {
                var pet = try JSONDecoder().decode(Pet.self, from: data)
                // Atualiza o pet com o tempo decorrido
                pet.updateState(currentTime: Date())
                return pet
            } catch {
                print("Failed to decode pet: \(error)")
            }
        }
        return Pet()
    }
    
    public func save() {
        do {
            let data = try JSONEncoder().encode(self)
            UserDefaults.standard.set(data, forKey: "TomaWatchi_PetState")
        } catch {
            print("Failed to encode pet: \(error)")
        }
    }
    
    public static func reset(stage: EvolutionStage = .egg1) -> Pet {
        let pet = Pet(stage: stage)
        pet.save()
        return pet
    }
}
