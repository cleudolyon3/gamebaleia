# Jogos da Mostra — Costa das Baleias (Flutter)

3 jogos + ranking local: **Corrida da Baleia** (ação em 3 fases), **Jogo da Memória** e **Resgate da Baleia**.
Controles da corrida: ↑ ↓ (ou W/S, ou toque/mouse nas 3 faixas), Esc volta.

## Novidades da versão 1.1 (Corrida da Baleia)
- **3 fases**: 1) Águas de Abrolhos, 2) Mar Aberto, 3) Rota dos Navios. Cada fase tem 3 perguntas, fica mais escura, mais rápida e mais difícil. Ao concluir uma fase há bônus de pontos e a baleia recupera 1 vida.
- **Navios com anzol** (fases 2 e 3, poucos): o navio passa na superfície e baixa o anzol até uma certa altura. Se a baleia bater no anzol, é **pescada** (fim de jogo). O escudo quebra o anzol. Sempre sobra uma faixa livre embaixo da ponta do anzol.
- **Filhote**: nada atrás da mãe. A primeira batida em rede ou saco faz a baleia **perder o filhote** (sem perder vida). Depois disso, cada batida tira 1 vida. Terminar com o filhote dá **+500 pontos**, e cada fase concluída com ele dá +150 de bônus.
- **Mais ação**: cardumes ao fundo, rastro de bolhas, o krill é puxado pela boca, a baleia dá um bote ao morder, riscos de velocidade com combo alto, céu e ondas na superfície, obstáculos duplos na fase 3.
- **Ranking**: a tela de ranking agora tem abas (Geral, Corrida, Memória e Resgate) e o botão Limpar pede confirmação. Os placares antigos são mantidos (mesma chave e mesmo nome de jogo).

## Imagens e vídeos incluídos (versão 1.2)
- Em `assets/img/`: `filhote.png`, `anzol.png`, `barco.png`, `fundo_mar2.jpg` (fase 2) e `fundo_mar3.jpg` (fase 3), já tratados (fundo transparente, sem sombra de chão e sem texto no casco).
- Em `videos/`: 4 vídeos para projetar na mostra (mãe e filhote, navio lançando o anzol, filhote se perdendo e chegada em Abrolhos). Não entram no jogo nem no .exe; abra no player do computador da exposição.
- Falta só uma imagem opcional: `saco_plastico.png` (veja o prompt 6 em `PROMPTS_IMAGENS_BALEIA.md`). Sem ela o jogo desenha o saco em código.

## Sons (versão 1.2)
Sons originais em `assets/audio/` (gerados por `python tools/gerar_sons.py`, sem direitos autorais): mar de fundo, canto de baleia, golfinho, tensão do navio, comer krill, acerto, erro, batida, filhote perdido, anzol, pescada, fase concluída e vitória.
- A baleia e o golfinho aparecem de vez em quando durante a corrida, e o golfinho também comemora cada fase concluída.
- Quando um navio entra na tela começa uma batida grave de tensão, que para quando o anzol passa.
- Botão de som no canto da tela ou tecla **M** para silenciar (útil na mostra).
- Para usar gravações reais, troque o `.wav` pelo mesmo nome na pasta (por exemplo, `baleia.wav` e `golfinho.wav` de um banco de sons livre, conferindo a licença). O tema do filme "Tubarão" é música protegida e não foi usado.
- Depois de atualizar, rode `flutter pub get` (novo pacote `audioplayers`).

### Ajustes rápidos (topo de `lib/corrida.dart`)
- `_anzolMata = true`: anzol pesca a baleia na hora. Mude para `false` para o anzol tirar só 1 vida.
- `_metas`, `_velBase`, `_pObst`, `_espMin`, `_espVar`: acertos por fase, velocidade, chance de obstáculos e intervalo entre objetos.
- Frequência dos navios: `proxNavio` em `_iniciarFase` e em `_navios`.

