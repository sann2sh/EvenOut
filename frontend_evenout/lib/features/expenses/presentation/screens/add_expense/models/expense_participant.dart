class ExpenseParticipant {
  final String id;
  final String name;
  final String? avatarUrl;
  final bool isMe;

  const ExpenseParticipant({
    required this.id,
    required this.name,
    this.avatarUrl,
    required this.isMe,
  });
}
