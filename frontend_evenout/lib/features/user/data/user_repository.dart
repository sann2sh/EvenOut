import 'package:dio/dio.dart';
import '../../../core/network/api_client.dart';

class UserModel {
  final String id;
  final String? email;
  final String? username;
  final String? displayName;
  final String? phoneNumber;
  final String? avatarUrl;
  final double splitScore;

  const UserModel({
    required this.id,
    this.email,
    this.username,
    this.displayName,
    this.phoneNumber,
    this.avatarUrl,
    this.splitScore = 0,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      email: json['email'] as String?,
      username: json['username'] as String?,
      displayName: json['display_name'] as String?,
      phoneNumber: json['phone_number'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      splitScore: (json['split_score'] as num?)?.toDouble() ?? 0,
    );
  }

  bool get needsProfileSetup => username == null || username!.isEmpty;
}

class UserRepository {
  final Dio _dio = ApiClient.instance;

  Future<UserModel> getMe() async {
    final response = await _dio.get('/users/me');
    return UserModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<UserModel> updateMe({
    String? username,
    String? displayName,
    String? phoneNumber,
    String? fcmToken,
  }) async {
    final body = <String, dynamic>{};
    if (username != null) body['username'] = username;
    if (displayName != null) body['display_name'] = displayName;
    if (phoneNumber != null) body['phone_number'] = phoneNumber;
    if (fcmToken != null) body['fcm_token'] = fcmToken;

    final response = await _dio.patch('/users/me', data: body);
    return UserModel.fromJson(response.data as Map<String, dynamic>);
  }

  /// Returns true if the username is available (does not exist in database).
  /// Uses GET /users/search?query= and checks for an exact match.
  Future<bool> isUsernameAvailable(String username) async {
    try {
      final response = await _dio.get(
        '/users/search',
        queryParameters: {'query': username},
      );
      final results = response.data as List<dynamic>;
      // Check if any result is an exact username match (case-insensitive)
      final taken = results.any((u) =>
          (u['username'] as String?)?.toLowerCase() == username.toLowerCase());
      return !taken;
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return true; // no results = available
      rethrow;
    }
  }

  Future<void> sendNudge(String debtorId) async {
    await _dio.post('/nudges/send', data: {'debtor_id': debtorId});
  }
}
