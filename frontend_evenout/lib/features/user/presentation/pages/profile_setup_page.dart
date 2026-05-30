import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../auth/presentation/pages/components.dart';
import '../providers/user_provider.dart';

class ProfileSetupPage extends ConsumerStatefulWidget {
  const ProfileSetupPage({super.key});

  @override
  ConsumerState<ProfileSetupPage> createState() => _ProfileSetupPageState();
}

class _ProfileSetupPageState extends ConsumerState<ProfileSetupPage>
    with SingleTickerProviderStateMixin {
  final _usernameController = TextEditingController();
  final _displayNameController = TextEditingController();
  final _phoneController = TextEditingController();

  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  // Username availability state
  Timer? _debounce;
  bool? _isUsernameAvailable;
  bool _checkingUsername = false;
  String _lastCheckedUsername = '';

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));
    _animController.forward();

    _usernameController.addListener(_onUsernameChanged);
  }

  @override
  void dispose() {
    _animController.dispose();
    _debounce?.cancel();
    _usernameController.removeListener(_onUsernameChanged);
    _usernameController.dispose();
    _displayNameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _onUsernameChanged() {
    final val = _usernameController.text.trim();
    if (val == _lastCheckedUsername) return;

    setState(() {
      _isUsernameAvailable = null;
      _checkingUsername = false;
    });

    if (val.length < 3) return;

    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 600), () async {
      if (!mounted) return;
      setState(() => _checkingUsername = true);
      try {
        final available = await ref
            .read(profileSetupProvider.notifier)
            .checkUsername(val);
        if (!mounted) return;
        setState(() {
          _isUsernameAvailable = available;
          _checkingUsername = false;
          _lastCheckedUsername = val;
        });
      } catch (_) {
        if (!mounted) return;
        setState(() => _checkingUsername = false);
      }
    });
  }

  Future<void> _save() async {
    final username = _usernameController.text.trim();
    final displayName = _displayNameController.text.trim();
    final phone = _phoneController.text.trim();

    if (username.isEmpty || displayName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Username and display name are required')),
      );
      return;
    }

    if (_isUsernameAvailable != true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please choose an available username')),
      );
      return;
    }

    await ref.read(profileSetupProvider.notifier).saveProfile(
          username: username,
          displayName: displayName,
          phoneNumber: phone,
        );

    if (!mounted) return;
    // Invalidate user cache and navigate to dashboard
    ref.invalidate(currentUserProvider);
    context.go('/dashboard');
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AsyncValue<void>>(profileSetupProvider, (_, next) {
      next.whenOrNull(
        error: (err, _) => ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(err.toString())),
        ),
      );
    });

    final isLoading = ref.watch(profileSetupProvider).isLoading;

    return AuthBackground(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 30),
        child: FadeTransition(
          opacity: _fadeAnim,
          child: SlideTransition(
            position: _slideAnim,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Icon(Icons.local_fire_department_outlined,
                        size: 36, color: Colors.black87),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: appGreen.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        'Step 1 of 1',
                        style: TextStyle(
                          color: appGreen,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 100),

                // Title
                const SizedBox(
                  width: double.infinity,
                  child: Text(
                    'Lessss goo!',
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      fontSize: 34,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1B1B3A),
                      height: 1.2,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: Text(
                    'Tell us a bit about yourself so your\nfriends can find you.',
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.black45,
                      height: 1.5,
                    ),
                  ),
                ),
                const SizedBox(height: 36),

                // --- Username field with availability indicator ---
                _SectionLabel(label: 'Username'),
                const SizedBox(height: 6),
                _UsernameField(
                  controller: _usernameController,
                  isAvailable: _isUsernameAvailable,
                  isChecking: _checkingUsername,
                ),
                const SizedBox(height: 20),

                // --- Display Name ---
                _SectionLabel(label: 'Display Name'),
                const SizedBox(height: 6),
                _ProfileField(
                  controller: _displayNameController,
                  hintText: 'Your name shown to friends',
                  prefixIcon: Icons.badge_outlined,
                ),
                const SizedBox(height: 20),

                // --- Phone Number (Optional) ---
                _SectionLabel(label: 'Phone Number (optional)'),
                const SizedBox(height: 6),
                _ProfileField(
                  controller: _phoneController,
                  hintText: '+977 98XXXXXXXX',
                  prefixIcon: Icons.phone_outlined,
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 40),

                // Save Button
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: appGreen,
                      disabledBackgroundColor: appGreen.withOpacity(0.4),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    onPressed: isLoading ? null : _save,
                    child: isLoading
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2.5),
                          )
                        : const Text(
                            'Continue',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ----- Helper Widgets -----

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: Color(0xFF1B1B3A),
        letterSpacing: 0.5,
      ),
    );
  }
}

