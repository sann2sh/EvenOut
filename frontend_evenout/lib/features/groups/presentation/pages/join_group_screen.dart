import 'package:flutter/material.dart';
import '../../data/models/group_model.dart';

class JoinGroupScreen extends StatefulWidget {
  const JoinGroupScreen({super.key});

  @override
  State<JoinGroupScreen> createState() => _JoinGroupScreenState();
}

class _JoinGroupScreenState extends State<JoinGroupScreen> with SingleTickerProviderStateMixin {
  late AnimationController _scannerController;
  final _codeController = TextEditingController();
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    // Repeating vertical scanning beam sweep animation
    _scannerController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _scannerController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    final Color backgroundColor = isDark ? const Color(0xFF121212) : const Color(0xFFFAFAFA);
    final Color cardColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final Color textColor = isDark ? Colors.white : const Color(0xFF1B1B3A);
    final Color subtextColor = isDark ? Colors.white60 : Colors.black54;
    final Color brandGreen = const Color(0xFF429246);

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: textColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Scan Join QR',
          style: TextStyle(color: textColor, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 10.0),
        child: Column(
          children: [
            const SizedBox(height: 15),
            
            // Instruction header
            Text(
              'Align group QR code inside the frame to join',
              style: TextStyle(fontSize: 13, color: subtextColor, fontWeight: FontWeight.w500),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 30),

            // 1. Beautiful Mock Camera Scanner view with Animated Laser Sweep Beam!
            Center(
              child: Container(
                width: 250,
                height: 250,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: brandGreen, width: 3),
                  boxShadow: [
                    BoxShadow(
                      color: brandGreen.withOpacity(0.15),
                      blurRadius: 20,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(26),
                  child: Stack(
                    children: [
                      // Camera viewport simulation grid background
                      Positioned.fill(
                        child: Container(
                          color: Colors.black.withOpacity(0.85),
                          child: GridPaper(
                            color: brandGreen.withOpacity(0.12),
                            divisions: 2,
                            subdivisions: 1,
                            interval: 50,
                          ),
                        ),
                      ),
                      
                      // QR icon phantom vector in the background
                      const Center(
                        child: Icon(
                          Icons.qr_code_2_rounded,
                          color: Colors.white12,
                          size: 130,
                        ),
                      ),

                      // Repeating Animated Scanning Laser Beam Sweep
                      AnimatedBuilder(
                        animation: _scannerController,
                        builder: (context, child) {
                          // Compute dynamic animated Y value top to bottom
                          final double scanY = _scannerController.value * 230 + 10;
                          return Positioned(
                            top: scanY,
                            left: 15,
                            right: 15,
                            child: Container(
                              height: 3,
                              decoration: BoxDecoration(
                                color: Colors.greenAccent,
                                borderRadius: BorderRadius.circular(2),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.greenAccent.withOpacity(0.8),
                                    blurRadius: 10,
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                      
                      // Viewfinder corners indicator overlay
                      _buildCameraCorners(),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 40),

            // 2. Divider Or Text
            Row(
              children: [
                Expanded(child: Divider(color: isDark ? Colors.white12 : Colors.grey.shade300, thickness: 1)),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text('OR ENTER INVITE CODE', style: TextStyle(color: subtextColor, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.8)),
                ),
                Expanded(child: Divider(color: isDark ? Colors.white12 : Colors.grey.shade300, thickness: 1)),
              ],
            ),
            const SizedBox(height: 25),

            // 3. Manual code entry textfield
            TextField(
              controller: _codeController,
              style: TextStyle(color: textColor, fontWeight: FontWeight.w600),
              decoration: InputDecoration(
                hintText: 'e.g. evenout-cabin-trip',
                hintStyle: TextStyle(color: subtextColor.withOpacity(0.5), fontSize: 14),
                prefixIcon: Icon(Icons.vpn_key_rounded, color: brandGreen),
                filled: true,
                fillColor: cardColor,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              ),
            ),
            const SizedBox(height: 25),

            // 4. Join Submit Button
            _isProcessing
                ? const Column(
                    children: [
                      CircularProgressIndicator(color: Colors.green),
                      SizedBox(height: 12),
                      Text('Connecting to group invite endpoint...', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
                    ],
                  )
                : SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: brandGreen,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 3,
                        shadowColor: brandGreen.withOpacity(0.3),
                      ),
                      onPressed: () {
                        final code = _codeController.text.trim();
                        if (code.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Please scan a QR code or enter a manual join code'),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                          return;
                        }

                        setState(() {
                          _isProcessing = true;
                        });

                        // Simulate deep link API call to join group
                        Future.delayed(const Duration(milliseconds: 1500), () {
                          if (context.mounted) {
                            setState(() {
                              _isProcessing = false;
                              
                              // Insert a new mock group dynamically into mockGroups representing the successful join!
                              mockGroups.insert(
                                0,
                                EvenOutGroup(
                                  id: (mockGroups.length + 1).toString(),
                                  name: 'Mountain Cabin Crew',
                                  avatarType: 'scenic',
                                  avatarBgColor: const Color(0xFFF57C00),
                                  lastActive: 'Joined just now',
                                  members: [
                                    GroupMember(name: 'You', avatarUrl: '', balance: 0.0),
                                    GroupMember(name: 'Santosh Ray', avatarUrl: '', balance: 0.0),
                                    GroupMember(name: 'Anuska', avatarUrl: '', balance: 0.0),
                                  ],
                                  expenses: [],
                                ),
                              );
                            });

                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: const Row(
                                  children: [
                                    Icon(Icons.verified_rounded, color: Colors.white),
                                    SizedBox(width: 10),
                                    Text('Successfully joined "Mountain Cabin Crew"!'),
                                  ],
                                ),
                                backgroundColor: brandGreen,
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          }
                        });
                      },
                      child: const Text(
                        'JOIN GROUP',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),
                  ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildCameraCorners() {
    return Positioned.fill(
      child: CustomPaint(
        painter: ViewfinderCornersPainter(),
      ),
    );
  }
}

// Custom Painter to draw professional white viewfinder corner marks
class ViewfinderCornersPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = Colors.white
      ..strokeWidth = 4.0
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final double width = size.width;
    final double height = size.height;
    const double len = 25.0;

    // Top-Left corner
    canvas.drawLine(const Offset(10, 10), const Offset(10 + len, 10), paint);
    canvas.drawLine(const Offset(10, 10), const Offset(10, 10 + len), paint);

    // Top-Right corner
    canvas.drawLine(Offset(width - 10, 10), Offset(width - 10 - len, 10), paint);
    canvas.drawLine(Offset(width - 10, 10), Offset(width - 10, 10 + len), paint);

    // Bottom-Left corner
    canvas.drawLine(Offset(10, height - 10), Offset(10 + len, height - 10), paint);
    canvas.drawLine(Offset(10, height - 10), Offset(10, height - 10 - len), paint);

    // Bottom-Right corner
    canvas.drawLine(Offset(width - 10, height - 10), Offset(width - 10 - len, height - 10), paint);
    canvas.drawLine(Offset(width - 10, height - 10), Offset(width - 10, height - 10 - len), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
