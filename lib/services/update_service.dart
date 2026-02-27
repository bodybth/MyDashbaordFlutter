import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class UpdateService {
  static const _owner = 'bodybth';
  static const _repo  = 'MyDashboardFlutter';

  static const _releasesApiUrl =
      'https://api.github.com/repos/$_owner/$_repo/releases/latest';
  static const _releasesPageUrl =
      'https://github.com/$_owner/$_repo/releases/latest';

  /// Checks GitHub for a newer release.
  ///
  /// Returns the latest tag string (e.g. "250227035") if a newer build exists,
  /// or null if the app is already up-to-date / offline / any error.
  ///
  /// How it works:
  ///   1. Reads the device's actual versionCode via package_info_plus (buildNumber).
  ///      This is always the real installed value — no hardcoded strings to maintain.
  ///   2. Fetches the latest GitHub release tag (e.g. "v250227035").
  ///   3. Strips the leading "v" and parses as integer.
  ///   4. If GitHub's code > installed code → update available.
  ///   5. Any failure (offline, parse error, HTTP error) → returns null silently.
  static Future<String?> checkForUpdate() async {
    try {
      // ── Step 1: get installed versionCode ──────────────────────
      final info = await PackageInfo.fromPlatform();
      // buildNumber is what Flutter maps from versionCode (the +N part of pubspec version,
      // which CI sets to the same YYMMDDRRR integer).
      final installedCode = int.tryParse(info.buildNumber) ?? 0;

      // ── Step 2: connectivity check ──────────────────────────────
      final lookup = await InternetAddress.lookup('api.github.com')
          .timeout(const Duration(seconds: 4));
      if (lookup.isEmpty || lookup.first.rawAddress.isEmpty) return null;

      // ── Step 3: fetch latest release ───────────────────────────
      final response = await http
          .get(Uri.parse(_releasesApiUrl),
              headers: {'Accept': 'application/vnd.github+json'})
          .timeout(const Duration(seconds: 8));
      if (response.statusCode != 200) return null;

      final json     = jsonDecode(response.body) as Map<String, dynamic>;
      final rawTag   = (json['tag_name'] as String? ?? '').replaceFirst('v', '');
      if (rawTag.isEmpty) return null;

      // ── Step 4: compare as integers ────────────────────────────
      final latestCode = int.tryParse(rawTag) ?? 0;
      if (latestCode > installedCode) return rawTag; // newer build exists
      return null;

    } catch (_) {
      // Offline, timeout, JSON error — never block the user
      return null;
    }
  }

  /// Opens the GitHub Releases page in the device browser.
  static Future<void> openReleasesPage() async {
    final uri = Uri.parse(_releasesPageUrl);
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (_) {}
  }
}
