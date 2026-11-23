import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
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

class _MenuTelaState extends State<MenuTela> with SingleTickerProviderStateMixin {
  late final Ticker _tk;
  double _t = 0;
  final _nome = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tk = createTicker((d) => setState(() => _t = d.inMicroseconds / 1e6))..start();
    Placar.nome().then((n) => _nome.text = n);
  }

  @override
  void dispose() {
    _tk.dispose();
    _nome.dispose();
    super.dispose();
  }

  Future<void> _abrir(Widget tela) async {
    await Placar.salvarNome(_nome.text);
    if (!mounted) return;
    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => tela));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(children: [
        Positioned.fill(child: CustomPaint(painter: _MenuPainter(_t))),
        Center(
          child: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              const Text('Costa das Baleias', style: TextStyle(fontSize: 44, fontWeight: FontWeight.w900, color: Colors.white, shadows: [Shadow(blurRadius: 12, color: Colors.black54)])),
              const Text('Mostra • Consciência Negra e Biodiversidade', style: TextStyle(fontSize: 18, color: Colors.white70)),
              const SizedBox(height: 18),
              SizedBox(
                width: 320,
                child: TextField(
                  controller: _nome,
                  textAlign: TextAlign.center,
                  maxLength: 20,
                  decoration: const InputDecoration(
                    labelText: 'Seu nome (para o ranking)',
                    filled: true,
                    fillColor: Color(0x99000000),
                    border: OutlineInputBorder(),
                    counterText: '',
                  ),
                ),
              ),
              const SizedBox(height: 14),
              _botao('🐋  Corrida da Baleia', 'Ação! Coma, fuja da rede e responda', () => _abrir(const CorridaTela())),
              _botao('🧠  Jogo da Memória', 'Encontre os pares da cultura e do mar', () => _abrir(const MemoriaTela())),
              _botao('🛟  Resgate da Baleia', 'Abra as comportas e leve-a ao mar', () => _abrir(const ResgateTela())),
              _botao('🏆  Ranking', 'Melhores pontuações neste computador', () => _abrir(const RankingTela())),
            ]),
          ),
        ),
      ]),
    );
  }

  Widget _botao(String t, String sub, VoidCallback f) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: SizedBox(
          width: 420,
          child: FilledButton(
            style: FilledButton.styleFrom(padding: const EdgeInsets.all(14), backgroundColor: const Color(0xDD0E6E8C)),
            onPressed: f,
            child: Column(children: [
              Text(t, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
              Text(sub, style: const TextStyle(fontSize: 14, color: Colors.white70)),
            ]),
          ),
        ),
      );
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

class _RankingTelaState extends State<RankingTela> {
  List<RegistroPlacar> _l = [];
  @override
  void initState() {
    super.initState();
    Placar.todos().then((l) => setState(() => _l = l));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('🏆 Ranking'), backgroundColor: const Color(0xFF06202E), actions: [
        TextButton(
          onPressed: () async {
            await Placar.limpar();
            setState(() => _l = []);
          },
          child: const Text('Limpar'),
        )
      ]),
      body: _l.isEmpty
          ? const Center(child: Text('Ainda ninguém jogou. Seja o primeiro!', style: TextStyle(fontSize: 20)))
          : ListView.builder(
              itemCount: math.min(_l.length, 30),
              itemBuilder: (_, i) {
                final r = _l[i];
                const medalha = ['🥇', '🥈', '🥉'];
                return ListTile(
                  leading: Text(i < 3 ? medalha[i] : '${i + 1}º', style: const TextStyle(fontSize: 26)),
                  title: Text(r.nome, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 20)),
                  subtitle: Text('${r.jogo} • ${r.data}'),
                  trailing: Text('${r.pontos}', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Color(0xFFFFE082))),
                );
              },
            ),
    );
  }
}
