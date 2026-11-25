/// Sem áudio: versão sem o plugin de som (o Windows pedia senha de administrador
/// e bloqueava o jogo). Mantém a mesma interface para o resto do código não mudar.
class Som {
  static bool mudo = true;
  static Future<void> tocar(String nome, {double vol = 0.8, int gapMs = 0}) async {}
  static Future<void> loop(String nome, bool ligar, {double vol = 0.5}) async {}
  static Future<void> pararTudo() async {}
}
