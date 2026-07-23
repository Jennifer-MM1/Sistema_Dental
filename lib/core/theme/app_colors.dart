import 'package:flutter/material.dart';

class AppColors {
  // Main brand colors based on Figma
  static const Color primaryBlue = Color(
    0xFF006C9C,
  ); // Color principal para botones y headers
  static const Color secondaryBlue = Color(0xFF00537A); // Azul más oscuro
  static const Color lightBlueAccent = Color(
    0xFFBBE5F6,
  ); // Azul claro para selección
  static const Color background = Color(0xFFF3F7FA); // Fondo general claro
  static const Color surface = Colors.white;

  // Text colors
  static const Color textPrimary = Color(0xFF1E293B);
  static const Color textSecondary = Color(0xFF64748B);

  // Status colors
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B); // Para "In Queue"
  static const Color error = Color(0xFFEF4444); // Para "Delayed"
}
