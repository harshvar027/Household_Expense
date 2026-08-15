import 'package:flutter/material.dart';

/// Persona accent tokens for Household Expense life-stage themes.
class PersonaAccent {
  final Color accent;
  final Color accentStrong;
  final Color accentSoft;
  final Color accentGlow;

  const PersonaAccent({
    required this.accent,
    required this.accentStrong,
    required this.accentSoft,
    required this.accentGlow,
  });
}

class PersonaPalette {
  PersonaPalette._();

  static const professional = PersonaAccent(
    accent: Color(0xFF2EE6A6),
    accentStrong: Color(0xFF14B8A6),
    accentSoft: Color(0x242EE6A6),
    accentGlow: Color(0x592EE6A6),
  );

  static const student = PersonaAccent(
    accent: Color(0xFF5EEAD4),
    accentStrong: Color(0xFF2DD4BF),
    accentSoft: Color(0x295EEAD4),
    accentGlow: Color(0x665EEAD4),
  );

  static const family = PersonaAccent(
    accent: Color(0xFFFBBF24),
    accentStrong: Color(0xFFF59E0B),
    accentSoft: Color(0x24FBBF24),
    accentGlow: Color(0x4DF59E0B),
  );

  static const senior = PersonaAccent(
    accent: Color(0xFFA5B4FC),
    accentStrong: Color(0xFF818CF8),
    accentSoft: Color(0x24A5B4FC),
    accentGlow: Color(0x4D818CF8),
  );

  static String normalize(String? raw) {
    switch ((raw ?? 'family').toLowerCase().trim()) {
      case 'student':
        return 'student';
      case 'professional':
        return 'professional';
      case 'senior':
        return 'senior';
      default:
        return 'family';
    }
  }

  static PersonaAccent of(String? persona) {
    switch (normalize(persona)) {
      case 'student':
        return student;
      case 'professional':
        return professional;
      case 'senior':
        return senior;
      default:
        return family;
    }
  }

  static String label(String? persona) {
    switch (normalize(persona)) {
      case 'student':
        return 'Student';
      case 'professional':
        return 'Professional';
      case 'senior':
        return 'Senior';
      default:
        return 'Family';
    }
  }
}
