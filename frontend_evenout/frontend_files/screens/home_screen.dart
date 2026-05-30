import 'package:flutter/material.dart';

const Color appBrandGreen = Color(0xFF65C052);

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black;
    final bgColor = isDark ? const Color(0xFF121212) : const Color(0xFFF8F9FA);
    final cardColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;

    return Scaffold(
      backgroundColor: bgColor,
      // --- CUSTOM BOTTOM NAV ---
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        backgroundColor: appBrandGreen,
        elevation: 2,
        shape: const CircleBorder(),
        child: const Icon(Icons.add, size: 32, color: Colors.white),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomAppBar(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        shape: const CircularNotchedRectangle(),
        notchMargin: 8.0,
        child: SizedBox(
          height: 60,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(Icons.grid_view_rounded, 'Home', true, isDark),
              _buildNavItem(Icons.group_outlined, 'Groups', false, isDark),
              const SizedBox(width: 40), // Empty space for FAB
              _buildNavItem(Icons.receipt_long_outlined, 'Expenses', false, isDark),
              _buildNavItem(Icons.person_outline, 'Account', false, isDark),
            ],
          ),
        ),
      ),
      
      // --- MAIN CONTENT ---
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 10),
              // Top Bar
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Icon(Icons.search, color: appBrandGreen, size: 28),
                  Icon(Icons.settings_outlined, color: appBrandGreen, size: 28),
                ],
              ),
              const SizedBox(height: 20),
              
              // Greeting
              Text(
                'Hi, Ashu',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: textColor),
              ),
              const SizedBox(height: 20),

              // Total Balance Card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: appBrandGreen,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const CircleAvatar(
                      radius: 20,
                      backgroundImage: NetworkImage('https://i.pravatar.cc/150?u=ashu'), 
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Text('Total Balance', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w600)),
                              const SizedBox(width: 8),
                              Icon(Icons.visibility_off_outlined, size: 16, color: Colors.black.withOpacity(0.6)),
                            ],
                          ),
                          const SizedBox(height: 12),
                          _buildBalanceRow('\$ 125.50', 'you are owed'),
                          const SizedBox(height: 8),
                          _buildBalanceRow('\$ 75.25', 'you owe'),
                        ],
                      ),
                    ),
                    const Icon(Icons.sort, color: Colors.white),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Friends List
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                  ),
                  child: ListView.builder(
                    itemCount: mockBalances.length,
                    itemBuilder: (context, index) {
                      final friend = mockBalances[index];
                      return _buildFriendTile(friend, textColor, isDark);
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Helper for Balance Card rows
  Widget _buildBalanceRow(String amount, String subtitle) {
    return Row(
      children: [
        Text(amount, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black)),
        const SizedBox(width: 12),
        Text(subtitle, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black87)),
      ],
    );
  }

  // Helper for Bottom Nav Items
  Widget _buildNavItem(IconData icon, String label, bool isActive, bool isDark) {
    final color = isActive ? textColor : Colors.grey;
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, color: color),
        Text(label, style: TextStyle(fontSize: 12, color: color, fontWeight: isActive ? FontWeight.w600 : FontWeight.normal)),
      ],
    );
  }

  // Helper for Individual List Items
  Widget _buildFriendTile(FriendBalance friend, Color textColor, bool isDark) {
    // Determine balance text and color
    String balanceText = 'settled';
    Color balanceColor = Colors.grey;
    
    if (friend.amount != null) {
      balanceText = '\$${friend.amount!.abs().toStringAsFixed(2)}';
      balanceColor = friend.amount! > 0 ? appBrandGreen : const Color(0xFFE55C5C);
    }

    // If they have details, use an ExpansionTile
    if (friend.details != null && friend.details!.isNotEmpty) {
      return Theme(
        data: ThemeData(dividerColor: Colors.transparent), // Removes the borders on ExpansionTile
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          leading: CircleAvatar(
            radius: 24,
            backgroundImage: NetworkImage(friend.avatarUrl),
          ),
          title: Text(friend.name, style: TextStyle(fontSize: 16, color: textColor, fontWeight: FontWeight.w500)),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(balanceText, style: TextStyle(color: balanceColor, fontSize: 16, fontWeight: FontWeight.w500)),
              const SizedBox(width: 8),
              Icon(Icons.keyboard_arrow_down, color: isDark ? Colors.white54 : Colors.black54),
            ],
          ),
          children: friend.details!.map((detail) {
            return Padding(
              padding: const EdgeInsets.only(left: 80, right: 20, bottom: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  RichText(
                    text: TextSpan(
                      style: TextStyle(color: isDark ? Colors.white70 : Colors.black87, fontSize: 13),
                      children: [
                        TextSpan(text: '${detail.description} '),
                        TextSpan(text: '\$${detail.amount.toStringAsFixed(2)}', style: const TextStyle(color: appBrandGreen)),
                      ],
                    ),
                  ),
                  Text(detail.category, style: TextStyle(color: isDark ? Colors.white70 : Colors.black87, fontSize: 13)),
                ],
              ),
            );
          }).toList(),
        ),
      );
    }

    // Standard static tile for users without expanded details
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      leading: CircleAvatar(
        radius: 24,
        backgroundImage: NetworkImage(friend.avatarUrl),
      ),
      title: Text(friend.name, style: TextStyle(fontSize: 16, color: textColor, fontWeight: FontWeight.w500)),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(balanceText, style: TextStyle(color: balanceColor, fontSize: 16, fontWeight: FontWeight.w500)),
          const SizedBox(width: 8),
          Icon(Icons.keyboard_arrow_right, color: isDark ? Colors.white54 : Colors.black54),
        ],
      ),
    );
  }
}