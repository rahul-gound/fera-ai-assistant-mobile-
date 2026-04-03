// lib/ui/widgets/language_selector.dart

import 'package:flutter/material.dart';
import 'package:fera_ai_assistant/utils/constants.dart';

/// A dropdown widget for switching between the 22 supported Indian languages.
class LanguageSelector extends StatelessWidget {
  const LanguageSelector({
    super.key,
    required this.currentLocale,
    required this.onLocaleChanged,
  });

  final String currentLocale;
  final ValueChanged<String> onLocaleChanged;

  @override
  Widget build(BuildContext context) {
    final languages = AppConstants.supportedLanguages;
    final currentName = languages.entries
        .firstWhere(
          (e) => e.value == currentLocale,
          orElse: () => const MapEntry('Hindi', 'hi-IN'),
        )
        .key;

    return DropdownButton<String>(
      value: currentName,
      underline: const SizedBox.shrink(),
      icon: const Icon(Icons.language, size: 20),
      items: languages.keys
          .map(
            (name) => DropdownMenuItem(
              value: name,
              child: Text(name, style: const TextStyle(fontSize: 14)),
            ),
          )
          .toList(),
      onChanged: (name) {
        if (name != null) {
          final locale = languages[name]!;
          onLocaleChanged(locale);
        }
      },
    );
  }
}
