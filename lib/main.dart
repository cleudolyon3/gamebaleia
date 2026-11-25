import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'arte.dart';
import 'baleia.dart';
import 'corrida.dart';
import 'memoria.dart';
import 'placar.dart';
import 'resgate.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Arte.carregar();
  Arte.carregarSeq('derrota');
  Arte.carregarSeq('intro');
  runApp(const MostraApp());
}

class MostraApp extends StatelessWidget {
  const MostraApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Jogos da Mostra',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF0E7C9B), brightness: Brightness.dark),
      ),
      home: const MenuTela(),
    );
  }
}

class MenuTela extends StatefulWidget {
  const MenuTela({super.key});
  @override
  State<MenuTela> createState() => _MenuTelaState();
}

class _Item {
  final String titulo, sub;
  final VoidCallback acao;
  const _Item(this.titulo, this.sub, this.acao);
}

class _MenuTelaState extends State<MenuTela> with SingleTickerProviderStateMixin {
  late final Ticker _tk;
  double _t = 0;
  final _ctl = TextEditingController();
  final _foco = FocusNode();
  String _nome = '';
  int _sel = 0;
  final _focoNome = FocusNode();

  @override
  void initState() {
    super.initState();
    _tk = createTicker((d) => setState(() => _t = d.inMicroseconds / 1e6))..start();
    Placar.nome().then((n) {
      if (mounted) {
        setState(() => _nome = n);
        _ctl.text = n;
        _ctl.selection = TextSelection(baseOffset: 0, extentOffset: n.length);
      }
    });
  }

  @override
  void dispose() {
    _tk.dispose();
    _ctl.dispose();
    _foco.dispose();
    _focoNome.dispose();
    super.dispose();
  }

  Future<void> _abrir(Widget tela) async {
    if (!mounted) return;
    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => tela));
    if (mounted) _foco.requestFocus();
  }

  void _nomeAlterado(String v) {
    _nome = v.trim();
    Placar.salvarNome(v);
  }

  void _irParaMenu() {
    Placar.salvarNome(_ctl.text);
    _nome = _ctl.text.trim();
    _focoNome.unfocus();
    _foco.requestFocus();
    setState(() {});
  }

  List<_Item> get _itens => [
        _Item('🐋  Corrida da Baleia', 'Ação em 3 fases! Salve a baleia e o filhote', () => _abrir(const CorridaTela())),
        _Item('🧠  Jogo da Memória', 'Encontre os pares da cultura e do mar', () => _abrir(const MemoriaTela())),
        _Item('🛟  Resgate da Baleia', 'Abra as comportas e leve-a ao mar', () => _abrir(const ResgateTela())),
        _Item('🏆  Ranking', 'Melhores pontuações neste computador', () => _abrir(const RankingTela())),
      ];

  KeyEventResult _tecla(FocusNode node, KeyEvent e) {
    if (e is! KeyDownEvent) return KeyEventResult.ignored;
    if (_focoNome.hasFocus) return KeyEventResult.ignored; // digitando o nome
    final k = e.logicalKey;
    final n = _itens.length;
    if (k == LogicalKeyboardKey.arrowUp || k == LogicalKeyboardKey.keyW) {
      setState(() => _sel = (_sel + n - 1) % n);
      return KeyEventResult.handled;
    }
    if (k == LogicalKeyboardKey.arrowDown || k == LogicalKeyboardKey.keyS) {
      setState(() => _sel = (_sel + 1) % n);
      return KeyEventResult.handled;
    }
    if (k == LogicalKeyboardKey.enter || k == LogicalKeyboardKey.numpadEnter || k == LogicalKeyboardKey.space) {
      _itens[_sel].acao();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final itens = _itens;
    return Scaffold(
      body: Focus(
        focusNode: _foco,
        autofocus: true,
        onKeyEvent: _tecla,
        child: Stack(children: [
          Positioned.fill(child: CustomPaint(painter: _MenuPainter(_t))),
          Center(
            child: SingleChildScrollView(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                const Text('Costa das Baleias', style: TextStyle(fontSize: 44, fontWeight: FontWeight.w900, color: Colors.white, shadows: [Shadow(blurRadius: 12, color: Colors.black54)])),
                const Text('Mostra • Consciência Negra e Biodiversidade', style: TextStyle(fontSize: 18, color: Colors.white70)),
                const SizedBox(height: 14),
                _campoNome(),
                const SizedBox(height: 8),
                for (var i = 0; i < itens.length; i++) _botao(i, itens[i]),
                const SizedBox(height: 12),
                const Text('Digite o nome e Enter   •   ↑ ↓ escolhem   •   Enter abre   •   Esc volta',
                    style: TextStyle(fontSize: 16, color: Colors.white70, shadows: [Shadow(blurRadius: 8, color: Colors.black87)])),
              ]),
            ),
          ),
        ]),
      ),
    );
  }

  // campo do nome sempre aberto: é só digitar. Enter ou seta para baixo vai para os jogos.
  Widget _campoNome() {
    return SizedBox(
      width: 460,
      child: Focus(
        onKeyEvent: (n, e) {
          if (e is KeyDownEvent && e.logicalKey == LogicalKeyboardKey.arrowDown) {
            _irParaMenu();
            return KeyEventResult.handled;
          }
          return KeyEventResult.ignored;
        },
        child: TextField(
          controller: _ctl,
          focusNode: _focoNome,
          autofocus: true,
          maxLength: 20,
          textInputAction: TextInputAction.done,
          onChanged: _nomeAlterado,
          onSubmitted: (_) => _irParaMenu(),
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Colors.white),
          decoration: InputDecoration(
            filled: true,
            fillColor: const Color(0xCC06202E),
            border: const OutlineInputBorder(),
            labelText: '✏️  Seu nome (aparece no ranking)',
            hintText: 'Digite seu nome e aperte Enter',
            counterText: '',
            suffixIcon: IconButton(icon: const Icon(Icons.check_circle, color: Color(0xFFFFB300)), onPressed: _irParaMenu),
          ),
        ),
      ),
    );
  }

  Widget _botao(int i, _Item it) {
    final sel = i == _sel;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: SizedBox(
        width: 460,
        child: FilledButton(
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.all(14),
            backgroundColor: sel ? const Color(0xFF1389A0) : const Color(0xDD0E6E8C),
            side: sel ? const BorderSide(color: Color(0xFFFFB300), width: 4) : null,
          ),
          onPressed: () {
            Placar.salvarNome(_ctl.text);
            setState(() => _sel = i);
            it.acao();
          },
          child: Column(children: [
            Text(it.titulo, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
            Text(it.sub, style: const TextStyle(fontSize: 14, color: Colors.white70)),
          ]),
        ),
      ),
    );
  }
}

