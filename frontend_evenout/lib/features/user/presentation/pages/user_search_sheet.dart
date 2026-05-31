import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../providers/user_search_provider.dart';

/// Opens the user search overlay as a full-screen modal.
void showUserSearchSheet(BuildContext context) {
  showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Search',
    barrierColor: Colors.black.withValues(alpha: 0.5),
    transitionDuration: const Duration(milliseconds: 280),
    pageBuilder: (_, __, ___) => const _UserSearchSheet(),
    transitionBuilder: (_, anim, __, child) {
      final curved =
          CurvedAnimation(parent: anim, curve: Curves.easeOutCubic);
      return SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.08),
          end: Offset.zero,
        ).animate(curved),
        child: FadeTransition(opacity: curved, child: child),
      );
    },
  );
}

class _UserSearchSheet extends ConsumerStatefulWidget {
  const _UserSearchSheet();

  @override
  ConsumerState<_UserSearchSheet> createState() => _UserSearchSheetState();
}

class _UserSearchSheetState extends ConsumerState<_UserSearchSheet> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  String _query = '';
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    // Auto-focus the search field when the sheet opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      if (mounted) {
        setState(() => _query = value.trim());
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppColors.backgroundDark : AppColors.backgroundLight;
    final surfaceColor = isDark ? AppColors.surfaceDark : AppColors.surfaceLight;
    final textColor = isDark ? Colors.white : AppColors.textMain;
    final subtextColor = isDark ? Colors.white60 : AppColors.textLight;
    final borderColor = isDark ? Colors.white12 : Colors.grey.shade200;

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Column(
          children: [
            // ─── Header ────────────────────────────────────────────────────
            Container(
              color: surfaceColor,
              padding: const EdgeInsets.fromLTRB(8, 12, 16, 12),
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.arrow_back_ios_new_rounded,
                        color: textColor, size: 20),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  Expanded(
                    child: Container(
                      height: 46,
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.07)
                            : AppColors.backgroundLight,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: _focusNode.hasFocus
                              ? AppColors.primary.withValues(alpha: 0.5)
                              : borderColor,
                          width: 1.5,
                        ),
                      ),
                      child: Row(
                        children: [
                          const SizedBox(width: 12),
                          Icon(Icons.search_rounded,
                              color: AppColors.primary, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextField(
                              controller: _controller,
                              focusNode: _focusNode,
                              onChanged: _onSearchChanged,
                              style: TextStyle(
                                color: textColor,
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                              ),
                              decoration: InputDecoration(
                                hintText: 'Search by username or name…',
                                hintStyle: TextStyle(
                                  color: subtextColor,
                                  fontSize: 14,
                                  fontWeight: FontWeight.normal,
                                ),
                                border: InputBorder.none,
                                isDense: true,
                              ),
                              textInputAction: TextInputAction.search,
                            ),
                          ),
                          if (_controller.text.isNotEmpty)
                            GestureDetector(
                              onTap: () {
                                _controller.clear();
                                setState(() => _query = '');
                              },
                              child: Padding(
                                padding: const EdgeInsets.all(10),
                                child: Icon(Icons.close_rounded,
                                    color: subtextColor, size: 18),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Subtle separator
            Divider(height: 1, color: borderColor),

            // ─── Results Area ───────────────────────────────────────────────
            Expanded(
              child: _query.length < 2
                  ? _buildEmptyHint(textColor, subtextColor)
                  : _SearchResults(
                      query: _query,
                      textColor: textColor,
                      subtextColor: subtextColor,
                      surfaceColor: surfaceColor,
                      isDark: isDark,
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyHint(Color textColor, Color subtextColor) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: AppColors.primaryTint,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.person_search_rounded,
                size: 42, color: AppColors.primary),
          ),
          const SizedBox(height: 20),
          Text(
            'Find your friends',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Type at least 2 characters to search\nby username or display name',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: subtextColor, height: 1.5),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Search Results Widget
// ---------------------------------------------------------------------------

class _SearchResults extends ConsumerWidget {
  final String query;
  final Color textColor;
  final Color subtextColor;
  final Color surfaceColor;
  final bool isDark;

  const _SearchResults({
    required this.query,
    required this.textColor,
    required this.subtextColor,
    required this.surfaceColor,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final searchAsync = ref.watch(userSearchProvider(query));

    return searchAsync.when(
      loading: () => const Center(
        child: CircularProgressIndicator(
          color: AppColors.primary,
          strokeWidth: 2.5,
        ),
      ),
      error: (err, _) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.wifi_off_rounded,
                size: 40, color: AppColors.primary),
            const SizedBox(height: 12),
            Text('Search failed',
                style: TextStyle(
                    color: textColor, fontWeight: FontWeight.bold, fontSize: 15)),
            const SizedBox(height: 6),
            Text(
              err.toString().length > 80
                  ? '${err.toString().substring(0, 80)}…'
                  : err.toString(),
              style: TextStyle(color: subtextColor, fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
      data: (results) {
        if (results.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.05)
                        : Colors.grey.shade100,
                    shape: BoxShape.circle,
                  ),
                  child:
                      Icon(Icons.search_off_rounded, size: 36, color: subtextColor),
                ),
                const SizedBox(height: 16),
                Text(
                  'No users found',
                  style: TextStyle(
                      color: textColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 16),
                ),
                const SizedBox(height: 6),
                Text(
                  'Try a different username or name',
                  style: TextStyle(color: subtextColor, fontSize: 13),
                ),
              ],
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: results.length,
          separatorBuilder: (_, __) => Divider(
            height: 1,
            indent: 76,
            color: isDark ? Colors.white10 : Colors.grey.shade100,
          ),
          itemBuilder: (context, index) {
            return _UserResultTile(
              user: results[index],
              textColor: textColor,
              subtextColor: subtextColor,
              isDark: isDark,
            );
          },
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Individual User Tile
// ---------------------------------------------------------------------------

class _UserResultTile extends ConsumerWidget {
  final UserSearchResult user;
  final Color textColor;
  final Color subtextColor;
  final bool isDark;

  const _UserResultTile({
    required this.user,
    required this.textColor,
    required this.subtextColor,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final requestMap = ref.watch(friendRequestProvider);
    final status =
        requestMap[user.id] ?? FriendRequestStatus.idle;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      leading: _buildAvatar(),
      title: Text(
        user.displayLabel,
        style: TextStyle(
          color: textColor,
          fontSize: 15,
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: user.usernameLabel.isNotEmpty
          ? Text(
              user.usernameLabel,
              style: TextStyle(
                color: AppColors.primary,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            )
          : null,
      trailing: _buildActionButton(context, ref, status),
    );
  }

  Widget _buildAvatar() {
    final initials = user.displayLabel.isNotEmpty
        ? user.displayLabel[0].toUpperCase()
        : '?';

    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.primaryTint, width: 2),
      ),
      child: CircleAvatar(
        radius: 22,
        backgroundColor: AppColors.primaryTint,
        backgroundImage: user.avatarUrl?.isNotEmpty == true
            ? NetworkImage(user.avatarUrl!)
            : null,
        child: user.avatarUrl == null || user.avatarUrl!.isEmpty
            ? Text(
                initials,
                style: const TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              )
            : null,
      ),
    );
  }

  Widget _buildActionButton(
      BuildContext context, WidgetRef ref, FriendRequestStatus status) {
    switch (status) {
      case FriendRequestStatus.loading:
        return Container(
          width: 38,
          height: 38,
          padding: const EdgeInsets.all(10),
          child: const CircularProgressIndicator(
            color: AppColors.primary,
            strokeWidth: 2.5,
          ),
        );

      case FriendRequestStatus.sent:
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.primaryTint,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Icon(Icons.check_rounded,
                  color: AppColors.primary, size: 15),
              SizedBox(width: 4),
              Text(
                'Sent',
                style: TextStyle(
                  color: AppColors.primary,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        );

      case FriendRequestStatus.error:
        return GestureDetector(
          onTap: () => ref
              .read(friendRequestProvider.notifier)
              .sendRequest(user.id),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.owe.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.owe.withValues(alpha: 0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Icon(Icons.refresh_rounded, color: AppColors.owe, size: 14),
                SizedBox(width: 4),
                Text(
                  'Retry',
                  style: TextStyle(
                    color: AppColors.owe,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        );

      case FriendRequestStatus.idle:
        return GestureDetector(
          onTap: () {
            ref.read(friendRequestProvider.notifier).sendRequest(user.id);
            // Show a quick feedback snackbar
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Sending friend request to ${user.displayLabel}…',
                  style: const TextStyle(color: Colors.white),
                ),
                backgroundColor: AppColors.primaryDark,
                duration: const Duration(seconds: 2),
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              ),
            );
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.primary, AppColors.primaryDark],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.25),
                  blurRadius: 6,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Icon(Icons.person_add_rounded, color: Colors.white, size: 15),
                SizedBox(width: 5),
                Text(
                  'Add',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        );
    }
  }
}
