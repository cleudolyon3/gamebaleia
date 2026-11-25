# Imagens e vídeos da versão 1.1 (Leonardo AI)

O jogo funciona sem nenhuma destas imagens. Cada arquivo colocado em `assets/img/` com o nome exato substitui o desenho feito em código.
Use o mesmo modelo e o mesmo estilo das imagens que você já gerou. Se o seu Leonardo tiver **Style Reference** ou **Character Reference**, use a `baleia_fechada.png` atual como referência para o filhote ficar igual à mãe.

Regras para todos os prompts:
- Ilustração digital infantil e educativa, cores vivas, contorno suave, luz de mar tropical da Bahia.
- Sem texto, sem letras, sem logotipos, sem marcas.
- Sem pessoas (se aparecerem, só silhueta sem rosto) e sem sangue.
- Objetos recortáveis (filhote, anzol, navio): **fundo branco liso e puro**, objeto inteiro. Depois rode `python tools/tirar_fundo.py assets/img/ARQUIVO.png` para virar PNG transparente.
- Os prompts estão em inglês porque o Leonardo costuma responder melhor assim.

Prompt negativo sugerido para todos (campo "Negative Prompt"):
`text, letters, watermark, logo, people, faces, blood, gore, realistic photo, dark horror, deformed, extra fins`

---
## 1. `filhote.png` - filhote de baleia jubarte (2:1)
> Cute baby humpback whale calf seen from the side, facing RIGHT, swimming, mouth closed, small rounded body, soft blue-gray back and light belly with grooves, tiny pectoral fin, big friendly eye, tiny bumps on the snout, playful and adorable. Children's educational digital illustration, vivid colors, soft outline, same style as an adult humpback whale illustration. Plain pure white background, whole object visible, no shadow on the ground, no text. Aspect ratio 2:1.

No jogo ele aparece atrás e embaixo da mãe, com uns 120 px de largura.

## 2. `anzol.png` - anzol com linha (proporção 3:4, vertical)
> A single large metal fishing hook hanging from a thin fishing line, seen from the front, vertical composition, the line enters from the top center and the J-shaped hook curves at the bottom with a sharp barb, shiny silver metal with subtle highlights, slightly threatening but friendly children's educational illustration style, vivid colors, soft outline. Plain pure white background, whole object visible, no text. Aspect ratio 3:4.

A ponta do anzol é o ponto mais baixo da imagem. O jogo já desenha a linha, então o anzol pode ter só um pedaço curto de linha no topo.

## 3. `barco.png` - navio de pesca visto de lado (substitui o barco antigo) (2:1)
> Industrial fishing ship seen from the side, facing LEFT, brown-red hull with a red stripe, white cabin with blue windows and a dark gray chimney, and a tall crane arm sticking out at the LEFT end of the ship, pointing up and to the left, ready to lower a fishing line. The bottom of the hull is flat and cut at the waterline (no water, no waves). No crew, no people, no name written on the hull. Children's educational digital illustration, vivid colors, soft outline. Plain pure white background, whole object visible, no text. Aspect ratio 2:1.

Importante: o navio anda para a esquerda e o anzol sai da ponta do guindaste, no lado esquerdo.

## 4. `fundo_mar2.jpg` - fase 2, Mar Aberto (1920x1080)
> Wide underwater scene of the open tropical ocean, deeper and darker blue than a coral reef, a few light rays coming from far above, scattered small coral rocks and sand far below, distant schools of small fish, clear and calm composition for a 2D side-scrolling game. Center and middle band free of large objects. No whales, no people, no ships, no text. 16:9.

## 5. `fundo_mar3.jpg` - fase 3, Rota dos Navios (1920x1080)
> Wide underwater scene in deep blue water, darker and more mysterious but still child friendly, faint light rays from the surface, a few dark ship hull silhouettes very far away at the top, floating pieces of old fishing net in the distance, plain dark sand far below. Center and middle band free of large objects. No whales, no people, no text. 16:9.

Se você não gerar o `fundo_mar2` e o `fundo_mar3`, o jogo usa o `fundo_mar` com um tom mais escuro em cada fase. O céu e as ondas do topo (até 96 px) são desenhados pelo jogo por cima da imagem.

---
## Vídeos opcionais (para projetar na mostra, fora do jogo)
No Leonardo, use a opção de imagem para vídeo (Motion / Image to Video) com a imagem de referência indicada. Se a sua conta não tiver essa opção, use Veo, Kling, Runway ou Sora com os mesmos textos.

**Vídeo A - "Mãe e filhote" (6 s)**, referência: `baleia_fechada.png` + `filhote.png`
> Underwater side view, a mother humpback whale and her small calf swim side by side from left to right through turquoise water, the calf stays close under the mother's fin, soft light rays, small bubbles, gentle camera drift, children's animated illustration style, calm and warm mood, no text, no people.

**Vídeo B - "O navio lança o anzol" (8 s)**, referência: `barco.png` + `anzol.png`
> Children's animated illustration. A fishing ship crosses the ocean surface from right to left, its crane slowly lowers a shiny fishing hook on a thin line into the deep blue water, the hook sways gently, a mother humpback whale and her calf swim away below the hook. Tense but child friendly mood, no people, no blood, no text.

**Vídeo C - "O filhote se perde" (6 s)**, referência: `filhote.png`
> Children's animated illustration. A baby humpback whale is gently carried away by an ocean current, drifting to the left and slowly fading into the blue water, its mother turns back and calls. Sad and quiet mood, soft lighting, no blood, no people, no text.

**Vídeo D - "Chegada em Abrolhos" (8 s)**, referência: `baleia_fechada.png` + `filhote.png` + `fundo_menu.jpg`
> Children's animated illustration. A mother humpback whale and her calf arrive together at the calm waters of the Abrolhos archipelago at sunrise, both jump out of the water one after the other with soft splashes, golden light, small islands in the background, joyful mood, no text, no people.

## Onde salvar
Tudo em `assets/img/` com **exatamente** estes nomes: `filhote`, `anzol`, `barco`, `fundo_mar2`, `fundo_mar3` (aceita .png, .webp ou .jpg).
Depois: `flutter run -d windows` ou gere o .exe de novo.
