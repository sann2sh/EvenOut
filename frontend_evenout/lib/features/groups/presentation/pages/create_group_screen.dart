import 'package:flutter/material.dart';
import '../../data/models/group_model.dart';

class CreateGroupScreen extends StatefulWidget {
  const CreateGroupScreen({super.key});

  @override
  State<CreateGroupScreen> createState() => _CreateGroupScreenState();
}

class _CreateGroupScreenState extends State<CreateGroupScreen> {
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  
  final List<Map<String, String>> _mockContacts = [
    {'name': 'Anuska Parajuli', 'initial': 'AP', 'color': '0xFF9C27B0'},
    {'name': 'Santosh Ray', 'initial': 'SR', 'color': '0xFF3F51B5'},
    {'name': 'Subash Gaire', 'initial': 'SG', 'color': '0xFF009688'},
    {'name': 'Prajwol Shrestha', 'initial': 'PS', 'color': '0xFFFF5722'},
    {'name': 'Elle Johnson', 'initial': 'EJ', 'color': '0xFFE91E63'},
    {'name': 'Earl Myers', 'initial': 'EM', 'color': '0xFF4CAF50'},
    {'name': 'Ramesh KC', 'initial': 'RK', 'color': '0xFFFF9800'},
  ];

  final List<String> _selectedContacts = [];
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
                        '${_selectedContacts.length} selected',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: brandGreen),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  
                  Container(
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _mockContacts.length,
                      separatorBuilder: (context, index) => Divider(
                        color: isDark ? Colors.white10 : Colors.grey.shade100,
                        height: 1,
                      ),
                      itemBuilder: (context, index) {
                        final contact = _mockContacts[index];
                        final name = contact['name']!;
                        final initial = contact['initial']!;
                        final hexColor = int.parse(contact['color']!);
                        final isAdded = _selectedContacts.contains(name);

                        return ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                          leading: CircleAvatar(
                            radius: 18,
                            backgroundColor: Color(hexColor),
                            child: Text(
                              initial,
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                          ),
                          title: Text(
                            name,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: textColor,
                            ),
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
                            child: isAdded 
                                ? const Icon(Icons.check, size: 14, color: Colors.white)
                                : null,
                          ),
                          onTap: () {
                            setState(() {
                              if (isAdded) {
                                _selectedContacts.remove(name);
                              } else {
                                _selectedContacts.add(name);
                              }
                            });
                          },
                        );
                      },
                    ),
                  ),
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
                onPressed: () {
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

                  // Add dynamically into mock lists so they see it live
                  setState(() {
                    mockGroups.add(
                      EvenOutGroup(
                        id: (mockGroups.length + 1).toString(),
                        name: name,
                        avatarType: _selectedCategory.toLowerCase() == 'hackathon' 
                            ? 'elephant' 
                            : 'diamond',
                        avatarBgColor: brandGreen,
                        lastActive: 'Active just now',
                        members: [
                          GroupMember(name: 'You', avatarUrl: '', balance: 0.0),
                          ..._selectedContacts.map((c) => GroupMember(name: c, avatarUrl: '', balance: 0.0)),
                        ],
                        expenses: [],
                      ),
                    );
                  });

                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Row(
                        children: [
                          const Icon(Icons.check_circle_rounded, color: Colors.white),
                          const SizedBox(width: 10),
                          Text('Group "$name" created successfully!'),
                        ],
                      ),
                      backgroundColor: brandGreen,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
                child: const Text(
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
}
