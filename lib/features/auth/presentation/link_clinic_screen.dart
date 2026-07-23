import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:sistema_dental/core/theme/app_colors.dart';
import 'package:sistema_dental/features/auth/providers/auth_providers.dart';

class LinkClinicScreen extends ConsumerStatefulWidget {
  final String role;
  const LinkClinicScreen({super.key, required this.role});

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
    final linkedRole = await authRepo.linkClinicWithCode(code);

    if (!mounted) return;
    setState(() {
      _isLinking = false;
    });

    if (linkedRole != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('¡Clínica vinculada con éxito!'),
          backgroundColor: AppColors.success,
        ),
      );

      // Redirigir al panel correspondiente según el rol
      if (linkedRole == 'owner' || linkedRole == 'dentist') {
        context.go('/dentist');
      } else if (linkedRole == 'secretary') {
        context.go('/secretary');
      } else {
        context.go('/client');
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

  Future<void> _scanQr() async {
    setState(() => _isScanning = true);
    final rawValue = await Navigator.of(context).push<String>(
      MaterialPageRoute(builder: (_) => const _InvitationQrScannerPage()),
    );
    if (!mounted) return;
    setState(() => _isScanning = false);
    if (rawValue == null) return;

    final uri = Uri.tryParse(rawValue);
    final code = uri?.queryParameters['code'] ?? rawValue;
    _codeController.text = code.trim();
    await _handleLinkCode();
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
                style: TextStyle(fontSize: 16, color: AppColors.textSecondary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),

              // Sección de QR
              Container(
                height: 200,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: AppColors.primaryBlue.withValues(alpha: 0.3),
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primaryBlue.withValues(alpha: 0.05),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: _isScanning
                    ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          CircularProgressIndicator(
                            color: AppColors.primaryBlue,
                          ),
                          SizedBox(height: 16),
                          Text(
                            'Abriendo cámara...',
                            style: TextStyle(
                              color: AppColors.primaryBlue,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      )
                    : InkWell(
                        borderRadius: BorderRadius.circular(24),
                        onTap: _scanQr,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(
                              Icons.qr_code_scanner,
                              size: 64,
                              color: AppColors.primaryBlue,
                            ),
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
                    child: Text(
                      'O INGRESA EL CÓDIGO',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Expanded(child: Divider()),
                ],
              ),
              const SizedBox(height: 32),

              // Campo de Código
              TextField(
                controller: _codeController,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 24,
                  letterSpacing: 4,
                  fontWeight: FontWeight.bold,
                ),
                decoration: InputDecoration(
                  hintText: 'X X X - X X X',
                  hintStyle: TextStyle(
                    color: Colors.grey.shade300,
                    letterSpacing: 4,
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(
                      color: AppColors.primaryBlue,
                      width: 2,
                    ),
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
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InvitationQrScannerPage extends StatefulWidget {
  const _InvitationQrScannerPage();

  @override
  State<_InvitationQrScannerPage> createState() =>
      _InvitationQrScannerPageState();
}

class _InvitationQrScannerPageState extends State<_InvitationQrScannerPage> {
  final MobileScannerController _controller = MobileScannerController(
    formats: const [BarcodeFormat.qrCode],
  );
  bool _hasResult = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_hasResult) return;
    final value = capture.barcodes
        .map((barcode) => barcode.rawValue)
        .whereType<String>()
        .firstOrNull;
    if (value == null || value.trim().isEmpty) return;

    _hasResult = true;
    await _controller.stop();
    if (mounted) Navigator.pop(context, value);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Escanear invitación'),
        foregroundColor: Colors.white,
        backgroundColor: Colors.black,
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          MobileScanner(controller: _controller, onDetect: _onDetect),
          Center(
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white, width: 3),
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
          const Positioned(
            left: 24,
            right: 24,
            bottom: 48,
            child: Text(
              'Coloca el código QR dentro del recuadro.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }
}
