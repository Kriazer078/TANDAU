import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import '../services/auth_service.dart';
import '../services/revenuecat_service.dart';

class PaywallScreen extends StatefulWidget {
  const PaywallScreen({super.key});

  @override
  State<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends State<PaywallScreen> {
  bool _isLoading = false;
  List<Package> _packages = [];

  @override
  void initState() {
    super.initState();
    _fetchOfferings();
  }

  Future<void> _fetchOfferings() async {
    final packages = await RevenueCatService().getOfferings();
    if (mounted) {
      setState(() {
        _packages = packages;
      });
    }
  }

  Future<void> _purchasePlan(String plan, int initialTokens) async {
    setState(() => _isLoading = true);

    try {
      // ПРОВЕРКА REVENUECAT: Если мы смогли вытащить реальные товары из магазина (Google Play/AppStore)
      if (_packages.isNotEmpty) {
        // Берем первый доступный пакет (для PRO плана)
        final packageToBuy = _packages.first;
        final isPro = await RevenueCatService().makePurchase(packageToBuy);

        if (isPro) {
          // Если RevenueCat подтвердил оплату, обновляем статус в нашей базе Firebase
          await AuthService().updateSubscriptionPlan('pro', 100);
          _showSuccessAndPop(plan);
        } else {
          _showError('Покупка отменена или произошла ошибка.');
        }
      } else {
        // --------------------------------------------------------------------------
        // FALLBACK (ЗАГЛУШКА): Пока ты не создал товары в Google Play Console,
        // RevenueCat будет возвращать 0 пакетов. Поэтому здесь мы оставляем эмуляцию
        // покупки, чтобы ты мог тестировать Алгоритм 4-х вузов уже сейчас!
        // --------------------------------------------------------------------------
        debugPrint(
          'RevenueCat: Пакеты не найдены. Использую тестовую заглушку покупки.',
        );
        await Future.delayed(const Duration(seconds: 2));
        final success = await AuthService().updateSubscriptionPlan(
          plan,
          initialTokens,
        );

        if (success) {
          _showSuccessAndPop(plan);
        } else {
          _showError('Ошибка при обновлении подписки в базе');
        }
      }
    } catch (e) {
      _showError('Произошла непредвиденная ошибка: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showSuccessAndPop(String plan) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Успешно! Ваш план изменен на ${plan.toUpperCase()}'),
        backgroundColor: Colors.green,
      ),
    );
    Navigator.pop(context);
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D12),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'TANDAU+',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 24,
            letterSpacing: 1.2,
          ),
        ),
        centerTitle: true,
      ),
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          // Background blobs
          Positioned(
            top: -100,
            right: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF4A00E0).withValues(alpha: 0.3),
              ),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 50, sigmaY: 50),
                child: Container(color: Colors.transparent),
              ),
            ),
          ),
          Positioned(
            bottom: -50,
            left: -100,
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF8E2DE2).withValues(alpha: 0.3),
              ),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 50, sigmaY: 50),
                child: Container(color: Colors.transparent),
              ),
            ),
          ),

          SafeArea(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      color: Colors.deepPurpleAccent,
                    ),
                  )
                : SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 20,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text(
                          'Раскройте свой\nпотенциал на максимум',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Выберите план, который подходит именно вам, и поступите на грант с уверенностью.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 16,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 32),

                        // FREE Plan
                        _buildPlanCard(
                          title: 'TANDAU Basic',
                          price: 'Бесплатно',
                          features: [
                            '5 ИИ-запросов в день',
                            'Базовая оценка шансов',
                            'Доступ к базе университетов',
                          ],
                          buttonText: 'Ваш текущий план',
                          buttonColor: Colors.white12,
                          textColor: Colors.white54,
                          onTap: null, // Disabled
                        ),
                        const SizedBox(height: 20),

                        // PRO Plan (Highlighted)
                        _buildPlanCard(
                          title: 'TANDAU PRO',
                          price: '1 990 ₸ / месяц',
                          subtitle: 'Идеально для 11-классников',
                          isPopular: true,
                          features: [
                            '100 ИИ-запросов в день',
                            'Генератор стратегии (Алгоритм 4-х вузов) 🔥',
                            'Детализированная оценка шансов',
                            'Приоритетный доступ',
                          ],
                          buttonText: 'Выбрать PRO',
                          buttonColor: const Color(0xFF8E2DE2),
                          textColor: Colors.white,
                          gradient: const LinearGradient(
                            colors: [Color(0xFF8E2DE2), Color(0xFF4A00E0)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          onTap: () => _purchasePlan('pro', 100),
                        ),
                        const SizedBox(height: 20),

                        // PREMIUM Plan
                        _buildPlanCard(
                          title: 'TANDAU Premium',
                          price: '2 990 ₸ / месяц',
                          features: [
                            'Безлимитные ИИ-запросы ♾️',
                            'Генератор стратегии (Алгоритм 4-х вузов) 🔥',
                            'Аналитика для родителей',
                            'Персональная поддержка',
                          ],
                          buttonText: 'Выбрать Premium',
                          buttonColor: Colors.amber.shade700,
                          textColor: Colors.white,
                          borderColor: Colors.amber.shade700.withValues(
                            alpha: 0.5,
                          ),
                          onTap: () => _purchasePlan('premium', 9999),
                        ),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlanCard({
    required String title,
    required String price,
    String? subtitle,
    required List<String> features,
    required String buttonText,
    required Color buttonColor,
    required Color textColor,
    Gradient? gradient,
    Color? borderColor,
    bool isPopular = false,
    VoidCallback? onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: gradient == null ? Colors.white.withValues(alpha: 0.05) : null,
        gradient: gradient,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color:
              borderColor ?? (isPopular ? Colors.transparent : Colors.white10),
          width: 2,
        ),
        boxShadow: isPopular
            ? [
                BoxShadow(
                  color: const Color(0xFF8E2DE2).withValues(alpha: 0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ]
            : null,
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          if (isPopular)
            Positioned(
              top: -12,
              right: 24,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.amber,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'ХИТ!',
                  style: TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  price,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                ],
                const SizedBox(height: 24),
                // Features
                ...features.map(
                  (feature) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      children: [
                        Icon(
                          Icons.check_circle_rounded,
                          color: isPopular
                              ? Colors.white
                              : const Color(0xFF8E2DE2),
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            feature,
                            style: TextStyle(
                              color: isPopular ? Colors.white : Colors.white70,
                              fontSize: 15,
                              fontWeight: feature.contains('🔥')
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: onTap,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: buttonColor,
                      foregroundColor: textColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: isPopular ? 8 : 0,
                    ),
                    child: Text(
                      buttonText,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