class _ProfileField extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final IconData prefixIcon;
  final TextInputType keyboardType;

  const _ProfileField({
    required this.controller,
    required this.hintText,
    required this.prefixIcon,
    this.keyboardType = TextInputType.text,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      style: const TextStyle(color: Colors.black87, fontSize: 15),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle:
            TextStyle(color: Colors.black.withOpacity(0.3), fontSize: 14),
        prefixIcon: Icon(prefixIcon, color: appGreen, size: 20),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              BorderSide(color: Colors.black.withOpacity(0.12), width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: appGreen, width: 2),
        ),
        filled: true,
        fillColor: Colors.white.withOpacity(0.7),
        contentPadding:
            const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      ),
    );
  }
}

class _UsernameField extends StatelessWidget {
  final TextEditingController controller;
  final bool? isAvailable;
  final bool isChecking;

  const _UsernameField({
    required this.controller,
    required this.isAvailable,
    required this.isChecking,
  });

  @override
  Widget build(BuildContext context) {
    Color borderColor = Colors.black.withOpacity(0.12);
    Widget? suffixWidget;

    if (isChecking) {
      suffixWidget = const SizedBox(
        width: 18,
        height: 18,
        child: CircularProgressIndicator(strokeWidth: 2, color: appGreen),
      );
    } else if (isAvailable == true) {
      borderColor = const Color(0xFF429246);
      suffixWidget = const Icon(Icons.check_circle, color: Color(0xFF429246), size: 22);
    } else if (isAvailable == false) {
      borderColor = Colors.redAccent;
      suffixWidget = const Icon(Icons.cancel, color: Colors.redAccent, size: 22);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: controller,
          style: const TextStyle(color: Colors.black87, fontSize: 15),
          decoration: InputDecoration(
            hintText: 'e.g. john_doe',
            hintStyle:
                TextStyle(color: Colors.black.withOpacity(0.3), fontSize: 14),
            prefixIcon:
                const Icon(Icons.alternate_email, color: appGreen, size: 20),
            prefixText: '',
            suffixIcon: suffixWidget != null
                ? Padding(
                    padding: const EdgeInsets.only(right: 14),
                    child: suffixWidget,
                  )
                : null,
            suffixIconConstraints:
                const BoxConstraints(minWidth: 0, minHeight: 0),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: borderColor, width: 1.5),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                  color: isAvailable == false
                      ? Colors.redAccent
                      : appGreen,
                  width: 2),
            ),
            filled: true,
            fillColor: Colors.white.withOpacity(0.7),
            contentPadding:
                const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
          ),
        ),
        if (isAvailable == false)
          const Padding(
            padding: EdgeInsets.only(top: 6, left: 4),
            child: Text(
              'Username is already taken',
              style: TextStyle(color: Colors.redAccent, fontSize: 12),
            ),
          ),
        if (isAvailable == true)
          const Padding(
            padding: EdgeInsets.only(top: 6, left: 4),
            child: Text(
              'Username is available!',
              style: TextStyle(color: Color(0xFF429246), fontSize: 12),
            ),
          ),
      ],
    );
  }
}
