import 'package:flutter/material.dart';

class GroupExpense {
  final String id;
  final String title;
  final double amount;
  final String date;
  final String paidBy;
  final IconData icon;
  final Color color;

  GroupExpense({
    required this.id,
    required this.title,
    required this.amount,
    required this.date,
    required this.paidBy,
    required this.icon,
    required this.color,
  });
}

class GroupMember {
  final String name;
  final String avatarUrl;
  double balance; // positive = owed money, negative = owes money

  GroupMember({
    required this.name,
    required this.avatarUrl,
    required this.balance,
  });
}

class EvenOutGroup {
  final String id;
  final String name;
  final String avatarType; // 'diamond', 'scenic', 'elephant', or custom letter
  final Color avatarBgColor;
  final List<GroupMember> members;
  final List<GroupExpense> expenses;
  final String lastActive;

  EvenOutGroup({
    required this.id,
    required this.name,
    required this.avatarType,
    required this.avatarBgColor,
    required this.members,
    required this.expenses,
    required this.lastActive,
  });

  // Calculate user's overall balance inside this group
  double get userBalance {
    // For demo purposes, we will return the balance of the 'You' member in this group
    final you = members.firstWhere((m) => m.name == 'You', orElse: () => GroupMember(name: 'You', avatarUrl: '', balance: 0.0));
    return you.balance;
  }

  // Calculate total expense amount inside the group
  double get totalExpenses {
    return expenses.fold(0.0, (sum, exp) => sum + exp.amount);
  }
}

// Mock Data representing the elements from the screenshot perfectly and expanding them
final List<EvenOutGroup> mockGroups = [
  EvenOutGroup(
    id: '1',
    name: 'Elle & Earl',
    avatarType: 'diamond',
    avatarBgColor: const Color(0xFF29B6F6),
    lastActive: 'Active 2 hours ago',
    members: [
      GroupMember(name: 'You', avatarUrl: '', balance: -15.50),
      GroupMember(name: 'Elle', avatarUrl: '', balance: 10.00),
      GroupMember(name: 'Earl', avatarUrl: '', balance: 5.50),
    ],
    expenses: [
      GroupExpense(
        id: 'e1',
        title: 'Starbucks Coffee split',
        amount: 18.00,
        date: 'Today, 10:30 AM',
        paidBy: 'Elle',
        icon: Icons.local_cafe_rounded,
        color: const Color(0xFFFF9800),
      ),
      GroupExpense(
        id: 'e2',
        title: 'Uber ride home',
        amount: 28.50,
        date: 'Yesterday, 8:15 PM',
        paidBy: 'Earl',
        icon: Icons.directions_car_rounded,
        color: const Color(0xFF03A9F4),
      ),
    ],
  ),
  EvenOutGroup(
    id: '2',
    name: 'Weekend Trip',
    avatarType: 'scenic',
    avatarBgColor: const Color(0xFF8D6E63),
    lastActive: 'Active Yesterday',
    members: [
      GroupMember(name: 'You', avatarUrl: '', balance: 42.00),
      GroupMember(name: 'Santosh Ray', avatarUrl: '', balance: -20.00),
      GroupMember(name: 'Anuska', avatarUrl: '', balance: -22.00),
    ],
    expenses: [
      GroupExpense(
        id: 'e3',
        title: 'Cabin Rental',
        amount: 150.00,
        date: '28 May 2026',
        paidBy: 'You',
        icon: Icons.home_rounded,
        color: const Color(0xFF673AB7),
      ),
      GroupExpense(
        id: 'e4',
        title: 'Gas & Fuel',
        amount: 45.00,
        date: '27 May 2026',
        paidBy: 'Santosh Ray',
        icon: Icons.local_gas_station_rounded,
        color: const Color(0xFF4CAF50),
      ),
    ],
  ),
  EvenOutGroup(
    id: '3',
    name: 'Hackathon Team',
    avatarType: 'elephant',
    avatarBgColor: const Color(0xFF78909C),
    lastActive: 'Active 3 days ago',
    members: [
      GroupMember(name: 'You', avatarUrl: '', balance: 0.00),
      GroupMember(name: 'Prajwol', avatarUrl: '', balance: 0.00),
      GroupMember(name: 'Subash', avatarUrl: '', balance: 0.00),
    ],
    expenses: [
      GroupExpense(
        id: 'e5',
        title: 'Team Pizzas',
        amount: 60.00,
        date: '25 May 2026',
        paidBy: 'You',
        icon: Icons.local_pizza_rounded,
        color: const Color(0xFFE91E63),
      ),
      GroupExpense(
        id: 'e6',
        title: 'Cloud Credits Hosting',
        amount: 40.00,
        date: '24 May 2026',
        paidBy: 'Prajwol',
        icon: Icons.cloud_done_rounded,
        color: const Color(0xFF607D8B),
      ),
    ],
  ),
];
