import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sistema_dental/core/theme/app_colors.dart';

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
            itemCount: patients.length,
            itemBuilder: (context, index) {
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
                          color: isSelected
                              ? AppColors.primaryBlue
                              : Colors.white,
                          border: Border.all(
                            color: isSelected
                                ? AppColors.primaryBlue
                                : Colors.grey.shade300,
                            width: 2,
                          ),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: AppColors.primaryBlue.withValues(
                                      alpha: 0.3,
                                    ),
                                    blurRadius: 8,
                                    offset: const Offset(0, 4),
                                  ),
                                ]
                              : null,
                        ),
                        child: Center(
                          child: Icon(
                            _getIconForRelationship(patient.relationship),
                            color: isSelected
                                ? Colors.white
                                : Colors.grey.shade500,
                            size: 28,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        patient.firstName,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.normal,
                          color: isSelected
                              ? AppColors.primaryBlue
                              : Colors.grey.shade600,
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
}
