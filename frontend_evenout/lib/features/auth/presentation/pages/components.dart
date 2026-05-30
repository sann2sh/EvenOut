import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

// --- CONSTANTS ---
const Color appGreen = Color(0xFF429246); // Match with your Figma hex
const Color appGreenDark = Color(0xFF1E5C22); // Premium high-contrast dark forest green
const Color appLightGreen = Color(0xFFD4E6D5);

// --- REUSABLE TEXT FIELD ---
class CustomInputField extends StatelessWidget {
  final String hintText;
  final IconData prefixIcon;
  final bool isPassword;
  final bool hasSuffix;

  const CustomInputField({
    super.key,
    required this.hintText,
    required this.prefixIcon,
    this.isPassword = false,
    this.hasSuffix = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: TextFormField(
        obscureText: isPassword,
        style: const TextStyle(color: Color(0xFF1A1A2E), fontSize: 16), // Dark readable typing text
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: const TextStyle(color: Color(0xFF6B7280), fontSize: 14), // Slate-gray hint
          prefixIcon: Icon(prefixIcon, color: Color(0xFF4B5563), size: 20), // Charcoal prefix icon
          suffixIcon: hasSuffix
              ? const Icon(Icons.visibility_off, color: Colors.black54, size: 20)
              : null,
          enabledBorder: const UnderlineInputBorder(
            borderSide: BorderSide(color: appLightGreen, width: 1.5),
          ),
          focusedBorder: const UnderlineInputBorder(
            borderSide: BorderSide(color: appGreen, width: 2),
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 15),
          filled: true,
          fillColor: Colors.transparent,
        ),
      ),
    );
  }
}

// --- BACKGROUND WRAPPER ---
// Note: For complex vector waves like in your design, the most performant 
// method in Flutter is exporting the wave as an SVG or high-res PNG from Figma.
class AuthBackground extends StatelessWidget {
  final Widget child;
  
  const AuthBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Background Gradient (Approximation of the soft green glow)
        Container(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: const Alignment(0.8, 0.5),
              radius: 2.0, // Increased radius for smoother transition
              colors: [
                appLightGreen.withOpacity(0.10), // Reduced opacity to be 1.5x lighter
                Colors.white.withOpacity(0.8), // Softer white edge
              ],
              stops: const [0.2, 1.0], // Smooth blend points
            ),
          ),
        ),
        // Background Image from assets
        Positioned.fill(
          child: Image.asset(
            'assets/Login_Page_1.png', 
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => Container(
              // Fallback box just in case the asset isn't loaded yet
              color: appLightGreen.withOpacity(0.3),
            ),
          ),
        ),
        // Safe Area and Scaffold for the actual content
        // The Scaffold is transparent and resizes automatically for the keyboard
        // while leaving the background layers completely static behind it!
        Scaffold(
          backgroundColor: Colors.transparent,
          body: SafeArea(child: child),
        ),
      ],
    );
  }
}

// --- SOCIAL LOGIN BUTTON ---
class SocialLoginButton extends StatelessWidget {
  final String text;
  final String iconAsset;
  final VoidCallback onPressed;

  const SocialLoginButton({
    super.key,
    required this.text,
    required this.iconAsset,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          backgroundColor: Colors.white,
          side: const BorderSide(color: Color(0xFFE0E0E0), width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        onPressed: onPressed,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SvgPicture.asset(iconAsset, width: 24, height: 24),
            const SizedBox(width: 12),
            Text(
              text,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1B1B3A),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// --- REMEMBER ME CHECKBOX ---
class RememberMeCheckbox extends StatefulWidget {
  const RememberMeCheckbox({super.key});

  @override
  State<RememberMeCheckbox> createState() => _RememberMeCheckboxState();
}

class _RememberMeCheckboxState extends State<RememberMeCheckbox> {
  bool isChecked = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        setState(() {
          isChecked = !isChecked;
        });
      },
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              color: isChecked ? appGreen : Colors.white,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(
                color: isChecked ? appGreen : const Color(0xFF9CA3AF),
                width: 1.5,
              ),
            ),
            child: isChecked 
              ? const Icon(Icons.check, size: 12, color: Colors.white)
              : null,
          ),
          const SizedBox(width: 8),
          const Text('Remember me', style: TextStyle(fontSize: 12, color: Colors.black87)),
        ],
      ),
    );
  }
}