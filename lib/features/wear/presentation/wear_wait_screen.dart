import 'package:flutter/material.dart';
import 'package:sistema_dental/features/wear/data/wear_data_service.dart';
import 'package:sistema_dental/features/wear/presentation/wear_turn_screen.dart';
import 'package:sistema_dental/features/wear/presentation/wear_shell.dart';
import 'package:sistema_dental/core/wear/wear_link_service.dart';
import 'package:sistema_dental/features/wear/presentation/wear_linked_empty_screen.dart';

class WearWaitScreen extends StatefulWidget {
  static const routeName = '/patient';

  final WearPatientQueueData data;
  final bool isDemo;

  const WearWaitScreen({
    super.key,
    this.data = WearPatientQueueData.demo,
    this.isDemo = true,
  });

  @override
  State<WearWaitScreen> createState() => _WearWaitScreenState();
}

class _WearWaitScreenState extends State<WearWaitScreen> {
  int _selectedFamilyIndex = 0;

  // Citas familiares (Titular + Dependientes)
  late final List<WearPatientQueueData> _familyAppointments;

  @override
  void initState() {
    super.initState();
    if (widget.isDemo) {
      _familyAppointments = [
        widget.data, // Cita principal / Titular
        const WearPatientQueueData(
          patientName: 'Sofía (Hija)',
          queueCode: 'C-05',
          peopleAhead: 2,
          estimatedMinutes: 25,
          doctorName: 'Dra. Mendoza',
          serviceName: 'Odontopediatría',
          roomName: 'Consultorio 3',
          status: 'upcoming',
          dateTimeLabel: 'Hoy • 11:30 AM',
        ),
      ];
    } else {
      _familyAppointments = [widget.data];
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentData = _familyAppointments[_selectedFamilyIndex];

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

                    // NOMBRE DEL PACIENTE / FAMILIAR
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (_familyAppointments.length > 1)
                          InkWell(
                            onTap: () {
                              setState(() {
                                _selectedFamilyIndex =
                                    (_selectedFamilyIndex + 1) %
                                    _familyAppointments.length;
                              });
                            },
                            child: const Icon(
                              Icons.arrow_left,
                              color: Color(0xFF78F2C0),
                              size: 18,
                            ),
                          ),
                        Flexible(
                          child: Text(
                            currentData.patientName.toUpperCase(),
                            style: const TextStyle(
                              color: Color(0xFF78F2C0),
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.5,
                            ),
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                          ),
                        ),
                        if (_familyAppointments.length > 1)
                          InkWell(
                            onTap: () {
                              setState(() {
                                _selectedFamilyIndex =
                                    (_selectedFamilyIndex + 1) %
                                    _familyAppointments.length;
                              });
                            },
                            child: const Icon(
                              Icons.arrow_right,
                              color: Color(0xFF78F2C0),
                              size: 18,
                            ),
                          ),
                      ],
                    ),
                    SizedBox(height: compact ? 4 : 6),

                    // CÍRCULO CON NÚMERO DE PERSONAS EN ESPERA
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
                          child: Text(
                            '${currentData.peopleAhead}',
                            style: TextStyle(
                              fontSize: compact ? 22 : 32,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              height: 1.0,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'EN ESPERA',
                        style: TextStyle(
                          fontSize: compact ? 7 : 9,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFFBFE4F7),
                          letterSpacing: 0.8,
                        ),
                      ),
                    SizedBox(height: compact ? 6 : 10),

                    // DETALLES DE LA CITA
                    Text(
                      '${currentData.doctorName} • ${currentData.serviceName}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Turno ${currentData.queueCode} • ~${currentData.estimatedMinutes} min',
                      style: const TextStyle(
                        color: Color(0xFF9E9E9E),
                        fontSize: 9,
                      ),
                    ),
                    SizedBox(height: compact ? 8 : 12),

                    SizedBox(
                      width: designWidth,
                      height: buttonHeight,
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => WearTurnScreen(
                                data: currentData,
                                isDemo: widget.isDemo,
                              ),
                            ),
                          );
                        },
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0xFF008ED1)),
                          foregroundColor: const Color(0xFF008ED1),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'VER FICHA COMPLETA',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 2),
                    // Botón para ir a la vista resumen
                    InkWell(
                      onTap: () async {
                        final data =
                            await WearLinkService.instance.readCompanionState();
                        if (!context.mounted) return;
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                WearLinkedEmptyScreen(summary: data?.summary),
                          ),
                        );
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 4),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Text(
                              'Ver resumen',
                              style: TextStyle(
                                  color: Color(0xFF78F2C0), fontSize: 10),
                            ),
                            SizedBox(width: 4),
                            Icon(Icons.arrow_forward_ios,
                                color: Color(0xFF78F2C0), size: 10),
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
