import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

enum TipoModalidade {
  megaSena,
  lotofacil,
  quina,
  duplaSena,
  lotomania,
  timemania,
  superSete,
}

class Modalidade {
  final String id;
  final String nome;
  final TipoModalidade tipo;
  final Color corPrimaria;
  final Color corSecundaria;
  final Color corDestaque;
  final int universoNumeros;
  final int numerosMin;
  final int numerosMax;
  final Map<int, String> faixasPremio;
  final bool disponivel;

  const Modalidade({
    required this.id,
    required this.nome,
    required this.tipo,
    required this.corPrimaria,
    required this.corSecundaria,
    required this.corDestaque,
    required this.universoNumeros,
    required this.numerosMin,
    required this.numerosMax,
    required this.faixasPremio,
    this.disponivel = true,
  });

  static const List<Modalidade> todas = [
    Modalidade(
      id: 'mega-sena',
      nome: 'Mega-Sena',
      tipo: TipoModalidade.megaSena,
      corPrimaria: AppColors.megaSenaPrimary,
      corSecundaria: AppColors.megaSenaSecondary,
      corDestaque: AppColors.megaSenaDestaque,
      universoNumeros: 60,
      numerosMin: 6,
      numerosMax: 20,
      faixasPremio: {6: 'Sena', 5: 'Quina', 4: 'Quadra'},
    ),
    Modalidade(
      id: 'lotofacil',
      nome: 'Lotofácil',
      tipo: TipoModalidade.lotofacil,
      corPrimaria: AppColors.lotofacilPrimary,
      corSecundaria: AppColors.lotofacilSecondary,
      corDestaque: AppColors.lotofacilDestaque,
      universoNumeros: 25,
      numerosMin: 15,
      numerosMax: 20,
      faixasPremio: {15: '15 acertos', 14: '14 acertos', 13: '13 acertos', 12: '12 acertos', 11: '11 acertos'},
    ),
    Modalidade(
      id: 'quina',
      nome: 'Quina',
      tipo: TipoModalidade.quina,
      corPrimaria: AppColors.quina,
      corSecundaria: Color(0xFFFCE8E8),
      corDestaque: Color(0xFF7B1212),
      universoNumeros: 80,
      numerosMin: 5,
      numerosMax: 15,
      faixasPremio: {5: 'Quina', 4: 'Quadra', 3: 'Terno', 2: 'Duque'},
    ),
    Modalidade(
      id: 'dupla-sena',
      nome: 'Dupla Sena',
      tipo: TipoModalidade.duplaSena,
      corPrimaria: AppColors.duplaSena,
      corSecundaria: Color(0xFFFCEFE8),
      corDestaque: Color(0xFFA82B06),
      universoNumeros: 50,
      numerosMin: 6,
      numerosMax: 15,
      faixasPremio: {6: 'Sena', 5: 'Quina', 4: 'Quadra', 3: 'Terno'},
      disponivel: false,
    ),
    Modalidade(
      id: 'lotomania',
      nome: 'Lotomania',
      tipo: TipoModalidade.lotomania,
      corPrimaria: AppColors.lotomania,
      corSecundaria: Color(0xFFFFF3E0),
      corDestaque: Color(0xFFCC5500),
      universoNumeros: 100,
      numerosMin: 50,
      numerosMax: 50,
      faixasPremio: {20: '20 acertos', 19: '19 acertos', 18: '18 acertos', 0: '0 acertos'},
      disponivel: false,
    ),
    Modalidade(
      id: 'timemania',
      nome: 'Timemania',
      tipo: TipoModalidade.timemania,
      corPrimaria: AppColors.timemania,
      corSecundaria: Color(0xFFE8F5E9),
      corDestaque: Color(0xFF1B5E20),
      universoNumeros: 80,
      numerosMin: 10,
      numerosMax: 10,
      faixasPremio: {7: 'Sete', 6: 'Seis', 5: 'Cinco', 4: 'Quatro', 3: 'Três'},
      disponivel: false,
    ),
    Modalidade(
      id: 'super-sete',
      nome: 'Super Sete',
      tipo: TipoModalidade.superSete,
      corPrimaria: AppColors.superSete,
      corSecundaria: Color(0xFFEFEBE9),
      corDestaque: Color(0xFF4E342E),
      universoNumeros: 10,
      numerosMin: 7,
      numerosMax: 7,
      faixasPremio: {7: 'Super Sete', 6: 'Seis', 5: 'Cinco', 4: 'Quatro', 3: 'Três'},
      disponivel: false,
    ),
  ];

  static Modalidade porId(String id) =>
      todas.firstWhere((m) => m.id == id, orElse: () => todas.first);
}
