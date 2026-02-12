import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../widgets/selection_card.dart';

class UserSelectionScreen extends StatelessWidget {
  const UserSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  'Welcome to Care4Elder',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.displaySmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Please select your role to continue',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 64),
                LayoutBuilder(
                  builder: (context, constraints) {
                    if (constraints.maxWidth > 600) {
                      // Desktop/Tablet Layout (Horizontal)
                      return Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Expanded(
                            child: SelectionCard(
                              title: 'Patient',
                              description:
                                  'Access your health records, consult doctors, and get emergency help.',
                              icon: Icons.person_outline_rounded,
                              delayMs: 200,
                              onTap: () {
                                context.go('/patient');
                              },
                            ),
                          ),
                          const SizedBox(width: 32),
                          Expanded(
                            child: SelectionCard(
                              title: 'Doctor',
                              description:
                                  'Manage appointments, view patient records, and provide consultations.',
                              icon: Icons.medical_services_outlined,
                              delayMs: 400,
                              onTap: () {
                                context.go('/doctor/login');
                              },
                            ),
                          ),
                        ],
                      );
                    } else {
                      // Mobile Layout (Vertical)
                      return Column(
                        children: [
                          SelectionCard(
                            title: 'Patient',
                            description:
                                'Access your health records, consult doctors, and get emergency help.',
                            icon: Icons.person_outline_rounded,
                            delayMs: 200,
                            onTap: () {
                              context.go('/patient');
                            },
                          ),
                          const SizedBox(height: 24),
                          SelectionCard(
                            title: 'Doctor',
                            description:
                                'Manage appointments, view patient records, and provide consultations.',
                            icon: Icons.medical_services_outlined,
                            delayMs: 400,
                            onTap: () {
                              context.go('/doctor/login');
                            },
                          ),
                        ],
                      );
                    }
                  },
                ),
                const SizedBox(height: 64),
                Text(
                  'Version 1.0.0',
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant.withOpacity(0.5)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
