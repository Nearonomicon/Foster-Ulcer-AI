import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:provider/provider.dart';

import 'package:flutter_application/features/auth/screens/register_screen.dart';
import 'package:flutter_application/features/auth/screens/case_inbox_screen.dart';
import 'package:flutter_application/features/auth/widgets/auth_common.dart';

import 'package:flutter_application/shared/locale_controller.dart';
import 'package:flutter_application/shared/app_localizations.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool obscure = true;

  final clinicalIdCtrl = TextEditingController();
  final passwordCtrl = TextEditingController();

  @override
  void dispose() {
    clinicalIdCtrl.dispose();
    passwordCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final localeCtrl = context.watch<LocaleController>();

    return Scaffold(
      body: Stack(
        children: [
          Positioned(
            top: -96,
            right: -96,
            child: AuthGlowBlob(color: cs.primary.withOpacity(0.06)),
          ),
          Positioned(
            bottom: -96,
            left: -96,
            child: AuthGlowBlob(color: cs.primary.withOpacity(0.06)),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
              child: Column(
                children: [
                  const Gap(12),
                  _HeaderLogo(primary: cs.primary),
                  const Gap(40),
                  SizedBox(
                    width: 380,
                    child: Column(
                      children: [
                        AuthLabeledField(
                          label: context.tr('login.clinical_id'),
                          child: TextField(
                            controller: clinicalIdCtrl,
                            decoration: const InputDecoration(
                              hintText: "DR-992-000",
                              prefixIcon: Padding(
                                padding: EdgeInsets.only(left: 8),
                                child: Icon(Icons.badge_outlined),
                              ),
                              prefixIconConstraints: BoxConstraints(minWidth: 48),
                            ),
                          ),
                        ),
                        const Gap(16),
                        AuthLabeledField(
                          label: context.tr('login.password'),
                          child: TextField(
                            controller: passwordCtrl,
                            obscureText: obscure,
                            decoration: InputDecoration(
                              hintText: "••••••••",
                              prefixIcon: const Padding(
                                padding: EdgeInsets.only(left: 8),
                                child: Icon(Icons.lock_outline),
                              ),
                              prefixIconConstraints:
                                  const BoxConstraints(minWidth: 48),
                              suffixIcon: IconButton(
                                onPressed: () => setState(() => obscure = !obscure),
                                icon: Icon(
                                  obscure
                                      ? Icons.visibility
                                      : Icons.visibility_off,
                                ),
                              ),
                            ),
                          ),
                        ),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () {},
                            child: Text(
                              context.tr('login.forgot'),
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                color: cs.primary,
                              ),
                            ),
                          ),
                        ),
                        const Gap(10),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const CaseInboxScreen(),
                                ),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: cs.primary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 18),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  context.tr('login.login'),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                const Icon(Icons.arrow_forward, size: 18),
                              ],
                            ),
                          ),
                        ),
                        const Gap(12),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const RegisterScreen(),
                                ),
                              );
                            },
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 18),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              side: BorderSide(
                                color: isDark
                                    ? Colors.white.withOpacity(0.14)
                                    : Colors.black.withOpacity(0.10),
                              ),
                            ),
                            child: Text(
                              context.tr('login.register'),
                              style: const TextStyle(
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        ),
                        const Gap(30),
                        Divider(
                          color: isDark
                              ? Colors.white.withOpacity(0.10)
                              : Colors.black.withOpacity(0.08),
                        ),
                        const Gap(12),
                        Text(
                          context.tr('login.need_help'),
                          style: TextStyle(
                            color: isDark
                                ? Colors.white.withOpacity(0.55)
                                : Colors.black.withOpacity(0.45),
                          ),
                        ),
                        const Gap(10),
                        OutlinedButton(
                          onPressed: () {},
                          style: OutlinedButton.styleFrom(
                            shape: const StadiumBorder(),
                          ),
                          child: Text(
                            context.tr('login.contact_it'),
                            style: const TextStyle(
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        const Gap(30),
                        const AuthBottomIndicator(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            top: 56,
            left: 24,
            child: _LanguageChip(
              code: localeCtrl.code,
              onSelect: (locale) =>
                  context.read<LocaleController>().setLocale(locale),
            ),
          ),
        ],
      ),
    );
  }
}

class _LanguageChip extends StatelessWidget {
  const _LanguageChip({
    required this.code,
    required this.onSelect,
  });

  final String code;
  final ValueChanged<Locale> onSelect;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: PopupMenuButton<Locale>(
        onSelected: onSelect,
        itemBuilder: (_) => const [
          PopupMenuItem(value: Locale('en'), child: Text("English")),
          PopupMenuItem(value: Locale('my'), child: Text("Myanmar")),
        ],
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: Colors.white24),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.language, size: 18),
              const SizedBox(width: 6),
              Text(
                code,
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeaderLogo extends StatelessWidget {
  const _HeaderLogo({required this.primary});
  final Color primary;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: primary,
            borderRadius: BorderRadius.circular(24),
          ),
          child: const Icon(Icons.healing, color: Colors.white, size: 46),
        ),
        const Gap(16),
        Text.rich(
          TextSpan(
            children: [
              TextSpan(
                text: "Foster ",
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                ),
              ),
              TextSpan(
                text: "Apps",
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w900,
                  color: primary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
