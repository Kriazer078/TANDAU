import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../theme/app_colors.dart';
import '../widgets/stat_card.dart';
import 'filter_screen.dart';
import 'comparison_screen.dart';
import '../utils/guest_guard.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Premium Header with Mesh-like background
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(24, 80, 24, 40),
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(40),
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.3),
                        width: 2,
                      ),
                    ),
                    child: Image.asset(
                      'assets/images/logo.png',
                      height: 100,
                      errorBuilder: (context, error, stackTrace) => const Icon(
                        Icons.school,
                        size: 80,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    AppLocalizations.of(context)?.appTitle ?? 'TANDAU',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Твой путь к образованию мечты',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.white.withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  const SizedBox(height: 24),
                  // CTA Button
                  _buildPremiumButton(
                    context,
                    label:
                        AppLocalizations.of(context)?.ctaStart ??
                        'Начать подбор',
                    icon: Icons.rocket_launch,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const FilterScreen()),
                    ),
                    isPrimary: true,
                  ),
                  const SizedBox(height: 16),
                  _buildPremiumButton(
                    context,
                    label:
                        AppLocalizations.of(context)?.comparisonTitle ??
                        'Сравнить вузы',
                    icon: Icons.compare_arrows,
                    onTap: () {
                      if (GuestGuard.check(context)) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const ComparisonScreen(),
                          ),
                        );
                      }
                    },
                    isPrimary: false,
                  ),

                  const SizedBox(height: 40),

                  // Stats Grid
                  Row(
                    children: [
                      const Expanded(
                        child: StatCard(
                          icon: Icons.school,
                          value: '120+',
                          label: 'ВУЗов',
                        ),
                      ),
                      const SizedBox(width: 16),
                      const Expanded(
                        child: StatCard(
                          icon: Icons.people,
                          value: '25k+',
                          label: 'Студентов',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Expanded(
                        child: StatCard(
                          icon: Icons.star,
                          value: '4.8',
                          label: 'Рейтинг',
                        ),
                      ),
                      const SizedBox(width: 16),
                      const Expanded(
                        child: StatCard(
                          icon: Icons.workspace_premium,
                          value: '500+',
                          label: 'Специальностей',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPremiumButton(
    BuildContext context, {
    required String label,
    required IconData icon,
    required VoidCallback onTap,
    required bool isPrimary,
  }) {
    return Container(
      width: double.infinity,
      height: 60,
      decoration: BoxDecoration(
        gradient: isPrimary ? AppColors.primaryGradient : null,
        color: isPrimary ? null : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: isPrimary
            ? null
            : Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
        boxShadow: isPrimary
            ? [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: isPrimary ? Colors.white : AppColors.primary,
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                label,
                style: TextStyle(
                  color: isPrimary ? Colors.white : AppColors.primary,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
