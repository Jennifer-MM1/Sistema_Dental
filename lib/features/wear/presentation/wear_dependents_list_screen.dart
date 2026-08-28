import 'package:flutter/material.dart';
import 'package:sistema_dental/features/wear/presentation/wear_shell.dart';

class WearDependentsListScreen extends StatelessWidget {
  final List<String> dependents;

  const WearDependentsListScreen({super.key, required this.dependents});

  @override
  Widget build(BuildContext context) {
    return WearShell(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 190;
          final width = compact ? 158.0 : 190.0;

          return Center(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: SizedBox(
                width: width,
                height: constraints.maxHeight, // Take full height for scrolling
                child: Column(
                  children: [
                    const WearTopBar(showSettings: false),
                    SizedBox(height: compact ? 2 : 4),
                    Row(
                      children: [
                        IconButton(
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          icon: const Icon(
                            Icons.arrow_back_ios_new,
                            color: Color(0xFF78F2C0),
                            size: 14,
                          ),
                          onPressed: () => Navigator.pop(context),
                        ),
                        const Expanded(child: WearTitle('A cargo')),
                        const SizedBox(width: 14), // balance back button
                      ],
                    ),
                    SizedBox(height: compact ? 6 : 8),
                    Expanded(
                      child: dependents.isEmpty
                          ? const Center(
                              child: Text(
                                'No tienes pacientes a cargo.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Color(0xFF8B969E),
                                  fontSize: 10,
                                ),
                              ),
                            )
                          : ListView.separated(
                              physics: const BouncingScrollPhysics(),
                              padding: const EdgeInsets.only(bottom: 20),
                              itemCount: dependents.length,
                              separatorBuilder: (_, _) =>
                                  const SizedBox(height: 6),
                              itemBuilder: (context, index) {
                                return Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF0A0F12),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: const Color(0xFF1C2D35),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(
                                        Icons.person,
                                        color: Color(0xFF008ED1),
                                        size: 14,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          dependents[index],
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
