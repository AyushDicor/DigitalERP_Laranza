// Shared visual language for the profile module — kept in one place so the
// overview and every section page stay identical.

import 'package:digitalerp/utils/app_constant_new.dart';
import 'package:flutter/material.dart';

const Color profileBgColor = Color(0xFFF0F2F8);
const Color profileValueColor = Color(0xFF1A1D2E);
const Color profileSubtleColor = Color(0xFF8A94B2);
const Color profileHintColor = Color(0xFFBCC4D8);
const Color profileBorderColor = Color(0xFFE2E8F5);
const Color profileInputFill = Color(0xFFFAFBFF);
const Color profileReadOnlyFill = Color(0xFFF5F6FA);
const Color profileAccentColor = Color(0xFF1C2B6A);

/// White rounded card used for every group of fields.
class ProfileCard extends StatelessWidget {
  const ProfileCard({super.key, required this.child, this.padding});

  final Widget child;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding ?? const EdgeInsets.fromLTRB(18, 20, 18, 22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: purpleColor.withValues(alpha: 0.06),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }
}

/// Accent bar + label used above a group of fields.
class ProfileGroupTitle extends StatelessWidget {
  const ProfileGroupTitle(this.label, {super.key});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 16,
          decoration: BoxDecoration(
            color: purpleColor,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: purpleColor,
            letterSpacing: 0.2,
          ),
        ),
      ],
    );
  }
}

/// Small uppercase-ish label above a value or input.
class ProfileFieldLabel extends StatelessWidget {
  const ProfileFieldLabel({
    super.key,
    required this.label,
    this.showReadOnlyBadge = false,
  });

  final String label;
  final bool showReadOnlyBadge;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Flexible(
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: profileSubtleColor,
              letterSpacing: 0.4,
            ),
          ),
        ),
        if (showReadOnlyBadge) ...[
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
            decoration: BoxDecoration(
              color: profileAccentColor.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Text(
              'READ ONLY',
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w700,
                color: profileAccentColor,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

InputDecoration profileInputDecoration({required String hint, Widget? prefix}) {
  return InputDecoration(
    hintText: hint,
    prefixIcon: prefix,
    hintStyle: const TextStyle(fontSize: 14, color: profileHintColor),
    filled: true,
    fillColor: profileInputFill,
    contentPadding:
        const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: profileBorderColor, width: 1.5),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: profileAccentColor, width: 1.8),
    ),
    disabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Color(0xFFEEF0F7), width: 1.5),
    ),
  );
}