### Para não perder o ranking ao atualizar
O ranking fica na pasta do usuário do Windows (AppData), não na pasta do jogo. Então: gere o novo .exe com o **mesmo nome de projeto (`mostra_baleias`)**, rode no **mesmo computador e no mesmo usuário do Windows** e substitua só a pasta do jogo. Copiar o jogo para outro PC começa com ranking vazio.
Nunca mude a chave `ranking_v1` nem o nome `'Corrida da Baleia'` em `placar.dart` e `corrida.dart`.


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
- Imagens: veja `PROMPTS_IMAGENS_BALEIA.md` e, para a versão 1.1 (filhote, anzol, navio, fundos das fases), `PROMPTS_LEONARDO_V2.md`. Sem imagens o jogo usa arte desenhada em código.
- Ranking: salvo no próprio computador (shared_preferences). Dá para ligar na API do Calvário/Mgestor depois.

## Versão 1.4

**Teclado em tudo**
- Menu: ↑ ↓ escolhem, Enter abre (o item "Nome" abre a digitação).
- Corrida: ↑ ↓ mudam de faixa. Na pergunta: ↑ ↓ escolhem, Enter confirma (ou 1, 2, 3). Enter continua. M liga/desliga o som. Esc volta.
- Memória: setas movem o cursor, Enter vira a carta.
- Resgate: ↑ ↓ escolhem, Enter confirma (ou 1 a 4), Enter continua.
- Ranking: ← → trocam de aba, Esc volta.

**Filhote (aparece uma vez por partida)**
- A mãe começa com o filhote ao lado. Batidas em rede ou saco tiram vidas só de quem você controla.
- Se a mãe perde as vidas ou é pescada, o filhote assume (2 vidas, menor).
- Cada krill comido faz o filhote crescer. Com 20 krill ele vira baleia adulta e ganha 1 vida.
- Se o filhote for perdido, o jogo acaba. Chegar ao fim com filhote dá +500 (+300 se ele cresceu).
- Ajustes em corrida.dart: `_krillMeta`, `_vidasFilhote`.

**Ranking em arquivo, sem opção de apagar**
- Foi removido o botão de limpar.
- Cada partida grava `ranking_mostra.json` ao lado do .exe e em `%APPDATA%\JogosDaMostra`, além do armazenamento antigo (o ranking das versões anteriores continua).
- Ao abrir, as três fontes são unidas. Para guardar o ranking, copie o arquivo `ranking_mostra.json`.

## Versão 1.5
- **Corrida da Baleia fechava o jogo inteiro no Windows**: o áudio criava e destruía players o tempo todo (o que derruba o `audioplayers` no Windows). Agora `lib/som.dart` usa um conjunto fixo de players reaproveitados, sem destruir nada; se o áudio falhar, o jogo segue sem som.
- **Nome do jogador**: o campo fica sempre aberto no topo do menu (basta digitar). Enter ou seta para baixo vai para os jogos; o nome é salvo ao digitar.

## Versão 1.6
- **Áudio removido** (sem o pacote `audioplayers` e sem `assets/audio`): no Windows da escola o plugin de som pedia senha de administrador e bloqueava o jogo. `lib/som.dart` ficou como um stub vazio, então o resto do código continua igual.

## Versão 1.7 — mais difícil
- **Mais barcos**: aparecem já na fase 1 e passam bem mais vezes nas fases 2 e 3; o anzol desce mais rápido a cada fase.
- **Profundidade do anzol varia** a cada barco (às vezes só a faixa de cima é atingida, às vezes as duas de cima). A faixa de baixo sempre fica livre.
- **Rede de arrasto**: rara, **uma única vez por partida** (fase 2 ou 3, sorteada). Um barco puxa uma rede que cobre 2 faixas e **deixa só 1 faixa livre** (sorteada), marcada em verde e com uma seta. Se a baleia estiver numa faixa coberta quando a rede passar, é pescada (o escudo rasga a rede).
