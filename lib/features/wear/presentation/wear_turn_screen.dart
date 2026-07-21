import 'package:flutter/material.dart';
import 'package:sistema_dental/features/wear/data/wear_data_service.dart';
import 'package:sistema_dental/features/wear/presentation/wear_alert_screen.dart';
import 'package:sistema_dental/features/wear/presentation/wear_shell.dart';

class WearTurnScreen extends StatelessWidget {
  static const routeName = '/turn';

  final WearPatientQueueData data;
  final bool isDemo;

  const WearTurnScreen({
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
          final designWidth = compact ? 158.0 : 190.0;
          final cardPadding = compact ? 10.0 : 13.0;

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
                    SizedBox(height: compact ? 8 : 12),
                    Container(
                      width: designWidth,
                      padding: EdgeInsets.all(cardPadding),
                      decoration: BoxDecoration(
                        color: const Color(0xFF006D9F),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'QUEUE',
                                style: TextStyle(
                                  color: Color(0xFFBFE4F7),
                                  fontSize: 7,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 1,
                                ),
                              ),
                              Text(
                                '${data.estimatedMinutes} MIN',
                                style: const TextStyle(
                                  color: Color(0xFFBFE4F7),
                                  fontSize: 7,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 1,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: compact ? 2 : 4),
                          Row(
                            children: [
                              Expanded(
                                child: FittedBox(
                                  alignment: Alignment.centerLeft,
                                  fit: BoxFit.scaleDown,
                                  child: Text(
                                    data.queueCode,
                                    style: TextStyle(
                                      color: const Color(0xFFDDEFF7),
                                      fontSize: compact ? 42 : 52,
                                      height: 0.95,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFFC400),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Text(
                                  _statusLabel,
                                  style: const TextStyle(
                                    color: Colors.black,
                                    fontSize: 7,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const Divider(color: Color(0xFF2A8AB5), height: 14),
                          Row(
                            children: [
                              Container(
                                width: compact ? 31 : 38,
                                height: compact ? 31 : 38,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF137AAE),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(
                                  Icons.medical_services_outlined,
                                  color: Colors.white,
                                  size: compact ? 16 : 19,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      data.doctorName,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: compact ? 10 : 12,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                    Text(
                                      '${data.patientName} - ${data.serviceName}',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: const Color(0xFFBFE4F7),
                                        fontSize: compact ? 8 : 9,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: compact ? 6 : 10),
                    SizedBox(
                      width: designWidth,
                      height: compact ? 26 : 32,
                      child: TextButton(
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                WearAlertScreen(data: data, isDemo: isDemo),
                          ),
                        ),
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          foregroundColor: const Color(0xFF78F2C0),
                        ),
                        child: Text(
                          'Simular alerta',
                          style: TextStyle(fontSize: compact ? 10 : 11),
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

  String get _statusLabel {
    switch (data.status) {
      case 'in_treatment':
        return 'TU TURNO';
      case 'in_lobby':
        return 'EN SALA';
      default:
        return 'EN COLA';
    }
  }
}
