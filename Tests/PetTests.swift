import XCTest

final class PetTests: XCTestCase {
    
    func testInitialState() {
        let pet = Pet()
        XCTAssertEqual(pet.name, "Toma")
        XCTAssertEqual(pet.stage, .egg1)
        XCTAssertEqual(pet.age, 0)
        XCTAssertEqual(pet.weight, 5)
        XCTAssertEqual(pet.hunger, 2)
        XCTAssertEqual(pet.strength, 1)
        XCTAssertEqual(pet.energy, 4)
        XCTAssertTrue(pet.isAlive)
        XCTAssertFalse(pet.isSick)
        XCTAssertFalse(pet.isSleeping)
        XCTAssertEqual(pet.poopCount, 0)
    }
    
    func testFeedingMeal() {
        var pet = Pet()
        pet.stage = .flapor
        pet.hunger = 2
        let initialWeight = pet.weight
        
        pet.feedMeal()
        
        XCTAssertEqual(pet.hunger, 3)
        XCTAssertEqual(pet.weight, initialWeight + 1)
    }
    
    func testFeedingMealCap() {
        var pet = Pet()
        pet.stage = .flapor
        pet.hunger = 4
        let initialWeight = pet.weight
        
        pet.feedMeal()
        
        XCTAssertEqual(pet.hunger, 4)
        XCTAssertEqual(pet.weight, initialWeight) // Não come se estiver cheio
    }
    
    func testFeedingVitamin() {
        var pet = Pet()
        pet.stage = .flapor
        pet.strength = 1
        let initialWeight = pet.weight
        
        pet.feedVitamin()
        
        XCTAssertEqual(pet.strength, 2)
        XCTAssertEqual(pet.weight, initialWeight + 2)
    }
    
    func testCleaningPoop() {
        var pet = Pet()
        pet.stage = .flapor
        pet.poopCount = 3
        
        pet.cleanPoop()
        
        XCTAssertEqual(pet.poopCount, 0)
    }
    
    func testTrainSuccess() {
        var pet = Pet()
        pet.stage = .flapor
        pet.strength = 1
        pet.energy = 4
        pet.weight = 10
        let initialWeight = pet.weight
        
        pet.train(success: true)
        
        XCTAssertEqual(pet.strength, 2)
        XCTAssertEqual(pet.energy, 3)
        XCTAssertEqual(pet.weight, initialWeight - 1)
    }
    
    func testTrainFail() {
        var pet = Pet()
        pet.stage = .flapor
        pet.strength = 1
        pet.energy = 4
        pet.weight = 10
        let initialWeight = pet.weight
        
        pet.train(success: false)
        
        XCTAssertEqual(pet.strength, 1) // Força não sobe
        XCTAssertEqual(pet.energy, 3) // Consome energia
        XCTAssertEqual(pet.weight, initialWeight - 2) // Queima mais calorias
    }
    
    func testToggleSleep() {
        var pet = Pet()
        pet.stage = .flapor
        pet.energy = 0
        XCTAssertFalse(pet.isSleeping)
        
        pet.toggleSleep()
        
        XCTAssertTrue(pet.isSleeping)
        XCTAssertEqual(pet.energy, 4) // Recupera energia ao dormir
        
        pet.toggleSleep()
        XCTAssertFalse(pet.isSleeping)
    }
    
    func testEvolutionFromEggToBaby() {
        var pet = Pet(timeMultiplier: 1.0)
        let initialDate = pet.lastUpdateTime
        
        // Simula 65 segundos passados
        let hatchDate = initialDate.addingTimeInterval(65)
        pet.updateState(currentTime: hatchDate)
        
        XCTAssertTrue(pet.stage == .flapor || pet.stage == .pyrop)
        XCTAssertEqual(pet.weight, 6)
        XCTAssertEqual(pet.evolutionSeconds, 0)
    }
    
