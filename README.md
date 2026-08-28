# DentalSync Connect 🦷

**DentalSync Connect** es un sistema integral e inteligente de gestión clínica odontológica desarrollado en **Flutter** y respaldado por **Supabase** y **Firebase**. Diseñado con una arquitectura moderna, reactiva y adaptativa, ofrece experiencias de usuario personalizadas según el rol de cada usuario y el dispositivo utilizado (Móvil, Tablet, Desktop, Web y Wear OS).

---

## 🌟 Características Principales

### 👨‍⚕️ 1. Módulo del Dentista (Clínico y Operativo)
* **Odontograma Interactivo**: Registro visual por piezas dentales y caras (oclusal, vestibular, lingual, mesial, distal) con estados patológicos y tratamientos (caries, obturación, endodoncia, coronas, extracciones, etc.).
* **Expediente e Historial Clínico Digital**: Registro y consulta cronológica de evoluciones, diagnósticos y notas médicas.
* **Estudios y Radiografías**: Carga, visualización y gestión de archivos adjuntos (radiografías, tomografías, fotos clínicas) integrados con Supabase Storage (`clinical-files`).
* **Generación de Recetas y Expedientes en PDF**: Emisión de recetas médicas y reportes de historial clínico en formato PDF profesional listos para imprimir o compartir.
* **Gestión de Personal y Consultorios (Staff Management)**:
  * Configuración de horarios semanales día por día y por consultorio/cabina.
  * Registro de días libres y vacaciones con motivos.
  * Control de disponibilidad en tiempo real (disponible / no disponible).
* **Reportes y Métricas Operativas**: Dashboard estadístico de citas completadas, canceladas y rendimiento general con exportación en PDF.
* **Agenda Clínica y Llamado de Pacientes**: Control de turnos y avance de estados en tiempo real con alertas automáticas.

---

### 👩‍💼 2. Módulo de Secretaría y Recepción (Administración)
* **Tablero de Control de Citas y Turnos**: Monitoreo y cambio de estados de sala de espera en tiempo real (`In Queue`, `In Lobby`, `In Treatment`, `Completed`, `Delayed`, `Cancelled`).
* **Recepción y Registro de Pacientes**: Creación y edición rápida de pacientes y asignación de turnos.
* **Gestión de Consultorios**: Asignación de pacientes a doctores y cabinas específicas.
* **Vinculación por Código QR**: Generación y escaneo de códigos QR para invocar y vincular pacientes o personal a la clínica.
* **Diseño para Pantallas Anchas**: Interfaz de alta densidad de información con navegación rápida optimizada para escritorio y navegadores web.

---

### 📱 3. Módulo del Paciente y Familiares (Móvil)
* **Gestión de Citas**: Visualización de citas programadas, estado del turno actual en sala de espera y tiempo estimado.
* **Gestión de Dependientes / Familiares**: Selector rápido para administrar citas e historiales de familiares a cargo.
* **Historial y Recetas**: Acceso directo y descarga de recetas emitidas y tratamientos previos.
* **Notificaciones en Tiempo Real**: Recepción de alertas instantáneas cuando el dentista o la clínica llaman al paciente a consulta.
* **Vinculación a Clínicas**: Registro ágil escaneando el código QR de la clínica o introduciendo el código de acceso.

---

### ⌚ 4. Aplicación Complementaria para Wear OS (Smartwatch)
* **App Nativa para Relojes Inteligentes**: Flavor dedicado (`wear`) con interfaces circulares y optimizadas para interacción táctil rápida.
* **Modo Paciente en Reloj**: Consulta de turno actual, sala de espera, selección de dependientes y vibración/alerta inmediata al ser llamado a cabina.
* **Modo Dentista en Reloj**: Visualización rápida del próximo paciente y llamado directo desde la muñeca.
* **Sincronización con el Teléfono**: Canal de datos local para mantener sincronizado el estado sin requerir login directo en el reloj.
* **Simulador / Vista Previa Web**: Ruta `/wear-preview` integrada para probar las pantallas del reloj directamente desde el navegador.

---

### 🔔 5. Notificaciones Push y Automatización
* **Firebase Cloud Messaging (FCM)**: Envío de alertas push directas a dispositivos Android/iOS.
* **Supabase Edge Functions**:
  * `notify-patient-turn`: Disparo automático de alertas al cambiar el estado del turno (`in_lobby`, `in_treatment`, etc.).
  * `remind-upcoming-appointments`: Recordatorios automáticos programados 24 horas antes de cada cita vía `pg_cron`.
* **Notificaciones Locales**: Alertas visuales flotantes en primer plano con `flutter_local_notifications`.

---

### 🌐 6. Resiliencia y Modo Offline
* **Caché Local**: Almacenamiento local de expedientes y citas para consulta rápida sin conexión a internet.
* **Detección de Conexión**: Banner visual interactivo que advierte el estado de conectividad en tiempo real.

---

## 🛠️ Stack Tecnológico

