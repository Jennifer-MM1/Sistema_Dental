
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:sistema_dental/core/wear/wear_link_service.dart';
import 'package:sistema_dental/features/wear/data/wear_data_service.dart';
import 'package:sistema_dental/features/wear/presentation/wear_doctor_screen.dart';
import 'package:sistema_dental/features/wear/presentation/wear_linked_empty_screen.dart';
import 'package:sistema_dental/features/wear/presentation/wear_doctor_empty_screen.dart';
import 'package:sistema_dental/features/wear/presentation/wear_link_waiting_screen.dart';
import 'package:sistema_dental/features/wear/presentation/wear_wait_screen.dart';
import 'package:sistema_dental/features/wear/presentation/wear_alert_screen.dart';


/// Preview del Wear OS en navegador web. Solo disponible con [kIsWeb].
/// Muestra las vistas del reloj con datos reales de Supabase dentro de un
/// marco circular que simula la pantalla redonda de un Wear OS.
class WearWebPreviewScreen extends StatefulWidget {
  final String? role;

  const WearWebPreviewScreen({super.key, this.role});

  @override
  State<WearWebPreviewScreen> createState() => _WearWebPreviewScreenState();
}

class _WearWebPreviewScreenState extends State<WearWebPreviewScreen> {
  late Future<WearStartupData?> _dataFuture;
  String? _lastReminderShownCode;

  @override
  void initState() {
    super.initState();
    _dataFuture = _loadRealDataAndCheckReminder();
  }

  Future<WearStartupData?> _loadRealDataAndCheckReminder() async {
    final result = await _loadRealData();
    if (result != null) {
      WearLinkService.instance.setStartupData(result);
    }
    if (result?.patient != null) {
      final p = result!.patient!;
      if (p.hasReminder && p.queueCode != _lastReminderShownCode) {
        _lastReminderShownCode = p.queueCode;
        if (mounted) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => WearAlertScreen(
                  data: p,
                  isDemo: false,
                  title: '¡RECORDATORIO!',
                  buttonText: '¡PREPÁRATE!',
                ),
              ),
            );
          });
        }
      }
    }
    return result;
  }

  Future<WearStartupData?> _loadRealData() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return null;
      return await WearLinkService.instance
          .buildStartupDataForWeb(roleLabel: widget.role ?? 'client');
    } catch (e) {
      debugPrint('[WearWebPreview] Error cargando datos: $e');
      return null;
    }
  }

  void _refresh() {
    setState(() {
      _dataFuture = _loadRealDataAndCheckReminder();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1117),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D1117),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white70),
          onPressed: () => context.go('/mode_selector'),
        ),
        title: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.watch_rounded, color: Color(0xFF78F2C0), size: 22),
            SizedBox(width: 10),
            Text(
              'Vista Previa — Wear OS',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.white70),
            tooltip: 'Recargar datos',
            onPressed: _refresh,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: FutureBuilder<WearStartupData?>(
        future: _dataFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(color: Color(0xFF78F2C0)),
                  SizedBox(height: 16),
                  Text(
                    'Cargando datos del reloj...',
                    style: TextStyle(color: Colors.white60, fontSize: 14),
                  ),
                ],
              ),
            );
          }

          final data = snapshot.data;
          final watchWidget = _buildWatchWidget(data);

          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Label de estado
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: data != null
                        ? const Color(0xFF78F2C0).withValues(alpha: 0.15)
                        : Colors.red.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: data != null
                          ? const Color(0xFF78F2C0).withValues(alpha: 0.4)
                          : Colors.red.withValues(alpha: 0.4),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        data != null
                            ? Icons.circle
                            : Icons.error_outline_rounded,
                        color: data != null
                            ? const Color(0xFF78F2C0)
                            : Colors.redAccent,
                        size: 10,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        data != null
                            ? _statusLabel(data)
                            : 'Sin sesión — no se pueden cargar datos',
                        style: TextStyle(
                          color: data != null
                              ? const Color(0xFF78F2C0)
                              : Colors.redAccent,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                // Marco circular del reloj
                _WearOsFrame(child: watchWidget),
                const SizedBox(height: 28),
                // Hint
                const Text(
                  'Esta vista utiliza tus datos reales de Supabase.\nSolo aparece en navegador web.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white30, fontSize: 12),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildWatchWidget(WearStartupData? data) {
    if (data == null || !data.isLinked) {
      return const WearLinkWaitingScreen();
    }

    return Navigator(
      onGenerateRoute: (settings) {
        Widget page;
        if (data.role == WearRole.dentist) {
          if (data.doctor == null) {
            page = WearDoctorEmptyScreen(summary: data.summary);
          } else {
            page = WearDoctorScreen(data: data.doctor!, isDemo: false);
          }
        } else if (data.role == WearRole.secretary) {
          if (data.secretary == null) {
            page = WearDoctorEmptyScreen(summary: data.summary);
          } else {
            page = WearDoctorScreen(
              data: data.secretary!,
              isDemo: false,
              secretaryMode: true,
            );
          }
        } else {
          if (data.patient != null) {
            page = WearWaitScreen(data: data.patient!, isDemo: false);
          } else {
            page = WearLinkedEmptyScreen(summary: data.summary);
          }
        }
        return MaterialPageRoute(builder: (_) => page);
      },
    );
  }

  String _statusLabel(WearStartupData data) {
    if (!data.isLinked) return 'Sin vincular';
    switch (data.role) {
      case WearRole.dentist:
        return data.doctor != null
            ? 'Dentista — turno activo'
            : 'Dentista — sin turno activo';
      case WearRole.secretary:
        return data.secretary != null
            ? 'Secretaria — vista de cola'
            : 'Secretaria — sin pacientes en espera';
      default:
        return (data.patient != null || (data.summary?.hasAppointments ?? false))
            ? 'Cliente — Citas sincronizadas'
            : 'Cliente — Sin citas activas';
    }
  }
}

/// Marco circular que simula la pantalla redonda de un Wear OS.
class _WearOsFrame extends StatelessWidget {
  final Widget child;

  const _WearOsFrame({required this.child});

  @override
  Widget build(BuildContext context) {
    const double watchSize = 300;
    const double bezelSize = 20;
    const double innerSize = watchSize - bezelSize * 2;

    return Container(
      width: watchSize,
      height: watchSize,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF2A2A2A), Color(0xFF111111)],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.6),
            blurRadius: 30,
            spreadRadius: 5,
          ),
          BoxShadow(
            color: const Color(0xFF78F2C0).withValues(alpha: 0.08),
            blurRadius: 40,
            spreadRadius: 10,
          ),
        ],
        border: Border.all(
          color: const Color(0xFF3A3A3A),
          width: 2,
        ),
      ),
      child: Center(
        child: ClipOval(
          child: SizedBox(
            width: innerSize,
            height: innerSize,
            child: child,
          ),
        ),
      ),
    );
  }
}
