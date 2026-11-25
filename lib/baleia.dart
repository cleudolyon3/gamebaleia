import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'arte.dart';

/// Desenha a baleia jubarte virada para a direita, centrada em (0,0).
/// [boca] vai de 0 (fechada) a 1 (aberta). Se existirem as imagens
/// baleia_fechada / baleia_boca em assets/img, elas são usadas no lugar.
void desenharBaleia(Canvas c, double x, double y,
    {double escala = 1, double boca = 0, double tilt = 0, double t = 0, double opacidade = 1}) {
  c.save();
  c.translate(x, y);
  c.rotate(tilt);
  c.scale(escala);

  final usarBoca = boca > 0.4 && Arte.get('baleia_boca') != null;
  final nomeImg = usarBoca ? 'baleia_boca' : 'baleia_fechada';
  if (Arte.get(nomeImg) != null) {
    final img = Arte.get(nomeImg)!;
    final w = 270.0, h = w * img.height / img.width;
    Arte.desenhar(c, nomeImg, Rect.fromLTWH(-w / 2, -h * 0.32, w, h), opacity: opacidade);
    c.restore();
    return;
  }

  final corpo = Paint()..color = const Color(0xFF2B4A63).withOpacity(opacidade);
  final claro = Paint()..color = const Color(0xFFDCE8EE).withOpacity(opacidade);
  final sombra = Paint()..color = const Color(0xFF1B3246).withOpacity(opacidade);

  // cauda
  final bate = math.sin(t * 7) * 10;
  final cauda = Path()
    ..moveTo(-80, 2)
    ..quadraticBezierTo(-108, -8, -128, -34 + bate)
    ..quadraticBezierTo(-108, -26, -98, -12)
    ..quadraticBezierTo(-108, 8, -130, 34 + bate)
    ..quadraticBezierTo(-104, 24, -80, 12)
    ..close();
  c.drawPath(cauda, sombra);

  // corpo (parte de cima, até a linha da boca)
  final alto = Path()
    ..moveTo(-85, 4)
    ..cubicTo(-60, -50, 40, -56, 96, -14)
    ..lineTo(102, 0)
    ..lineTo(34, 8)
    ..cubicTo(10, 44, -50, 34, -85, 4)
    ..close();
  c.drawPath(alto, corpo);

  // barriga clara
  c.save();
  c.clipPath(alto);
  final barriga = Path()
    ..moveTo(-90, 14)
    ..quadraticBezierTo(-10, 4, 110, 8)
    ..lineTo(110, 60)
    ..lineTo(-90, 60)
    ..close();
  c.drawPath(barriga, claro);
  final sulco = Paint()
    ..color = const Color(0xFF9DB6C4).withOpacity(opacidade)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.6;
  for (var i = 0; i < 6; i++) {
    final yy = 14 + i * 4.5;
    c.drawLine(Offset(-20 + i * 2, yy), Offset(60, yy - 3), sulco);
  }
  c.restore();

  // mandíbula inferior (gira em torno do pivô)
  final ang = boca * 0.62;
  c.save();
  c.translate(34, 8);
  if (boca > 0.05) {
    final pt = Offset(68 * math.cos(ang), 68 * math.sin(ang));
    final interior = Path()
      ..moveTo(0, 0)
      ..lineTo(68, -6)
      ..lineTo(pt.dx, pt.dy)
      ..close();
    c.drawPath(interior, Paint()..color = const Color(0xFF8A2433).withOpacity(opacidade));
    final lingua = Path()
      ..moveTo(8, 2)
      ..quadraticBezierTo(34, 6 + boca * 14, 52, 4 + boca * 20)
      ..quadraticBezierTo(30, 14 + boca * 12, 8, 8)
      ..close();
    c.drawPath(lingua, Paint()..color = const Color(0xFFD9707F).withOpacity(opacidade));
  }
  c.rotate(ang);
  final mand = Path()
    ..moveTo(0, 0)
    ..lineTo(68, -2)
    ..quadraticBezierTo(66, 22, 22, 28)
    ..quadraticBezierTo(2, 24, 0, 0)
    ..close();
  c.drawPath(mand, corpo);
  c.save();
  c.clipPath(mand);
  c.drawRect(const Rect.fromLTWH(-5, 8, 80, 30), claro);
  c.restore();
  c.restore();

  // nadadeira
  c.save();
  c.translate(8, 20);
  c.rotate(0.5 + math.sin(t * 5) * 0.18);
  final nad = Path()
    ..moveTo(0, 0)
    ..quadraticBezierTo(-10, 30, -46, 52)
    ..quadraticBezierTo(-14, 40, 14, 10)
    ..close();
  c.drawPath(nad, sombra);
  c.restore();

  // olho
  c.drawCircle(const Offset(64, -6), 5, Paint()..color = Colors.white.withOpacity(opacidade));
  c.drawCircle(const Offset(65, -6), 2.6, Paint()..color = const Color(0xFF06202E).withOpacity(opacidade));

  // calombos
  final cal = Paint()..color = const Color(0xFF3C6079).withOpacity(opacidade);
  for (final p in const [Offset(86, -12), Offset(74, -22), Offset(90, -2)]) {
    c.drawCircle(p, 2.4, cal);
  }
  c.restore();
}

