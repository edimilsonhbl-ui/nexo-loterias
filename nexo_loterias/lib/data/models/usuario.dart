import 'package:cloud_firestore/cloud_firestore.dart';

enum PlanoUsuario { free, mensal, anual, vitalicio }

// Sentinel para diferenciar "não informado" de "explicitamente null" no copyWith
const _keepCurrent = Object();

class Usuario {
  final String id;
  final String nome;
  final String email;
  final bool premium;
  final PlanoUsuario plano;
  final DateTime? dataExpiracaoPremium;

  const Usuario({
    required this.id,
    required this.nome,
    required this.email,
    this.premium = false,
    this.plano = PlanoUsuario.free,
    this.dataExpiracaoPremium,
  });

  // NOTA: verificação de expiração usa o relógio do aparelho como fallback.
  // A fonte de verdade definitiva é a Cloud Function validatePremium,
  // que deve ser consultada em ações críticas (desbloqueio de recurso).
  bool get premiumAtivo {
    if (!premium) return false;
    if (plano == PlanoUsuario.vitalicio) return true;
    if (dataExpiracaoPremium == null) return false;
    return DateTime.now().isBefore(dataExpiracaoPremium!);
  }

  /// Uso do sentinel `_keepCurrent` permite que `dataExpiracaoPremium`
  /// seja explicitamente setado para null (ex: ao promover para vitalício).
  Usuario copyWith({
    String? nome,
    bool? premium,
    PlanoUsuario? plano,
    Object? dataExpiracaoPremium = _keepCurrent,
  }) {
    return Usuario(
      id: id,
      nome: nome ?? this.nome,
      email: email,
      premium: premium ?? this.premium,
      plano: plano ?? this.plano,
      dataExpiracaoPremium: identical(dataExpiracaoPremium, _keepCurrent)
          ? this.dataExpiracaoPremium
          : dataExpiracaoPremium as DateTime?,
    );
  }

  factory Usuario.fromMap(Map<String, dynamic> map) {
    DateTime? parseData(dynamic value) {
      if (value == null) return null;
      if (value is Timestamp) return value.toDate();
      if (value is String) return DateTime.tryParse(value);
      return null;
    }

    return Usuario(
      id: map['id'] as String,
      nome: map['nome'] as String? ?? '',
      email: map['email'] as String? ?? '',
      premium: map['premium'] as bool? ?? false,
      plano: PlanoUsuario.values.firstWhere(
        (p) => p.name == (map['plano'] as String? ?? 'free'),
        orElse: () => PlanoUsuario.free,
      ),
      dataExpiracaoPremium: parseData(map['dataExpiracaoPremium']),
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'nome': nome,
        'email': email,
        'premium': premium,
        'plano': plano.name,
        'dataExpiracaoPremium': dataExpiracaoPremium?.toIso8601String(),
      };
}
