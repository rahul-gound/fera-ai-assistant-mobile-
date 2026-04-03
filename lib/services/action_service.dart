// lib/services/action_service.dart

import 'package:url_launcher/url_launcher.dart';
import 'package:fera_ai_assistant/models/ai_response.dart';

/// Executes device-level actions such as opening YouTube, making a call,
/// navigating in Maps, etc.
///
/// All actions use [url_launcher] deep-links so no extra permissions are needed
/// beyond those already declared in [AndroidManifest.xml].
class ActionService {
  ActionService._();

  // ---------------------------------------------------------------------------
  // Public API
  // ---------------------------------------------------------------------------

  /// Dispatches [action] with an optional [argument] (e.g. a search query).
  /// Returns a human-readable confirmation string.
  static Future<String> execute(
    AssistantAction action, {
    String? argument,
  }) async {
    switch (action) {
      case AssistantAction.openYoutube:
        return _launch('https://www.youtube.com', 'Opening YouTube…');

      case AssistantAction.searchYoutube:
        final query = argument ?? '';
        final encoded = Uri.encodeQueryComponent(query);
        return _launch(
          'https://www.youtube.com/results?search_query=$encoded',
          'Searching YouTube for "$query"…',
        );

      case AssistantAction.playYoutubeLatest:
        // Opens a YouTube search for the latest video of the requested creator.
        // The user must tap the first result; deep auto-play requires the
        // YouTube Data API.
        final query = (argument?.isNotEmpty == true)
            ? '$argument latest video'
            : 'MrBeast latest video';
        final encoded = Uri.encodeQueryComponent(query);
        return _launch(
          'https://www.youtube.com/results?search_query=$encoded',
          'Searching for the latest video of ${argument ?? "MrBeast"}…',
        );

      case AssistantAction.openWhatsApp:
        return _launch('https://wa.me/', 'Opening WhatsApp…');

      case AssistantAction.openMaps:
        final destination = Uri.encodeQueryComponent(argument ?? '');
        return _launch(
          'https://www.google.com/maps/search/?api=1&query=$destination',
          'Opening Maps for "${argument ?? ''}"…',
        );

      case AssistantAction.openBrowser:
        final url = argument?.startsWith('http') == true
            ? argument!
            : 'https://${argument ?? ''}';
        return _launch(url, 'Opening browser…');

      case AssistantAction.makeCall:
        final number = Uri.encodeComponent(argument ?? '');
        return _launch('tel:$number', 'Calling $argument…');

      case AssistantAction.sendSms:
        final number = Uri.encodeComponent(argument ?? '');
        return _launch('sms:$number', 'Opening SMS to $argument…');

      case AssistantAction.openSettings:
        return _launch('package:com.android.settings', 'Opening settings…');

      case AssistantAction.setAlarm:
        // Android intent deep link for alarm; requires the intent query in
        // AndroidManifest.xml.
        return _launch(
          'intent:#Intent;action=android.intent.action.SET_ALARM;end',
          'Setting alarm…',
        );

      case AssistantAction.other:
        return 'Action not recognised.';
    }
  }

  // ---------------------------------------------------------------------------
  // Private
  // ---------------------------------------------------------------------------

  static Future<String> _launch(String rawUrl, String confirmationText) async {
    final uri = Uri.parse(rawUrl);
    final canLaunch = await canLaunchUrl(uri);
    if (!canLaunch) return 'Could not open "$rawUrl". App may not be installed.';
    await launchUrl(uri, mode: LaunchMode.externalApplication);
    return confirmationText;
  }
}
