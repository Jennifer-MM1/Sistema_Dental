import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sistema_dental/core/theme/app_colors.dart';
import 'package:sistema_dental/core/models/clinical_note.dart';
import 'package:sistema_dental/features/dentist/data/clinical_repository.dart';
import 'package:sistema_dental/features/dentist/presentation/widgets/odontogram_widget.dart';
import 'package:sistema_dental/core/models/prescription.dart';
import 'package:sistema_dental/features/shared/data/prescription_pdf_generator.dart';
import 'package:sistema_dental/features/client/data/patient_repository.dart';
import 'package:intl/intl.dart';

/// Vista de Historial Clínico para el panel del paciente (cliente).
/// Permite ver notas clínicas (solo lectura), odontograma y descargar recetas PDF.
class PatientClinicalHistoryView extends ConsumerStatefulWidget {
  const PatientClinicalHistoryView({super.key});

  @override
  ConsumerState<PatientClinicalHistoryView> createState() =>
      _PatientClinicalHistoryViewState();
}

class _PatientClinicalHistoryViewState
    extends ConsumerState<PatientClinicalHistoryView> {
  List<ClinicalNote> _notes = [];
  List<Prescription> _prescriptions = [];
  bool _isLoading = true;
  String _patientName = '';
  String? _patientDob;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    if (mounted) setState(() => _isLoading = true);
    final selectedPatient = ref.read(selectedPatientProvider);
    if (selectedPatient == null) {
      if (mounted) {
        setState(() {
          _notes = [];
          _prescriptions = [];
          _patientName = '';
          _patientDob = null;
          _isLoading = false;
        });
      }
      return;
    }

    _patientName = selectedPatient.fullName;
    _patientDob = selectedPatient.dateOfBirth?.toIso8601String().substring(
      0,
      10,
    );

    final repo = ref.read(clinicalRepositoryProvider);
    _notes = await repo.getNotesForPatient(selectedPatient.id);
    _prescriptions = await repo.getPrescriptionsForPatient(selectedPatient.id);

    if (mounted) setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(selectedPatientProvider, (previous, next) {
      if (previous?.id != next?.id) _loadHistory();
    });

    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primaryBlue),
      );
    }

    if (_notes.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.medical_information_outlined,
                size: 64,
                color: Colors.grey.shade300,
              ),
              const SizedBox(height: 16),
              Text(
                'Sin historial clínico',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade400,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Cuando tu dentista registre consultas, aparecerán aquí.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.grey.shade400),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadHistory,
      color: AppColors.primaryBlue,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _notes.length + 1, // +1 for the header
        itemBuilder: (context, index) {
          if (index == 0) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Row(
                children: [
                  const Icon(
                    Icons.medical_information,
                    color: AppColors.primaryBlue,
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Mi Historial Clínico',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primaryBlue.withAlpha(26),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${_notes.length} consulta${_notes.length > 1 ? 's' : ''}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.primaryBlue,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }

          final note = _notes[index - 1];
          return _buildNoteCard(note);
        },
      ),
    );
  }

  Widget _buildNoteCard(ClinicalNote note) {
    final dateStr = note.createdAt != null
        ? DateFormat('dd/MM/yyyy').format(note.createdAt!)
        : 'Sin fecha';
    
    final doctor = note.doctorName != null ? 'Dr(a). ${note.doctorName}' : 'Doctor no especificado';
    final hasPrescription = _prescriptions.any((p) => p.clinicalNoteId == note.id);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(
          dividerColor: Colors.transparent,
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
        ),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          childrenPadding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.medical_information,
                  color: AppColors.primaryBlue,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      doctor,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      dateStr,
                      style: const TextStyle(color: Colors.grey, fontSize: 14),
                    ),
                  ],
                ),
              ),
              if (hasPrescription)
                Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.description_outlined,
                    color: AppColors.success,
                    size: 16,
                  ),
                ),
            ],
          ),
          children: [
            const Divider(height: 1),
            const SizedBox(height: 16),
            // Fecha y doctor expandido
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primaryBlue.withAlpha(26),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.calendar_today, size: 14, color: AppColors.primaryBlue),
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
                if (note.doctorName != null) ...[
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      'Dr(a). ${note.doctorName}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
                const Spacer(),
                // Botón de receta condicional
                if (hasPrescription)
                  TextButton.icon(
                    onPressed: () => _showPrescription(note),
                    icon: const Icon(Icons.description_outlined, size: 16),
                    label: const Text('Ver receta'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.success,
                      textStyle: const TextStyle(fontSize: 12),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Diagnóstico
            if (note.diagnosis != null && note.diagnosis!.isNotEmpty) ...[
              SizedBox(
                width: double.infinity,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildLabel('Diagnóstico'),
                    const SizedBox(height: 4),
                    Text(note.diagnosis!, style: const TextStyle(fontSize: 14)),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ],

            // Tratamiento
            if (note.treatmentPerformed != null &&
                note.treatmentPerformed!.isNotEmpty) ...[
              SizedBox(
                width: double.infinity,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildLabel('Tratamiento Realizado'),
                    const SizedBox(height: 4),
                    Text(
                      note.treatmentPerformed!,
                      style: const TextStyle(fontSize: 14),
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ],

            // Observaciones
            if (note.observations != null && note.observations!.isNotEmpty) ...[
              SizedBox(
                width: double.infinity,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildLabel('Observaciones'),
                    const SizedBox(height: 4),
                    Text(note.observations!, style: const TextStyle(fontSize: 14)),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ],

            // Dientes
            if (note.toothNumbers.isNotEmpty) ...[
              SizedBox(
                width: double.infinity,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildLabel('Dientes tratados'),
                    const SizedBox(height: 8),
                    OdontogramWidget(
                      selectedTeeth: note.toothNumbers,
                      readOnly: true,
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: AppColors.textSecondary,
      ),
    );
  }

  Future<void> _showPrescription(ClinicalNote note) async {
    if (note.id == null) return;

    final repo = ref.read(clinicalRepositoryProvider);
    final prescription = await repo.getPrescription(note.id!);

    if (prescription == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No hay receta asociada a esta consulta.'),
          ),
        );
      }
      return;
    }

    if (!mounted) return;

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
                          'Mi Receta',
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
                            'Dosis: ${med.dosage} | Cada: ${med.frequency} | Por: ${med.duration}',
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
                    _buildLabel('Indicaciones'),
                    const SizedBox(height: 4),
                    Text(prescription.instructions!),
                  ],

                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        await PrescriptionPdfGenerator.generateAndShow(
                          context: context,
                          prescription: prescription,
                          note: note,
                          patientName: _patientName,
                          patientDob: _patientDob,
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
                      label: const Text('Descargar PDF'),
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
}
