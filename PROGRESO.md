# 📈 Progreso del Proyecto: DentalSync (Sistema Dental)

Este documento detalla el estado actual del desarrollo del sistema dental **DentalSync**, describiendo las funcionalidades implementadas hasta la fecha y las sugerencias de implementación para las siguientes etapas.

---

## 🛠️ Lo que se lleva hasta ahora (Implementado)

### 1. Gestión de Personal y Consultorios (Módulo 1)
Se completó un sistema robusto para que la administración o los dueños de clínicas gestionen el equipo de trabajo y los recursos físicos:
* **Base de Datos (Supabase):** 
  * Tabla `doctor_schedules` para definir los horarios semanales por doctor y clínica.
  * Tabla `doctor_days_off` para registrar ausencias puntuales o vacaciones con su respectivo motivo.
  * Políticas de RLS (Row Level Security) y triggers para mantener `updated_at` al día.
* **Backend y Modelos (Dart):**
  * Modelos `StaffMember`, `DoctorDaySchedule` y `DoctorDayOff` en [doctor.dart](file:///lib/core/models/doctor.dart).
  * Repositorio [staff_repository.dart](file:///lib/features/dentist/data/staff_repository.dart) con operaciones CRUD para horarios, días libres, cabinas y disponibilidad.
* **Interfaz de Usuario (Flutter):**
  * Nueva pestaña en el panel del dentista: **"Personal y Consultorios"** ([staff_management_view.dart](file:///lib/features/dentist/presentation/widgets/staff_management_view.dart)).
  * Tarjetas de presentación de personal con switch para cambiar la **disponibilidad** en tiempo real.
  * Selector desplegable para asignar y cambiar el **consultorio (cabina)** asignado.
  * Modal deslizante (Bottom Sheet) para programar el **horario semanal** día por día con `TimePicker`.
  * Diálogo interactivo para añadir y eliminar **días libres** usando `DatePicker`.

### 2. Notificaciones Push en Tiempo Real (Módulo 2)
Se estructuró la infraestructura de comunicación para alertar a los pacientes sobre el estado de sus citas directamente en sus dispositivos móviles:
* **Integración Android - Firebase:**
  * Configuración a nivel nativo de Android mediante el archivo `google-services.json` y la inclusión de dependencias usando la Firebase BoM.
  * Generación de `firebase_options.dart` para inicializar el SDK de Firebase en Flutter.
* **Lógica en Flutter:**
  * Creación del servicio [fcm_service.dart](file:///lib/core/notifications/fcm_service.dart) para solicitar permisos de notificación, obtener el token único del dispositivo y registrarlo/desactivarlo en la tabla `linked_devices` de Supabase.
  * Integración con `flutter_local_notifications` para mostrar notificaciones flotantes cuando la aplicación se encuentra en primer plano (foreground).
  * Conexión asíncrona ("fire-and-forget") en `AppointmentRepository` para invocar el envío al cambiar el estado de la cita a `in_lobby`, `in_treatment` o `completed`.
* **Edge Function (Supabase):**
  * Creación y despliegue de la función `notify-patient-turn` escrita en TypeScript (Deno).
  * Autenticación segura mediante la API v1 de FCM utilizando una cuenta de servicio de Firebase (`FIREBASE_SERVICE_ACCOUNT` secret).
  * Detección y limpieza automática en base de datos de tokens FCM obsoletos o desinstalados (`UNREGISTERED`).

---

## 🚀 Próximas Funcionalidades (Sugeridas para Implementar)

A partir de la base actual, se pueden implementar las siguientes características para enriquecer el software:

### 1. Integración con Smartwatches y Wearables
* La tabla `linked_devices` en Supabase cuenta con soporte para registrar dispositivos de tipo `watch_os`. Se puede extender la aplicación cliente en Flutter para enviar alertas de turnos directamente a relojes inteligentes.

### 2. Recordatorios de Citas Automatizados (Cron Jobs / Supabase pg_net)
* Implementar recordatorios automáticos (por ejemplo, 24 horas antes de la cita).
* Esto se puede realizar mediante Edge Functions que se ejecuten periódicamente (ej. cada hora) para buscar citas próximas y disparar notificaciones push automáticas a los pacientes correspondientes.

### 3. Historial Clínico y Recetas Digitales
* Crear un módulo para que los dentistas registren notas de evolución, odontogramas interactivos y generen recetas en formato PDF que los pacientes puedan descargar desde su respectivo panel.

### 4. Chat Interno de la Clínica (Dentistas ↔️ Recepción)
* Aprovechar las capacidades en tiempo real de Supabase (`Realtime`) para crear un canal de chat ágil entre la recepción (secretarias) y los odontólogos en los consultorios, facilitando avisos internos sin salir de la app.

### 5. Configuración de Notificaciones en iOS
* Actualmente la app está lista en Android. Para iOS, se requiere configurar las llaves APNs en el portal de desarrolladores de Apple y vincular los certificados en Firebase Console para habilitar las alertas push en iPhones.
