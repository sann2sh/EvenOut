import 'package:flutter/material.dart';
import '../../data/models/group_model.dart';
import 'package:frontend_evenout/features/expenses/presentation/pages/add_expense_screen.dart';
import 'esewa_payment_screen.dart';

class GroupDetailsScreen extends StatefulWidget {
  final EvenOutGroup group;
  
  const GroupDetailsScreen({super.key, required this.group});

  @override
  State<GroupDetailsScreen> createState() => _GroupDetailsScreenState();
}

class _GroupDetailsScreenState extends State<GroupDetailsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isSettleOpen = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
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

    final double totalGroupSpend = widget.group.totalExpenses;
    final double userBalance = widget.group.userBalance;

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
            onPressed: () => _showAddMemberFriendsDrawer(context, brandGreen, textColor, subtextColor, cardColor),
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
                _buildHeroAvatar(widget.group.avatarType, widget.group.avatarBgColor),
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
                        widget.group.lastActive,
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
                Tab(text: 'Expenses'),
                Tab(text: 'Members'),
                Tab(text: 'Insights'),
              ],
            ),
          ),

          // 4. Tab View Lists
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // TAB 1: Expenses Log
                widget.group.expenses.isEmpty
                    ? Center(
                        child: Text(
                          'No bills added yet',
                          style: TextStyle(color: subtextColor, fontSize: 14),
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                        itemCount: widget.group.expenses.length,
                        separatorBuilder: (context, index) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final expense = widget.group.expenses[index];
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
                                // Category Icon
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: expense.color.withOpacity(0.08),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(expense.icon, color: expense.color, size: 22),
                                ),
                                const SizedBox(width: 14),
                                
                                // Title Details
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        expense.title,
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          color: textColor,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Paid by ${expense.paidBy} • ${expense.date}',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: subtextColor,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                
                                // Price
                                Text(
                                  '\$${expense.amount.toStringAsFixed(2)}',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: textColor,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),

                // TAB 2: Members Splits Ledger
                ListView(
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
                          onTap: () => _showAddMemberFriendsDrawer(context, brandGreen, textColor, subtextColor, cardColor),
                        ),
                      ),
                    ),
                    
                    ...widget.group.members.map((member) {
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
                            // Custom Small Avatar
                            CircleAvatar(
                              radius: 18,
                              backgroundColor: brandGreen.withOpacity(0.1),
                              child: Text(
                                member.name.substring(0, 1).toUpperCase(),
                                style: TextStyle(color: brandGreen, fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                            ),
                            const SizedBox(width: 14),
                            
                            // Member Name
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
                            
                            // Balance Stats & Settle Button
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
                                
                                // Trigger eSewa Settle if they owe money
                                if (member.name != 'You' && memBal != 0.0) ...[
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
                                    onPressed: () => _openSettleDrawer(context, member.name, memBal.abs(), brandGreen, cardColor, textColor, subtextColor),
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
                ),
                
                // TAB 3: Group Insights Dashboard
                _buildGroupInsightsTab(isDark, cardColor, textColor, subtextColor, brandGreen),
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
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => AddExpenseScreen(initialGroupName: widget.group.name),
              ),
            );
            setState(() {}); // Refresh instantly to display newly added expense!
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
                                      setState(() {
                                        try {
                                          final target = widget.group.members.firstWhere((m) => m.name == name);
                                          target.balance = 0.0;
                                        } catch (_) {}
                                      });

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



  Widget _buildHeroAvatar(String type, Color bgColor) {
    if (type == 'diamond') {
      return Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          color: bgColor,
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.diamond_rounded,
          color: Colors.white,
          size: 28,
        ),
      );
    } else if (type == 'scenic') {
      return Container(
        width: 60,
        height: 60,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          image: DecorationImage(
            image: NetworkImage(
              'https://images.unsplash.com/photo-1464822759023-fed622ff2c3b?auto=format&fit=crop&w=150&q=80',
            ),
            fit: BoxFit.cover,
          ),
        ),
      );
    } else if (type == 'elephant') {
      return Container(
        width: 60,
        height: 60,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          image: DecorationImage(
            image: NetworkImage(
              'https://images.unsplash.com/photo-1557050543-4d5f4e07ef46?auto=format&fit=crop&w=150&q=80',
            ),
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
        .where((friend) => !widget.group.members.any((member) => member.name.toLowerCase() == friend['name']!.toLowerCase()))
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
                                setState(() {
                                  for (final friendName in selectedFriends) {
                                    widget.group.members.add(
                                      GroupMember(name: friendName, avatarUrl: '', balance: 0.0),
                                    );
                                  }
                                });

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

  Widget _buildGroupInsightsTab(bool isDark, Color cardColor, Color textColor, Color subtextColor, Color brandGreen) {
    final double totalGroupSpend = widget.group.totalExpenses;
    final double userBalance = widget.group.userBalance;

    // Determine top spender inside group
    String topSpenderName = 'You';
    double topSpenderAmt = 0.0;
    if (widget.group.expenses.isNotEmpty) {
      final Map<String, double> spenderMap = {};
      for (final exp in widget.group.expenses) {
        spenderMap[exp.paidBy] = (spenderMap[exp.paidBy] ?? 0.0) + exp.amount;
      }
      var maxAmt = -1.0;
      spenderMap.forEach((name, amt) {
        if (amt > maxAmt) {
          maxAmt = amt;
          topSpenderName = name;
          topSpenderAmt = amt;
        }
      });
    }

    // Determine category distribution dynamically
    final Map<String, double> catSums = {};
    for (final exp in widget.group.expenses) {
      final title = exp.title.toLowerCase();
      var cat = 'Others';
      if (title.contains('coffee') || title.contains('food') || title.contains('cafe') || title.contains('restaurant') || title.contains('momo') || title.contains('tea')) {
        cat = 'Food';
      } else if (title.contains('taxi') || title.contains('cab') || title.contains('ride') || title.contains('travel') || title.contains('fuel') || title.contains('gas')) {
        cat = 'Travel';
      } else if (title.contains('shopping') || title.contains('gift') || title.contains('clothes') || title.contains('mall')) {
        cat = 'Shopping';
      } else if (title.contains('movie') || title.contains('party') || title.contains('game') || title.contains('entertainment')) {
        cat = 'Entertainment';
      }
      catSums[cat] = (catSums[cat] ?? 0.0) + exp.amount;
    }
    // Default categories if empty
    if (catSums.isEmpty) {
      catSums['Food'] = 450.0;
      catSums['Travel'] = 120.0;
      catSums['Shopping'] = 300.0;
      catSums['Others'] = 150.0;
    }
    final double totalCatSum = catSums.values.fold(0.0, (sum, val) => sum + val);

    // Build trend graph data
    final List<double> graphValues = [];
    final List<String> graphLabels = [];
    if (widget.group.expenses.isNotEmpty) {
      final takeAmt = widget.group.expenses.take(5).toList();
      for (int i = takeAmt.length - 1; i >= 0; i--) {
        graphValues.add(takeAmt[i].amount);
        final label = takeAmt[i].title;
        graphLabels.add(label.length > 5 ? '${label.substring(0, 5)}..' : label);
      }
    }
    if (graphValues.length < 3) {
      graphValues.clear();
      graphLabels.clear();
      graphValues.addAll([120.0, 310.0, 180.0, 420.0, totalGroupSpend > 0 ? totalGroupSpend : 350.0]);
      graphLabels.addAll(['Jan', 'Feb', 'Mar', 'Apr', 'May']);
    }

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      children: [
        Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(isDark ? 0.2 : 0.02),
                      blurRadius: 6,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'YOUR SHARE BALANCE',
                      style: TextStyle(fontSize: 9, color: Colors.grey, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      userBalance > 0 
                          ? '+\$${userBalance.toStringAsFixed(2)}'
                          : userBalance < 0
                              ? '-\$${userBalance.abs().toStringAsFixed(2)}'
                              : '\$0.00',
                      style: TextStyle(
                        fontSize: 15, 
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
            const SizedBox(width: 12),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(isDark ? 0.2 : 0.02),
                      blurRadius: 6,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'TOP SPENDER',
                      style: TextStyle(fontSize: 9, color: Colors.grey, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '$topSpenderName (\$${topSpenderAmt.toStringAsFixed(0)})',
                      style: TextStyle(
                        fontSize: 14, 
                        fontWeight: FontWeight.bold, 
                        color: brandGreen,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),

        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.2 : 0.02),
                blurRadius: 6,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Group Spending Curve',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: textColor),
              ),
              const SizedBox(height: 4),
              Text(
                'Recent transaction timeline insights',
                style: TextStyle(fontSize: 11, color: subtextColor),
              ),
              const SizedBox(height: 20),
              SizedBox(
                height: 110,
                width: double.infinity,
                child: CustomPaint(
                  painter: GroupTrendLinePainter(
                    data: graphValues,
                    labels: graphLabels,
                    lineColor: brandGreen,
                    gridColor: isDark ? Colors.white10 : Colors.grey.shade200,
                    textColor: subtextColor,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),

        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.2 : 0.02),
                blurRadius: 6,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Category Breakdown',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: textColor),
              ),
              const SizedBox(height: 12),
              ...catSums.entries.map((e) {
                final catName = e.key;
                final amt = e.value;
                final ratio = totalCatSum > 0 ? amt / totalCatSum : 0.0;
                final percentage = (ratio * 100).toStringAsFixed(0);
                
                IconData catIcon = Icons.folder_open_rounded;
                Color catColor = brandGreen;
                if (catName == 'Food') {
                  catIcon = Icons.local_cafe_rounded;
                  catColor = Colors.orange;
                } else if (catName == 'Travel') {
                  catIcon = Icons.directions_car_rounded;
                  catColor = Colors.blue;
                } else if (catName == 'Shopping') {
                  catIcon = Icons.shopping_bag_rounded;
                  catColor = Colors.purple;
                } else if (catName == 'Entertainment') {
                  catIcon = Icons.videogame_asset_rounded;
                  catColor = Colors.red;
                }

                return Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 14,
                        backgroundColor: catColor.withOpacity(0.1),
                        child: Icon(catIcon, color: catColor, size: 14),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  catName,
                                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: textColor),
                                ),
                                Text(
                                  '\$${amt.toStringAsFixed(0)} ($percentage%)',
                                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: subtextColor),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: ratio,
                                minHeight: 5,
                                backgroundColor: isDark ? Colors.white10 : Colors.grey.shade200,
                                valueColor: AlwaysStoppedAnimation<Color>(catColor),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
        const SizedBox(height: 18),

        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.2 : 0.02),
                blurRadius: 6,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.psychology_outlined, color: Colors.blueAccent, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Smart Splitting Insights',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: textColor),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _buildSmartRow(
                Icons.check_circle_outline_rounded,
                'Smart ledger analysis matches direct eSewa deep links.',
                textColor,
              ),
              if (widget.group.expenses.isNotEmpty) ...[
                _buildSmartRow(
                  Icons.trending_up_rounded,
                  '$topSpenderName spent the most, covering ${widget.group.expenses.where((x) => x.paidBy == topSpenderName).length} expenses.',
                  textColor,
                ),
              ],
              _buildSmartRow(
                Icons.info_outline_rounded,
                userBalance > 0 
                    ? 'You are owed money. Complete pending settlements to cash out!'
                    : userBalance < 0
                        ? 'You owe money in this group. Use esewa settle up now!'
                        : 'Awesome! Your group balance is fully settled.',
                textColor,
              ),
            ],
          ),
        ),
        const SizedBox(height: 35),
      ],
    );
  }

  Widget _buildSmartRow(IconData icon, String text, Color textC) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.blueAccent, size: 14),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(fontSize: 11, color: textC.withOpacity(0.8), height: 1.3),
            ),
          ),
        ],
      ),
    );
  }
}

