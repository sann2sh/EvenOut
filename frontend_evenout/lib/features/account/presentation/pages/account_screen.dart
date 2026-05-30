import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/theme_provider.dart';

class AccountScreen extends ConsumerWidget {
  const AccountScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final themeMode = ref.watch(themeModeProvider);

    final textColor = isDark ? Colors.white : AppColors.textMain;
    final subtextColor = isDark ? Colors.white70 : AppColors.textLight;
    final cardColor = isDark ? AppColors.surfaceDark : AppColors.surfaceLight;

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Text(
                'My Account',
                style: Theme.of(context).textTheme.displayMedium?.copyWith(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
              ),
              const SizedBox(height: 25),

              // Profile Identity Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(isDark ? 0.2 : 0.04),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Avatar with Gradient Border
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [AppColors.primary, AppColors.primaryDark],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: const CircleAvatar(
                        radius: 46,
                        backgroundImage: NetworkImage('https://i.pravatar.cc/150?u=ashu'),
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Display Name
                    Text(
                      'Ashmit Ghimire',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    
                    // Email
                    Text(
                      'ashu.ghimire@evenout.com',
                      style: TextStyle(
                        fontSize: 14,
                        color: subtextColor,
                      ),
                    ),
                    const SizedBox(height: 6),

                    // Phone Number with Verified Badge
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.phone_android_outlined, size: 14, color: subtextColor),
                        const SizedBox(width: 4),
                        Text(
                          '+977 9801234567',
                          style: TextStyle(
                            fontSize: 13,
                            color: subtextColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.primaryTint,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: const [
                              Icon(Icons.check, size: 10, color: AppColors.primaryDark),
                              SizedBox(width: 2),
                              Text(
                                'Verified',
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primaryDark,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 25),

              // Split Score Section (Custom Gauge)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(isDark ? 0.2 : 0.04),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    const Text(
                      'Split Credibility Score',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 20),
                    
                    // Circular Gauge
                    SizedBox(
                      height: 140,
                      width: 140,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          CustomPaint(
                            size: const Size(140, 140),
                            painter: SplitScorePainter(
                              score: 96,
                              maxScore: 100,
                              trackColor: isDark ? Colors.white10 : Colors.grey.shade200,
                              fillGradient: const LinearGradient(
                                colors: [AppColors.primary, AppColors.primaryDark],
                                begin: Alignment.bottomLeft,
                                end: Alignment.topRight,
                              ),
                            ),
                          ),
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                '96',
                                style: TextStyle(
                                  fontSize: 36,
                                  fontWeight: FontWeight.w900,
                                  color: textColor,
                                ),
                              ),
                              Text(
                                'Excellent',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primaryDark,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    
                    // Split Level Badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.primaryTint,
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(Icons.stars_rounded, size: 16, color: AppColors.primaryDark),
                          SizedBox(width: 6),
                          Text(
                            'Elite Splitter Status',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primaryDark,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 15),

                    // Metrics Breakdown Grid
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildMetricCol('99.2%', 'On-Time', textColor, subtextColor),
                        Container(width: 1, height: 30, color: Colors.grey.shade300),
                        _buildMetricCol('0.2 hrs', 'Avg Settle', textColor, subtextColor),
                        Container(width: 1, height: 30, color: Colors.grey.shade300),
                        _buildMetricCol('12', 'Groups', textColor, subtextColor),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 25),

              // Wallet & Sync Panel
              Text(
                'Wallet & Sync Integration',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 12),
              
              // Esewa Sync Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(isDark ? 0.1 : 0.02),
                      blurRadius: 6,
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    // Esewa Green style circle
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.primaryTint,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.account_balance_wallet_outlined, color: AppColors.primary, size: 24),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'eSewa Balance Synced',
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: textColor),
                          ),
                          const SizedBox(height: 2),
                          const Text(
                            'Ready for instantly settling owes',
                            style: TextStyle(fontSize: 12, color: AppColors.primaryDark, fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.check_circle, color: AppColors.primary, size: 22),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Isar Queue Status Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(isDark ? 0.1 : 0.02),
                      blurRadius: 6,
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.cloud_done_outlined, color: Colors.blue.shade600, size: 24),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Offline Action Queue',
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: textColor),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Isar database synced (0 pending requests)',
                            style: TextStyle(fontSize: 12, color: subtextColor),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'ONLINE',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 25),

              // Theme Settings
              Text(
                'Interface Settings',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 12),

              // Theme Toggle Tile
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(isDark ? 0.1 : 0.02),
                      blurRadius: 6,
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Visual Theme',
                              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: textColor),
                            ),
                            Text(
                              'Choose your custom background mode',
                              style: TextStyle(fontSize: 12, color: subtextColor),
                            ),
                          ],
                        ),
                        Icon(
                          isDark ? Icons.nights_stay : Icons.wb_sunny,
                          color: isDark ? Colors.amber : Colors.orange,
                          size: 24,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(child: _buildThemeBtn(ref, ThemeMode.light, 'Light', themeMode == ThemeMode.light)),
                        const SizedBox(width: 8),
                        Expanded(child: _buildThemeBtn(ref, ThemeMode.dark, 'Dark', themeMode == ThemeMode.dark)),
                        const SizedBox(width: 8),
                        Expanded(child: _buildThemeBtn(ref, ThemeMode.system, 'System', themeMode == ThemeMode.system)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 25),

              // Actions list
              Container(
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(isDark ? 0.1 : 0.02),
                      blurRadius: 6,
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    _buildActionTile(
                      icon: Icons.notifications_none_outlined,
                      title: 'Notification Manager',
                      subtitle: 'Set split alerts & nudges',
                      textColor: textColor,
                      subtextColor: subtextColor,
                      onTap: () {},
                    ),
                    Divider(height: 1, color: isDark ? Colors.white12 : Colors.grey.shade100),
                    _buildActionTile(
                      icon: Icons.security_outlined,
                      title: 'Privacy & Security',
                      subtitle: 'Authentication and active sessions',
                      textColor: textColor,
                      subtextColor: subtextColor,
                      onTap: () {},
                    ),
                    Divider(height: 1, color: isDark ? Colors.white12 : Colors.grey.shade100),
                    _buildActionTile(
                      icon: Icons.help_outline_outlined,
                      title: 'Help Center',
                      subtitle: 'FAQ & customer support',
                      textColor: textColor,
                      subtextColor: subtextColor,
                      onTap: () {},
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),

              // Logout Button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: OutlinedButton.icon(
                  onPressed: () {
                    // Navigate back to Login Screen
                    context.go('/login');
                  },
                  icon: const Icon(Icons.logout_rounded, color: AppColors.owe),
                  label: const Text(
                    'SIGN OUT FROM EVENOUT',
                    style: TextStyle(
                      color: AppColors.owe,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      letterSpacing: 0.8,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.owe, width: 1.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  // Theme Mode Selection Button builder
  Widget _buildThemeBtn(WidgetRef ref, ThemeMode mode, String label, bool isSelected) {
    return InkWell(
      onTap: () => ref.read(themeModeProvider.notifier).state = mode,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected 
              ? AppColors.primary 
              : (Theme.of(ref.context).brightness == Brightness.dark 
                  ? Colors.white.withOpacity(0.04) 
                  : Colors.grey.shade100),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? AppColors.primary : Colors.transparent,
            width: 1,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: isSelected ? Colors.white : AppColors.primaryDark,
            ),
          ),
        ),
      ),
    );
  }

  // Metric grid helper
  Widget _buildMetricCol(String value, String label, Color textColor, Color subtextColor) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: subtextColor,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  // Action Tile helper
  Widget _buildActionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color textColor,
    required Color subtextColor,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.primaryTint,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: AppColors.primary, size: 20),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.bold,
          color: textColor,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: 12,
          color: subtextColor,
        ),
      ),
      trailing: Icon(Icons.arrow_forward_ios_rounded, size: 14, color: subtextColor),
      onTap: onTap,
    );
  }
}

