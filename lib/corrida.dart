import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'arte.dart';
import 'baleia.dart';
import 'dados.dart';
import 'placar.dart';
import 'som.dart';

const double _W = 960, _H = 540;
const List<double> _lanes = [175, 290, 405];
const double _whaleX = 210;
const double _tempoResposta = 15;
const double _surfY = 120; // linha da superficie (onde o navio fica)

// Bolinhas das 4 operacoes (+ - x /): a baleia come e os pontos mudam
const int _opCapGanho = 500; // maximo que o x2 pode somar de uma vez
const int _opCapPerda = 250; // maximo que o /2 pode tirar de uma vez

// Anzol: true = pesca na hora quem estiver sendo controlado. false = tira so 1 vida.
const bool _anzolMata = true;
const double _anzOffX = -100; // posicao do anzol em relacao ao centro do navio (ponta do guindaste)
const double _anzTopo = 2; // altura de onde a linha sai do guindaste
const double _anzolH = 80; // altura do anzol desenhado (usada na colisao)
// imagem barco.png (832x569): largura no jogo 210, linha d'agua a 477 px do topo
const double _navioW = 210, _navioH = 143.6, _navioLinha = 120.4;

// Filhote
const int _krillMeta = 20; // krill comidos para o filhote virar baleia adulta
const int _vidasFilhote = 2; // vidas do filhote (ganha +1 ao virar adulto)

// Fases
const List<double> _durFase = [60, 80, 120]; // segundos de travessia de cada fase (a final e a maior)
const int _perguntasBonus = 3; // perguntas opcionais no fim de cada fase
const int _pontosBonus = 100; // pontos por pergunta certa no bonus

// Cargas explosivas: o navio joga, elas afundam e explodem (fases 2 e 3)
const List<bool> _cargasFase = [false, true, true];
const List<int> _maxCargas = [0, 1, 2]; // cargas por navio: fase 2 = 1, fase 3 = ate 2
const List<double> _cargaInt = [0, 1.0, 0.9]; // intervalo base entre cargas (s)
const double _cargaVel = 300; // velocidade de afundar (px/s)
const double _cargaOffX = 70; // onde a carga sai, em relacao ao centro do navio
const double _explRX = 135, _explRY = 100; // alcance da explosao
const double _explDur = 1.3; // duracao da explosao (s)
const List<String> _fNomes = ['Águas de Abrolhos', 'Mar Aberto', 'Rota dos Navios'];
const List<String> _fDicas = [
  'Coma krill e fuja das redes e dos sacos. Bolinhas + e × somam pontos, − e ÷ tiram!',
  'O mar ficou mais fundo e as redes, mais perigosas. Os navios agora jogam uma carga explosiva!',
  'Navios lançam anzóis, redes de arrasto e até 2 cargas explosivas! Saia da faixa marcada em vermelho.',
];
const List<double> _velBase = [215, 250, 285];
const List<double> _pObst = [0.42, 0.52, 0.58];
const List<double> _espMin = [0.95, 0.80, 0.65];
const List<double> _espVar = [0.80, 0.65, 0.50];

// troca = a mae e pescada e o filhote assume o jogo
enum _Fase { pronto, jogando, transicao, oferta, troca, derrota, vitoria }
enum _Tipo { rede, saco, krill, escudo, dobro, op }

class _Ent {
  final _Tipo tipo;
  double x;
  double y;
  final int lane;
  bool morta = false;
  String op = ''; // '+', '−', '×' ou '÷' (so para _Tipo.op)
  int val = 0;
  _Ent(this.tipo, this.x, this.lane) : y = _lanes[lane];
}

class _Navio {
  double x;
  final double alvoY; // profundidade final do olhal do anzol
  int estado = 0; // 0 chegando, 1 anzol baixado, 2 recolhendo
  double anz = 0; // 0 (recolhido) a 1 (totalmente baixado)
  double t = 0;
  int lancadas = 0; // cargas ja jogadas por este navio
  _Navio(this.x, this.alvoY);
  double get tipY => _anzTopo + anz * (alvoY - _anzTopo);
}

// rede de arrasto: um barco puxa uma rede que cobre 2 faixas e deixa 1 livre
class _Arrasto {
  double x;
  final int livre; // faixa (0, 1 ou 2) por onde a baleia pode passar
  double t = 0;
  _Arrasto(this.x, this.livre);
}

// carga explosiva jogada pelo navio: afunda ate a faixa e explode
class _Carga {
  double x, y;
  final double alvoY;
  final int lane;
  bool explodiu = false, atingiu = false;
  double t = 0; // tempo desde a explosao
  _Carga(this.x, this.y, this.lane) : alvoY = _lanes[lane];
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
  double invuln = 0, escudoT = 0, dobroT = 0, tremor = 0, flash = 0, veu = 0;
  final List<_Ent> ents = [];
  final List<_Bolha> bolhas = [];
  final List<_Texto> textos = [];
  double proxSpawn = 1.2;
  bool perguntaAtiva = false, respondida = false;
  int escolhida = -1, sel = 0;
  double tempoPerg = _tempoResposta, feedbackT = 0;
  List<String> opcoesPerg = [];
  int numPergunta = 0;
  Pergunta? perg;
  int certaIdx = 0;
  List<Pergunta> _fila = [];
  String aviso = '';
  bool avisoOk = true;
  double avisoT = 0;
  double tFim = 0;
  bool fimMostrado = false, _registrado = false;

  // fases
  int faseNum = 0;
  double tFase = 0; // tempo de travessia da fase atual
  bool emBonus = false; // perguntas opcionais do fim da fase
  int bonusRestantes = 0, bonusCertas = 0, bonusPerg = 0;
  final List<_Carga> cargas = [];
  double proxCarga = 2;
  int ultCargaLane = -1;
  bool causaBomba = false;
  bool causaGancho = false; // pescada pelo anzol: toca o video do navio antes da cena de derrota
  double faseBannerT = 0;
  int bonusFase = 0;

  // filhote: acompanha a mae, cresce comendo krill e assume o jogo se a mae for pescada
  bool ctrlFilhote = false; // true = o jogador controla o filhote
  bool filhoteVivo = true;
  bool filhoteAdulto = false;
  int vidasF = _vidasFilhote;
  int krillF = 0;
  double filhoteY = _lanes[1] + 64;

  // navio e anzol
  _Navio? navio;
  _Arrasto? arrasto;
  bool redeFeita = false; // a rede de arrasto aparece uma unica vez por partida
  int arrastoFase = 1; // em qual fase ela aparece
  double proxArrasto = -1;
  double proxNavio = 8;
  bool causaAnzol = false;

  // sons
  double proxBaleiaSom = 9, proxGolfSom = 14;
  bool _ambOn = false, _tenOn = false;

  // ranking mostrado no fim
  List<RegistroPlacar> topRank = [];
  int meuIdx = -1;

