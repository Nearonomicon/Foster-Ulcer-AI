import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

class AuthGlowBlob extends StatelessWidget {
  const AuthGlowBlob({super.key, required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 260,
      height: 260,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(color: color, blurRadius: 70, spreadRadius: 10),
        ],
      ),
    );
  }
}

class AuthLabeledField extends StatelessWidget {
  const AuthLabeledField({
    super.key,
    required this.label,
    required this.child,
    this.withInsetLabel = false,
  });

  final String label;
  final Widget child;
  final bool withInsetLabel;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final labelText = Text(
      label,
      style: TextStyle(
        fontSize: 11,
        letterSpacing: withInsetLabel ? 1.1 : null,
        fontWeight: FontWeight.w900,
        color: withInsetLabel
            ? (isDark ? Colors.white54 : Colors.black45)
            : null,
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (withInsetLabel)
          Padding(
            padding: const EdgeInsets.only(left: 6),
            child: labelText,
          )
        else
          labelText,
        const Gap(8),
        child,
      ],
    );
  }
}

class AuthBottomIndicator extends StatelessWidget {
  const AuthBottomIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: 120,
      height: 6,
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withOpacity(0.18)
            : Colors.black.withOpacity(0.14),
        borderRadius: BorderRadius.circular(999),
      ),
    );
  }
}
