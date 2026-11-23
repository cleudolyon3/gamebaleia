import 'dart:convert';
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

/// Ranking local (salvo no próprio computador, funciona offline).
class Placar {
  static const _kNome = 'nome_jogador';
  static const _kRank = 'ranking_v1';

  static Future<String> nome() async =>
      (await SharedPreferences.getInstance()).getString(_kNome) ?? '';

  static Future<void> salvarNome(String n) async =>
      (await SharedPreferences.getInstance()).setString(_kNome, n.trim());

  static Future<List<RegistroPlacar>> todos() async {
    final p = await SharedPreferences.getInstance();
    final raw = p.getString(_kRank);
    if (raw == null) return [];
    try {
      final l = (jsonDecode(raw) as List)
          .map((e) => RegistroPlacar.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
      l.sort((a, b) => b.pontos.compareTo(a.pontos));
      return l;
    } catch (_) {
      return [];
    }
  }

  static Future<void> registrar(String jogo, int pontos) async {
    final nome = (await Placar.nome()).isEmpty ? 'Visitante' : await Placar.nome();
    final l = await todos();
    final d = DateTime.now();
    l.add(RegistroPlacar(nome, jogo, pontos, '${d.day}/${d.month}'));
    l.sort((a, b) => b.pontos.compareTo(a.pontos));
    final p = await SharedPreferences.getInstance();
    await p.setString(_kRank, jsonEncode(l.take(100).map((e) => e.toJson()).toList()));
  }

  static Future<void> limpar() async =>
      (await SharedPreferences.getInstance()).remove(_kRank);
}
