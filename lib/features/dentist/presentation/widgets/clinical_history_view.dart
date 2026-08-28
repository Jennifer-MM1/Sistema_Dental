import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sistema_dental/core/theme/app_colors.dart';
import 'package:sistema_dental/core/models/clinical_note.dart';
import 'package:sistema_dental/core/models/prescription.dart';
import 'package:sistema_dental/features/dentist/data/clinical_repository.dart';
import 'package:sistema_dental/features/dentist/presentation/widgets/odontogram_widget.dart';
import 'package:sistema_dental/features/shared/data/prescription_pdf_generator.dart';
import 'package:file_picker/file_picker.dart' as fp;
import 'package:sistema_dental/core/models/clinical_attachment.dart';
import 'package:sistema_dental/features/dentist/data/clinical_attachment_repository.dart';
import 'package:sistema_dental/features/shared/data/clinical_history_pdf_generator.dart';
import 'package:intl/intl.dart';

/// Vista de Historial Clínico para el panel del dentista.
/// Permite buscar pacientes, ver su historial de notas clínicas,
/// crear nuevas notas con odontograma y generar recetas PDF.
class ClinicalHistoryView extends ConsumerStatefulWidget {
  const ClinicalHistoryView({super.key});

  @override
  ConsumerState<ClinicalHistoryView> createState() =>
      _ClinicalHistoryViewState();
}

class _ClinicalHistoryViewState extends ConsumerState<ClinicalHistoryView> {
  String _clinicId = '';
  String _doctorRecordId = '';
  List<Map<String, dynamic>> _patients = [];
  List<Map<String, dynamic>> _filteredPatients = [];
  Map<String, dynamic>? _selectedPatient;
  List<ClinicalNote> _notes = [];
  List<Map<String, dynamic>> _patientAppointments = [];
  List<ClinicalAttachment> _attachments = [];
  int _selectedTab = 0; // 0: Notas clínicas, 1: Citas agendadas, 2: Radiografías y Estudios
  bool _isLoading = true;
  bool _isLoadingNotes = false;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    final client = Supabase.instance.client;
    final user = client.auth.currentUser;
    if (user == null) return;

    try {
      final membership = await client
          .from('clinic_memberships')
          .select('clinic_id')
          .eq('user_id', user.id)
          .inFilter('role_in_clinic', ['owner', 'dentist'])
          .eq('is_active', true)
          .limit(1)
          .maybeSingle();

      if (membership == null) return;
      _clinicId = membership['clinic_id'] as String;

      final repo = ref.read(clinicalRepositoryProvider);
      _doctorRecordId = await repo.getDoctorRecordId(user.id, _clinicId) ?? '';
      _patients = await repo.getPatientsInClinic(_clinicId);
      _filteredPatients = List.from(_patients);
    } catch (e) {
      debugPrint('Error loading clinical data: $e');
    }

    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _loadNotesForPatient(String patientId) async {
    setState(() => _isLoadingNotes = true);
    final repo = ref.read(clinicalRepositoryProvider);
    _notes = await repo.getNotesForPatientInClinic(patientId, _clinicId);

    try {
      final client = Supabase.instance.client;
      final appts = await client
          .from('appointments')
          .select('*, doctors(profiles(name)), services(service_name, duration_mins)')
          .eq('patient_id', patientId)
          .order('date_time', ascending: false);
      _patientAppointments = List<Map<String, dynamic>>.from(appts);
    } catch (e) {
      debugPrint('Error loading patient appointments: $e');
    }

    try {
      final attachmentRepo = ref.read(clinicalAttachmentRepositoryProvider);
      _attachments = await attachmentRepo.getAttachmentsForPatient(patientId);
    } catch (e) {
      debugPrint('Error loading patient attachments: $e');
      _attachments = [];
    }

    if (mounted) setState(() => _isLoadingNotes = false);
  }

