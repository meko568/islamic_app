import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:flutter/foundation.dart';

class UpdateCheckResult {
  final bool hasUpdate;
  final String? latestVersion;
  final String? downloadUrl;
  final bool forceUpdate;
  final String? changelog;

  UpdateCheckResult({
    required this.hasUpdate,
    this.latestVersion,
    this.downloadUrl,
    this.forceUpdate = false,
    this.changelog,
  });
}

class UpdateCheckService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<UpdateCheckResult> checkForUpdate() async {
    try {
      final PackageInfo packageInfo = await PackageInfo.fromPlatform();
      // current build number (int)
      final int currentBuildNumber = int.tryParse(packageInfo.buildNumber) ?? 0;

      final doc = await _firestore.collection('app_config').doc('update_info').get();

      if (!doc.exists) {
        return UpdateCheckResult(hasUpdate: false);
      }

      final data = doc.data()!;
      final int latestBuildNumber = data['latest_build_number'] ?? 0;
      final String? latestVersion = data['latest_version'];
      final String? downloadUrl = data['download_url'];
      final bool forceUpdate = data['force_update'] ?? false;
      final String? changelog = data['changelog'];

      if (latestBuildNumber > currentBuildNumber) {
        return UpdateCheckResult(
          hasUpdate: true,
          latestVersion: latestVersion,
          downloadUrl: downloadUrl,
          forceUpdate: forceUpdate,
          changelog: changelog,
        );
      }
    } catch (e) {
      debugPrint('Error checking for update: $e');
    }

    return UpdateCheckResult(hasUpdate: false);
  }
}
