import 'package:flutter_test/flutter_test.dart';
import 'package:sistema_dental/core/cache/local_cache_service.dart';

void main() {
  group('LocalCacheService Tests', () {
    test('Debe guardar y recuperar datos JSON en memoria correctamente', () async {
      final cache = LocalCacheService.instance;
      cache.clear();

      final data = {'appointmentsCount': 5, 'patientName': 'Juan Pérez'};
      await cache.setJson('test_key', data);

      expect(cache.hasKey('test_key'), isTrue);

      final retrieved = cache.getJson('test_key');
      expect(retrieved, isNotNull);
      expect(retrieved['appointmentsCount'], equals(5));
      expect(retrieved['patientName'], equals('Juan Pérez'));
    });

    test('Debe retornar null cuando una clave no existe en la caché', () {
      final cache = LocalCacheService.instance;
      final result = cache.getJson('non_existent_key');
      expect(result, isNull);
    });
  });
}
