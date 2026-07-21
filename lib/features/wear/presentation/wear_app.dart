import 'package:flutter/material.dart';
import 'package:sistema_dental/features/wear/presentation/wear_alert_screen.dart';
import 'package:sistema_dental/features/wear/presentation/wear_bootstrap_screen.dart';
import 'package:sistema_dental/features/wear/presentation/wear_doctor_screen.dart';
import 'package:sistema_dental/features/wear/presentation/wear_turn_screen.dart';
import 'package:sistema_dental/features/wear/presentation/wear_wait_screen.dart';

class WearDentalSyncApp extends StatelessWidget {
  const WearDentalSyncApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DentalSync Watch',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: Colors.black,
        fontFamily: 'Roboto',
      ),
      home: const WearBootstrapScreen(),
      routes: {
        WearWaitScreen.routeName: (_) => const WearWaitScreen(),
        WearTurnScreen.routeName: (_) => const WearTurnScreen(),
        WearAlertScreen.routeName: (_) => const WearAlertScreen(),
        WearDoctorScreen.routeName: (_) => const WearDoctorScreen(),
      },
    );
  }
}
