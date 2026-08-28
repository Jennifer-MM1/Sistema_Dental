import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:sistema_dental/features/wear/data/wear_data_service.dart';
import 'package:sistema_dental/features/wear/presentation/wear_bootstrap_screen.dart';
import 'package:sistema_dental/features/wear/presentation/wear_dependents_list_screen.dart';
import 'package:sistema_dental/features/wear/presentation/wear_shell.dart';
import 'package:sistema_dental/features/wear/presentation/wear_turn_screen.dart';

class WearLinkedEmptyScreen extends StatefulWidget {
  final WearPatientSummaryData? summary;

  const WearLinkedEmptyScreen({super.key, this.summary});

  @override
  State<WearLinkedEmptyScreen> createState() => _WearLinkedEmptyScreenState();
}

class _WearLinkedEmptyScreenState extends State<WearLinkedEmptyScreen> {
  late final ScrollController _scrollController;
  int _currentApptPage = 0;
  late final PageController _pageController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WearShell(
      padding: EdgeInsets.zero,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 190;
          final width = compact ? 162.0 : 196.0;
          final data = widget.summary;
          final patientPreview = data?.patientNames.take(3).join(', ') ?? '';
          final appointments = data?.appointments ?? [];

          return Stack(
            children: [
              // Lista con efecto de escalado dinámico tipo Pixel Watch
              Center(
                child: SizedBox(
                  width: width,
                  child: ListView(
                    controller: _scrollController,
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.only(
                      top: 36,
                      bottom: 48,
                    ),
                    children: [
                      if (Navigator.canPop(context))
                        _ScalingWearCard(
                          scrollController: _scrollController,
                          child: InkWell(
                            onTap: () => Navigator.pop(context),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              alignment: Alignment.center,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: const [
                                  Icon(Icons.arrow_back_ios_new, color: Color(0xFF78F2C0), size: 12),
                                  SizedBox(width: 4),
                                  Text('Volver al turno', style: TextStyle(color: Color(0xFF78F2C0), fontSize: 10, fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ),
                          ),
                        ),
                      if (Navigator.canPop(context))
                        const SizedBox(height: 8),
                      // 1. Cabecera de usuario
                      _ScalingWearCard(
                        scrollController: _scrollController,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF142B36), Color(0xFF0C1920)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFF1A4557)),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: compact ? 34 : 38,
                                height: compact ? 34 : 38,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF1B4E63),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.person,
                                  color: Color(0xFF78F2C0),
                                  size: 21,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      data?.userName ?? 'Cliente',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: compact ? 13 : 15,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                    const Text(
                                      'Cliente',
                                      style: TextStyle(
                                        color: Color(0xFF78F2C0),
                                        fontSize: 10,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),

                      // 2. Métricas destacadas
                      _ScalingWearCard(
                        scrollController: _scrollController,
                        child: Row(
                          children: [
                            Expanded(
                              child: _MiniMetric(
                                value: '${data?.patientNames.length ?? 0}',
                                label: 'Pacientes',
                                color: const Color(0xFF008ED1),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: _MiniMetric(
                                value: '${data?.appointmentCount ?? appointments.length}',
                                label: 'Citas',
                                color: const Color(0xFF78F2C0),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),

                      // 3. Próxima Cita / Carrusel
                      _ScalingWearCard(
                        scrollController: _scrollController,
                        child: appointments.isEmpty
                            ? _InfoPanel(
                                title: 'Sin citas',
                                body: 'No tienes citas programadas hoy.',
                              )
                            : appointments.length == 1
                                ? _AppointmentCard(
                                    appointment: appointments.first,
                                    onTap: () => _openAppointment(appointments.first),
                                    compact: compact,
                                  )
                                : Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      SizedBox(
                                        height: compact ? 64 : 72,
                                        child: PageView.builder(
                                          controller: _pageController,
                                          itemCount: appointments.length,
                                          onPageChanged: (i) =>
                                              setState(() => _currentApptPage = i),
                                          itemBuilder: (context, index) {
                                            return _AppointmentCard(
                                              appointment: appointments[index],
                                              onTap: () => _openAppointment(
                                                  appointments[index]),
                                              compact: compact,
                                              badgeText:
                                                  '${index + 1}/${appointments.length}',
                                            );
                                          },
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: List.generate(
                                          appointments.length,
                                          (idx) => Container(
                                            margin: const EdgeInsets.symmetric(
                                                horizontal: 2),
                                            width: _currentApptPage == idx ? 12 : 4,
                                            height: 3,
                                            decoration: BoxDecoration(
                                              color: _currentApptPage == idx
                                                  ? const Color(0xFF78F2C0)
                                                  : const Color(0xFF334A54),
                                              borderRadius: BorderRadius.circular(2),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                      ),

                      // 4. Botón de Personas a Cargo
                      if (patientPreview.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        _ScalingWearCard(
                          scrollController: _scrollController,
                          child: InkWell(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => WearDependentsListScreen(
                                    dependents: data?.patientNames ?? [],
                                  ),
                                ),
                              );
                            },
                            borderRadius: BorderRadius.circular(14),
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 8),
                              decoration: BoxDecoration(
                                color: const Color(0xFF0A0F12),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: const Color(0xFF1C2D35)),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.people_alt_outlined,
                                    color: Color(0xFF008ED1),
                                    size: 18,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          'A cargo (${data?.patientNames.length ?? 0})',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 11,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                        Text(
                                          patientPreview,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            color: Color(0xFF8B969E),
                                            fontSize: 9,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const Icon(
                                    Icons.chevron_right,
                                    color: Color(0xFF78F2C0),
                                    size: 16,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],

                      if (!kIsWeb) ...[
                        const SizedBox(height: 10),
                        _ScalingWearCard(
                          scrollController: _scrollController,
                          child: SizedBox(
                            width: double.infinity,
                            height: 32,
                            child: FilledButton(
                              onPressed: () {
                                Navigator.pushAndRemoveUntil(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const WearBootstrapScreen(),
                                  ),
                                  (_) => false,
                                );
                              },
                              style: FilledButton.styleFrom(
                                backgroundColor: const Color(0xFF087956),
                                foregroundColor: Colors.white,
                                padding: EdgeInsets.zero,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              child: const Text('Actualizar'),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              // Barra superior flotante con hora
              Positioned(
                top: 6,
                left: 16,
                right: 16,
                child: const WearTopBar(),
              ),
            ],
          );
        },
      ),
    );
  }

  void _openAppointment(WearPatientQueueData appt) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => WearTurnScreen(data: appt, isDemo: false),
      ),
    );
  }
}

/// Widget que escala y da zoom a la tarjeta a medida que se acerca al centro del reloj (Efecto Pixel Watch)
class _ScalingWearCard extends StatelessWidget {
  final ScrollController scrollController;
  final Widget child;

  const _ScalingWearCard({
    required this.scrollController,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: scrollController,
      builder: (context, _) {
        final renderObject = context.findRenderObject();
        if (renderObject is! RenderBox || !renderObject.hasSize) {
          return child;
        }

        final viewport = RenderAbstractViewport.of(renderObject);


        final offsetToCenter = viewport.getOffsetToReveal(renderObject, 0.5).offset;
        final currentOffset = scrollController.hasClients ? scrollController.offset : 0.0;
        final distanceToCenter = (currentOffset - offsetToCenter).abs();

        // En el centro: escala 1.05, opacidad 1.0
        // Hacia los bordes: escala 0.88, opacidad 0.65
        final progress = (1.0 - (distanceToCenter / 130.0)).clamp(0.0, 1.0);
        final scale = 0.88 + (0.17 * progress);
        final opacity = 0.65 + (0.35 * progress);

        return Transform.scale(
          scale: scale,
          alignment: Alignment.center,
          child: Opacity(
            opacity: opacity,
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}

class _AppointmentCard extends StatelessWidget {
  final WearPatientQueueData appointment;
  final VoidCallback onTap;
  final bool compact;
  final String? badgeText;

  const _AppointmentCard({
    required this.appointment,
    required this.onTap,
    required this.compact,
    this.badgeText,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFF0D2533),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFF155C75), width: 1.2),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Próxima cita',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10.5,
                      fontWeight: FontWeight.w900,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 4),
                Flexible(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFF78F2C0).withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'Ticket ${appointment.queueCode}',
                      style: const TextStyle(
                        color: Color(0xFF78F2C0),
                        fontSize: 9.5,
                        fontWeight: FontWeight.w900,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                if (badgeText != null) ...[
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      badgeText!,
                      style: const TextStyle(
                        color: Color(0xFF78F2C0),
                        fontSize: 8.5,
                        fontWeight: FontWeight.w800,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 3),
            Text(
              '${appointment.patientName} • ${appointment.dateTimeLabel}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(0xFFBFE4F7),
                fontSize: 9.5,
                fontWeight: FontWeight.w800,
              ),
            ),
            Text(
              '${appointment.doctorName} • ${appointment.serviceName}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(0xFF8B969E),
                fontSize: 8.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniMetric extends StatelessWidget {
  final String value;
  final String label;
  final Color color;

  const _MiniMetric({
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 18,
              fontWeight: FontWeight.w900,
              height: 1,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: color, fontSize: 8.5, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class _InfoPanel extends StatelessWidget {
  final String title;
  final String body;

  const _InfoPanel({required this.title, required this.body});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF0A0F12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF1C2D35)),
      ),
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
              fontSize: 10.5,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            body,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Color(0xFF8B969E), fontSize: 9),
          ),
        ],
      ),
    );
  }
}
