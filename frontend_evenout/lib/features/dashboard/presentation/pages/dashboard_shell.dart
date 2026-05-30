import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../account/presentation/pages/account_screen.dart';
import 'home_screen.dart';

class DashboardShell extends StatefulWidget {
  const DashboardShell({super.key});

  @override
  State<DashboardShell> createState() => _DashboardShellState();
}

class _DashboardShellState extends State<DashboardShell> {
  int _currentIndex = 0;

  // Screens corresponding to each tab
  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      const HomeScreen(),
      const _PlaceholderScreen(title: 'Groups Listing', icon: Icons.group_outlined),
      const _PlaceholderScreen(title: 'Expenses History', icon: Icons.receipt_long_outlined),
      const AccountScreen(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final navBgColor = isDark ? AppColors.surfaceDark : Colors.white;
    final activeColor = AppColors.primary;
    final inactiveColor = isDark ? Colors.white38 : Colors.black38;

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      
      // Floating Action Button in center
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddExpenseOverlay(context, isDark),
        backgroundColor: AppColors.primary,
        elevation: 4,
        shape: const CircleBorder(),
        child: const Icon(Icons.add, size: 32, color: Colors.white),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      
      // Modern Bottom App Bar with Notch
      bottomNavigationBar: BottomAppBar(
        color: navBgColor,
        shape: const CircularNotchedRectangle(),
        notchMargin: 8.0,
        elevation: 10,
        padding: EdgeInsets.zero,
        height: 64,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavItem(0, Icons.grid_view_rounded, 'Home', activeColor, inactiveColor),
            _buildNavItem(1, Icons.group_outlined, 'Groups', activeColor, inactiveColor),
            const SizedBox(width: 44), // Empty space placeholder for Center Floating Action Button
            _buildNavItem(2, Icons.receipt_long_outlined, 'Expenses', activeColor, inactiveColor),
            _buildNavItem(3, Icons.person_outline, 'Account', activeColor, inactiveColor),
          ],
        ),
      ),
    );
  }

  // Navigation item constructor
  Widget _buildNavItem(int index, IconData icon, String label, Color activeColor, Color inactiveColor) {
    final isActive = _currentIndex == index;
    final color = isActive ? activeColor : inactiveColor;

    return Expanded(
      child: InkWell(
        onTap: () {
          setState(() {
            _currentIndex = index;
          });
        },
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedScale(
              scale: isActive ? 1.15 : 1.0,
              duration: const Duration(milliseconds: 150),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: color,
                fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Beautiful Add Expense overlay bottom sheet
  void _showAddExpenseOverlay(BuildContext context, bool isDark) {
    final sheetBg = isDark ? AppColors.surfaceDark : Colors.white;
    final titleColor = isDark ? Colors.white : AppColors.textMain;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          decoration: BoxDecoration(
            color: sheetBg,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: 15,
                spreadRadius: 2,
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Top drag indicator line
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white24 : Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Add New Expense',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: titleColor,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              
              // Option: Bill Scan
              _buildOverlayOption(
                icon: Icons.qr_code_scanner_outlined,
                iconBg: AppColors.primaryTint,
                iconColor: AppColors.primary,
                title: 'Bill Scan',
                subtitle: 'Scan printed bills automatically via AI parser',
                onTap: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Bill scan camera initialization coming soon!'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
                isDark: isDark,
              ),
              const SizedBox(height: 12),
              
              // Option: Manual Entry
              _buildOverlayOption(
                icon: Icons.edit_note_outlined,
                iconBg: Colors.blue.shade50,
                iconColor: Colors.blue.shade600,
                title: 'Manual Entry',
                subtitle: 'Enter transaction splits and details manually',
                onTap: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Manual expense entry editor coming soon!'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
                isDark: isDark,
              ),
              const SizedBox(height: 25),
            ],
          ),
        );
      },
    );
  }

  // Options item builder for Add Expense sheet
  Widget _buildOverlayOption({
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: isDark ? Colors.white10 : Colors.grey.shade200, width: 1.5),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: iconBg,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : AppColors.textMain,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? Colors.white60 : AppColors.textLight,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded, size: 14, color: isDark ? Colors.white30 : Colors.grey.shade400),
          ],
        ),
      ),
    );
  }
}

// Sub-screen placeholder
class _PlaceholderScreen extends StatelessWidget {
  final String title;
  final IconData icon;

  const _PlaceholderScreen({required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = isDark ? Colors.white : AppColors.textMain;

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 64, color: AppColors.primary.withOpacity(0.5)),
            const SizedBox(height: 16),
            Text(
              title,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color),
            ),
            const SizedBox(height: 8),
            Text(
              'Feature modules are currently under active development',
              style: TextStyle(fontSize: 12, color: isDark ? Colors.white60 : AppColors.textLight),
            ),
          ],
        ),
      ),
    );
  }
}
