import 'package:cloud_firestore/cloud_firestore.dart';

class Bolao {
  final String id;
  final String nome;
  final String codigo;
  final String modalidadeId;
  final String criadoPorUid;
  final String criadoPorNome;
  final List<String> membrosUids;
  final List<String> jogosIds;
  final DateTime criadoEm;

  const Bolao({
    required this.id,
    required this.nome,
    required this.codigo,
    required this.modalidadeId,
    required this.criadoPorUid,
    required this.criadoPorNome,
    required this.membrosUids,
    required this.jogosIds,
    required this.criadoEm,
  });

  int get totalMembros => membrosUids.length;
  int get totalJogos => jogosIds.length;

  factory Bolao.fromMap(Map<String, dynamic> map) {
    return Bolao(
      id: map['id'] as String? ?? '',
      nome: map['nome'] as String? ?? '',
      codigo: map['codigo'] as String? ?? '',
      modalidadeId: map['modalidadeId'] as String? ?? 'mega-sena',
      criadoPorUid: map['criadoPorUid'] as String? ?? '',
      criadoPorNome: map['criadoPorNome'] as String? ?? '',
      membrosUids: List<String>.from(map['membrosUids'] ?? []),
      jogosIds: List<String>.from(map['jogosIds'] ?? []),
      criadoEm: map['criadoEm'] is Timestamp
          ? (map['criadoEm'] as Timestamp).toDate()
          : DateTime.tryParse(map['criadoEm']?.toString() ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'nome': nome,
        'codigo': codigo,
        'modalidadeId': modalidadeId,
        'criadoPorUid': criadoPorUid,
        'criadoPorNome': criadoPorNome,
        'membrosUids': membrosUids,
        'jogosIds': jogosIds,
        'criadoEm': criadoEm.toIso8601String(),
      };
}
