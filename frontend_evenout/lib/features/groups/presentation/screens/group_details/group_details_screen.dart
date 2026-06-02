import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend_evenout/features/groups/data/groups_repository.dart';
import 'package:frontend_evenout/features/groups/presentation/providers/group_details_provider.dart';
import 'package:frontend_evenout/features/expenses/presentation/screens/add_expense/add_expense_screen.dart';
import '../esewa_payment/esewa_payment_screen.dart';
import 'widgets/group_hero_header.dart';
import 'widgets/group_stats_grid.dart';

class GroupDetailsScreen extends ConsumerStatefulWidget {
  final Group group;
  
  const GroupDetailsScreen({super.key, required this.group});

  @override
  ConsumerState<GroupDetailsScreen> createState() => _GroupDetailsScreenState();
}

class _GroupDetailsScreenState extends ConsumerState<GroupDetailsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isSettleOpen = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
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

    final detailsAsync = ref.watch(groupDetailsProvider(widget.group.id));
    final double totalGroupSpend = detailsAsync.valueOrNull?.totalSpend ?? 0.0;
    final double userBalance = detailsAsync.valueOrNull?.userShare ?? 0.0;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: textColor),
          onPressed: () => Navigator.pop(context),
        ),
        actions: const [
          SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // 1. Large Group Header Section
          GroupHeroHeader(
            group: widget.group,
            textColor: textColor,
            subtextColor: subtextColor,
          ),

          // 2. Spending Stat Highlights Grid
          GroupStatsGrid(
            totalGroupSpend: totalGroupSpend,
            userBalance: userBalance,
            isDark: isDark,
            cardColor: cardColor,
            textColor: textColor,
            subtextColor: subtextColor,
          ),

          // 3. Tab Segment Control
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
            decoration: BoxDecoration(
              color: isDark ? Colors.white10 : Colors.grey.shade200,
              borderRadius: BorderRadius.circular(12),
            ),
            child: TabBar(
              controller: _tabController,
              indicatorSize: TabBarIndicatorSize.tab,
              dividerColor: Colors.transparent,
              indicator: BoxDecoration(
                color: brandGreen,
                borderRadius: BorderRadius.circular(12),
              ),
              labelColor: Colors.white,
              unselectedLabelColor: subtextColor,
              labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              tabs: const [
                Tab(text: 'Transactions'),
                Tab(text: 'Members'),
              ],
            ),
          ),

          // 4. Tab View Lists
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // TAB 1: Transactions Log
                detailsAsync.when(
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (err, stack) => Center(child: Text('Error: $err')),
                  data: (data) {
                    if (data.transactions.isEmpty) {
                      return Center(
                        child: Text(
                          'No transactions yet',
                          style: TextStyle(color: subtextColor, fontSize: 14),
                        ),
                      );
                    }
                    return ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                      itemCount: data.transactions.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final tx = data.transactions[index];
                        if (tx is ExpenseTimelineItem) {
                          return Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: cardColor,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(isDark ? 0.15 : 0.02),
                                  blurRadius: 6,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF429246).withOpacity(0.08),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.receipt_long_rounded, color: Color(0xFF429246), size: 22),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        tx.title,
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          color: textColor,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Paid by ${tx.paidByName} • ${tx.date.toString().substring(0, 10)}',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: subtextColor,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Text(
                                  '\$${tx.amount.toStringAsFixed(2)}',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: textColor,
                                  ),
                                ),
                              ],
                            ),
                          );
                        } else if (tx is SettlementTimelineItem) {
                          return Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: cardColor,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(isDark ? 0.15 : 0.02),
                                  blurRadius: 6,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: Colors.blue.withOpacity(0.08),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.payment_rounded, color: Colors.blue, size: 22),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Settlement',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          color: textColor,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '${tx.payerName} paid ${tx.payeeName} • ${tx.date.toString().substring(0, 10)}',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: subtextColor,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Text(
                                  '\$${tx.amount.toStringAsFixed(2)}',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    );
                  },
                ),

                // TAB 2: Members
                detailsAsync.when(
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (err, stack) => Center(child: Text('Error: $err')),
                  data: (data) {
                    return ListView(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                      children: [
                        ...data.members.map((member) {
                          final double memBal = member.balance;
                          
                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            decoration: BoxDecoration(
                              color: cardColor,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(isDark ? 0.15 : 0.02),
                                  blurRadius: 6,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 18,
                                  backgroundColor: brandGreen.withOpacity(0.1),
                                  backgroundImage: member.avatarUrl != null ? NetworkImage(member.avatarUrl!) : null,
                                  child: member.avatarUrl == null ? Text(
                                    member.name.substring(0, 1).toUpperCase(),
                                    style: TextStyle(color: brandGreen, fontWeight: FontWeight.bold, fontSize: 13),
                                  ) : null,
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Text(
                                    member.name,
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: textColor,
                                    ),
                                  ),
                                ),
                                Row(
                                  children: [
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        Text(
                                          memBal > 0 
                                              ? 'Owed \$${memBal.toStringAsFixed(2)}'
                                              : memBal < 0
                                                  ? 'Owes \$${memBal.abs().toStringAsFixed(2)}'
                                                  : 'Settled',
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                            color: memBal > 0 
                                                ? const Color(0xFF2E7D32) 
                                                : memBal < 0
                                                    ? const Color(0xFFC62828)
                                                    : subtextColor,
                                          ),
                                        ),
                                      ],
                                    ),
                                    if (member.id != data.currentUserId && memBal < 0) ...[
                                      const SizedBox(width: 12),
                                      ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: brandGreen,
                                          foregroundColor: Colors.white,
                                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                          minimumSize: Size.zero,
                                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                        ),
                                        onPressed: () => _openSettleDrawer(context, member.id, member.name, memBal.abs(), brandGreen, cardColor, textColor, subtextColor),
                                        child: const Text(
                                          'Settle',
                                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ],
                            ),
                          );
                        }),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        color: isDark ? const Color(0xFF1E1E2E) : const Color(0xFFEDF0F5),
        padding: const EdgeInsets.fromLTRB(20.0, 8.0, 20.0, 20.0),
        child: ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: brandGreen,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            elevation: 1.5,
          ),
          onPressed: () async {
            final result = await Navigator.push<AddExpenseResult>(
              context,
              MaterialPageRoute(
                builder: (context) => AddExpenseScreen(
                  initialGroupId: widget.group.id,
                  initialGroupName: widget.group.name,
                ),
              ),
            );
            if (result != null) {
              ref.invalidate(groupDetailsProvider(widget.group.id));
            }
          },
          icon: const Icon(Icons.add_rounded, color: Colors.white),
          label: const Text(
            'Add Group Expense',
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 13, letterSpacing: 0.5),
          ),
        ),
      ),
    );
  }

  // 1. Invite QR Drawer Generator Modal
  // 2. Interactive Settle Up eSewa Simulation Drawer
  void _openSettleDrawer(
    BuildContext context, 
    String userId,
    String name, 
    double amount, 
    Color brandGreen, 
    Color cardColor, 
    Color textColor, 
    Color subtextColor,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDrawerState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 24.0, 
                right: 24.0, 
                top: 25.0, 
                bottom: MediaQuery.of(context).viewInsets.bottom + 30.0,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 40,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade400,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  const SizedBox(height: 25),
                  
                  // Payment Avatar Info
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: brandGreen.withOpacity(0.1),
                    child: Icon(Icons.payment_rounded, color: brandGreen, size: 30),
                  ),
                  const SizedBox(height: 14),
                  
                  Text(
                    'Settle Balance with $name',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Simulated Payment Gateway via eSewa Balance',
                    style: TextStyle(fontSize: 12, color: subtextColor),
                  ),
                  const SizedBox(height: 25),
                  
                  // Big Payment Display
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    decoration: BoxDecoration(
                      color: brandGreen.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: brandGreen.withOpacity(0.15)),
                    ),
                    child: Column(
                      children: [
                        const Text(
                          'AMOUNT TO TRANSFER',
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1.0, color: Colors.grey),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '\$${amount.toStringAsFixed(2)}',
                          style: TextStyle(fontSize: 36, fontWeight: FontWeight.w900, color: brandGreen),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 25),
                  
                  // Action Payment Button
                  _isSettleOpen 
                      ? const Column(
                          children: [
                            CircularProgressIndicator(color: Colors.green),
                            SizedBox(height: 12),
                            Text('Contacting eSewa secure balance gateway...', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
                          ],
                        )
                      : SizedBox(
                          width: double.infinity,
                          height: 54,
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF60BB46), // eSewa signature brand green
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                            onPressed: () {
                              Navigator.pop(context); // Close sheet
                              
                              // Launch secure eSewa mock portal check
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => EsewaPaymentScreen(
                                    payeeName: name,
                                    amount: amount,
                                    onPaymentSuccess: () {
                                        ref.invalidate(groupDetailsProvider(widget.group.id));
// Show confirmation SnackBar
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Row(
                                            children: [
                                              const Icon(Icons.check_circle_rounded, color: Colors.white),
                                              const SizedBox(width: 10),
                                              Text('Settled $name balance successfully via eSewa!'),
                                            ],
                                          ),
                                          backgroundColor: const Color(0xFF2E7D32),
                                          behavior: SnackBarBehavior.floating,
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              );
                            },
                            icon: const Icon(Icons.payment_rounded, color: Colors.white),
                            label: const Text(
                              'PAY VIA ESEWA PORTAL (TEST)',
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 0.8),
                            ),
                          ),
                        ),
                  const SizedBox(height: 10),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // 4. Interactive Friend Selector Drawer
}
