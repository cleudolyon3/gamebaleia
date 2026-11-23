import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'baleia.dart';
import 'dados.dart';
import 'placar.dart';

const _gates = [0.1, 0.2, 0.3, 0.4, 0.5, 0.6, 0.7, 0.8];

Path _canal() => Path()
  ..moveTo(70, 50)
  ..cubicTo(70, 100, 290, 90, 290, 150)
  ..cubicTo(290, 210, 70, 200, 70, 270)
  ..cubicTo(70, 330, 290, 320, 290, 380)
  ..cubicTo(290, 440, 130, 430, 130, 480)
  ..lineTo(130, 530);

class ResgateTela extends StatefulWidget {
  const ResgateTela({super.key});
  @override
  State<ResgateTela> createState() => _ResgateTelaState();
}

class _ResgateTelaState extends State<ResgateTela> with SingleTickerProviderStateMixin {
  late final AnimationController _anim;
  final _rnd = math.Random();
  List<Pergunta> _fila = [];
  Pergunta? _q;
  int _abertas = 0, _vidas = 5, _erros = 0;
  double _p0 = 0.0, _p1 = 0.0;
  int? _marcada;
  String _msg = '';
  bool _respondida = false, _fim = false, _venceu = false;
  int _pontos = 0;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400))..addListener(() => setState(() {}));
    _novo();
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  double get _prog => _p0 + (_p1 - _p0) * Curves.easeInOut.transform(_anim.value);

  void _novo() {
    _abertas = 0;
    _vidas = 5;
    _erros = 0;
    _p0 = _p1 = 0;
    _fim = false;
    _venceu = false;
    _respondida = false;
    _marcada = null;
    _msg = '';
    _fila = [];
    _proxima();
    _anim.value = 0;
  }

  void _proxima() {
    if (_fila.isEmpty) _fila = List.of(perguntasResgate)..shuffle(_rnd);
    _q = _fila.removeLast();
    _respondida = false;
    _marcada = null;
    _msg = '';
    setState(() {});
  }

  void _responde(int i) {
    if (_respondida || _fim) return;
    final q = _q!;
    setState(() {
      _marcada = i;
      _respondida = true;
      if (i == q.certa) {
        _abertas++;
        _p0 = _prog;
        _p1 = _abertas >= _gates.length ? 1.0 : _gates[_abertas - 1] + 0.05;
        _anim.forward(from: 0);
        _msg = '✅ Comporta aberta! ${q.explicacao}';
        if (_abertas >= _gates.length) {
          _venceu = true;
          _pontos = 800 + _vidas * 100;
          Placar.registrar('Resgate da Baleia', _pontos);
        }
      } else {
        _vidas--;
        _erros++;
        _msg = '❌ Não foi essa. ${q.explicacao}';
        if (_vidas <= 0) {
          _pontos = _abertas * 100;
          Placar.registrar('Resgate da Baleia', _pontos);
        }
      }
    });
  }

  void _continuar() {
    if (_venceu || _vidas <= 0) {
      setState(() => _fim = true);
    } else {
      _proxima();
    }
  }

  @override
  Widget build(BuildContext context) {
    final q = _q!;
    return Scaffold(
      appBar: AppBar(
        title: const Text('🛟 Resgate da Baleia'),
        backgroundColor: const Color(0xFF06202E),
        actions: [
          Center(child: Padding(padding: const EdgeInsets.only(right: 16), child: Text('🚪 $_abertas/${_gates.length}    ${'❤️' * math.max(0, _vidas)}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)))),
        ],
      ),
      body: Container(
        color: const Color(0xFF0B3B4F),
        child: Row(children: [
          Expanded(
            flex: 4,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Center(
                child: AspectRatio(
                  aspectRatio: 360 / 540,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: CustomPaint(painter: _MapaPainter(_prog, _abertas, _anim.isAnimating ? _anim.value : DateTime.now().millisecond / 1000)),
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            flex: 6,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: _fim ? _final() : _pergunta(q),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _pergunta(Pergunta q) {
    return SingleChildScrollView(
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Text(q.tema.toUpperCase(), style: const TextStyle(color: Color(0xFF8ED8D3), fontWeight: FontWeight.w900, letterSpacing: 1.5)),
        const SizedBox(height: 8),
        Text(q.enunciado, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w800, height: 1.25)),
        const SizedBox(height: 16),
        for (var i = 0; i < q.opcoes.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                alignment: Alignment.centerLeft,
                padding: const EdgeInsets.all(16),
                backgroundColor: !_respondida
                    ? const Color(0xFFE8FAFF)
                    : (i == q.certa ? const Color(0xFFA5D6A7) : (i == _marcada ? const Color(0xFFEF9A9A) : const Color(0xFFCFD8DC))),
              ),
              onPressed: _respondida ? null : () => _responde(i),
              child: Text(q.opcoes[i], style: const TextStyle(color: Color(0xFF06202E), fontSize: 18, fontWeight: FontWeight.w700)),
            ),
          ),
        if (_respondida) ...[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: const Color(0x66000000), borderRadius: BorderRadius.circular(12)),
            child: Text(_msg, style: const TextStyle(color: Colors.white, fontSize: 17, height: 1.3)),
          ),
          const SizedBox(height: 12),
          FilledButton(onPressed: _continuar, child: const Padding(padding: EdgeInsets.all(10), child: Text('Continuar', style: TextStyle(fontSize: 18)))),
        ],
      ]),
    );
  }

  Widget _final() {
    return Center(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Text(_venceu ? '🌊 A baleia chegou ao mar aberto!' : '🪢 A baleia ficou presa no canal…',
            textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.w900)),
        const SizedBox(height: 10),
        Text('$_pontos pontos  •  $_erros erros', style: const TextStyle(color: Color(0xFFFFE082), fontSize: 22, fontWeight: FontWeight.w800)),
        const SizedBox(height: 16),
        Row(mainAxisSize: MainAxisSize.min, children: [
          FilledButton(onPressed: _novo, child: const Text('Jogar de novo')),
          const SizedBox(width: 10),
          OutlinedButton(onPressed: () => Navigator.of(context).maybePop(), child: const Text('Menu', style: TextStyle(color: Colors.white))),
        ]),
      ]),
    );
  }
}

