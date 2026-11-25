import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'placar.dart';

class _Simbolo {
  final String emoji, nome, fato;
  const _Simbolo(this.emoji, this.nome, this.fato);
}

const _simbolos = [
  _Simbolo('🐋', 'Baleia jubarte', 'Abrolhos é refúgio e berçário das baleias jubarte.'),
  _Simbolo('🐠', 'Peixe', 'Os recifes de Abrolhos têm a maior biodiversidade do Atlântico Sul.'),
  _Simbolo('🪸', 'Coral', 'Preservar o meio ambiente protege a biodiversidade local.'),
  _Simbolo('🖐️', 'Mão rupestre', 'A arte rupestre é uma das formas mais antigas de expressão humana.'),
  _Simbolo('☀️', 'Sol', 'Sóis e espirais aparecem na pintura corporal das fotos da mostra.'),
  _Simbolo('🛶', 'Canoa', 'O mar liga Prado, Alcobaça, Caravelas, Nova Viçosa e Mucuri.'),
  _Simbolo('🧵', 'Kente', 'O kente é um tecido tradicional de Gana, feito de faixas coloridas.'),
  _Simbolo('🎵', 'Berimbau', 'O berimbau acompanha a capoeira, arte afro-brasileira.'),
];

class MemoriaTela extends StatefulWidget {
  const MemoriaTela({super.key});
  @override
  State<MemoriaTela> createState() => _MemoriaTelaState();
}

class _MemoriaTelaState extends State<MemoriaTela> {
  late List<int> _cartas;
  final Set<int> _viradas = {};
  final Set<int> _achadas = {};
  int? _primeira;
  bool _trava = false;
  int _erros = 0, _seg = 0;
  Timer? _timer;
  String _fato = 'Encontre os pares!';
  bool _fim = false;
  int _pontos = 0;
  int _cur = 0; // carta selecionada pelo teclado
  final _foco = FocusNode();

  @override
  void initState() {
    super.initState();
    _novo();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _foco.dispose();
    super.dispose();
  }

