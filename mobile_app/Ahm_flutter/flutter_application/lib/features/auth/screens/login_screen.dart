import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:flutter_application/core/theme/app_theme.dart';
import 'package:flutter_application/features/auth/screens/register_screen.dart';
import 'package:flutter_application/features/auth/screens/case_inbox_screen.dart';







class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  int siteIndex = 0; // 0 = Main Hospital, 1 = West Wing Clinic
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

    return Scaffold(
      body: Stack(
        children: [
          // glow blobs
          Positioned(
            top: -96,
            right: -96,
            child: _GlowBlob(color: cs.primary.withOpacity(0.06)),
          ),
          Positioned(
            bottom: -96,
            left: -96,
            child: _GlowBlob(color: cs.primary.withOpacity(0.06)),
          ),

          SafeArea(
            child: Column(
              children: [
                // top status bar mimic
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: const [
                      Text("9:41", style: TextStyle(fontWeight: FontWeight.w700)),
                      Row(
                        children: [
                          Icon(Icons.signal_cellular_alt, size: 18),
                          SizedBox(width: 6),
                          Icon(Icons.wifi, size: 18),
                          SizedBox(width: 6),
                          Icon(Icons.battery_full, size: 18),
                        ],
                      ),
                    ],
                  ),
                ),

                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
                    child: Column(
                      children: [
                        const Gap(12),
                        _HeaderLogo(primary: cs.primary),
                        const Gap(28),

                        SizedBox(
                          width: 380,
                          child: Column(
                            children: [
                              _SegmentedSitePicker(
                                index: siteIndex,
                                onChanged: (v) => setState(() => siteIndex = v),
                              ),
                              const Gap(16),

                              _LabeledField(
                                label: "CLINICAL ID",
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
                              const Gap(14),

                              _LabeledField(
                                label: "PASSWORD",
                                child: TextField(
                                  controller: passwordCtrl,
                                  obscureText: obscure,
                                  decoration: InputDecoration(
                                    hintText: "••••••••",
                                    prefixIcon: const Padding(
                                      padding: EdgeInsets.only(left: 8),
                                      child: Icon(Icons.lock_outline),
                                    ),
                                    prefixIconConstraints: const BoxConstraints(minWidth: 48),
                                    suffixIcon: IconButton(
                                      onPressed: () => setState(() => obscure = !obscure),
                                      icon: Icon(obscure ? Icons.visibility : Icons.visibility_off),
                                    ),
                                  ),
                                ),
                              ),

                              Align(
                                alignment: Alignment.centerRight,
                                child: TextButton(
                                  onPressed: () {},
                                  child: Text(
                                    "Forgot Password?",
                                    style: TextStyle(
                                      fontWeight: FontWeight.w800,
                                      color: cs.primary,
                                    ),
                                  ),
                                ),
                              ),

                              const Gap(6),

                              // buttons
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: () {
                                    Navigator.pushReplacement(
                                      context,
                                      MaterialPageRoute(builder: (_) => const CaseInboxScreen()),
                                    );
                                  },

                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: cs.primary,
                                    foregroundColor: Colors.white,
                                    elevation: 0,
                                    padding: const EdgeInsets.symmetric(vertical: 18),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    shadowColor: cs.primary.withOpacity(0.35),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: const [
                                      Text("Log In", style: TextStyle(fontWeight: FontWeight.w900)),
                                      SizedBox(width: 8),
                                      Icon(Icons.arrow_forward, size: 18),
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
                                        MaterialPageRoute(builder: (_) => RegisterScreen()),
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
                                  child: const Text(
                                    "Register Account",
                                    style: TextStyle(fontWeight: FontWeight.w900),
                                  ),
                                ),
                              ),

                              const Gap(24),

                              // biometrics
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.fingerprint, color: cs.primary),
                                  const Gap(8),
                                  TextButton(
                                    onPressed: () {},
                                    child: Text(
                                      "Log in with Biometrics",
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        color: isDark
                                            ? Colors.white.withOpacity(0.70)
                                            : Colors.black.withOpacity(0.65),
                                      ),
                                    ),
                                  ),
                                ],
                              ),

                              const Gap(18),

                              Divider(
                                color: isDark
                                    ? Colors.white.withOpacity(0.10)
                                    : Colors.black.withOpacity(0.08),
                              ),
                              const Gap(12),
                              Text(
                                "Need technical assistance?",
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
                                  side: BorderSide(
                                    color: isDark
                                        ? Colors.white.withOpacity(0.18)
                                        : Colors.black.withOpacity(0.18),
                                  ),
                                ),
                                child: const Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 8),
                                  child: Text(
                                    "Contact IT Support",
                                    style: TextStyle(fontWeight: FontWeight.w900),
                                  ),
                                ),
                              ),

                              const Gap(28),

                              // home indicator
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
                      ],
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

class _HeaderLogo extends StatelessWidget {
  const _HeaderLogo({required this.primary});
  final Color primary;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: primary,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: primary.withOpacity(0.25),
                blurRadius: 24,
                offset: const Offset(0, 12),
              )
            ],
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
                  color: isDark ? Colors.white : const Color(0xFF1F2937),
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
          textAlign: TextAlign.center,
        ),
        const Gap(6),
        Text(
          "Specialist Ulcer Management",
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white.withOpacity(0.55) : Colors.black.withOpacity(0.45),
          ),
        ),
      ],
    );
  }
}

class _SegmentedSitePicker extends StatelessWidget {
  const _SegmentedSitePicker({
    required this.index,
    required this.onChanged,
  });

  final int index;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppTheme.cardDark : Colors.black.withOpacity(0.06);

    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Expanded(
            child: _SegButton(
              label: "Main Hospital",
              selected: index == 0,
              onTap: () => onChanged(0),
            ),
          ),
          Expanded(
            child: _SegButton(
              label: "West Wing Clinic",
              selected: index == 1,
              onTap: () => onChanged(1),
            ),
          ),
        ],
      ),
    );
  }
}

class _SegButton extends StatelessWidget {
  const _SegButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: selected ? (isDark ? const Color(0xFF334155) : Colors.white) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          boxShadow: selected && !isDark
              ? [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 10)]
              : null,
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w900,
              color: selected ? cs.primary : (isDark ? Colors.white54 : Colors.black45),
            ),
          ),
        ),
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