  int get mult => math.min(5, 1 + combo ~/ 3) * (dobroT > 0 ? 2 : 1);
  // segundos do video do anzol (so quando o anzol pescou)
  double get preDerrota =>
      ((fase == _Fase.derrota || fase == _Fase.troca) && causaGancho && Arte.quadros('pescada') > 0) ? Arte.quadros('pescada') / 12 + 0.3 : 0.0;
  double get tDer => tFim - preDerrota;
  double get _prog => math.min(1.0, tFase / _durFase[faseNum]);
  int get vidasAtual => ctrlFilhote ? vidasF : vidas;
  double get _g => math.min(1.0, krillF / _krillMeta);
  // tamanho de quem o jogador controla (1 = baleia adulta)
  double get tamCtrl => !ctrlFilhote ? 1.0 : (filhoteAdulto ? 1.0 : 0.5 + 0.5 * _g);
  // tamanho do filhote quando so acompanha a mae
  double get tamSeguindo => filhoteAdulto ? 0.85 : 0.4 + 0.45 * _g;
  double get _hit => 0.75 + 0.25 * tamCtrl;

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
    Som.pararTudo();
    super.dispose();
  }

  void _novo() {
    ents.clear();
    cargas.clear();
    textos.clear();
    vidas = 3;
    pontos = acertos = combo = 0;
    invuln = escudoT = dobroT = tremor = flash = veu = 0;
    lane = 1;
    whaleY = _lanes[1];
    perguntaAtiva = false;
    perg = null;
    aviso = '';
    avisoT = 0;
    respondida = false;
    escolhida = -1;
    sel = 0;
    numPergunta = 0;
    tFim = 0;
    fimMostrado = false;
    _registrado = false;
    causaAnzol = false;
    causaGancho = false;
    causaBomba = false;
    emBonus = false;
    bonusFase = 0;
    ctrlFilhote = false;
    filhoteVivo = true;
    filhoteAdulto = false;
    vidasF = _vidasFilhote;
    krillF = 0;
    filhoteY = _lanes[1] + 64;
    navio = null;
    arrasto = null;
    redeFeita = false;
    arrastoFase = 1 + _rnd.nextInt(2);
    proxArrasto = -1;
    topRank = [];
    meuIdx = -1;
    proxBaleiaSom = 6 + _rnd.nextDouble() * 6;
    proxGolfSom = 12 + _rnd.nextDouble() * 8;
    _fila = List.of(perguntasCorrida)..shuffle(_rnd);
    _iniciarFase(0);
    _foco.requestFocus();
  }

  void _iniciarFase(int n) {
    faseNum = n;
    tFase = 0;
    emBonus = false;
    bonusRestantes = 0;
    bonusCertas = 0;
    bonusPerg = 0;
    ents.clear();
    cargas.clear();
    navio = null;
    perguntaAtiva = false;
    perg = null;
    proxSpawn = 1.6;
    proxCarga = 1.5;
    arrasto = null;
    proxArrasto = (!redeFeita && n == arrastoFase) ? 7 + _rnd.nextDouble() * 9 : -1;
    // mais barcos: ja aparecem na fase 1 e passam com mais frequencia
    proxNavio = n == 0 ? 11 + _rnd.nextDouble() * 4 : (n == 1 ? 4 + _rnd.nextDouble() * 3 : 3 + _rnd.nextDouble() * 2.5);
    faseBannerT = 3.0;
    tFim = 0;
    fase = _Fase.jogando;
  }

  void _mover(int d) {
    if (fase != _Fase.jogando || perguntaAtiva) return;
    lane = (lane + d).clamp(0, 2);
  }

  void _tick(Duration d) {
    var dt = (d - _ult).inMicroseconds / 1e6;
    _ult = d;
    if (dt <= 0 || dt > 0.1) dt = 0.016;
    t += dt;
    whaleY += (_lanes[lane] - whaleY) * math.min(1.0, dt * 9);
    filhoteY += (whaleY + 64 - filhoteY) * math.min(1.0, dt * 4.5);
    tremor = math.max(0, tremor - dt * 2.2);
    flash = math.max(0, flash - dt * 2.5);
    veu = math.max(0, veu - dt * 1.0);
    mordida = math.max(0, mordida - dt);
    avisoT = math.max(0, avisoT - dt);
    faseBannerT = math.max(0, faseBannerT - dt);
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
    } else if (fase == _Fase.transicao) {
      ents.clear();
      cargas.clear();
      navio = null;
      arrasto = null;
      tFim += dt;
      boca += ((tFim % 1.2 < 0.5 ? 1.0 : 0.0) - boca) * math.min(1.0, dt * 10);
      if (tFim > 3.4) _iniciarFase(faseNum + 1);
    } else if (fase == _Fase.oferta) {
      ents.clear();
      cargas.clear();
      navio = null;
      arrasto = null;
      boca += (0 - boca) * math.min(1.0, dt * 6);
    } else if (fase == _Fase.troca) {
      ents.clear();
      cargas.clear();
      navio = null;
      arrasto = null;
      tFim += dt;
      boca += (0 - boca) * math.min(1.0, dt * 6);
      final dur = (Arte.quadros('derrota') > 0 ? Arte.quadros('derrota') / 12 + 0.6 : 4.2) + preDerrota;
      if (tFim > dur) _assumirFilhote();
    } else if (fase == _Fase.derrota) {
      ents.clear();
      cargas.clear();
      tFim += dt;
      boca += (0 - boca) * math.min(1.0, dt * 6);
      final dur = (Arte.quadros('derrota') > 0 ? Arte.quadros('derrota') / 12 + 0.8 : 6.2) + preDerrota;
      if (tFim > dur && !fimMostrado) _terminar();
    } else if (fase == _Fase.vitoria) {
      tFim += dt;
      boca += ((tFim % 1.2 < 0.5 ? 1.0 : 0.0) - boca) * math.min(1.0, dt * 10);
      final durV = Arte.quadros('chegada') > 0 ? Arte.quadros('chegada') / 12 + 0.8 : 2.6;
      if (tFim > durV && !fimMostrado) _terminar();
    }
    _sincronizarSons();
    if (mounted) setState(() {});
  }

  // mar de fundo e tensão do navio ligam e desligam conforme a situação
  void _sincronizarSons() {
    final amb = !Som.mudo && !fimMostrado && fase != _Fase.derrota && fase != _Fase.troca;
    if (amb != _ambOn) {
      _ambOn = amb;
      Som.loop('mar_ambiente', amb, vol: 0.35);
    }
    final n = navio;
    final ten = !Som.mudo && fase == _Fase.jogando && !perguntaAtiva && n != null && n.estado < 2;
    if (ten != _tenOn) {
      _tenOn = ten;
      Som.loop('tensao', ten, vol: 0.6);
    }
  }

  Future<void> _terminar() async {
    fimMostrado = true;
    if (!_registrado) {
      _registrado = true;
      await Placar.registrar('Corrida da Baleia', pontos);
    }
    final l = await Placar.doJogo('Corrida da Baleia');
    if (!mounted) return;
    setState(() {
      topRank = l.take(3).toList();
      meuIdx = topRank.indexWhere((r) => r.pontos == pontos);
    });
  }

  void _jogar(double dt) {
    if (perguntaAtiva) {
      // jogo PAUSADO: o aluno responde (15 s) ou lê o feedback
      if (!respondida) {
        tempoPerg -= dt;
        if (tempoPerg <= 0) _responder(-1);
      } else {
        feedbackT -= dt;
        if (feedbackT <= 0) _continuar();
      }
      return;
    }
    final vel = _velBase[faseNum] + _prog * 40 + (mult - 1) * 5;
    scroll += vel * dt;
    tFase += dt;
    invuln = math.max(0, invuln - dt);
    escudoT = math.max(0, escudoT - dt);
    dobroT = math.max(0, dobroT - dt);

    // rastro de bolhas da cauda
    if (_rnd.nextDouble() < dt * 14) {
      bolhas.add(_Bolha(_whaleX - 115 * tamCtrl + _rnd.nextDouble() * 20, whaleY + _rnd.nextDouble() * 24 - 8, 2 + _rnd.nextDouble() * 3, 25 + _rnd.nextDouble() * 30));
      if (bolhas.length > 140) bolhas.removeRange(0, bolhas.length - 140);
    }
    proxBaleiaSom -= dt;
    if (proxBaleiaSom <= 0) {
      Som.tocar('baleia', vol: 0.45);
      proxBaleiaSom = 14 + _rnd.nextDouble() * 10;
    }
    proxGolfSom -= dt;
    if (proxGolfSom <= 0) {
      Som.tocar('golfinho', vol: 0.5);
      proxGolfSom = 18 + _rnd.nextDouble() * 14;
    }

    proxSpawn -= dt;
    if (proxSpawn <= 0) {
      _spawnComum();
      proxSpawn = _espMin[faseNum] + _rnd.nextDouble() * _espVar[faseNum];
    }
    // fim da travessia: oferece as perguntas bonus
    if (tFase >= _durFase[faseNum]) {
      _fimDaTravessia();
      return;
    }

    final h = _hit;
    var comestivelPerto = false;
    for (final e in ents) {
      if (fase != _Fase.jogando) break;
      e.x -= vel * dt;
      if (e.morta) continue;
      // a boca "puxa" o krill que passa perto
      if (e.tipo == _Tipo.krill && e.x > _whaleX && e.x < _whaleX + 260 && (e.y - whaleY).abs() < 110) {
        e.y += (whaleY - e.y) * math.min(1.0, dt * 5);
      }
      final dy = (e.y - whaleY).abs();
      final comest = e.tipo == _Tipo.krill || e.tipo == _Tipo.escudo || e.tipo == _Tipo.dobro || e.tipo == _Tipo.op;
      if (comest && dy < 56 && e.x < _whaleX + 215 && e.x > _whaleX) comestivelPerto = true;
      if (comest) {
        if (dy < 56 && e.x < _whaleX + 125 && e.x > _whaleX - 20) _comer(e);
      } else if (dy < 50 * h && e.x < _whaleX + 90 * h && e.x > _whaleX - 90 * h) {
        if (escudoT > 0) {
          e.morta = true;
          _estourar(e.x, e.y, 8);
        } else if (invuln <= 0) {
          e.morta = true;
          _perderVida(e.x, e.y);
        }
      }
    }
    if (fase != _Fase.jogando) return;
    final alvo = (comestivelPerto || mordida > 0) ? 1.0 : 0.0;
    boca += (alvo - boca) * math.min(1.0, dt * 14);

    ents.removeWhere((e) => e.x < -300 || (e.morta && e.x < -50));
    _navios(dt, vel);
    if (fase != _Fase.jogando) return;
    _cargasTick(dt, vel);
  }

  // ---------------------------------------------------------------- navio e anzol
  void _navios(double dt, double vel) {
    // ---- rede de arrasto (rara: uma vez por partida)
    final a = arrasto;
    if (a != null) {
      _arrastar(a, dt, vel);
      return;
    }
    final n = navio;
    if (n == null) {
      if (proxArrasto > 0) {
        proxArrasto -= dt;
        if (proxArrasto <= 0) {
          proxArrasto = -1;
          redeFeita = true;
          arrasto = _Arrasto(_W + 420, _rnd.nextInt(3));
          textos.add(_Texto('REDE DE ARRASTO! Vá para a faixa livre', _W - 330, 170, const Color(0xFFFFAB40)));
          Som.tocar('anzol', vol: 0.7);
          return;
        }
      }
      if (_durFase[faseNum] - tFase < 9) return; // perto do fim da fase nao entra navio novo
      proxNavio -= dt;
      if (proxNavio <= 0) {
        // profundidade do anzol varia a cada barco (sempre sobra a faixa de baixo livre)
        final prof = 95 + _rnd.nextDouble() * 150;
        navio = _Navio(_W + 170, prof);
        proxCarga = 0.2;
      }
      return;
    }
    n.x -= vel * 0.55 * dt;
    n.t += dt;
    // fases 2 e 3: o navio joga cargas explosivas enquanto se aproxima (1 na fase 2, ate 2 na fase 3)
    if (_cargasFase[faseNum] && n.lancadas < _maxCargas[faseNum] && n.estado < 2 && n.x + _cargaOffX > 740 && n.x < _W - 20) {
      proxCarga -= dt;
      if (proxCarga <= 0) {
        _soltarCarga(n.x + _cargaOffX);
        n.lancadas++;
        proxCarga = _cargaInt[faseNum] + _rnd.nextDouble() * 0.4;
      }
    }
    if (n.estado == 0 && n.x <= _W - 130) {
      n.estado = 1;
      textos.add(_Texto('CUIDADO: ANZOL!', _W - 200, 150, const Color(0xFFFF8A80)));
      Som.tocar('anzol', vol: 0.7);
    }
    if (n.estado == 1) {
      n.anz = math.min(1.0, n.anz + dt / (faseNum == 0 ? 1.3 : (faseNum == 1 ? 1.0 : 0.8)));
      if (n.x < _whaleX - 175) n.estado = 2;
    } else if (n.estado == 2) {
      n.anz = math.max(0.0, n.anz - dt / 0.9);
    }
    if (n.estado == 1 && n.anz > 0.2) {
      final hx = n.x + _anzOffX;
      final dx = hx - _whaleX;
      if (dx > -95 && dx < 100 && n.tipY + _anzolH > whaleY - 38) {
        if (escudoT > 0) {
          n.estado = 2;
          _estourar(hx, n.tipY, 10);
          textos.add(_Texto('Anzol quebrado!', hx, n.tipY - 20, const Color(0xFF80DEEA)));
          Som.tocar('poder');
        } else if (_anzolMata) {
          _pescada(hx, n.tipY, gancho: true);
          return;
        } else if (invuln <= 0) {
          n.estado = 2;
          _perderVida(hx, n.tipY);
        }
      }
    }
    if (n.x < -230) {
      navio = null;
      proxNavio = faseNum == 0 ? 16 + _rnd.nextDouble() * 6 : (faseNum == 1 ? 7 + _rnd.nextDouble() * 3 : 5 + _rnd.nextDouble() * 3);
    }
  }

  // ---------------------------------------------------------------- cargas explosivas
  void _soltarCarga(double x) {
    if (cargas.length >= 3) return;
    var l = _rnd.nextInt(3);
    if (l == ultCargaLane) l = (l + 1 + _rnd.nextInt(2)) % 3;
    ultCargaLane = l;
    cargas.add(_Carga(x, _surfY + 8, l));
    Som.tocar('anzol', vol: 0.4);
  }

  void _cargasTick(double dt, double vel) {
    for (final g in cargas.toList()) {
      g.x -= vel * dt;
      if (!g.explodiu) {
        g.y = math.min(g.alvoY, g.y + _cargaVel * dt);
        // chegou ao fundo e esta perto da baleia: explode
        if (g.y >= g.alvoY && g.x < _whaleX + 240) _explodir(g);
      } else {
        g.t += dt;
        if (!g.atingiu && g.t < _explDur - 0.2) {
          final k = math.min(1.0, g.t / 0.35);
          final grow = 1 - (1 - k) * (1 - k);
          final dx = (g.x - _whaleX) / (_explRX * grow + 1);
          final dy = (g.y - whaleY) / (_explRY * grow + 1);
          if (dx * dx + dy * dy < 1) {
            if (escudoT > 0) {
              g.atingiu = true;
              _estourar(_whaleX, whaleY, 10);
              textos.add(_Texto('Escudo protegeu!', _whaleX + 40, whaleY - 50, const Color(0xFF80DEEA)));
              Som.tocar('poder');
            } else if (invuln <= 0) {
              g.atingiu = true;
              _perderVida(_whaleX, whaleY, bomba: true);
              if (fase != _Fase.jogando) return;
            }
          }
        }
      }
    }
    cargas.removeWhere((g) => g.x < -250 || (g.explodiu && g.t > _explDur));
  }

  void _explodir(_Carga g) {
    g.explodiu = true;
    g.t = 0;
    g.y = g.alvoY;
    tremor = math.max(tremor, 0.35);
    _estourar(g.x, g.y, 16);
    Som.tocar('batida', vol: 0.6);
  }

  // ---------------------------------------------------------------- perguntas bonus (fim da fase)
  void _fimDaTravessia() {
    ents.clear();
    cargas.clear();
    navio = null;
    arrasto = null;
    perguntaAtiva = false;
    tFim = 0;
    Som.tocar('fase');
    fase = _Fase.oferta;
  }

  void _aceitarBonus() {
    if (fase != _Fase.oferta) return;
    fase = _Fase.jogando;
    emBonus = true;
    bonusRestantes = _perguntasBonus;
    bonusPerg = _perguntasBonus;
    bonusCertas = 0;
    _proximaBonus();
  }

  void _pularBonus() {
    if (fase != _Fase.oferta) return;
    bonusPerg = 0;
    bonusCertas = 0;
    _aposBonus();
  }

  void _aposBonus() {
    emBonus = false;
    if (faseNum >= 2) {
      _vitoria();
    } else {
      _concluirFase();
    }
  }

  // perguntas bonus: Costa das Baleias e Consciencia Negra (banco em dados.dart)
  void _proximaBonus() => _iniciarPergunta();

  // rede de arrasto: cobre 2 faixas e so deixa 1 livre
  void _arrastar(_Arrasto a, double dt, double vel) {
    a.x -= vel * 0.62 * dt;
    a.t += dt;
    final dx = (a.x - _whaleX).abs();
    if (dx < 70) {
      var pega = false;
      for (var l = 0; l < 3; l++) {
        if (l != a.livre && (whaleY - _lanes[l]).abs() < 62) pega = true;
      }
      if (pega) {
        if (escudoT > 0) {
          _estourar(a.x, whaleY, 12);
          textos.add(_Texto('Rede rasgada!', a.x, whaleY - 30, const Color(0xFF80DEEA)));
          Som.tocar('poder');
          arrasto = null;
        } else if (_anzolMata) {
          _pescada(a.x, whaleY);
        } else if (invuln <= 0) {
          _perderVida(a.x, whaleY);
          arrasto = null;
        }
        return;
      }
    }
    if (a.x < -380) arrasto = null;
  }

  // o anzol pegou quem o jogador controla
  void _pescada(double x, double y, {bool gancho = false}) {
    causaAnzol = true;
    causaGancho = gancho;
    if (ctrlFilhote) {
      vidasF = 0;
    } else {
      vidas = 0;
    }
    combo = 0;
    tremor = 1;
    flash = 1;
    _estourar(x, y, 14);
    _perdeuPersonagem();
  }

  // ---------------------------------------------------------------- mae e filhote
  // Acabaram as vidas (ou veio o anzol). Se era a mae e o filhote vive, ele assume. Se era o filhote, o jogo acaba.
  void _perdeuPersonagem() {
    perguntaAtiva = false;
    respondida = false;
    navio = null;
    arrasto = null;
    cargas.clear();
    Som.tocar('pescada');
    tFim = 0;
    if (!ctrlFilhote && filhoteVivo) {
      fase = _Fase.troca;
    } else {
      if (ctrlFilhote) filhoteVivo = false;
      fase = _Fase.derrota;
    }
  }

  void _assumirFilhote() {
    ctrlFilhote = true;
    causaAnzol = false;
    causaGancho = false;
    invuln = 2.5;
    combo = 0;
    ents.clear();
    cargas.clear();
    navio = null;
    causaBomba = false;
    proxSpawn = 1.2;
    veu = 1;
    aviso = 'Agora você é o filhote! Coma krill para crescer e virar uma baleia.';
    avisoOk = true;
    avisoT = 6;
    Som.tocar('filhote', vol: 0.7);
    fase = _Fase.jogando;
  }

  // todo krill comido alimenta o filhote
  void _alimentar() {
    if (!filhoteVivo || filhoteAdulto) return;
    krillF++;
    if (krillF >= _krillMeta) {
      filhoteAdulto = true;
      if (vidasF < 3) vidasF++;
      flash = 0.5;
      textos.add(_Texto('O filhote virou baleia!', _W / 2, 150, const Color(0xFFFFE082)));
      aviso = 'O filhote cresceu e virou uma baleia adulta! Ganhou 1 vida.';
      avisoOk = true;
      avisoT = 5;
      Som.tocar('fase');
      Som.tocar('baleia', vol: 0.6);
    }
  }

  // ---------------------------------------------------------------- spawns
  void _spawnComum() {
    final l = _rnd.nextInt(3);
    final r = _rnd.nextDouble();
    final po = _pObst[faseNum];
    if (r < po * 0.6) {
      ents.add(_Ent(_Tipo.rede, _W + 80, l));
      _obstaculoExtra(l);
    } else if (r < po) {
      ents.add(_Ent(_Tipo.saco, _W + 80, l));
      _obstaculoExtra(l);
    } else if (r < 0.88) {
      final n = faseNum == 0 ? 3 : 4;
      for (var i = 0; i < n; i++) {
        ents.add(_Ent(_Tipo.krill, _W + 80 + i * 55, l));
      }
    } else if (r < 0.96) {
      _spawnOperacao(l);
    } else {
      ents.add(_Ent(_Tipo.escudo, _W + 80, l));
    }
  }

  // bolinha de operacao: + e x somam pontos, - e / tiram
  void _spawnOperacao(int l) {
    final e = _Ent(_Tipo.op, _W + 80, l);
    switch (_rnd.nextInt(4)) {
      case 0:
        e.op = '+';
        e.val = const [30, 50, 100][_rnd.nextInt(3)];
        break;
      case 1:
        e.op = '−';
        e.val = const [20, 30, 50][_rnd.nextInt(3)];
        break;
      case 2:
        e.op = '×';
        e.val = 2;
        break;
      default:
        e.op = '÷';
        e.val = 2;
        break;
    }
    ents.add(e);
  }

  // na fase 3 as vezes vem um segundo obstaculo ao lado (sempre sobra uma faixa livre)
  void _obstaculoExtra(int l) {
    if (faseNum < 2 || _rnd.nextDouble() > 0.22) return;
    var l2 = _rnd.nextInt(3);
    if (l2 == l) l2 = (l + 1) % 3;
    ents.add(_Ent(_rnd.nextBool() ? _Tipo.rede : _Tipo.saco, _W + 80, l2));
  }

  void _iniciarPergunta([Pergunta? forca]) {
    final Pergunta p;
    if (forca != null) {
      p = forca;
    } else {
      if (_fila.isEmpty) _fila = List.of(perguntasCorrida)..shuffle(_rnd);
      p = _fila.removeLast();
    }
    perg = p;
    final erradas = <int>[for (var i = 0; i < p.opcoes.length; i++) if (i != p.certa) i]..shuffle(_rnd);
    final escolhidas = [p.certa, erradas[0], erradas[1]]..shuffle(_rnd);
    certaIdx = escolhidas.indexOf(p.certa);
    opcoesPerg = [for (final i in escolhidas) p.opcoes[i]];
    numPergunta++;
    tempoPerg = _tempoResposta;
    respondida = false;
    escolhida = -1;
    sel = 0;
    ents.clear(); // limpa a tela: ao voltar não há obstáculo em cima da baleia
    navio = null; // o navio sai de cena: ao voltar não há anzol em cima da baleia
    arrasto = null;
    cargas.clear();
    perguntaAtiva = true;
    boca = 0;
    _foco.requestFocus();
  }

  /// [i] = índice da opção (0..2) ou -1 quando o tempo acabou.
  void _responder(int i) {
    if (!perguntaAtiva || respondida || fase != _Fase.jogando) return;
    respondida = true;
    escolhida = i;
    feedbackT = 7;
    if (i == certaIdx) {
      acertos++;
      bonusCertas++;
      pontos += _pontosBonus;
      textos.add(_Texto('+$_pontosBonus', _whaleX + 60, whaleY - 60, const Color(0xFFA5D6A7)));
      _estourar(_whaleX + 100, whaleY, 14);
      Som.tocar('acerto');
    } else {
      // pergunta bonus: errar nao tira vida
      Som.tocar('erro');
    }
    _foco.requestFocus();
  }

  void _continuar() {
    if (!perguntaAtiva || !respondida) return;
    perguntaAtiva = false;
    respondida = false;
    ents.clear();
    bonusRestantes--;
    _foco.requestFocus();
    if (bonusRestantes > 0) {
      _proximaBonus();
    } else {
      _aposBonus();
    }
  }

  void _concluirFase() {
    bonusFase = 200 + (filhoteVivo ? 150 : 0);
    pontos += bonusFase;
    if (vidasAtual < 3) {
      if (ctrlFilhote) {
        vidasF++;
      } else {
        vidas++;
      }
    }
    Som.tocar('fase');
    Som.tocar('golfinho', vol: 0.6);
    fase = _Fase.transicao;
    tFim = 0;
  }

  void _vitoria() {
    pontos += vidasAtual * 150;
    if (filhoteVivo) {
      pontos += 500;
      if (filhoteAdulto) pontos += 300;
    }
    Som.tocar('vitoria');
    Som.tocar('baleia', vol: 0.6);
    Som.tocar('golfinho', vol: 0.6);
    fase = _Fase.vitoria;
    tFim = 0;
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
        Som.tocar('come', vol: 0.5, gapMs: 90);
        _estourar(e.x, e.y, 4);
        _alimentar();
        break;
      case _Tipo.op:
        final antes = pontos;
        var depois = pontos;
        if (e.op == '+') {
          depois = pontos + e.val;
        } else if (e.op == '−') {
          depois = math.max(0, pontos - e.val);
        } else if (e.op == '×') {
          depois = pontos + math.min(pontos * (e.val - 1), _opCapGanho);
        } else {
          depois = pontos - math.min(pontos - pontos ~/ e.val, _opCapPerda);
        }
        pontos = depois;
        final delta = depois - antes;
        final bom = e.op == '+' || e.op == '×';
        textos.add(_Texto('${e.op}${e.val}  (${delta >= 0 ? '+' : ''}$delta)', e.x, e.y - 30,
            bom ? const Color(0xFFA5D6A7) : const Color(0xFFFF8A80)));
        Som.tocar(bom ? 'acerto' : 'erro', vol: 0.5);
        _estourar(e.x, e.y, 6);
        break;
      case _Tipo.escudo:
        escudoT = 8;
        Som.tocar('poder');
        textos.add(_Texto('ESCUDO!', e.x, e.y - 30, const Color(0xFF80DEEA)));
        break;
      case _Tipo.dobro:
        dobroT = 8;
        Som.tocar('poder');
        textos.add(_Texto('PONTOS x2!', e.x, e.y - 30, const Color(0xFFFFD54F)));
        break;
      default:
        break;
    }
  }

  // batida em rede ou saco: tira 1 vida de quem o jogador controla
  void _perderVida(double x, double y, {bool bomba = false}) {
    causaBomba = bomba;
    causaGancho = false;
    Som.tocar('batida');
    if (ctrlFilhote) {
      vidasF--;
    } else {
      vidas--;
    }
    combo = 0;
    invuln = 1.6;
    tremor = 1;
    flash = 1;
    _estourar(x, y, 10);
    if (vidasAtual <= 0) _perdeuPersonagem();
  }

  void _estourar(double x, double y, int n) {
    for (var i = 0; i < n; i++) {
      bolhas.add(_Bolha(x + _rnd.nextDouble() * 40 - 20, y + _rnd.nextDouble() * 30 - 15, 2 + _rnd.nextDouble() * 4, 40 + _rnd.nextDouble() * 60));
    }
    if (bolhas.length > 140) bolhas.removeRange(0, bolhas.length - 140);
  }

  // ---------------------------------------------------------------- teclado
  KeyEventResult _tecla(FocusNode node, KeyEvent e) {
    if (e is! KeyDownEvent) return KeyEventResult.ignored;
    final k = e.logicalKey;
    final cima = k == LogicalKeyboardKey.arrowUp || k == LogicalKeyboardKey.keyW;
    final baixo = k == LogicalKeyboardKey.arrowDown || k == LogicalKeyboardKey.keyS;
    final ok = k == LogicalKeyboardKey.enter || k == LogicalKeyboardKey.numpadEnter || k == LogicalKeyboardKey.space;
    if (k == LogicalKeyboardKey.keyM) {
      setState(() => Som.mudo = !Som.mudo);
      return KeyEventResult.handled;
    }
    if (k == LogicalKeyboardKey.escape) {
      Navigator.of(context).maybePop();
      return KeyEventResult.handled;
    }
    if (fase == _Fase.pronto || fimMostrado) {
      if (ok) {
        _novo();
        return KeyEventResult.handled;
      }
      return KeyEventResult.ignored;
    }
    if (fase == _Fase.oferta) {
      if (ok) _aceitarBonus();
      if (k == LogicalKeyboardKey.keyN) _pularBonus();
      return KeyEventResult.handled;
    }
    if (fase != _Fase.jogando) return KeyEventResult.ignored;
    if (perguntaAtiva) {
      if (!respondida) {
        final n = opcoesPerg.length;
        if (cima) setState(() => sel = (sel + n - 1) % n);
        if (baixo) setState(() => sel = (sel + 1) % n);
        if (ok) _responder(sel);
        if (k == LogicalKeyboardKey.digit1 || k == LogicalKeyboardKey.numpad1) _responder(0);
        if (k == LogicalKeyboardKey.digit2 || k == LogicalKeyboardKey.numpad2) _responder(1);
        if (k == LogicalKeyboardKey.digit3 || k == LogicalKeyboardKey.numpad3) _responder(2);
      } else if (ok) {
        _continuar();
      }
      return KeyEventResult.handled;
    }
    if (cima) _mover(-1);
    if (baixo) _mover(1);
    return (cima || baixo) ? KeyEventResult.handled : KeyEventResult.ignored;
  }

  // ---------------------------------------------------------------- UI
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Focus(
        focusNode: _foco,
        autofocus: true,
        onKeyEvent: _tecla,
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
                  if (fase == _Fase.jogando || fase == _Fase.oferta || fase == _Fase.transicao || (fase == _Fase.vitoria && Arte.quadros('chegada') == 0)) _hud(sc),
                  if (fase == _Fase.jogando && faseBannerT > 0 && !perguntaAtiva) _banner(sc),
                  if (fase == _Fase.transicao) _cartaoTransicao(sc),
                  if (fase == _Fase.oferta) _cartaoOferta(sc),
                  if (fase == _Fase.troca) _bannerTroca(sc),
                  if (fase == _Fase.jogando && perguntaAtiva && perg != null) _painelPergunta(sc),
                  if (fase == _Fase.pronto) _cartaoInicio(sc),
                  if (fimMostrado) _cartaoFim(sc),
                  Positioned(
                    left: 8 * sc,
                    top: 8 * sc,
                    child: Column(children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.white70),
                        onPressed: () => Navigator.of(context).maybePop(),
                      ),
                      IconButton(
                        tooltip: 'Som (tecla M)',
                        icon: Icon(Som.mudo ? Icons.volume_off : Icons.volume_up, color: Colors.white70),
                        onPressed: () => setState(() => Som.mudo = !Som.mudo),
                      ),
                    ]),
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
    if (fase != _Fase.jogando || perguntaAtiva) return;
    lane = y < 232 ? 0 : (y < 348 ? 1 : 2);
  }

  Widget _hud(double sc) {
    final corCoracao = ctrlFilhote ? const Color(0xFFFF80AB) : const Color(0xFFFF5252);
    return Positioned.fill(
      child: IgnorePointer(
        child: Padding(
          padding: EdgeInsets.fromLTRB(60 * sc, 10 * sc, 16 * sc, 0),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Expanded(
                child: Wrap(spacing: 8 * sc, runSpacing: 6 * sc, children: [
                  _pill('⭐ $pontos', sc),
                  _pill('Combo x$mult', sc, cor: mult > 1 ? const Color(0xFFFF8F00) : null),
                  _pill('Fase ${faseNum + 1}/3', sc, cor: const Color(0xFF5E35B1)),
                  _pill('🏁 ${(_prog * 100).floor()}%', sc),
                  if (ctrlFilhote) _pill('Você é o filhote', sc, cor: const Color(0xFFC2185B)),
                  if (filhoteVivo)
                    _pill(filhoteAdulto ? '🐋 Filhote adulto' : '🐳 $krillF/$_krillMeta', sc, cor: const Color(0xFF2E7D32)),
                  if (escudoT > 0) _pill('🛡️ ${escudoT.ceil()}s', sc, cor: const Color(0xFF00838F)),
                  if (dobroT > 0) _pill('x2 ${dobroT.ceil()}s', sc, cor: const Color(0xFFF9A825)),
                ]),
              ),
              Row(mainAxisSize: MainAxisSize.min, children: [
                for (var i = 0; i < 3; i++)
                  Icon(i < vidasAtual ? Icons.favorite : Icons.favorite_border, color: corCoracao, size: 30 * sc),
              ]),
            ]),
            const Spacer(),
            if (avisoT > 0 && aviso.isNotEmpty)
              Container(
                width: double.infinity,
                margin: EdgeInsets.only(bottom: 12 * sc),
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

  Widget _painelPergunta(double sc) {
    final p = perg!;
    final tempoOk = tempoPerg.clamp(0, _tempoResposta).toDouble();
    final urgente = tempoOk <= 5;
    return Positioned.fill(
      child: Container(
        color: const Color(0xAA02101C),
        child: Center(
          child: Container(
            width: 800 * sc,
            padding: EdgeInsets.all(22 * sc),
            decoration: BoxDecoration(
              color: const Color(0xF006202E),
              borderRadius: BorderRadius.circular(22 * sc),
              border: Border.all(color: const Color(0xFF39B5C9), width: 2),
            ),
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Row(children: [
                Text('Bônus ${_perguntasBonus - bonusRestantes + 1}/$_perguntasBonus  •  ${p.tema}',
                    style: TextStyle(color: const Color(0xFF8ED8D3), fontSize: 15 * sc, fontWeight: FontWeight.w900)),
                const Spacer(),
                if (!respondida)
                  Text('⏱ ${tempoOk.ceil()} s',
                      style: TextStyle(color: urgente ? const Color(0xFFFF8A80) : Colors.white, fontSize: 22 * sc, fontWeight: FontWeight.w900)),
              ]),
              if (!respondida) ...[
                SizedBox(height: 6 * sc),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: tempoOk / _tempoResposta,
                    minHeight: 8 * sc,
                    color: urgente ? const Color(0xFFFF5252) : const Color(0xFF39B5C9),
                    backgroundColor: Colors.white12,
                  ),
                ),
              ],
              SizedBox(height: 14 * sc),
              Text(p.enunciado, style: TextStyle(color: Colors.white, fontSize: 24 * sc, fontWeight: FontWeight.w800, height: 1.25)),
              SizedBox(height: 14 * sc),
              for (var i = 0; i < opcoesPerg.length; i++)
                Padding(
                  padding: EdgeInsets.only(bottom: 9 * sc),
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      alignment: Alignment.centerLeft,
                      padding: EdgeInsets.all(14 * sc),
                      side: (!respondida && i == sel) ? const BorderSide(color: Color(0xFFFFB300), width: 4) : null,
                      backgroundColor: !respondida
                          ? (i == sel ? const Color(0xFFFFF3C4) : const Color(0xFFE8FAFF))
                          : (i == certaIdx ? const Color(0xFFA5D6A7) : (i == escolhida ? const Color(0xFFEF9A9A) : const Color(0xFFCFD8DC))),
                    ),
                    onPressed: respondida ? null : () => _responder(i),
                    child: Text('${(!respondida && i == sel) ? '▶ ' : ''}${i + 1})  ${opcoesPerg[i]}',
                        style: TextStyle(color: const Color(0xFF06202E), fontSize: 18 * sc, fontWeight: FontWeight.w700)),
                  ),
                ),
              if (!respondida)
                Text('↑ ↓ escolhem  •  Enter confirma  •  ou aperte 1, 2 ou 3',
                    textAlign: TextAlign.center, style: TextStyle(color: Colors.white54, fontSize: 14 * sc)),
              if (respondida) ...[
                Container(
                  padding: EdgeInsets.all(12 * sc),
                  decoration: BoxDecoration(
                    color: escolhida == certaIdx ? const Color(0xEE1B5E20) : const Color(0xEEB71C1C),
                    borderRadius: BorderRadius.circular(12 * sc),
                  ),
                  child: Text(
                    '${escolhida == certaIdx ? '✅ Acertou! +$_pontosBonus pontos. ' : (escolhida < 0 ? '⏱ Tempo esgotado! Sem problema, é só bônus. ' : '❌ Errou, mas não perdeu vida. ')}${p.explicacao}',
                    style: TextStyle(color: Colors.white, fontSize: 16 * sc, fontWeight: FontWeight.w700, height: 1.3),
                  ),
                ),
                SizedBox(height: 10 * sc),
                FilledButton(
                  onPressed: _continuar,
                  child: Padding(padding: EdgeInsets.all(8 * sc), child: Text('Continuar (Enter)', style: TextStyle(fontSize: 20 * sc))),
                ),
              ],
            ]),
          ),
        ),
      ),
    );
  }

  Widget _pill(String s, double sc, {Color? cor}) => Container(
        padding: EdgeInsets.symmetric(horizontal: 12 * sc, vertical: 6 * sc),
        decoration: BoxDecoration(color: cor ?? const Color(0xCC06202E), borderRadius: BorderRadius.circular(20 * sc)),
        child: Text(s, style: TextStyle(color: Colors.white, fontSize: 16 * sc, fontWeight: FontWeight.w800)),
      );

  // faixa grande no inicio de cada fase
  Widget _banner(double sc) {
    final sai = math.min(1.0, faseBannerT / 0.8);
    final entra = math.min(1.0, (3.0 - faseBannerT) / 0.3);
    final op = math.max(0.0, math.min(1.0, sai * entra));
    return Positioned.fill(
      child: IgnorePointer(
        child: Align(
          alignment: const Alignment(0, -0.05),
          child: Opacity(
            opacity: op,
            child: Container(
              width: 620 * sc,
              padding: EdgeInsets.symmetric(horizontal: 22 * sc, vertical: 14 * sc),
              decoration: BoxDecoration(
                color: const Color(0xCC06202E),
                borderRadius: BorderRadius.circular(20 * sc),
                border: Border.all(color: const Color(0xFFFFD54F), width: 2),
              ),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Text('FASE ${faseNum + 1}',
                    style: TextStyle(color: const Color(0xFFFFD54F), fontSize: 38 * sc, fontWeight: FontWeight.w900)),
                Text(_fNomes[faseNum],
                    style: TextStyle(color: Colors.white, fontSize: 26 * sc, fontWeight: FontWeight.w800)),
                SizedBox(height: 6 * sc),
                Text(_fDicas[faseNum],
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white70, fontSize: 16 * sc, height: 1.3)),
              ]),
            ),
          ),
        ),
      ),
    );
  }

  Widget _bannerTroca(double sc) => Positioned.fill(
        child: IgnorePointer(
          child: Align(
            alignment: const Alignment(0, 0.8),
            child: Container(
              width: 700 * sc,
              padding: EdgeInsets.all(14 * sc),
              decoration: BoxDecoration(color: const Color(0xDDB71C1C), borderRadius: BorderRadius.circular(16 * sc)),
              child: Text('🎣 A mãe foi pescada! O filhote continua a viagem sozinho.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white, fontSize: 22 * sc, fontWeight: FontWeight.w800)),
            ),
          ),
        ),
      );

  Widget _cartaoTransicao(double sc) {
    final prox = faseNum + 1 <= 2 ? faseNum + 1 : 2;
    return Align(
      alignment: const Alignment(0.55, -0.05),
      child: Container(
        width: 360 * sc,
        padding: EdgeInsets.all(16 * sc),
        decoration: BoxDecoration(
          color: const Color(0xDD06202E),
          borderRadius: BorderRadius.circular(20 * sc),
          border: Border.all(color: const Color(0xFF39B5C9), width: 2),
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text('🎉 Fase ${faseNum + 1} completa!',
              style: TextStyle(color: Colors.white, fontSize: 26 * sc, fontWeight: FontWeight.w900)),
          SizedBox(height: 6 * sc),
          Text('Bônus: +$bonusFase',
              style: TextStyle(color: const Color(0xFFFFE082), fontSize: 22 * sc, fontWeight: FontWeight.w800)),
          if (bonusPerg > 0)
            Text('Perguntas bônus: $bonusCertas/$bonusPerg certas (+${bonusCertas * _pontosBonus})',
                style: TextStyle(color: const Color(0xFFA5D6A7), fontSize: 16 * sc, fontWeight: FontWeight.w800)),
          Text(filhoteVivo ? 'O filhote está com você! 🐳' : 'O filhote se perdeu pelo caminho.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white70, fontSize: 15 * sc)),
          SizedBox(height: 8 * sc),
          Text('Próxima: ${_fNomes[prox]}',
              textAlign: TextAlign.center,
              style: TextStyle(color: const Color(0xFF80DEEA), fontSize: 17 * sc, fontWeight: FontWeight.w800)),
        ]),
      ),
    );
  }

  Widget _cartaoOferta(double sc) => _cartao(sc, [
        Text('🏁 Fase ${faseNum + 1} concluída!',
            style: TextStyle(color: Colors.white, fontSize: 30 * sc, fontWeight: FontWeight.w900)),
        SizedBox(height: 10 * sc),
        Text(
          'Quer responder $_perguntasBonus perguntas sobre a Costa das Baleias e a Consciência Negra?\n'
          'Cada acerto vale +$_pontosBonus pontos. Errar não tira vida!',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white70, fontSize: 18 * sc, height: 1.4),
        ),
        SizedBox(height: 18 * sc),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          FilledButton(onPressed: _aceitarBonus, child: Padding(padding: EdgeInsets.all(8 * sc), child: Text('Responder (Enter)', style: TextStyle(fontSize: 20 * sc)))),
          SizedBox(width: 14 * sc),
          OutlinedButton(
              onPressed: _pularBonus,
              child: Padding(padding: EdgeInsets.all(8 * sc), child: Text('Pular (N)', style: TextStyle(fontSize: 20 * sc, color: Colors.white)))),
        ]),
      ]);

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
          'Nade pelas 3 faixas com as setas ↑ ↓ (ou W/S, ou o mouse).\n'
          'Coma krill: ele faz o filhote crescer. Fuja de redes, sacos e anzóis!\n'
          'Se a mãe for pescada, o filhote assume. Se o filhote se perder, o jogo acaba.\n'
          'Bolinhas + e × somam pontos, − e ÷ tiram: coma as verdes e fuja das vermelhas!\n'
          'Navios jogam cargas explosivas (1 na fase 2, até 2 na fase 3): saia da faixa vermelha!\n'
          'No fim de cada fase há perguntas sobre a Costa das Baleias e a Consciência Negra para ganhar bônus.\n'
          'Sobreviva às 3 fases para chegar a Abrolhos.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white70, fontSize: 17 * sc, height: 1.4),
        ),
        SizedBox(height: 18 * sc),
        FilledButton(onPressed: _novo, child: Padding(padding: EdgeInsets.all(8 * sc), child: Text('JOGAR (Enter)', style: TextStyle(fontSize: 22 * sc)))),
      ]);

  Widget _cartaoFim(double sc) {
    final venceu = fase == _Fase.vitoria;
    String titulo, msg;
    if (venceu) {
      if (ctrlFilhote) {
        titulo = '🎉 O filhote chegou a Abrolhos!';
        msg = filhoteAdulto
            ? 'Mesmo sem a mãe, ele cresceu e virou uma baleia adulta. Bônus: +500 e +300.'
            : 'Mesmo sem a mãe, o filhote chegou ao fim da viagem. Bônus: +500.';
      } else {
        titulo = '🎉 Mãe e filhote chegaram a Abrolhos!';
        msg = filhoteAdulto
            ? 'O filhote cresceu e virou uma baleia adulta. Bônus: +500 e +300.'
            : 'O filhote chegou são e salvo. Bônus: +500.';
      }
    } else {
      titulo = '🎣 O filhote foi pescado…';
      msg = causaAnzol
          ? 'Anzóis e redes de pesca ferem os animais marinhos. Preservar o mar é papel de todos!'
          : (causaBomba
              ? 'Explosões debaixo d\'água machucam e afastam os animais marinhos. Preservar o mar é papel de todos!'
              : 'Redes e plástico ferem os animais marinhos. Preservar o mar e a biodiversidade é papel de todos!');
    }
    return _cartao(sc, [
      Text(titulo, textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontSize: 28 * sc, fontWeight: FontWeight.w900)),
      SizedBox(height: 8 * sc),
      Text('Pontos: $pontos   •   Perguntas certas: $acertos   •   Fase ${faseNum + 1}/3',
          style: TextStyle(color: const Color(0xFFFFE082), fontSize: 19 * sc, fontWeight: FontWeight.w800)),
      SizedBox(height: 8 * sc),
      Text(msg, textAlign: TextAlign.center, style: TextStyle(color: Colors.white70, fontSize: 16 * sc, height: 1.3)),
      if (topRank.isNotEmpty) ...[
        SizedBox(height: 10 * sc),
        Text('🏆 Melhores da Corrida', style: TextStyle(color: Colors.white, fontSize: 16 * sc, fontWeight: FontWeight.w800)),
        for (var i = 0; i < topRank.length; i++)
          Text('${i + 1}º  ${topRank[i].nome}   ${topRank[i].pontos}',
              style: TextStyle(
                color: i == meuIdx ? const Color(0xFFFFD54F) : Colors.white70,
                fontSize: 16 * sc,
                fontWeight: i == meuIdx ? FontWeight.w900 : FontWeight.w600,
              )),
      ],
      SizedBox(height: 14 * sc),
      Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        FilledButton(onPressed: _novo, child: const Text('Jogar de novo (Enter)')),
        const SizedBox(width: 12),
        OutlinedButton(onPressed: () => Navigator.of(context).maybePop(), child: const Text('Menu (Esc)', style: TextStyle(color: Colors.white))),
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
    if (s.fase == _Fase.vitoria && Arte.quadros('chegada') > 0) {
      Arte.quadro(c, 'chegada', (s.tFim * 12).floor(), const Rect.fromLTWH(0, 0, _W, _H));
      _confete(c);
      c.restore();
      return;
    }
    if ((s.fase == _Fase.derrota || s.fase == _Fase.troca) && s.tFim < s.preDerrota) {
      // video do navio baixando o anzol ate a baleia
      Arte.quadro(c, 'pescada', (s.tFim * 12).floor(), const Rect.fromLTWH(0, 0, _W, _H));
      final fim = Arte.quadros('pescada') / 12;
      if (s.tFim > fim) {
        c.drawRect(const Rect.fromLTWH(0, 0, _W, _H), Paint()..color = Color.fromRGBO(0, 8, 20, _ease((s.tFim - fim) / 0.3)));
      }
      c.restore();
      return;
    }
    _fundo(c);
    _peixes(c);
    _riscos(c);
    _superficie(c);
    for (final b in s.bolhas) {
      c.drawCircle(Offset(b.x, b.y), b.r, Paint()..color = const Color(0x55FFFFFF));
    }
    _navio(c);
    _arrastoDesenho(c);
    _cargasDesenho(c);
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
    if (s.veu > 0) {
      c.drawRect(const Rect.fromLTWH(0, 0, _W, _H), Paint()..color = Color.fromRGBO(0, 8, 20, math.min(1.0, s.veu)));
    }
    if (s.fase == _Fase.vitoria || s.fase == _Fase.transicao) _confete(c);
    c.restore();
  }

  void _fundo(Canvas c) {
    const r = Rect.fromLTWH(0, 0, _W, _H);
    final profundo = s.fase == _Fase.derrota ? _ease((s.tDer - 3.6) / 2.4) : 0.0;
    const nomes = ['fundo_mar', 'fundo_mar2', 'fundo_mar3'];
    final okImg = Arte.cobrir(c, nomes[s.faseNum], r) || (s.faseNum > 0 && Arte.cobrir(c, 'fundo_mar', r));
    if (!okImg) {
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
    // cada fase fica mais escura e funda (so quando a fase nao tem imagem propria)
    const tons = [0.0, 0.16, 0.32];
    if (s.faseNum > 0 && Arte.get(nomes[s.faseNum]) == null) {
      c.drawRect(r, Paint()..color = Color.fromRGBO(0, 20, 60, tons[s.faseNum]));
    }
    if (profundo > 0) {
      c.drawRect(r, Paint()..color = Color.fromRGBO(0, 8, 20, 0.85 * profundo));
    }
    // marcação discreta das faixas
    for (final y in _lanes) {
      c.drawLine(Offset(0, y + 52), Offset(_W, y + 52), Paint()..color = const Color(0x12FFFFFF)..strokeWidth = 1);
    }
  }

  // cardumes ao fundo (so enfeite, passam em varias velocidades)
  void _peixes(Canvas c) {
    final pf = Paint()..color = const Color(0x55E1F5FE);
    for (var k = 0; k < 3; k++) {
      final base = (s.scroll * 0.4 + k * 430 + s.t * 25) % (_W + 400);
      final x0 = _W + 150 - base;
      final y0 = 150 + k * 110 + math.sin(s.t * 0.8 + k) * 14;
      for (var i = 0; i < 6; i++) {
        final fx = x0 + (i % 3) * 26 + (i ~/ 3) * 10;
        final fy = y0 + (i ~/ 3) * 22 + math.sin(s.t * 3 + i) * 3;
        c.drawOval(Rect.fromCenter(center: Offset(fx, fy), width: 18, height: 8), pf);
        final cauda = Path()
          ..moveTo(fx + 8, fy)
          ..lineTo(fx + 15, fy - 5)
          ..lineTo(fx + 15, fy + 5)
          ..close();
        c.drawPath(cauda, pf);
      }
    }
  }

  // riscos de velocidade quando o combo esta alto
  void _riscos(Canvas c) {
    if (s.fase != _Fase.jogando || s.perguntaAtiva) return;
    if (s.mult < 2 && s.dobroT <= 0) return;
    final p = Paint()
      ..color = const Color(0x2AFFFFFF)
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < 10; i++) {
      final x = _W + 100 - ((s.scroll * 2.2 + i * 211) % (_W + 260));
      final y = 120.0 + (i * 47) % 360;
      final len = 70.0 + (i % 3) * 30;
      c.drawLine(Offset(x, y), Offset(x + len, y), p);
    }
  }

  // ceu e ondas na superficie (o navio fica aqui)
  void _superficie(Canvas c) {
    const topo = [Color(0xFF8ED8F8), Color(0xFF6FB6E0), Color(0xFF5B6F9A)];
    const base = [Color(0xFFDFF6FF), Color(0xFFBFE3F5), Color(0xFF9AA9CC)];
    final n = s.faseNum;
    const r = Rect.fromLTWH(0, 0, _W, _surfY);
    c.drawRect(r, Paint()..shader = ui.Gradient.linear(r.topCenter, r.bottomCenter, [topo[n], base[n]]));
    if (n == 0) {
      c.drawCircle(const Offset(870, 44), 24, Paint()..color = const Color(0xFFFFF59D));
      c.drawCircle(const Offset(870, 44), 38, Paint()..color = const Color(0x33FFF59D));
    }
    final onda = Path()..moveTo(0, _surfY);
    for (var x = 0.0; x <= _W; x += 20) {
      onda.lineTo(x, _surfY + math.sin(x * 0.03 + s.t * 2) * 4);
    }
    onda
      ..lineTo(_W, _surfY + 24)
      ..lineTo(0, _surfY + 24)
      ..close();
    c.drawPath(onda, Paint()..color = const Color(0x7739B5C9));
    final espuma = Path()..moveTo(0, _surfY);
    for (var x = 0.0; x <= _W; x += 20) {
      espuma.lineTo(x, _surfY + math.sin(x * 0.03 + s.t * 2) * 4);
    }
    c.drawPath(espuma, Paint()..color = const Color(0xCCFFFFFF)..style = PaintingStyle.stroke..strokeWidth = 3);
  }

  // rede de arrasto: barco na superficie puxando uma rede que cobre 2 faixas
  void _arrastoDesenho(Canvas c) {
    final a = s.arrasto;
    if (a == null) return;
    final bob = math.sin(s.t * 2) * 2.5;
    final y = _surfY + bob;
    _desenharNavio(c, a.x + 260, y);
    // cabos do barco ate a rede
    final cabo = Paint()..color = const Color(0xFFBCAAA4)..strokeWidth = 3;
    c.drawLine(Offset(a.x + 160, y + 30), Offset(a.x, _lanes[0] - 70), cabo);
    c.drawLine(Offset(a.x + 160, y + 30), Offset(a.x, _lanes[2] + 70), cabo);
    // faixa livre brilha em verde; o resto e rede
    final fio = Paint()..color = const Color(0xCCFFFFFF)..strokeWidth = 2.5..style = PaintingStyle.stroke;
    final cor = Paint()..color = const Color(0x55E0F2F1);
    for (var l = 0; l < 3; l++) {
      final top = _lanes[l] - 60, bot = _lanes[l] + 60;
      if (l == a.livre) {
        c.drawRect(Rect.fromLTRB(a.x - 150, top, a.x + 30, bot), Paint()..color = const Color(0x2266BB6A));
        continue;
      }
      final r = Rect.fromLTRB(a.x - 22, top, a.x + 22, bot);
      c.drawRect(r, cor);
      for (var yy = top; yy <= bot; yy += 18) {
        c.drawLine(Offset(r.left, yy), Offset(r.right, yy), fio);
      }
      for (var xx = r.left; xx <= r.right; xx += 14) {
        c.drawLine(Offset(xx, top), Offset(xx, bot), fio);
      }
    }
    // seta indicando a faixa livre (some quando a rede chega perto)
    if (a.x > _whaleX + 120) {
      final yl = _lanes[a.livre];
      final tp = Paint()..color = const Color(0xFF69F0AE);
      final path = Path()
        ..moveTo(_whaleX + 150, yl - 16)
        ..lineTo(_whaleX + 190, yl)
        ..lineTo(_whaleX + 150, yl + 16)
        ..close();
      c.drawPath(path, tp);
    }
  }

  // cargas explosivas: faixa de perigo, carga piscando e explosao
  void _cargasDesenho(Canvas c) {
    for (final g in s.cargas) {
      if (g.explodiu) {
        _explosao(c, g);
        continue;
      }
      final pulso = 0.5 + 0.5 * math.sin(s.t * 8);
      final xDir = math.min(g.x + 40, _W);
      if (xDir > _whaleX - 150) {
        c.drawRect(Rect.fromLTRB(_whaleX - 150, g.alvoY - 52, xDir, g.alvoY + 52),
            Paint()..color = Color.fromRGBO(255, 23, 68, 0.07 + 0.10 * pulso));
      }
      final dist = ((g.x - _whaleX) / 700).clamp(0.0, 1.0).toDouble();
      final blink = (s.t * (4 + 10 * (1 - dist))).floor() % 2 == 0;
      final cx = g.x, cy = g.y;
      if (!Arte.desenhar(c, 'carga', Rect.fromCenter(center: Offset(cx, cy), width: 84, height: 84))) {
        final corpo = RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(cx, cy), width: 40, height: 56), const Radius.circular(9));
        c.drawRRect(corpo, Paint()..color = const Color(0xFF546E7A));
        c.drawRect(Rect.fromCenter(center: Offset(cx, cy - 14), width: 40, height: 6), Paint()..color = const Color(0xFF263238));
        c.drawRect(Rect.fromCenter(center: Offset(cx, cy + 14), width: 40, height: 6), Paint()..color = const Color(0xFF263238));
        c.drawRect(Rect.fromCenter(center: Offset(cx, cy), width: 40, height: 8), Paint()..color = const Color(0xFFFFCA28));
        c.drawLine(Offset(cx, cy - 28), Offset(cx, cy - 34), Paint()..color = const Color(0xFF263238)..strokeWidth = 3);
        c.drawCircle(Offset(cx, cy - 36), 5, Paint()..color = blink ? const Color(0xFFFF1744) : const Color(0xFF7F0000));
      }
      if (blink) c.drawCircle(Offset(cx, cy - 34), 12, Paint()..color = const Color(0x55FF1744));
    }
  }

  void _explosao(Canvas c, _Carga g) {
    final k = (g.t / _explDur).clamp(0.0, 1.0).toDouble();
    final grow = _ease(math.min(1.0, g.t / 0.35));
    final alfa = 1 - k * k;
    final centro = Offset(g.x, g.y);
    final lado = 2 * _explRX * (0.45 + 0.65 * grow);
    if (Arte.desenhar(c, 'explosao', Rect.fromCenter(center: centro, width: lado, height: lado), opacity: alfa)) return;
    final r = _explRX * (0.25 + 0.85 * grow);
    c.drawCircle(
        centro,
        r,
        Paint()
          ..shader = ui.Gradient.radial(centro, r, [
            Color.fromRGBO(255, 245, 157, alfa),
            Color.fromRGBO(255, 143, 0, 0.9 * alfa),
            const Color.fromRGBO(213, 0, 0, 0.0),
          ], const [0.0, 0.5, 1.0]));
    c.drawOval(Rect.fromCenter(center: centro, width: 2 * _explRX * grow, height: 2 * _explRY * grow),
        Paint()..color = Color.fromRGBO(255, 255, 255, 0.8 * alfa)..style = PaintingStyle.stroke..strokeWidth = 4);
    for (var i = 0; i < 10; i++) {
      final ang = i * 0.628 + g.alvoY * 0.01;
      final d = r * (0.5 + 0.6 * grow);
      c.drawCircle(Offset(g.x + math.cos(ang) * d, g.y + math.sin(ang) * d * 0.8), 5 * (1 - k) + 1,
          Paint()..color = Color.fromRGBO(255, 202, 40, alfa));
    }
  }

  void _navio(Canvas c) {
    final n = s.navio;
    if (n == null) return;
    final bob = math.sin(s.t * 2 + n.x * 0.01) * 2.5;
    final y = _surfY + bob;
    final hx = n.x + _anzOffX;
    _desenharNavio(c, n.x, y);
    // a parte de baixo do casco fica debaixo da agua
    final agua = Rect.fromLTWH(n.x - 102, y, 206, 26);
    c.drawRect(
        agua,
        Paint()
          ..shader = ui.Gradient.linear(
              agua.topCenter, agua.bottomCenter, const [Color(0xB339B5C9), Color(0x0039B5C9)]));
    c.drawLine(Offset(n.x - 102, y), Offset(n.x + 104, y), Paint()..color = const Color(0xAAFFFFFF)..strokeWidth = 2.5);
    if (n.anz > 0.01) {
      final tipY = n.tipY;
      final sw = math.sin(s.t * 2.5 + n.x * 0.02) * 9 * n.anz;
      final linha = Path()
        ..moveTo(hx, _anzTopo)
        ..quadraticBezierTo(hx + sw * 0.3, (_anzTopo + tipY) / 2, hx + sw, tipY);
      c.drawPath(linha, Paint()..color = const Color(0xFFCDA434)..style = PaintingStyle.stroke..strokeWidth = 3);
      if (n.estado == 1) {
        final pulso = 34 + math.sin(s.t * 9) * 5;
        c.drawCircle(Offset(hx + sw, tipY + 40), pulso, Paint()..color = const Color(0x33FF1744));
      }
      final ax = hx + sw, ay = tipY;
      // anzol.png (257x570): olhal em (214,33), altura no jogo 80
      if (!Arte.desenhar(c, 'anzol', Rect.fromLTWH(ax - 30.0, ay - 4.6, 36.1, _anzolH))) {
        final gancho = Path()
          ..moveTo(ax, ay)
          ..lineTo(ax, ay + 34)
          ..quadraticBezierTo(ax, ay + 58, ax + 20, ay + 50)
          ..quadraticBezierTo(ax + 32, ay + 42, ax + 26, ay + 28);
        c.drawPath(
            gancho,
            Paint()
              ..color = const Color(0xFFECEFF1)
              ..style = PaintingStyle.stroke
              ..strokeWidth = 6
              ..strokeCap = StrokeCap.round);
        final farpa = Path()
          ..moveTo(ax + 26, ay + 28)
          ..lineTo(ax + 14, ay + 37)
          ..lineTo(ax + 33, ay + 39)
          ..close();
        c.drawPath(farpa, Paint()..color = const Color(0xFFECEFF1));
        c.drawCircle(Offset(ax, ay), 5, Paint()..color = const Color(0xFF90A4AE));
      }
    }
  }

  void _desenharNavio(Canvas c, double x, double y) {
    if (Arte.desenhar(c, 'barco', Rect.fromLTWH(x - _navioW / 2, y - _navioLinha, _navioW, _navioH))) return;
    final casco = Path()
      ..moveTo(x - 125, y - 30)
      ..lineTo(x + 135, y - 30)
      ..lineTo(x + 100, y + 12)
      ..lineTo(x - 95, y + 12)
      ..close();
    c.drawPath(casco, Paint()..color = const Color(0xFF5D4037));
    c.drawRect(Rect.fromLTWH(x - 125, y - 36, 260, 8), Paint()..color = const Color(0xFFB71C1C));
    // cabine
    c.drawRect(Rect.fromLTWH(x + 5, y - 72, 78, 42), Paint()..color = const Color(0xFFEFEBE9));
    for (var i = 0; i < 3; i++) {
      c.drawRect(Rect.fromLTWH(x + 14 + i * 24, y - 62, 14, 12), Paint()..color = const Color(0xFF4FC3F7));
    }
    c.drawRect(Rect.fromLTWH(x + 52, y - 92, 16, 22), Paint()..color = const Color(0xFF455A64));
    // guindaste apontando para a esquerda
    final pen = Paint()
      ..color = const Color(0xFF37474F)
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round;
    c.drawLine(Offset(x - 15, y - 30), Offset(x + _anzOffX, _anzTopo), pen);
    final fino = Paint()
      ..color = const Color(0xFF37474F)
      ..strokeWidth = 3;
    c.drawLine(Offset(x - 15, y - 30), Offset(x - 15, y - 62), fino);
    c.drawLine(Offset(x - 15, y - 62), Offset(x + _anzOffX, _anzTopo), fino);
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
      case _Tipo.op:
        {
          final bomOp = e.op == '+' || e.op == '×';
          final corOp = bomOp ? const Color(0xFF2E9E5B) : const Color(0xFFD94B3F);
          final pOp = 1 + math.sin(s.t * 6 + e.x * 0.01) * 0.06;
          c.drawCircle(Offset(e.x, e.y), 32 * pOp, Paint()..color = corOp.withValues(alpha: 0.92));
          c.drawCircle(Offset(e.x, e.y), 32 * pOp, Paint()..color = Colors.white..style = PaintingStyle.stroke..strokeWidth = 3);
          c.drawCircle(Offset(e.x - 11, e.y - 12), 7, Paint()..color = const Color(0x55FFFFFF));
          final tOp = TextPainter(
            text: TextSpan(text: '${e.op}${e.val}', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Colors.white)),
            textDirection: TextDirection.ltr,
          )..layout();
          tOp.paint(c, Offset(e.x - tOp.width / 2, e.y - tOp.height / 2));
        }
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
    }
  }

  // corpo de quem o jogador controla: mae, filhote (cresce com o krill) ou filhote ja adulto
  void _corpo(Canvas c, double x, double y, {double boca = 0, double tilt = 0, double t = 0, double opacidade = 1}) {
    if (s.ctrlFilhote && !s.filhoteAdulto) {
      desenharFilhote(c, x, y, escala: s.tamCtrl * (1 + boca * 0.05), tilt: tilt, t: t, opacidade: opacidade);
    } else {
      desenharBaleia(c, x, y, boca: boca, tilt: tilt, t: t, opacidade: opacidade);
    }
  }

  void _baleia(Canvas c) {
    final s = this.s;
    if (s.fase == _Fase.derrota || s.fase == _Fase.troca) return _baleiaDerrota(c);
    var y = s.whaleY;
    var tilt = (_lanes[s.lane] - s.whaleY) / 220;
    var x = _whaleX;
    final pulando = s.fase == _Fase.vitoria || s.fase == _Fase.transicao;
    if (pulando) {
      final p = (s.tFim % 1.6) / 1.6;
      y = _lanes[1] - math.sin(p * math.pi) * 130;
      tilt = -0.35 * math.cos(p * math.pi);
    } else {
      // balanco de nado e "bote" quando morde
      y += math.sin(s.t * 3.2) * 4;
      tilt += math.sin(s.t * 3.2 + 1) * 0.025;
      if (s.mordida > 0) x += math.sin(s.mordida / 0.32 * math.pi) * 16;
    }
    // o filhote acompanha a mae (atras e embaixo)
    if (!s.ctrlFilhote && s.filhoteVivo) {
      _filhoteSeguindo(c, pulando ? y + 64 : s.filhoteY, tilt);
    }
    // escudo
    if (s.escudoT > 0) {
      final double raio = 125.0 * math.max<double>(0.6, s.tamCtrl.toDouble());
      final double a = s.escudoT < 2 ? (math.sin(s.t * 20) > 0 ? 0.5 : 0.15) : 0.4;
      c.drawCircle(Offset(x, y), raio, Paint()..color = const Color(0xFF26C6DA).withValues(alpha: a));
      c.drawCircle(Offset(x, y), raio, Paint()..color = Colors.white.withValues(alpha: a + 0.2)..style = PaintingStyle.stroke..strokeWidth = 3);
    }
    final pisca = s.invuln > 0 && (s.t * 14).floor() % 2 == 0;
    _corpo(c, x, y, boca: s.boca, tilt: tilt, t: s.t, opacidade: pisca ? 0.35 : 1);
  }

  void _filhoteSeguindo(Canvas c, double fy, double tilt) {
    final s = this.s;
    final px = _whaleX - (s.filhoteAdulto ? 150 : 105) + math.sin(s.t * 2) * 6;
    final py = fy + math.sin(s.t * 4) * 4;
    final pisca = s.invuln > 0 && (s.t * 14).floor() % 2 == 0;
    final op = pisca ? 0.5 : 1.0;
    if (s.filhoteAdulto) {
      desenharBaleia(c, px, py, escala: 0.85, tilt: tilt, t: s.t * 1.2, opacidade: op);
    } else {
      desenharFilhote(c, px, py, escala: s.tamSeguindo, tilt: tilt, t: s.t, opacidade: op);
    }
  }

  // -------- sequência de derrota: rede cai, baleia é içada, rede solta, afunda
  // (a mesma cena serve quando a mae e pescada e o filhote assume)
  void _baleiaDerrota(Canvas c) {
    final td = s.tDer;
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
      if (!Arte.desenhar(c, 'barco', Rect.fromLTWH(bx - 150, -70, 300, 205))) {
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
    _corpo(c, _whaleX, wy, boca: 0.4, tilt: tilt, t: s.t * 0.4);
    if (redeOp > 0) {
      desenharRede(c, Rect.fromLTWH(_whaleX - 150, redeTopo, 300, 220), opacidade: redeOp);
    }
    if (td >= 3.9 && Arte.get('baleia_afunda') != null) {
      final a = _ease((td - 3.9) / 1.5);
      Arte.cobrir(c, 'baleia_afunda', const Rect.fromLTWH(0, 0, _W, _H));
      c.drawRect(const Rect.fromLTWH(0, 0, _W, _H), Paint()..color = Color.fromRGBO(0, 0, 0, 1 - a));
    }
  }

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
