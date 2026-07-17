import SwiftUI
import Network

// MARK: - Battle Message Model
struct BattleMessage: Codable, Equatable {
    let name: String
    let stage: EvolutionStage
    let strength: Int
    let health: Int
    let randomValue: Int
}

// MARK: - NW Peer Model
struct NWPeer: Identifiable, Hashable {
    let id: UUID
    let displayName: String
    let endpoint: NWEndpoint?
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: NWPeer, rhs: NWPeer) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Battle Session Manager (Network Framework P2P Implementation)
class BattleSessionManager: NSObject, ObservableObject {
    @Published var connectedPeers: [NWPeer] = []
    @Published var availablePeers: [NWPeer] = []
    @Published var receivedMessage: BattleMessage? = nil
    @Published var isHosting = false
    @Published var isSearching = false
    
    private var listener: NWListener?
    private var browser: NWBrowser?
    private var connection: NWConnection?
    
    private let displayName: String
    private var pendingLocalMessage: BattleMessage?
    private var myPendingMessage: BattleMessage?
    
    init(displayName: String) {
        self.displayName = displayName.isEmpty ? "Toma" : String(displayName.prefix(15))
        super.init()
    }
    
    deinit {
        stopAll()
    }
    
    func startHosting() {
        stopAll()
        isHosting = true
        
        let parameters = NWParameters.tcp
        parameters.includePeerToPeer = true
        
        do {
            let listener = try NWListener(using: parameters)
            self.listener = listener
            
            listener.service = NWListener.Service(name: displayName, type: "_tomawatchi-btl._tcp")
            
            listener.stateUpdateHandler = { [weak self] state in
                switch state {
                case .failed(let error):
                    print("Listener failed: \(error)")
                    self?.stopAll()
                default:
                    break
                }
            }
            
            listener.newConnectionHandler = { [weak self] newConnection in
                self?.handleIncomingConnection(newConnection)
            }
            
            listener.start(queue: .main)
        } catch {
            print("Failed to create listener: \(error)")
            stopAll()
        }
    }
    
    func startSearching() {
        stopAll()
        isSearching = true
        
        let descriptor = NWBrowser.Descriptor.bonjour(type: "_tomawatchi-btl._tcp", domain: nil)
        let parameters = NWParameters()
        parameters.includePeerToPeer = true
        
        let browser = NWBrowser(for: descriptor, using: parameters)
        self.browser = browser
        
        browser.stateUpdateHandler = { [weak self] state in
            if case .failed(let error) = state {
                print("Browser failed: \(error)")
                self?.stopAll()
            }
        }
        
        browser.browseResultsChangedHandler = { [weak self] results, changes in
            self?.handleBrowseResults(results)
        }
        
        browser.start(queue: .main)
    }
    
    func stopAll() {
        isHosting = false
        isSearching = false
        
        browser?.cancel()
        browser = nil
        
        listener?.cancel()
        listener = nil
        
        connection?.cancel()
        connection = nil
        
        pendingLocalMessage = nil
        myPendingMessage = nil
        
        DispatchQueue.main.async {
            self.connectedPeers.removeAll()
            self.availablePeers.removeAll()
            self.receivedMessage = nil
        }
    }
    
    func connect(to peer: NWPeer) {
        guard let endpoint = peer.endpoint else { return }
        browser?.cancel()
        browser = nil
        
        let parameters = NWParameters.tcp
        parameters.includePeerToPeer = true
        
        let connection = NWConnection(to: endpoint, using: parameters)
        self.connection = connection
        
        connection.stateUpdateHandler = { [weak self] state in
            self?.handleConnectionStateChange(state, connection: connection)
        }
        
        connection.start(queue: .main)
        receiveMessage(from: connection)
        
        DispatchQueue.main.async {
            self.connectedPeers = [peer]
        }
    }
    
    func send(message: BattleMessage) {
        myPendingMessage = message
        guard let connection = connection else {
            pendingLocalMessage = message
            return
        }
        
        do {
            let data = try JSONEncoder().encode(message)
            var size = UInt32(data.count).bigEndian
            let payload = Data(bytes: &size, count: 4) + data
            
            connection.send(content: payload, completion: .contentProcessed({ error in
                if let error = error {
                    print("Send failed: \(error)")
                }
            }))
        } catch {
            print("Failed to encode message: \(error)")
        }
    }
    
