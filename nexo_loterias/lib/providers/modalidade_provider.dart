import 'package:flutter/material.dart';
import '../data/models/modalidade.dart';
import '../core/theme/app_theme.dart';

class ModalidadeProvider extends ChangeNotifier {
  Modalidade _modalidadeAtual = Modalidade.todas.first;

  Modalidade get modalidadeAtual => _modalidadeAtual;

  ThemeData get temaAtual {
    switch (_modalidadeAtual.tipo) {
      case TipoModalidade.megaSena:
        return AppTheme.megaSena;
      case TipoModalidade.lotofacil:
        return AppTheme.lotofacil;
      default:
        return AppTheme.buildTheme(
          primary: _modalidadeAtual.corPrimaria,
          secondary: _modalidadeAtual.corSecundaria,
          destaque: _modalidadeAtual.corDestaque,
        );
    }
  }

  void selecionarModalidade(Modalidade modalidade) {
    if (_modalidadeAtual.id != modalidade.id) {
      _modalidadeAtual = modalidade;
      notifyListeners();
    }
  }
}
