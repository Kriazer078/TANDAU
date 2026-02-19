import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme/app_colors.dart'; // Import AppColors

class UpdateDialog extends StatelessWidget {
  final bool isForceUpdate;
  final String storeUrl;

  const UpdateDialog({
    super.key,
    required this.isForceUpdate,
    required this.storeUrl,
  });

  @override
  Widget build(BuildContext context) {
    // PopScope replaces WillPopScope
    // canPop: false means "prevent back button"
    // We want to prevent pop ONLY if it is a force update.
    // So canPop should be !isForceUpdate.
    return PopScope(
      canPop: !isForceUpdate,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        // logic if pop was blocked (optional)
      },
      child: AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Update Available',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Text(
          isForceUpdate
              ? 'A critical update requires you to update the app to continue using it.'
              : 'A new version of TANDAU is available. Would you like to update now?',
        ),
        actions: [
          if (!isForceUpdate)
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Later'),
            ),
          ElevatedButton(
            onPressed: () async {
              final Uri url = Uri.parse(storeUrl);
              if (await canLaunchUrl(url)) {
                await launchUrl(url, mode: LaunchMode.externalApplication);
              } else {
                debugPrint('Could not launch $storeUrl');
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors
                  .primary, // Use AppColors directly or Theme.of(context).primaryColor
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text('Update Now'),
          ),
        ],
      ),
    );
  }
}
