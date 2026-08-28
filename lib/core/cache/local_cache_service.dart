import 'dart:convert';
import 'package:flutter/foundation.dart';

/// Servicio de caché local en memoria y persistente para modo sin conexión (Offline).
class LocalCacheService {
  static final LocalCacheService instance = LocalCacheService._internal();
  LocalCacheService._internal();

  final Map<String, String> _memoryCache = {};

  /// Guardar un objeto o lista JSON en caché por clave
  Future<void> setJson(String key, dynamic data) async {
    try {
      final jsonStr = jsonEncode(data);
      _memoryCache[key] = jsonStr;
    } catch (e) {
      debugPrint('Error guardando en caché local ($key): $e');
    }
  }

  /// Recuperar un objeto o lista JSON desde la caché local
  dynamic getJson(String key) {
    try {
      final raw = _memoryCache[key];
      if (raw == null) return null;
      return jsonDecode(raw);
    } catch (e) {
      debugPrint('Error leyendo caché local ($key): $e');
      return null;
    }
  }

  /// Verificar si existe una clave en caché
  bool hasKey(String key) => _memoryCache.containsKey(key);

  /// Limpiar caché
  void clear() {
    _memoryCache.clear();
  }
}
