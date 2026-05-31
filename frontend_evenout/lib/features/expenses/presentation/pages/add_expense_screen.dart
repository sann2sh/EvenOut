import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../dashboard/presentation/providers/home_provider.dart';
import '../../../groups/data/groups_repository.dart';
import '../../../groups/presentation/providers/groups_provider.dart';
import '../../../user/data/user_repository.dart';
import '../../../user/presentation/providers/user_provider.dart';
import '../../../user/presentation/providers/friends_provider.dart';
import '../../data/expenses_repository.dart';
import '../providers/expense_providers.dart';
import 'chaos_roulette_screen.dart';

/// Returned to the caller when an expense is saved, so a group screen can show
/// the new entry immediately without a round-trip.
class AddExpenseResult {
  final String title;
  final double amount;
  final String paidByName;
  const AddExpenseResult({
    required this.title,
    required this.amount,
    required this.paidByName,
  });
}

/// A single person an expense can be split between.
class _Participant {
  final String id;
  final String name;
  final String? avatarUrl;
  final bool isMe;
  const _Participant({
    required this.id,
    required this.name,
    this.avatarUrl,
    required this.isMe,
  });
}

class AddExpenseScreen extends ConsumerStatefulWidget {
  /// When launched from a group ("Add Group Expense") the expense is pre-scoped
  /// to that group. Omit for a peer-to-peer expense started from the home tab.
  final String? initialGroupId;
  final String? initialGroupName;

  const AddExpenseScreen({
    super.key,
    this.initialGroupId,
    this.initialGroupName,
  });