    private func handleIncomingConnection(_ newConnection: NWConnection) {
        if connection != nil {
            newConnection.cancel()
            return
        }
        
        self.connection = newConnection
        newConnection.stateUpdateHandler = { [weak self] state in
            self?.handleConnectionStateChange(state, connection: newConnection)
        }
        
        newConnection.start(queue: .main)
        receiveMessage(from: newConnection)
        
        let peer = NWPeer(id: UUID(), displayName: "Rival (Conectando)", endpoint: nil)
        DispatchQueue.main.async {
            self.connectedPeers = [peer]
        }
    }
    
    private func handleConnectionStateChange(_ state: NWConnection.State, connection: NWConnection) {
        switch state {
        case .ready:
            if let pending = pendingLocalMessage {
                send(message: pending)
                pendingLocalMessage = nil
            }
        case .failed(let error):
            print("Connection failed: \(error)")
            stopAll()
        case .cancelled:
            stopAll()
        default:
            break
        }
    }
    
    private func handleBrowseResults(_ results: Set<NWBrowser.Result>) {
        var peers: [NWPeer] = []
        for result in results {
            var name = "Rival"
            if case .service(let serviceName, _, _, _) = result.endpoint {
                name = serviceName
            }
            let peer = NWPeer(id: UUID(), displayName: name, endpoint: result.endpoint)
            peers.append(peer)
        }
        
        DispatchQueue.main.async {
            self.availablePeers = peers
        }
    }
    
    private func receiveMessage(from connection: NWConnection) {
        connection.receive(minimumIncompleteLength: 4, maximumLength: 4) { [weak self] data, context, isComplete, error in
            if let error = error {
                print("Receive header failed: \(error)")
                return
            }
            guard let data = data, data.count == 4 else { return }
            
            let size = data.withUnsafeBytes { $0.load(as: UInt32.self).bigEndian }
            
            connection.receive(minimumIncompleteLength: Int(size), maximumLength: Int(size)) { data, context, isComplete, error in
                if let error = error {
                    print("Receive body failed: \(error)")
                    return
                }
                guard let data = data else { return }
                
                do {
                    let msg = try JSONDecoder().decode(BattleMessage.self, from: data)
                    DispatchQueue.main.async {
                        self?.receivedMessage = msg
                        if self?.isHosting == true {
                            self?.connectedPeers = [NWPeer(id: UUID(), displayName: msg.name, endpoint: nil)]
                        }
                    }
                } catch {
                    print("Failed to decode: \(error)")
                }
            }
        }
    }
}

// MARK: - MultipeerBattleView
public struct MultipeerBattleView: View {
    @Binding public var pet: Pet
    public let pixelColor: Color
    public let onComplete: () -> Void
    
    @StateObject private var manager: BattleSessionManager
    
    // Battle logic states
    @State private var hasSentData = false
    @State private var isFighting = false
    @State private var showResult = false
    @State private var victory = false
    @State private var localRandomValue = Int.random(in: 1...100)
    
    // Animation states
    @State private var petOffset: CGFloat = -40
    @State private var opponentOffset: CGFloat = 40
    @State private var showSword = false
    @State private var frameToggler = 0
    
    public init(pet: Binding<Pet>, pixelColor: Color, onComplete: @escaping () -> Void) {
        self._pet = pet
        self.pixelColor = pixelColor
        self.onComplete = onComplete
        self._manager = StateObject(wrappedValue: BattleSessionManager(displayName: pet.wrappedValue.name))
    }
    
