import 'dart:math';

import 'package:dio/dio.dart';
import '../../../core/network/api_client.dart';

final Random _uuidRng = Random.secure();

/// Generates an RFC-4122 version-4 UUID. The backend requires the client to
/// supply the expense `id` (offline-first: `expenses.id` has no DB default), so
/// we mint one here before posting.
String generateUuidV4() {
  final bytes = List<int>.generate(16, (_) => _uuidRng.nextInt(256));
  bytes[6] = (bytes[6] & 0x0f) | 0x40; // version 4
  bytes[8] = (bytes[8] & 0x3f) | 0x80; // RFC-4122 variant
  String hex(int b) => b.toRadixString(16).padLeft(2, '0');
  final h = bytes.map(hex).toList();
  return '${h[0]}${h[1]}${h[2]}${h[3]}-${h[4]}${h[5]}-${h[6]}${h[7]}-'
      '${h[8]}${h[9]}-${h[10]}${h[11]}${h[12]}${h[13]}${h[14]}${h[15]}';
}

/// One participant's share of an expense, shaped for `POST /expenses`.
///
/// Which fields are required depends on the expense `split_mode`:
/// * `equal`          → only [userId] (backend divides the total evenly)
/// * `exact`          → [userId] + [amount] (must sum to the total)
/// * `percentage`     → [userId] + [percentage] (must sum to 100)
/// * `chaos_roulette` → [userId] + [amount] (frontend pre-computes the cascade)
class ExpenseSplitInput {
  final String userId;
  final double? amount;
  final double? percentage;
  final int? eliminationOrder;

  const ExpenseSplitInput({
    required this.userId,
    this.amount,
    this.percentage,
    this.eliminationOrder,
  });

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{'user_id': userId};
    if (amount != null) map['amount'] = amount;
    if (percentage != null) map['percentage'] = percentage;
    if (eliminationOrder != null) map['elimination_order'] = eliminationOrder;
    return map;
  }
}

class ExpensesRepository {
  final Dio _dio = ApiClient.instance;

  /// POST /expenses — records a new expense. The backend always sets the payer
  /// to the authenticated user, so [splits] should include the current user.
  /// Omit [groupId] for a peer-to-peer expense.
  Future<void> createExpense({
    String? groupId,
    required double amount,
    required String description,
    String? category,
    required String splitMode,
    required List<ExpenseSplitInput> splits,
  }) async {
    final body = <String, dynamic>{
      'id': generateUuidV4(),
      'amount': amount,
      'description': description,
      'split_mode': splitMode,
      'splits': splits.map((s) => s.toJson()).toList(),
    };
    if (groupId != null) body['group_id'] = groupId;
    if (category != null && category.trim().isNotEmpty) {
      body['category'] = category.trim();
    }
    await _dio.post('/expenses', data: body);
  }
}

/// "Chaos Roulette" cascading 50%-reduction shares (PRD Feature 8).
///
/// Returns a list of length [n] where index `k` is the amount owed by the
/// person eliminated in position `k` (position 0 = first eliminated = pays the
/// largest share). The values always sum to [total].
///
/// * N = 1 → the single person owes everything.
/// * N = 2 → first owes the full total, second owes nothing.
/// * N ≥ 3 → each person pays half of the running balance; the last two split
///   what remains evenly.
List<double> computeChaosShares(double total, int n) {
  if (n <= 0) return const [];
  if (n == 1) return [_round2(total)];
  if (n == 2) return [_round2(total), 0.0];

  final shares = List<double>.filled(n, 0.0);
  double remaining = total;
  for (int i = 0; i < n; i++) {
    if (i == n - 1) {
      // Last person absorbs whatever is left (avoids rounding drift).
      shares[i] = _round2(remaining);
    } else {
      final share = _round2(remaining * 0.5);
      shares[i] = share;
      remaining -= share;
    }
  }
  return shares;
}

double _round2(double v) => double.parse(v.toStringAsFixed(2));

/// Extracts a human-readable message from an API/network error so screens can
/// surface something better than a raw `DioException` dump.
String expenseErrorMessage(Object error) {
  if (error is DioException) {
    final data = error.response?.data;
    if (data is Map && data['message'] != null) {
      final message = data['message'];
      if (message is List) return message.join(', ');
      return message.toString();
    }
    if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout) {
      return 'The server took too long to respond. Please try again.';
    }
    return error.message ?? 'Network error. Please try again.';
  }
  return error.toString();
}
