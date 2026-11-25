import 'dart:convert';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';

class RegistroPlacar {
  final String nome, jogo;
  final int pontos;
  final String data;
  RegistroPlacar(this.nome, this.jogo, this.pontos, this.data);
  Map<String, dynamic> toJson() => {'n': nome, 'j': jogo, 'p': pontos, 'd': data};
  static RegistroPlacar fromJson(Map<String, dynamic> m) =>
      RegistroPlacar(m['n'] as String, m['j'] as String, (m['p'] as num).toInt(), m['d'] as String);
}

/// Ranking local. Fica salvo em ARQUIVO (ranking_mostra.json) e não existe opção de apagar.
///
/// Cópias gravadas a cada partida:
///  1) ranking_mostra.json na pasta do jogo (junto do .exe), fácil de achar e copiar;
///  2) ranking_mostra.json em AppData\JogosDaMostra (Windows) ou ~/JogosDaMostra (Mac/Linux);
///  3) o armazenamento antigo (shared_preferences), que mantém os placares das versões anteriores.
/// Ao ler, as três fontes são unidas, então nada se perde ao atualizar o jogo.
class Placar {
  static const _kNome = 'nome_jogador';
  static const _kRank = 'ranking_v1'; // não mudar: guarda o ranking das versões antigas
  static const _arquivo = 'ranking_mostra.json';
  static const _maximo = 2000;

  static Future<String> nome() async =>
      (await SharedPreferences.getInstance()).getString(_kNome) ?? '';

  static Future<void> salvarNome(String n) async =>
      (await SharedPreferences.getInstance()).setString(_kNome, n.trim());

  static List<File> _arquivos() {
    final l = <File>[];
    final sep = Platform.pathSeparator;
    try {
      l.add(File('${File(Platform.resolvedExecutable).parent.path}$sep$_arquivo'));
    } catch (_) {}
    try {
      final env = Platform.environment;
      final base = env['APPDATA'] ?? env['HOME'];
      if (base != null) {
        final pasta = env['APPDATA'] != null ? 'JogosDaMostra' : '.jogos_da_mostra';
        l.add(File('$base$sep$pasta$sep$_arquivo'));
      }
    } catch (_) {}
    return l;
  }

  static List<RegistroPlacar> _decodificar(String raw) {
    try {
      return (jsonDecode(raw) as List)
          .map((e) => RegistroPlacar.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
    } catch (_) {
      return [];
    }
  }

  static String _chave(RegistroPlacar r) => '${r.nome}|${r.jogo}|${r.pontos}|${r.data}';

  // une as fontes sem duplicar (registros iguais em fontes diferentes contam uma vez)
  static List<RegistroPlacar> _uniao(List<List<RegistroPlacar>> fontes) {
    final maior = <String, int>{};
    final amostra = <String, RegistroPlacar>{};
    for (final fonte in fontes) {
      final c = <String, int>{};
      for (final r in fonte) {
        final k = _chave(r);
        c[k] = (c[k] ?? 0) + 1;
        amostra[k] = r;
      }
      c.forEach((k, v) {
        if (v > (maior[k] ?? 0)) maior[k] = v;
      });
    }
    final out = <RegistroPlacar>[];
    maior.forEach((k, v) {
      for (var i = 0; i < v; i++) {
        out.add(amostra[k]!);
      }
    });
    out.sort((a, b) => b.pontos.compareTo(a.pontos));
    return out;
  }

  static Future<List<RegistroPlacar>> todos() async {
    final fontes = <List<RegistroPlacar>>[];
    try {
      final p = await SharedPreferences.getInstance();
      fontes.add(_decodificar(p.getString(_kRank) ?? ''));
    } catch (_) {}
    for (final f in _arquivos()) {
      try {
        if (await f.exists()) fontes.add(_decodificar(await f.readAsString()));
      } catch (_) {}
    }
    return _uniao(fontes);
  }

  static Future<List<RegistroPlacar>> doJogo(String jogo) async =>
      (await todos()).where((r) => r.jogo == jogo).toList();

  static Future<void> registrar(String jogo, int pontos) async {
    final n = await Placar.nome();
    final l = await todos();
    final d = DateTime.now();
    l.add(RegistroPlacar(n.isEmpty ? 'Visitante' : n, jogo, pontos, '${d.day}/${d.month}'));
    l.sort((a, b) => b.pontos.compareTo(a.pontos));
    final json = jsonEncode(l.take(_maximo).map((e) => e.toJson()).toList());
    try {
      final p = await SharedPreferences.getInstance();
      await p.setString(_kRank, json);
    } catch (_) {}
    for (final f in _arquivos()) {
      try {
        await f.parent.create(recursive: true);
        await f.writeAsString(json, flush: true);
      } catch (_) {}
    }
  }
}
