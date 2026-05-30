class TransactionDetail {
  final String description;
  final String category;
  final double amount;

  TransactionDetail({
    required this.description,
    required this.category,
    required this.amount,
  });
}

class FriendBalance {
  final String name;
  final double? amount; // positive = they owe you (green), negative = you owe them (red), null = settled
  final String avatarUrl; 
  final List<TransactionDetail>? details;

  FriendBalance({
    required this.name,
    this.amount,
    required this.avatarUrl,
    this.details,
  });
}

// Figma-aligned Mock Balances
final List<FriendBalance> mockBalances = [
  FriendBalance(
    name: 'Asmit Ghimire',
    amount: 50.00,
    avatarUrl: 'https://i.pravatar.cc/150?u=asmit',
    details: [
      TransactionDetail(description: 'Jack Smith owes you', category: 'Burgers', amount: 25.00),
      TransactionDetail(description: 'Jack Smith owes you', category: 'Food & Drinks', amount: 25.00),
    ],
  ),
  FriendBalance(name: 'Santosh Ray', avatarUrl: 'https://i.pravatar.cc/150?u=santosh'),
  FriendBalance(name: 'Anuska', amount: -20.25, avatarUrl: 'https://i.pravatar.cc/150?u=anuska'),
  FriendBalance(name: 'Kapuri', amount: 75.50, avatarUrl: 'https://i.pravatar.cc/150?u=kapuri'),
  FriendBalance(name: 'Safal', avatarUrl: 'https://i.pravatar.cc/150?u=safal'),
  FriendBalance(name: 'Gagan', amount: -55.00, avatarUrl: 'https://i.pravatar.cc/150?u=gagan'),
];
