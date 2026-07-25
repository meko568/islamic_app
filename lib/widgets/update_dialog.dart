import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:provider/provider.dart';
import '../l10n/app_strings.dart';
import '../providers/settings_provider.dart';
import '../services/update_check_service.dart';

class UpdateDialog extends StatelessWidget {
  final UpdateCheckResult updateInfo;

  const UpdateDialog({super.key, required this.updateInfo});

  Future<void> _launchUpdateUrl() async {
    if (updateInfo.downloadUrl == null) return;
    final url = Uri.parse(updateInfo.downloadUrl!);
    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      debugPrint('Could not launch update URL: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.read<SettingsProvider>().appLanguage;
    final isForceUpdate = updateInfo.forceUpdate;

    return PopScope(
      canPop: !isForceUpdate,
      child: AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          AppStrings.get('update_available', lang),
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (updateInfo.latestVersion != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  AppStrings.get(
                    'new_version_available',
                    lang,
                    params: {'version': updateInfo.latestVersion!},
                  ),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            if (updateInfo.changelog != null && updateInfo.changelog!.isNotEmpty)
              Container(
                width: double.maxFinite,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      updateInfo.changelog!,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
          ],
        ),
        actions: [
          if (!isForceUpdate)
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                AppStrings.get('later', lang),
                style: TextStyle(color: Theme.of(context).colorScheme.secondary),
              ),
            ),
          ElevatedButton(
            onPressed: _launchUpdateUrl,
            child: Text(AppStrings.get('update_now', lang)),
          ),
        ],
        actionsAlignment: MainAxisAlignment.spaceEvenly,
        actionsPadding: const EdgeInsets.only(bottom: 16, left: 8, right: 8),
      ),
    );
  }
}
