import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../providers/friend_requests_provider.dart';

// ---------------------------------------------------------------------------
// Entry point — opens the sheet as a full-screen modal
// ---------------------------------------------------------------------------

void showFriendRequestsSheet(BuildContext context) {
  showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Notifications',
    barrierColor: Colors.black.withValues(alpha: 0.5),
    transitionDuration: const Duration(milliseconds: 280),
    pageBuilder: (_, __, ___) => const _FriendRequestsSheet(),
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

// ---------------------------------------------------------------------------
// Root sheet scaffold
// ---------------------------------------------------------------------------

class _FriendRequestsSheet extends ConsumerWidget {
  const _FriendRequestsSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor =
        isDark ? AppColors.backgroundDark : AppColors.backgroundLight;
    final surfaceColor =
        isDark ? AppColors.surfaceDark : AppColors.surfaceLight;
    final textColor = isDark ? Colors.white : AppColors.textMain;
    final subtextColor = isDark ? Colors.white60 : AppColors.textLight;
    final borderColor = isDark ? Colors.white12 : Colors.grey.shade200;

    final requestsAsync = ref.watch(incomingRequestsProvider);

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Column(
          children: [
            // ─── Header ─────────────────────────────────────────────────────
            Container(
              color: surfaceColor,
              padding: const EdgeInsets.fromLTRB(4, 12, 20, 12),
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.arrow_back_ios_new_rounded,
                        color: textColor, size: 20),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Friend Requests',
                          style: TextStyle(
                            color: textColor,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        requestsAsync.maybeWhen(
                          data: (list) => list.isNotEmpty
                              ? Text(
                                  '${list.length} pending',
                                  style: TextStyle(
                                    color: AppColors.primary,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                )
                              : const SizedBox.shrink(),
                          orElse: () => const SizedBox.shrink(),
                        ),
                      ],
                    ),
                  ),
                  // Refresh button
                  IconButton(
                    icon: Icon(Icons.refresh_rounded,
                        color: AppColors.primary, size: 22),
                    onPressed: () => ref.invalidate(incomingRequestsProvider),
                    tooltip: 'Refresh',
                  ),
                ],
              ),
            ),

            Divider(height: 1, color: borderColor),

            // ─── Body ────────────────────────────────────────────────────────
            Expanded(
              child: requestsAsync.when(
                loading: () => const Center(
                  child: CircularProgressIndicator(
                    color: AppColors.primary,
                    strokeWidth: 2.5,
                  ),
                ),
                error: (err, _) => _ErrorState(
                  message: err.toString(),
                  onRetry: () => ref.invalidate(incomingRequestsProvider),
                  textColor: textColor,
                  subtextColor: subtextColor,
                ),
                data: (requests) {
                  if (requests.isEmpty) {
                    return _EmptyState(
                        textColor: textColor, subtextColor: subtextColor);
                  }
                  return ListView.separated(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    itemCount: requests.length,
                    separatorBuilder: (_, __) =>
                        Divider(height: 1, color: borderColor, indent: 80),
                    itemBuilder: (context, index) {
                      return _RequestTile(
                        request: requests[index],
                        textColor: textColor,
                        subtextColor: subtextColor,
                        isDark: isDark,
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Individual request tile
// ---------------------------------------------------------------------------

class _RequestTile extends ConsumerWidget {
  final FriendRequest request;
  final Color textColor;
  final Color subtextColor;
  final bool isDark;

  const _RequestTile({
    required this.request,
    required this.textColor,
    required this.subtextColor,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statusMap = ref.watch(requestResponseProvider);
    final status =
        statusMap[request.id] ?? RequestResponseStatus.idle;

    // Once accepted or declined, show a compact resolved chip instead
    if (status == RequestResponseStatus.accepted) {
      return _ResolvedTile(
        request: request,
        label: 'Accepted',
        icon: Icons.check_circle_rounded,
        color: AppColors.primary,
        textColor: textColor,
        subtextColor: subtextColor,
      );
    }
    if (status == RequestResponseStatus.declined) {
      return _ResolvedTile(
        request: request,
        label: 'Declined',
        icon: Icons.cancel_rounded,
        color: AppColors.owe,
        textColor: textColor,
        subtextColor: subtextColor,
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        children: [
          // Avatar
          _RequestAvatar(user: request.requester),
          const SizedBox(width: 14),

          // Name + time
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  request.requester.label,
                  style: TextStyle(
                    color: textColor,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  _formatTime(request.requestedAt),
                  style: TextStyle(color: subtextColor, fontSize: 12),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),

          // Action buttons
          if (status == RequestResponseStatus.loading)
            const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                color: AppColors.primary,
                strokeWidth: 2.5,
              ),
            )
          else ...[
            // Decline button
            _ActionButton(
              icon: Icons.close_rounded,
              color: AppColors.owe,
              bgColor: AppColors.owe.withValues(alpha: 0.1),
              onTap: status == RequestResponseStatus.error
                  ? null
                  : () => ref
                      .read(requestResponseProvider.notifier)
                      .respond(request.id, 'declined'),
              tooltip: 'Decline',
            ),
            const SizedBox(width: 8),
            // Accept button
            _ActionButton(
              icon: Icons.check_rounded,
              color: Colors.white,
              bgColor: AppColors.primary,
              isGradient: true,
              onTap: status == RequestResponseStatus.error
                  ? null
                  : () => ref
                      .read(requestResponseProvider.notifier)
                      .respond(request.id, 'accepted'),
              tooltip: 'Accept',
            ),
          ],

          // Error retry hint
          if (status == RequestResponseStatus.error) ...[
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () => ref
                  .read(requestResponseProvider.notifier)
                  .respond(request.id, 'accepted'),
              child: Text(
                'Retry',
                style: TextStyle(
                  color: AppColors.owe,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatTime(String iso) {
    if (iso.isEmpty) return '';
    try {
      final dt = DateTime.parse(iso).toLocal();
      final now = DateTime.now();
      final diff = now.difference(dt);
      if (diff.inMinutes < 1) return 'Just now';
      if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
      if (diff.inHours < 24) return '${diff.inHours}h ago';
      if (diff.inDays < 7) return '${diff.inDays}d ago';
      return '${dt.day}/${dt.month}/${dt.year}';
    } catch (_) {
      return '';
    }
  }
}

// ---------------------------------------------------------------------------
// Resolved tile (after accept/decline)
// ---------------------------------------------------------------------------

class _ResolvedTile extends StatelessWidget {
  final FriendRequest request;
  final String label;
  final IconData icon;
  final Color color;
  final Color textColor;
  final Color subtextColor;

  const _ResolvedTile({
    required this.request,
    required this.label,
    required this.icon,
    required this.color,
    required this.textColor,
    required this.subtextColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        children: [
          _RequestAvatar(user: request.requester),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              request.requester.label,
              style: TextStyle(
                color: textColor.withValues(alpha: 0.5),
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: color, size: 14),
                const SizedBox(width: 5),
                Text(
                  label,
                  style: TextStyle(
                    color: color,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Avatar widget
// ---------------------------------------------------------------------------

class _RequestAvatar extends StatelessWidget {
  final FriendRequestUser user;

  const _RequestAvatar({required this.user});

  @override
  Widget build(BuildContext context) {
    final initials =
        user.label.isNotEmpty ? user.label[0].toUpperCase() : '?';
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.primaryTint, width: 2),
      ),
      child: CircleAvatar(
        radius: 24,
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
                  fontSize: 17,
                ),
              )
            : null,
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Circular action button (Accept / Decline)
// ---------------------------------------------------------------------------

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final Color bgColor;
  final bool isGradient;
  final VoidCallback? onTap;
  final String tooltip;

  const _ActionButton({
    required this.icon,
    required this.color,
    required this.bgColor,
    this.isGradient = false,
    required this.onTap,
    required this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    final Widget inner = Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isGradient ? null : bgColor,
        gradient: isGradient
            ? const LinearGradient(
                colors: [AppColors.primary, AppColors.primaryDark],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
        boxShadow: isGradient
            ? [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.3),
                  blurRadius: 6,
                  offset: const Offset(0, 3),
                )
              ]
            : null,
      ),
      child: Icon(icon, color: color, size: 18),
    );

    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onTap,
        child: inner,
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Empty state
// ---------------------------------------------------------------------------

class _EmptyState extends StatelessWidget {
  final Color textColor;
  final Color subtextColor;

  const _EmptyState({required this.textColor, required this.subtextColor});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              color: AppColors.primaryTint,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.notifications_none_rounded,
              size: 44,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'All caught up!',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'No pending friend requests right now',
            style: TextStyle(fontSize: 13, color: subtextColor),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Error state
// ---------------------------------------------------------------------------

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  final Color textColor;
  final Color subtextColor;

  const _ErrorState({
    required this.message,
    required this.onRetry,
    required this.textColor,
    required this.subtextColor,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.cloud_off_outlined,
              size: 44, color: AppColors.primary),
          const SizedBox(height: 16),
          Text(
            'Could not load requests',
            style: TextStyle(
                color: textColor, fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              message.length > 100
                  ? '${message.substring(0, 100)}…'
                  : message,
              style: TextStyle(color: subtextColor, fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded, size: 16),
            label: const Text('Retry'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }
}