class _MenuPainter extends CustomPainter {
  final double t;
  _MenuPainter(this.t);
  @override
  bool shouldRepaint(covariant CustomPainter old) => true;

  @override
  void paint(Canvas c, Size size) {
    final r = Offset.zero & size;
    if (!Arte.cobrir(c, 'fundo_menu', r)) c.drawRect(r, pincelAgua(r));
    for (var i = 0; i < 25; i++) {
      final x = (i * 83.0 + math.sin(t + i) * 20) % size.width;
      final y = size.height - ((t * (20 + i * 3) + i * 70) % (size.height + 20));
      c.drawCircle(Offset(x, y), 2 + (i % 5), Paint()..color = const Color(0x44FFFFFF));
    }
    // baleia nadando de tempos em tempos abre a boca
    final ciclo = (t % 14) / 14;
    final x = -200 + ciclo * (size.width + 400);
    final y = size.height * 0.28 + math.sin(t * 1.2) * 20;
    final boca = (math.sin(t * 1.6) > 0.5) ? 1.0 : 0.0;
    desenharBaleia(c, x, y, escala: 1.3, boca: boca, tilt: math.sin(t * 1.2) * 0.06, t: t);
  }
}

class RankingTela extends StatefulWidget {
  const RankingTela({super.key});
  @override
  State<RankingTela> createState() => _RankingTelaState();
}

class _RankingTelaState extends State<RankingTela> with SingleTickerProviderStateMixin {
  List<RegistroPlacar> _l = [];
  // nomes iguais aos usados em Placar.registrar (não mudar, senão o ranking antigo some da aba)
  static const _abas = ['Geral', '🐋 Corrida', '🧠 Memória', '🛟 Resgate'];
  static const List<String?> _jogos = [null, 'Corrida da Baleia', 'Memória', 'Resgate da Baleia'];
  late final TabController _tab = TabController(length: _abas.length, vsync: this);
  final _foco = FocusNode();

  @override
  void initState() {
    super.initState();
    Placar.todos().then((l) {
      if (mounted) setState(() => _l = l);
    });
  }

  @override
  void dispose() {
    _tab.dispose();
    _foco.dispose();
    super.dispose();
  }

  KeyEventResult _tecla(FocusNode node, KeyEvent e) {
    if (e is! KeyDownEvent) return KeyEventResult.ignored;
    final k = e.logicalKey;
    if (k == LogicalKeyboardKey.arrowLeft || k == LogicalKeyboardKey.keyA) {
      _tab.animateTo(math.max(0, _tab.index - 1));
      return KeyEventResult.handled;
    }
    if (k == LogicalKeyboardKey.arrowRight || k == LogicalKeyboardKey.keyD) {
      _tab.animateTo(math.min(_abas.length - 1, _tab.index + 1));
      return KeyEventResult.handled;
    }
    if (k == LogicalKeyboardKey.escape || k == LogicalKeyboardKey.enter || k == LogicalKeyboardKey.numpadEnter) {
      Navigator.of(context).maybePop();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  Widget _lista(String? jogo) {
    final l = jogo == null ? _l : _l.where((r) => r.jogo == jogo).toList();
    if (l.isEmpty) {
      return const Center(child: Text('Ainda ninguém jogou. Seja o primeiro!', style: TextStyle(fontSize: 20)));
    }
    return ListView.builder(
      itemCount: math.min(l.length, 30),
      itemBuilder: (_, i) {
        final r = l[i];
        const medalha = ['🥇', '🥈', '🥉'];
        return ListTile(
          leading: Text(i < 3 ? medalha[i] : '${i + 1}º', style: const TextStyle(fontSize: 26)),
          title: Text(r.nome, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 20)),
          subtitle: Text(jogo == null ? '${r.jogo} • ${r.data}' : r.data),
          trailing: Text('${r.pontos}', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Color(0xFFFFE082))),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🏆 Ranking   (← → trocam de aba, Esc volta)'),
        backgroundColor: const Color(0xFF06202E),
        bottom: TabBar(controller: _tab, tabs: [for (final a in _abas) Tab(text: a)]),
      ),
      body: Focus(
        focusNode: _foco,
        autofocus: true,
        onKeyEvent: _tecla,
        child: TabBarView(controller: _tab, children: [for (final j in _jogos) _lista(j)]),
      ),
    );
  }
}
