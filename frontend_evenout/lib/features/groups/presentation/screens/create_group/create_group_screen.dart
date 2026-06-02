import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend_evenout/features/groups/data/groups_repository.dart';
import 'package:frontend_evenout/features/groups/presentation/providers/groups_provider.dart';
import 'package:frontend_evenout/features/user/presentation/providers/friends_provider.dart';

class CreateGroupScreen extends ConsumerStatefulWidget {
  const CreateGroupScreen({super.key});

  @override
  ConsumerState<CreateGroupScreen> createState() => _CreateGroupScreenState();
}

class _CreateGroupScreenState extends ConsumerState<CreateGroupScreen> {
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _createGroup() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a group name'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      // 1. Create the group (creator is added as admin server-side).
      final group = await ref.read(groupsRepositoryProvider).createGroup(
            name: name,
            description: _descController.text.trim().isNotEmpty
                ? _descController.text.trim()
                : _selectedCategory,
          );

      // 2. Add each selected friend as a member (best-effort).
      final repo = ref.read(groupsRepositoryProvider);
      int addedCount = 0;
      final failed = <String>[];
      for (final friendId in _selectedFriendIds) {
        try {
          await repo.addMember(group.id, friendId);
          addedCount++;
        } catch (_) {
          failed.add(friendId);
        }
      }

      // Refresh the groups list so the new group shows immediately.
      ref.invalidate(myGroupsProvider);

      if (!mounted) return;
      Navigator.pop(context);