  Future<void> _uploadAttachmentForSelectedPatient() async {
    final patient = _selectedPatient;
    if (patient == null) return;
    final patientId = patient['id'] as String;

    try {
      fp.FilePickerResult? result = await fp.FilePicker.platform.pickFiles(
        type: fp.FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf', 'webp'],
        allowMultiple: false,
      );

      if (result == null || result.files.isEmpty || !mounted) return;

      final fileBytes = result.files.first.bytes;
      final fileName = result.files.first.name;

      if (fileBytes == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No se pudieron leer los datos del archivo seleccionado.'),
            backgroundColor: AppColors.error,
          ),
        );
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Subiendo $fileName para ${patient['first_name']}...'),
        ),
      );

      final attachmentRepo = ref.read(clinicalAttachmentRepositoryProvider);
      final attachment = await attachmentRepo.uploadAttachment(
        patientId: patientId,
        fileName: fileName,
        bytes: fileBytes,
      );

      if (mounted) {
        if (attachment != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Radiografía/Estudio guardado y asociado exitosamente al expediente.'),
              backgroundColor: AppColors.success,
            ),
          );
          _loadNotesForPatient(patientId);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No se pudo completar el registro del archivo en la nube.'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Error uploading attachment: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al subir radiografía: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _filterPatients(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredPatients = List.from(_patients);
      } else {
        final lower = query.toLowerCase();
        _filteredPatients = _patients.where((p) {
          final name = '${p['first_name']} ${p['last_name']}'.toLowerCase();
          return name.contains(lower);
        }).toList();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primaryBlue),
      );
    }

    final isWide = MediaQuery.of(context).size.width > 900;

    if (isWide) {
      return Row(
        children: [
          SizedBox(width: 320, child: _buildPatientList()),
          const VerticalDivider(width: 1),
          Expanded(child: _buildClinicalContent()),
        ],
      );
    }

    // En móvil, si hay paciente seleccionado, mostrar contenido clínico
    if (_selectedPatient != null) {
      return Column(
        children: [
          _buildPatientHeader(),
          Expanded(child: _buildClinicalContent()),
        ],
      );
    }

    return _buildPatientList();
  }

  Widget _buildPatientList() {
    return Container(
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Historial Clínico',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${_patients.length} pacientes registrados',
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _searchController,
                  onChanged: _filterPatients,
                  decoration: InputDecoration(
                    hintText: 'Buscar paciente...',
                    prefixIcon: const Icon(
                      Icons.search,
                      color: AppColors.primaryBlue,
                    ),
                    filled: true,
                    fillColor: AppColors.background,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: _filteredPatients.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.person_search,
                          size: 48,
                          color: Colors.grey.shade300,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'No se encontraron pacientes',
                          style: TextStyle(color: Colors.grey.shade400),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: _filteredPatients.length,
                    itemBuilder: (context, index) {
                      final patient = _filteredPatients[index];
                      final isSelected =
                          _selectedPatient?['id'] == patient['id'];
                      final name =
                          '${patient['first_name']} ${patient['last_name']}';

                      final tutorName = patient['profiles'] != null ? patient['profiles']['name'] as String? : null;
                      final relStr = patient['relationship'] == 'self'
                          ? 'Paciente Titular'
                          : (patient['relationship'] == 'child'
                              ? 'Hijo(a) ${tutorName != null ? '• Tutor: $tutorName' : ''}'
                              : (patient['relationship'] == 'spouse'
                                  ? 'Cónyuge ${tutorName != null ? '• Tutor: $tutorName' : ''}'
                                  : 'Familiar ${tutorName != null ? '• Tutor: $tutorName' : ''}'));

                      return Material(
                        color: Colors.transparent,
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: isSelected
                                ? AppColors.primaryBlue
                                : AppColors.lightBlueAccent,
                            child: Text(
                              name[0].toUpperCase(),
                              style: TextStyle(
                                color: isSelected
                                    ? Colors.white
                                    : AppColors.primaryBlue,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          title: Text(
                            name,
                            style: TextStyle(
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                          subtitle: Text(
                            patient['date_of_birth'] != null
                                ? '$relStr • Nacimiento: ${patient['date_of_birth']}'
                                : relStr,
                            style: const TextStyle(fontSize: 12),
                          ),
                          selected: isSelected,
                          selectedTileColor: AppColors.primaryBlue.withAlpha(13),
                          onTap: () {
                            setState(() => _selectedPatient = patient);
                            _loadNotesForPatient(patient['id'] as String);
                          },
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildPatientHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: Colors.white,
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => setState(() => _selectedPatient = null),
          ),
          CircleAvatar(
            backgroundColor: AppColors.lightBlueAccent,
            child: Text(
              (_selectedPatient?['first_name'] as String? ?? 'P')[0]
                  .toUpperCase(),
              style: const TextStyle(
                color: AppColors.primaryBlue,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              '${_selectedPatient?['first_name']} ${_selectedPatient?['last_name']}',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClinicalContent() {
    if (_selectedPatient == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.assignment_outlined,
              size: 64,
              color: Colors.grey.shade300,
            ),
            const SizedBox(height: 16),
            Text(
              'Selecciona un paciente',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey.shade400,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Para ver su historial clínico y crear notas',
              style: TextStyle(fontSize: 13, color: Colors.grey.shade400),
            ),
          ],
        ),
      );
    }

    return Container(
      color: AppColors.background,
      child: Column(
        children: [
          // Barra de acciones
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Historial de ${_selectedPatient?['first_name']} ${_selectedPatient?['last_name']}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: _exportFullPatientHistoryPdf,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.error,
                    side: const BorderSide(color: AppColors.error),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(Icons.picture_as_pdf, size: 18),
                  label: const Text('Exportar PDF'),
                ),
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  onPressed: _uploadAttachmentForSelectedPatient,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primaryBlue,
                    side: const BorderSide(color: AppColors.primaryBlue),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(Icons.cloud_upload_outlined, size: 18),
                  label: const Text('Subir Radiografía'),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: () => _showNewNoteDialog(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryBlue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Nueva Nota'),
                ),
              ],
            ),
          ),
          // Barra de pestañas (Notas vs Citas vs Radiografías)
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  ChoiceChip(
                    label: Text('Notas Clínicas (${_notes.length})'),
                    selected: _selectedTab == 0,
                    onSelected: (val) {
                      if (val) setState(() => _selectedTab = 0);
                    },
                  ),
                  const SizedBox(width: 8),
                  ChoiceChip(
                    label: Text('Citas Agendadas (${_patientAppointments.length})'),
                    selected: _selectedTab == 1,
                    onSelected: (val) {
                      if (val) setState(() => _selectedTab = 1);
                    },
                  ),
                  const SizedBox(width: 8),
                  ChoiceChip(
                    label: Text('Radiografías y Estudios (${_attachments.length})'),
                    selected: _selectedTab == 2,
                    onSelected: (val) {
                      if (val) setState(() => _selectedTab = 2);
                    },
                  ),
                ],
              ),
            ),
          ),
          const Divider(height: 1),
          // Contenido según pestaña elegida
          Expanded(
            child: _isLoadingNotes
                ? const Center(
                    child: CircularProgressIndicator(
                      color: AppColors.primaryBlue,
                    ),
                  )
                : _selectedTab == 0
                    ? (_notes.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.note_alt_outlined,
                                  size: 48,
                                  color: Colors.grey.shade300,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Sin notas clínicas',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey.shade400,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: _notes.length,
                            itemBuilder: (context, index) {
                              return _buildNoteCard(_notes[index]);
                            },
                          ))
                    : (_selectedTab == 1
                        ? (_patientAppointments.isEmpty
                            ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.calendar_today_outlined,
                                      size: 48,
                                      color: Colors.grey.shade300,
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Sin citas registradas',
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: Colors.grey.shade400,
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : ListView.builder(
                                padding: const EdgeInsets.all(16),
                                itemCount: _patientAppointments.length,
                                itemBuilder: (context, index) {
                                  final appt = _patientAppointments[index];
                                  final dateStr = appt['date_time'] != null
                                      ? DateFormat('dd/MM/yyyy - hh:mm a').format(
                                          DateTime.parse(appt['date_time'] as String).toLocal(),
                                        )
                                      : 'Fecha no especificada';
                                  final doctorName = (appt['doctors'] as Map?)?['profiles']?['name'] ?? 'Dentista';
                                  final serviceName = (appt['services'] as Map?)?['service_name'] ?? 'Consulta';
                                  final status = appt['status'] as String? ?? 'upcoming';

                                  final statusLabel = switch (status) {
                                    'upcoming' => 'Programada',
                                    'in_lobby' => 'En espera',
                                    'in_treatment' => 'En consulta',
                                    'completed' => 'Completada',
                                    'cancelled' => 'Cancelada',
                                    _ => status,
                                  };

                                  return Card(
                                    margin: const EdgeInsets.only(bottom: 12),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: ListTile(
                                      leading: const CircleAvatar(
                                        backgroundColor: AppColors.lightBlueAccent,
                                        child: Icon(Icons.calendar_month, color: AppColors.primaryBlue),
                                      ),
                                      title: Text(
                                        serviceName,
                                        style: const TextStyle(fontWeight: FontWeight.bold),
                                      ),
                                      subtitle: Text('Dr. $doctorName • $dateStr'),
                                      trailing: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: AppColors.lightBlueAccent,
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Text(
                                          statusLabel,
                                          style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.primaryBlue,
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ))
                        : _buildAttachmentsGrid()),
          ),
        ],
      ),
    );
  }

  Widget _buildNoteCard(ClinicalNote note) {
    String dateStr = 'Sin fecha';
    if (note.createdAt != null) {
      try {
        dateStr = DateFormat('dd MMM yyyy, HH:mm', 'es').format(note.createdAt!);
      } catch (_) {
        dateStr = DateFormat('dd/MM/yyyy, HH:mm').format(note.createdAt!);
      }
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cabecera con fecha y acciones
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primaryBlue.withAlpha(26),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.calendar_today,
                        size: 14,
                        color: AppColors.primaryBlue,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        dateStr,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.primaryBlue,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                // Botón de receta
                TextButton.icon(
                  onPressed: () => _showPrescriptionDialog(note),
                  icon: const Icon(Icons.description_outlined, size: 16),
                  label: const Text('Receta'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.success,
                    textStyle: const TextStyle(fontSize: 13),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Diagnóstico
            if (note.diagnosis != null && note.diagnosis!.isNotEmpty) ...[
              _buildSectionTitle('Diagnóstico'),
              const SizedBox(height: 4),
              Text(note.diagnosis!, style: const TextStyle(fontSize: 14)),
              const SizedBox(height: 12),
            ],

            // Tratamiento
            if (note.treatmentPerformed != null &&
                note.treatmentPerformed!.isNotEmpty) ...[
              _buildSectionTitle('Tratamiento Realizado'),
              const SizedBox(height: 4),
              Text(
                note.treatmentPerformed!,
                style: const TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 12),
            ],

            // Observaciones
            if (note.observations != null && note.observations!.isNotEmpty) ...[
              _buildSectionTitle('Observaciones'),
              const SizedBox(height: 4),
              Text(note.observations!, style: const TextStyle(fontSize: 14)),
              const SizedBox(height: 12),
            ],

            // Dientes involucrados
            if (note.toothNumbers.isNotEmpty) ...[
              _buildSectionTitle('Dientes Involucrados'),
              const SizedBox(height: 8),
              OdontogramWidget(
                selectedTeeth: note.toothNumbers,
                readOnly: true,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: AppColors.textSecondary,
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  //  DIÁLOGO: Nueva Nota Clínica
  // ─────────────────────────────────────────────────────────────

  Future<void> _showNewNoteDialog() async {
    final diagnosisCtrl = TextEditingController();
    final treatmentCtrl = TextEditingController();
    final observationsCtrl = TextEditingController();
    List<int> selectedTeeth = [];

    final savedNote = await showDialog<dynamic>(
      context: context,
      barrierDismissible: false,
      builder: (context) {

        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 600),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Título
                      Row(
                        children: [
                          const Icon(
                            Icons.note_add,
                            color: AppColors.primaryBlue,
                          ),
                          const SizedBox(width: 8),
                          const Expanded(
                            child: Text(
                              'Nueva Nota Clínica',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () => Navigator.pop(context, false),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Diagnóstico
                      TextField(
                        controller: diagnosisCtrl,
                        maxLines: 3,
                        decoration: InputDecoration(
                          labelText: 'Diagnóstico',
                          hintText: 'Ej: Caries profunda en pieza 36...',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Tratamiento
                      TextField(
                        controller: treatmentCtrl,
                        maxLines: 3,
                        decoration: InputDecoration(
                          labelText: 'Tratamiento Realizado',
                          hintText: 'Ej: Obturación con resina compuesta...',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Observaciones
                      TextField(
                        controller: observationsCtrl,
                        maxLines: 2,
                        decoration: InputDecoration(
                          labelText: 'Observaciones (opcional)',
                          hintText:
                              'Ej: Paciente refiere sensibilidad al frío...',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Odontograma
                      OdontogramWidget(
                        selectedTeeth: selectedTeeth,
                        onSelectionChanged: (teeth) {
                          setDialogState(() => selectedTeeth = teeth);
                        },
                      ),
                      const SizedBox(height: 24),

                      // Botones
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text('Cancelar'),
                          ),
                          const SizedBox(width: 8),
                          OutlinedButton.icon(
                            onPressed: () async {
                              if (diagnosisCtrl.text.trim().isEmpty &&
                                  treatmentCtrl.text.trim().isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Ingresa al menos un diagnóstico o tratamiento.'),
                                  ),
                                );
                                return;
                              }

                              final note = ClinicalNote(
                                patientId: _selectedPatient!['id'] as String,
                                doctorId: _doctorRecordId,
                                clinicId: _clinicId,
                                diagnosis: diagnosisCtrl.text.trim(),
                                treatmentPerformed: treatmentCtrl.text.trim(),
                                observations: observationsCtrl.text.trim(),
                                toothNumbers: selectedTeeth,
                              );

                              final repo = ref.read(clinicalRepositoryProvider);
                              final saved = await repo.saveNote(note);
                              if (saved != null && context.mounted) {
                                Navigator.pop(context, {'note': saved, 'prescribe': false});
                              }
                            },
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.primaryBlue,
                              side: const BorderSide(color: AppColors.primaryBlue),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            ),
                            icon: const Icon(Icons.save, size: 18),
                            label: const Text('Solo Guardar'),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton.icon(
                            onPressed: () async {
                              if (diagnosisCtrl.text.trim().isEmpty &&
                                  treatmentCtrl.text.trim().isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Ingresa al menos un diagnóstico o tratamiento.'),
                                  ),
                                );
                                return;
                              }

                              final note = ClinicalNote(
                                patientId: _selectedPatient!['id'] as String,
                                doctorId: _doctorRecordId,
                                clinicId: _clinicId,
                                diagnosis: diagnosisCtrl.text.trim(),
                                treatmentPerformed: treatmentCtrl.text.trim(),
                                observations: observationsCtrl.text.trim(),
                                toothNumbers: selectedTeeth,
                              );

                              final repo = ref.read(clinicalRepositoryProvider);
                              final savedNote = await repo.saveNote(note);
                              if (savedNote != null && context.mounted) {
                                Navigator.pop(context, {'note': savedNote, 'prescribe': true});
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primaryBlue,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            ),
                            icon: const Icon(Icons.medication, size: 18),
                            label: const Text('Guardar y Recetar'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );

    if (savedNote is Map<String, dynamic> && _selectedPatient != null) {
      final note = savedNote['note'] as ClinicalNote;
      final prescribe = savedNote['prescribe'] as bool;

      _loadNotesForPatient(_selectedPatient!['id'] as String);

      if (prescribe) {
        _showNewPrescriptionDialog(note);
      }
    }
  }

  // ─────────────────────────────────────────────────────────────
  //  DIÁLOGO: Receta Digital
  // ─────────────────────────────────────────────────────────────

  Future<void> _showPrescriptionDialog(ClinicalNote note) async {
    if (note.id == null) return;

    // Verificar si ya existe receta
    final repo = ref.read(clinicalRepositoryProvider);
    final existing = await repo.getPrescription(note.id!);

    if (existing != null && mounted) {
      // Mostrar la receta existente y ofrecer PDF
      _showExistingPrescription(existing, note);
      return;
    }

    // Crear nueva receta
    if (mounted) _showNewPrescriptionDialog(note);
  }

  Future<void> _showExistingPrescription(
    Prescription prescription,
    ClinicalNote note,
  ) async {
    await showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.description, color: AppColors.success),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'Receta Digital',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Lista de medicamentos
                  ...prescription.medications.map(
                    (med) => Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            med.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Dosis: ${med.dosage} | Frecuencia: ${med.frequency} | Duración: ${med.duration}',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  if (prescription.instructions != null &&
                      prescription.instructions!.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    _buildSectionTitle('Indicaciones Generales'),
                    const SizedBox(height: 4),
                    Text(prescription.instructions!),
                  ],

                  const SizedBox(height: 20),

                  // Botón generar PDF
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        await PrescriptionPdfGenerator.generateAndShow(
                          context: context,
                          prescription: prescription,
                          note: note,
                          patientName:
                              '${_selectedPatient?['first_name']} ${_selectedPatient?['last_name']}',
                          patientDob:
                              _selectedPatient?['date_of_birth'] as String?,
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryBlue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: const Icon(Icons.picture_as_pdf),
                      label: const Text('Descargar / Imprimir PDF'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _showNewPrescriptionDialog(ClinicalNote note) async {
    final instructionsCtrl = TextEditingController();
    List<PrescriptionItem> medications = [];
    final nameCtrl = TextEditingController();
    final dosageCtrl = TextEditingController();
    final frequencyCtrl = TextEditingController();
    final durationCtrl = TextEditingController();

    final saved = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 550),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.medication_outlined,
                            color: AppColors.primaryBlue,
                          ),
                          const SizedBox(width: 8),
                          const Expanded(
                            child: Text(
                              'Nueva Receta',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () => Navigator.pop(context, false),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Formulario de medicamento
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.background,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Agregar Medicamento',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 12),
                            TextField(
                              controller: nameCtrl,
                              decoration: InputDecoration(
                                labelText: 'Medicamento',
                                hintText: 'Ej: Amoxicilina 500mg',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                isDense: true,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: dosageCtrl,
                                    decoration: InputDecoration(
                                      labelText: 'Dosis',
                                      hintText: 'Ej: 1 cápsula',
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      isDense: true,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: TextField(
                                    controller: frequencyCtrl,
                                    decoration: InputDecoration(
                                      labelText: 'Frecuencia',
                                      hintText: 'Ej: Cada 8 hrs',
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      isDense: true,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: durationCtrl,
                                    decoration: InputDecoration(
                                      labelText: 'Duración',
                                      hintText: 'Ej: 7 días',
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      isDense: true,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                ElevatedButton(
                                  onPressed: () {
                                    if (nameCtrl.text.trim().isEmpty) return;
                                    setDialogState(() {
                                      medications.add(
                                        PrescriptionItem(
                                          name: nameCtrl.text.trim(),
                                          dosage: dosageCtrl.text.trim(),
                                          frequency: frequencyCtrl.text.trim(),
                                          duration: durationCtrl.text.trim(),
                                        ),
                                      );
                                      nameCtrl.clear();
                                      dosageCtrl.clear();
                                      frequencyCtrl.clear();
                                      durationCtrl.clear();
                                    });
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.success,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                  child: const Text('Agregar'),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Lista de medicamentos agregados
                      if (medications.isNotEmpty)
                        ...medications.asMap().entries.map((entry) {
                          final i = entry.key;
                          final med = entry.value;
                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey.shade200),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        med.name,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Text(
                                        '${med.dosage} | ${med.frequency} | ${med.duration}',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey.shade600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.delete_outline,
                                    color: AppColors.error,
                                    size: 20,
                                  ),
                                  onPressed: () {
                                    setDialogState(() {
                                      medications.removeAt(i);
                                    });
                                  },
                                ),
                              ],
                            ),
                          );
                        }),

                      const SizedBox(height: 12),
                      TextField(
                        controller: instructionsCtrl,
                        maxLines: 2,
                        decoration: InputDecoration(
                          labelText: 'Indicaciones Generales (opcional)',
                          hintText: 'Ej: Tomar después de los alimentos...',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text('Cancelar'),
                          ),
                          const SizedBox(width: 12),
                          ElevatedButton.icon(
                            onPressed: medications.isEmpty
                                ? null
                                : () async {
                                    final prescription = Prescription(
                                      clinicalNoteId: note.id!,
                                      patientId: note.patientId,
                                      doctorId: note.doctorId,
                                      clinicId: note.clinicId,
                                      medications: medications,
                                      instructions: instructionsCtrl.text
                                          .trim(),
                                    );
                                    final repo = ref.read(
                                      clinicalRepositoryProvider,
                                    );
                                    final result = await repo.savePrescription(
                                      prescription,
                                    );
                                    if (result != null && context.mounted) {
                                      Navigator.pop(context, true);
                                    }
                                  },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primaryBlue,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 12,
                              ),
                            ),
                            icon: const Icon(Icons.save, size: 18),
                            label: const Text('Guardar Receta'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );

    if (saved != true || !mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Receta guardada exitosamente.'),
        backgroundColor: AppColors.success,
      ),
    );
  }

  Widget _buildAttachmentsGrid() {
    if (_attachments.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.photo_library_outlined,
                size: 56,
                color: Colors.grey.shade300,
              ),
              const SizedBox(height: 12),
              Text(
                'Sin radiografías o estudios registrados',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade500,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Sube una radiografía para asociarla al expediente de ${_selectedPatient?['first_name'] ?? 'este paciente'}.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: Colors.grey.shade400),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: _uploadAttachmentForSelectedPatient,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryBlue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(Icons.cloud_upload_outlined, size: 18),
                label: const Text('Subir Radiografía / Estudio'),
              ),
            ],
          ),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Estudios y Radiografías (${_attachments.length})',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              TextButton.icon(
                onPressed: _uploadAttachmentForSelectedPatient,
                icon: const Icon(Icons.add_a_photo_outlined, size: 18),
                label: const Text('Añadir Otro'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 220,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 0.85,
            ),
            itemCount: _attachments.length,
            itemBuilder: (context, index) {
              final att = _attachments[index];
              final dateStr = DateFormat('dd/MM/yyyy').format(att.createdAt.toLocal());
              final isPdf = att.fileType == 'pdf' || att.fileName.toLowerCase().endsWith('.pdf');

              return InkWell(
                onTap: () => _viewAttachmentPreview(att),
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.grey.shade200),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(8),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
                          child: Container(
                            width: double.infinity,
                            color: AppColors.primaryBlue.withAlpha(12),
                            child: isPdf
                                ? const Center(
                                    child: Icon(
                                      Icons.picture_as_pdf_outlined,
                                      size: 48,
                                      color: AppColors.error,
                                    ),
                                  )
                                : Image.network(
                                    att.fileUrl,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) =>
                                        const Center(
                                      child: Icon(
                                        Icons.image_not_supported_outlined,
                                        size: 40,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(10.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              att.fileName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              dateStr,
                              style: const TextStyle(
                                color: Colors.grey,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  void _viewAttachmentPreview(ClinicalAttachment att) {
    final isPdf = att.fileType == 'pdf' || att.fileName.toLowerCase().endsWith('.pdf');
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 700, maxHeight: 600),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AppBar(
                  title: Text(att.fileName, style: const TextStyle(fontSize: 16)),
                  backgroundColor: Colors.white,
                  foregroundColor: AppColors.textPrimary,
                  elevation: 0,
                  automaticallyImplyLeading: false,
                  actions: [
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                Expanded(
                  child: InteractiveViewer(
                    child: isPdf
                        ? const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.picture_as_pdf, size: 64, color: AppColors.error),
                                SizedBox(height: 12),
                                Text('Documento PDF adjunto.'),
                              ],
                            ),
                          )
                        : Image.network(
                            att.fileUrl,
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) =>
                                const Center(child: Text('Error al cargar imagen')),
                          ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _exportFullPatientHistoryPdf() async {
    final patient = _selectedPatient;
    if (patient == null) return;

    try {
      await ClinicalHistoryPdfGenerator.generateAndShow(
        context: context,
        patient: patient,
        notes: _notes,
        appointments: _patientAppointments,
        attachments: _attachments,
      );
    } catch (e) {
      debugPrint('Error generating PDF: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al generar expediente PDF: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }
}
