# Jogos da Mostra — Costa das Baleias (Flutter)

3 jogos + ranking local: **Corrida da Baleia** (ação, boca abrindo, rede, afundamento), **Jogo da Memória** e **Resgate da Baleia**.
Controles da corrida: ↑ ↓ (ou W/S, ou toque/mouse nas 3 faixas), Esc volta.

## Gerar o .exe do Windows
O Flutter só compila para Windows **em um Windows**. Duas formas:

### A) No seu PC com Windows
1. Instale o Flutter (https://docs.flutter.dev/get-started/install/windows) e o Visual Studio 2022 com "Desenvolvimento para desktop com C++".
2. Na pasta do projeto:
```
flutter create --platforms=windows --project-name mostra_baleias .
flutter pub get
flutter analyze
flutter run -d windows        # testar
flutter build windows --release
```
3. O programa fica em `build\windows\x64\runner\Release\` — a pasta inteira (com `mostra_baleias.exe`, `flutter_windows.dll` e `data\`) é o jogo. Copie a pasta toda para o pendrive/PC da escola e dê dois cliques no `.exe`. Não precisa instalar nada nem ter internet.

### B) Sem Windows: pelo GitHub (automático)
1. Crie um repositório no GitHub e envie esta pasta.
2. Aba **Actions → "Gerar .exe para Windows" → Run workflow**.
3. Baixe o artefato `JogosDaMostra-Windows` (zip com o .exe pronto).

### Um único arquivo .exe?
O Flutter gera uma pasta. Para virar **um instalador/arquivo único** use o Inno Setup (grátis) apontando para a pasta `Release`, ou o `msix` (`flutter pub add --dev msix`).

## Dicas
- Nome da janela e ícone: edite `windows\runner\main.cpp` (título) e `windows\runner\resources\app_icon.ico`.
- Tela cheia na mostra: F11 não vem pronto; se quiser, adiciono o pacote `window_manager`.
- Imagens: veja `PROMPTS_IMAGENS_BALEIA.md`. Sem imagens o jogo usa arte desenhada em código.
- Ranking: salvo no próprio computador (shared_preferences). Dá para ligar na API do Calvário/Mgestor depois.
