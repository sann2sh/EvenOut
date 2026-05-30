import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/theme_provider.dart';
import 'stats_dashboard_screen.dart';
import '../../../user/presentation/providers/user_provider.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

class AccountScreen extends ConsumerWidget {
  const AccountScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final themeMode = ref.watch(themeModeProvider);

    final textColor = isDark ? Colors.white : AppColors.textMain;
    final subtextColor = isDark ? Colors.white70 : AppColors.textLight;
    final cardColor = isDark ? AppColors.surfaceDark : AppColors.surfaceLight;

    final userAsync = ref.watch(currentUserProvider);

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      body: SafeArea(
        child: userAsync.when(
          loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
          error: (err, _) => Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 48, color: AppColors.primary),
                const SizedBox(height: 12),
                Text('Failed to load profile', style: TextStyle(color: textColor)),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: () => ref.invalidate(currentUserProvider),
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                  child: const Text('Retry', style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
          ),
          data: (user) {
            final scoreValue = user.splitScore.clamp(0, 100).toDouble();
            final scoreLabel = _getScoreLabel(scoreValue);

            return SingleChildScrollView(
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
                          child: CircleAvatar(
                            radius: 46,
                            backgroundImage: user.avatarUrl != null && user.avatarUrl!.isNotEmpty
                                ? NetworkImage(user.avatarUrl!)
                                : null,
                            child: user.avatarUrl == null || user.avatarUrl!.isEmpty
                                ? Text(
                                    (user.displayName ?? user.username ?? 'U')[0].toUpperCase(),
                                    style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold),
                                  )
                                : null,
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Display Name
                        Text(
                          user.displayName ?? user.username ?? 'User',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: textColor,
                          ),
                        ),
                        if (user.username != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            '@${user.username}',
                            style: TextStyle(fontSize: 13, color: subtextColor),
                          ),
                        ],
                        const SizedBox(height: 4),

                        // Email
                        Text(
                          user.email ?? '',
                          style: TextStyle(
                            fontSize: 14,
                            color: subtextColor,
                          ),
                        ),
                        const SizedBox(height: 6),

                        // Phone Number
                        if (user.phoneNumber != null && user.phoneNumber!.isNotEmpty)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.phone_android_outlined, size: 14, color: subtextColor),
                              const SizedBox(width: 4),
                              Text(
                                user.phoneNumber!,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: subtextColor,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 25),

                  // Split Score Section
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
                                  score: scoreValue,
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
                                    scoreValue.toInt().toString(),
                                    style: TextStyle(
                                      fontSize: 36,
                                      fontWeight: FontWeight.w900,
                                      color: textColor,
                                    ),
                                  ),
                                  Text(
                                    scoreLabel,
                                    style: const TextStyle(
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
                            children: [
                              const Icon(Icons.stars_rounded, size: 16, color: AppColors.primaryDark),
                              const SizedBox(width: 6),
                              Text(
                                '$scoreLabel Splitter Status',
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primaryDark,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 25),

                  // Wallet & Sync Panel
                  Text(
                    'Wallet & Sync Integration',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textColor),
                  ),
                  const SizedBox(height: 12),

                  // Esewa Sync Card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(isDark ? 0.1 : 0.02), blurRadius: 6)],
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: const BoxDecoration(color: AppColors.primaryTint, shape: BoxShape.circle),
                          child: const Icon(Icons.account_balance_wallet_outlined, color: AppColors.primary, size: 24),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('eSewa Balance Synced', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: textColor)),
                              const SizedBox(height: 2),
                              const Text('Ready for instantly settling owes', style: TextStyle(fontSize: 12, color: AppColors.primaryDark, fontWeight: FontWeight.w500)),
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
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(isDark ? 0.1 : 0.02), blurRadius: 6)],
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(color: Colors.blue.shade50, shape: BoxShape.circle),
                          child: Icon(Icons.cloud_done_outlined, color: Colors.blue.shade600, size: 24),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Offline Action Queue', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: textColor)),
                              const SizedBox(height: 2),
                              Text('Isar database synced (0 pending requests)', style: TextStyle(fontSize: 12, color: subtextColor)),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(8)),
                          child: Text('ONLINE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.blue.shade600)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 25),

                  // Theme Settings
                  Text('Interface Settings', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textColor)),
                  const SizedBox(height: 12),

                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(isDark ? 0.1 : 0.02), blurRadius: 6)],
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
                                Text('Visual Theme', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: textColor)),
                                Text('Choose your custom background mode', style: TextStyle(fontSize: 12, color: subtextColor)),
                              ],
                            ),
                            Icon(isDark ? Icons.nights_stay : Icons.wb_sunny, color: isDark ? Colors.amber : Colors.orange, size: 24),
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
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(isDark ? 0.1 : 0.02), blurRadius: 6)],
                    ),
                    child: Column(
                      children: [
                        _buildActionTile(icon: Icons.notifications_none_outlined, title: 'Notification Manager', subtitle: 'Set split alerts & nudges', textColor: textColor, subtextColor: subtextColor, onTap: () {}),
                        Divider(height: 1, color: isDark ? Colors.white12 : Colors.grey.shade100),
                        _buildActionTile(icon: Icons.security_outlined, title: 'Privacy & Security', subtitle: 'Authentication and active sessions', textColor: textColor, subtextColor: subtextColor, onTap: () {}),
                        Divider(height: 1, color: isDark ? Colors.white12 : Colors.grey.shade100),
                        _buildActionTile(icon: Icons.help_outline_outlined, title: 'Help Center', subtitle: 'FAQ & customer support', textColor: textColor, subtextColor: subtextColor, onTap: () {}),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),

                  // Sign Out Button
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        await ref.read(authNotifierProvider.notifier).signOut();
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
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  String _getScoreLabel(double score) {
    if (score >= 90) return 'Elite';
    if (score >= 70) return 'Great';
    if (score >= 50) return 'Good';
    if (score >= 30) return 'Fair';
    return 'Improving';
  }

  Widget _buildThemeBtn(WidgetRef ref, ThemeMode mode, String label, bool isSelected) {
    return InkWell(
      onTap: () => ref.read(themeModeProvider.notifier).state = mode,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary
              : (Theme.of(ref.context).brightness == Brightness.dark ? Colors.white.withOpacity(0.04) : Colors.grey.shade100),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: isSelected ? AppColors.primary : Colors.transparent, width: 1),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: isSelected ? Colors.white : AppColors.primaryDark),
          ),
        ),
      ),
    );
  }

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
        decoration: const BoxDecoration(color: AppColors.primaryTint, shape: BoxShape.circle),
        child: Icon(icon, color: AppColors.primary, size: 20),
      ),
      title: Text(title, style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: textColor)),
      subtitle: Text(subtitle, style: TextStyle(fontSize: 12, color: subtextColor)),
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
