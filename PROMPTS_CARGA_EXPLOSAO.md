# Imagens da versão 1.8: carga explosiva e explosão

O jogo funciona sem estas imagens (desenha um barril e uma explosão em código). Cada arquivo colocado em `assets/img/` com o nome exato substitui o desenho.
Use o mesmo modelo e o mesmo estilo das imagens que você já gerou (barco, anzol, filhote).

Regras: ilustração digital infantil e educativa, cores vivas, contorno suave, sem texto, sem letras, sem pessoas, sem sangue.
Fundo branco liso e puro, depois rode `python tools/tirar_fundo.py assets/img/ARQUIVO.png` para virar PNG transparente.

Prompt negativo sugerido: `text, letters, watermark, logo, people, faces, blood, gore, realistic photo, dark horror, deformed`

---
## 1. `carga.png` - carga de profundidade (quadrada 1:1)
> A single underwater depth charge, a rounded metal barrel with two dark bands and a yellow warning stripe, a small red warning lamp on top, seen from the side, slightly tilted, sinking in water. Dangerous but child friendly, children's educational digital illustration, vivid colors, soft outline. Plain pure white background, whole object visible, centered, no shadow on the ground, no text. Aspect ratio 1:1.

No jogo aparece com cerca de 84 px, afundando na água. A lâmpada vermelha fica no topo (o jogo ainda pisca um brilho vermelho por cima).

## 2. `explosao.png` - explosão submarina (quadrada 1:1)
> Underwater explosion seen from the side, a round bright burst with a yellow-white core, orange fireball edges, a ring shockwave and many bubbles and small sparks flying outwards, centered, symmetrical, stylized cartoon fire, no debris, no animals, no people. Children's educational digital illustration, vivid colors, soft outline. Plain pure white background, whole effect visible and centered, no text. Aspect ratio 1:1.

O jogo cresce a imagem de pequena a grande (até uns 300 px) e some aos poucos. O centro da imagem é o centro da explosão, por isso deixe-a bem centralizada.

Dica: se o fundo branco atrapalhar no `tirar_fundo.py` (explosão muito clara), peça fundo **verde chroma liso** e me avise que eu adapto o script.
