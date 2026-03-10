class Aposta {
  final String id;
  final String modalidadeId;
  final List<int> numerosEscolhidos;
  final double valorAposta;
  final double probabilidade;
  final DateTime criadaEm;
  final int? acertos;
  final String? faixaPremio;

  const Aposta({
    required this.id,
    required this.modalidadeId,
    required this.numerosEscolhidos,
    required this.valorAposta,
    required this.probabilidade,
    required this.criadaEm,
    this.acertos,
    this.faixaPremio,
  });

  Aposta copyWith({
    int? acertos,
    String? faixaPremio,
  }) {
    return Aposta(
      id: id,
      modalidadeId: modalidadeId,
      numerosEscolhidos: numerosEscolhidos,
      valorAposta: valorAposta,
      probabilidade: probabilidade,
      criadaEm: criadaEm,
      acertos: acertos ?? this.acertos,
      faixaPremio: faixaPremio ?? this.faixaPremio,
    );
  }

  factory Aposta.fromMap(Map<String, dynamic> map) {
    return Aposta(
      id: map['id'] as String,
      modalidadeId: map['modalidadeId'] as String,
      numerosEscolhidos: List<int>.from(map['numerosEscolhidos'] as List),
      valorAposta: (map['valorAposta'] as num).toDouble(),
      probabilidade: (map['probabilidade'] as num).toDouble(),
      criadaEm: DateTime.parse(map['criadaEm'] as String),
      acertos: map['acertos'] as int?,
      faixaPremio: map['faixaPremio'] as String?,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'modalidadeId': modalidadeId,
        'numerosEscolhidos': numerosEscolhidos,
        'valorAposta': valorAposta,
        'probabilidade': probabilidade,
        'criadaEm': criadaEm.toIso8601String(),
        'acertos': acertos,
        'faixaPremio': faixaPremio,
      };
}
