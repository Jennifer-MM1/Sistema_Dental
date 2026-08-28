import 'package:flutter/material.dart';
import 'package:sistema_dental/core/wear/wear_link_service.dart';
import 'package:sistema_dental/features/wear/data/wear_data_service.dart';
import 'package:sistema_dental/features/wear/presentation/wear_bootstrap_screen.dart';
import 'package:sistema_dental/features/wear/presentation/wear_shell.dart';

class WearLinkWaitingScreen extends StatefulWidget {
  const WearLinkWaitingScreen({super.key});

  @override
  State<WearLinkWaitingScreen> createState() => _WearLinkWaitingScreenState();
}

class _WearLinkWaitingScreenState extends State<WearLinkWaitingScreen> {
  bool _isChecking = false;

  Future<void> _handleVincularPress() async {
    setState(() => _isChecking = true);

    final state = await WearLinkService.instance.readCompanionState();
    if (!mounted) return;

    if (state == null || !state.isLinked) {
      if (!mounted) return;
      setState(() => _isChecking = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se pudo establecer la conexión Bluetooth con el teléfono.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    if (!mounted) return;
    setState(() => _isChecking = false);

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const WearBootstrapScreen()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return WearShell(
      child: Center(
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: SizedBox(
            width: 175,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const WearTopBar(showSettings: false),
                const SizedBox(height: 4),

                // 🟢 INTERFAZ DE BIENVENIDA AL RELOJ
                const WearTitle('DentalSync Wear'),
                const SizedBox(height: 8),
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: const Color(0xFF078256).withAlpha(50),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFF78F2C0),
                      width: 1.5,
                    ),
                  ),
                  child: const Icon(
                    Icons.watch_outlined,
                    color: Color(0xFF78F2C0),
                    size: 26,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  '¡Bienvenido!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                const Text(
                  'Reloj no vinculado',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Color(0xFF9E9E9E),
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 12),

                // BOTÓN VINCULAR RELOJ
                SizedBox(
                  width: 140,
                  height: 38,
                  child: FilledButton(
                    onPressed: _isChecking ? null : _handleVincularPress,
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF78F2C0),
                      foregroundColor: const Color(0xFF044830),
                      elevation: 4,
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: _isChecking
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Color(0xFF044830),
                            ),
                          )
                        : const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.link_rounded, size: 16),
                              SizedBox(width: 4),
                              Text(
                                'VINCULAR RELOJ',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0.5,
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
      ),
    );
  }
}
