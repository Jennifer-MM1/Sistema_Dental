import 'package:flutter/material.dart';
import 'package:sistema_dental/features/wear/data/wear_data_service.dart';
import 'package:sistema_dental/features/wear/presentation/wear_alert_screen.dart';
import 'package:sistema_dental/features/wear/presentation/wear_shell.dart';

class WearDoctorScreen extends StatefulWidget {
  static const routeName = '/doctor';

  final WearDoctorQueueData data;
  final bool isDemo;

  const WearDoctorScreen({
    super.key,
    this.data = WearDoctorQueueData.demo,
    this.isDemo = true,
  });

  @override
  State<WearDoctorScreen> createState() => _WearDoctorScreenState();
}

class _WearDoctorScreenState extends State<WearDoctorScreen> {
  late int _queueAhead;
  late String _status;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _queueAhead = widget.data.queueCount;
    _status = widget.data.statusLabel;
  }

  Future<void> _callNext() async {
    await _updateStatus('in_treatment');
    setState(() {
      _queueAhead = (_queueAhead - 1).clamp(0, 99);
      _status = 'Turno llamado';
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

  Future<void> _complete() async {
    await _updateStatus('completed');
    if (!mounted) return;
    setState(() {
      _status = 'Atendido';
    });
  }

  Future<void> _updateStatus(String status) async {
    if (widget.data.appointmentId.isEmpty) return;
    setState(() => _saving = true);
    try {
      await Future<void>.delayed(const Duration(milliseconds: 250));
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
                    SizedBox(height: compact ? 3 : 5),
                    const WearTitle('Modo dentista'),
                    SizedBox(height: compact ? 8 : 12),
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
                                  crossAxisAlignment: CrossAxisAlignment.start,
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
                                        color: Colors.white,
                                        fontSize: compact ? 9 : 10,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    Text(
                                      _saving ? 'Sincronizando...' : _status,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: const Color(0xFF78F2C0),
                                        fontSize: compact ? 9 : 10,
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
                    SizedBox(height: compact ? 8 : 12),
                    Row(
                      children: [
                        Expanded(
                          child: _ActionButton(
                            label: 'Llamar',
                            color: const Color(0xFF087956),
                            onTap: _saving ? null : _callNext,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _ActionButton(
                            label: 'OK',
                            color: const Color(0xFF006D9F),
                            onTap: _saving ? null : _complete,
                          ),
                        ),
                      ],
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
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: 22,
                fontWeight: FontWeight.w900,
                height: 1,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: color, fontSize: 8),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback? onTap;

  const _ActionButton({
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 32,
      child: FilledButton(
        onPressed: onTap,
        style: FilledButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          padding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
        ),
        child: Text(
          label,
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800),
        ),
      ),
    );
  }
}
