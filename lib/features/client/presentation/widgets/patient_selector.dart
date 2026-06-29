import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sistema_dental/core/models/patient.dart';
import 'package:sistema_dental/core/theme/app_colors.dart';
import 'package:sistema_dental/features/auth/providers/auth_providers.dart';
import 'package:sistema_dental/features/client/data/patient_repository.dart';

class PatientSelector extends ConsumerWidget {
  const PatientSelector({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final patientsAsync = ref.watch(familyPatientsProvider);
    final selectedPatient = ref.watch(selectedPatientProvider);

    return patientsAsync.when(
      data: (patients) {
        if (patients.isEmpty) {
          return const SizedBox.shrink();
        }

        // Si no hay paciente seleccionado, seleccionamos el primero por defecto
        if (selectedPatient == null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            ref.read(selectedPatientProvider.notifier).select(patients.first);
          });
          return const SizedBox.shrink();
        }

        return Container(
          height: 100,
          margin: const EdgeInsets.only(bottom: 24),
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: patients.length + 1, // +1 para el botón de "Añadir"
            itemBuilder: (context, index) {
              if (index == patients.length) {
                return _buildAddPatientButton(context, ref);
              }

              final patient = patients[index];
              final isSelected = patient.id == selectedPatient.id;

              return GestureDetector(
                onTap: () {
                  ref.read(selectedPatientProvider.notifier).select(patient);
                },
                child: Container(
                  margin: const EdgeInsets.only(right: 16),
                  width: 80,
                  child: Column(
                    children: [
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isSelected ? AppColors.primaryBlue : Colors.white,
                          border: Border.all(
                            color: isSelected ? AppColors.primaryBlue : Colors.grey.shade300,
                            width: 2,
                          ),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: AppColors.primaryBlue.withValues(alpha: 0.3),
                                    blurRadius: 8,
                                    offset: const Offset(0, 4),
                                  )
                                ]
                              : null,
                        ),
                        child: Center(
                          child: Icon(
                            _getIconForRelationship(patient.relationship),
                            color: isSelected ? Colors.white : Colors.grey.shade500,
                            size: 28,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        patient.firstName,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          color: isSelected ? AppColors.primaryBlue : Colors.grey.shade600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, st) => const Text('Error al cargar familiares'),
    );
  }

  IconData _getIconForRelationship(String relationship) {
    switch (relationship) {
      case 'child':
        return Icons.child_care;
      case 'spouse':
        return Icons.favorite;
      case 'parent':
        return Icons.elderly;
      default:
        return Icons.person;
    }
  }

  Widget _buildAddPatientButton(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: () {
        showDialog(
          context: context,
          builder: (context) => const _AddFamilyMemberDialog(),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(right: 16),
        width: 80,
        child: Column(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.grey.shade100,
                border: Border.all(
                  color: Colors.grey.shade300,
                  style: BorderStyle.solid,
                  width: 2,
                ),
              ),
              child: Center(
                child: Icon(
                  Icons.add,
                  color: Colors.grey.shade500,
                  size: 28,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Añadir',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _AddFamilyMemberDialog extends ConsumerStatefulWidget {
  const _AddFamilyMemberDialog();

  @override
  ConsumerState<_AddFamilyMemberDialog> createState() => _AddFamilyMemberDialogState();
}

class _AddFamilyMemberDialogState extends ConsumerState<_AddFamilyMemberDialog> {
  final _formKey = GlobalKey<FormState>();
  String _firstName = '';
  String _lastName = '';
  String _relationship = 'child';
  bool _isLoading = false;

  final List<String> _relationships = ['child', 'spouse', 'parent', 'other'];
  
  String _translateRelationship(String rel) {
    switch (rel) {
      case 'child': return 'Hijo/a';
      case 'spouse': return 'Cónyuge';
      case 'parent': return 'Padre/Madre';
      case 'other': return 'Otro';
      default: return rel;
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();
    
    setState(() => _isLoading = true);

    final currentUser = ref.read(currentUserProvider).value;
    if (currentUser == null) {
      setState(() => _isLoading = false);
      return;
    }

    final repo = ref.read(patientRepositoryProvider);
    final patient = await repo.createPatient(
      profileId: currentUser.id,
      firstName: _firstName,
      lastName: _lastName,
      relationship: _relationship,
    );

    setState(() => _isLoading = false);

    if (patient != null && mounted) {
      ref.invalidate(familyPatientsProvider);
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Familiar añadido con éxito'), backgroundColor: AppColors.success),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error al añadir familiar'), backgroundColor: AppColors.error),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Añadir Familiar'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              decoration: const InputDecoration(labelText: 'Nombre', border: OutlineInputBorder()),
              validator: (val) => val == null || val.isEmpty ? 'Requerido' : null,
              onSaved: (val) => _firstName = val!.trim(),
            ),
            const SizedBox(height: 16),
            TextFormField(
              decoration: const InputDecoration(labelText: 'Apellido', border: OutlineInputBorder()),
              validator: (val) => val == null || val.isEmpty ? 'Requerido' : null,
              onSaved: (val) => _lastName = val!.trim(),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _relationship,
              decoration: const InputDecoration(labelText: 'Parentesco', border: OutlineInputBorder()),
              items: _relationships.map((rel) {
                return DropdownMenuItem(value: rel, child: Text(_translateRelationship(rel)));
              }).toList(),
              onChanged: (val) {
                if (val != null) setState(() => _relationship = val);
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _submit,
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryBlue, foregroundColor: Colors.white),
          child: _isLoading ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Text('Guardar'),
        ),
      ],
    );
  }
}