class _MapaPainter extends CustomPainter {
  final double prog;
  final int abertas;
  final double t;
  _MapaPainter(this.prog, this.abertas, this.t);

  @override
  bool shouldRepaint(covariant CustomPainter old) => true;

  @override
  void paint(Canvas c, Size size) {
    c.scale(size.width / 360);
    c.drawRect(const Rect.fromLTWH(0, 0, 360, 540), Paint()..color = const Color(0xFFD9B872));
    final verde = Paint()..color = const Color(0xFF2F7D4F);
    for (final p in const [Offset(318, 64), Offset(338, 92), Offset(24, 168), Offset(170, 120), Offset(190, 236), Offset(32, 330), Offset(334, 250), Offset(180, 340), Offset(330, 448), Offset(30, 440)]) {
      c.drawCircle(p, 18, verde);
    }
    c.drawOval(const Rect.fromLTWH(8, -4, 124, 80), Paint()..color = const Color(0xFF1389A0));
    final canal = _canal();
    c.drawPath(canal, Paint()..color = const Color(0xFF0E6E8C)..style = PaintingStyle.stroke..strokeWidth = 42..strokeCap = StrokeCap.round..strokeJoin = StrokeJoin.round);
    c.drawPath(canal, Paint()..color = const Color(0xFF1389A0)..style = PaintingStyle.stroke..strokeWidth = 34..strokeCap = StrokeCap.round..strokeJoin = StrokeJoin.round);
    c.drawRect(const Rect.fromLTWH(0, 486, 360, 54), Paint()..color = const Color(0xFF0B4A66));
    final m = canal.computeMetrics().first;
    for (var i = 0; i < _gates.length; i++) {
      final tg = m.getTangentForOffset(m.length * _gates[i])!;
      final n = Offset(-tg.vector.dy, tg.vector.dx);
      final aberta = i < abertas;
      final cor = Paint()..color = aberta ? const Color(0xFF66BB6A) : const Color(0xFFD2312F)..strokeWidth = 7..strokeCap = StrokeCap.round;
      if (aberta) {
        c.drawLine(tg.position + n * 20, tg.position + n * 30, cor);
        c.drawLine(tg.position - n * 20, tg.position - n * 30, cor);
      } else {
        c.drawLine(tg.position + n * 24, tg.position - n * 24, cor);
      }
    }
    final pos = m.getTangentForOffset(m.length * prog.clamp(0.0, 1.0))!;
    c.save();
    c.translate(pos.position.dx, pos.position.dy);
    var inc = pos.angle;
    if (pos.vector.dx < 0) {
      c.scale(-1, 1);
      inc = math.pi - pos.angle;
    }
    desenharBaleia(c, 0, 0, escala: 0.3, tilt: inc, boca: prog >= 1 ? 1 : 0, t: t * 4);
    c.restore();
    final tp = TextPainter(text: const TextSpan(text: 'MAR ABERTO', style: TextStyle(color: Color(0xFFEAF6F2), fontSize: 13, fontWeight: FontWeight.w900)), textDirection: TextDirection.ltr)..layout();
    tp.paint(c, Offset(180 - tp.width / 2, 505));
    final tl = TextPainter(text: const TextSpan(text: 'LAGOA', style: TextStyle(color: Color(0xFFEAF6F2), fontSize: 12, fontWeight: FontWeight.w900)), textDirection: TextDirection.ltr)..layout();
    tl.paint(c, Offset(70 - tl.width / 2, 8));
  }
}
