import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';

class StatsDashboardScreen extends ConsumerWidget {
  const StatsDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : AppColors.textMain;
    final subtextColor = isDark ? Colors.white70 : AppColors.textLight;
    final cardColor = isDark ? AppColors.surfaceDark : AppColors.surfaceLight;
    final backgroundColor = isDark ? AppColors.backgroundDark : AppColors.backgroundLight;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: textColor),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Spending & Insights',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Premium Glassmorphic Stats Cards Row
              _buildCoreStatsCards(cardColor, isDark, textColor, subtextColor),
              const SizedBox(height: 25),

              // 2. Spending Trend Graph Section
              Text(
                'Monthly Spending Trend',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 12),
              _buildTrendGraphCard(cardColor, isDark, textColor, subtextColor),
              const SizedBox(height: 25),

              // 3. Category Breakdown Section
              Text(
                'Expense Category Breakdown',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 12),
              _buildCategoryBreakdownCard(cardColor, isDark, textColor, subtextColor),
              const SizedBox(height: 25),

              // 4. Smart Splitting Insights Section
              Text(
                'Smart Splitting Insights',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 12),
              _buildSmartInsightsCard(cardColor, isDark, textColor, subtextColor),
              const SizedBox(height: 25),

              // 5. Recent Activity Ledger
              Text(
                'Recent Stats Activity',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 12),
              _buildRecentActivityList(cardColor, isDark, textColor, subtextColor),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  // 1. Premium Stats Cards
  Widget _buildCoreStatsCards(Color cardColor, bool isDark, Color textColor, Color subtextColor) {
    return Column(
      children: [
        // Main Total Paid Card
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.primary, AppColors.primaryDark],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withOpacity(0.3),
                blurRadius: 15,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'TOTAL PAID TILL NOW',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.18),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'All Time',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Text(
                '\$1,420.50',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 38,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Includes individual settlements, group contributions, and direct payments.',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 15),

        // Saved vs Net Grid
        Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(isDark ? 0.2 : 0.03),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        color: AppColors.primaryTint,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.savings_outlined,
                        color: AppColors.primary,
                        size: 20,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Split Savings',
                      style: TextStyle(
                        fontSize: 12,
                        color: subtextColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '\$840.00',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(isDark ? 0.2 : 0.03),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.insights_rounded,
                        color: Colors.blue.shade600,
                        size: 20,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Net Balance',
                      style: TextStyle(
                        fontSize: 12,
                        color: subtextColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '+\$120.75',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // 2. Custom Painter Trend Graph Card
  Widget _buildTrendGraphCard(Color cardColor, bool isDark, Color textColor, Color subtextColor) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
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
                    'Spending Velocity',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Last 5 months stats',
                    style: TextStyle(
                      fontSize: 12,
                      color: subtextColor,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.primaryTint,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text(
                  '+12.4% MoM',
                  style: TextStyle(
                    color: AppColors.primaryDark,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 25),

          // Custom Paint Graph
          SizedBox(
            height: 150,
            width: double.infinity,
            child: CustomPaint(
              size: const Size(double.infinity, 150),
              painter: TrendLinePainter(
                data: [180.0, 240.0, 310.0, 280.0, 410.5],
                labels: ['Jan', 'Feb', 'Mar', 'Apr', 'May'],
                lineColor: AppColors.primary,
                gridColor: isDark ? Colors.white10 : Colors.grey.shade200,
                textColor: subtextColor,
              ),
            ),
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }

  // 3. Spending Category Breakdown Card
  Widget _buildCategoryBreakdownCard(Color cardColor, bool isDark, Color textColor, Color subtextColor) {
    final categories = [
      _CategoryData(
        name: 'Food & Dining',
        percentage: 0.40,
        amount: 568.20,
        icon: Icons.restaurant_rounded,
        color: const Color(0xFFFF9800),
      ),
      _CategoryData(
        name: 'Rent & Bills',
        percentage: 0.35,
        amount: 497.18,
        icon: Icons.home_work_rounded,
        color: const Color(0xFF673AB7),
      ),
      _CategoryData(
        name: 'Travel & Trips',
        percentage: 0.15,
        amount: 213.08,
        icon: Icons.directions_bus_rounded,
        color: const Color(0xFF03A9F4),
      ),
      _CategoryData(
        name: 'Entertainment',
        percentage: 0.10,
        amount: 142.05,
        icon: Icons.local_activity_rounded,
        color: const Color(0xFFE91E63),
      ),
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: categories.map((cat) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 18.0),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: cat.color.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        cat.icon,
                        color: cat.color,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            cat.name,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: textColor,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${(cat.percentage * 100).toInt()}% of total expenses',
                            style: TextStyle(
                              fontSize: 11,
                              color: subtextColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '\$${cat.amount.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: cat.percentage,
                    minHeight: 6,
                    backgroundColor: isDark ? Colors.white10 : Colors.grey.shade100,
                    valueColor: AlwaysStoppedAnimation<Color>(cat.color),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  // 4. Smart Splitting Insights Card
  Widget _buildSmartInsightsCard(Color cardColor, bool isDark, Color textColor, Color subtextColor) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildInsightRow(
            icon: Icons.people_alt_rounded,
            iconColor: AppColors.primary,
            title: 'Top Split Partner',
            value: 'Santosh Ray (Shared 8 bills)',
            textColor: textColor,
            subtextColor: subtextColor,
          ),
          const Divider(height: 24, thickness: 0.8),
          _buildInsightRow(
            icon: Icons.speed_rounded,
            iconColor: Colors.purple,
            title: 'Avg Settle Frequency',
            value: '0.2 hours (Instant settlements)',
            textColor: textColor,
            subtextColor: subtextColor,
          ),
          const Divider(height: 24, thickness: 0.8),
          _buildInsightRow(
            icon: Icons.verified_user_rounded,
            iconColor: Colors.blue.shade600,
            title: 'Splitting Reliability',
            value: '99.2% on-time payer status',
            textColor: textColor,
            subtextColor: subtextColor,
          ),
          const Divider(height: 24, thickness: 0.8),
          _buildInsightRow(
            icon: Icons.trending_up_rounded,
            iconColor: Colors.pink,
            title: 'Peak Spending Month',
            value: 'May (Rent & Group Travel)',
            textColor: textColor,
            subtextColor: subtextColor,
          ),
        ],
      ),
    );
  }

  Widget _buildInsightRow({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String value,
    required Color textColor,
    required Color subtextColor,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.08),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: iconColor, size: 22),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: TextStyle(
                  fontSize: 12,
                  color: subtextColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // 5. Recent Activity Ledger
  Widget _buildRecentActivityList(Color cardColor, bool isDark, Color textColor, Color subtextColor) {
    final activities = [
      _ActivityItem(
        title: 'Paid for Burgers Hangout',
        category: 'Food & Dining',
        amount: -25.00,
        date: 'Today, 2:15 PM',
        icon: Icons.restaurant_rounded,
        iconColor: const Color(0xFFFF9800),
      ),
      _ActivityItem(
        title: 'Settled owes with Anuska',
        category: 'Settlement',
        amount: -20.25,
        date: 'Yesterday, 6:40 PM',
        icon: Icons.check_circle_rounded,
        iconColor: AppColors.primary,
      ),
      _ActivityItem(
        title: 'Paid for Weekly Groceries',
        category: 'Food & Dining',
        amount: -48.50,
        date: '28 May 2026',
        icon: Icons.restaurant_rounded,
        iconColor: const Color(0xFFFF9800),
      ),
      _ActivityItem(
        title: 'Paid for Electric Bill',
        category: 'Rent & Bills',
        amount: -110.00,
        date: '25 May 2026',
        icon: Icons.home_work_rounded,
        iconColor: const Color(0xFF673AB7),
      ),
      _ActivityItem(
        title: 'Paid for Movie Night',
        category: 'Entertainment',
        amount: -15.00,
        date: '22 May 2026',
        icon: Icons.local_activity_rounded,
        iconColor: const Color(0xFFE91E63),
      ),
    ];

    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: activities.length,
        separatorBuilder: (context, index) => Divider(
          color: isDark ? Colors.white12 : Colors.grey.shade100,
          height: 1,
        ),
        itemBuilder: (context, index) {
          final act = activities[index];
          return ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            leading: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: act.iconColor.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(
                act.icon,
                color: act.iconColor,
                size: 20,
              ),
            ),
            title: Text(
              act.title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 2.0),
              child: Row(
                children: [
                  Text(
                    act.category,
                    style: TextStyle(
                      fontSize: 11,
                      color: subtextColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    width: 3,
                    height: 3,
                    decoration: BoxDecoration(
                      color: subtextColor.withOpacity(0.5),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    act.date,
                    style: TextStyle(
                      fontSize: 11,
                      color: subtextColor,
                    ),
                  ),
                ],
              ),
            ),
            trailing: Text(
              '-\$${act.amount.abs().toStringAsFixed(2)}',
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: AppColors.owe,
              ),
            ),
          );
        },
      ),
    );
  }
}

// Sparkline Custom Painter
class TrendLinePainter extends CustomPainter {
  final List<double> data;
  final List<String> labels;
  final Color lineColor;
  final Color gridColor;
  final Color textColor;

  TrendLinePainter({
    required this.data,
    required this.labels,
    required this.lineColor,
    required this.gridColor,
    required this.textColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    final double paddingLeft = 40.0;
    final double paddingRight = 15.0;
    final double paddingTop = 20.0;
    final double paddingBottom = 25.0;

    final double chartWidth = size.width - paddingLeft - paddingRight;
    final double chartHeight = size.height - paddingTop - paddingBottom;

    final double maxVal = data.reduce(max);
    final double minVal = 0.0; // Start chart from $0 for scaling comparison
    final double valRange = maxVal - minVal;

    final Paint gridPaint = Paint()
      ..color = gridColor
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    // Draw horizontal gridlines & Y axis values
    final int gridLinesCount = 3;
    for (int i = 0; i <= gridLinesCount; i++) {
      final double ratio = i / gridLinesCount;
      final double y = paddingTop + chartHeight * (1 - ratio);

      canvas.drawLine(
        Offset(paddingLeft, y),
        Offset(size.width - paddingRight, y),
        gridPaint,
      );

      final double priceVal = minVal + valRange * ratio;
      final textSpan = TextSpan(
        style: TextStyle(
          color: textColor,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
        text: '\$${priceVal.toInt()}',
      );
      final textPainter = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(paddingLeft - textPainter.width - 8, y - textPainter.height / 2),
      );
    }

    // Coordinates points
    final List<Offset> points = [];
    final double xIncrement = chartWidth / (data.length - 1);

    for (int i = 0; i < data.length; i++) {
      final double x = paddingLeft + i * xIncrement;
      final double y = paddingTop + chartHeight * (1 - (data[i] - minVal) / valRange);
      points.add(Offset(x, y));

      // Draw X axis label
      final labelSpan = TextSpan(
        style: TextStyle(
          color: textColor,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
        text: labels[i],
      );
      final labelPainter = TextPainter(
        text: labelSpan,
        textDirection: TextDirection.ltr,
      );
      labelPainter.layout();
      labelPainter.paint(
        canvas,
        Offset(x - labelPainter.width / 2, size.height - labelPainter.height),
      );
    }

    // Draw modern gradient fills under the line
    final Path fillPath = Path();
    fillPath.moveTo(points.first.dx, paddingTop + chartHeight);
    for (final pt in points) {
      fillPath.lineTo(pt.dx, pt.dy);
    }
    fillPath.lineTo(points.last.dx, paddingTop + chartHeight);
    fillPath.close();

    final Paint fillPaint = Paint()
      ..shader = LinearGradient(
        colors: [lineColor.withOpacity(0.35), lineColor.withOpacity(0.0)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTRB(paddingLeft, paddingTop, size.width - paddingRight, size.height - paddingBottom))
      ..style = PaintingStyle.fill;

    canvas.drawPath(fillPath, fillPaint);

    // Draw main Trend Line
    final Paint linePaint = Paint()
      ..color = lineColor
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final Path linePath = Path();
    linePath.moveTo(points.first.dx, points.first.dy);
    for (int i = 1; i < points.length; i++) {
      // Use smooth quadratic curves instead of rigid straight lines
      final xc = (points[i - 1].dx + points[i].dx) / 2;
      final yc = (points[i - 1].dy + points[i].dy) / 2;
      linePath.quadraticBezierTo(points[i - 1].dx, points[i - 1].dy, xc, yc);
    }
    linePath.lineTo(points.last.dx, points.last.dy);
    canvas.drawPath(linePath, linePaint);

    // Draw circular node points with dynamic shadow-like rings
    final Paint dotCorePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final Paint dotBorderPaint = Paint()
      ..color = lineColor
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;

    for (int i = 0; i < points.length; i++) {
      final pt = points[i];
      // Outer colored border ring
      canvas.drawCircle(pt, 5.5, Paint()..color = lineColor.withOpacity(0.2)..style = PaintingStyle.fill);
      canvas.drawCircle(pt, 4.0, dotCorePaint);
      canvas.drawCircle(pt, 4.0, dotBorderPaint);

      // Draw value on peak node
      if (i == points.length - 1 || i == 2) {
        final valSpan = TextSpan(
          style: TextStyle(
            color: lineColor,
            fontSize: 10,
            fontWeight: FontWeight.w900,
          ),
          text: '\$${data[i].toInt()}',
        );
        final valPainter = TextPainter(
          text: valSpan,
          textDirection: TextDirection.ltr,
        );
        valPainter.layout();
        valPainter.paint(
          canvas,
          Offset(pt.dx - valPainter.width / 2, pt.dy - valPainter.height - 6),
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant TrendLinePainter oldDelegate) {
    return oldDelegate.data != data ||
        oldDelegate.labels != labels ||
        oldDelegate.lineColor != lineColor ||
        oldDelegate.gridColor != gridColor ||
        oldDelegate.textColor != textColor;
  }
}

// Category helper model
class _CategoryData {
  final String name;
  final double percentage;
  final double amount;
  final IconData icon;
  final Color color;

  _CategoryData({
    required this.name,
    required this.percentage,
    required this.amount,
    required this.icon,
    required this.color,
  });
}

// Activity helper model
class _ActivityItem {
  final String title;
  final String category;
  final double amount;
  final String date;
  final IconData icon;
  final Color iconColor;

  _ActivityItem({
    required this.title,
    required this.category,
    required this.amount,
    required this.date,
    required this.icon,
    required this.iconColor,
  });
}
