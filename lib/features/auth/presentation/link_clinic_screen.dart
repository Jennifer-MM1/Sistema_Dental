import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sistema_dental/core/theme/app_colors.dart';
import 'package:sistema_dental/features/auth/providers/auth_providers.dart';

class LinkClinicScreen extends ConsumerStatefulWidget {
  const LinkClinicScreen({super.key});

  @override
  ConsumerState<LinkClinicScreen> createState() => _LinkClinicScreenState();
}

class _LinkClinicScreenState extends ConsumerState<LinkClinicScreen> {
  final _codeController = TextEditingController();
  bool _isScanning = false;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  bool _isLinking = false;

  Future<void> _handleLinkCode() async {
    final code = _codeController.text.trim();
    if (code.isEmpty) return;

    setState(() {
      _isLinking = true;
    });

    final authRepo = ref.read(authRepositoryProvider);
    final role = await authRepo.linkClinicWithCode(code);

    if (!mounted) return;
    setState(() {
      _isLinking = false;
    });

    if (role != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('¡Clínica vinculada con éxito!'),
          backgroundColor: AppColors.success,
        ),
      );

      // Redirigir al panel correspondiente según el rol
      if (role == 'super_admin' || role == 'admin_dentist') {
        context.go('/super_admin');
      } else if (role == 'admin_secretary') {
        context.go('/secretary');
      } else {
        context.go('/patient');
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Código inválido o expirado.'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => context.go('/login'),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(
                Icons.medical_services_outlined,
                size: 64,
                color: AppColors.primaryBlue,
              ),
              const SizedBox(height: 24),
              const Text(
                'Vincular Clínica',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                'Ingresa el código proporcionado por tu dentista o escanea el código QR para asociar tu cuenta a la clínica.',
                style: TextStyle(
                  fontSize: 16,
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),

              // Sección de QR
              Container(
                height: 200,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: AppColors.primaryBlue.withOpacity(0.3), width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primaryBlue.withOpacity(0.05),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: _isScanning
                    ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          CircularProgressIndicator(color: AppColors.primaryBlue),
                          SizedBox(height: 16),
                          Text('Abriendo cámara...', style: TextStyle(color: AppColors.primaryBlue, fontWeight: FontWeight.bold)),
                        ],
                      )
                    : InkWell(
                        borderRadius: BorderRadius.circular(24),
                        onTap: () {
                          setState(() => _isScanning = true);
                          Future.delayed(const Duration(seconds: 2), () {
                            if (mounted) setState(() => _isScanning = false);
                            // Simular escaneo exitoso
                            _codeController.text = 'DENT-123456';
                          });
                        },
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(Icons.qr_code_scanner, size: 64, color: AppColors.primaryBlue),
                            SizedBox(height: 16),
                            Text(
                              'Toca para escanear QR',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primaryBlue,
                              ),
                            ),
                          ],
                        ),
                      ),
              ),

              const SizedBox(height: 32),
              Row(
                children: const [
                  Expanded(child: Divider()),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Text('O INGRESA EL CÓDIGO', style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold)),
                  ),
                  Expanded(child: Divider()),
                ],
              ),
              const SizedBox(height: 32),

              // Campo de Código
              TextField(
                controller: _codeController,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 24, letterSpacing: 4, fontWeight: FontWeight.bold),
                decoration: InputDecoration(
                  hintText: 'X X X - X X X',
                  hintStyle: TextStyle(color: Colors.grey.shade300, letterSpacing: 4),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: AppColors.primaryBlue, width: 2),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Botón Vincular
              ElevatedButton(
                onPressed: _handleLinkCode,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryBlue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                child: _isLinking
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'Vincular Cuenta',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
