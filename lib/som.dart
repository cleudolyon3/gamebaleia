import 'package:audioplayers/audioplayers.dart';

/// Sons do jogo (arquivos em assets/audio). Se algum arquivo faltar ou o
/// áudio falhar, o jogo continua normalmente, só sem o som.
///
/// IMPORTANTE (Windows): criar e destruir AudioPlayer a todo momento (e destruir
/// dentro do callback de "terminou") derruba o aplicativo inteiro. Por isso aqui
/// existe um conjunto FIXO de players que são reaproveitados e nunca destruídos.
class Som {
  static bool mudo = false;

  static const int _tamPool = 4;
  static final List<AudioPlayer> _pool = [];
  static int _prox = 0;
  static final Map<String, int> _ultimo = {};
  static final Map<String, AudioPlayer> _loops = {};
  static bool _quebrou = false; // se o áudio falhar de vez, desliga sem derrubar o jogo

  static AudioPlayer _proximoPlayer() {
    if (_pool.length < _tamPool) {
      final p = AudioPlayer();
      _pool.add(p);
      return p;
    }
    final p = _pool[_prox];
    _prox = (_prox + 1) % _tamPool;
    return p;
  }

  /// Toca um efeito curto. [gapMs] evita repetir o mesmo som muito rápido.
  static Future<void> tocar(String nome, {double vol = 0.8, int gapMs = 120}) async {
    if (mudo || _quebrou) return;
    final agora = DateTime.now().millisecondsSinceEpoch;
    if (gapMs > 0 && agora - (_ultimo[nome] ?? 0) < gapMs) return;
    _ultimo[nome] = agora;
    try {
      final p = _proximoPlayer();
      await p.stop();
      await p.setReleaseMode(ReleaseMode.stop);
      await p.setVolume(vol);
      await p.play(AssetSource('audio/$nome.wav'));
    } catch (_) {
      _quebrou = true;
    }
  }

  /// Liga ou desliga um som em repetição (mar, tensão do navio).
  /// O player do loop é criado uma vez e só pausa/retoma (nunca é destruído).
  static Future<void> loop(String nome, bool ligar, {double vol = 0.5}) async {
    if (_quebrou) return;
    try {
      var p = _loops[nome];
      if (!ligar) {
        if (p != null) await p.pause();
        return;
      }
      if (mudo) return;
      if (p == null) {
        p = AudioPlayer();
        _loops[nome] = p;
        await p.setReleaseMode(ReleaseMode.loop);
        await p.setVolume(vol);
        await p.play(AssetSource('audio/$nome.wav'));
      } else {
        await p.setVolume(vol);
        await p.resume();
      }
    } catch (_) {
      _quebrou = true;
    }
  }

  static Future<void> pararTudo() async {
    for (final n in _loops.keys.toList()) {
      await loop(n, false);
    }
    for (final p in _pool) {
      try {
        await p.stop();
      } catch (_) {}
    }
  }
}
