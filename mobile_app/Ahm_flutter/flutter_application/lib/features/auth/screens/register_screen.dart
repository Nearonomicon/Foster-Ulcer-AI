import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

import 'package:flutter_application/shared/app_localizations.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final fullNameCtrl = TextEditingController();
  final licenseCtrl = TextEditingController();
  final hospitalCtrl = TextEditingController();

  String specialty = "";
  bool agree = false;

  @override
  void dispose() {
    fullNameCtrl.dispose();
    licenseCtrl.dispose();
    hospitalCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // dropdown items
    final specialtyItems = <DropdownMenuItem<String>>[
      DropdownMenuItem(value: "", child: Text(context.tr('register.specialty.select'))),
      DropdownMenuItem(value: "dermatology", child: Text(context.tr('register.specialty.dermatology'))),
      DropdownMenuItem(value: "vascular", child: Text(context.tr('register.specialty.vascular'))),
      DropdownMenuItem(value: "wound_care", child: Text(context.tr('register.specialty.wound_care'))),
      DropdownMenuItem(value: "endocrinology", child: Text(context.tr('register.specialty.endocrinology'))),
      DropdownMenuItem(value: "internal_medicine", child: Text(context.tr('register.specialty.internal_medicine'))),
    ];

    return Scaffold(
      body: Stack(
        children: [
          Positioned(top: -96, right: -96, child: _GlowBlob(color: cs.primary.withOpacity(0.06))),
          Positioned(bottom: -96, left: -96, child: _GlowBlob(color: cs.primary.withOpacity(0.06))),

          SafeArea(
            child: Column(
              children: [
                // top bar (with back)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.arrow_back_ios_new, size: 18),
                      ),
                    ],
                  ),
                ),

                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 380),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            const Gap(8),
                            _Header(
                              primary: cs.primary,
                              title: context.tr('register.header.title'),
                              subtitle: context.tr('register.header.subtitle'),
                            ),
                            const Gap(18),

                            _AvatarPicker(
                              primary: cs.primary,
                              label: context.tr('register.avatar.label'),
                            ),
                            const Gap(18),

                            _LabeledField(
                              label: context.tr('register.full_name.label'),
                              child: TextField(
                                controller: fullNameCtrl,
                                decoration: InputDecoration(
                                  hintText: context.tr('register.full_name.hint'),
                                  prefixIcon: const Padding(
                                    padding: EdgeInsets.only(left: 8),
                                    child: Icon(Icons.person_outline),
                                  ),
                                  prefixIconConstraints: const BoxConstraints(minWidth: 48),
                                ),
                              ),
                            ),
                            const Gap(14),

                            _LabeledField(
                              label: context.tr('register.license.label'),
                              child: TextField(
                                controller: licenseCtrl,
                                decoration: InputDecoration(
                                  hintText: context.tr('register.license.hint'),
                                  prefixIcon: const Padding(
                                    padding: EdgeInsets.only(left: 8),
                                    child: Icon(Icons.verified_user_outlined),
                                  ),
                                  prefixIconConstraints: const BoxConstraints(minWidth: 48),
                                ),
                              ),
                            ),
                            const Gap(14),

                            _LabeledField(
                              label: context.tr('register.specialty.label'),
                              child: DropdownButtonFormField<String>(
                                value: specialty.isEmpty ? null : specialty,
                                items: specialtyItems,
                                onChanged: (v) => setState(() => specialty = v ?? ""),
                                decoration: const InputDecoration(
                                  prefixIcon: Padding(
                                    padding: EdgeInsets.only(left: 8),
                                    child: Icon(Icons.medical_services_outlined),
                                  ),
                                  prefixIconConstraints: BoxConstraints(minWidth: 48),
                                ),
                                icon: const Icon(Icons.expand_more),
                              ),
                            ),
                            const Gap(14),

                            _LabeledField(
                              label: context.tr('register.hospital.label'),
                              child: TextField(
                                controller: hospitalCtrl,
                                decoration: InputDecoration(
                                  hintText: context.tr('register.hospital.hint'),
                                  prefixIcon: const Padding(
                                    padding: EdgeInsets.only(left: 8),
                                    child: Icon(Icons.apartment_outlined),
                                  ),
                                  prefixIconConstraints: const BoxConstraints(minWidth: 48),
                                ),
                              ),
                            ),

                            const Gap(14),

                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Transform.translate(
                                  offset: const Offset(0, 2),
                                  child: Checkbox(
                                    value: agree,
                                    onChanged: (v) => setState(() => agree = v ?? false),
                                    activeColor: cs.primary,
                                  ),
                                ),
                                const Gap(6),
                                Expanded(
                                  child: Text.rich(
                                    TextSpan(
                                      text: context.tr('register.terms.prefix'),
                                      style: TextStyle(
                                        fontSize: 11,
                                        height: 1.35,
                                        color: isDark ? Colors.white54 : Colors.black45,
                                        fontWeight: FontWeight.w500,
                                      ),
                                      children: [
                                        TextSpan(
                                          text: context.tr('register.terms.terms'),
                                          style: TextStyle(
                                            color: cs.primary,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                        TextSpan(
                                          text: context.tr('register.terms.suffix'),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            const Gap(22),

                            // Create Account
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: agree ? () {} : null,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: cs.primary,
                                  foregroundColor: Colors.white,
                                  disabledBackgroundColor: cs.primary.withOpacity(0.45),
                                  elevation: 0,
                                  padding: const EdgeInsets.symmetric(vertical: 18),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      context.tr('register.create_account'),
                                      style: const TextStyle(fontWeight: FontWeight.w900),
                                    ),
                                    const SizedBox(width: 8),
                                    const Icon(Icons.arrow_forward, size: 18),
                                  ],
                                ),
                              ),
                            ),

                            const Gap(18),

                            // Already have account? Log In
                            Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Text.rich(
                                TextSpan(
                                  text: context.tr('register.have_account.prefix'),
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: isDark ? Colors.white54 : Colors.black45,
                                  ),
                                  children: [
                                    WidgetSpan(
                                      alignment: PlaceholderAlignment.middle,
                                      child: GestureDetector(
                                        onTap: () => Navigator.pop(context),
                                        child: Text(
                                          context.tr('register.have_account.login'),
                                          style: TextStyle(
                                            color: cs.primary,
                                            fontWeight: FontWeight.w900,
                                          ),
                                        ),
                                      ),
                                    )
                                  ],
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),

                            const Gap(22),

                            // iOS home indicator
                            Container(
                              width: 120,
                              height: 6,
                              decoration: BoxDecoration(
                                color: isDark
                                    ? Colors.white.withOpacity(0.18)
                                    : Colors.black.withOpacity(0.14),
                                borderRadius: BorderRadius.circular(999),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.primary,
    required this.title,
    required this.subtitle,
  });

  final Color primary;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: primary,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: primary.withOpacity(0.20),
                blurRadius: 22,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: const Icon(Icons.medical_services, color: Colors.white, size: 34),
        ),
        const Gap(14),
        Text(
          title,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w900,
            color: isDark ? Colors.white : const Color(0xFF1F2937),
          ),
          textAlign: TextAlign.center,
        ),
        const Gap(6),
        Text(
          subtitle,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white.withOpacity(0.55) : Colors.black.withOpacity(0.45),
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class _AvatarPicker extends StatelessWidget {
  const _AvatarPicker({required this.primary, required this.label});
  final Color primary;
  final String label;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      children: [
        Stack(
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.black.withOpacity(0.06),
                shape: BoxShape.circle,
                border: Border.all(
                  color: isDark ? Colors.white.withOpacity(0.22) : Colors.black.withOpacity(0.15),
                  style: BorderStyle.solid,
                  width: 2,
                ),
              ),
              child: Icon(Icons.add_a_photo, color: isDark ? Colors.white38 : Colors.black38, size: 32),
            ),
            Positioned(
              right: 2,
              bottom: 2,
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: primary,
                  shape: BoxShape.circle,
                  border: Border.all(color: isDark ? const Color(0xFF0F172A) : Colors.white, width: 2),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.10), blurRadius: 10),
                  ],
                ),
                child: const Icon(Icons.edit, size: 14, color: Colors.white),
              ),
            ),
          ],
        ),
        const Gap(10),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.0,
            color: primary,
          ),
        ),
      ],
    );
  }
}

class _GlowBlob extends StatelessWidget {
  const _GlowBlob({required this.color});
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

class _LabeledField extends StatelessWidget {
  const _LabeledField({required this.label, required this.child});
  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 6),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 11,
              letterSpacing: 1.1,
              fontWeight: FontWeight.w900,
              color: isDark ? Colors.white54 : Colors.black45,
            ),
          ),
        ),
        const Gap(8),
        child,
      ],
    );
  }
}
