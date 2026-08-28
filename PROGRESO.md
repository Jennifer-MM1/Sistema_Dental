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


### 3. Recordatorios de Citas Automatizados (Módulo 3)
* **Edge Function en Supabase:** `remind-upcoming-appointments` para enviar notificaciones push a pacientes 24h antes de su cita.
* **Migración SQL:** [202608030001_cron_reminders.sql](file:///supabase/migrations/202608030001_cron_reminders.sql) con la columna `reminder_sent` e índices para la ejecución periódica con `pg_cron`.

### 4. Estudios Clínicos y Radiografías (Módulo 4)
* **Supabase Storage:** Bucket `clinical-files` y políticas RLS [202608030002_clinical_attachments_storage.sql](file:///supabase/migrations/202608030002_clinical_attachments_storage.sql).
* **Dart Models & Repository:** Modelo [clinical_attachment.dart](file:///lib/core/models/clinical_attachment.dart) y repositorio [clinical_attachment_repository.dart](file:///lib/features/dentist/data/clinical_attachment_repository.dart) para subir y descargar radiografías, tomografías e imágenes clínicas.

### 5. Caché Local y Modo Offline (Módulo 5)
* **Servicio de Caché:** [local_cache_service.dart](file:///lib/core/cache/local_cache_service.dart) para almacenar copias locales de expedientes y citas.
* **Banner de Estado:** Componente visual [offline_banner.dart](file:///lib/features/shared/presentation/widgets/offline_banner.dart) para alertar al usuario en modo sin conexión.

### 6. Reportes Médicos Operativos y Pruebas (Módulo 6)
* **Dashboard Estadístico:** Componente [clinical_reports_view.dart](file:///lib/features/dentist/presentation/widgets/clinical_reports_view.dart) con gráficos de citas completadas vs canceladas y exportación de reportes resumidos en PDF.
* **Pruebas Automatizadas:** Suite de tests unitarios [clinical_attachment_test.dart](file:///test/clinical_attachment_test.dart) y [local_cache_service_test.dart](file:///test/local_cache_service_test.dart).

---

## 📱 Compatibilidad Multidispositivo (Estado Actual)

El sistema está diseñado en **Flutter** para ser multidispositivo, adaptándose de la siguiente manera:

* **Celulares y Tablets (Android / iOS):**
  * **Diseño:** 100% responsivo. Las pantallas adaptan automáticamente sus menús, botones y componentes visuales para un uso táctil cómodo en cualquier tamaño.
  * **Notificaciones:** Listas en Android. En iOS requiere configurar las credenciales APNs en Firebase Console.
* **Computadoras de Escritorio / Laptops (PC / Web):**
  * **Diseño:** Optimizado para pantallas horizontales amplias (barra de navegación lateral persistente, tablas organizadas y flujos de trabajo paralelos).
  * **Notificaciones:** Integradas a través del canal en tiempo real de Supabase (`Realtime`), garantizando actualizaciones al instante sin depender de sistemas de push tradicionales de celular.
* **Relojes Inteligentes (Smartwatches - Wear OS / watchOS):**
  * **Modo Espejo (Mirroring):** Funcional por defecto. Al recibir notificaciones push en el teléfono enlazado, se duplican directamente en el reloj del usuario. Se determinó que este comportamiento es suficiente, por lo que se descarta desarrollar una aplicación o interfaz dedicada para el reloj.

---

## 🚀 Pendientes que requieren intervención manual / credenciales externas

1. **Configuración de Notificaciones en iOS (APNs):**
   * Vincular certificados APNs de Apple Developer Portal en Firebase Console para notificaciones en dispositivos iPhone.
2. **Registro de secretos en Supabase Console (Producción):**
   * Registrar `FIREBASE_SERVICE_ACCOUNT` en el apartado *Edge Functions -> Secrets* de Supabase si se migra a un proyecto de producción.

