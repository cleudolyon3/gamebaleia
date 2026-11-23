// Perguntas do projeto da mostra (extraídas do jogo original).
class Pergunta {
  final String tema, enunciado, explicacao;
  final List<String> opcoes;
  final int certa;
  final String grupo;
  const Pergunta(this.tema, this.enunciado, this.opcoes, this.certa, this.explicacao, [this.grupo = ""]);
}

const List<Pergunta> perguntasCorrida = [
  Pergunta("Costa das Baleias", "Qual destes municípios faz parte da Zona Turística da Costa das Baleias?", ["Caravelas","Salvador","Lençóis","Feira de Santana"], 0, "A Costa das Baleias reúne Prado, Alcobaça, Caravelas, Nova Viçosa e Mucuri, no extremo sul da Bahia."),
  Pergunta("Costa das Baleias", "Qual arquipélago é refúgio e berçário das baleias jubarte?", ["Fernando de Noronha","Abrolhos","Alcatrazes","Tinharé"], 1, "O arquipélago de Abrolhos recebe as jubartes, que vêm se reproduzir e ter seus filhotes."),
  Pergunta("Costa das Baleias", "Os recifes de Abrolhos são reconhecidos como os de maior biodiversidade de qual região?", ["Atlântico Sul","Mar Mediterrâneo","Oceano Ártico","Mar Vermelho"], 0, "Segundo a SCT, são os recifes de maior biodiversidade de todo o Atlântico Sul."),
  Pergunta("Costa das Baleias", "Por que as baleias jubarte vêm para a região de Abrolhos?", ["Para se reproduzir e cuidar dos filhotes","Para fugir do calor","Para buscar petróleo","Para dormir o ano todo"], 0, "A região é berçário: ali as jubartes se reproduzem e os filhotes nascem em águas calmas e quentes."),
  Pergunta("Nossa terra", "Em qual região da Bahia fica Teixeira de Freitas?", ["Recôncavo","Chapada Diamantina","Extremo Sul","Oeste baiano"], 2, "Teixeira de Freitas fica no Extremo Sul da Bahia, perto da Costa das Baleias."),
  Pergunta("Costa das Baleias", "Quantos municípios formam a Costa das Baleias, segundo o projeto da escola?", ["2","3","5","12"], 2, "São cinco: Prado, Alcobaça, Caravelas, Nova Viçosa e Mucuri."),
  Pergunta("Cultura africana", "Quem foi Zumbi dos Palmares?", ["Um navegador português","Líder do Quilombo dos Palmares","Um rei de Portugal","Um cientista marinho"], 1, "Zumbi foi líder do Quilombo dos Palmares, o maior da história do Brasil."),
  Pergunta("Cultura africana", "Em que dia se celebra o Dia Nacional de Zumbi e da Consciência Negra?", ["7 de setembro","12 de outubro","20 de novembro","25 de dezembro"], 2, "É 20 de novembro, data que lembra a morte de Zumbi. Desde a Lei 14.759/2023 é feriado nacional."),
  Pergunta("Cultura africana", "Qual é o instrumento de uma corda que acompanha a capoeira?", ["Berimbau","Violino","Sanfona","Gaita"], 0, "O berimbau conduz o ritmo da roda de capoeira, arte afro-brasileira que une luta, dança e música."),
  Pergunta("Cultura africana", "Qual destas comidas típicas da Bahia tem raízes africanas?", ["Pão de queijo","Acarajé","Churrasco","Pizza"], 1, "O acarajé chegou com a cultura africana e é vendido pelas baianas de acarajé."),
  Pergunta("Cultura africana", "O tecido colorido kente é uma tradição de qual país africano?", ["Gana","Japão","Peru","Noruega"], 0, "O kente é um tecido tradicional de Gana, feito de faixas coloridas com muitos desenhos."),
  Pergunta("Cultura africana", "A Lei 10.639, de 2003, tornou obrigatório o ensino de quê nas escolas?", ["Só de matemática","História e cultura afro-brasileira e africana","Apenas de inglês","Só de educação física"], 1, "A lei leva a história e a cultura afro-brasileira e africana para dentro da sala de aula."),
  Pergunta("Diversidade cultural", "O que significa valorizar a diversidade cultural?", ["Achar que só uma cultura importa","Respeitar e conhecer as diferentes culturas","Esquecer a história","Copiar sempre os outros"], 1, "Valorizar a diversidade é conhecer e respeitar as culturas que formam a nossa região e o nosso país."),
  Pergunta("Preservação", "O que ajuda a proteger as baleias e os recifes?", ["Jogar lixo no mar","Preservar o meio ambiente e a biodiversidade","Pescar com redes de arrasto perto dos recifes","Ignorar o problema"], 1, "Preservar o meio ambiente e a biodiversidade local é um dos objetivos do projeto."),
];

