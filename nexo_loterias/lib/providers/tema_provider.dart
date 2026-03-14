import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TemaProvider extends ChangeNotifier {
  static const _chave = 'tema_escuro';
  bool _escuro = true;

  bool get escuro => _escuro;
  ThemeMode get themeMode => _escuro ? ThemeMode.dark : ThemeMode.light;

  TemaProvider() {
    _carregar();
  }

  Future<void> _carregar() async {
    final prefs = await SharedPreferences.getInstance();
    _escuro = prefs.getBool(_chave) ?? true;
    notifyListeners();
  }

  Future<void> alternar() async {
    _escuro = !_escuro;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_chave, _escuro);
  }
}
