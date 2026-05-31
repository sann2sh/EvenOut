import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/groups_repository.dart';
import '../providers/group_details_provider.dart';
import 'package:frontend_evenout/features/expenses/presentation/pages/add_expense_screen.dart';
import 'esewa_payment_screen.dart';

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
        actions: [
          // Add Member from Friend List
          IconButton(
            icon: Icon(Icons.person_add_rounded, color: brandGreen, size: 26),
            onPressed: () {
              final currentMembers = ref.read(groupDetailsProvider(widget.group.id)).valueOrNull?.members ?? [];
              _showAddMemberFriendsDrawer(context, brandGreen, textColor, subtextColor, cardColor, currentMembers);
            },
          ),
          // Invite deep-link QR option
          IconButton(
            icon: Icon(Icons.qr_code_2_rounded, color: brandGreen, size: 28),
            onPressed: () => _showInviteQRCode(context, brandGreen, textColor, subtextColor, cardColor),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // 1. Large Group Header Section
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
            child: Row(
              children: [
                _buildHeroAvatar(widget.group.avatarUrl ?? ''),
                const SizedBox(width: 20.0),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.group.name,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                      const SizedBox(height: 4.0),
                      Text(
                        (widget.group.description ?? 'Active recently'),
                        style: TextStyle(
                          fontSize: 12,
                          color: subtextColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // 2. Spending Stat Highlights Grid
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 15.0),
            child: Row(
              children: [
                // Total group spending
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(isDark ? 0.2 : 0.03),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Total Spend',
                          style: TextStyle(fontSize: 12, color: subtextColor, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '\$${totalGroupSpend.toStringAsFixed(2)}',
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: textColor),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 15.0),
                
                // User active split balance inside this group
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(isDark ? 0.2 : 0.03),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Your Share',
                          style: TextStyle(fontSize: 12, color: subtextColor, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          userBalance > 0 
                              ? '+\$${userBalance.toStringAsFixed(2)}'
                              : userBalance < 0
                                  ? '-\$${userBalance.abs().toStringAsFixed(2)}'
                                  : '\$0.00',
                          style: TextStyle(
                            fontSize: 20, 
                            fontWeight: FontWeight.bold, 
                            color: userBalance > 0 
                                ? const Color(0xFF2E7D32) 
                                : userBalance < 0
                                    ? const Color(0xFFC62828)
                                    : textColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
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
                        // Dynamic clickable "Add Member from Friends" item
                        Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: cardColor,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: brandGreen.withOpacity(0.3), width: 1.5),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(isDark ? 0.15 : 0.02),
                                blurRadius: 6,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Material(
                            color: Colors.transparent,
                            borderRadius: BorderRadius.circular(16),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: brandGreen.withOpacity(0.1),
                                child: Icon(Icons.person_add_alt_1_rounded, color: brandGreen),
                              ),
                              title: Text(
                                'Add member from friends...',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: brandGreen,
                                ),
                              ),
                              trailing: Icon(Icons.arrow_forward_ios_rounded, size: 14, color: brandGreen),
                              onTap: () => _showAddMemberFriendsDrawer(context, brandGreen, textColor, subtextColor, cardColor, data.members),
                            ),
                          ),
                        ),
                        
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
  void _showInviteQRCode(
    BuildContext context, 
    Color brandGreen, 
    Color textColor, 
    Color subtextColor, 
    Color cardColor,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        final String deepLink = 'evenout://join-group?id=${widget.group.id}';
        
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 30.0),
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
              Text(
                'Invite to ${widget.group.name}',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor),
              ),
              const SizedBox(height: 6),
              Text(
                'Let others scan to join this group instantly',
                style: TextStyle(fontSize: 12, color: subtextColor),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 25),
              
              // Custom Painted Vector QR Code Box
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: SizedBox(
                  width: 170,
                  height: 170,
                  child: CustomPaint(
                    painter: QRMockPainter(brandColor: brandGreen),
                  ),
                ),
              ),
              
              const SizedBox(height: 20),
              
              // Shareable text link
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: brandGreen.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: brandGreen.withOpacity(0.2)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.link_rounded, color: Colors.green, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        deepLink,
                        style: TextStyle(
                          fontSize: 12, 
                          color: brandGreen, 
                          fontWeight: FontWeight.w600,
                          fontFamily: 'monospace',
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Row(
                              children: [
                                Icon(Icons.check_circle_rounded, color: Colors.white),
                                SizedBox(width: 10),
                                Text('Invite deep-link copied to clipboard!'),
                              ],
                            ),
                            backgroundColor: brandGreen,
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        );
                      },
                      child: Icon(Icons.copy_all_rounded, color: brandGreen, size: 20),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 15),
            ],
          ),
        );
      },
    );
  }

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



  Widget _buildHeroAvatar(String avatarUrl) {
    if (avatarUrl.isNotEmpty) {
      return Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          image: DecorationImage(
            image: NetworkImage(avatarUrl),
            fit: BoxFit.cover,
          ),
        ),
      );
    } else {
      return Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          color: Colors.grey.shade400,
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.group_rounded, color: Colors.white, size: 28),
      );
    }
  }

  // 4. Interactive Friend Selector Drawer
  void _showAddMemberFriendsDrawer(
    BuildContext context,
    Color brandGreen,
    Color textColor,
    Color subtextColor,
    Color cardColor,
    List<GroupMemberUserWithBalance> currentMembers,
  ) {
    final List<Map<String, String>> mockFriends = [
      {'name': 'Anuska Parajuli', 'initial': 'AP', 'color': '0xFF9C27B0'},
      {'name': 'Santosh Ray', 'initial': 'SR', 'color': '0xFF3F51B5'},
      {'name': 'Subash Gaire', 'initial': 'SG', 'color': '0xFF009688'},
      {'name': 'Prajwol Shrestha', 'initial': 'PS', 'color': '0xFFFF5722'},
      {'name': 'Elle Johnson', 'initial': 'EJ', 'color': '0xFFE91E63'},
      {'name': 'Earl Myers', 'initial': 'EM', 'color': '0xFF4CAF50'},
      {'name': 'Ramesh KC', 'initial': 'RK', 'color': '0xFFFF9800'},
    ];

    // Filter out friends already inside this group members list
    final List<Map<String, String>> remainingFriends = mockFriends
        .where((friend) => !currentMembers.any((member) => member.name.toLowerCase() == friend['name']!.toLowerCase()))
        .toList();

    final List<String> selectedFriends = [];

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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade400,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 25),
                  Text(
                    'Add Members from Friends',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Directly add active friends to ${widget.group.name}',
                    style: TextStyle(fontSize: 12, color: subtextColor),
                  ),
                  const SizedBox(height: 20),

                  if (remainingFriends.isEmpty)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 30.0),
                        child: Column(
                          children: [
                            Icon(Icons.people_outline_rounded, size: 48, color: subtextColor.withOpacity(0.5)),
                            const SizedBox(height: 12),
                            Text(
                              'All your friends are already in this group!',
                              style: TextStyle(fontSize: 13, color: subtextColor, fontWeight: FontWeight.bold),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    )
                  else ...[
                    // Scrollable Friends list inside drawer
                    Container(
                      constraints: const BoxConstraints(maxHeight: 250),
                      child: ListView.separated(
                        shrinkWrap: true,
                        itemCount: remainingFriends.length,
                        separatorBuilder: (context, index) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final friend = remainingFriends[index];
                          final name = friend['name']!;
                          final initial = friend['initial']!;
                          final colorHex = int.parse(friend['color']!);
                          final isSelected = selectedFriends.contains(name);
                          return Material(
                            color: Colors.transparent,
                            child: ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: CircleAvatar(
                                radius: 16,
                                backgroundColor: Color(colorHex),
                                child: Text(
                                  initial,
                                  style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                                ),
                              ),
                              title: Text(
                                name,
                                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: textColor),
                              ),
                              trailing: Container(
                                width: 20,
                                height: 20,
                                decoration: BoxDecoration(
                                  color: isSelected ? brandGreen : Colors.transparent,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: isSelected ? brandGreen : Colors.grey.shade400,
                                    width: 1.5,
                                  ),
                                ),
                                child: isSelected
                                    ? const Icon(Icons.check, size: 12, color: Colors.white)
                                    : null,
                              ),
                              onTap: () {
                                setDrawerState(() {
                                  if (isSelected) {
                                    selectedFriends.remove(name);
                                  } else {
                                    selectedFriends.add(name);
                                  }
                                });
                              },
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 25),

                    // Add button action
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: brandGreen,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        onPressed: selectedFriends.isEmpty
                            ? null
                            : () {
                                // Fake add for mock friends
                                // ref.invalidate(groupDetailsProvider(widget.group.id));

                                Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Row(
                                      children: [
                                        const Icon(Icons.people_alt_rounded, color: Colors.white),
                                        const SizedBox(width: 10),
                                        Text('Added ${selectedFriends.length} friends to "${widget.group.name}"!'),
                                      ],
                                    ),
                                    backgroundColor: brandGreen,
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              },
                        child: Text(
                          selectedFriends.isEmpty
                              ? 'SELECT FRIENDS TO ADD'
                              : 'ADD ${selectedFriends.length} SELECTED FRIENDS',
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 0.8),
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 10),
                ],
              ),
            );
          },
        );
      },
    );
  }

}