      final memberMsg = addedCount > 0
          ? ' with $addedCount member${addedCount == 1 ? '' : 's'}'
          : '';
      final failMsg =
          failed.isNotEmpty ? ' (${failed.length} could not be added)' : '';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle_rounded, color: Colors.white),
              const SizedBox(width: 10),
              Expanded(child: Text('Group "$name" created$memberMsg!$failMsg')),
            ],
          ),
          backgroundColor: const Color(0xFF429246),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not create group: ${groupErrorMessage(e)}'),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  /// User ids of friends selected to be added to the new group.
  final Set<String> _selectedFriendIds = {};
  String _selectedCategory = 'Trip';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    final Color backgroundColor = isDark ? const Color(0xFF121212) : const Color(0xFFFAFAFA);
    final Color cardColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final Color textColor = isDark ? Colors.white : const Color(0xFF1B1B3A);
    final Color subtextColor = isDark ? Colors.white60 : Colors.black54;
    final Color brandGreen = const Color(0xFF429246);

    final categories = ['Trip', 'Home', 'Hackathon', 'Dining', 'Other'];

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.close_rounded, color: textColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Create Group',
          style: TextStyle(color: textColor, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 10.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Group Avatar mock builder box
                  Center(
                    child: Stack(
                      children: [
                        CircleAvatar(
                          radius: 46,
                          backgroundColor: brandGreen.withOpacity(0.1),
                          child: Icon(Icons.group_add_rounded, color: brandGreen, size: 42),
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: CircleAvatar(
                            radius: 14,
                            backgroundColor: brandGreen,
                            child: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 14),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 25),

                  // 2. Input Name Box
                  Text(
                    'GROUP NAME',
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: subtextColor, letterSpacing: 0.8),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _nameController,
                    style: TextStyle(color: textColor, fontWeight: FontWeight.w600),
                    decoration: InputDecoration(
                      hintText: 'Enter group name...',
                      hintStyle: TextStyle(color: subtextColor.withOpacity(0.6), fontSize: 14),
                      filled: true,
                      fillColor: cardColor,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // 3. Category Selector chips
                  Text(
                    'CATEGORY',
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: subtextColor, letterSpacing: 0.8),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 38,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: categories.length,
                      separatorBuilder: (context, index) => const SizedBox(width: 10),
                      itemBuilder: (context, index) {
                        final cat = categories[index];
                        final isSelected = _selectedCategory == cat;
                        return ChoiceChip(
                          selectedColor: brandGreen,
                          backgroundColor: cardColor,
                          label: Text(
                            cat,
                            style: TextStyle(
                              color: isSelected ? Colors.white : textColor,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          selected: isSelected,
                          onSelected: (val) {
                            if (val) {
                              setState(() {
                                _selectedCategory = cat;
                              });
                            }
                          },
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 25),

                  // 4. Contact Selector List
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'INVITE MEMBERS',
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: subtextColor, letterSpacing: 0.8),
                      ),
                      Text(
                        '${_selectedFriendIds.length} selected',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: brandGreen),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  
                  _buildFriendsSelector(cardColor, textColor, subtextColor, brandGreen, isDark),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),

          // 5. Create Button bottom action docking
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: brandGreen,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 3,
                  shadowColor: brandGreen.withOpacity(0.3),
                ),
                onPressed: _isSubmitting ? null : _createGroup,
                child: _isSubmitting
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'CREATE GROUP',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 0.8,
                        ),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Avatar palette for friends without a photo.
  static const List<Color> _avatarPalette = [
    Color(0xFF9C27B0),
    Color(0xFF3F51B5),
    Color(0xFF009688),
    Color(0xFFFF5722),
    Color(0xFFE91E63),
    Color(0xFF4CAF50),
    Color(0xFFFF9800),
  ];

  Color _friendColor(String id) {
    final hash = id.codeUnits.fold<int>(0, (sum, c) => sum + c);
    return _avatarPalette[hash % _avatarPalette.length];
  }

  /// Live "Invite Members" picker backed by the real friends API.
  Widget _buildFriendsSelector(
    Color cardColor,
    Color textColor,
    Color subtextColor,
    Color brandGreen,
    bool isDark,
  ) {
    final friendsAsync = ref.watch(friendsProvider);

    Widget wrap(Widget child) => Container(
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(20),
          ),
          child: child,
        );

    return friendsAsync.when(
      loading: () => wrap(
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 30),
          child: Center(
            child: SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2.5, color: Color(0xFF429246)),
            ),
          ),
        ),
      ),
      error: (err, _) => wrap(
        Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Icon(Icons.cloud_off_outlined, color: subtextColor, size: 32),
              const SizedBox(height: 8),
              Text(
                'Could not load friends',
                style: TextStyle(color: subtextColor, fontSize: 13, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                groupErrorMessage(err),
                style: TextStyle(color: subtextColor, fontSize: 11),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => ref.invalidate(friendsProvider),
                child: Text('Retry', style: TextStyle(color: brandGreen, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
      data: (friends) {
        if (friends.isEmpty) {
          return wrap(
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
              child: Column(
                children: [
                  Icon(Icons.person_off_outlined, color: subtextColor.withOpacity(0.6), size: 36),
                  const SizedBox(height: 10),
                  Text(
                    'No friends yet',
                    style: TextStyle(color: subtextColor, fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Add friends from the home screen to invite them to groups.',
                    style: TextStyle(color: subtextColor, fontSize: 11),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }

        return wrap(
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: friends.length,
            separatorBuilder: (context, index) => Divider(
              color: isDark ? Colors.white10 : Colors.grey.shade100,
              height: 1,
            ),
            itemBuilder: (context, index) {
              final friend = friends[index];
              final isAdded = _selectedFriendIds.contains(friend.id);
              final color = _friendColor(friend.id);
              final hasPhoto = friend.avatarUrl != null && friend.avatarUrl!.isNotEmpty;

              return ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                leading: CircleAvatar(
                  radius: 18,
                  backgroundColor: color,
                  backgroundImage: hasPhoto ? NetworkImage(friend.avatarUrl!) : null,
                  child: hasPhoto
                      ? null
                      : Text(
                          friend.initials,
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                ),
                title: Text(
                  friend.label,
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: textColor),
                ),
                trailing: Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    color: isAdded ? brandGreen : Colors.transparent,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isAdded ? brandGreen : Colors.grey.shade400,
                      width: 1.5,
                    ),
                  ),
                  child: isAdded ? const Icon(Icons.check, size: 14, color: Colors.white) : null,
                ),
                onTap: () {
                  setState(() {
                    if (isAdded) {
                      _selectedFriendIds.remove(friend.id);
                    } else {
                      _selectedFriendIds.add(friend.id);
                    }
                  });
                },
              );
            },
          ),
        );
      },
    );
  }
}
