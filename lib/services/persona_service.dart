import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../theme/persona_palette.dart';

/// Local persona + onboarding flags (on-device only).
class PersonaService extends ChangeNotifier {
  PersonaService._();
  static final PersonaService instance = PersonaService._();

  static const _personaKey = 'he_persona';
  static const _onboardingKey = 'he_onboarding_complete';
  static const _incomeKey = 'he_monthly_income_seed';

  String _persona = 'family';
  bool _onboardingComplete = false;
  double _monthlyIncomeSeed = 0;
  bool _loaded = false;

  String get persona => _persona;
  bool get onboardingComplete => _onboardingComplete;
  double get monthlyIncomeSeed => _monthlyIncomeSeed;
  bool get isLoaded => _loaded;
  PersonaAccent get accents => PersonaPalette.of(_persona);

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _persona = PersonaPalette.normalize(prefs.getString(_personaKey));
    _onboardingComplete = prefs.getBool(_onboardingKey) ?? false;
    _monthlyIncomeSeed = prefs.getDouble(_incomeKey) ?? 0;
    _loaded = true;
    notifyListeners();
  }

  Future<void> setPersona(String persona) async {
    _persona = PersonaPalette.normalize(persona);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_personaKey, _persona);
    notifyListeners();
  }

  Future<void> completeOnboarding({
    required String persona,
    required double monthlyIncome,
  }) async {
    _persona = PersonaPalette.normalize(persona);
    _monthlyIncomeSeed = monthlyIncome < 0 ? 0 : monthlyIncome;
    _onboardingComplete = true;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_personaKey, _persona);
    await prefs.setBool(_onboardingKey, true);
    await prefs.setDouble(_incomeKey, _monthlyIncomeSeed);
    notifyListeners();
  }

  Future<void> resetOnboardingForTests() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_onboardingKey);
    _onboardingComplete = false;
    notifyListeners();
  }
}
