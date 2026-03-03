import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../theme/app_colors.dart';
import '../models/university.dart';
import '../l10n/app_localizations.dart';

/// Contact tab for university detail screen.
/// Phone, email, and website are clickable via url_launcher.
/// Includes a stylish map placeholder that opens Google Maps.
class UniversityContactTab extends StatelessWidget {
  final University university;
  final bool isDark;

  const UniversityContactTab({
    super.key,
    required this.university,
    required this.isDark,
  });

  // ── Launch helpers ──────────────────────────────────────

  Future<void> _launchPhone(String phone) async {
    final Uri uri = Uri.parse('tel:$phone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _launchEmail(String email) async {
    final Uri uri = Uri.parse('mailto:$email');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _launchWebsite(String url) async {
    String finalUrl = url;
    if (!finalUrl.startsWith('http://') && !finalUrl.startsWith('https://')) {
      finalUrl = 'https://$finalUrl';
    }
    final Uri uri = Uri.parse(finalUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _launchMaps(String address) async {
    final String encoded = Uri.encodeComponent(address);
    final Uri uri = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=$encoded',
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  // ── Build ───────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final AppLocalizations? l10n = AppLocalizations.of(context);

    final String phone = university.contactPhone.isNotEmpty
        ? university.contactPhone
        : l10n?.detailPhoneNotProvided ?? 'Не указан';

    final String email = university.email.isNotEmpty
        ? university.email
        : l10n?.detailPhoneNotProvided ?? 'Не указан';

    final String website = university.website.isNotEmpty
        ? university.website
        : l10n?.detailWebsiteNotProvided ?? 'Website not provided';

    final bool hasPhone = university.contactPhone.isNotEmpty;
    final bool hasEmail = university.email.isNotEmpty;
    final bool hasWebsite = university.website.isNotEmpty;
    final bool hasAddress = university.address.isNotEmpty;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          // ── Contact card ──
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: isDark ? AppColors.cardDark : Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: isDark
                    ? Colors.white.withAlpha(13)
                    : AppColors.border.withAlpha(128),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(8),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildContactRow(
                  icon: Icons.location_on_rounded,
                  label: l10n?.detailAddressLabel ?? 'Адрес',
                  data: university.address,
                  isClickable: hasAddress,
                  onTap:
                      hasAddress ? () => _launchMaps(university.address) : null,
                ),
                const _ContactDivider(),
                _buildContactRow(
                  icon: Icons.language_rounded,
                  label: l10n?.detailWebsiteLabel ?? 'Сайт',
                  data: website,
                  isClickable: hasWebsite,
                  onTap: hasWebsite
                      ? () => _launchWebsite(university.website)
                      : null,
                ),
                const _ContactDivider(),
                _buildContactRow(
                  icon: Icons.phone_rounded,
                  label: l10n?.detailPhoneLabelFull ?? 'Телефон',
                  data: phone,
                  isClickable: hasPhone,
                  onTap: hasPhone
                      ? () => _launchPhone(university.contactPhone)
                      : null,
                ),
                const _ContactDivider(),
                _buildContactRow(
                  icon: Icons.email_rounded,
                  label: 'Email',
                  data: email,
                  isClickable: hasEmail,
                  onTap: hasEmail ? () => _launchEmail(university.email) : null,
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // ── Map placeholder card ──
          if (hasAddress) _buildMapPlaceholder(context),
        ],
      ),
    );
  }

  // ── Contact row ─────────────────────────────────────────

  Widget _buildContactRow({
    required IconData icon,
    required String label,
    required String data,
    bool isClickable = false,
    VoidCallback? onTap,
  }) {
    final Widget content = Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.primary.withAlpha(25),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: AppColors.primary, size: 20),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                data,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                  color: isClickable ? AppColors.primary : null,
                  decoration: isClickable
                      ? TextDecoration.underline
                      : TextDecoration.none,
                  decorationColor: isClickable ? AppColors.primary : null,
                ),
              ),
            ],
          ),
        ),
        if (isClickable)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Icon(
              Icons.open_in_new_rounded,
              size: 16,
              color: AppColors.primary.withAlpha(150),
            ),
          ),
      ],
    );

    if (!isClickable || onTap == null) return content;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        splashColor: AppColors.primary.withAlpha(20),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: content,
        ),
      ),
    );
  }

  // ── Map placeholder ─────────────────────────────────────

  Widget _buildMapPlaceholder(BuildContext context) {
    final AppLocalizations? l10n = AppLocalizations.of(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _launchMaps(university.address),
        borderRadius: BorderRadius.circular(24),
        child: Container(
          width: double.infinity,
          height: 180,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: LinearGradient(
              colors: isDark
                  ? [const Color(0xFF1E293B), const Color(0xFF0F172A)]
                  : [const Color(0xFFE0F2FE), const Color(0xFFBAE6FD)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            border: Border.all(
              color: isDark
                  ? Colors.white.withAlpha(13)
                  : AppColors.primary.withAlpha(40),
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withAlpha(isDark ? 15 : 25),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Stack(
            children: [
              // Grid lines (decorative)
              ..._buildGridLines(),

              // Center pin icon
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withAlpha(30),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.location_on_rounded,
                        color: AppColors.primary,
                        size: 36,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Text(
                        university.address,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color:
                              isDark ? Colors.white70 : AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // "Open in Maps" badge
              Positioned(
                bottom: 12,
                right: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withAlpha(80),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.map_rounded,
                        color: Colors.white,
                        size: 14,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        l10n?.detailAddressLabel ?? 'Открыть карту',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Generates decorative grid lines for the map placeholder.
  List<Widget> _buildGridLines() {
    final Color lineColor =
        isDark ? Colors.white.withAlpha(8) : AppColors.primary.withAlpha(15);

    return [
      for (double top in [40, 80, 120])
        Positioned(
          top: top,
          left: 0,
          right: 0,
          child: Container(height: 1, color: lineColor),
        ),
      for (double left in [60, 130, 200, 270, 340])
        Positioned(
          top: 0,
          bottom: 0,
          left: left,
          child: Container(width: 1, color: lineColor),
        ),
    ];
  }
}

/// Small divider used between contact rows.
class _ContactDivider extends StatelessWidget {
  const _ContactDivider();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 16),
      child: Divider(height: 1),
    );
  }
}
