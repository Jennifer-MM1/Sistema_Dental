import 'package:flutter/material.dart';
import 'package:sistema_dental/features/wear/presentation/wear_doctor_screen.dart';
import 'package:sistema_dental/features/wear/presentation/wear_shell.dart';
import 'package:sistema_dental/features/wear/presentation/wear_wait_screen.dart';

class WearModeScreen extends StatelessWidget {
  const WearModeScreen({super.key});

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
                const WearTopBar(),
                const SizedBox(height: 8),
                const WearTitle('DentalSync Watch'),
                const SizedBox(height: 16),
                _ModeButton(
                  icon: Icons.person_outline,
                  label: 'Paciente',
                  color: const Color(0xFF008ED1),
                  onTap: () =>
                      Navigator.pushNamed(context, WearWaitScreen.routeName),
                ),
                const SizedBox(height: 10),
                _ModeButton(
                  icon: Icons.medical_services_outlined,
                  label: 'Dentista',
                  color: const Color(0xFF087956),
                  onTap: () =>
                      Navigator.pushNamed(context, WearDoctorScreen.routeName),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ModeButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ModeButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 42,
      child: FilledButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 18),
        label: Text(label, style: const TextStyle(fontWeight: FontWeight.w800)),
        style: FilledButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}
