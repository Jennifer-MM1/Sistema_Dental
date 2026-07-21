import 'package:flutter/material.dart';
import 'package:sistema_dental/features/wear/data/wear_data_service.dart';
import 'package:sistema_dental/features/wear/presentation/wear_shell.dart';

class WearAlertScreen extends StatelessWidget {
  static const routeName = '/alert';

  final WearPatientQueueData data;
  final bool isDemo;

  const WearAlertScreen({
    super.key,
    this.data = WearPatientQueueData.demo,
    this.isDemo = true,
  });

  @override
  Widget build(BuildContext context) {
    return WearShell(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 190;
          final designWidth = compact ? 155.0 : 185.0;
          final iconSize = compact ? 48.0 : 58.0;

          return Center(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: SizedBox(
                width: designWidth,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const WearTopBar(),
                    SizedBox(height: compact ? 3 : 5),
                    const WearTitle('Estado de espera'),
                    SizedBox(height: compact ? 12 : 18),
                    Container(
                      width: iconSize,
                      height: iconSize,
                      decoration: BoxDecoration(
                        color: const Color(0xFF78F2C0),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.notifications_active,
                        color: const Color(0xFF087956),
                        size: compact ? 29 : 35,
                      ),
                    ),
                    SizedBox(height: compact ? 11 : 15),
                    Text(
                      '¡Es tu turno!',
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: const Color(0xFF78F2C0),
                        fontSize: compact ? 20 : 24,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(height: compact ? 3 : 5),
                    Text(
                      data.patientName,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: compact ? 11 : 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: compact ? 6 : 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF078256),
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: Text(
                        data.roomName,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: compact ? 11 : 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    SizedBox(height: compact ? 10 : 16),
                    SizedBox(
                      width: designWidth,
                      height: compact ? 31 : 39,
                      child: FilledButton(
                        onPressed: () => Navigator.popUntil(
                          context,
                          (route) => route.isFirst,
                        ),
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF087956),
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.zero,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: Text(
                          'CONFIRMAR',
                          style: TextStyle(
                            fontSize: compact ? 11 : 14,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.3,
                          ),
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
