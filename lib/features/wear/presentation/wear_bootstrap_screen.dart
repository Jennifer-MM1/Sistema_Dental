import 'package:flutter/material.dart';
import 'package:sistema_dental/core/wear/wear_link_service.dart';
import 'package:sistema_dental/features/wear/data/wear_data_service.dart';
import 'package:sistema_dental/features/wear/presentation/wear_doctor_screen.dart';
import 'package:sistema_dental/features/wear/presentation/wear_linked_empty_screen.dart';
import 'package:sistema_dental/features/wear/presentation/wear_link_waiting_screen.dart';
import 'package:sistema_dental/features/wear/presentation/wear_shell.dart';
import 'package:sistema_dental/features/wear/presentation/wear_wait_screen.dart';

enum _WearBootstrapState { waitingForLink, linkedWithoutActiveTurn, ready }

class _WearBootstrapResult {
  final _WearBootstrapState state;
  final WearStartupData? data;
  final WearPatientSummaryData? summary;

  const _WearBootstrapResult(this.state, [this.data, this.summary]);
}

class WearBootstrapScreen extends StatelessWidget {
  const WearBootstrapScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_WearBootstrapResult>(
      future: _loadData(),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const WearShell(
            child: Center(
              child: CircularProgressIndicator(color: Color(0xFF78F2C0)),
            ),
          );
        }

        final result = snapshot.data;
        if (result == null ||
            result.state == _WearBootstrapState.waitingForLink) {
          return const WearLinkWaitingScreen();
        }

        if (result.state == _WearBootstrapState.linkedWithoutActiveTurn) {
          return WearLinkedEmptyScreen(summary: result.summary);
        }

        final data = result.data!;
        if (data.role == WearRole.dentist) {
          return WearDoctorScreen(data: data.doctor!, isDemo: false);
        }

        return WearWaitScreen(data: data.patient!, isDemo: false);
      },
    );
  }

  Future<_WearBootstrapResult> _loadData() async {
    try {
      final data = await WearLinkService.instance.readCompanionState();
      if (data == null || !data.isLinked) {
        return const _WearBootstrapResult(_WearBootstrapState.waitingForLink);
      }

      if (data.role == WearRole.dentist) {
        if (data.doctor == null) {
          return _WearBootstrapResult(
            _WearBootstrapState.linkedWithoutActiveTurn,
            null,
            data.summary,
          );
        }
      } else if (data.patient == null) {
        return _WearBootstrapResult(
          _WearBootstrapState.linkedWithoutActiveTurn,
          null,
          data.summary,
        );
      }

      return _WearBootstrapResult(_WearBootstrapState.ready, data);
    } catch (e) {
      debugPrint('[Wear] Error bootstrapping watch: $e');
      return const _WearBootstrapResult(_WearBootstrapState.waitingForLink);
    }
  }
}