const List<Pergunta> perguntasResgate = [
  Pergunta("Baleias", "Qual baleia visita Abrolhos todos os anos para se reproduzir?", ["Baleia jubarte","Baleia azul","Cachalote","Orca"], 0, "A jubarte deixa as águas frias da Antártida e vem para as águas quentes do litoral sul da Bahia.", "b"),
  Pergunta("Baleias", "A baleia é um peixe ou um mamífero?", ["Mamífero: respira ar e amamenta o filhote","Peixe: vive o tempo todo na água","Réptil: tem sangue frio","Anfíbio: vive na água e na terra"], 0, "A baleia respira ar pelos pulmões e amamenta o filhote, como todo mamífero.", "b"),
  Pergunta("Baleias", "Em que estado fica o Parque Nacional Marinho dos Abrolhos?", ["Bahia","Ceará","Rio Grande do Sul","Pará"], 0, "Os Abrolhos ficam no mar do sul da Bahia, na região da Costa das Baleias.", "b"),
  Pergunta("Baleias", "O que os machos da jubarte fazem durante a época de reprodução?", ["Cantam canções longas e complexas","Pescam em grupos com redes","Constroem ninhos no recife","Dormem no fundo do mar"], 0, "Os machos cantam. O canto da jubarte é uma das vozes mais complexas do mundo animal.", "b"),
  Pergunta("Baleias", "Qual atitude ajuda a proteger as baleias?", ["Não jogar lixo no mar e manter distância dos animais","Jogar restos de comida na água","Chegar bem perto com o barco para ver melhor","Deixar redes de pesca abandonadas"], 0, "Plástico e redes ferem os animais marinhos, e os barcos precisam manter distância para não assustar nem ferir.", "b"),
  Pergunta("Baleias", "Por que as jubartes vêm para as águas quentes da Costa das Baleias?", ["Para acasalar e para os filhotes nascerem e crescerem protegidos","Para fugir do calor da Antártida","Para procurar ouro","Porque lá não existe mar aberto"], 0, "As águas calmas e quentes são um berçário. Depois, as jubartes voltam para as águas frias onde se alimentam.", "b"),
  Pergunta("Consciência Negra", "Em que data se comemora o Dia Nacional da Consciência Negra?", ["20 de novembro","13 de maio","7 de setembro","21 de abril"], 0, "Em 20 de novembro lembramos Zumbi dos Palmares e a luta do povo negro por liberdade e respeito.", "c"),
  Pergunta("Consciência Negra", "Quem foi Zumbi dos Palmares?", ["Líder do Quilombo dos Palmares e símbolo da resistência à escravidão","Um navegador português","Um imperador do Brasil","Um explorador de baleias"], 0, "Zumbi liderou o Quilombo dos Palmares, onde viviam pessoas que resistiram à escravidão.", "c"),
  Pergunta("Consciência Negra", "O que era um quilombo?", ["Comunidade formada por pessoas que fugiram da escravidão e resistiram","Um tipo de navio baleeiro","Uma festa de colheita europeia","Um porto de pesca"], 0, "Os quilombos foram espaços de liberdade, cultura e resistência. Muitos continuam vivos até hoje.", "c"),
  Pergunta("Consciência Negra", "A capoeira, que usa o berimbau, nasceu da:", ["Resistência e da cultura de africanos escravizados no Brasil","Dança de salão da Europa","Tradição indígena do Pacífico","Música clássica italiana"], 0, "A capoeira mistura luta, dança, música e história, e é patrimônio cultural brasileiro.", "c"),
  Pergunta("Consciência Negra", "O kente, tecido de faixas coloridas, é uma tradição de qual país africano?", ["Gana","Japão","México","Peru"], 0, "O kente é um tecido tradicional de Gana, e cada cor e desenho carrega um significado.", "c"),
  Pergunta("Consciência Negra", "A Lei 10.639/2003 tornou obrigatório nas escolas o ensino de:", ["História e cultura afro-brasileira e africana","Apenas língua inglesa","Somente história da Europa","Apenas educação física"], 0, "A lei garante que a história e a cultura afro-brasileira e africana sejam estudadas nas escolas.", "c"),
];