class GroupTrendLinePainter extends CustomPainter {
  final List<double> data;
  final List<String> labels;
  final Color lineColor;
  final Color gridColor;
  final Color textColor;

  GroupTrendLinePainter({
    required this.data,
    required this.labels,
    required this.lineColor,
    required this.gridColor,
    required this.textColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    final double paddingLeft = 32.0;
    final double paddingRight = 10.0;
    final double paddingTop = 15.0;
    final double paddingBottom = 15.0;

    final double chartWidth = size.width - paddingLeft - paddingRight;
    final double chartHeight = size.height - paddingTop - paddingBottom;

    final double maxVal = data.reduce((a, b) => a > b ? a : b);
    final double minVal = 0.0;
    final double valRange = maxVal > 0 ? maxVal - minVal : 1.0;

    final Paint gridPaint = Paint()
      ..color = gridColor
      ..strokeWidth = 0.8
      ..style = PaintingStyle.stroke;

    final Paint linePaint = Paint()
      ..color = lineColor
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final Paint fillPaint = Paint()
      ..color = lineColor.withOpacity(0.08)
      ..style = PaintingStyle.fill;

    final int linesCount = 2;
    for (int i = 0; i <= linesCount; i++) {
      final double ratio = i / linesCount;
      final double y = paddingTop + chartHeight * (1 - ratio);
      canvas.drawLine(Offset(paddingLeft, y), Offset(size.width - paddingRight, y), gridPaint);

      final priceVal = minVal + valRange * ratio;
      final textSpan = TextSpan(
        style: TextStyle(color: textColor, fontSize: 8, fontWeight: FontWeight.bold),
        text: '\$${priceVal.toInt()}',
      );
      final textPainter = TextPainter(text: textSpan, textDirection: TextDirection.ltr);
      textPainter.layout();
      textPainter.paint(canvas, Offset(paddingLeft - textPainter.width - 4, y - textPainter.height / 2));
    }

    final double stepX = chartWidth / (data.length - 1);
    final List<Offset> points = [];
    for (int i = 0; i < data.length; i++) {
      final double x = paddingLeft + i * stepX;
      final double ratio = (data[i] - minVal) / valRange;
      final double y = paddingTop + chartHeight * (1 - ratio);
      points.add(Offset(x, y));
    }

    final Path path = Path();
    path.moveTo(points[0].dx, points[0].dy);
    for (int i = 1; i < points.length; i++) {
      path.lineTo(points[i].dx, points[i].dy);
    }
    canvas.drawPath(path, linePaint);

    final Path fillPath = Path.from(path);
    fillPath.lineTo(points.last.dx, paddingTop + chartHeight);
    fillPath.lineTo(points.first.dx, paddingTop + chartHeight);
    fillPath.close();
    canvas.drawPath(fillPath, fillPaint);

    final Paint dotPaint = Paint()
      ..color = lineColor
      ..style = PaintingStyle.fill;
    final Paint whiteDotPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    for (final pt in points) {
      canvas.drawCircle(pt, 4.0, dotPaint);
      canvas.drawCircle(pt, 2.0, whiteDotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant GroupTrendLinePainter oldDelegate) => true;
}

// Custom Painter to draw a high-contrast premium QR code graphic mockup
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
