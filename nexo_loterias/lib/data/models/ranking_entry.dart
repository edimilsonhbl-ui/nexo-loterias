import 'package:cloud_firestore/cloud_firestore.dart';

class RankingEntry {
  final String id;
  final String userId;
  final String displayName;
  final String modalidadeId;
  final int acertos;
  final double valorGanho;
  final int concursoNumero;
  final DateTime criadaEm;

  const RankingEntry({
    required this.id,
    required this.userId,
    required this.displayName,
    required this.modalidadeId,
    required this.acertos,
    required this.valorGanho,
    required this.concursoNumero,
    required this.criadaEm,
  });

  factory RankingEntry.fromMap(String id, Map<String, dynamic> map) {
    DateTime parseData(dynamic v) {
      if (v is Timestamp) return v.toDate();
      if (v is String) return DateTime.tryParse(v) ?? DateTime.now();
      return DateTime.now();
    }

    return RankingEntry(
      id: id,
      userId: map['userId'] as String? ?? '',
      displayName: map['displayName'] as String? ?? 'Anônimo',
      modalidadeId: map['modalidadeId'] as String? ?? '',
      acertos: (map['acertos'] as num?)?.toInt() ?? 0,
      valorGanho: (map['valorGanho'] as num?)?.toDouble() ?? 0,
      concursoNumero: (map['concursoNumero'] as num?)?.toInt() ?? 0,
      criadaEm: parseData(map['criadaEm']),
    );
  }

  Map<String, dynamic> toMap() => {
        'userId': userId,
        'displayName': displayName,
        'modalidadeId': modalidadeId,
        'acertos': acertos,
        'valorGanho': valorGanho,
        'concursoNumero': concursoNumero,
        'criadaEm': FieldValue.serverTimestamp(),
      };

  String get nomeExibicao {
    if (displayName.length <= 2) return displayName.toUpperCase();
    final partes = displayName.trim().split(' ');
    if (partes.length == 1) return partes[0];
    return '${partes.first} ${partes.last[0]}.';
  }
}
