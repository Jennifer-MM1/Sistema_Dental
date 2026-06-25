# DentalSync Connect 🦷

DentalSync Connect es un sistema inteligente y profesional de gestión clínica odontológica, desarrollado en **Flutter**. El sistema está diseñado bajo un enfoque multiplataforma y adaptativo, ofreciendo interfaces de usuario personalizadas y optimizadas según el rol del usuario y el dispositivo de uso común.

---

## 🚀 Arquitectura y Roles del Sistema

La aplicación adapta su flujo de trabajo y presentación visual a tres perfiles principales:

1. **Dentista (Optimizado para Tablets 📱)**:
   - Panel de control clínico táctil para consultas rápidas.
   - Gestión y visualización de expedientes médicos y tratamientos en tiempo real.
   - Vista optimizada para la interacción rápida durante la atención al paciente.

2. **Secretaria / Recepción (Optimizado para Escritorio 💻)**:
   - Agenda completa y gestión de turnos/citas.
   - Panel administrativo para registro de pacientes, estados de asistencia ("In Queue", "Delayed", etc.) y facturación.
   - Interfaz con alta densidad de información ideal para pantallas anchas.

3. **Paciente (Optimizado para Dispositivos Móviles 📲)**:
   - Consulta de citas próximas y pasadas.
   - Visualización de historial de tratamientos y recetas.
   - Recordatorios y comunicación directa con la clínica.

---

## 🛠️ Stack Tecnológico

- **Framework**: [Flutter](https://flutter.dev) (multiplataforma)
- **Lenguaje**: [Dart](https://dart.dev)
- **Gestor de Estado**: [Riverpod (flutter_riverpod)](https://riverpod.dev) para un manejo de estado robusto y testeable.
- **Navegación**: [GoRouter](https://pub.dev/packages/go_router) para rutas declarativas y soporte de deep linking.
- **Base de Datos y Autenticación**: [Firebase Suite](https://firebase.google.com/) (Auth, Firestore y Core).
- **Diseño Visual**:
  - Fuente: [Google Fonts - Inter](https://fonts.google.com/specimen/Inter)
  - Temas dinámicos y paletas de colores basadas en HSL (en `core/theme`).

---

## 📂 Estructura del Proyecto

El proyecto sigue un patrón **Feature-First (orientado a características)**, lo cual facilita la modularización y la escalabilidad del sistema:

```text
lib/
├── core/                  # Recursos transversales del sistema
│   ├── router/            # Configuración de GoRouter (rutas del sistema)
│   └── theme/             # Definición de la paleta de colores y estilos globales
├── features/              # Módulos de funcionalidad independientes
│   ├── auth/              # Pantalla de inicio de sesión y autenticación
│   ├── dentist/           # Dashboard y flujos clínicos del odontólogo
│   ├── patient/           # Vista y utilidades del paciente
│   └── secretary/         # Gestión administrativa, agenda y recepción
└── main.dart              # Punto de entrada de la aplicación
```

---

## ⚙️ Instalación y Configuración Local

Sigue estos pasos para levantar el entorno de desarrollo localmente:

### 1. Requisitos Previos
- Tener instalado el SDK de [Flutter](https://flutter.dev/docs/get-started/install) (versión compatible con Dart SDK `^3.12.2`).
- Disponer de un emulador (Android/iOS) o navegador web activo para pruebas.

### 2. Clonar el Repositorio
```bash
git clone <url-del-repositorio>
cd Sistema_Dental
```

### 3. Instalar Dependencias
Descarga todos los paquetes necesarios declarados en el `pubspec.yaml`:
```bash
flutter pub get
```

### 4. Configurar Firebase (Opcional)
Si deseas conectar tu propia instancia de Firebase:
- Crea un proyecto en la consola de Firebase.
- Agrega plataformas (Android, iOS, Web).
- Configura las credenciales descargando los archivos `google-services.json` (Android), `GoogleService-Info.plist` (iOS) o inicializando con FlutterFire CLI.

### 5. Ejecutar la Aplicación
Puedes iniciar la aplicación en modo desarrollo ejecutando:
```bash
flutter run
```

---

## 🎨 Guía de Diseño Visual y Colores

Los colores principales de la aplicación se definen de manera centralizada en `lib/core/theme/app_colors.dart`:
- **Azul Primario (`0xFF006C9C`)**: Color de identidad para botones y encabezados principales.
- **Azul Secundario (`0xFF00537A`)**: Acentos y botones secundarios.
- **Fondo General (`0xFFF3F7FA`)**: Tono grisáceo claro para mayor descanso visual.
- **Estados**:
  - `success` (`0xFF10B981`) -> Éxito, completado.
  - `warning` (`0xFFF59E0B`) -> En cola / Pendiente.
  - `error` (`0xFFEF4444`) -> Retrasado / Cancelado.