  void _novo() {
    _timer?.cancel();
    _cartas = [for (var i = 0; i < _simbolos.length; i++) ...[i, i]]..shuffle(math.Random());
    _viradas.clear();
    _achadas.clear();
    _primeira = null;
    _trava = false;
    _erros = 0;
    _seg = 0;
    _fim = false;
    _cur = 0;
    _fato = 'Encontre os pares!';
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted && !_fim) setState(() => _seg++);
    });
    setState(() {});
  }

  void _toca(int i) {
    if (_trava || _fim || _viradas.contains(i) || _achadas.contains(i)) return;
    setState(() => _viradas.add(i));
    if (_primeira == null) {
      _primeira = i;
      return;
    }
    final a = _primeira!;
    _primeira = null;
    if (_cartas[a] == _cartas[i]) {
      setState(() {
        _achadas.addAll([a, i]);
        _fato = '${_simbolos[_cartas[i]].emoji} ${_simbolos[_cartas[i]].nome}: ${_simbolos[_cartas[i]].fato}';
      });
      if (_achadas.length == _cartas.length) _terminar();
    } else {
      _trava = true;
      _erros++;
      Timer(const Duration(milliseconds: 850), () {
        if (!mounted) return;
        setState(() {
          _viradas.remove(a);
          _viradas.remove(i);
          _trava = false;
        });
      });
    }
  }

  void _terminar() {
    _timer?.cancel();
    _pontos = math.max(100, 1000 - _erros * 40 - _seg * 4);
    Placar.registrar('Memória', _pontos);
    setState(() => _fim = true);
  }

  String get _tempo => '${_seg ~/ 60}:${(_seg % 60).toString().padLeft(2, '0')}';

  KeyEventResult _tecla(FocusNode node, KeyEvent e) {
    if (e is! KeyDownEvent) return KeyEventResult.ignored;
    final k = e.logicalKey;
    if (k == LogicalKeyboardKey.escape) {
      Navigator.of(context).maybePop();
      return KeyEventResult.handled;
    }
    final ok = k == LogicalKeyboardKey.enter || k == LogicalKeyboardKey.numpadEnter || k == LogicalKeyboardKey.space;
    if (_fim) {
      if (ok) {
        _novo();
        return KeyEventResult.handled;
      }
      return KeyEventResult.ignored;
    }
    final n = _cartas.length;
    if (k == LogicalKeyboardKey.arrowLeft || k == LogicalKeyboardKey.keyA) {
      setState(() => _cur = (_cur % 4 == 0) ? _cur + 3 : _cur - 1);
    } else if (k == LogicalKeyboardKey.arrowRight || k == LogicalKeyboardKey.keyD) {
      setState(() => _cur = (_cur % 4 == 3) ? _cur - 3 : _cur + 1);
    } else if (k == LogicalKeyboardKey.arrowUp || k == LogicalKeyboardKey.keyW) {
      setState(() => _cur = (_cur - 4 + n) % n);
    } else if (k == LogicalKeyboardKey.arrowDown || k == LogicalKeyboardKey.keyS) {
      setState(() => _cur = (_cur + 4) % n);
    } else if (ok) {
      _toca(_cur);
    } else {
      return KeyEventResult.ignored;
    }
    return KeyEventResult.handled;
  }

  @override
  Widget build(BuildContext context) {
    return Focus(focusNode: _foco, autofocus: true, onKeyEvent: _tecla, child: _corpo(context));
  }

  Widget _corpo(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🧠 Jogo da Memória'),
        backgroundColor: const Color(0xFF06202E),
        actions: [
          Center(child: Padding(padding: const EdgeInsets.only(right: 16), child: Text('⏱ $_tempo    ❌ $_erros', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)))),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF0E7C9B), Color(0xFF06202E)])),
        child: Column(children: [
          Container(
            width: double.infinity,
            margin: const EdgeInsets.all(12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: const Color(0x66000000), borderRadius: BorderRadius.circular(12)),
            child: Text('$_fato\n(setas movem  •  Enter vira a carta  •  Esc volta)', textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
          ),
          Expanded(
            child: Center(
              child: AspectRatio(
                aspectRatio: 1,
                child: Stack(children: [
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: GridView.count(
                      crossAxisCount: 4,
                      mainAxisSpacing: 10,
                      crossAxisSpacing: 10,
                      physics: const NeverScrollableScrollPhysics(),
                      children: [for (var i = 0; i < _cartas.length; i++) _carta(i)],
                    ),
                  ),
                  if (_fim)
                    Center(
                      child: Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(color: const Color(0xF006202E), borderRadius: BorderRadius.circular(20), border: Border.all(color: const Color(0xFF39B5C9), width: 2)),
                        child: Column(mainAxisSize: MainAxisSize.min, children: [
                          const Text('🎉 Parabéns!', style: TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.w900)),
                          const SizedBox(height: 8),
                          Text('$_pontos pontos  •  $_tempo  •  $_erros erros', style: const TextStyle(color: Color(0xFFFFE082), fontSize: 20, fontWeight: FontWeight.w800)),
                          const SizedBox(height: 14),
                          Row(mainAxisSize: MainAxisSize.min, children: [
                            FilledButton(onPressed: _novo, child: const Text('Jogar de novo (Enter)')),
                            const SizedBox(width: 10),
                            OutlinedButton(onPressed: () => Navigator.of(context).maybePop(), child: const Text('Menu (Esc)', style: TextStyle(color: Colors.white))),
                          ]),
                        ]),
                      ),
                    ),
                ]),
              ),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _carta(int i) {
    final aberta = _viradas.contains(i) || _achadas.contains(i);
    final ok = _achadas.contains(i);
    return GestureDetector(
      onTap: () => _toca(i),
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: aberta ? 1 : 0),
        duration: const Duration(milliseconds: 260),
        builder: (context, v, _) {
          final mostrando = v > 0.5;
          return Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.001)
              ..rotateY(v * math.pi),
            child: Container(
              decoration: BoxDecoration(
                color: mostrando ? (ok ? const Color(0xFFC8E6C9) : const Color(0xFFE8FAFF)) : const Color(0xFF1389A0),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                    color: (i == _cur && !_fim) ? const Color(0xFFFFB300) : (ok ? const Color(0xFF43A047) : Colors.white54),
                    width: (i == _cur && !_fim) ? 6 : 3),
              ),
              alignment: Alignment.center,
              child: mostrando
                  ? Transform(
                      alignment: Alignment.center,
                      transform: Matrix4.identity()..rotateY(math.pi),
                      child: Text(_simbolos[_cartas[i]].emoji, style: const TextStyle(fontSize: 44)),
                    )
                  : const Text('🌊', style: TextStyle(fontSize: 34)),
            ),
          );
        },
      ),
    );
  }
}
