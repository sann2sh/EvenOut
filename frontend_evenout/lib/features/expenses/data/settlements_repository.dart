import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/network/api_client.dart';

class SettlementsRepository {
  final Dio _dio;
  final _uuid = const Uuid();

  SettlementsRepository(this._dio);

  Future<void> createSettlement({
    required String payerId,
    required String payeeId,
    required double amount,
    required String groupId,
  }) async {
    try {
      await _dio.post('/settlements', data: {
        'id': _uuid.v4(),
        'payer_id': payerId,
        'payee_id': payeeId,
        'amount': amount,
        'group_id': groupId,
        'status': 'confirmed',
      });
    } catch (e) {
      throw Exception('Failed to create settlement: $e');
    }
  }
}

final settlementsRepositoryProvider = Provider<SettlementsRepository>((ref) {
  return SettlementsRepository(ApiClient.instance);
});
