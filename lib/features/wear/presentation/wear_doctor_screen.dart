import 'package:flutter/material.dart';
import 'package:sistema_dental/core/wear/wear_link_service.dart';
import 'package:sistema_dental/features/wear/data/wear_data_service.dart';
import 'package:sistema_dental/features/wear/presentation/wear_alert_screen.dart';
import 'package:sistema_dental/features/wear/presentation/wear_shell.dart';

class WearDoctorScreen extends StatefulWidget {
  static const routeName = '/doctor';

  final WearDoctorQueueData data;
  final bool isDemo;
  final bool secretaryMode;

  const WearDoctorScreen({
    super.key,
    this.data = WearDoctorQueueData.demo,
    this.isDemo = true,
    this.secretaryMode = false,
  });

  @override
  State<WearDoctorScreen> createState() => _WearDoctorScreenState();
}

class _WearDoctorScreenState extends State<WearDoctorScreen> {
  late int _queueAhead;
  bool _saving = false;
  bool _showWeekly = false;

  @override
  void initState() {
    super.initState();
    _queueAhead = widget.data.queueCount;
  }

  @override
  void didUpdateWidget(covariant WearDoctorScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.data.appointmentId != widget.data.appointmentId ||
        oldWidget.data.status != widget.data.status ||
        oldWidget.data.queueCount != widget.data.queueCount) {
      _queueAhead = widget.data.queueCount;
    }
  }

  Future<void> _callNext() async {
    final success = await _sendAction('call_patient');
    if (!success || !mounted) return;
    setState(() {
      _queueAhead = (_queueAhead - 1).clamp(0, 99);
    });
    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            WearAlertScreen(data: _patientData, isDemo: widget.isDemo),
      ),
    );
  }


  Future<bool> _sendAction(String action) async {
    if (widget.data.appointmentId.isEmpty) return false;
    setState(() => _saving = true);
    try {
      final sent = await WearLinkService.instance.sendActionToPhone(
        appointmentId: widget.data.appointmentId,
        action: action,
      );
      if (!sent && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Abre DentalSync en el teléfono.')),
        );
      }
      return sent;
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  WearPatientQueueData get _patientData => WearPatientQueueData(
    patientName: widget.data.patientName,
    queueCode: widget.data.queueCode,
    peopleAhead: 0,
    estimatedMinutes: widget.data.estimatedMinutes,
    doctorName: 'Dentista',
    serviceName: 'Consulta',
    roomName: 'Consultorio',
    status: 'in_treatment',
  );

  @override
  Widget build(BuildContext context) {
    return WearShell(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 190;
          final designWidth = compact ? 158.0 : 190.0;

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

                    // TOGGLE DE HOY vs SEMANA
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        InkWell(
                          onTap: () => setState(() => _showWeekly = false),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: !_showWeekly
                                  ? const Color(0xFF78F2C0)
                                  : const Color(0xFF1C2D35),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              'HOY',
                              style: TextStyle(
                                color: !_showWeekly
                                    ? const Color(0xFF044830)
                                    : Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        InkWell(
                          onTap: () => setState(() => _showWeekly = true),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: _showWeekly
                                  ? const Color(0xFF78F2C0)
                                  : const Color(0xFF1C2D35),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              'SEMANA',
                              style: TextStyle(
                                color: _showWeekly
                                    ? const Color(0xFF044830)
                                    : Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: compact ? 6 : 8),

                    if (!_showWeekly) ...[
                      // 🟢 VISTA DE CITAS DE HOY
                      Container(
                        width: designWidth,
                        padding: EdgeInsets.all(compact ? 10 : 13),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0A0F12),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: const Color(0xFF1C2D35),
                            width: 1,
                          ),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              children: [
                                _Metric(
                                  value: '$_queueAhead',
                                  label: 'En cola',
                                  color: const Color(0xFF008ED1),
                                ),
                                const SizedBox(width: 8),
                                _Metric(
                                  value: '${widget.data.estimatedMinutes}',
                                  label: 'Min',
                                  color: const Color(0xFF78F2C0),
                                ),
                              ],
                            ),
                            const Divider(color: Color(0xFF1C2D35), height: 16),
                            Row(
                              children: [
                                Container(
                                  width: compact ? 30 : 36,
                                  height: compact ? 30 : 36,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF12394B),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Icon(
                                    Icons.person,
                                    color: Color(0xFFBFE4F7),
                                    size: 18,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        widget.data.queueCode,
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: compact ? 18 : 22,
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ),
                                      Text(
                                        widget.data.patientName,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          color: const Color(0xFFBFE4F7),
                                          fontSize: compact ? 11 : 13,
                                          fontWeight: FontWeight.w700,
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
                      SizedBox(height: compact ? 8 : 10),

                      SizedBox(
                        width: designWidth,
                        height: compact ? 34 : 40,
                        child: FilledButton(
                          onPressed: _saving ? null : _callNext,
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFF78F2C0),
                            foregroundColor: const Color(0xFF044830),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: Text(
                            widget.secretaryMode
                                ? 'PASAR A CONSULTORIO'
                                : 'LLAMAR PACIENTE',
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ),
                    ] else ...[
                      // 🟢 VISTA DE CITAS DE LA SEMANA
                      Container(
                        width: designWidth,
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0A0F12),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: const Color(0xFF1C2D35)),
                        ),
                        child: const Column(
                          children: [
                            Text(
                              'CITAS DE LA SEMANA',
                              style: TextStyle(
                                color: Color(0xFF78F2C0),
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            SizedBox(height: 6),
                            _WeeklyAppointmentTile(
                              day: 'Hoy 10:30 AM',
                              patient: 'María García',
                              service: 'Limpieza Dental',
                            ),
                            SizedBox(height: 4),
                            _WeeklyAppointmentTile(
                              day: 'Mañana 04:00 PM',
                              patient: 'Carlos López',
                              service: 'Evaluación General',
                            ),
                            SizedBox(height: 4),
                            _WeeklyAppointmentTile(
                              day: 'Jue 11:15 AM',
                              patient: 'Ana Martínez',
                              service: 'Ortodoncia',
                            ),
                          ],
                        ),
                      ),
                    ],
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

class _WeeklyAppointmentTile extends StatelessWidget {
  final String day;
  final String patient;
  final String service;

  const _WeeklyAppointmentTile({
    required this.day,
    required this.patient,
    required this.service,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF121B21),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  patient,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '$day • $service',
                  style: const TextStyle(color: Colors.grey, fontSize: 8),
                ),
              ],
            ),
          ),
          const Icon(Icons.calendar_today, size: 12, color: Color(0xFF78F2C0)),
        ],
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  final String value;
  final String label;
  final Color color;

  const _Metric({
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Row(
        children: [
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(color: Colors.grey, fontSize: 10),
          ),
        ],
      ),
    );
  }
}
