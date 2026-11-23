# Imagens do jogo "Costa das Baleias" (opcionais)

O jogo **já funciona sem nenhuma imagem** (a baleia, a rede, o barco etc. são desenhados em código).
Cada imagem que você gerar e colocar em `assets/img/` **substitui automaticamente** o desenho correspondente.
Não precisa gerar todas de uma vez.

## Regras (valem para todos os prompts)
- Estilo: ilustração digital infantil/educativa, cores vivas, contornos suaves, luz de mar tropical (Bahia).
- **Sem texto, sem letras, sem logotipos, sem marcas.**
- Pessoas, se aparecerem, **só silhuetas sem rosto**.
- Objetos "recortáveis" (baleia, rede, saco, krill, barco): **fundo branco liso e puro**, objeto inteiro, sem sombra no chão.
  Depois rode `python tools/tirar_fundo.py assets/img/ARQUIVO.png` para virar PNG transparente.

---
## 1. `baleia_fechada.png` — baleia nadando, boca fechada
> Baleia jubarte vista de lado, virada para a DIREITA, nadando, boca fechada, corpo cinza-azulado escuro com barriga clara com sulcos, nadadeira peitoral longa, calombos no focinho, olho pequeno e simpático, cauda levemente curvada. Ilustração digital infantil, cores vivas, contorno suave. Fundo branco liso, objeto inteiro, sem texto. Proporção 2:1 (horizontal).

## 2. `baleia_boca.png` — a mesma baleia com a boca bem aberta
> A MESMA baleia jubarte da imagem anterior, mesmo ângulo, virada para a DIREITA, agora com a boca bem aberta engolindo água: mandíbula inferior abaixada, interior rosado e escuro, língua visível, fileiras de barbatanas (cerdas) no céu da boca. Expressão tranquila (não assustadora). Mesmo tamanho e posição do corpo. Fundo branco liso, sem texto. Proporção 2:1.

*Dica:* gere as duas na mesma conversa/sessão do gerador, pedindo "mesma personagem", para ficarem iguais.

## 3. `fundo_mar.jpg` — cenário da corrida (1920×1080)
> Cenário subaquático horizontal, mar tropical da Costa das Baleias, Bahia: água azul-turquesa com raios de luz vindo da superfície, recife de corais coloridos e areia no fundo, cardumes pequenos ao longe, algas ao longe. Centro e faixa do meio livres (sem objetos grandes), composição ampla e calma para jogo 2D. Sem baleias, sem pessoas, sem texto. 16:9.

## 4. `fundo_menu.jpg` — tela inicial (1920×1080)
> Paisagem do mar de Abrolhos ao amanhecer, visão meio dentro meio fora d'água: céu laranja-rosado, ondas suaves, ilhas pequenas ao fundo, raios de sol entrando na água azul. Espaço livre no centro. Sem pessoas, sem barcos, sem texto. 16:9.

## 5. `rede_cai.png` — obstáculo: rede de pesca
> Rede de pesca emaranhada em formato arredondado, fios bege/amarelados, boias vermelhas pequenas na borda, aspecto ameaçador mas infantil. Vista frontal. Fundo branco liso, sem texto. 1:1.

## 6. `saco_plastico.png` — obstáculo: saco plástico
> Saco plástico transparente flutuando na água, translúcido com reflexos azulados, amassado, alças balançando. Fundo branco liso, sem texto. 1:1.

## 7. `krill.png` — comida (bolinhas de pontos)
> Pequeno grupo de 3 krills (crustáceos minúsculos cor de laranja-rosado) nadando juntos, estilo fofo, olhos pretos. Fundo branco liso. 3:2.

## 8. `barco.png` — barco pesqueiro (aparece quando a baleia é pescada)
> Barco de pesca industrial visto de lado, casco marrom-escuro, cabine branca, guindaste com cabo para içar rede. Estilo ilustração infantil, **sem tripulantes**, sem nome escrito no casco. Fundo branco liso. 2:1.

---
## SEQUÊNCIA DA DERROTA (quando o aluno perde)
No jogo a cena é: **1) a rede cai sobre a baleia → 2) ela é içada pelo barco → 3) a rede abre e ela afunda no escuro.**
Já existe versão desenhada em código; as duas imagens abaixo entram em tela cheia por cima, com fade, deixando a cena mais bonita.

## 9. `baleia_pescada.jpg` — quadro 2 (1920×1080)
> Vista de dentro da água: uma baleia jubarte presa numa grande rede de pesca sendo puxada para a superfície por um cabo, o casco de um barco pesqueiro aparece no alto da imagem, bolhas e raios de luz, clima dramático porém adequado para crianças (sem sangue, sem ferimentos, sem pessoas). Cores azuis frias com a rede amarelada em destaque. Sem texto. 16:9.

## 10. `baleia_afunda.jpg` — quadro 3 (1920×1080)
> Baleia jubarte afundando lentamente em água azul cada vez mais escura, de lado, com pedaços de rede soltos flutuando acima dela, trilha de bolhas subindo, um feixe fraco de luz lá no alto da superfície. Cena triste e silenciosa, adequada para crianças (sem sangue). Predominância de azul-marinho e preto. Sem texto. 16:9.

---
## OPCIONAL — VÍDEO (para projetar na mostra, ex.: Veo, Sora, Runway, Kling)
Os vídeos tocam fora do jogo (ex.: tela da exposição). Use as imagens 1, 9 e 10 como quadros de referência.

**Vídeo A – "A boca da baleia" (6 s):**
> Câmera subaquática fixa, uma baleia jubarte nada em direção à câmera e abre lentamente a boca enorme, cardume de krill é sugado para dentro, raios de luz azuis, movimento suave, estilo ilustração animada infantil, sem texto.

**Vídeo B – "Pescada e afundando" (10 s):**
> Estilo ilustração animada infantil. Plano 1: baleia jubarte nadando calma. Plano 2: uma rede de pesca cai de cima e a envolve. Plano 3: a rede é içada por um cabo até o casco de um barco no alto da tela. Plano 4: o cabo se solta e a baleia afunda lentamente na água escura entre bolhas. Final em azul escuro. Sem pessoas, sem sangue, sem texto.

---
## Onde salvar
Tudo em `assets/img/` com **exatamente** estes nomes: `baleia_fechada`, `baleia_boca`, `fundo_mar`, `fundo_menu`, `rede_cai`, `saco_plastico`, `krill`, `barco`, `baleia_pescada`, `baleia_afunda` (aceita .png, .webp ou .jpg).
Depois: `flutter run -d windows` ou gere o .exe de novo.
