class EstatisticaNumero {
  final int numero;
  final int frequencia;
  final int ultimoConcurso;
  final int concursoAtual;

  const EstatisticaNumero({
    required this.numero,
    required this.frequencia,
    required this.ultimoConcurso,
    required this.concursoAtual,
  });

  int get atraso => concursoAtual - ultimoConcurso;

  double get frequenciaRelativa => frequencia / concursoAtual;
}

class EstatisticasModalidade {
  final String modalidadeId;
  final int totalConcursos;
  final List<EstatisticaNumero> numeros;
  final double mediaParesUltimos10;
  final double mediaImparesUltimos10;
  final double somaMediaUltimos10;

  const EstatisticasModalidade({
    required this.modalidadeId,
    required this.totalConcursos,
    required this.numeros,
    required this.mediaParesUltimos10,
    required this.mediaImparesUltimos10,
    required this.somaMediaUltimos10,
  });

  List<EstatisticaNumero> get maisSorteados {
    final lista = List<EstatisticaNumero>.from(numeros);
    lista.sort((a, b) => b.frequencia.compareTo(a.frequencia));
    return lista;
  }

  List<EstatisticaNumero> get menosSorteados {
    final lista = List<EstatisticaNumero>.from(numeros);
    lista.sort((a, b) => a.frequencia.compareTo(b.frequencia));
    return lista;
  }

  List<EstatisticaNumero> get maisAtrasados {
    final lista = List<EstatisticaNumero>.from(numeros);
    lista.sort((a, b) => b.atraso.compareTo(a.atraso));
    return lista;
  }
}
