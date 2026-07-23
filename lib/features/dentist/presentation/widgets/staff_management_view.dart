import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sistema_dental/core/theme/app_colors.dart';
import 'package:sistema_dental/core/models/doctor.dart';
import 'package:sistema_dental/features/auth/data/auth_repository.dart';
import 'package:sistema_dental/features/dentist/data/staff_repository.dart';

/// Vista completa de gestión de personal: consultorios, disponibilidad,
/// horarios semanales y días libres. Reemplaza la CoworkersView básica.
class StaffManagementView extends StatefulWidget {
  const StaffManagementView({
    super.key,
    this.dentistsOnly = false,
    this.showInviteAction = false,
    this.includeInactiveMembers = false,
  });

  final bool dentistsOnly;
  final bool showInviteAction;
  final bool includeInactiveMembers;

  @override
  State<StaffManagementView> createState() => _StaffManagementViewState();
}

class _StaffManagementViewState extends State<StaffManagementView> {
  late StaffRepository _repo;
  String? _clinicId;
  List<StaffMember> _staff = [];
  bool _isLoading = true;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    _repo = StaffRepository(Supabase.instance.client);
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _loadError = null;
    });
    final client = Supabase.instance.client;
    final user = client.auth.currentUser;
    if (user == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    try {
      final membership = await client
          .from('clinic_memberships')
          .select('clinic_id, role_in_clinic')
          .eq('user_id', user.id)
          .inFilter('role_in_clinic', ['owner', 'dentist', 'secretary'])
          .eq('is_active', true)
          .limit(1)
          .maybeSingle();

      if (membership == null) {
        setState(() => _isLoading = false);
        return;
      }

      _clinicId = membership['clinic_id'] as String;
      final role = membership['role_in_clinic'] as String?;
      if (role == 'owner' || role == 'dentist') {
        await _repo.ensureDoctorRecord(userId: user.id, clinicId: _clinicId!);
      }
      final staff = await _repo.getStaffInClinic(
        _clinicId!,
        includeInactive: widget.includeInactiveMembers,
      );
      _staff = widget.dentistsOnly
          ? staff
                .where(
                  (member) =>
                      member.roleInClinic == 'owner' ||
                      member.roleInClinic == 'dentist',
                )
                .toList()
          : staff;
    } catch (e) {
      debugPrint('Error loading staff: $e');
      _loadError = 'No se pudo cargar el personal de la clínica.';
    }
    setState(() => _isLoading = false);
  }

  Future<void> _showDentistInvitation() async {
    final clinicId = _clinicId;
    if (clinicId == null) return;

    final code = await AuthRepository(
      Supabase.instance.client,
    ).generateInvitationCode(clinicId, targetRole: 'dentist');
    if (!mounted) return;
    if (code == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se pudo generar el cÃ³digo de invitaciÃ³n.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Invitar dentista'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'El dentista debe crear su cuenta, seleccionar el rol Dentista e ingresar este cÃ³digo. Es vÃ¡lido por 24 horas y se usa una sola vez.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            SelectableText(
              code,
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                letterSpacing: 4,
                color: AppColors.primaryBlue,
              ),
            ),
          ],
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width > 900;
    final activeStaffCount = _staff
        .where((member) => member.isMembershipActive)
        .length;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.all(isDesktop ? 32.0 : 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Header ───────────────────────────────────────────
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Gestión de Personal',
                                style: TextStyle(
                                  fontSize: 26,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primaryBlue,
                                ),
                              ),
                              Text(
                                '$activeStaffCount miembro${activeStaffCount != 1 ? "s" : ""} activos en la clínica',
                                style: const TextStyle(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (widget.showInviteAction) ...[
                          FilledButton.icon(
                            onPressed: _clinicId == null
                                ? null
                                : _showDentistInvitation,
                            icon: const Icon(Icons.person_add_alt_1, size: 18),
                            label: Text(
                              isDesktop ? 'Invitar dentista' : 'Invitar',
                            ),
                          ),
                          const SizedBox(width: 8),
                        ],
                        ElevatedButton.icon(
                          onPressed: _loadData,
                          icon: const Icon(Icons.refresh, size: 18),
                          label: const Text('Actualizar'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryBlue,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 28),

                    if (_loadError != null) ...[
                      _buildErrorState(),
                      const SizedBox(height: 28),
                    ] else ...[
                      _buildStatsRow(),
                      const SizedBox(height: 28),
                    ],

                    // ── Lista de personal ─────────────────────────────────
                    if (_staff.isEmpty)
                      _buildEmptyState()
                    else ...[
                      const Text(
                        'Personal Activo',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (isDesktop)
                        // Grid 2 columnas en desktop
                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                crossAxisSpacing: 16,
                                mainAxisSpacing: 16,
                                childAspectRatio: 1.25,
                              ),
                          itemCount: _staff.length,
                          itemBuilder: (ctx, i) => _StaffCard(
                            member: _staff[i],
                            clinicId: _clinicId ?? '',
                            repo: _repo,
                            onRefresh: _loadData,
                          ),
                        )
                      else
                        // Lista en mobile
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _staff.length,
                          separatorBuilder: (_, _) =>
                              const SizedBox(height: 12),
                          itemBuilder: (ctx, i) => _StaffCard(
                            member: _staff[i],
                            clinicId: _clinicId ?? '',
                            repo: _repo,
                            onRefresh: _loadData,
                          ),
                        ),
                    ],
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildStatsRow() {
    final dentists = _staff
        .where(
          (s) =>
              s.isMembershipActive &&
              (s.roleInClinic == 'owner' || s.roleInClinic == 'dentist'),
        )
        .length;
    final secretaries = _staff
        .where((s) => s.isMembershipActive && s.roleInClinic == 'secretary')
        .length;
    final available = _staff
        .where((s) => s.isMembershipActive && s.isAvailable && s.hasDocRecord)
        .length;

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 760
            ? 3
            : constraints.maxWidth >= 420
            ? 2
            : 1;
        final width = (constraints.maxWidth - ((columns - 1) * 12)) / columns;

        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            SizedBox(
              width: width,
              child: _buildStatChip(
                Icons.medical_services_outlined,
                '$dentists',
                'Dentistas',
                AppColors.primaryBlue,
              ),
            ),
            SizedBox(
              width: width,
              child: _buildStatChip(
                Icons.support_agent,
                '$secretaries',
                'Secretarias',
                const Color(0xFF7C3AED),
              ),
            ),
            SizedBox(
              width: width,
              child: _buildStatChip(
                Icons.check_circle_outline,
                '$available',
                'Disponibles',
                AppColors.success,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatChip(
    IconData icon,
    String value,
    String label,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withAlpha(20),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withAlpha(60)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 11, color: color.withAlpha(180)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Icon(Icons.people_outline, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          const Text(
            'Sin personal registrado',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Invita a dentistas y secretarias usando el Código QR de la clínica.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.error.withAlpha(14),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.error.withAlpha(60)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: AppColors.error),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _loadError!,
              style: const TextStyle(color: AppColors.error),
            ),
          ),
          TextButton.icon(
            onPressed: _loadData,
            icon: const Icon(Icons.refresh),
            label: const Text('Reintentar'),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// TARJETA DE MIEMBRO DEL PERSONAL
// ═══════════════════════════════════════════════════════════════

class _StaffCard extends StatefulWidget {
  final StaffMember member;
  final String clinicId;
  final StaffRepository repo;
  final VoidCallback onRefresh;

  const _StaffCard({
    required this.member,
    required this.clinicId,
    required this.repo,
    required this.onRefresh,
  });

  @override
  State<_StaffCard> createState() => _StaffCardState();
}

class _StaffCardState extends State<_StaffCard> {
  late StaffMember _member;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _member = widget.member;
  }

  @override
  void didUpdateWidget(covariant _StaffCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.member != widget.member) _member = widget.member;
  }

  Color get _roleColor {
    switch (_member.roleInClinic) {
      case 'owner':
        return AppColors.primaryBlue;
      case 'dentist':
        return const Color(0xFF0891B2);
      case 'secretary':
        return const Color(0xFF7C3AED);
      default:
        return Colors.grey;
    }
  }

  IconData get _roleIcon {
    if (_member.roleInClinic == 'secretary') return Icons.support_agent;
    return Icons.medical_services;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(10),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Cabecera: avatar + nombre + rol ───────────────────
          Row(
            children: [
              Stack(
                children: [
                  CircleAvatar(
                    radius: 26,
                    backgroundColor: _roleColor.withAlpha(30),
                    child: Icon(_roleIcon, color: _roleColor, size: 28),
                  ),
                  if (_member.hasDocRecord)
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        width: 14,
                        height: 14,
                        decoration: BoxDecoration(
                          color: _member.isAvailable
                              ? AppColors.success
                              : AppColors.error,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _member.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (!_member.isMembershipActive)
                      const Text(
                        'Acceso inactivo',
                        style: TextStyle(
                          color: AppColors.error,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    const SizedBox(height: 2),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: _roleColor.withAlpha(20),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _member.roleLabel,
                        style: TextStyle(
                          color: _roleColor,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // ── Switch disponibilidad (solo dentistas) ─────────
              if (_member.hasDocRecord)
                Tooltip(
                  message: _member.isAvailable
                      ? 'Marcar como no disponible'
                      : 'Marcar como disponible',
                  child: Transform.scale(
                    scale: 0.85,
                    child: Switch(
                      value: _member.isAvailable,
                      onChanged: _isSaving || !_member.isMembershipActive
                          ? null
                          : _toggleAvailability,
                      activeThumbColor: AppColors.success,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 14),

          // ── Consultorio asignado ───────────────────────────────
          if (_member.hasDocRecord) ...[
            Row(
              children: [
                const Icon(
                  Icons.meeting_room_outlined,
                  size: 16,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(width: 6),
                const Text(
                  'Consultorio:',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _CabinDropdown(
                    currentCabin: _member.cabinAssigned ?? 'Sin asignar',
                    onChanged: _updateCabin,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],

          // ── Especialidad ───────────────────────────────────────
          if (_member.specialty != null && _member.specialty!.isNotEmpty)
            Row(
              children: [
                const Icon(
                  Icons.star_outline,
                  size: 16,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Especialidad: ${_member.specialty}',
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  tooltip: 'Editar especialidad',
                  visualDensity: VisualDensity.compact,
                  onPressed: _member.isMembershipActive ? _editSpecialty : null,
                  icon: const Icon(Icons.edit_outlined, size: 17),
                ),
              ],
            ),

          if (!_member.hasDocRecord &&
              (_member.roleInClinic == 'owner' ||
                  _member.roleInClinic == 'dentist')) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.error.withAlpha(12),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.error.withAlpha(45)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, size: 18, color: AppColors.error),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Falta crear el registro de consultorio para este dentista.',
                      style: TextStyle(color: AppColors.error, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _isSaving ? null : _configureDoctorRecord,
                icon: const Icon(Icons.settings_suggest_outlined),
                label: const Text('Configurar dentista'),
              ),
            ),
          ],

          const SizedBox(height: 12),

          // ── Acciones ──────────────────────────────────────────
          Row(
            children: [
              if (_member.hasDocRecord) ...[
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _member.isMembershipActive
                        ? () => _showScheduleSheet(context)
                        : null,
                    icon: const Icon(Icons.schedule, size: 16),
                    label: const Text(
                      'Horario',
                      style: TextStyle(fontSize: 12),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primaryBlue,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _member.isMembershipActive
                        ? () => _showDaysOffDialog(context)
                        : null,
                    icon: const Icon(Icons.event_busy, size: 16),
                    label: const Text(
                      'Días Libres',
                      style: TextStyle(fontSize: 12),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF7C3AED),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ],
              if (_member.roleInClinic != 'owner') ...[
                if (_member.hasDocRecord) const SizedBox(width: 8),
                IconButton(
                  onPressed: () => _confirmToggleAccess(context),
                  icon: Icon(
                    _member.isMembershipActive
                        ? Icons.remove_circle_outline
                        : Icons.restore,
                    color: _member.isMembershipActive
                        ? AppColors.error
                        : AppColors.success,
                  ),
                  tooltip: _member.isMembershipActive
                      ? 'Desactivar acceso'
                      : 'Reactivar acceso',
                  style: IconButton.styleFrom(
                    backgroundColor:
                        (_member.isMembershipActive
                                ? AppColors.error
                                : AppColors.success)
                            .withAlpha(15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _editSpecialty() async {
    final doctorRecordId = _member.doctorRecordId;
    if (doctorRecordId == null) return;
    final specialty = await showDialog<String>(
      context: context,
      builder: (_) =>
          _EditSpecialtyDialog(initialValue: _member.specialty ?? ''),
    );
    if (specialty == null || !mounted) return;

    setState(() => _isSaving = true);
    final ok = await widget.repo.updateDoctorSpecialty(
      doctorRecordId: doctorRecordId,
      specialty: specialty,
    );
    if (!mounted) return;
    setState(() {
      _isSaving = false;
      if (ok) _member = _member.copyWith(specialty: specialty);
    });
    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.repo.lastError ?? 'No se pudo actualizar la especialidad.',
          ),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> _configureDoctorRecord() async {
    setState(() => _isSaving = true);
    final recordId = await widget.repo.ensureDoctorRecord(
      userId: _member.userId,
      clinicId: widget.clinicId,
    );
    if (!mounted) return;
    setState(() => _isSaving = false);
    if (recordId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se pudo configurar el registro del dentista.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }
    widget.onRefresh();
  }

  Future<void> _toggleAvailability(bool val) async {
    if (_member.doctorRecordId == null) return;
    setState(() => _isSaving = true);
    final ok = await widget.repo.toggleAvailability(
      doctorRecordId: _member.doctorRecordId!,
      isAvailable: val,
    );
    if (ok) {
      setState(() => _member = _member.copyWith(isAvailable: val));
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.repo.lastError ?? 'No se pudo cambiar la disponibilidad.',
          ),
          backgroundColor: AppColors.error,
        ),
      );
    }
    setState(() => _isSaving = false);
  }

  Future<void> _updateCabin(String cabin) async {
    if (_member.doctorRecordId == null) return;
    final ok = await widget.repo.updateDoctorCabin(
      doctorRecordId: _member.doctorRecordId!,
      cabin: cabin,
    );
    if (ok) {
      setState(() => _member = _member.copyWith(cabinAssigned: cabin));
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.repo.lastError ?? 'No se pudo actualizar el consultorio.',
          ),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> _confirmToggleAccess(BuildContext context) async {
    if (!_member.isMembershipActive) {
      final restored = await widget.repo.setMemberAccess(
        userId: _member.userId,
        clinicId: widget.clinicId,
        isActive: true,
      );
      if (!context.mounted) return;
      if (restored) {
        widget.onRefresh();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo reactivar el acceso.')),
        );
      }
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('¿Remover acceso?'),
        content: Text(
          '¿Seguro que deseas remover el acceso de ${_member.name} a la clínica?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Remover', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await widget.repo.removeMemberAccess(
        userId: _member.userId,
        clinicId: widget.clinicId,
      );
      widget.onRefresh();
    }
  }

  void _showScheduleSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _ScheduleSheet(
        member: _member,
        clinicId: widget.clinicId,
        repo: widget.repo,
      ),
    );
  }

  void _showDaysOffDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => _DaysOffDialog(
        member: _member,
        clinicId: widget.clinicId,
        repo: widget.repo,
      ),
    );
  }
}

class _EditSpecialtyDialog extends StatefulWidget {
  const _EditSpecialtyDialog({required this.initialValue});

  final String initialValue;

  @override
  State<_EditSpecialtyDialog> createState() => _EditSpecialtyDialogState();
}

class _EditSpecialtyDialogState extends State<_EditSpecialtyDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final value = _controller.text.trim();
    if (value.isNotEmpty) Navigator.pop(context, value);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Editar especialidad'),
      content: TextField(
        controller: _controller,
        autofocus: true,
        textCapitalization: TextCapitalization.words,
        decoration: const InputDecoration(
          labelText: 'Especialidad',
          hintText: 'Ej. Ortodoncia',
        ),
        onSubmitted: (_) => _submit(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton(onPressed: _submit, child: const Text('Guardar')),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// DROPDOWN DE CONSULTORIOS
// ═══════════════════════════════════════════════════════════════

class _CabinDropdown extends StatelessWidget {
  final String currentCabin;
  final Future<void> Function(String) onChanged;

  static const _cabins = [
    'Consultorio 1',
    'Consultorio 2',
    'Consultorio 3',
    'Consultorio 4',
    'Consultorio 5',
    'Sin asignar',
  ];

  const _CabinDropdown({required this.currentCabin, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final value = _cabins.contains(currentCabin) ? currentCabin : 'Sin asignar';
    return DropdownButtonHideUnderline(
      child: DropdownButton<String>(
        value: value,
        isDense: true,
        style: const TextStyle(
          fontSize: 13,
          color: AppColors.primaryBlue,
          fontWeight: FontWeight.bold,
        ),
        onChanged: (v) {
          if (v != null) onChanged(v);
        },
        items: _cabins
            .map((c) => DropdownMenuItem(value: c, child: Text(c)))
            .toList(),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// BOTTOM SHEET: HORARIO SEMANAL
// ═══════════════════════════════════════════════════════════════

class _ScheduleSheet extends StatefulWidget {
  final StaffMember member;
  final String clinicId;
  final StaffRepository repo;

  const _ScheduleSheet({
    required this.member,
    required this.clinicId,
    required this.repo,
  });

  @override
  State<_ScheduleSheet> createState() => _ScheduleSheetState();
}

class _ScheduleSheetState extends State<_ScheduleSheet> {
  List<DoctorDaySchedule>? _schedule;
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadSchedule();
  }

  Future<void> _loadSchedule() async {
    final s = await widget.repo.getWeeklySchedule(
      doctorUserId: widget.member.userId,
      clinicId: widget.clinicId,
    );
    setState(() {
      _schedule = s;
      _isLoading = false;
    });
  }

  Future<void> _save() async {
    if (_schedule == null) return;
    setState(() => _isSaving = true);
    final ok = await widget.repo.saveWeeklySchedule(
      doctorUserId: widget.member.userId,
      clinicId: widget.clinicId,
      schedule: _schedule!,
    );
    if (!mounted) return;
    setState(() => _isSaving = false);
    if (ok) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Horario guardado exitosamente'),
          backgroundColor: AppColors.success,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.repo.lastError ?? 'No se pudo guardar el horario.',
          ),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.75,
      maxChildSize: 0.92,
      minChildSize: 0.4,
      builder: (ctx, scrollCtrl) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Column(
          children: [
            // Handle
            Center(
              child: Container(
                margin: const EdgeInsets.symmetric(vertical: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Horario de ${widget.member.name}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Text(
                        'Toca una hora para editarla',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  ElevatedButton(
                    onPressed: _isSaving ? null : _save,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryBlue,
                    ),
                    child: _isSaving
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('Guardar'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            const Divider(),
            if (_isLoading)
              const Expanded(child: Center(child: CircularProgressIndicator()))
            else
              Expanded(
                child: ListView.builder(
                  controller: scrollCtrl,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 8,
                  ),
                  itemCount: _schedule!.length,
                  itemBuilder: (ctx, i) {
                    final day = _schedule![i];
                    return _DayScheduleRow(
                      day: day,
                      onToggle: (val) => setState(() => day.isWorkingDay = val),
                      onChangeStart: (t) => setState(() => day.startTime = t),
                      onChangeEnd: (t) => setState(() => day.endTime = t),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ─── Fila de un día en el horario ────────────────────────────

class _DayScheduleRow extends StatelessWidget {
  final DoctorDaySchedule day;
  final ValueChanged<bool> onToggle;
  final ValueChanged<String> onChangeStart;
  final ValueChanged<String> onChangeEnd;

  const _DayScheduleRow({
    required this.day,
    required this.onToggle,
    required this.onChangeStart,
    required this.onChangeEnd,
  });

  Future<void> _pickTime(
    BuildContext context,
    String current,
    ValueChanged<String> onPick,
  ) async {
    final parts = current.split(':');
    final initial = TimeOfDay(
      hour: int.parse(parts[0]),
      minute: int.parse(parts[1]),
    );
    final picked = await showTimePicker(context: context, initialTime: initial);
    if (picked != null) {
      final h = picked.hour.toString().padLeft(2, '0');
      final m = picked.minute.toString().padLeft(2, '0');
      onPick('$h:$m');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: day.isWorkingDay
            ? AppColors.primaryBlue.withAlpha(12)
            : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: day.isWorkingDay
              ? AppColors.primaryBlue.withAlpha(60)
              : Colors.grey.shade300,
        ),
      ),
      child: Row(
        children: [
          // Nombre del día
          SizedBox(
            width: 48,
            child: Text(
              day.dayShort,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: day.isWorkingDay
                    ? AppColors.primaryBlue
                    : AppColors.textSecondary,
              ),
            ),
          ),
          // Toggle activo/inactivo
          Switch(
            value: day.isWorkingDay,
            onChanged: onToggle,
            activeThumbColor: AppColors.primaryBlue,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          const Spacer(),
          if (day.isWorkingDay) ...[
            // Hora inicio
            GestureDetector(
              onTap: () => _pickTime(context, day.startTime, onChangeStart),
              child: _TimeChip(time: day.startTime, label: 'Inicio'),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                '–',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
            // Hora fin
            GestureDetector(
              onTap: () => _pickTime(context, day.endTime, onChangeEnd),
              child: _TimeChip(time: day.endTime, label: 'Fin'),
            ),
          ] else
            const Text(
              'Día libre',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
        ],
      ),
    );
  }
}

class _TimeChip extends StatelessWidget {
  final String time;
  final String label;

  const _TimeChip({required this.time, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.primaryBlue,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(
            time,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          Text(
            label,
            style: const TextStyle(color: Colors.white70, fontSize: 9),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// DIÁLOGO: DÍAS LIBRES
// ═══════════════════════════════════════════════════════════════

class _DaysOffDialog extends StatefulWidget {
  final StaffMember member;
  final String clinicId;
  final StaffRepository repo;

  const _DaysOffDialog({
    required this.member,
    required this.clinicId,
    required this.repo,
  });

  @override
  State<_DaysOffDialog> createState() => _DaysOffDialogState();
}

class _DaysOffDialogState extends State<_DaysOffDialog> {
  List<DoctorDayOff> _daysOff = [];
  bool _isLoading = true;
  DateTime? _selectedDate;
  final _reasonCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadDaysOff();
  }

  @override
  void dispose() {
    _reasonCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadDaysOff() async {
    setState(() => _isLoading = true);
    final list = await widget.repo.getDaysOff(
      doctorUserId: widget.member.userId,
      clinicId: widget.clinicId,
    );
    setState(() {
      _daysOff = list;
      _isLoading = false;
    });
  }

  Future<void> _addDayOff() async {
    if (_selectedDate == null) return;
    final ok = await widget.repo.addDayOff(
      doctorUserId: widget.member.userId,
      clinicId: widget.clinicId,
      date: _selectedDate!,
      reason: _reasonCtrl.text.trim().isEmpty ? null : _reasonCtrl.text.trim(),
    );
    if (ok) {
      _reasonCtrl.clear();
      setState(() => _selectedDate = null);
      _loadDaysOff();
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.repo.lastError ?? 'No se pudo agregar el dia libre.',
          ),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> _removeDayOff(String id) async {
    final ok = await widget.repo.removeDayOff(id);
    if (ok) {
      _loadDaysOff();
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.repo.lastError ?? 'No se pudo eliminar el dia libre.',
          ),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Días Libres – ${widget.member.name}',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const Text(
            'Agrega ausencias o vacaciones',
            style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
        ],
      ),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Formulario para agregar ──────────────────────────
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.lightBlueAccent,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Agregar día libre',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: DateTime.now().add(
                                const Duration(days: 1),
                              ),
                              firstDate: DateTime.now(),
                              lastDate: DateTime.now().add(
                                const Duration(days: 365),
                              ),
                            );
                            if (picked != null) {
                              setState(() => _selectedDate = picked);
                            }
                          },
                          icon: const Icon(Icons.calendar_today, size: 16),
                          label: Text(
                            _selectedDate == null
                                ? 'Seleccionar fecha'
                                : '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}',
                            style: const TextStyle(fontSize: 13),
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.primaryBlue,
                            padding: const EdgeInsets.symmetric(vertical: 10),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _reasonCtrl,
                    decoration: InputDecoration(
                      hintText: 'Motivo (opcional)',
                      isDense: true,
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _selectedDate == null ? null : _addDayOff,
                      icon: const Icon(Icons.add, size: 16),
                      label: const Text('Agregar'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryBlue,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ── Lista de días libres próximos ────────────────────
            const Text(
              'Ausencias programadas',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
            const SizedBox(height: 8),
            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else if (_daysOff.isEmpty)
              const Text(
                'Sin ausencias registradas.',
                style: TextStyle(color: AppColors.textSecondary),
              )
            else
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 180),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _daysOff.length,
                  itemBuilder: (ctx, i) {
                    final d = _daysOff[i];
                    return ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(
                        Icons.event_busy,
                        color: AppColors.error,
                        size: 20,
                      ),
                      title: Text(
                        '${d.date.day}/${d.date.month}/${d.date.year}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                      subtitle: d.reason != null
                          ? Text(
                              d.reason!,
                              style: const TextStyle(fontSize: 11),
                            )
                          : null,
                      trailing: IconButton(
                        icon: const Icon(
                          Icons.delete_outline,
                          color: AppColors.error,
                          size: 18,
                        ),
                        onPressed: () =>
                            d.id != null ? _removeDayOff(d.id!) : null,
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cerrar'),
        ),
      ],
    );
  }
}
