import 'package:flutter/material.dart';
import '../../data/models/group_model.dart';
import 'group_details_screen.dart';
import 'create_group_screen.dart';
import 'join_group_screen.dart';

class GroupsScreen extends StatefulWidget {
  const GroupsScreen({super.key});

  @override
  State<GroupsScreen> createState() => _GroupsScreenState();
}

class _GroupsScreenState extends State<GroupsScreen> {
  String _searchQuery = '';
  bool _isSearchExpanded = false;
  final TextEditingController _searchController = TextEditingController();

  List<EvenOutGroup> get _filteredGroups {
    if (_searchQuery.isEmpty) {
      return mockGroups;
    }
    return mockGroups
        .where((group) =>
            group.name.toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    // Sleek theme-specific values
    final Color backgroundColor = isDark ? const Color(0xFF121212) : const Color(0xFFFAFAFA);
    final Color cardColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final Color textColor = isDark ? Colors.white : const Color(0xFF1B1B3A);
    final Color subtextColor = isDark ? Colors.white60 : Colors.black54;
    final Color brandGreen = const Color(0xFF429246);

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Header Search & Title Row
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 15.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Search expandable container
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                    width: _isSearchExpanded ? MediaQuery.of(context).size.width * 0.70 : 44.0,
                    height: 44.0,
                    decoration: BoxDecoration(
                      color: _isSearchExpanded 
                          ? (isDark ? Colors.white12 : Colors.grey.shade100) 
                          : brandGreen,
                      shape: _isSearchExpanded ? BoxShape.rectangle : BoxShape.circle,
                      borderRadius: _isSearchExpanded ? BorderRadius.circular(22) : null,
                      boxShadow: [
                        if (!_isSearchExpanded)
                          BoxShadow(
                            color: brandGreen.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          )
                      ],
                    ),
                    child: _isSearchExpanded
                        ? TextField(
                            controller: _searchController,
                            autofocus: true,
                            style: TextStyle(color: textColor, fontSize: 15),
                            decoration: InputDecoration(
                              hintText: 'Search groups...',
                              hintStyle: TextStyle(color: subtextColor, fontSize: 14),
                              border: InputBorder.none,
                              prefixIcon: Icon(Icons.search, color: brandGreen),
                              suffixIcon: IconButton(
                                icon: const Icon(Icons.close, size: 20),
                                color: subtextColor,
                                onPressed: () {
                                  setState(() {
                                    _searchController.clear();
                                    _searchQuery = '';
                                    _isSearchExpanded = false;
                                  });
                                },
                              ),
                              contentPadding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            onChanged: (val) {
                              setState(() {
                                _searchQuery = val;
                              });
                            },
                          )
                        : IconButton(
                            icon: const Icon(Icons.search, color: Colors.white, size: 20),
                            onPressed: () {
                              setState(() {
                                _isSearchExpanded = true;
                              });
                            },
                          ),
                  ),
                  
                  // Simple Header Title
                  if (!_isSearchExpanded)
                    Text(
                      'Groups',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                  
                  // Spacing alignment buddy
                  const SizedBox(width: 44),
                ],
              ),
            ),

            // Group List Section
            Expanded(
              child: _filteredGroups.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.search_off_rounded, size: 64, color: subtextColor.withOpacity(0.5)),
                          const SizedBox(height: 12),
                          Text(
                            'No groups match your search',
                            style: TextStyle(color: subtextColor, fontSize: 16),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
                      itemCount: _filteredGroups.length,
                      itemBuilder: (context, index) {
                        final group = _filteredGroups[index];
                        final double userBal = group.userBalance;
                        
                        // Set up dynamic layout coloring for balances
                        final Color balColor = userBal > 0 
                            ? const Color(0xFF2E7D32) // Owed money (green)
                            : userBal < 0 
                                ? const Color(0xFFC62828) // Owes money (red)
                                : subtextColor;
                        
                        final String balText = userBal > 0 
                            ? 'Owes you \$${userBal.toStringAsFixed(2)}'
                            : userBal < 0 
                                ? 'You owe \$${userBal.abs().toStringAsFixed(2)}'
                                : 'All settled up';

                        return Container(
                          margin: const EdgeInsets.only(bottom: 16.0),
                          decoration: BoxDecoration(
                            color: cardColor,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(isDark ? 0.3 : 0.04),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(20),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => GroupDetailsScreen(group: group),
                                  ),
                                );
                              },
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
                                child: Row(
                                  children: [
                                    // Custom visual avatars perfectly matched to mockup screenshot
                                    _buildCustomAvatar(group.avatarType, group.avatarBgColor),
                                    
                                    const SizedBox(width: 16.0),
                                    
                                    // Center Details: Title, balance active
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            group.name,
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              color: textColor,
                                            ),
                                          ),
                                          const SizedBox(height: 4.0),
                                          Row(
                                            children: [
                                              Container(
                                                width: 6,
                                                height: 6,
                                                decoration: BoxDecoration(
                                                  color: balColor,
                                                  shape: BoxShape.circle,
                                                ),
                                              ),
                                              const SizedBox(width: 6),
                                              Text(
                                                balText,
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.bold,
                                                  color: balColor,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                    
                                    // Right Chevron indicator
                                    Icon(
                                      Icons.chevron_right_rounded,
                                      color: subtextColor.withOpacity(0.6),
                                      size: 24,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),

            // Actions Overlay Button Panel (Create Group & Join Group)
            Padding(
              padding: const EdgeInsets.only(left: 20.0, right: 20.0, bottom: 25.0, top: 10.0),
              child: Row(
                children: [
                  // Create Group Button
                  Expanded(
                    child: SizedBox(
                      height: 52,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: brandGreen,
                          foregroundColor: Colors.white,
                          elevation: 3,
                          shadowColor: brandGreen.withOpacity(0.3),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const CreateGroupScreen(),
                            ),
                          );
                        },
                        icon: const Icon(Icons.person_add_rounded, size: 20),
                        label: const Text(
                          'Create Group',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 15.0),
                  
                  // Join Group Button
                  Expanded(
                    child: SizedBox(
                      height: 52,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: brandGreen,
                          foregroundColor: Colors.white,
                          elevation: 3,
                          shadowColor: brandGreen.withOpacity(0.3),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const JoinGroupScreen(),
                            ),
                          );
                        },
                        icon: const Icon(Icons.qr_code_scanner_rounded, size: 20),
                        label: const Text(
                          'Join Group',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Visual helper to render perfect avatars based on types from user screenshot
  Widget _buildCustomAvatar(String type, Color bgColor) {
    if (type == 'diamond') {
      return Container(
        width: 46,
        height: 46,
        decoration: BoxDecoration(
          color: bgColor,
          shape: BoxShape.circle,
          gradient: LinearGradient(
            colors: [bgColor.withOpacity(0.85), bgColor],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: const Icon(
          Icons.diamond_rounded,
          color: Colors.white,
          size: 22,
        ),
      );
    } else if (type == 'scenic') {
      return Container(
        width: 46,
        height: 46,
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
        width: 46,
        height: 46,
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
        width: 46,
        height: 46,
        decoration: BoxDecoration(
          color: Colors.grey.shade400,
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.group_rounded, color: Colors.white),
      );
    }
  }
}
