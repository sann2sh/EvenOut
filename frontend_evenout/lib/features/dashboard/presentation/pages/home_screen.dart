import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../providers/home_provider.dart';

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

    final homeAsync = ref.watch(homeDataProvider);

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: homeAsync.when(
            loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
            error: (err, _) => Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.cloud_off_outlined, size: 48, color: AppColors.primary),
                  const SizedBox(height: 12),
                  Text('Could not load data', style: TextStyle(color: textColor, fontSize: 16)),
                  const SizedBox(height: 8),
                  Text(err.toString(), style: TextStyle(color: subtextColor, fontSize: 12), textAlign: TextAlign.center),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => ref.invalidate(homeDataProvider),
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                    child: const Text('Retry', style: TextStyle(color: Colors.white)),
                  ),
                ],
              ),
            ),
            data: (homeData) {
              final user = homeData.user;
              final friends = homeData.friends;
              final greeting = user.displayName?.split(' ').first ?? user.username ?? 'there';

              return Column(
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
                    'Hi, $greeting',
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
                      gradient: const LinearGradient(
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
                        CircleAvatar(
                          radius: 22,
                          backgroundImage: user.avatarUrl != null && user.avatarUrl!.isNotEmpty
                              ? NetworkImage(user.avatarUrl!)
                              : null,
                          child: user.avatarUrl == null || user.avatarUrl!.isEmpty
                              ? Text(
                                  (user.displayName ?? 'U')[0].toUpperCase(),
                                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                                )
                              : null,
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
                                isBalanceVisible ? 'Rs ${homeData.totalOwed.toStringAsFixed(2)}' : '••••••',
                                'you are owed',
                                Colors.white,
                              ),
                              const SizedBox(height: 8),
                              _buildBalanceRow(
                                isBalanceVisible ? 'Rs ${homeData.totalOwing.toStringAsFixed(2)}' : '••••••',
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
                      child: friends.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.people_outline, size: 48, color: subtextColor),
                                  const SizedBox(height: 12),
                                  Text(
                                    'No friends yet',
                                    style: TextStyle(color: subtextColor, fontSize: 16),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Add friends to start splitting expenses',
                                    style: TextStyle(color: subtextColor, fontSize: 12),
                                  ),
                                ],
                              ),
                            )
                          : ClipRRect(
                              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                              child: ListView.separated(
                                padding: const EdgeInsets.symmetric(vertical: 10),
                                itemCount: friends.length,
                                separatorBuilder: (context, index) => Divider(
                                  color: isDark ? Colors.white12 : Colors.grey.shade100,
                                  height: 1,
                                  indent: 80,
                                ),
                                itemBuilder: (context, index) {
                                  final friend = friends[index];
                                  return _buildFriendTile(friend, textColor, subtextColor, isDark, isBalanceVisible);
                                },
                              ),
                            ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

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

  Widget _buildFriendTile(FriendWithBalance friend, Color textColor, Color subtextColor, bool isDark, bool isBalanceVisible) {
    String balanceText = 'settled';
    Color balanceColor = isDark ? Colors.white38 : Colors.grey;

    if (friend.netBalance != 0) {
      if (isBalanceVisible) {
        balanceText = 'Rs ${friend.netBalance.abs().toStringAsFixed(2)}';
      } else {
        balanceText = '••••';
      }
      balanceColor = friend.netBalance > 0 ? AppColors.settle : AppColors.owe;
    }

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      leading: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: friend.netBalance > 0
                ? AppColors.primary.withOpacity(0.2)
                : Colors.transparent,
            width: 2,
          ),
        ),
        child: CircleAvatar(
          radius: 22,
          backgroundImage: friend.avatarUrl != null && friend.avatarUrl!.isNotEmpty
              ? NetworkImage(friend.avatarUrl!)
              : null,
          child: friend.avatarUrl == null || friend.avatarUrl!.isEmpty
              ? Text(
                  friend.name[0].toUpperCase(),
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                )
              : null,
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
        friend.netBalance > 0
            ? 'owes you'
            : friend.netBalance < 0
                ? 'you owe'
                : 'settled up',
        style: TextStyle(fontSize: 12, color: subtextColor),
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
          Icon(Icons.keyboard_arrow_right, color: subtextColor, size: 20),
        ],
      ),
      onTap: () {},
    );
  }
}
