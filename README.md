# TomaWatchi — um bichinho de pulso que cresce com os seus passos

O TomaWatchi é um Tamagotchi para watchOS (com app macOS): os **passos reais do dia**, lidos do HealthKit, cuidam do seu pet. Andou, ele se exercita e evolui; parou, ele enfraquece. Um ovo choca em uma de 93 espécies organizadas em árvore de evolução, com 3 alinhamentos (Vacina, Dados, Vírus) — e dois relógios próximos podem **batalhar entre si** pela rede local, sem internet.

## O que tem de real aqui

- **~5.500 linhas de SwiftUI** em 12 arquivos, organizados por domínio (Model, View) — projeto gerado com **xcodegen** (`project.yml` é a fonte da verdade do `.xcodeproj`).
- **HealthKit**: leitura de passos diários para cura/treino do pet, com as permissões declaradas no `project.yml`.
- **Multipeer Connectivity** para batalha P2P: os relógios se descobrem por Bonjour/Bluetooth na rede local e duelam sem servidor.
- **Árvore de evolução de 93 espécies** (3 ovos × estágios bebê → criança → adulto), documentada em `docs/EVOLUTION.md`.
- **Minigame** como segunda frente de treino, sprites em pixel art renderizados em SwiftUI.

## Como rodar

```bash
# requer Xcode com SDK watchOS 10+ / iOS 17+ / macOS 14+
xcodegen generate          # gera o .xcodeproj a partir do project.yml
open TomaWatchi.xcodeproj  # rode no simulador de watchOS ou no Mac
```

Permissões necessárias: HealthKit (passos), Bluetooth/rede local (batalha P2P).

## Status honesto

Projeto pessoal em desenvolvimento ativo durante 2025 — todo o histórico está no git. Roda em watchOS e macOS; as builds locais foram feitas durante o desenvolvimento. **Não publicado na App Store.**

Stack: Swift, SwiftUI, HealthKit, Multipeer Connectivity, xcodegen.