    func testEvolutionFromBabyToChild() {
        var pet = Pet(timeMultiplier: 1.0)
        let initialDate = pet.lastUpdateTime
        
        // Choca primeiro (forçamos para flapor e fome alta)
        pet.updateState(currentTime: initialDate.addingTimeInterval(65))
        pet.stage = .flapor
        pet.hunger = 4
        
        // Simula 605 segundos no estágio de bebê (precisa de 600s para evoluir)
        pet.updateState(currentTime: initialDate.addingTimeInterval(65 + 605))
        
        XCTAssertTrue(pet.stage == .tomaDrake || pet.stage == .tomaFlaris)
        XCTAssertEqual(pet.weight, 15)
    }
    
    func testEvolutionFromChildToAdultGood() {
        var pet = Pet(timeMultiplier: 1.0)
        let initialDate = pet.lastUpdateTime
        
        // Passa ovo -> bebê -> criança
        pet.updateState(currentTime: initialDate.addingTimeInterval(65))
        pet.stage = .tomaDrake
        
        // Prepara atributos para boa evolução (sem negligência, força alta)
        pet.strength = 4
        pet.careMistakes = 0
        
        // Criança vira adulto em 3600 segundos
        pet.updateState(currentTime: initialDate.addingTimeInterval(65 + 3605))
        
        XCTAssertEqual(pet.stage, .drakeLord)
        XCTAssertEqual(pet.weight, 30)
    }
    
    func testHungerDecay() {
        var pet = Pet(timeMultiplier: 1.0)
        let initialDate = pet.lastUpdateTime
        
        // Choca o ovo primeiro
        pet.updateState(currentTime: initialDate.addingTimeInterval(65))
        pet.hunger = 4
        
        // Simula 1805 segundos passados (decaimento a cada 1800s)
        pet.updateState(currentTime: initialDate.addingTimeInterval(65 + 1805))
        
        XCTAssertEqual(pet.hunger, 3)
    }
    
    func testHealthDecayAndDeath() {
        var pet = Pet(timeMultiplier: 1.0)
        let initialDate = pet.lastUpdateTime
        
        // Choca o ovo
        pet.updateState(currentTime: initialDate.addingTimeInterval(65))
        pet.hunger = 0
        pet.health = 10
        
        // Fome zero reduz a vida em 10 pontos a cada 1800 segundos
        pet.updateState(currentTime: initialDate.addingTimeInterval(65 + 1805))
        
        XCTAssertEqual(pet.health, 0)
        XCTAssertFalse(pet.isAlive)
    }
    
    func testSaveAndLoad() {
        var pet = Pet(name: "TestPet")
        pet.stage = .tomaDrake
        pet.hunger = 1
        pet.save()
        
        let loadedPet = Pet.load()
        XCTAssertEqual(loadedPet.name, "TestPet")
        XCTAssertEqual(loadedPet.stage, .tomaDrake)
        XCTAssertEqual(loadedPet.hunger, 1)
    }
    
    func testApplySteps() {
        var pet = Pet()
        pet.stage = .tomaDrake
        pet.stepsApplied = 0
        pet.health = 50
        pet.poopCount = 2
        pet.energy = 2
        pet.weight = 15
        pet.isSick = true
        
        // Aplica 2000 passos (deve gerar 2 bônus)
        pet.applySteps(2000)
        
        XCTAssertEqual(pet.stepsApplied, 2000)
        XCTAssertEqual(pet.health, 60) // 50 + 5 * 2
        XCTAssertEqual(pet.poopCount, 0) // Limpou os 2 cocôs
        XCTAssertEqual(pet.energy, 4) // 2 + 2
        XCTAssertEqual(pet.weight, 13) // 15 - 2
    }
    
