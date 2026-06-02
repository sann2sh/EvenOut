import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend_evenout/features/groups/data/groups_repository.dart';
import 'package:frontend_evenout/features/groups/presentation/providers/groups_provider.dart';
import '../group_details/group_details_screen.dart';
import '../create_group/create_group_screen.dart';
import '../join_group/join_group_screen.dart';

class GroupsScreen extends ConsumerStatefulWidget {
  const GroupsScreen({super.key});

  @override
  ConsumerState<GroupsScreen> createState() => _GroupsScreenState();
}

class _GroupsScreenState extends ConsumerState<GroupsScreen> {
  String _searchQuery = '';
  bool _isSearchExpanded = false;
  final TextEditingController _searchController = TextEditingController();

  // Palette for deterministic letter-avatars (keyed off the group id).
  static const List<Color> _avatarPalette = [
    Color(0xFF29B6F6),
    Color(0xFF8D6E63),
    Color(0xFF78909C),
    Color(0xFF7E57C2),
    Color(0xFFEF5350),
    Color(0xFF26A69A),
    Color(0xFFFFA726),
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Group> _filterGroups(List<Group> groups) {
    if (_searchQuery.isEmpty) return groups;
    return groups
        .where((g) => g.name.toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();
  }

  Color _avatarColor(String id) {
    final hash = id.codeUnits.fold<int>(0, (sum, c) => sum + c);
    return _avatarPalette[hash % _avatarPalette.length];
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

    final groupsAsync = ref.watch(myGroupsProvider);

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

            // Group List Section — live data
            Expanded(
              child: groupsAsync.when(
                loading: () => const Center(
                  child: CircularProgressIndicator(color: Color(0xFF429246)),
                ),
                error: (err, _) => _buildErrorState(err, subtextColor, brandGreen),
                data: (allGroups) {
                  final groups = _filterGroups(allGroups);

                  if (allGroups.isEmpty) {
                    return _buildEmptyState(
                      icon: Icons.groups_2_outlined,
                      title: 'No groups yet',
                      subtitle: 'Create a group or join one with an invite code',
                      subtextColor: subtextColor,
                    );
                  }

                  if (groups.isEmpty) {
                    return _buildEmptyState(
                      icon: Icons.search_off_rounded,
                      title: 'No groups match your search',
                      subtextColor: subtextColor,
                    );
                  }

                  return RefreshIndicator(
                    color: brandGreen,
                    onRefresh: () async => ref.refresh(myGroupsProvider.future),
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
                      itemCount: groups.length,
                      itemBuilder: (context, index) {
                        final group = groups[index];
                        return _buildGroupCard(
                          group, cardColor, textColor, subtextColor, isDark,
                        );
                      },
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
                        onPressed: () async {
                          await Navigator.push(
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
                        onPressed: () async {
                          await Navigator.push(
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

  Widget _buildGroupCard(
    Group group,
    Color cardColor,
    Color textColor,
    Color subtextColor,
    bool isDark,
  ) {
    final String subtitle = (group.description?.isNotEmpty ?? false)
        ? group.description!
        : 'Tap to view details';

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
                _buildLiveAvatar(group),
                const SizedBox(width: 16.0),
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
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4.0),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 12,
                          color: subtextColor,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
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
  }

  Widget _buildLiveAvatar(Group group) {
    final color = _avatarColor(group.id);
    if (group.avatarUrl != null && group.avatarUrl!.isNotEmpty) {
      return CircleAvatar(
        radius: 23,
        backgroundColor: color,
        backgroundImage: NetworkImage(group.avatarUrl!),
      );
    }
    final initial = group.name.trim().isNotEmpty
        ? group.name.trim()[0].toUpperCase()
        : '#';
    return Container(
      width: 46,
      height: 46,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [color.withOpacity(0.85), color],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        initial,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    String? subtitle,
    required Color subtextColor,
  }) {
    // Wrapped in a scroll view so RefreshIndicator-less empty states still feel right.
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: subtextColor.withOpacity(0.5)),
          const SizedBox(height: 12),
          Text(
            title,
            style: TextStyle(color: subtextColor, fontSize: 16, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Text(
                subtitle,
                style: TextStyle(color: subtextColor, fontSize: 13),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildErrorState(Object err, Color subtextColor, Color brandGreen) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.cloud_off_outlined, size: 56, color: brandGreen.withOpacity(0.7)),
          const SizedBox(height: 12),
          Text(
            'Could not load your groups',
            style: TextStyle(color: subtextColor, fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              groupErrorMessage(err),
              style: TextStyle(color: subtextColor, fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => ref.invalidate(myGroupsProvider),
            style: ElevatedButton.styleFrom(backgroundColor: brandGreen),
            child: const Text('Retry', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
