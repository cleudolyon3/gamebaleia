import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'arte.dart';
import 'baleia.dart';
import 'dados.dart';
import 'placar.dart';

const double _W = 960, _H = 540;
const List<double> _lanes = [175, 290, 405];
const double _whaleX = 210;
const int _meta = 8;

enum _Fase { pronto, jogando, derrota, vitoria }
enum _Tipo { resp, rede, saco, krill, escudo, dobro }

class _Ent {
  final _Tipo tipo;
  double x;
  final double y;
  final int lane;
  final int idx;
  bool morta = false;
  TextPainter? tp;
  _Ent(this.tipo, this.x, this.lane, {this.idx = 0, String? txt}) : y = _lanes[lane] {
    if (txt != null) {
      tp = TextPainter(
        text: TextSpan(
          text: txt,
          style: const TextStyle(color: Color(0xFF06202E), fontSize: 15, fontWeight: FontWeight.w800, height: 1.1),
        ),
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
        maxLines: 3,
        ellipsis: '…',
      )..layout(maxWidth: 222);
    }
  }
}

class _Bolha {
  double x, y, r, v;
  _Bolha(this.x, this.y, this.r, this.v);
}

class _Texto {
  String s;
  double x, y, t = 0;
  Color cor;
  _Texto(this.s, this.x, this.y, this.cor);
}

class CorridaTela extends StatefulWidget {
  const CorridaTela({super.key});
  @override
  State<CorridaTela> createState() => _CorridaTelaState();
}

class _CorridaTelaState extends State<CorridaTela> with SingleTickerProviderStateMixin {
  final _rnd = math.Random();
  late final Ticker _ticker;
  Duration _ult = Duration.zero;
  final _foco = FocusNode();

  _Fase fase = _Fase.pronto;
  double t = 0, scroll = 0;
  int lane = 1;
  double whaleY = _lanes[1];
  double boca = 0, mordida = 0;
  int vidas = 3, pontos = 0, acertos = 0, combo = 0;
  double invuln = 0, escudoT = 0, dobroT = 0, tremor = 0, flash = 0;
  final List<_Ent> ents = [];
  final List<_Bolha> bolhas = [];
  final List<_Texto> textos = [];
  double proxSpawn = 1.2, faseObst = 5;
  bool perguntaAtiva = false;
  Pergunta? perg;
  int certaIdx = 0;
  List<Pergunta> _fila = [];
  String aviso = '';
  bool avisoOk = true;
  double avisoT = 0;
  double tFim = 0;
  bool fimMostrado = false, _registrado = false;

