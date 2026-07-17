import Foundation

public enum EvolutionTier: String, Codable, CaseIterable {
    case egg = "Ovo"
    case baby = "Bebê"
    case child = "Criança"
    case adult = "Adulto"
    case perfect = "Perfeito"
}

public enum EvolutionStage: String, Codable, CaseIterable {
    // MARK: - OVO #1 (Fogo/Dragão)
    case egg1 = "Ovo de Fogo"
    case flapor = "Flapor"
    case pyrop = "Pyrop"
    case tomaDrake = "TomaDrake"
    case tomaFlaris = "TomaFlaris"
    case tomaIgnis = "TomaIgnis"
    case tomaCoal = "TomaCoal"
    
    // Adultos Ovo 1
    case drakeLord = "DrakeLord"
    case pyroBeast = "PyroBeast"
    case shadowDrake = "ShadowDrake"
    case solPhoenix = "SolPhoenix"
    case gryphFlame = "GryphFlame"
    case doomPhoenix = "DoomPhoenix"
    case ignisShaman = "IgnisShaman"
    case lavaRex = "LavaRex"
    case venomCinder = "VenomCinder"
    case coalTitan = "CoalTitan"
    case sulfurHound = "SulfurHound"
    case slagPile = "SlagPile"
    
    // Perfeitos Ovo 1
    case kaiserDrake = "KaiserDrake"
    case kaiserBeast = "KaiserBeast"
    case diabloDrake = "DiabloDrake"
    case astroPhoenix = "AstroPhoenix"
    case gryphOverlord = "GryphOverlord"
    case necroPhoenix = "NecroPhoenix"
    case ignisArchmage = "IgnisArchmage"
    case titanosaurus = "Titanosaurus"
    case basiliskFlame = "BasiliskFlame"
    case omegaTitan = "OmegaTitan"
    case cerberusSulfur = "CerberusSulfur"
    case plutoSlag = "PlutoSlag"
    
    // MARK: - OVO #2 (Água/Gelo)
    case egg2 = "Ovo de Água"
    case bubble = "Bubble"
    case drop = "Drop"
    case aquapup = "Aquapup"
    case finlet = "Finlet"
    case shelly = "Shelly"
    case jelly = "Jelly"
    
    // Adultos Ovo 2
    case tsunamihound = "TsunamiHound"
    case wavecrest = "WaveCrest"
    case deepmaw = "DeepMaw"
    case aquapegasus = "AquaPegasus"
    case coralfin = "CoralFin"
    case abysssark = "AbyssSark"
    case tortureshield = "TortureShield"
    case reefkraken = "ReefKraken"
    case toxicshell = "ToxicShell"
    case hydromage = "HydroMage"
    case mistwolf = "MistWolf"
    case poisonjelly = "PoisonJelly"
    
    // Perfeitos Ovo 2
    case neptunehound = "NeptuneHound"
    case oceanking = "OceanKing"
    case leviathan = "Leviathan"
    case poseidonwing = "PoseidonWing"
    case coralemperor = "CoralEmperor"
    case krakenabyss = "KrakenAbyss"
    case aegistortoise = "AegisTortoise"
    case abyssalkraken = "AbyssalKraken"
    case nukelist = "NukeList"
    case poseidonmage = "PoseidonMage"
    case fenrirmist = "FenrirMist"
    case hadesjelly = "HadesJelly"
    
    // MARK: - OVO #3 (Planta/Natureza)
    case egg3 = "Ovo da Natureza"
    case seed = "Seed"
    case leaf = "Leaf"
    case sprout = "Sprout"
    case thorn = "Thorn"
    case flutter = "Flutter"
    case twig = "Twig"
    
    // Adultos Ovo 3
    case woodtitan = "WoodTitan"
    case canopybeast = "CanopyBeast"
    case thornviper = "ThornViper"
    case bloomdrake = "BloomDrake"
    case cactusthorn = "CactusThorn"
    case sporefungus = "SporeFungus"
    case sylvanfly = "SylvanFly"
    case junglehunter = "JungleHunter"
    case waspvenom = "WaspVenom"
    case treemage = "TreeMage"
    case rootbeast = "RootBeast"
    case rotwight = "RotWight"
    
    // Perfeitos Ovo 3
    case yggdrasiltitan = "YggdrasilTitan"
    case forestguardian = "ForestGuardian"
    case basiliskwood = "BasiliskWood"
    case quetzalcoatl = "Quetzalcoatl"
    case megacactus = "MegaCactus"
    case toxicspore = "ToxicSpore"
    case monarchfly = "MonarchFly"
    case pantherjungle = "PantherJungle"
    case hornetempress = "HornetEmpress"
    case druidarchmage = "DruidArchmage"
    case gaiaelemental = "GaiaElemental"
    case necrorot = "NecroRot"
    
    // MARK: - Tier Mapping
    public var tier: EvolutionTier {
        switch self {
        case .egg1, .egg2, .egg3:
            return .egg
        case .flapor, .pyrop, .bubble, .drop, .seed, .leaf:
            return .baby
        case .tomaDrake, .tomaFlaris, .tomaIgnis, .tomaCoal,
             .aquapup, .finlet, .shelly, .jelly,
             .sprout, .thorn, .flutter, .twig:
            return .child
        case .drakeLord, .pyroBeast, .shadowDrake, .solPhoenix, .gryphFlame, .doomPhoenix, .ignisShaman, .lavaRex, .venomCinder, .coalTitan, .sulfurHound, .slagPile,
             .tsunamihound, .wavecrest, .deepmaw, .aquapegasus, .coralfin, .abysssark, .tortureshield, .reefkraken, .toxicshell, .hydromage, .mistwolf, .poisonjelly,
             .woodtitan, .canopybeast, .thornviper, .bloomdrake, .cactusthorn, .sporefungus, .sylvanfly, .junglehunter, .waspvenom, .treemage, .rootbeast, .rotwight:
            return .adult
        case .kaiserDrake, .kaiserBeast, .diabloDrake, .astroPhoenix, .gryphOverlord, .necroPhoenix, .ignisArchmage, .titanosaurus, .basiliskFlame, .omegaTitan, .cerberusSulfur, .plutoSlag,
             .neptunehound, .oceanking, .leviathan, .poseidonwing, .coralemperor, .krakenabyss, .aegistortoise, .abyssalkraken, .nukelist, .poseidonmage, .fenrirmist, .hadesjelly,
             .yggdrasiltitan, .forestguardian, .basiliskwood, .quetzalcoatl, .megacactus, .toxicspore, .monarchfly, .pantherjungle, .hornetempress, .druidarchmage, .gaiaelemental, .necrorot:
            return .perfect
        }
    }
    
    public var displayName: String {
        return self.rawValue
    }
}
