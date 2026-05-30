import 'package:flutter/material.dart';

// --- CONSTANTS ---
const Color appGreen = Color(0xFF429246); // Match with your Figma hex
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
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: const TextStyle(color: appGreen, fontSize: 14),
          prefixIcon: Icon(prefixIcon, color: appGreen, size: 20),
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
    return Scaffold(
      body: Stack(
        children: [
          // Background Gradient (Approximation of the soft green glow)
          Container(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: const Alignment(0.8, 0.5),
                radius: 1.2,
                colors: [
                  appLightGreen.withOpacity(0.5),
                  Colors.white,
                ],
              ),
            ),
          ),
          // Top Left Wave Graphic 
          // Replace 'assets/wave_bg.png' with your actual Figma export
          Positioned(
            top: 0,
            left: 0,
            child: Image.asset(
              'assets/wave_bg.png', 
              width: MediaQuery.of(context).size.width * 0.7,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
                // Fallback box just in case the asset isn't loaded yet
                width: 200, height: 200, color: appLightGreen.withOpacity(0.3),
              ),
            ),
          ),
          // Safe Area for the actual content
          SafeArea(child: child),
        ],
      ),
    );
  }
}