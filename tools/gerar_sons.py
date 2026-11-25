"""Gera os sons do jogo (sons originais, criados por código, sem direitos autorais).

Uso:  python tools/gerar_sons.py
Saída: assets/audio/*.wav

Para usar gravações reais (ex.: baleia/golfinho de bancos de som livres), basta
substituir o arquivo .wav com o MESMO nome em assets/audio/.
"""
import os
import wave

import numpy as np

SR = 22050
SAIDA = os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', 'assets', 'audio')
rng = np.random.default_rng(7)


def t_(dur):
    return np.arange(int(SR * dur)) / SR


def norm(x, pico=0.85):
    m = np.max(np.abs(x))
    return x if m == 0 else x / m * pico


def salvar(nome, x):
    os.makedirs(SAIDA, exist_ok=True)
    x = np.clip(x, -1, 1)
    d = (x * 32767).astype('<i2')
    with wave.open(os.path.join(SAIDA, nome + '.wav'), 'wb') as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(SR)
        w.writeframes(d.tobytes())
    print('ok', nome, round(len(x) / SR, 2), 's')


def env(n, a=0.01, r=0.1):
    e = np.ones(n)
    na, nr = int(a * SR), int(r * SR)
    if na > 0:
        e[:na] = np.linspace(0, 1, na)
    if nr > 0:
        e[-nr:] *= np.linspace(1, 0, nr)
    return e


def filtro_ruido(dur, f_baixa, f_alta=0):
    """Ruido filtrado por FFT (periodico, serve para loop sem emenda)."""
    n = int(SR * dur)
    X = np.fft.rfft(rng.standard_normal(n))
    f = np.fft.rfftfreq(n, 1 / SR)
    g = 1 / (1 + (f / f_baixa) ** 4)
    if f_alta > 0:
        g *= 1 / (1 + (f_alta / np.maximum(f, 1e-3)) ** 4)
    return np.fft.irfft(X * g, n)


def glide(f0, f1, dur, vib=0.0, vibf=5.0):
    t = t_(dur)
    f = np.linspace(f0, f1, len(t))
    if vib:
        f = f * (1 + vib * np.sin(2 * np.pi * vibf * t))
    return np.cumsum(2 * np.pi * f / SR)


# ---------------------------------------------------------------- mar (loop de 12 s)
def mar():
    dur = 12
    t = t_(dur)
    base = filtro_ruido(dur, 700, 60)
    # ondas: volume que sobe e desce, com periodos que cabem em 12 s
    onda = 0.55 + 0.25 * np.sin(2 * np.pi * 3 * t / dur) + 0.2 * np.sin(2 * np.pi * 5 * t / dur + 1.3)
    surdo = filtro_ruido(dur, 120, 20) * 1.6
    x = base * onda + surdo * (0.6 + 0.4 * np.sin(2 * np.pi * 2 * t / dur))
    salvar('mar_ambiente', norm(x, 0.7))


# ---------------------------------------------------------------- baleia (canto)
def baleia():
    dur = 5.0
    x = np.zeros(int(SR * dur))
    notas = [(0.0, 0.9, 110, 260), (0.9, 0.8, 260, 190), (1.7, 1.3, 190, 420), (3.0, 1.2, 420, 150), (4.0, 0.9, 150, 95)]
    for ini, d, f0, f1 in notas:
        ph = glide(f0, f1, d, vib=0.015, vibf=6)
        n = len(ph)
        v = np.sin(ph) + 0.5 * np.sin(2 * ph) + 0.28 * np.sin(3 * ph) + 0.12 * np.sin(4 * ph)
        v *= env(n, 0.15, 0.25)
        i = int(ini * SR)
        x[i:i + n] += v[: len(x) - i]
    # eco simples
    eco = np.zeros_like(x)
    for atraso, g in ((0.28, 0.35), (0.55, 0.2)):
        k = int(atraso * SR)
        eco[k:] += x[:-k] * g
    x = norm(x + eco, 0.75)
    salvar('baleia', x)


# ---------------------------------------------------------------- golfinho
def golfinho():
    dur = 2.6
    x = np.zeros(int(SR * dur))
    # assobios (chirps)
    for ini, d, f0, f1 in ((0.05, 0.35, 2800, 6200), (0.5, 0.25, 5800, 3200), (0.85, 0.4, 3000, 6800)):
        ph = glide(f0, f1, d, vib=0.03, vibf=30)
        v = (np.sin(ph) + 0.25 * np.sin(2 * ph)) * env(len(ph), 0.02, 0.06)
        i = int(ini * SR)
        x[i:i + len(v)] += v * 0.7
    # cliques (trem de estalos que acelera)
    pos = 1.5
    gap = 0.11
    while pos < 2.5:
        i = int(pos * SR)
        n = int(0.012 * SR)
        click = rng.standard_normal(n) * np.exp(-np.linspace(0, 9, n))
        click = np.convolve(click, np.ones(3) / 3, mode='same')
        x[i:i + n] += click * 0.9
        pos += gap
        gap = max(0.018, gap * 0.82)
    salvar('golfinho', norm(x, 0.8))


