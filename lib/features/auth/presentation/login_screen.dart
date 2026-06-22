import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Container(
          width: 400,
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 20,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.medical_services, size: 48, color: Color(0xFF006C9C)),
              const SizedBox(height: 16),
              const Text('DentalSync Connect', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              const Text('Gestión clínica inteligente y profesional', style: TextStyle(color: Colors.grey)),
              const SizedBox(height: 32),
              
              const Text('Selecciona tu rol para ingresar:', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 16),
              
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => context.go('/dentist'),
                  child: const Text('Ingresar como Dentista (Tablet)'),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => context.go('/secretary'),
                  child: const Text('Ingresar como Secretaria (Escritorio)'),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => context.go('/patient'),
                  child: const Text('Ingresar como Paciente (Móvil)'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