  int get mult => math.min(5, 1 + combo ~/ 3) * (dobroT > 0 ? 2 : 1);

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_tick)..start();
    for (var i = 0; i < 30; i++) {
      bolhas.add(_Bolha(_rnd.nextDouble() * _W, _rnd.nextDouble() * _H, 2 + _rnd.nextDouble() * 5, 15 + _rnd.nextDouble() * 30));
    }
  }

  @override
  void dispose() {
    _ticker.dispose();
    _foco.dispose();
    super.dispose();
  }

  void _novo() {
    ents.clear();
    textos.clear();
    vidas = 3;
    pontos = acertos = combo = 0;
    invuln = escudoT = dobroT = tremor = flash = 0;
    lane = 1;
    whaleY = _lanes[1];
    perguntaAtiva = false;
    perg = null;
    aviso = '';
    avisoT = 0;
    proxSpawn = 1.0;
    faseObst = 4.5;
    tFim = 0;
    fimMostrado = false;
    _registrado = false;
    _fila = List.of(perguntasCorrida)..shuffle(_rnd);
    fase = _Fase.jogando;
  }

  void _mover(int d) {
    if (fase != _Fase.jogando) return;
    lane = (lane + d).clamp(0, 2);
  }

  void _tick(Duration d) {
    var dt = (d - _ult).inMicroseconds / 1e6;
    _ult = d;
    if (dt <= 0 || dt > 0.1) dt = 0.016;
    t += dt;
    whaleY += (_lanes[lane] - whaleY) * math.min(1.0, dt * 9);
    tremor = math.max(0, tremor - dt * 2.2);
    flash = math.max(0, flash - dt * 2.5);
    mordida = math.max(0, mordida - dt);
    for (final b in bolhas) {
      b.y -= b.v * dt;
      b.x += math.sin(t * 2 + b.r) * 8 * dt;
      if (b.y < -10) {
        b.y = _H + 10;
        b.x = _rnd.nextDouble() * _W;
      }
    }
    for (final tx in textos) {
      tx.t += dt;
    }
    textos.removeWhere((e) => e.t > 1.1);

    if (fase == _Fase.jogando) {
      _jogar(dt);
    } else if (fase == _Fase.derrota) {
      ents.clear();
      tFim += dt;
      boca += (0 - boca) * math.min(1.0, dt * 6);
      final dur = Arte.quadros('derrota') > 0 ? Arte.quadros('derrota') / 12 + 0.8 : 6.2;
      if (tFim > dur && !fimMostrado) _terminar();
    } else if (fase == _Fase.vitoria) {
      tFim += dt;
      boca += ((tFim % 1.2 < 0.5 ? 1.0 : 0.0) - boca) * math.min(1.0, dt * 10);
      if (tFim > 2.2 && !fimMostrado) _terminar();
    }
    if (mounted) setState(() {});
  }

  void _terminar() {
    fimMostrado = true;
    if (!_registrado) {
      _registrado = true;
      Placar.registrar('Corrida da Baleia', pontos);
    }
  }

  void _jogar(double dt) {
    final vel = 230.0 + acertos * 16 + (mult - 1) * 5;
    scroll += vel * dt;
    invuln = math.max(0, invuln - dt);
    escudoT = math.max(0, escudoT - dt);
    dobroT = math.max(0, dobroT - dt);
    avisoT = math.max(0, avisoT - dt);

    if (!perguntaAtiva && avisoT <= 0.8) {
      proxSpawn -= dt;
      faseObst -= dt;
      if (proxSpawn <= 0) {
        _spawnComum();
        proxSpawn = 0.75 + _rnd.nextDouble() * 0.7;
      }
      if (faseObst <= 0) _iniciarPergunta();
    }

    var comestivelPerto = false;
    for (final e in ents) {
      e.x -= vel * dt;
      if (e.morta) continue;
      final dy = (e.y - whaleY).abs();
      final comest = e.tipo == _Tipo.krill || e.tipo == _Tipo.resp || e.tipo == _Tipo.escudo || e.tipo == _Tipo.dobro;
      final alcance = e.tipo == _Tipo.resp ? 245.0 : 125.0;
      if (comest && dy < 56 && e.x < _whaleX + alcance + 90 && e.x > _whaleX) comestivelPerto = true;
      if (comest) {
        if (dy < 56 && e.x < _whaleX + alcance && e.x > _whaleX - 20) _comer(e);
      } else if (dy < 50 && e.x < _whaleX + 90 && e.x > _whaleX - 90) {
        if (escudoT > 0) {
          e.morta = true;
          _estourar(e.x, e.y, 8);
        } else if (invuln <= 0) {
          e.morta = true;
          _perderVida(e.x, e.y);
        }
      }
    }
    final alvo = (comestivelPerto || mordida > 0) ? 1.0 : 0.0;
    boca += (alvo - boca) * math.min(1.0, dt * 14);

    ents.removeWhere((e) => e.x < -300 || (e.morta && e.tipo != _Tipo.resp && e.x < -50));
    if (perguntaAtiva && !ents.any((e) => e.tipo == _Tipo.resp && !e.morta)) {
      // passou sem responder
      perguntaAtiva = false;
      _errou('Você deixou a pergunta passar. ');
    }
  }

  void _spawnComum() {
    final l = _rnd.nextInt(3);
    final r = _rnd.nextDouble();
    if (r < 0.34) {
      ents.add(_Ent(_Tipo.rede, _W + 80, l));
    } else if (r < 0.58) {
      ents.add(_Ent(_Tipo.saco, _W + 80, l));
    } else if (r < 0.93) {
      for (var i = 0; i < 3; i++) {
        ents.add(_Ent(_Tipo.krill, _W + 80 + i * 55, l));
      }
    } else {
      ents.add(_Ent(_rnd.nextBool() ? _Tipo.escudo : _Tipo.dobro, _W + 80, l));
    }
  }

  void _iniciarPergunta() {
    if (_fila.isEmpty) _fila = List.of(perguntasCorrida)..shuffle(_rnd);
    final p = _fila.removeLast();
    perg = p;
    final erradas = <int>[for (var i = 0; i < p.opcoes.length; i++) if (i != p.certa) i]..shuffle(_rnd);
    final escolhidas = [p.certa, erradas[0], erradas[1]]..shuffle(_rnd);
    certaIdx = escolhidas.indexOf(p.certa);
    for (var l = 0; l < 3; l++) {
      ents.add(_Ent(_Tipo.resp, _W + 140, l, idx: l, txt: p.opcoes[escolhidas[l]]));
    }
    perguntaAtiva = true;
  }

  void _comer(_Ent e) {
    e.morta = true;
    mordida = 0.32;
    switch (e.tipo) {
      case _Tipo.krill:
        combo++;
        final g = 10 * mult;
        pontos += g;
        textos.add(_Texto('+$g', e.x, e.y - 30, const Color(0xFFFFE082)));
        _estourar(e.x, e.y, 4);
        break;
      case _Tipo.escudo:
        escudoT = 8;
        textos.add(_Texto('ESCUDO!', e.x, e.y - 30, const Color(0xFF80DEEA)));
        break;
      case _Tipo.dobro:
        dobroT = 8;
        textos.add(_Texto('PONTOS x2!', e.x, e.y - 30, const Color(0xFFFFD54F)));
        break;
      case _Tipo.resp:
        for (final o in ents) {
          if (o.tipo == _Tipo.resp) o.morta = true;
        }
        perguntaAtiva = false;
        final p = perg!;
        if (e.idx == certaIdx) {
          acertos++;
          combo += 2;
          final g = 100 * mult;
          pontos += g;
          aviso = 'Muito bem! ${p.explicacao}';
          avisoOk = true;
          avisoT = 5.0;
          faseObst = 4.0 + _rnd.nextDouble() * 2;
          textos.add(_Texto('+$g', e.x, e.y - 40, const Color(0xFFA5D6A7)));
          _estourar(e.x, e.y, 14);
          if (acertos >= _meta) {
            fase = _Fase.vitoria;
            tFim = 0;
            pontos += vidas * 150;
          }
        } else {
          _errou('');
        }
        break;
      default:
        break;
    }
  }

  void _errou(String prefixo) {
    final p = perg;
    aviso = '${prefixo}Não foi essa. ${p?.explicacao ?? ''}';
    avisoOk = false;
    avisoT = 5.0;
    faseObst = 4.0 + _rnd.nextDouble() * 2;
    _perderVida(_whaleX + 100, whaleY);
  }

  void _perderVida(double x, double y) {
    vidas--;
    combo = 0;
    invuln = 1.6;
    tremor = 1;
    flash = 1;
    _estourar(x, y, 10);
    if (vidas <= 0) {
      fase = _Fase.derrota;
      tFim = 0;
      perguntaAtiva = false;
    }
  }

  void _estourar(double x, double y, int n) {
    for (var i = 0; i < n; i++) {
      bolhas.add(_Bolha(x + _rnd.nextDouble() * 40 - 20, y + _rnd.nextDouble() * 30 - 15, 2 + _rnd.nextDouble() * 4, 40 + _rnd.nextDouble() * 60));
    }
    if (bolhas.length > 140) bolhas.removeRange(0, bolhas.length - 140);
  }

  // ---------------------------------------------------------------- UI
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: KeyboardListener(
        focusNode: _foco,
        autofocus: true,
        onKeyEvent: (e) {
          if (e is! KeyDownEvent) return;
          final k = e.logicalKey;
          if (k == LogicalKeyboardKey.arrowUp || k == LogicalKeyboardKey.keyW) _mover(-1);
          if (k == LogicalKeyboardKey.arrowDown || k == LogicalKeyboardKey.keyS) _mover(1);
          if ((k == LogicalKeyboardKey.space || k == LogicalKeyboardKey.enter) && (fase == _Fase.pronto || fimMostrado)) _novo();
          if (k == LogicalKeyboardKey.escape) Navigator.of(context).maybePop();
        },
        child: Center(
          child: AspectRatio(
            aspectRatio: _W / _H,
            child: LayoutBuilder(builder: (ctx, c) {
              final sc = c.maxWidth / _W;
              return Listener(
                onPointerDown: (e) => _ponteiro(e.localPosition.dy / sc),
                onPointerMove: (e) => _ponteiro(e.localPosition.dy / sc),
                child: Stack(children: [
                  Positioned.fill(child: CustomPaint(painter: _CorridaPainter(this))),
                  if (fase == _Fase.jogando || fase == _Fase.vitoria) _hud(sc),
                  if (fase == _Fase.pronto) _cartaoInicio(sc),
                  if (fimMostrado) _cartaoFim(sc),
                  Positioned(
                    left: 8 * sc,
                    top: 8 * sc,
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white70),
                      onPressed: () => Navigator.of(context).maybePop(),
                    ),
                  ),
                ]),
              );
            }),
          ),
        ),
      ),
    );
  }

  void _ponteiro(double y) {
    if (fase != _Fase.jogando) return;
    lane = y < 232 ? 0 : (y < 348 ? 1 : 2);
  }

  Widget _hud(double sc) {
    return Positioned.fill(
      child: IgnorePointer(
        child: Padding(
          padding: EdgeInsets.fromLTRB(60 * sc, 10 * sc, 16 * sc, 0),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              _pill('⭐ $pontos', sc),
              SizedBox(width: 8 * sc),
              _pill('Combo x$mult', sc, cor: mult > 1 ? const Color(0xFFFF8F00) : null),
              SizedBox(width: 8 * sc),
              _pill('🐋 $acertos/$_meta', sc),
              if (escudoT > 0) ...[SizedBox(width: 8 * sc), _pill('🛡️ ${escudoT.ceil()}s', sc, cor: const Color(0xFF00838F))],
              if (dobroT > 0) ...[SizedBox(width: 8 * sc), _pill('x2 ${dobroT.ceil()}s', sc, cor: const Color(0xFFF9A825))],
              const Spacer(),
              for (var i = 0; i < 3; i++)
                Icon(i < vidas ? Icons.favorite : Icons.favorite_border, color: const Color(0xFFFF5252), size: 30 * sc),
            ]),
            SizedBox(height: 8 * sc),
            if (perguntaAtiva && perg != null)
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(10 * sc),
                decoration: BoxDecoration(color: const Color(0xDD06202E), borderRadius: BorderRadius.circular(14 * sc)),
                child: Text(perg!.enunciado,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white, fontSize: 19 * sc, fontWeight: FontWeight.w800)),
              ),
            const Spacer(),
            if (avisoT > 0 && aviso.isNotEmpty)
              Container(
                width: double.infinity,
                margin: EdgeInsets.only(bottom: 12 * sc, right: 0),
                padding: EdgeInsets.all(12 * sc),
                decoration: BoxDecoration(
                  color: avisoOk ? const Color(0xEE1B5E20) : const Color(0xEEB71C1C),
                  borderRadius: BorderRadius.circular(14 * sc),
                ),
                child: Text(aviso, style: TextStyle(color: Colors.white, fontSize: 16 * sc, fontWeight: FontWeight.w700)),
              ),
          ]),
        ),
      ),
    );
  }

  Widget _pill(String s, double sc, {Color? cor}) => Container(
        padding: EdgeInsets.symmetric(horizontal: 12 * sc, vertical: 6 * sc),
        decoration: BoxDecoration(color: cor ?? const Color(0xCC06202E), borderRadius: BorderRadius.circular(20 * sc)),
        child: Text(s, style: TextStyle(color: Colors.white, fontSize: 16 * sc, fontWeight: FontWeight.w800)),
      );

  Widget _cartao(double sc, List<Widget> filhos) => Center(
        child: Container(
          width: 560 * sc,
          padding: EdgeInsets.all(24 * sc),
          decoration: BoxDecoration(
            color: const Color(0xCC06202E),
            borderRadius: BorderRadius.circular(22 * sc),
            border: Border.all(color: const Color(0xFF39B5C9), width: 2),
          ),
          child: Column(mainAxisSize: MainAxisSize.min, children: filhos),
        ),
      );

  Widget _cartaoInicio(double sc) => _cartao(sc, [
        Text('🐋 Corrida da Baleia',
            style: TextStyle(color: Colors.white, fontSize: 32 * sc, fontWeight: FontWeight.w900)),
        SizedBox(height: 12 * sc),
        Text(
          'Nade pelas 3 faixas (setas ↑ ↓, W/S ou toque na tela).\n'
          'Abra a boca para comer krill e as respostas certas.\n'
          'Fuja das redes de pesca e dos sacos plásticos!\n'
          'Acerte $_meta perguntas para salvar a baleia.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white70, fontSize: 18 * sc, height: 1.4),
        ),
        SizedBox(height: 18 * sc),
        FilledButton(onPressed: _novo, child: Padding(padding: EdgeInsets.all(8 * sc), child: Text('JOGAR', style: TextStyle(fontSize: 22 * sc)))),
      ]);

  Widget _cartaoFim(double sc) {
    final venceu = fase == _Fase.vitoria;
    return _cartao(sc, [
      Text(venceu ? '🎉 A baleia está salva!' : '🎣 A baleia foi pescada…',
          style: TextStyle(color: Colors.white, fontSize: 30 * sc, fontWeight: FontWeight.w900)),
      SizedBox(height: 10 * sc),
      Text('Pontos: $pontos   •   Acertos: $acertos/$_meta',
          style: TextStyle(color: const Color(0xFFFFE082), fontSize: 22 * sc, fontWeight: FontWeight.w800)),
      SizedBox(height: 10 * sc),
      Text(
        venceu
            ? 'Cuidar do mar e conhecer a nossa história é proteger a vida das baleias jubarte da Costa das Baleias.'
            : 'Redes e plástico ferem os animais marinhos. Preservar o mar e a biodiversidade é papel de todos!',
        textAlign: TextAlign.center,
        style: TextStyle(color: Colors.white70, fontSize: 17 * sc, height: 1.35),
      ),
      SizedBox(height: 16 * sc),
      Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        FilledButton(onPressed: _novo, child: const Text('Jogar de novo')),
        const SizedBox(width: 12),
        OutlinedButton(onPressed: () => Navigator.of(context).maybePop(), child: const Text('Menu', style: TextStyle(color: Colors.white))),
      ]),
    ]);
  }
}