// Split Score Radial Gauge Painter
class SplitScorePainter extends CustomPainter {
  final double score;
  final double maxScore;
  final Color trackColor;
  final Gradient fillGradient;

  SplitScorePainter({
    required this.score,
    required this.maxScore,
    required this.trackColor,
    required this.fillGradient,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double strokeWidth = 12.0;
    final Offset center = Offset(size.width / 2, size.height / 2);
    final double radius = min(size.width / 2, size.height / 2) - strokeWidth / 2;

    // Draw Background Track Ring (incomplete circle from 140 to 400 degrees)
    final Paint trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final double startAngle = 135 * pi / 180;
    final double sweepAngle = 270 * pi / 180;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      trackPaint,
    );

    // Draw Foreground Fill Ring with dynamic progress arc
    final double fillPercentage = score / maxScore;
    final double progressSweepAngle = sweepAngle * fillPercentage;

    final Paint fillPaint = Paint()
      ..shader = fillGradient.createShader(Rect.fromCircle(center: center, radius: radius))
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      progressSweepAngle,
      false,
      fillPaint,
    );
  }

  @override
  bool shouldRepaint(covariant SplitScorePainter oldDelegate) {
    return oldDelegate.score != score ||
        oldDelegate.maxScore != maxScore ||
        oldDelegate.trackColor != trackColor;
  }
}