    func testWeatherDecay() {
        // Clima chuvoso: decaimento de energia é 1.5x mais rápido
        var petRainy = Pet(timeMultiplier: 1.0)
        petRainy.weather = .rainy
        petRainy.stage = .tomaDrake
        petRainy.energy = 4
        
        // Clima nevoso: decaimento de fome é 1.5x mais rápido
        var petSnowy = Pet(timeMultiplier: 1.0)
        petSnowy.weather = .snowy
        petSnowy.stage = .tomaDrake
        petSnowy.hunger = 4
        
        let initialDate = petRainy.lastUpdateTime
        
        // Com 1205 segundos (normal seria 1800s):
        // Sob Snowy (1.5x), o tempo de fome decai em 1800 / 1.5 = 1200 segundos.
        petSnowy.updateState(currentTime: initialDate.addingTimeInterval(1205))
        XCTAssertEqual(petSnowy.hunger, 3)
        
        // Sob Rainy (1.5x), o decaimento de energia normal a cada 7200s drena em 7200 / 1.5 = 4800s.
        // Se passarmos 4805 segundos:
        var petRainy2 = Pet(timeMultiplier: 1.0)
        petRainy2.weather = .rainy
        petRainy2.stage = .tomaDrake
        petRainy2.energy = 4
        let initialDate2 = petRainy2.lastUpdateTime
        
        petRainy2.updateState(currentTime: initialDate2.addingTimeInterval(4805))
        XCTAssertEqual(petRainy2.energy, 3) // Deve ter decaído de 4 para 3
    }
    
    func testCiclopediaUnlock() {
        var pet = Pet(timeMultiplier: 1.0)
        XCTAssertTrue(pet.unlockedStages.contains(.egg1))
        
        let initialDate = pet.lastUpdateTime
        
        // Ovo -> Bebê
        pet.updateState(currentTime: initialDate.addingTimeInterval(65))
        XCTAssertTrue(pet.unlockedStages.contains(.flapor) || pet.unlockedStages.contains(.pyrop))
        
        // Bebê -> Criança (forçando flapor e fome alta)
        pet.stage = .flapor
        pet.hunger = 4
        pet.updateState(currentTime: initialDate.addingTimeInterval(65 + 605))
        XCTAssertTrue(pet.unlockedStages.contains(.tomaDrake) || pet.unlockedStages.contains(.tomaFlaris))
    }
    
    func testEvolutionEgg2() {
        var pet = Pet(stage: .egg2, timeMultiplier: 1.0)
        let initialDate = pet.lastUpdateTime
        
        // Ovo 2 -> choca em Bubble ou Drop
        pet.updateState(currentTime: initialDate.addingTimeInterval(65))
        XCTAssertTrue(pet.stage == .bubble || pet.stage == .drop)
        
        // Se for Bubble com fome alta, deve evoluir para aquapup
        pet.stage = .bubble
        pet.hunger = 4
        pet.updateState(currentTime: initialDate.addingTimeInterval(65 + 605))
        XCTAssertEqual(pet.stage, .aquapup)
        
        // Se for aquapup com 0 erros de cuidado, deve evoluir para tsunamihound
        pet.careMistakes = 0
        pet.updateState(currentTime: initialDate.addingTimeInterval(65 + 605 + 3605))
        XCTAssertEqual(pet.stage, .tsunamihound)
        
        // tsunamihound com 5 vitorias deve evoluir para neptunehound
        pet.wins = 5
        pet.losses = 0
        pet.updateState(currentTime: initialDate.addingTimeInterval(65 + 605 + 3605 + 7205))
        XCTAssertEqual(pet.stage, .neptunehound)
    }
    
    func testEvolutionEgg3() {
        var pet = Pet(stage: .egg3, timeMultiplier: 1.0)
        let initialDate = pet.lastUpdateTime
        
        // Ovo 3 -> choca em Seed ou Leaf
        pet.updateState(currentTime: initialDate.addingTimeInterval(65))
        XCTAssertTrue(pet.stage == .seed || pet.stage == .leaf)
        
        // Se for Seed com pouca comida (fome baixa), evolui para thorn
        pet.stage = .seed
        pet.hunger = 1
        pet.updateState(currentTime: initialDate.addingTimeInterval(65 + 605))
        XCTAssertEqual(pet.stage, .thorn)
        
        // Se for thorn com cuidado ruim (careMistakes >= 4), evolui para sporefungus
        pet.careMistakes = 5
        pet.updateState(currentTime: initialDate.addingTimeInterval(65 + 605 + 3605))
        XCTAssertEqual(pet.stage, .sporefungus)
        
        // sporefungus evolui para toxicspore
        pet.wins = 10
        pet.losses = 1
        pet.updateState(currentTime: initialDate.addingTimeInterval(65 + 605 + 3605 + 7205))
        XCTAssertEqual(pet.stage, .toxicspore)
    }
}