/// Filhote da baleia: usa assets/img/filhote.png se existir, senao a baleia desenhada em tamanho pequeno.
void desenharFilhote(Canvas c, double x, double y, {double tilt = 0, double t = 0, double opacidade = 1}) {
  final img = Arte.get('filhote');
  if (img != null) {
    final w = 118.0, h = w * img.height / img.width;
    c.save();
    c.translate(x, y);
    c.rotate(tilt);
    Arte.desenhar(c, 'filhote', Rect.fromLTWH(-w / 2, -h * 0.5, w, h), opacity: opacidade);
    c.restore();
    return;
  }
  desenharBaleia(c, x, y, escala: 0.4, tilt: tilt, t: t * 1.6, opacidade: opacidade);
}

/// Desenha uma rede de pesca (malha) cobrindo [r].
void desenharRede(Canvas c, Rect r, {double opacidade = 1}) {
  final p = Paint()
    ..color = const Color(0xFFE8D9A8).withOpacity(opacidade)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2.4;
  const passo = 22.0;
  for (var x = r.left; x <= r.right; x += passo) {
    c.drawLine(Offset(x, r.top), Offset(x + 10, r.bottom), p);
    c.drawLine(Offset(x + 10, r.top), Offset(x, r.bottom), p);
  }
  for (var y = r.top; y <= r.bottom; y += passo) {
    c.drawLine(Offset(r.left, y), Offset(r.right, y + 6), p);
  }
  final borda = Paint()
    ..color = const Color(0xFFB8893C).withOpacity(opacidade)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 5;
  c.drawRRect(RRect.fromRectAndRadius(r, const Radius.circular(18)), borda);
}

void desenharSaco(Canvas c, double x, double y, double t) {
  if (Arte.desenhar(c, 'saco_plastico', Rect.fromCenter(center: Offset(x, y), width: 70, height: 70))) return;
  c.save();
  c.translate(x, y + math.sin(t * 3 + x * 0.02) * 6);
  final p = Path()
    ..moveTo(-22, -26)
    ..quadraticBezierTo(0, -40, 22, -26)
    ..quadraticBezierTo(34, 0, 18, 30)
    ..quadraticBezierTo(0, 22, -18, 30)
    ..quadraticBezierTo(-34, 0, -22, -26)
    ..close();
  c.drawPath(p, Paint()..color = const Color(0xCCEFF6FF));
  c.drawPath(p, Paint()..color = const Color(0xFF9FB7C7)..style = PaintingStyle.stroke..strokeWidth = 2);
  c.drawLine(const Offset(-8, -18), const Offset(-14, 10), Paint()..color = const Color(0x88FFFFFF)..strokeWidth = 3);
  c.restore();
}

void desenharKrill(Canvas c, double x, double y, double t) {
  if (Arte.desenhar(c, 'krill', Rect.fromCenter(center: Offset(x, y), width: 64, height: 43))) return;
  c.save();
  c.translate(x, y + math.sin(t * 5 + x * 0.05) * 4);
  final p = Paint()..color = const Color(0xFFFF8A65);
  c.drawOval(const Rect.fromLTWH(-14, -6, 28, 12), p);
  c.drawCircle(const Offset(-10, -2), 1.8, Paint()..color = Colors.black);
  c.drawLine(const Offset(14, 0), const Offset(22, -5), Paint()..color = const Color(0xFFFF8A65)..strokeWidth = 3);
  c.restore();
}

Paint pincelAgua(Rect r, {double fundo = 0}) => Paint()
  ..shader = ui.Gradient.linear(r.topCenter, r.bottomCenter, [
    Color.lerp(const Color(0xFF39B5C9), const Color(0xFF0A3550), fundo)!,
    Color.lerp(const Color(0xFF0E7C9B), const Color(0xFF03121F), fundo)!,
  ]);
