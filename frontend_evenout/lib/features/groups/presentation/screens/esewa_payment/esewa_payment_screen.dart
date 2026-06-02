import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

class EsewaPaymentScreen extends StatefulWidget {
  final String payeeName;
  final double amount;
  final VoidCallback onPaymentSuccess;

  const EsewaPaymentScreen({
    super.key,
    required this.payeeName,
    required this.amount,
    required this.onPaymentSuccess,
  });

  @override
  State<EsewaPaymentScreen> createState() => _EsewaPaymentScreenState();
}

class _EsewaPaymentScreenState extends State<EsewaPaymentScreen> {
  // Brand color signature to eSewa
  final Color esewaGreen = const Color(0xFF60BB46);
  final Color esewaDarkGreen = const Color(0xFF4A9035);
  final Color esewaOrange = const Color(0xFFF37021);

  // Flow State: 0 = Login, 1 = OTP/MPIN Confirm, 2 = Loading, 3 = Success Receipt
  int _currentStep = 0;

  // Controllers
  final TextEditingController _idController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _mpinController = TextEditingController();

  String? _loginError;
  String? _mpinError;

  // Transaction details for receipt
  late final String _transactionId;
  late final String _formattedDate;

  @override
  void initState() {
    super.initState();
    // Generate mock txn ID and timestamp
    final randomDigits = (10000000 + (DateTime.now().millisecondsSinceEpoch % 90000000)).toString();
    _transactionId = "ESW-TXN-$randomDigits";
    final now = DateTime.now();
    _formattedDate = "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')} ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}";
  }

  @override
  void dispose() {
    _idController.dispose();
    _passwordController.dispose();
    _mpinController.dispose();
    super.dispose();
  }

  void _quickFillCredentials() {
    setState(() {
      _idController.text = "9806800002";
      _passwordController.text = "Nepal@123";
      _loginError = null;
    });
    // Visual feedback
    HapticFeedback.mediumImpact();
  }

  void _quickFillMpin() {
    setState(() {
      _mpinController.text = "1122";
      _mpinError = null;
    });
    HapticFeedback.mediumImpact();
  }

  void _handleLogin() {
    final id = _idController.text.trim();
    final password = _passwordController.text;

    // Validate using the test bounds provided
    final validIds = ["9806800002", "9806800003", "9806800004", "9806800005"];
    if (!validIds.contains(id) || password != "Nepal@123") {
      setState(() {
        _loginError = "Invalid test ID or password! Please tap the helper card below.";
      });
      HapticFeedback.vibrate();
    } else {
      setState(() {
        _loginError = null;
        _currentStep = 1; // Move to MPIN check
      });
      HapticFeedback.mediumImpact();
    }
  }

