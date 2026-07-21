import 'package:flutter/material.dart';
import 'package:sistema_dental/features/wear/data/wear_data_service.dart';
import 'package:sistema_dental/features/wear/presentation/wear_shell.dart';
import 'package:sistema_dental/features/wear/presentation/wear_turn_screen.dart';

class WearWaitScreen extends StatelessWidget {
  static const routeName = '/patient';

  final WearPatientQueueData data;
  final bool isDemo;

  const WearWaitScreen({
    super.key,
    this.data = WearPatientQueueData.demo,
    this.isDemo = true,
  });

  @override
  Widget build(BuildContext context) {
    return WearShell(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final shortSide = constraints.maxWidth < constraints.maxHeight
              ? constraints.maxWidth
              : constraints.maxHeight;
          final compact = shortSide < 210;
          final designWidth = compact ? 150.0 : 190.0;
          final circleSize = compact ? 58.0 : 84.0;
          final buttonHeight = compact ? 25.0 : 36.0;

          return Center(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.center,
              child: SizedBox(
                width: designWidth,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const WearTopBar(),
                    SizedBox(height: compact ? 3 : 5),
                    const WearTitle('Estado de espera'),
                    SizedBox(height: compact ? 7 : 10),
                    Container(
                      width: circleSize,
                      height: circleSize,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color(0xFF008ED1),
                          width: compact ? 5 : 7,
                        ),
                      ),
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '${data.peopleAhead}',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: compact ? 20 : 25,
                                fontWeight: FontWeight.w800,
                                height: 1,
                              ),
                            ),
                            Text(
                              'EN COLA',
                              style: TextStyle(
                                color: const Color(0xFF9AA4AD),
                                fontSize: compact ? 6.5 : 8,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: compact ? 7 : 10),
                    Text(
                      data.patientName,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: compact ? 11.5 : 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: compact ? 1 : 3),
                    Text(
                      '${data.peopleAhead} personas antes de ti',
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: compact ? 9.5 : 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: compact ? 1 : 3),
                    Text(
                      'Tiempo est.: ${data.estimatedMinutes} min',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: const Color(0xFF7C858E),
                        fontSize: compact ? 8.5 : 11,
                      ),
                    ),
                    SizedBox(height: compact ? 6 : 14),
                    SizedBox(
                      width: designWidth,
                      height: buttonHeight,
                      child: FilledButton(
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                WearTurnScreen(data: data, isDemo: isDemo),
                          ),
                        ),
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFFE9E7E5),
                          foregroundColor: const Color(0xFF242424),
                          padding: EdgeInsets.zero,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text(
                          'Ver Detalles',
                          style: TextStyle(fontSize: compact ? 10 : 13),
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
