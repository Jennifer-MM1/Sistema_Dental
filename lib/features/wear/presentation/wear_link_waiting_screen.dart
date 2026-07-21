import 'package:flutter/material.dart';
import 'package:sistema_dental/core/wear/wear_link_service.dart';
import 'package:sistema_dental/features/wear/presentation/wear_bootstrap_screen.dart';
import 'package:sistema_dental/features/wear/presentation/wear_shell.dart';

class WearLinkWaitingScreen extends StatefulWidget {
  const WearLinkWaitingScreen({super.key});

  @override
  State<WearLinkWaitingScreen> createState() => _WearLinkWaitingScreenState();
}

class _WearLinkWaitingScreenState extends State<WearLinkWaitingScreen> {
  bool _syncing = false;
  String _message = 'Abre DentalSync en tu telefono y vincula este reloj.';

  Future<void> _retrySync() async {
    if (_syncing) return;

    setState(() {
      _syncing = true;
      _message = 'Buscando vinculacion...';
    });

    final data = await WearLinkService.instance.readCompanionState();

    if (!mounted) return;

    if (data != null && data.isLinked) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const WearBootstrapScreen()),
        (_) => false,
      );
      return;
    }

    setState(() {
      _syncing = false;
      _message = 'Todavia no se recibio la vinculacion.';
    });
  }

  @override
  Widget build(BuildContext context) {
    return WearShell(
      child: Center(
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: SizedBox(
            width: 185,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const WearTopBar(),
                const SizedBox(height: 8),
                const WearTitle('Vinculacion'),
                const SizedBox(height: 18),
                Container(
                  width: 58,
                  height: 58,
                  decoration: BoxDecoration(
                    color: const Color(0xFF0A0F12),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFF1C2D35)),
                  ),
                  child: _syncing
                      ? const Padding(
                          padding: EdgeInsets.all(16),
                          child: CircularProgressIndicator(
                            strokeWidth: 3,
                            color: Color(0xFF78F2C0),
                          ),
                        )
                      : const Icon(
                          Icons.watch_outlined,
                          color: Color(0xFF78F2C0),
                          size: 32,
                        ),
                ),
                const SizedBox(height: 14),
                const Text(
                  'Esperando reloj',
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _message,
                  textAlign: TextAlign.center,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF8B969E),
                    fontSize: 10,
                    height: 1.25,
                  ),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  height: 34,
                  child: FilledButton(
                    onPressed: _syncing ? null : _retrySync,
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF087956),
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: Text(_syncing ? 'Sincronizando' : 'Reintentar'),
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
