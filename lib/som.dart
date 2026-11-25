import 'package:audioplayers/audioplayers.dart';

/// Sons do jogo (arquivos em assets/audio). Se algum arquivo faltar ou o
/// áudio falhar, o jogo continua normalmente, só sem o som.
class Som {
  static bool mudo = false;
  static final Map<String, AudioPlayer> _loops = {};
  static final Map<String, int> _ultimo = {};
  static int _ativos = 0;

  /// Toca um efeito curto. [gapMs] evita repetir o mesmo som muito rápido.
  static Future<void> tocar(String nome, {double vol = 0.8, int gapMs = 0}) async {
    if (mudo || _ativos >= 8) return;
    final agora = DateTime.now().millisecondsSinceEpoch;
    if (gapMs > 0 && agora - (_ultimo[nome] ?? 0) < gapMs) return;
    _ultimo[nome] = agora;
    try {
      final p = AudioPlayer();
      _ativos++;
      p.onPlayerComplete.listen((_) {
        _ativos--;
        p.dispose();
      });
      await p.setVolume(vol);
      await p.play(AssetSource('audio/$nome.wav'));
    } catch (_) {
      if (_ativos > 0) _ativos--;
    }
  }

  /// Liga ou desliga um som em repetição (mar, tensão do navio).
  static Future<void> loop(String nome, bool ligar, {double vol = 0.5}) async {
    try {
      final atual = _loops[nome];
      if (!ligar) {
        if (atual != null) {
          _loops.remove(nome);
          await atual.stop();
          await atual.dispose();
        }
        return;
      }
      if (atual != null || mudo) return;
      final p = AudioPlayer();
      _loops[nome] = p;
      await p.setReleaseMode(ReleaseMode.loop);
      await p.setVolume(vol);
      await p.play(AssetSource('audio/$nome.wav'));
    } catch (_) {}
  }

  static Future<void> pararTudo() async {
    for (final n in _loops.keys.toList()) {
      await loop(n, false);
    }
  }
}
