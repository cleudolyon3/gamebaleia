import 'dart:ui' as ui;
import 'package:flutter/services.dart';

/// Carrega as imagens opcionais de assets/img. Se um arquivo não existir,
/// o jogo usa a arte vetorial desenhada em código (fallback).
class Arte {
  static const nomes = [
    'baleia_fechada', 'baleia_boca', 'fundo_mar', 'fundo_menu',
    'rede_cai', 'baleia_pescada', 'baleia_afunda', 'barco',
    'saco_plastico', 'krill',
  ];
  static final Map<String, ui.Image> _m = {};

  static Future<void> carregar() async {
    for (final n in nomes) {
      for (final ext in const ['png', 'webp', 'jpg']) {
        try {
          final data = await rootBundle.load('assets/img/$n.$ext');
          final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
          final f = await codec.getNextFrame();
          _m[n] = f.image;
          break;
        } catch (_) {}
      }
    }
  }

  static ui.Image? get(String n) => _m[n];

  // ---- sequências de quadros (vídeos convertidos): assets/img/<nome>/001.jpg ...
  static final Map<String, List<ui.Image>> _seq = {};

  static Future<void> carregarSeq(String nome) async {
    final l = <ui.Image>[];
    for (var i = 1; i < 1000; i++) {
      try {
        final data = await rootBundle.load('assets/img/$nome/${i.toString().padLeft(3, '0')}.jpg');
        final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
        l.add((await codec.getNextFrame()).image);
      } catch (_) {
        break;
      }
    }
    if (l.isNotEmpty) _seq[nome] = l;
  }

  static int quadros(String n) => _seq[n]?.length ?? 0;

  /// Desenha o quadro [i] da sequência [n] cobrindo [dst].
  static bool quadro(ui.Canvas c, String n, int i, ui.Rect dst) {
    final l = _seq[n];
    if (l == null || l.isEmpty) return false;
    _cobrirImg(c, l[i.clamp(0, l.length - 1)], dst);
    return true;
  }

  static void _cobrirImg(ui.Canvas c, ui.Image img, ui.Rect dst) {
    final iw = img.width.toDouble(), ih = img.height.toDouble();
    final s = (dst.width / iw) > (dst.height / ih) ? dst.width / iw : dst.height / ih;
    final w = iw * s, h = ih * s;
    final r = ui.Rect.fromLTWH(dst.left + (dst.width - w) / 2, dst.top + (dst.height - h) / 2, w, h);
    c.save();
    c.clipRect(dst);
    c.drawImageRect(img, ui.Rect.fromLTWH(0, 0, iw, ih), r, ui.Paint()..filterQuality = ui.FilterQuality.medium);
    c.restore();
  }

  /// Desenha a imagem [n] dentro de [dst]; devolve false se não existir.
  static bool desenhar(ui.Canvas c, String n, ui.Rect dst, {double opacity = 1}) {
    final img = _m[n];
    if (img == null) return false;
    final src = ui.Rect.fromLTWH(0, 0, img.width.toDouble(), img.height.toDouble());
    c.drawImageRect(img, src, dst, ui.Paint()..color = ui.Color.fromRGBO(255, 255, 255, opacity)..filterQuality = ui.FilterQuality.medium);
    return true;
  }

  /// Cobre [dst] (estilo BoxFit.cover).
  static bool cobrir(ui.Canvas c, String n, ui.Rect dst) {
    final img = _m[n];
    if (img == null) return false;
    final iw = img.width.toDouble(), ih = img.height.toDouble();
    final s = (dst.width / iw) > (dst.height / ih) ? dst.width / iw : dst.height / ih;
    final w = iw * s, h = ih * s;
    final r = ui.Rect.fromLTWH(dst.left + (dst.width - w) / 2, dst.top + (dst.height - h) / 2, w, h);
    c.save();
    c.clipRect(dst);
    c.drawImageRect(img, ui.Rect.fromLTWH(0, 0, iw, ih), r, ui.Paint()..filterQuality = ui.FilterQuality.medium);
    c.restore();
    return true;
  }
}