    public var body: some View {
        VStack(spacing: 4) {
            Text("BATALHA P2P")
                .font(.system(.caption, design: .monospaced))
                .bold()
                .foregroundColor(pixelColor)
            
            if manager.connectedPeers.isEmpty {
                // Connection setup screen
                VStack(spacing: 6) {
                    Text("Conectar com Amigos")
                        .font(.system(.footnote, design: .monospaced))
                        .foregroundColor(pixelColor)
                    
                    HStack(spacing: 6) {
                        Button(action: {
                            manager.startHosting()
                        }) {
                            Text("AGUARDAR")
                                .font(.system(.caption2, design: .monospaced))
                                .bold()
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 6)
                                .background(manager.isHosting ? pixelColor : Color.clear)
                                .foregroundColor(manager.isHosting ? (pixelColor == .black ? .white : .black) : pixelColor)
                                .overlay(RoundedRectangle(cornerRadius: 3).stroke(pixelColor, lineWidth: 1))
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        Button(action: {
                            manager.startSearching()
                        }) {
                            Text("PROCURAR")
                                .font(.system(.caption2, design: .monospaced))
                                .bold()
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 6)
                                .background(manager.isSearching ? pixelColor : Color.clear)
                                .foregroundColor(manager.isSearching ? (pixelColor == .black ? .white : .black) : pixelColor)
                                .overlay(RoundedRectangle(cornerRadius: 3).stroke(pixelColor, lineWidth: 1))
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    
                    // Peers List
                    if manager.isSearching {
                        VStack(spacing: 4) {
                            Text("Dispositivos próximos:")
                                .font(.system(.caption2, design: .monospaced))
                                .foregroundColor(pixelColor)
                            
                            if manager.availablePeers.isEmpty {
                                Text("Buscando...")
                                    .font(.system(.footnote, design: .monospaced))
                                    .foregroundColor(pixelColor.opacity(0.5))
                            } else {
                                ScrollView {
                                    ForEach(manager.availablePeers, id: \.self) { peer in
                                        Button(action: {
                                            manager.connect(to: peer)
                                        }) {
                                            HStack {
                                                Text(peer.displayName)
                                                    .font(.system(.caption, design: .monospaced))
                                                Spacer()
                                                Text("Conectar")
                                                    .font(.system(.caption2, design: .monospaced))
                                                    .bold()
                                            }
                                            .foregroundColor(pixelColor)
                                            .padding(4)
                                            .background(RoundedRectangle(cornerRadius: 2).stroke(pixelColor, lineWidth: 1))
                                        }
                                        .buttonStyle(PlainButtonStyle())
                                    }
                                }
                                .frame(maxHeight: 60)
                            }
                        }
                    } else if manager.isHosting {
                        VStack(spacing: 8) {
                            Text("Aguardando desafiante...")
                                .font(.system(.caption2, design: .monospaced))
                                .foregroundColor(pixelColor)
                            ProgressView()
                                .tint(pixelColor)
                        }
                        .frame(maxHeight: 60)
                    } else {
                        Spacer()
                    }
                    
                    Button(action: {
                        manager.stopAll()
                        onComplete()
                    }) {
                        Text("VOLTAR")
                            .font(.system(.body, design: .monospaced))
                            .bold()
                            .padding(.top, 4)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .foregroundColor(pixelColor)
                }
                .frame(maxHeight: .infinity)
            } else if !showResult {
                // Connected / Battle Screening
                VStack(spacing: 8) {
                    Text("CONECTADO COM:")
                        .font(.system(.caption2, design: .monospaced))
                        .foregroundColor(pixelColor)
                    
                    Text(manager.connectedPeers.first?.displayName ?? "Desconhecido")
                        .font(.system(.body, design: .monospaced))
                        .bold()
                        .foregroundColor(pixelColor)
                    
                    if !isFighting {
                        // Pre-fight Sync Screen
                        VStack(spacing: 6) {
                            if !hasSentData {
                                Button(action: {
                                    sendBattleData()
                                }) {
                                    Text("ENVIAR DESAFIO")
                                        .font(.system(.body, design: .monospaced))
                                        .bold()
                                        .padding(.vertical, 6)
                                        .frame(maxWidth: .infinity)
                                        .background(pixelColor)
                                        .foregroundColor(pixelColor == .black ? .white : .black)
                                        .cornerRadius(4)
                                }
                                .buttonStyle(PlainButtonStyle())
                            } else {
                                Text("Aguardando oponente...")
                                    .font(.system(.footnote, design: .monospaced))
                                    .foregroundColor(pixelColor.opacity(0.7))
                            }
                        }
                        .padding(.top, 8)
                        .onChange(of: manager.receivedMessage) { newValue in
                            if hasSentData && newValue != nil {
                                startFightAnimation()
                            }
                        }
                    } else {
                        // Battle Arena
                        VStack {
                            ZStack {
                                // Pet Sprite
                                PixelSpriteView(frame: Sprites.animation(for: pet.stage, frameIndex: frameToggler), pixelColor: pixelColor)
                                    .frame(width: 44, height: 44)
                                    .offset(x: petOffset)
                                
                                // Opponent Sprite
                                if let opponent = manager.receivedMessage {
                                    PixelSpriteView(frame: Sprites.animation(for: opponent.stage, frameIndex: frameToggler + 1), pixelColor: pixelColor)
                                        .frame(width: 44, height: 44)
                                        .offset(x: opponentOffset)
                                        .scaleEffect(x: -1, y: 1)
                                }
                                
                                if showSword {
                                    PixelSpriteView(frame: Sprites.sword, pixelColor: pixelColor)
                                        .frame(width: 28, height: 28)
                                }
                            }
                            .frame(height: 70)
                            
                            Text("LUTANDO...")
                                .font(.system(.footnote, design: .monospaced))
                                .foregroundColor(pixelColor)
                        }
                    }
                }
                .frame(maxHeight: .infinity)
            } else {
                // Result screen
                VStack(spacing: 6) {
                    Text(victory ? "VITÓRIA!" : "DERROTA!")
                        .font(.system(.title3, design: .monospaced))
                        .bold()
                        .foregroundColor(pixelColor)
                    
                    Text("Oponente: \(manager.receivedMessage?.name ?? "Rival")")
                        .font(.system(.caption, design: .monospaced))
                        .foregroundColor(pixelColor)
                    
                    if victory {
                        Text("+1 Força / -1 Energia")
                            .font(.system(.footnote, design: .monospaced))
                            .foregroundColor(pixelColor)
                    } else {
                        Text("-15 Saúde / -2 Energia")
                            .font(.system(.footnote, design: .monospaced))
                            .foregroundColor(pixelColor)
                    }
                    
                    Button(action: {
                        manager.stopAll()
                        onComplete()
                    }) {
                        Text("FECHAR")
                            .font(.system(.body, design: .monospaced))
                            .bold()
                    }
                    .buttonStyle(PlainButtonStyle())
                    .foregroundColor(pixelColor)
                    .padding(.top, 4)
                }
                .frame(maxHeight: .infinity)
            }
        }
    }
    
    private func sendBattleData() {
        let msg = BattleMessage(
            name: pet.name,
            stage: pet.stage,
            strength: pet.strength,
            health: pet.health,
            randomValue: localRandomValue
        )
        manager.send(message: msg)
        hasSentData = true
        
        // If we already received data, we can start immediately
        if manager.receivedMessage != nil {
            startFightAnimation()
        }
    }
    
    private func startFightAnimation() {
        guard let opponent = manager.receivedMessage else { return }
        
        isFighting = true
        petOffset = -40
        opponentOffset = 40
        showSword = false
        
        // Determine fight outcome deterministically based on seed
        let localScore = (pet.strength * 10) + (pet.health / 5) + localRandomValue
        let opponentScore = (opponent.strength * 10) + (opponent.health / 5) + opponent.randomValue
        
        if localScore == opponentScore {
            // Tie breaker
            victory = localRandomValue > opponent.randomValue
        } else {
            victory = localScore > opponentScore
        }
        
        // Apply battle result locally
        if victory {
            pet.wins += 1
            pet.strength = min(4, pet.strength + 1)
            pet.energy = max(0, pet.energy - 1)
            pet.weight = max(5, pet.weight - 1)
        } else {
            pet.losses += 1
            pet.health = max(0, pet.health - 15)
            pet.energy = max(0, pet.energy - 2)
            pet.careMistakes += 1
        }
        pet.save()
        
        animateRound(round: 1)
    }
    
    private func animateRound(round: Int) {
        frameToggler += 1
        
        withAnimation(.easeInOut(duration: 0.3)) {
            petOffset = -15
            opponentOffset = 15
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            showSword = true
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                showSword = false
                
                withAnimation(.easeInOut(duration: 0.2)) {
                    petOffset = -35
                    opponentOffset = 35
                }
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    if round < 3 {
                        animateRound(round: round + 1)
                    } else {
                        // Conclui luta
                        withAnimation {
                            isFighting = false
                            showResult = true
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