// ======================================================================
class _CorridaPainter extends CustomPainter {
  final _CorridaTelaState s;
  _CorridaPainter(this.s) : super(repaint: null);

  @override
  bool shouldRepaint(covariant CustomPainter old) => true;

  double _ease(double x) {
    x = x.clamp(0.0, 1.0);
    return x * x * (3 - 2 * x);
  }

  @override
  void paint(Canvas c, Size size) {
    c.save();
    c.scale(size.width / _W);
    c.clipRect(const Rect.fromLTWH(0, 0, _W, _H));
    if (s.tremor > 0) {
      c.translate(math.sin(s.t * 60) * 7 * s.tremor, math.cos(s.t * 50) * 5 * s.tremor);
    }
    if (s.fase == _Fase.pronto && Arte.quadros('intro') > 0) {
      Arte.quadro(c, 'intro', (s.t * 12).floor() % Arte.quadros('intro'), const Rect.fromLTWH(0, 0, _W, _H));
      c.restore();
      return;
    }
    _fundo(c);
    for (final b in s.bolhas) {
      c.drawCircle(Offset(b.x, b.y), b.r, Paint()..color = const Color(0x55FFFFFF));
    }
    for (final e in s.ents) {
      if (e.morta) continue;
      _ent(c, e);
    }
    _baleia(c);
    for (final tx in s.textos) {
      final tp = TextPainter(
        text: TextSpan(text: tx.s, style: TextStyle(color: tx.cor.withValues(alpha: 1 - tx.t / 1.1), fontSize: 26, fontWeight: FontWeight.w900)),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(c, Offset(tx.x - tp.width / 2, tx.y - tx.t * 50));
    }
    if (s.flash > 0) {
      c.drawRect(const Rect.fromLTWH(0, 0, _W, _H), Paint()..color = Color.fromRGBO(255, 0, 0, 0.35 * s.flash));
    }
    if (s.fase == _Fase.derrota) _derrotaTela(c);
    if (s.fase == _Fase.vitoria) _confete(c);
    c.restore();
  }

  void _fundo(Canvas c) {
    const r = Rect.fromLTWH(0, 0, _W, _H);
    final profundo = s.fase == _Fase.derrota ? _ease((s.tFim - 3.6) / 2.4) : 0.0;
    if (!Arte.cobrir(c, 'fundo_mar', r)) {
      c.drawRect(r, pincelAgua(r, fundo: 0.0));
      // raios de luz
      for (var i = 0; i < 4; i++) {
        final x0 = 120.0 + i * 230 + math.sin(s.t * 0.6 + i) * 30;
        final p = Path()
          ..moveTo(x0, 0)
          ..lineTo(x0 + 70, 0)
          ..lineTo(x0 + 20, _H)
          ..lineTo(x0 - 120, _H)
          ..close();
        c.drawPath(p, Paint()..color = const Color(0x14FFFFFF));
      }
      // fundo do mar com paralaxe
      final off = (s.scroll * 0.25) % 400;
      final chao = Path()..moveTo(0, _H);
      for (var x = -400.0; x <= _W + 400; x += 40) {
        chao.lineTo(x - off + 400 - 400, _H - 38 - math.sin((x + 0) * 0.02) * 12);
      }
      chao
        ..lineTo(_W + 400, _H)
        ..close();
      c.drawPath(chao, Paint()..color = const Color(0xFF0B3B4F));
      for (var i = -1; i < 9; i++) {
        final cx = i * 160.0 - (s.scroll * 0.5) % 160;
        c.drawCircle(Offset(cx + 20, _H - 40), 14, Paint()..color = const Color(0xFFD2536A));
        c.drawCircle(Offset(cx + 42, _H - 52), 10, Paint()..color = const Color(0xFFE08A4E));
        c.drawCircle(Offset(cx + 90, _H - 38), 12, Paint()..color = const Color(0xFF7E57C2));
      }
    }
    if (profundo > 0) {
      c.drawRect(r, Paint()..color = Color.fromRGBO(0, 8, 20, 0.85 * profundo));
    }
    // marcação discreta das faixas
    for (final y in _lanes) {
      c.drawLine(Offset(0, y + 52), Offset(_W, y + 52), Paint()..color = const Color(0x12FFFFFF)..strokeWidth = 1);
    }
  }

  void _ent(Canvas c, _Ent e) {
    switch (e.tipo) {
      case _Tipo.rede:
        if (!Arte.desenhar(c, 'rede_cai', Rect.fromCenter(center: Offset(e.x, e.y), width: 120, height: 112))) {
          desenharRede(c, Rect.fromCenter(center: Offset(e.x, e.y), width: 96, height: 96));
        }
        break;
      case _Tipo.saco:
        desenharSaco(c, e.x, e.y, s.t);
        break;
      case _Tipo.krill:
        desenharKrill(c, e.x, e.y, s.t);
        break;
      case _Tipo.escudo:
      case _Tipo.dobro:
        final cor = e.tipo == _Tipo.escudo ? const Color(0xFF26C6DA) : const Color(0xFFFFCA28);
        final pulso = 1 + math.sin(s.t * 6) * 0.08;
        c.drawCircle(Offset(e.x, e.y), 30 * pulso, Paint()..color = cor.withValues(alpha: 0.35));
        c.drawCircle(Offset(e.x, e.y), 30 * pulso, Paint()..color = cor..style = PaintingStyle.stroke..strokeWidth = 4);
        final tp = TextPainter(
          text: TextSpan(text: e.tipo == _Tipo.escudo ? '🛡️' : 'x2', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Colors.white)),
          textDirection: TextDirection.ltr,
        )..layout();
        tp.paint(c, Offset(e.x - tp.width / 2, e.y - tp.height / 2));
        break;
      case _Tipo.resp:
        final rr = RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(e.x, e.y), width: 250, height: 82), const Radius.circular(40));
        c.drawRRect(rr, Paint()..color = const Color(0xE6E8FAFF));
        c.drawRRect(rr, Paint()..color = const Color(0xFF39B5C9)..style = PaintingStyle.stroke..strokeWidth = 4);
        final tp = e.tp!;
        tp.paint(c, Offset(e.x - tp.width / 2, e.y - tp.height / 2));
        break;
    }
  }

  void _baleia(Canvas c) {
    final s = this.s;
    if (s.fase == _Fase.derrota) return _baleiaDerrota(c);
    var y = s.whaleY;
    var tilt = (_lanes[s.lane] - s.whaleY) / 220;
    var x = _whaleX;
    if (s.fase == _Fase.vitoria) {
      final p = (s.tFim % 1.6) / 1.6;
      y = _lanes[1] - math.sin(p * math.pi) * 130;
      tilt = -0.35 * math.cos(p * math.pi);
    }
    // escudo
    if (s.escudoT > 0) {
      final a = s.escudoT < 2 ? (math.sin(s.t * 20) > 0 ? 0.5 : 0.15) : 0.4;
      c.drawCircle(Offset(x, y), 125, Paint()..color = const Color(0xFF26C6DA).withValues(alpha: a));
      c.drawCircle(Offset(x, y), 125, Paint()..color = Colors.white.withValues(alpha: a + 0.2)..style = PaintingStyle.stroke..strokeWidth = 3);
    }
    final pisca = s.invuln > 0 && (s.t * 14).floor() % 2 == 0;
    desenharBaleia(c, x, y, boca: s.boca, tilt: tilt, t: s.t, opacidade: pisca ? 0.35 : 1);
  }

  // -------- sequência de derrota: rede cai, baleia é içada, rede solta, afunda
  void _baleiaDerrota(Canvas c) {
    final td = s.tFim;
    if (Arte.quadros('derrota') > 0) {
      Arte.quadro(c, 'derrota', (td * 12).floor(), const Rect.fromLTWH(0, 0, _W, _H));
      final fim = Arte.quadros('derrota') / 12;
      if (td > fim) {
        c.drawRect(const Rect.fromLTWH(0, 0, _W, _H), Paint()..color = Color.fromRGBO(0, 8, 20, _ease((td - fim) / 0.8) * 0.7));
      }
      return;
    }
    final y0 = s.whaleY;
    double wy = y0, tilt = 0, redeTopo = -400, redeOp = 1;
    if (td < 1.4) {
      final p = _ease(td / 1.4);
      redeTopo = -330 + p * (y0 - 110 + 330);
      tilt = math.sin(td * 10) * 0.08 * p;
    } else if (td < 3.2) {
      final p = _ease((td - 1.4) / 1.8);
      wy = y0 - p * (y0 - 120);
      redeTopo = wy - 110;
      tilt = math.sin(td * 12) * 0.2;
    } else if (td < 3.9) {
      final p = _ease((td - 3.2) / 0.7);
      wy = 120 + p * 40;
      redeTopo = 120 - 110 - p * 90;
      redeOp = 1 - p;
      tilt = 0.2 + p * 0.5;
    } else {
      final p = _ease((td - 3.9) / 2.3);
      wy = 160 + p * 380;
      tilt = 0.7 + p * 0.9;
      redeOp = 0;
      if (s._rnd.nextDouble() < 0.5) {
        s.bolhas.add(_Bolha(_whaleX + s._rnd.nextDouble() * 120 - 60, wy, 2 + s._rnd.nextDouble() * 4, 60 + s._rnd.nextDouble() * 60));
      }
    }
    // barco e corda
    if (td > 1.0 && td < 3.9) {
      final bx = _W - 260 + (td < 1.6 ? (1.6 - td) * 300 : 0);
      if (!Arte.desenhar(c, 'barco', Rect.fromLTWH(bx - 120, -30, 300, 150))) {
        final casco = Path()
          ..moveTo(bx - 110, 20)
          ..lineTo(bx + 120, 20)
          ..lineTo(bx + 90, 62)
          ..lineTo(bx - 80, 62)
          ..close();
        c.drawPath(casco, Paint()..color = const Color(0xFF5D4037));
        c.drawRect(Rect.fromLTWH(bx - 20, -10, 10, 32), Paint()..color = const Color(0xFF3E2723));
        c.drawRect(Rect.fromLTWH(bx - 60, 6, 70, 14), Paint()..color = const Color(0xFFEFEBE9));
      }
      c.drawLine(Offset(bx - 70, 40), Offset(_whaleX, wy - 100), Paint()..color = const Color(0xFFD7CCC8)..strokeWidth = 4);
    }
    // quadro cheio opcional (imagens geradas)
    if (td >= 0.8 && td < 3.2 && Arte.get('baleia_pescada') != null) {
      final a = _ease((td - 0.8) / 0.8) * (td > 2.6 ? 1 - _ease((td - 2.6) / 0.6) : 1);
      Arte.cobrir(c, 'baleia_pescada', const Rect.fromLTWH(0, 0, _W, _H));
      c.drawRect(const Rect.fromLTWH(0, 0, _W, _H), Paint()..color = Color.fromRGBO(0, 0, 0, 1 - a));
    }
    desenharBaleia(c, _whaleX, wy, boca: 0.4, tilt: tilt, t: s.t * 0.4);
    if (redeOp > 0) {
      desenharRede(c, Rect.fromLTWH(_whaleX - 150, redeTopo, 300, 220), opacidade: redeOp);
    }
    if (td >= 3.9 && Arte.get('baleia_afunda') != null) {
      final a = _ease((td - 3.9) / 1.5);
      Arte.cobrir(c, 'baleia_afunda', const Rect.fromLTWH(0, 0, _W, _H));
      c.drawRect(const Rect.fromLTWH(0, 0, _W, _H), Paint()..color = Color.fromRGBO(0, 0, 0, 1 - a));
    }
  }

  void _derrotaTela(Canvas c) {}

  void _confete(Canvas c) {
    final cores = [Colors.amber, Colors.pinkAccent, Colors.lightBlueAccent, Colors.lightGreenAccent];
    for (var i = 0; i < 60; i++) {
      final x = (i * 97.0 + math.sin(i * 12.9) * 200) % _W;
      final y = ((s.tFim * 140 + i * 53) % (_H + 40)) - 20;
      c.save();
      c.translate(x, y);
      c.rotate(s.tFim * 3 + i);
      c.drawRect(const Rect.fromLTWH(-5, -3, 10, 6), Paint()..color = cores[i % 4]);
      c.restore();
    }
  }
}
