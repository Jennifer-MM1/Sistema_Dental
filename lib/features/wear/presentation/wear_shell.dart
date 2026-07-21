import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:sistema_dental/core/wear/wear_link_service.dart';
import 'package:sistema_dental/features/wear/presentation/wear_bootstrap_screen.dart';

class WearShell extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;

  const WearShell({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.fromLTRB(22, 16, 22, 18),
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final contentWidth = math.min(
              math.min(
                constraints.maxWidth * 0.78,
                constraints.maxHeight * 0.72,
              ),
              360.0,
            );
            final contentHeight = math.min(
              constraints.maxHeight * 0.86,
              contentWidth * 1.12,
            );
            final defaultPadding =
                padding == const EdgeInsets.fromLTRB(22, 16, 22, 18);
            final responsivePadding = defaultPadding
                ? EdgeInsets.fromLTRB(
                    (contentWidth * 0.045).clamp(6.0, 20.0),
                    (contentHeight * 0.03).clamp(4.0, 15.0),
                    (contentWidth * 0.045).clamp(6.0, 20.0),
                    (contentHeight * 0.03).clamp(4.0, 15.0),
                  )
                : padding;

            return Center(
              child: SizedBox(
                width: contentWidth,
                height: contentHeight,
                child: Padding(padding: responsivePadding, child: child),
              ),
            );
          },
        ),
      ),
    );
  }
}

class WearTopBar extends StatefulWidget {
  final bool showSettings;

  const WearTopBar({super.key, this.showSettings = true});

  @override
  State<WearTopBar> createState() => _WearTopBarState();
}

class _WearTopBarState extends State<WearTopBar> {
  late DateTime _now;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _now = DateTime.now();
    _timer = Timer.periodic(const Duration(seconds: 20), (_) {
      if (mounted) setState(() => _now = DateTime.now());
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final time =
        '${_now.hour.toString().padLeft(2, '0')}:${_now.minute.toString().padLeft(2, '0')}';
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          time,
          style: const TextStyle(
            color: Color(0xFF78F2C0),
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
        if (widget.showSettings)
          InkWell(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const WearSettingsScreen()),
            ),
            borderRadius: BorderRadius.circular(12),
            child: const Padding(
              padding: EdgeInsets.all(2),
              child: Icon(
                Icons.settings_outlined,
                color: Color(0xFF78F2C0),
                size: 18,
              ),
            ),
          )
        else
          const Padding(
            padding: EdgeInsets.all(2),
            child: Icon(Icons.check_circle, color: Color(0xFF78F2C0), size: 18),
          ),
      ],
    );
  }
}

class WearSettingsScreen extends StatefulWidget {
  const WearSettingsScreen({super.key});

  @override
  State<WearSettingsScreen> createState() => _WearSettingsScreenState();
}

class _WearSettingsScreenState extends State<WearSettingsScreen> {
  String? _message;
  bool _syncing = false;

  Future<void> _syncNow(BuildContext context) async {
    setState(() {
      _syncing = true;
      _message = null;
    });

    final data = await WearLinkService.instance.readCompanionState();
    if (!context.mounted) return;

    if (data == null || !data.isLinked) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const WearBootstrapScreen()),
        (_) => false,
      );
      return;
    }

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
            width: 170,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const WearTopBar(showSettings: false),
                const SizedBox(height: 10),
                const WearTitle('Ajustes'),
                const SizedBox(height: 14),
                _SettingsRow(
                  icon: Icons.sync,
                  title: 'Reloj vinculado',
                  subtitle: 'DentalSync',
                ),
                const SizedBox(height: 8),
                _SettingsRow(
                  icon: Icons.notifications_active_outlined,
                  title: 'Alertas',
                  subtitle: 'Activas',
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 32,
                  child: FilledButton(
                    onPressed: _syncing ? null : () => _syncNow(context),
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF087956),
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.zero,
                    ),
                    child: Text(_syncing ? 'Actualizando...' : 'Sincronizar'),
                  ),
                ),
                if (_message != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    _message!,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF8B969E),
                      fontSize: 9,
                    ),
                  ),
                ],
                const SizedBox(height: 6),
                SizedBox(
                  width: double.infinity,
                  height: 28,
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFF78F2C0),
                      padding: EdgeInsets.zero,
                    ),
                    child: const Text('Cerrar'),
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

class _SettingsRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _SettingsRow({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFF78F2C0), size: 18),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Color(0xFF7C858E), fontSize: 9),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class WearTitle extends StatelessWidget {
  final String text;

  const WearTitle(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      textAlign: TextAlign.center,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: const TextStyle(
        color: Color(0xFFBFC7CE),
        fontSize: 10,
        fontWeight: FontWeight.w700,
        letterSpacing: 2,
      ),
    );
  }
}
