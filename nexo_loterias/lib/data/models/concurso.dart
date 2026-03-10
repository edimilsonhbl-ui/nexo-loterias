class Concurso {
  final String id;
  final String modalidadeId;
  final int numeroConcurso;
  final DateTime dataSorteio;
  final List<int> dezenasSorteadas;
  final double premioEstimado;
  final bool acumulado;

  const Concurso({
    required this.id,
    required this.modalidadeId,
    required this.numeroConcurso,
    required this.dataSorteio,
    required this.dezenasSorteadas,
    required this.premioEstimado,
    this.acumulado = false,
  });

  factory Concurso.fromMap(Map<String, dynamic> map) {
    return Concurso(
      id: map['id'] as String,
      modalidadeId: map['modalidadeId'] as String,
      numeroConcurso: map['numeroConcurso'] as int,
      dataSorteio: DateTime.parse(map['dataSorteio'] as String),
      dezenasSorteadas: List<int>.from(map['dezenasSorteadas'] as List),
      premioEstimado: (map['premioEstimado'] as num).toDouble(),
      acumulado: map['acumulado'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'modalidadeId': modalidadeId,
        'numeroConcurso': numeroConcurso,
        'dataSorteio': dataSorteio.toIso8601String(),
        'dezenasSorteadas': dezenasSorteadas,
        'premioEstimado': premioEstimado,
        'acumulado': acumulado,
      };
}