  void _handleConfirmPayment() {
    final mpin = _mpinController.text.trim();

    if (mpin != "1122") {
      setState(() {
        _mpinError = "Invalid MPIN! Use test MPIN: 1122";
      });
      HapticFeedback.vibrate();
    } else {
      setState(() {
        _mpinError = null;
        _currentStep = 2; // Transition to processing loader
      });
      HapticFeedback.mediumImpact();

      // Simulate network request to eSewa sandbox servers
      Timer(const Duration(milliseconds: 2200), () {
        if (mounted) {
          setState(() {
            _currentStep = 3; // Success Receipt!
          });
          HapticFeedback.lightImpact();
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEDF0F5),
      appBar: AppBar(
        backgroundColor: esewaGreen,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            const Icon(Icons.security_rounded, color: Colors.white, size: 18),
            const SizedBox(width: 6),
            Text(
              'eSewa Secure Checkout',
              style: GoogleFonts.inter(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            alignment: Alignment.center,
            child: Text(
              'SANDBOX',
              style: GoogleFonts.inter(color: esewaOrange, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 0.5),
            ),
          )
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // eSewa SubHeader Banner
              Container(
                width: double.infinity,
                color: esewaGreen,
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                child: Column(
                  children: [
                    // Mock gorgeous eSewa Logo
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            'e',
                            style: GoogleFonts.outfit(
                              color: esewaGreen,
                              fontSize: 26,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'esewa',
                          style: GoogleFonts.outfit(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Official Settlement Partner for EvenOut',
                      style: GoogleFonts.inter(color: Colors.white.withOpacity(0.9), fontSize: 11, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),

              Padding(
                padding: const EdgeInsets.all(20.0),
                child: _buildGatewayFlow(),
              ),

              // SSL Secure footer
              if (_currentStep < 2) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.lock_outline_rounded, size: 12, color: Colors.grey.shade600),
                      const SizedBox(width: 6),
                      Text(
                        '128-bit SSL Secure Payment Gateway',
                        style: GoogleFonts.inter(fontSize: 10, color: Colors.grey.shade600, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ]
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGatewayFlow() {
    switch (_currentStep) {
      case 0:
        return _buildLoginStep();
      case 1:
        return _buildConfirmMpinStep();
      case 2:
        return _buildProcessingStep();
      case 3:
        return _buildSuccessReceiptStep();
      default:
        return const SizedBox();
    }
  }

  // STEP 1: LOGIN PORTAL
  Widget _buildLoginStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Payment Amount Box
        Container(
          width: double.infinity,
          margin: const EdgeInsets.only(bottom: 20),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 8,
                offset: const Offset(0, 3),
              )
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'SETTLEMENT TO',
                    style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.w800, color: Colors.grey.shade500),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.payeeName,
                    style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'TOTAL PAYMENT',
                    style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.w800, color: Colors.grey.shade500),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'NPR ${widget.amount.toStringAsFixed(2)}',
                    style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w900, color: esewaGreen),
                  ),
                ],
              ),
            ],
          ),
        ),

        // Main Login Card
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 8,
                offset: const Offset(0, 3),
              )
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Login to your eSewa Account',
                style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.black87),
              ),
              const SizedBox(height: 16),

              if (_loginError != null) ...[
                Container(
                  padding: const EdgeInsets.all(10),
                  margin: const EdgeInsets.only(bottom: 14),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Text(
                    _loginError!,
                    style: GoogleFonts.inter(color: Colors.red.shade800, fontSize: 11, fontWeight: FontWeight.w500),
                  ),
                ),
              ],

              // User ID Input
              Text(
                'eSewa ID (Mobile / Email)',
                style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey.shade700),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: _idController,
                keyboardType: TextInputType.phone,
                style: GoogleFonts.inter(fontSize: 13, color: Colors.black87),
                decoration: InputDecoration(
                  hintText: 'e.g. 9806800002',
                  hintStyle: GoogleFonts.inter(fontSize: 13, color: Colors.grey.shade400),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: esewaGreen, width: 1.5),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Password Input
              Text(
                'Password',
                style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey.shade700),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: _passwordController,
                obscureText: true,
                style: GoogleFonts.inter(fontSize: 13, color: Colors.black87),
                decoration: InputDecoration(
                  hintText: 'Enter your password',
                  hintStyle: GoogleFonts.inter(fontSize: 13, color: Colors.grey.shade400),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: esewaGreen, width: 1.5),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Login Button
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: esewaGreen,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: _handleLogin,
                  child: Text(
                    'LOG IN',
                    style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 0.5),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // TEST CREDENTIALS TAP HELPER CARD
        GestureDetector(
          onTap: _quickFillCredentials,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.amber.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.amber.shade300, width: 1.5),
            ),
            child: Row(
              children: [
                const Icon(Icons.flash_on_rounded, color: Colors.amber, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'HACKATHON QUICK-FILL',
                        style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.amber.shade900, letterSpacing: 0.5),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Tap here to pre-populate SDK test credentials!',
                        style: GoogleFonts.inter(fontSize: 11, color: Colors.amber.shade900, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // STEP 2: MPIN / CONFIRMATION STEP
  Widget _buildConfirmMpinStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Checkout Details Overview
        Container(
          width: double.infinity,
          margin: const EdgeInsets.only(bottom: 20),
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 8,
                offset: const Offset(0, 3),
              )
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'TRANSACTION VERIFICATION',
                style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w800, color: Colors.grey.shade500, letterSpacing: 0.5),
              ),
              const Divider(height: 20),
              _buildCheckoutRow('Merchant Code', 'EPAYTEST'),
              const SizedBox(height: 8),
              _buildCheckoutRow('Token', '123456'),
              const SizedBox(height: 8),
              _buildCheckoutRow('Secret Key', '8gBm/:&EnhH...'),
              const SizedBox(height: 8),
              _buildCheckoutRow('Payee Account', widget.payeeName),
              const Divider(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Amount Due',
                    style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black87),
                  ),
                  Text(
                    'NPR ${widget.amount.toStringAsFixed(2)}',
                    style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w900, color: esewaGreen),
                  ),
                ],
              ),
            ],
          ),
        ),

        // MPIN Card
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 8,
                offset: const Offset(0, 3),
              )
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Enter Transaction PIN',
                style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.black87),
              ),
              const SizedBox(height: 4),
              Text(
                'Required to securely authorize this NPR transfer.',
                style: GoogleFonts.inter(fontSize: 11, color: Colors.grey.shade500),
              ),
              const SizedBox(height: 16),

              if (_mpinError != null) ...[
                Container(
                  padding: const EdgeInsets.all(10),
                  margin: const EdgeInsets.only(bottom: 14),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Text(
                    _mpinError!,
                    style: GoogleFonts.inter(color: Colors.red.shade800, fontSize: 11, fontWeight: FontWeight.w500),
                  ),
                ),
              ],

              // MPIN Input
              Text(
                '4-Digit eSewa MPIN',
                style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey.shade700),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: _mpinController,
                obscureText: true,
                keyboardType: TextInputType.number,
                maxLength: 4,
                style: GoogleFonts.inter(fontSize: 16, color: Colors.black87, fontWeight: FontWeight.bold, letterSpacing: 8.0),
                decoration: InputDecoration(
                  counterText: '',
                  hintText: '••••',
                  hintStyle: GoogleFonts.inter(fontSize: 16, color: Colors.grey.shade300, letterSpacing: 8.0),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: esewaGreen, width: 1.5),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Confirm Button
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: esewaGreen,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: _handleConfirmPayment,
                  child: Text(
                    'CONFIRM PAYMENT',
                    style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 0.5),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // TEST MPIN TAP HELPER CARD
        GestureDetector(
          onTap: _quickFillMpin,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.amber.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.amber.shade300, width: 1.5),
            ),
            child: Row(
              children: [
                const Icon(Icons.pin_rounded, color: Colors.amber, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'TEST MPIN FILL',
                        style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.amber.shade900, letterSpacing: 0.5),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Tap here to pre-populate secure test MPIN: 1122',
                        style: GoogleFonts.inter(fontSize: 11, color: Colors.amber.shade900, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCheckoutRow(String title, String val) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: GoogleFonts.inter(fontSize: 12, color: Colors.grey.shade600, fontWeight: FontWeight.w500)),
        Text(val, style: GoogleFonts.inter(fontSize: 12, color: Colors.black87, fontWeight: FontWeight.bold)),
      ],
    );
  }

  // STEP 3: PROCESSING SECURE ROUTER
  Widget _buildProcessingStep() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          )
        ],
      ),
      child: Column(
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(esewaGreen),
            strokeWidth: 4,
          ),
          const SizedBox(height: 30),
          Text(
            'Authorizing Transfer...',
            style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
          ),
          const SizedBox(height: 8),
          Text(
            'Contacting secure eSewa merchant sandbox...',
            style: GoogleFonts.inter(fontSize: 12, color: Colors.grey.shade500),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 16),
          Text(
            'Secret Key Verification: 8gBm/:&EnhH.1/q',
            style: GoogleFonts.sourceCodePro(fontSize: 9, color: Colors.grey.shade600, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  // STEP 4: SUCCESS RECEIPT
  Widget _buildSuccessReceiptStep() {
    return Column(
      children: [
        // Confetti Ribbon success badge
        Container(
          padding: const EdgeInsets.all(12),
          decoration: const BoxDecoration(
            color: Color(0xFFE8F5E9),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.check_circle_rounded, color: Color(0xFF2E7D32), size: 52),
        ),
        const SizedBox(height: 16),

        Text(
          'Settlement Complete!',
          style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
        ),
        const SizedBox(height: 4),
        Text(
          'eSewa sandbox balance transferred successfully.',
          style: GoogleFonts.inter(fontSize: 12, color: Colors.grey.shade500),
        ),
        const SizedBox(height: 24),

        // Beautiful PDF-Like Digital Receipt Card
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade200, width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 10,
                offset: const Offset(0, 5),
              )
            ],
          ),
          child: Column(
            children: [
              // Receipt Header
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
                  border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'DIGITAL RECEIPT',
                      style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.grey.shade600, letterSpacing: 0.8),
                    ),
                    const Icon(Icons.receipt_long_rounded, color: Colors.grey, size: 16),
                  ],
                ),
              ),

              Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    // Big Cash Paid Value
                    Text(
                      'NPR ${widget.amount.toStringAsFixed(2)}',
                      style: GoogleFonts.inter(fontSize: 28, fontWeight: FontWeight.w900, color: esewaGreen),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Paid to $widget.payeeName',
                      style: GoogleFonts.inter(fontSize: 12, color: Colors.grey.shade600, fontWeight: FontWeight.w600),
                    ),
                    const Divider(height: 24),

                    // Details
                    _buildReceiptRow('Transaction Ref', _transactionId),
                    const SizedBox(height: 10),
                    _buildReceiptRow('Merchant Code', 'EPAYTEST'),
                    const SizedBox(height: 10),
                    _buildReceiptRow('Payment Token', '123456'),
                    const SizedBox(height: 10),
                    _buildReceiptRow('Secret Signature', '8gBm/:&EnhH.1/q'),
                    const SizedBox(height: 10),
                    _buildReceiptRow('Date & Time', _formattedDate),
                    const SizedBox(height: 10),
                    _buildReceiptRow('Status', 'SUCCESSFUL', color: const Color(0xFF2E7D32)),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 30),

        // Action Return Done Button
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: esewaGreen,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 1,
            ),
            onPressed: () {
              // Trigger successful callback settling balances in parent list view
              widget.onPaymentSuccess();
              Navigator.pop(context);
            },
            child: Text(
              'RETURN TO EVENOUT',
              style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 0.8),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildReceiptRow(String label, String value, {Color? color}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(fontSize: 11, color: Colors.grey.shade500, fontWeight: FontWeight.w500),
        ),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 11, 
            color: color ?? Colors.black87, 
            fontWeight: color != null ? FontWeight.bold : FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