  @override
  ConsumerState<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends ConsumerState<AddExpenseScreen> {
  final _descCtrl = TextEditingController();
  final _categoryCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();

  final Map<String, TextEditingController> _exactCtrls = {};
  final Map<String, TextEditingController> _pctCtrls = {};

  String _mode = 'p2p'; // 'p2p' | 'group'
  Friend? _friend;
  String? _groupId;
  String? _groupName;

  String _splitMode = 'equal'; // equal | percentage | exact | chaos_roulette
  final Set<String> _excludedIds = {}; // group members removed from the split
  ChaosResult? _chaosResult;

  bool _submitting = false;

  static const _splitOptions = [
    ('equal', 'Equally', Icons.drag_handle_rounded),
    ('percentage', 'Percent', Icons.percent_rounded),
    ('exact', 'Exact', Icons.tune_rounded),
    ('chaos_roulette', 'Chaos', Icons.casino_rounded),
  ];

  @override
  void initState() {
    super.initState();
    if (widget.initialGroupId != null) {
      _mode = 'group';
      _groupId = widget.initialGroupId;
      _groupName = widget.initialGroupName;
    }
    // Equal share + live validation hints depend on the amount; the chaos
    // outcome is invalidated whenever the total changes.
    _amountCtrl.addListener(() => setState(() => _chaosResult = null));
  }

  @override
  void dispose() {
    _descCtrl.dispose();
    _categoryCtrl.dispose();
    _amountCtrl.dispose();
    for (final c in _exactCtrls.values) {
      c.dispose();
    }
    for (final c in _pctCtrls.values) {
      c.dispose();
    }
    super.dispose();
  }

  double get _amount => double.tryParse(_amountCtrl.text.trim()) ?? 0;

  TextEditingController _inputCtrl(
      Map<String, TextEditingController> map, String id) {
    return map.putIfAbsent(id, () => TextEditingController());
  }

  // --- Participants ---------------------------------------------------------

  List<_Participant> _participants(UserModel me, List<GroupMemberUser>? members) {
    if (_mode == 'group') {
      final ms = members ?? const <GroupMemberUser>[];
      var parts = ms
          .map((m) => _Participant(
                id: m.id,
                name: m.id == me.id ? 'You' : m.label,
                avatarUrl: m.avatarUrl,
                isMe: m.id == me.id,
              ))
          .toList();
      if (!parts.any((p) => p.isMe)) {
        parts.insert(
          0,
          _Participant(id: me.id, name: 'You', avatarUrl: me.avatarUrl, isMe: true),
        );
      }
      return parts.where((p) => p.isMe || !_excludedIds.contains(p.id)).toList();
    }

    final parts = <_Participant>[
      _Participant(id: me.id, name: 'You', avatarUrl: me.avatarUrl, isMe: true),
    ];
    if (_friend != null) {
      parts.add(_Participant(
        id: _friend!.id,
        name: _friend!.label,
        avatarUrl: _friend!.avatarUrl,
        isMe: false,
      ));
    }
    return parts;
  }

  // --- Actions --------------------------------------------------------------

  void _snack(String message, {Color? color}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: color,
      ),
    );
  }

  void _pickFriend(Friend f) {
    setState(() {
      _mode = 'p2p';
      _friend = f;
      _groupId = null;
      _groupName = null;
      _excludedIds.clear();
      _chaosResult = null;
    });
  }

  void _pickGroup(Group g) {
    setState(() {
      _mode = 'group';
      _groupId = g.id;
      _groupName = g.name;
      _friend = null;
      _excludedIds.clear();
      _chaosResult = null;
    });
  }

  Future<void> _openChaos(List<_Participant> parts) async {
    if (_amount < 0.01) {
      _snack('Enter an amount before spinning');
      return;
    }
    if (parts.length < 2) {
      _snack('Add at least two people first');
      return;
    }
    final result = await Navigator.push<ChaosResult>(
      context,
      MaterialPageRoute(
        builder: (_) => ChaosRouletteScreen(
          total: _amount,
          participants:
              parts.map((p) => ChaosParticipant(id: p.id, name: p.name)).toList(),
        ),
      ),
    );
    if (result != null && mounted) {
      setState(() => _chaosResult = result);
    }
  }

  Future<void> _save(List<_Participant> parts) async {
    final desc = _descCtrl.text.trim();
    final amount = _amount;

    if (_mode == 'p2p' && _friend == null) {
      _snack('Choose a friend to split with');
      return;
    }
    if (_mode == 'group' && _groupId == null) {
      _snack('Choose a group');
      return;
    }
    if (desc.isEmpty) {
      _snack('Enter what this expense was for');
      return;
    }
    if (amount < 0.01) {
      _snack('Enter an amount greater than zero');
      return;
    }
    if (parts.length < 2) {
      _snack('Pick at least two people to split between');
      return;
    }

    final List<ExpenseSplitInput> splits;
    switch (_splitMode) {
      case 'exact':
        double sum = 0;
        final list = <ExpenseSplitInput>[];
        for (final p in parts) {
          final v = double.tryParse(_inputCtrl(_exactCtrls, p.id).text.trim()) ?? 0;
          sum += v;
          list.add(ExpenseSplitInput(userId: p.id, amount: v));
        }
        if ((sum - amount).abs() > 0.01) {
          _snack(
              'Exact amounts add up to Rs ${sum.toStringAsFixed(2)}, but the total is Rs ${amount.toStringAsFixed(2)}');
          return;
        }
        splits = list;
        break;
      case 'percentage':
        double sum = 0;
        final list = <ExpenseSplitInput>[];
        for (final p in parts) {
          final v = double.tryParse(_inputCtrl(_pctCtrls, p.id).text.trim()) ?? 0;
          sum += v;
          list.add(ExpenseSplitInput(userId: p.id, percentage: v));
        }
        if ((sum - 100).abs() > 0.01) {
          _snack('Percentages add up to ${sum.toStringAsFixed(1)}%, they must total 100%');
          return;
        }
        splits = list;
        break;
      case 'chaos_roulette':
        final res = _chaosResult;
        if (res == null || !parts.every((p) => res.shares.containsKey(p.id))) {
          _snack('Spin the chaos wheel to decide the split first');
          return;
        }
        final ordered = res.orderedIds
            .where((id) => parts.any((p) => p.id == id))
            .toList();
        splits = [
          for (var i = 0; i < ordered.length; i++)
            ExpenseSplitInput(
              userId: ordered[i],
              amount: res.shares[ordered[i]],
              eliminationOrder: i + 1,
            ),
        ];
        break;
      case 'equal':
      default:
        splits = parts.map((p) => ExpenseSplitInput(userId: p.id)).toList();
    }

    setState(() => _submitting = true);
    try {
      await ref.read(expensesRepositoryProvider).createExpense(
            groupId: _mode == 'group' ? _groupId : null,
            amount: amount,
            description: desc,
            category: _categoryCtrl.text,
            splitMode: _splitMode,
            splits: splits,
          );

      // P2P balances on the home tab are derived from expenses — refresh them.
      ref.invalidate(homeDataProvider);

      if (!mounted) return;
      _snack('Expense "$desc" split successfully!', color: AppColors.settle);
      Navigator.pop(
        context,
        AddExpenseResult(title: desc, amount: amount, paidByName: 'You'),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _submitting = false);
      _snack(expenseErrorMessage(e), color: AppColors.owe);
    }
  }

  // --- Build ----------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(currentUserProvider);
    return userAsync.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator(color: AppColors.primary)),
      ),
      error: (e, _) => Scaffold(
        appBar: AppBar(),
        body: Center(child: Text('Could not load your profile.\n$e',
            textAlign: TextAlign.center)),
      ),
      data: (me) {
        if (_mode == 'group' && _groupId != null) {
          final membersAsync = ref.watch(groupMembersProvider(_groupId!));
          return membersAsync.when(
            loading: () => _buildScaffold(me, null, membersLoading: true),
            error: (e, _) => _buildScaffold(me, null, membersError: e),
            data: (members) => _buildScaffold(me, members),
          );
        }
        return _buildScaffold(me, null);
      },
    );
  }

  Widget _buildScaffold(
    UserModel me,
    List<GroupMemberUser>? members, {
    bool membersLoading = false,
    Object? membersError,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF121212) : const Color(0xFFF5F6FA);
    final cardColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF1B1B3A);
    final subtextColor = isDark ? Colors.white60 : Colors.black54;

    final parts = _participants(me, members);

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.close_rounded, color: textColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Add Expense',
          style: TextStyle(
              color: textColor, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
          children: [
            _targetSelector(isDark, cardColor, textColor, subtextColor),
            const SizedBox(height: 16),
            _amountField(isDark, cardColor, textColor, subtextColor),
            const SizedBox(height: 14),
            _textCard(
              controller: _descCtrl,
              hint: 'What was it for? (e.g. Dinner)',
              icon: Icons.receipt_long_rounded,
              cardColor: cardColor,
              textColor: textColor,
              subtextColor: subtextColor,
            ),
            const SizedBox(height: 12),
            _textCard(
              controller: _categoryCtrl,
              hint: 'Category (optional)',
              icon: Icons.category_outlined,
              cardColor: cardColor,
              textColor: textColor,
              subtextColor: subtextColor,
            ),
            const SizedBox(height: 20),
            _sectionLabel('How to split', textColor),
            const SizedBox(height: 10),
            _splitModeSelector(isDark, cardColor, textColor, subtextColor),
            const SizedBox(height: 20),
            _sectionLabel('Split between', textColor),
            const SizedBox(height: 10),
            if (membersLoading)
              _infoCard('Loading group members…', cardColor, subtextColor,
                  loading: true)
            else if (membersError != null)
              _infoCard('Could not load members: ${expenseErrorMessage(membersError)}',
                  cardColor, subtextColor)
            else
              _participantsSection(
                  parts, me, members, isDark, cardColor, textColor, subtextColor),
          ],
        ),
      ),
      bottomNavigationBar: _saveBar(parts, cardColor, isDark),
    );
  }

  // --- Pieces ---------------------------------------------------------------

  Widget _sectionLabel(String text, Color textColor) => Padding(
        padding: const EdgeInsets.only(left: 4),
        child: Text(text,
            style: TextStyle(
                fontSize: 15, fontWeight: FontWeight.bold, color: textColor)),
      );

  Widget _targetSelector(
      bool isDark, Color cardColor, Color textColor, Color subtextColor) {
    final bool hasTarget = _mode == 'group' ? _groupId != null : _friend != null;
    final String title = _mode == 'group'
        ? (_groupName ?? 'Select a group')
        : (_friend?.label ?? 'Select a friend');
    final String subtitle = _mode == 'group'
        ? 'Group expense • Paid by you'
        : (_friend == null ? 'Tap to choose' : 'Peer to peer • Paid by you');

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: _openTargetSelector,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: hasTarget
                  ? AppColors.primary.withOpacity(0.4)
                  : (isDark ? Colors.white12 : Colors.grey.shade200),
              width: 1.4),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _mode == 'group' ? Icons.groups_rounded : Icons.person_rounded,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('You & $title',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: textColor)),
                  const SizedBox(height: 2),
                  Text(subtitle,
                      style: TextStyle(fontSize: 12, color: subtextColor)),
                ],
              ),
            ),
            Icon(Icons.unfold_more_rounded, color: subtextColor, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _amountField(
      bool isDark, Color cardColor, Color textColor, Color subtextColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Text('Rs',
              style: TextStyle(
                  fontSize: 22, fontWeight: FontWeight.bold, color: subtextColor)),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: _amountCtrl,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
              ],
              style: TextStyle(
                  fontSize: 30, fontWeight: FontWeight.bold, color: textColor),
              decoration: InputDecoration(
                border: InputBorder.none,
                isDense: true,
                hintText: '0.00',
                hintStyle: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                    color: subtextColor.withOpacity(0.4)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _textCard({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    required Color cardColor,
    required Color textColor,
    required Color subtextColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(icon, color: subtextColor, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: controller,
              style: TextStyle(color: textColor, fontSize: 15),
              decoration: InputDecoration(
                border: InputBorder.none,
                hintText: hint,
                hintStyle: TextStyle(color: subtextColor, fontSize: 14),
                contentPadding: const EdgeInsets.symmetric(vertical: 15),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _splitModeSelector(
      bool isDark, Color cardColor, Color textColor, Color subtextColor) {
    return Row(
      children: [
        for (final opt in _splitOptions) ...[
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() {
                _splitMode = opt.$1;
                if (opt.$1 != 'chaos_roulette') _chaosResult = null;
              }),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: _splitMode == opt.$1
                      ? AppColors.primary
                      : cardColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: _splitMode == opt.$1
                          ? AppColors.primary
                          : (isDark ? Colors.white12 : Colors.grey.shade200)),
                ),
                child: Column(
                  children: [
                    Icon(opt.$3,
                        size: 20,
                        color: _splitMode == opt.$1 ? Colors.white : subtextColor),
                    const SizedBox(height: 4),
                    Text(opt.$2,
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: _splitMode == opt.$1
                                ? Colors.white
                                : subtextColor)),
                  ],
                ),
              ),
            ),
          ),
          if (opt != _splitOptions.last) const SizedBox(width: 8),
        ],
      ],
    );
  }

  Widget _infoCard(String text, Color cardColor, Color subtextColor,
      {bool loading = false}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          if (loading) ...[
            const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: AppColors.primary)),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Text(text,
                style: TextStyle(fontSize: 13, color: subtextColor)),
          ),
        ],
      ),
    );
  }

  Widget _participantsSection(
    List<_Participant> parts,
    UserModel me,
    List<GroupMemberUser>? members,
    bool isDark,
    Color cardColor,
    Color textColor,
    Color subtextColor,
  ) {
    if (_mode == 'p2p' && _friend == null) {
      return _infoCard(
          'Choose a friend above to split this expense with.',
          cardColor,
          subtextColor);
    }

    // Chaos mode has its own dedicated UI.
    if (_splitMode == 'chaos_roulette') {
      return _chaosSection(parts, cardColor, textColor, subtextColor);
    }

    // For groups, allow toggling members in/out of the split.
    final allGroupMembers = _mode == 'group'
        ? (members ?? const <GroupMemberUser>[])
        : const <GroupMemberUser>[];

    final children = <Widget>[];

    // Live "remaining" banner for exact / percentage.
    final banner = _remainingBanner(parts);
    if (banner != null) {
      children.add(banner);
      children.add(const SizedBox(height: 10));
    }

    for (final p in parts) {
      children.add(_participantTile(p, cardColor, textColor, subtextColor, isDark,
          canToggle: _mode == 'group' && !p.isMe,
          included: true,
          participantCount: parts.length));
      children.add(const SizedBox(height: 8));
    }

    // Excluded group members (so they can be re-added).
    if (_mode == 'group') {
      for (final m in allGroupMembers) {
        if (m.id == me.id) continue;
        if (!_excludedIds.contains(m.id)) continue;
        final p = _Participant(
            id: m.id, name: m.label, avatarUrl: m.avatarUrl, isMe: false);
        children.add(_participantTile(p, cardColor, textColor, subtextColor, isDark,
            canToggle: true, included: false, participantCount: parts.length));
        children.add(const SizedBox(height: 8));
      }
    }

    return Column(children: children);
  }

  Widget? _remainingBanner(List<_Participant> parts) {
    if (_splitMode == 'exact') {
      double sum = 0;
      for (final p in parts) {
        sum += double.tryParse(_inputCtrl(_exactCtrls, p.id).text.trim()) ?? 0;
      }
      final left = _amount - sum;
      final ok = left.abs() <= 0.01;
      return _bannerBox(
        ok
            ? 'All set — amounts add up to Rs ${_amount.toStringAsFixed(2)}'
            : left > 0
                ? 'Rs ${left.toStringAsFixed(2)} left to assign'
                : 'Over by Rs ${(-left).toStringAsFixed(2)}',
        ok,
      );
    }
    if (_splitMode == 'percentage') {
      double sum = 0;
      for (final p in parts) {
        sum += double.tryParse(_inputCtrl(_pctCtrls, p.id).text.trim()) ?? 0;
      }
      final left = 100 - sum;
      final ok = left.abs() <= 0.01;
      return _bannerBox(
        ok
            ? 'All set — percentages total 100%'
            : left > 0
                ? '${left.toStringAsFixed(1)}% left to assign'
                : 'Over by ${(-left).toStringAsFixed(1)}%',
        ok,
      );
    }
    if (_splitMode == 'equal' && parts.isNotEmpty) {
      final each = _amount / parts.length;
      return _bannerBox(
          'Rs ${each.toStringAsFixed(2)} each • ${parts.length} people', true,
          neutral: true);
    }
    return null;
  }

  Widget _bannerBox(String text, bool ok, {bool neutral = false}) {
    final color = neutral
        ? AppColors.primary
        : ok
            ? AppColors.settle
            : AppColors.owe;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(neutral ? Icons.info_outline_rounded : (ok ? Icons.check_circle_rounded : Icons.error_outline_rounded),
              size: 16, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text,
                style: TextStyle(
                    fontSize: 12.5, fontWeight: FontWeight.w600, color: color)),
          ),
        ],
      ),
    );
  }

  Widget _participantTile(
    _Participant p,
    Color cardColor,
    Color textColor,
    Color subtextColor,
    bool isDark, {
    required bool canToggle,
    required bool included,
    required int participantCount,
  }) {
    Widget trailing;
    if (!included) {
      trailing = TextButton(
        onPressed: () => setState(() {
          _excludedIds.remove(p.id);
          _chaosResult = null;
        }),
        child: const Text('Add'),
      );
    } else {
      switch (_splitMode) {
        case 'exact':
          trailing = _miniInput(_inputCtrl(_exactCtrls, p.id), 'Rs', textColor,
              subtextColor, isDark);
          break;
        case 'percentage':
          final pct = double.tryParse(_inputCtrl(_pctCtrls, p.id).text.trim()) ?? 0;
          final amt = _amount * pct / 100;
          trailing = Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Rs ${amt.toStringAsFixed(0)}',
                  style: TextStyle(fontSize: 11, color: subtextColor)),
              const SizedBox(width: 6),
              _miniInput(_inputCtrl(_pctCtrls, p.id), '%', textColor,
                  subtextColor, isDark),
            ],
          );
          break;
        case 'equal':
        default:
          final each =
              (_amount > 0 && participantCount > 0) ? _amount / participantCount : 0;
          trailing = Text('Rs ${each.toStringAsFixed(2)}',
              style: TextStyle(
                  fontSize: 14, fontWeight: FontWeight.bold, color: textColor));
      }
    }

    return Opacity(
      opacity: included ? 1 : 0.5,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            if (canToggle)
              GestureDetector(
                onTap: () => setState(() {
                  if (included) {
                    _excludedIds.add(p.id);
                  } else {
                    _excludedIds.remove(p.id);
                  }
                  _chaosResult = null;
                }),
                child: Icon(
                  included
                      ? Icons.check_circle_rounded
                      : Icons.radio_button_unchecked_rounded,
                  color: included ? AppColors.primary : subtextColor,
                  size: 22,
                ),
              ),
            if (canToggle) const SizedBox(width: 10),
            _avatar(p, 16),
            const SizedBox(width: 12),
            Expanded(
              child: Text(p.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: textColor)),
            ),
            trailing,
          ],
        ),
      ),
    );
  }

  Widget _miniInput(TextEditingController ctrl, String suffix, Color textColor,
      Color subtextColor, bool isDark) {
    return SizedBox(
      width: 84,
      child: TextField(
        controller: ctrl,
        textAlign: TextAlign.right,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        inputFormatters: [
          FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
        ],
        onChanged: (_) => setState(() {}),
        style: TextStyle(
            fontSize: 14, fontWeight: FontWeight.bold, color: textColor),
        decoration: InputDecoration(
          isDense: true,
          suffixText: suffix,
          suffixStyle: TextStyle(color: subtextColor, fontSize: 12),
          contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
          filled: true,
          fillColor: isDark ? Colors.white10 : Colors.grey.shade100,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  Widget _chaosSection(List<_Participant> parts, Color cardColor,
      Color textColor, Color subtextColor) {
    final res = _chaosResult;
    final hasResult =
        res != null && parts.every((p) => res.shares.containsKey(p.id));

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withOpacity(0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('🎲', style: TextStyle(fontSize: 18)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Let fate decide. Spin the wheel — whoever is eliminated first pays the biggest share.',
                  style: TextStyle(fontSize: 12.5, color: subtextColor, height: 1.3),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (hasResult) ...[
            for (var i = 0; i < res.orderedIds.length; i++)
              if (parts.any((p) => p.id == res.orderedIds[i]))
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      _avatar(
                          parts.firstWhere((p) => p.id == res.orderedIds[i]), 14),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          parts
                              .firstWhere((p) => p.id == res.orderedIds[i])
                              .name,
                          style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: textColor),
                        ),
                      ),
                      Text('Rs ${(res.shares[res.orderedIds[i]] ?? 0).toStringAsFixed(2)}',
                          style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: textColor)),
                    ],
                  ),
                ),
            const SizedBox(height: 12),
          ],
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: const BorderSide(color: AppColors.primary),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () => _openChaos(parts),
              icon: const Icon(Icons.casino_rounded),
              label: Text(hasResult ? 'Re-spin the wheel' : 'Spin the chaos wheel'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _avatar(_Participant p, double radius) {
    final hasImg = p.avatarUrl != null && p.avatarUrl!.isNotEmpty;
    return CircleAvatar(
      radius: radius,
      backgroundColor: AppColors.primary.withOpacity(0.15),
      backgroundImage: hasImg ? NetworkImage(p.avatarUrl!) : null,
      child: hasImg
          ? null
          : Text(
              p.name.isNotEmpty ? p.name[0].toUpperCase() : '?',
              style: TextStyle(
                  fontSize: radius * 0.8,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryDark),
            ),
    );
  }

  Widget _saveBar(List<_Participant> parts, Color cardColor, bool isDark) {
    return Container(
      padding: EdgeInsets.fromLTRB(
          20, 12, 20, 12 + MediaQuery.of(context).padding.bottom),
      decoration: BoxDecoration(
        color: cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.06),
            blurRadius: 12,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SizedBox(
        width: double.infinity,
        height: 52,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
          onPressed: _submitting ? null : () => _save(parts),
          child: _submitting
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                      strokeWidth: 2.4, color: Colors.white),
                )
              : Text(
                  _amount > 0
                      ? 'Save • Rs ${_amount.toStringAsFixed(2)}'
                      : 'Save Expense',
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold),
                ),
        ),
      ),
    );
  }

  // --- Target selector sheet ------------------------------------------------

  void _openTargetSelector() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF1B1B3A);
    final subtextColor = isDark ? Colors.white60 : Colors.black54;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetCtx) {
        return Consumer(
          builder: (ctx, ref, _) {
            final friendsAsync = ref.watch(friendsProvider);
            final groupsAsync = ref.watch(myGroupsProvider);

            return DraggableScrollableSheet(
              expand: false,
              initialChildSize: 0.7,
              maxChildSize: 0.9,
              minChildSize: 0.4,
              builder: (ctx, scrollController) {
                return ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: subtextColor.withOpacity(0.4),
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text('Split with',
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: textColor)),
                    const SizedBox(height: 16),

                    // Friends
                    Text('FRIENDS (PEER TO PEER)',
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                            color: subtextColor)),
                    const SizedBox(height: 8),
                    friendsAsync.when(
                      loading: () => const Padding(
                        padding: EdgeInsets.all(12),
                        child: Center(
                            child: CircularProgressIndicator(
                                color: AppColors.primary)),
                      ),
                      error: (e, _) => Text('Could not load friends',
                          style: TextStyle(color: subtextColor, fontSize: 13)),
                      data: (friends) {
                        if (friends.isEmpty) {
                          return Text('No friends yet — add some to split P2P.',
                              style:
                                  TextStyle(color: subtextColor, fontSize: 13));
                        }
                        return Column(
                          children: friends.map((f) {
                            final selected =
                                _mode == 'p2p' && _friend?.id == f.id;
                            return _selectorTile(
                              title: f.label,
                              avatarUrl: f.avatarUrl,
                              initials: f.initials,
                              selected: selected,
                              textColor: textColor,
                              subtextColor: subtextColor,
                              onTap: () {
                                _pickFriend(f);
                                Navigator.pop(sheetCtx);
                              },
                            );
                          }).toList(),
                        );
                      },
                    ),
                    const SizedBox(height: 20),

                    // Groups
                    Text('GROUPS',
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                            color: subtextColor)),
                    const SizedBox(height: 8),
                    groupsAsync.when(
                      loading: () => const Padding(
                        padding: EdgeInsets.all(12),
                        child: Center(
                            child: CircularProgressIndicator(
                                color: AppColors.primary)),
                      ),
                      error: (e, _) => Text('Could not load groups',
                          style: TextStyle(color: subtextColor, fontSize: 13)),
                      data: (groups) {
                        if (groups.isEmpty) {
                          return Text('No groups yet.',
                              style:
                                  TextStyle(color: subtextColor, fontSize: 13));
                        }
                        return Column(
                          children: groups.map((g) {
                            final selected =
                                _mode == 'group' && _groupId == g.id;
                            return _selectorTile(
                              title: g.name,
                              avatarUrl: g.avatarUrl,
                              initials: g.name.isNotEmpty
                                  ? g.name[0].toUpperCase()
                                  : '#',
                              selected: selected,
                              isGroup: true,
                              textColor: textColor,
                              subtextColor: subtextColor,
                              onTap: () {
                                _pickGroup(g);
                                Navigator.pop(sheetCtx);
                              },
                            );
                          }).toList(),
                        );
                      },
                    ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _selectorTile({
    required String title,
    required String? avatarUrl,
    required String initials,
    required bool selected,
    required Color textColor,
    required Color subtextColor,
    required VoidCallback onTap,
    bool isGroup = false,
  }) {
    final hasImg = avatarUrl != null && avatarUrl.isNotEmpty;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      onTap: onTap,
      leading: CircleAvatar(
        radius: 20,
        backgroundColor: AppColors.primary.withOpacity(0.15),
        backgroundImage: hasImg ? NetworkImage(avatarUrl) : null,
        child: hasImg
            ? null
            : (isGroup
                ? Icon(Icons.groups_rounded, color: AppColors.primaryDark, size: 20)
                : Text(initials,
                    style: TextStyle(
                        color: AppColors.primaryDark,
                        fontWeight: FontWeight.bold))),
      ),
      title: Text(title,
          style: TextStyle(
              fontWeight: FontWeight.bold, color: textColor, fontSize: 15)),
      trailing: selected
          ? const Icon(Icons.check_circle_rounded, color: AppColors.primary)
          : Icon(Icons.circle_outlined, color: subtextColor.withOpacity(0.5)),
    );
  }
}
