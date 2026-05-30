import 'package:flutter/material.dart';
import 'components/components.dart'; // Import your shared components here

class SignUpPage extends StatelessWidget {
  const SignUpPage({super.key});

  @override
  Widget build(BuildContext context) {
    return AuthBackground(
      child: SingleChildScrollView( // Added scroll view to prevent overflow with more fields
        padding: const EdgeInsets.symmetric(horizontal: 30.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Icon(Icons.local_fire_department_outlined, size: 36, color: Colors.black87),
                IconButton(
                  icon: const Icon(Icons.menu, size: 32, color: Color(0xFF1B1B3A)),
                  onPressed: () {},
                ),
              ],
            ),
            const SizedBox(height: 60), // Slightly reduced spacing for extra fields
            
            // Title
            const Text(
              'Create an account',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1B1B3A),
              ),
            ),
            const SizedBox(height: 30),

            // Form Fields
            const CustomInputField(
              hintText: 'Name',
              prefixIcon: Icons.person_outline,
            ),
            const CustomInputField(
              hintText: 'Email',
              prefixIcon: Icons.email_outlined,
            ),
            const CustomInputField(
              hintText: 'Password',
              prefixIcon: Icons.lock_outline,
              isPassword: true,
            ),
            const CustomInputField(
              hintText: 'Confirm Password',
              prefixIcon: Icons.lock_outline,
              isPassword: true,
              hasSuffix: true,
            ),
            
            const SizedBox(height: 10),

            // Remember me & Forgot Password Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 16,
                      height: 16,
                      color: appLightGreen, 
                    ),
                    const SizedBox(width: 8),
                    const Text('Remember me', style: TextStyle(fontSize: 12)),
                  ],
                ),
                const Text(
                  'Forgot password?',
                  style: TextStyle(fontSize: 12, color: Colors.black87),
                ),
              ],
            ),
            const SizedBox(height: 30),

            // Sign Up Button
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
                onPressed: () {},
                child: const Text(
                  'SIGN UP',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Login Redirect
            Center(
              child: RichText(
                text: const TextSpan(
                  text: "Already have an account ? ",
                  style: TextStyle(color: Colors.black87, fontSize: 14),
                  children: [
                    TextSpan(
                      text: 'Login',
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
            const SizedBox(height: 20), // Bottom padding
          ],
        ),
      ),
    );
  }
}