"""Remove o fundo branco das imagens (png/jpg/webp) em assets/img e salva como PNG transparente.
Uso:  python tools/tirar_fundo.py assets/img/baleia_fechada.png [outras...]
Precisa:  pip install pillow numpy scipy
"""
import sys
import numpy as np
from PIL import Image
from scipy import ndimage

for caminho in sys.argv[1:]:
    im = Image.open(caminho).convert("RGBA")
    a = np.array(im)
    branco = (a[..., :3] > 235).all(axis=-1)
    rot, n = ndimage.label(branco)
    borda = set(rot[0, :]) | set(rot[-1, :]) | set(rot[:, 0]) | set(rot[:, -1])
    borda.discard(0)
    fundo = np.isin(rot, list(borda))
    fundo = ndimage.binary_dilation(fundo, iterations=1) & branco
    a[fundo, 3] = 0
    saida = caminho.rsplit(".", 1)[0] + ".png"
    Image.fromarray(a).save(saida)
    print("ok:", saida)
