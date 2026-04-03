// lib/ui/widgets/voice_input_button.dart

import 'package:flutter/material.dart';

/// Animated microphone FAB that reflects the current [VoiceInputState].
class VoiceInputButton extends StatelessWidget {
  const VoiceInputButton({
    super.key,
    required this.state,
    required this.onPressed,
  });

  final VoiceInputState state;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: onPressed,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: switch (state) {
            VoiceInputState.idle => colorScheme.primary,
            VoiceInputState.listening => colorScheme.error,
            VoiceInputState.processing => colorScheme.secondary,
          },
          boxShadow: [
            BoxShadow(
              color: colorScheme.primary.withOpacity(0.4),
              blurRadius: state == VoiceInputState.listening ? 16 : 4,
              spreadRadius: state == VoiceInputState.listening ? 4 : 0,
            ),
          ],
        ),
        child: Icon(
          switch (state) {
            VoiceInputState.idle => Icons.mic,
            VoiceInputState.listening => Icons.mic_none,
            VoiceInputState.processing => Icons.hourglass_top,
          },
          color: Colors.white,
          size: 30,
        ),
      ),
    );
  }
}

enum VoiceInputState { idle, listening, processing }