# ---------------------------------------------------------------- tensao (loop de 3 s, original)
def tensao():
    dur = 3.0
    t = t_(dur)
    x = np.zeros(len(t))
    # batidas graves em dois tempos, que vao ficando mais rapidas dentro do loop
    for pos, g in ((0.0, 1.0), (0.38, 0.7), (1.5, 1.0), (1.85, 0.7), (2.4, 0.8), (2.65, 0.6), (2.85, 0.5)):
        i = int(pos * SR)
        n = int(0.32 * SR)
        tt = np.arange(n) / SR
        thump = np.sin(2 * np.pi * (62 - 22 * tt / 0.32) * tt) * np.exp(-tt * 9)
        x[i:i + n] += thump[: len(x) - i] * g
    # zumbido grave continuo
    x += 0.22 * np.sin(2 * np.pi * 41 * t) * (0.7 + 0.3 * np.sin(2 * np.pi * t / dur))
    x += 0.07 * np.sin(2 * np.pi * 82.4 * t + 0.5)
    salvar('tensao', norm(x, 0.8))


# ---------------------------------------------------------------- efeitos curtos
def come():
    d = 0.16
    ph = glide(320, 980, d)
    x = np.sin(ph) * np.exp(-t_(d) * 14)
    salvar('come', norm(x, 0.7))


def poder():
    d = 0.45
    ph = glide(500, 1800, d)
    x = (np.sin(ph) + 0.4 * np.sin(2 * ph)) * env(len(ph), 0.01, 0.2)
    salvar('poder', norm(x, 0.65))


def acerto():
    x = np.zeros(int(SR * 0.7))
    for i, f in enumerate((523.25, 659.25, 783.99)):
        n = int(0.4 * SR)
        tt = np.arange(n) / SR
        v = (np.sin(2 * np.pi * f * tt) + 0.3 * np.sin(4 * np.pi * f * tt)) * np.exp(-tt * 6)
        k = int(i * 0.1 * SR)
        x[k:k + n] += v[: len(x) - k]
    salvar('acerto', norm(x, 0.7))


def erro():
    d = 0.45
    ph = glide(220, 110, d)
    x = (np.sign(np.sin(ph)) * 0.5 + np.sin(ph) * 0.5) * env(len(ph), 0.01, 0.15)
    salvar('erro', norm(x, 0.6))


def batida():
    d = 0.4
    n = int(SR * d)
    tt = np.arange(n) / SR
    ru = filtro_ruido(d, 900, 80)[:n] * np.exp(-tt * 10)
    thump = np.sin(2 * np.pi * (140 - 80 * tt / d) * tt) * np.exp(-tt * 9)
    salvar('batida', norm(ru * 0.7 + thump, 0.85))


def filhote():
    d = 1.4
    ph = glide(700, 260, d, vib=0.02, vibf=7)
    x = (np.sin(ph) + 0.4 * np.sin(2 * ph)) * env(len(ph), 0.08, 0.5)
    k = int(0.3 * SR)
    eco = np.zeros_like(x)
    eco[k:] = x[:-k] * 0.3
    salvar('filhote', norm(x + eco, 0.7))


def anzol():
    d = 0.9
    n = int(SR * d)
    tt = np.arange(n) / SR
    splash = filtro_ruido(d, 3500, 400)[:n] * np.exp(-tt * 6)
    ping = np.sin(2 * np.pi * 1850 * tt) * np.exp(-tt * 7) * 0.5 + np.sin(2 * np.pi * 2790 * tt) * np.exp(-tt * 9) * 0.25
    salvar('anzol', norm(splash * 0.9 + ping, 0.75))


def pescada():
    d = 1.8
    n = int(SR * d)
    tt = np.arange(n) / SR
    ph = glide(330, 70, d)
    x = np.sin(ph) * env(n, 0.02, 0.5)
    x += filtro_ruido(d, 1500, 100)[:n] * np.exp(-tt * 2.2) * 0.8
    salvar('pescada', norm(x, 0.8))


def fase():
    notas = (523.25, 659.25, 783.99, 1046.5)
    x = np.zeros(int(SR * 1.3))
    for i, f in enumerate(notas):
        n = int(0.5 * SR)
        tt = np.arange(n) / SR
        v = (np.sin(2 * np.pi * f * tt) + 0.35 * np.sin(4 * np.pi * f * tt)) * np.exp(-tt * 4)
        k = int(i * 0.16 * SR)
        x[k:k + n] += v[: len(x) - k]
    salvar('fase', norm(x, 0.7))


def vitoria():
    notas = (392.0, 523.25, 659.25, 783.99, 1046.5, 1318.5)
    x = np.zeros(int(SR * 2.4))
    for i, f in enumerate(notas):
        n = int(0.8 * SR)
        tt = np.arange(n) / SR
        v = (np.sin(2 * np.pi * f * tt) + 0.3 * np.sin(4 * np.pi * f * tt)) * np.exp(-tt * 3.2)
        k = int(i * 0.2 * SR)
        x[k:k + n] += v[: len(x) - k]
    salvar('vitoria', norm(x, 0.7))


if __name__ == '__main__':
    for f in (mar, baleia, golfinho, tensao, come, poder, acerto, erro, batida, filhote, anzol, pescada, fase, vitoria):
        f()
