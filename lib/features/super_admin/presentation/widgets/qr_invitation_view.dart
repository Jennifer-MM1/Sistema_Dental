import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sistema_dental/core/theme/app_colors.dart';
import 'package:sistema_dental/core/supabase/supabase_provider.dart';

class QRInvitationView extends ConsumerStatefulWidget {
  const QRInvitationView({super.key});

  @override
  ConsumerState<QRInvitationView> createState() => _QRInvitationViewState();
}

class _QRInvitationViewState extends ConsumerState<QRInvitationView> {
  bool _isLoading = false;

  Future<void> _showTemporalQR() async {
    setState(() => _isLoading = true);
    final client = ref.read(supabaseClientProvider);
    final user = client.auth.currentUser;

    if (user == null) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      // Find clinic
      final membership = await client
          .from('clinic_memberships')
          .select('clinic_id')
          .eq('user_id', user.id)
          .eq('is_active', true)
          .single();
      
      final clinicId = membership['clinic_id'];

      // Generate a code
      final code = _generateAlphanumericCode();
      await client.from('invitation_codes').insert({
        'clinic_id': clinicId,
        'code': code,
        'created_by': user.id,
        'is_used': false,
      });

      setState(() => _isLoading = false);

      if (!mounted) return;

      // Show Dialog
      await showDialog(
        context: context,
        barrierDismissible: false, // Must click close
        builder: (context) => AlertDialog(
          title: const Text('Código Universal', textAlign: TextAlign.center),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Cualquier usuario puede escanear este código.\nSe vinculará a la clínica con el rol que eligió al registrarse.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Container(
                width: 200,
                height: 200,
                color: Colors.grey.shade200,
                child: const Center(
                  child: Icon(Icons.qr_code_2, size: 150, color: AppColors.primaryBlue),
                ),
              ),
              const SizedBox(height: 24),
              const Text('Código manual temporal:', style: TextStyle(color: Colors.grey)),
              const SizedBox(height: 8),
              Text(
                code,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 4,
                  color: AppColors.primaryBlue,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cerrar y Destruir Código'),
            ),
          ],
        ),
      );

      // On Dialog close, destroy code
      await client.from('invitation_codes').delete().eq('code', code);

    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error al generar el código'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  String _generateAlphanumericCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final random = DateTime.now().millisecondsSinceEpoch;
    final buffer = StringBuffer();
    for (var i = 0; i < 8; i++) {
      buffer.write(chars[(random + i * 7) % chars.length]);
    }
    return buffer.toString();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Generar QR Universal', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text(
            'Genera un código efímero para que pacientes o miembros del equipo se vinculen a tu clínica.',
            style: TextStyle(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 32),
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Center(
              child: Column(
                children: [
                  const Icon(Icons.qr_code_scanner, size: 80, color: AppColors.primaryBlue),
                  const SizedBox(height: 16),
                  const Text(
                    'Código Seguro',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'El código generado solo será válido mientras la ventana esté abierta.\nAl cerrarla, el código se autodestruirá.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 24),
                  _isLoading
                      ? const CircularProgressIndicator()
                      : ElevatedButton.icon(
                          onPressed: _showTemporalQR,
                          icon: const Icon(Icons.generating_tokens, color: Colors.white),
                          label: const Text('Mostrar QR', style: TextStyle(color: Colors.white)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryBlue,
                            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
