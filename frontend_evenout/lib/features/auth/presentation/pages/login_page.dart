import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'components.dart'; // Import your shared components here

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return AuthBackground(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 30.0),
          child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            // Header: Logo and Hamburger Menu
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Icon(Icons.local_fire_department_outlined, size: 36, color: Colors.black87), // Replace with your SVG Logo
                IconButton(
                  icon: const Icon(Icons.menu, size: 32, color: Color(0xFF1B1B3A)),
                  onPressed: () {},
                ),
              ],
            ),
            const SizedBox(height: 100),
            
            // Title
            const Center(
              child: Text(
                'Login',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1B1B3A),
                ),
              ),
            ),
            const SizedBox(height: 40),

            // Form Fields
            const CustomInputField(
              hintText: 'Email',
              prefixIcon: Icons.email_outlined,
            ),
            const CustomInputField(
              hintText: 'Password',
              prefixIcon: Icons.lock_outline,
              isPassword: true,
              hasSuffix: true,
            ),
            
            const SizedBox(height: 10),

            // Remember me & Forgot Password Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const RememberMeCheckbox(),
                const Text(
                  'Forgot password?',
                  style: TextStyle(fontSize: 12, color: Colors.black87),
                ),
              ],
            ),
            const SizedBox(height: 40),

            // Login Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: appGreen,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: () => context.go('/dashboard'),
                child: const Text(
                  'LOGIN',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            
            // OR Divider
            Row(
              children: [
                Expanded(child: Divider(color: Colors.grey.shade300, thickness: 1)),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text('OR', style: TextStyle(color: Colors.grey.shade600, fontSize: 12, fontWeight: FontWeight.bold)),
                ),
                Expanded(child: Divider(color: Colors.grey.shade300, thickness: 1)),
              ],
            ),
            const SizedBox(height: 20),

            // Google Login Button
            SocialLoginButton(
              text: 'Sign in with Google',
              iconAsset: 'assets/google_logo.svg',
              onPressed: () => context.go('/dashboard'),
            ),
            
            const SizedBox(height: 30),

            // Sign Up Redirect
            Center(
              child: GestureDetector(
                onTap: () => context.go('/signup'),
                child: RichText(
                  text: const TextSpan(
                    text: "Don't have an account ? ",
                    style: TextStyle(color: Colors.black87, fontSize: 14),
                    children: [
                      TextSpan(
                        text: 'Sign Up',
                        style: TextStyle(
                          color: appGreen,
                          fontWeight: FontWeight.bold,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      ),
    );
  }
}