| Capa | Tecnología / Paquete | Propósito |
| :--- | :--- | :--- |
| **Framework** | [Flutter](https://flutter.dev) (SDK `^3.12.2` / Dart 3) | Desarrollo multiplataforma (Móvil, Tablet, Desktop, Web, Wear OS) |
| **Gestión de Estado** | [Riverpod (`flutter_riverpod`)](https://riverpod.dev) | Arquitectura reactiva y providers testeables |
| **Navegación** | [GoRouter](https://pub.dev/packages/go_router) | Rutas declarativas y redirecciones por roles |
| **Backend & DB** | [Supabase](https://supabase.com/) | PostgreSQL, Autenticación, Realtime WebSockets, Storage y Edge Functions |
| **Notificaciones** | Firebase Cloud Messaging (FCM) + `flutter_local_notifications` | Alertas push remotas y locales |
| **Documentos PDF** | `pdf` & `printing` | Generación e impresión de recetas, historiales y reportes |
| **Escaneo QR** | `qr_flutter` & `mobile_scanner` | Generación y lectura de códigos QR de clínica |
| **Tipografía y Estilo** | `google_fonts` (Inter) + Temas HSL personalizados | Sistema de diseño profesional y consistente |

---

## 📂 Estructura del Proyecto

El código está organizado bajo el enfoque **Feature-First (orientado a módulos)**:

```text
lib/
├── core/                         # Utilidades y configuración transversal
│   ├── cache/                    # Servicio de caché local y almacenamiento
│   ├── models/                   # Modelos de datos globales (Doctor, Citas, Adjuntos, etc.)
│   ├── notifications/            # Servicio FCM y notificaciones locales
│   ├── router/                   # Configuración y protección de rutas con GoRouter
│   ├── supabase/                 # Inicialización y cliente de Supabase
│   ├── theme/                    # Paleta de colores HSL, estilos y temas globales
│   └── wear/                     # Servicios de vinculación y datos para Wear OS
├── features/                     # Módulos funcionales del sistema
│   ├── auth/                     # Autenticación, registro, selección de rol y vinculación
│   ├── client/                   # Dashboard del paciente, selector de dependientes e historial
│   ├── dentist/                  # Panel clínico, odontograma, staff, expedientes y reportes
│   ├── secretary/                # Recepción, agenda de citas y control de sala de espera
│   ├── shared/                   # Generadores PDF, repositorios compartidos y widgets comunes
│   ├── super_admin/              # Administración general y generación de invitaciones QR
│   └── wear/                     # Vistas y lógica de la app para Wear OS y preview web
├── main.dart                     # Punto de entrada principal (Phone / Tablet / Desktop / Web)
├── main_wear.dart                # Punto de entrada para la aplicación de Wear OS
└── firebase_options.dart         # Configuración del cliente Firebase
```

---

## ⚙️ Instalación y Configuración

### 1. Requisitos Previos
* **Flutter SDK**: `>= 3.12.2` instalado y configurado en el PATH.
* **Dispositivo de prueba**: Emulador Android, simulador iOS, dispositivo físico o navegador Chrome.
* **Cuenta de Supabase** y proyecto activo con el esquema configurado.
* **Proyecto en Firebase** con credenciales para Android (`google-services.json`) e iOS (`GoogleService-Info.plist`).

### 2. Clonar el Repositorio
```bash
git clone <url-del-repositorio>
cd Sistema_Dental
```

### 3. Configurar Variables de Entorno
Copia el archivo de ejemplo `.env.example` a `.env` y completa tus credenciales:
```bash
cp .env.example .env
```
Contenido esperado en `.env`:
```env
SUPABASE_URL=https://tu-proyecto.supabase.co
SUPABASE_ANON_KEY=tu-anon-key
```

### 4. Instalar Dependencias
```bash
flutter pub get
```

### 5. Ejecutar la Aplicación Principal
```bash
# En el navegador Web
flutter run -d chrome

# En un dispositivo Android o emulador
flutter run
```

---

## ⌚ Compilación y Uso en Wear OS

Para ejecutar o compilar la aplicación dedicada de **Wear OS**:

### Compilar el APK para Smartwatch:
```bash
flutter build apk --debug --flavor wear -t lib/main_wear.dart
```

### Instalar en el reloj vía ADB:
```bash
adb pair <IP_DEL_RELOJ>:<PUERTO>
adb connect <IP_DEL_RELOJ>:<PUERTO>
adb -s <IP_DEL_RELOJ>:<PUERTO> install -r build/app/outputs/flutter-apk/app-wear-debug.apk
```

### Probar en el navegador (Simulador Web):
Inicia la app web y navega a:
```text
http://localhost:<puerto>/#/wear-preview
```

---

## 🎨 Sistema de Diseño y Colores

La paleta cromática centralizada en `lib/core/theme/app_colors.dart` garantiza consistencia visual:

* 🔵 **Azul Primario (`#006C9C`)**: Botones de acción principal y encabezados clínicos.
* 🔷 **Azul Secundario (`#00537A`)**: Elementos secundarios y acentos de navegación.
* ⚪ **Fondo General (`#F3F7FA`)**: Fondo claro y limpio optimizado para lectura prolongada.
* 🟢 **Éxito (`#10B981`)**: Tratamiento completado / Cita finalizada / Disponible.
* 🟡 **Advertencia (`#F59E0B`)**: Paciente en espera (`In Queue`, `In Lobby`).
* 🔴 **Error / Retraso (`#EF4444`)**: Cita cancelada / Retrasada / No disponible.

---

## 📄 Licencia

Este proyecto es de uso profesional y clínico bajo los términos de propiedad del equipo de desarrollo de **DentalSync**.