class QRMockPainter extends CustomPainter {
  final Color brandColor;

  QRMockPainter({required this.brandColor});

  @override
  void paint(Canvas canvas, Size size) {
    final Paint activePaint = Paint()
      ..color = const Color(0xFF1B1B3A)
      ..style = PaintingStyle.fill;

    final Paint borderPaint = Paint()
      ..color = brandColor
      ..strokeWidth = 3.5
      ..style = PaintingStyle.stroke;

    final double squareSize = size.width;
    final double block = squareSize / 9;

    // 1. Draw top-left focus box
    canvas.drawRect(Rect.fromLTWH(0, 0, block * 3, block * 3), borderPaint);
    canvas.drawRect(Rect.fromLTWH(block * 0.75, block * 0.75, block * 1.5, block * 1.5), activePaint);

    // 2. Draw top-right focus box
    canvas.drawRect(Rect.fromLTWH(block * 6, 0, block * 3, block * 3), borderPaint);
    canvas.drawRect(Rect.fromLTWH(block * 6.75, block * 0.75, block * 1.5, block * 1.5), activePaint);

    // 3. Draw bottom-left focus box
    canvas.drawRect(Rect.fromLTWH(0, block * 6, block * 3, block * 3), borderPaint);
    canvas.drawRect(Rect.fromLTWH(block * 0.75, block * 6.75, block * 1.5, block * 1.5), activePaint);

    // 4. Draw random mock data dots
    final List<Offset> mockDataPositions = [
      Offset(block * 4.5, block * 0.5),
      Offset(block * 4.5, block * 1.5),
      Offset(block * 5.0, block * 2.5),
      Offset(block * 1.5, block * 4.5),
      Offset(block * 2.5, block * 4.5),
      Offset(block * 3.5, block * 3.5),
      Offset(block * 3.5, block * 5.0),
      Offset(block * 4.5, block * 4.5),
      Offset(block * 5.5, block * 4.5),
      Offset(block * 6.5, block * 3.5),
      Offset(block * 7.5, block * 4.5),
      Offset(block * 8.5, block * 5.5),
      Offset(block * 4.5, block * 6.5),
      Offset(block * 5.5, block * 7.5),
      Offset(block * 6.5, block * 6.5),
      Offset(block * 7.5, block * 7.5),
      Offset(block * 8.5, block * 8.5),
    ];

    for (final pos in mockDataPositions) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: pos, width: block * 0.7, height: block * 0.7),
          Radius.circular(block * 0.15),
        ),
        activePaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
