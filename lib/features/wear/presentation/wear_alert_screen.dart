import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sistema_dental/features/wear/data/wear_data_service.dart';
import 'package:sistema_dental/features/wear/presentation/wear_shell.dart';

class WearAlertScreen extends StatefulWidget {
  static const routeName = '/alert';

  final WearPatientQueueData data;
  final bool isDemo;
  final String title;
  final String buttonText;

  const WearAlertScreen({
    super.key,
    this.data = WearPatientQueueData.demo,
    this.isDemo = true,
    this.title = 'LLAMADA A CONSULTORIO',
    this.buttonText = '¡ES TU TURNO!',
  });

  @override
  State<WearAlertScreen> createState() => _WearAlertScreenState();
}

class _WearAlertScreenState extends State<WearAlertScreen> {
  bool _isConfirmed = false;

  void _onTurnConfirmed() async {
    // 1. Respuesta Háptica Táctil Sobredimensionada (Vibración física en reloj)
    try {
      await HapticFeedback.heavyImpact();
      await Future.delayed(const Duration(milliseconds: 100));
      await HapticFeedback.vibrate();
    } catch (_) {}

    if (!mounted) return;
    setState(() => _isConfirmed = true);

    // 2. Regresar después de mostrar el estado de "En camino"
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        Navigator.popUntil(context, (route) => route.isFirst);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return WearShell(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 190;
          final designWidth = compact ? 160.0 : 190.0;

          if (_isConfirmed) {
            return Center(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: SizedBox(
                  width: designWidth,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const WearTopBar(showSettings: false),
                      const SizedBox(height: 12),
                      Container(
                        width: compact ? 56 : 68,
                        height: compact ? 56 : 68,
                        decoration: const BoxDecoration(
                          color: Color(0xFF78F2C0),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.directions_run_rounded,
                          color: Color(0xFF078256),
                          size: 38,
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        '¡EN CAMINO!',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Color(0xFF78F2C0),
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Pasa al ${widget.data.roomName}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }

          return Center(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: SizedBox(
                width: designWidth,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const WearTopBar(),
                    SizedBox(height: compact ? 2 : 4),
                    WearTitle(widget.title),
                    SizedBox(height: compact ? 8 : 12),

                    // Badge de Sala / Consultorio
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF078256),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        widget.data.roomName.toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                    SizedBox(height: compact ? 10 : 14),

                    // 🟢 BOTÓN SOBREDIMENSIONADO "¡ES TU TURNO!"
                    SizedBox(
                      width: designWidth,
                      height: compact ? 62 : 74,
                      child: FilledButton(
                        onPressed: _onTurnConfirmed,
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF78F2C0),
                          foregroundColor: const Color(0xFF044830),
                          elevation: 6,
                          shadowColor: const Color(0xFF78F2C0).withAlpha(120),
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(22),
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.notifications_active_rounded,
                                  size: 20,
                                  color: Color(0xFF044830),
                                ),
                                const SizedBox(width: 6),
                                Flexible(
                                  child: Text(
                                    widget.buttonText,
                                    style: TextStyle(
                                      fontSize: compact ? 15 : 17,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 0.8,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Toca para confirmar 👆',
                              style: TextStyle(
                                fontSize: compact ? 9 : 10,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF078256),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
