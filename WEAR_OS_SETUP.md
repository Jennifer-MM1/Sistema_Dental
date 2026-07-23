# DentalSync para Wear OS

El reloj funciona como extensión de la aplicación Android. La autenticación,
Supabase y Firebase permanecen en el teléfono; Wear OS solo recibe el estado
necesario y envía acciones al teléfono emparejado.

## Compilar

La aplicación normal usa por defecto el flavor `phone`:

```powershell
flutter run -d R58W500HZNV
```

Para generar el APK complementario de Wear OS:

```powershell
flutter build apk --debug --flavor wear -t lib/main_wear.dart
```

El resultado queda en `build/app/outputs/flutter-apk/app-wear-debug.apk`.

## Instalar durante desarrollo

Activa las opciones de desarrollador y la depuración inalámbrica en el Pixel
Watch. Después conecta ADB con la dirección que muestra el reloj e instala el
APK:

```powershell
adb pair DIRECCION_IP:PUERTO
adb connect DIRECCION_IP:PUERTO
adb -s DIRECCION_IP:PUERTO install -r build\app\outputs\flutter-apk\app-wear-debug.apk
```

La aplicación Google Pixel Watch administra el emparejamiento. Para distribuir
DentalSync automáticamente desde ella, los flavors `phone` y `wear` deberán
publicarse con la misma firma y el mismo `applicationId` en Google Play.

## Uso

1. Inicia sesión en DentalSync únicamente desde el teléfono.
2. Abre `Perfil > Vincular Wear OS`.
3. Abre DentalSync Watch y pulsa `Reintentar` si todavía muestra la espera.
4. Para desvincular, utiliza el mismo apartado del perfil o cierra sesión.
