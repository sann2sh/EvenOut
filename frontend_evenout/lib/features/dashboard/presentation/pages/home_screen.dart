import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/models/expense_models.dart';

// Riverpod provider to manage balance visibility state
final balanceVisibilityProvider = StateProvider<bool>((ref) => true);

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isBalanceVisible = ref.watch(balanceVisibilityProvider);

    final textColor = isDark ? Colors.white : AppColors.textMain;
    final subtextColor = isDark ? Colors.white70 : AppColors.textLight;
    final cardColor = isDark ? AppColors.surfaceDark : AppColors.surfaceLight;

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 15),
              // Top Bar
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.search, color: AppColors.primary, size: 28),
                    onPressed: () {},
                  ),
                  IconButton(
                    icon: const Icon(Icons.settings_outlined, color: AppColors.primary, size: 28),
                    onPressed: () {},
                  ),
                ],
              ),
              const SizedBox(height: 15),
              
              // Greeting
              Text(
                'Hi, Ashu',
                style: Theme.of(context).textTheme.displayMedium?.copyWith(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
              ),
              const SizedBox(height: 20),

              // Total Balance Card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.primary, AppColors.primaryDark],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const CircleAvatar(
                      radius: 22,
                      backgroundImage: NetworkImage('https://i.pravatar.cc/150?u=ashu'), 
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Text(
                                'Total Balance', 
                                style: TextStyle(
                                  color: Colors.white, 
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(width: 8),
                              GestureDetector(
                                onTap: () => ref.read(balanceVisibilityProvider.notifier).state = !isBalanceVisible,
                                child: Icon(
                                  isBalanceVisible ? Icons.visibility_outlined : Icons.visibility_off_outlined, 
                                  size: 18, 
                                  color: Colors.white.withOpacity(0.8),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          _buildBalanceRow(
                            isBalanceVisible ? '\$125.50' : '••••••', 
                            'you are owed',
                            Colors.white,
                          ),
                          const SizedBox(height: 8),
                          _buildBalanceRow(
                            isBalanceVisible ? '\$75.25' : '••••••', 
                            'you owe',
                            Colors.white.withOpacity(0.9),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.sort, color: Colors.white),
                  ],
                ),
              ),
              const SizedBox(height: 25),

              // Friends Ledger Title
              Padding(
                padding: const EdgeInsets.only(left: 4, bottom: 12),
                child: Text(
                  'Friends Ledger',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
              ),

              // Friends List
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.03),
                        blurRadius: 10,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                    child: ListView.separated(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      itemCount: mockBalances.length,
                      separatorBuilder: (context, index) => Divider(
                        color: isDark ? Colors.white12 : Colors.grey.shade100,
                        height: 1,
                        indent: 80,
                      ),
                      itemBuilder: (context, index) {
                        final friend = mockBalances[index];
                        return _buildFriendTile(context, friend, textColor, subtextColor, isDark, isBalanceVisible);
                      },
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

  // Helper for Balance Card rows
  Widget _buildBalanceRow(String amount, String subtitle, Color color) {
    return Row(
      children: [
        Text(
          amount, 
          style: const TextStyle(
            fontSize: 20, 
            fontWeight: FontWeight.bold, 
            color: Colors.white,
          ),
        ),
        const SizedBox(width: 12),
        Text(
          subtitle, 
          style: TextStyle(
            fontSize: 13, 
            fontWeight: FontWeight.w500, 
            color: color,
          ),
        ),
      ],
    );
  }

  // Helper for Friend List Items (with expand/collapse details)
  Widget _buildFriendTile(BuildContext context, FriendBalance friend, Color textColor, Color subtextColor, bool isDark, bool isBalanceVisible) {
    String balanceText = 'settled';
    Color balanceColor = isDark ? Colors.white38 : Colors.grey;
    
    if (friend.amount != null) {
      if (isBalanceVisible) {
        balanceText = '\$${friend.amount!.abs().toStringAsFixed(2)}';
      } else {
        balanceText = '••••';
      }
      balanceColor = friend.amount! > 0 ? AppColors.settle : AppColors.owe;
    }

    final hasDetails = friend.details != null && friend.details!.isNotEmpty;

    if (hasDetails) {
      return Theme(
        data: Theme.of(context).copyWith(
          dividerColor: Colors.transparent,
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
        ),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
          leading: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.primary.withOpacity(0.2), width: 2),
            ),
            child: CircleAvatar(
              radius: 22,
              backgroundImage: NetworkImage(friend.avatarUrl),
            ),
          ),
          title: Text(
            friend.name, 
            style: TextStyle(
              fontSize: 16, 
              color: textColor, 
              fontWeight: FontWeight.w600,
            ),
          ),
          subtitle: Text(
            friend.amount != null 
              ? (friend.amount! > 0 ? 'owes you' : 'you owe') 
              : 'no active balance',
            style: TextStyle(
              fontSize: 12,
              color: subtextColor,
            ),
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                balanceText, 
                style: TextStyle(
                  color: balanceColor, 
                  fontSize: 16, 
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.keyboard_arrow_down, 
                color: subtextColor, 
                size: 20,
              ),
            ],
          ),
          children: friend.details!.map((detail) {
            return Container(
              margin: const EdgeInsets.only(left: 76, right: 20, bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark ? Colors.white.withOpacity(0.03) : Colors.grey.shade50,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          detail.description,
                          style: TextStyle(
                            color: textColor,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          detail.category,
                          style: TextStyle(
                            color: subtextColor,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    isBalanceVisible ? '\$${detail.amount.toStringAsFixed(2)}' : '••••',
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      );
    }

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      leading: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: Colors.transparent, width: 2),
        ),
        child: CircleAvatar(
          radius: 22,
          backgroundImage: NetworkImage(friend.avatarUrl),
        ),
      ),
      title: Text(
        friend.name, 
        style: TextStyle(
          fontSize: 16, 
          color: textColor, 
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(
        'settled up',
        style: TextStyle(
          fontSize: 12,
          color: subtextColor,
        ),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            balanceText, 
            style: TextStyle(
              color: balanceColor, 
              fontSize: 16, 
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 8),
          Icon(
            Icons.keyboard_arrow_right, 
            color: subtextColor, 
            size: 20,
          ),
        ],
      ),
      onTap: () {},
    );
  }
}
