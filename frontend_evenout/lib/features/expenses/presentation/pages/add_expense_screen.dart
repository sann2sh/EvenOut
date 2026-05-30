import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:frontend_evenout/features/groups/data/models/group_model.dart';

class AddExpenseScreen extends StatefulWidget {
  final String? initialGroupName;
  const AddExpenseScreen({super.key, this.initialGroupName});

  @override
  State<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen> {
  @override
  void initState() {
    super.initState();
    if (widget.initialGroupName != null) {
      _selectedTargetName = widget.initialGroupName!;
      _selectedTargetType = 'group';
      
      final matchedGroup = mockGroups.firstWhere(
        (g) => g.name.toLowerCase() == widget.initialGroupName!.toLowerCase(),
        orElse: () => mockGroups[0],
      );
      _selectedTargetEmoji = matchedGroup.avatarType == 'elephant' 
          ? '🐘' 
          : matchedGroup.avatarType == 'scenic' 
              ? '⛰️' 
              : '💎';
    }
  }
  final _nameController = TextEditingController(text: 'Coffee');
  final _categoryController = TextEditingController(text: 'Food');
  
  String _amount = '1500';
  String _selectedCurrency = 'NPR';
  String _paidBy = 'Kapuri';
  String _splitMethod = 'Split Equally';
  
  // You and selection state
  bool _isSelectionOpen = false;
  String _selectedTargetName = 'Hackathon team';
  String _selectedTargetType = 'group'; // 'friend' or 'group'
  String _selectedTargetEmoji = '🐘';
  
  // Active selected Date
  String _selectedDateText = 'Month 2026';

  final List<Map<String, String>> _mockFriends = [
    {'name': 'Asmit Ghimire', 'avatar': 'AG', 'color': '0xFF9C27B0'},
    {'name': 'Anuska Parajuli', 'avatar': 'AP', 'color': '0xFFE91E63'},
    {'name': 'Santosh Ray', 'avatar': 'SR', 'color': '0xFF3F51B5'},
    {'name': 'Subash Gaire', 'avatar': 'SG', 'color': '0xFF009688'},
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    // Pixel-perfect replication of mockup screenshot background & colors
    final Color backgroundColor = isDark ? const Color(0xFF1E1E2E) : const Color(0xFFEDF0F5);
    final Color cardColor = isDark ? const Color(0xFF2A2A3A) : Colors.white;
    final Color textColor = isDark ? Colors.white : Colors.black;
    final Color subtextColor = isDark ? Colors.white60 : Colors.black54;

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                // 1. Top bar with cancel (left), swipe (center), save (right)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Circular close action
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: CircleAvatar(
                          radius: 18,
                          backgroundColor: isDark ? Colors.white10 : Colors.black.withOpacity(0.08),
                          child: Icon(Icons.close_rounded, size: 16, color: textColor.withOpacity(0.7)),
                        ),
                      ),
                      
                      // Swipe indicator bar
                      Container(
                        width: 44,
                        height: 5,
                        decoration: BoxDecoration(
                          color: isDark ? Colors.white24 : Colors.grey.shade400,
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      
                      // Save outline floppy style action
                      GestureDetector(
                        onTap: _saveExpense,
                        child: Icon(
                          Icons.save_outlined,
                          size: 22,
                          color: textColor.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                ),
                
                // 2. You and: Capsule selector chip
                const SizedBox(height: 10),
                Center(
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _isSelectionOpen = !_isSelectionOpen;
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: cardColor,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'You and: ',
                            style: TextStyle(
                              color: isDark ? Colors.white70 : Colors.grey.shade700,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(width: 4),
                          // Scenic/mountain background avatar representation
                          ClipOval(
                            child: Container(
                              width: 16,
                              height: 16,
                              color: Colors.blue.shade100,
                              child: Image.network(
                                'https://images.unsplash.com/photo-1464822759023-fed622ff2c3b?w=80&q=80',
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) => Container(color: Colors.blue),
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            _selectedTargetName,
                            style: TextStyle(
                              color: textColor,
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            _selectedTargetEmoji,
                            style: const TextStyle(fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                
                // 3. Grid Form elements (Rounded white borders with soft shadows)
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ROW 1: Coffee & Category Fields
                        Row(
                          children: [
                            // Coffee field
                            Expanded(
                              flex: 3,
                              child: _buildMockupTextField(
                                controller: _nameController,
                                isDark: isDark,
                                cardColor: cardColor,
                                textColor: textColor,
                              ),
                            ),
                            const SizedBox(width: 14),
                            
                            // Category field
                            Expanded(
                              flex: 2,
                              child: _buildMockupTextField(
                                controller: _categoryController,
                                isDark: isDark,
                                cardColor: cardColor,
                                textColor: textColor,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),
                        
                        // ROW 2: Currency NPR & Amount selector
                        Row(
                          children: [
                            // NPR Selector
                            Expanded(
                              flex: 2,
                              child: _buildMockupCurrencyPicker(isDark, cardColor, textColor, subtextColor),
                            ),
                            const SizedBox(width: 14),
                            
                            // Amount display
                            Expanded(
                              flex: 3,
                              child: Container(
                                height: 48,
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                decoration: BoxDecoration(
                                  color: cardColor,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Align(
                                  alignment: Alignment.centerRight,
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      Text(
                                        _amount.isEmpty ? '0' : _amount,
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w500,
                                          color: textColor,
                                        ),
                                      ),
                                      _buildMockupCursor(textColor),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),
                        
                        // ROW 3: Dropdowns and descriptive labels beneath
                        Row(
                          children: [
                            // Paid By
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  _buildMockupDropdown(
                                    val: _paidBy,
                                    options: ['Kapuri', 'You', 'Asmit', 'Elle', 'Earl'],
                                    isDark: isDark,
                                    cardColor: cardColor,
                                    textColor: textColor,
                                    subtextColor: subtextColor,
                                    onChanged: (v) => setState(() => _paidBy = v),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'Paid By',
                                    style: TextStyle(fontSize: 11, color: subtextColor, fontWeight: FontWeight.w500),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 14),
                            
                            // Split Method
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  _buildMockupDropdown(
                                    val: _splitMethod,
                                    options: ['Split Equally', 'Split by %', 'Split by exact amount'],
                                    isDark: isDark,
                                    cardColor: cardColor,
                                    textColor: textColor,
                                    subtextColor: subtextColor,
                                    onChanged: (v) => setState(() => _splitMethod = v),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'Split Method',
                                    style: TextStyle(fontSize: 11, color: subtextColor, fontWeight: FontWeight.w500),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                
                // 4. Custom keypads replicating mockup layout perfectly
                _buildMockupKeypad(isDark, textColor, subtextColor),
              ],
            ),
            
            // 5. Dynamic selector list drawer
            if (_isSelectionOpen)
              _buildCleanSelectionOverlay(isDark, textColor, subtextColor),
          ],
        ),
      ),
    );
  }

  // Pure white borderless field matching mockup
  Widget _buildMockupTextField({
    required TextEditingController controller,
    required bool isDark,
    required Color cardColor,
    required Color textColor,
  }) {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(10),
      ),
      child: TextField(
        controller: controller,
        style: TextStyle(color: textColor, fontWeight: FontWeight.normal, fontSize: 15),
        decoration: const InputDecoration(
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        ),
      ),
    );
  }

  // Currency Picker matching mockup
  Widget _buildMockupCurrencyPicker(bool isDark, Color cardColor, Color textColor, Color subtextColor) {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 22,
                height: 18,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(2),
                  color: const Color(0xFFDC143C),
                  border: Border.all(color: const Color(0xFF003893), width: 1.5),
                ),
                child: const Center(
                  child: Text(
                    '🇳🇵',
                    style: TextStyle(fontSize: 10, height: 1.0),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                _selectedCurrency,
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.normal, color: textColor),
              ),
            ],
          ),
          Icon(Icons.keyboard_arrow_down_rounded, color: subtextColor, size: 18),
        ],
      ),
    );
  }

  // Dropdown matching mockup
  Widget _buildMockupDropdown({
    required String val,
    required List<String> options,
    required bool isDark,
    required Color cardColor,
    required Color textColor,
    required Color subtextColor,
    required Function(String) onChanged,
  }) {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(10),
      ),
      child: DropdownButton<String>(
        value: val,
        icon: Icon(Icons.keyboard_arrow_down_rounded, color: subtextColor, size: 18),
        underline: const SizedBox(),
        isExpanded: true,
        style: TextStyle(color: textColor, fontWeight: FontWeight.normal, fontSize: 14),
        dropdownColor: isDark ? const Color(0xFF2E2E2E) : Colors.white,
        items: options.map((String opt) {
          return DropdownMenuItem<String>(
            value: opt,
            child: Text(opt),
          );
        }).toList(),
        onChanged: (String? newV) {
          if (newV != null) onChanged(newV);
        },
      ),
    );
  }

  // Pulsating Cursor representing manual focus
  Widget _buildMockupCursor(Color color) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 500),
      builder: (context, val, child) {
        return Opacity(
          opacity: val > 0.5 ? 1.0 : 0.0,
          child: Container(
            width: 1.5,
            height: 18,
            margin: const EdgeInsets.only(left: 3),
            color: color,
          ),
        );
      },
      onEnd: () {},
    );
  }

  // Mockup Alphanumeric Keypad matching screenshot details
  Widget _buildMockupKeypad(bool isDark, Color textColor, Color subtextColor) {
    final keypadColor = isDark ? const Color(0xFF1E1E28) : const Color(0xFFD6DBE2);
    final keyBgColor = isDark ? const Color(0xFF2E2E3E) : Colors.white;
    
    return Container(
      color: keypadColor,
      child: Column(
        children: [
          // Custom Date Row: "Month 2026 >"
          GestureDetector(
            onTap: _pickCustomDate,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              color: Colors.black.withOpacity(0.02),
              child: Row(
                children: [
                  Text(
                    _selectedDateText,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.normal,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(width: 3),
                  // Chevron blue arrow
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: Color(0xFF007AFF), // Blue color matching mockup arrow
                    size: 16,
                  ),
                ],
              ),
            ),
          ),
          
          // Keys Grid
          Padding(
            padding: const EdgeInsets.only(left: 8.0, right: 8.0, bottom: 20.0, top: 4.0),
            child: Column(
              children: [
                Row(
                  children: [
                    _buildMockupKey('1', '', keyBgColor, textColor),
                    _buildMockupKey('2', 'ABC', keyBgColor, textColor),
                    _buildMockupKey('3', 'DEF', keyBgColor, textColor),
                  ],
                ),
                Row(
                  children: [
                    _buildMockupKey('4', 'GHI', keyBgColor, textColor),
                    _buildMockupKey('5', 'JKL', keyBgColor, textColor),
                    _buildMockupKey('6', 'MNO', keyBgColor, textColor),
                  ],
                ),
                Row(
                  children: [
                    _buildMockupKey('7', 'PQRS', keyBgColor, textColor),
                    _buildMockupKey('8', 'TUV', keyBgColor, textColor),
                    _buildMockupKey('9', 'WXYZ', keyBgColor, textColor),
                  ],
                ),
                Row(
                  children: [
                    _buildMockupKey('.', '', keyBgColor, textColor),
                    _buildMockupKey('0', '', keyBgColor, textColor),
                    _buildBackspaceButton(keyBgColor, textColor),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Key element builder
  Widget _buildMockupKey(String digit, String letters, Color bg, Color txt) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.all(4.0),
        height: 48,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: bg,
            elevation: 1,
            shadowColor: Colors.black.withOpacity(0.08),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(6),
            ),
            padding: EdgeInsets.zero,
          ),
          onPressed: () => _onKeypadPressed(digit),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                digit,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.normal,
                  color: txt,
                ),
              ),
              if (letters.isNotEmpty)
                Text(
                  letters,
                  style: const TextStyle(
                    fontSize: 7,
                    fontWeight: FontWeight.bold,
                    color: Colors.black54,
                    letterSpacing: 0.5,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // Backspace icon button
  Widget _buildBackspaceButton(Color bg, Color txt) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.all(4.0),
        height: 48,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: bg,
            elevation: 1,
            shadowColor: Colors.black.withOpacity(0.08),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(6),
            ),
          ),
          onPressed: _onBackspacePressed,
          child: Icon(
            Icons.backspace_outlined,
            color: txt,
            size: 18,
          ),
        ),
      ),
    );
  }

  // Selection overlay dropdown matching mockup theme
  Widget _buildCleanSelectionOverlay(bool isDark, Color textColor, Color subtextColor) {
    return Positioned(
      top: 60,
      left: 20,
      right: 20,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF262626) : Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Search Input
            Container(
              height: 38,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: isDark ? Colors.white10 : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(Icons.search_rounded, color: Colors.blue, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      style: GoogleFonts.inter(color: textColor, fontSize: 13),
                      decoration: InputDecoration(
                        hintText: 'Search friends or groups...',
                        hintStyle: GoogleFonts.inter(color: Colors.grey.shade400, fontSize: 12),
                        border: InputBorder.none,
                        isDense: true,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            
            // Friends section
            Text(
              'Friends :',
              style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w800, color: subtextColor),
            ),
            const SizedBox(height: 8),
            
            Column(
              children: _mockFriends.map((friend) {
                final name = friend['name']!;
                final avatar = friend['avatar']!;
                final isSelected = _selectedTargetName == name;
                
                return Material(
                  color: Colors.transparent,
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                    leading: CircleAvatar(
                      radius: 12,
                      backgroundColor: Color(int.parse(friend['color']!)),
                      child: Text(avatar, style: GoogleFonts.inter(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold)),
                    ),
                    title: Text(
                      name,
                      style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold, color: textColor),
                    ),
                    trailing: Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        color: isSelected ? Colors.blue : Colors.transparent,
                        shape: BoxShape.circle,
                        border: Border.all(color: isSelected ? Colors.blue : Colors.grey.shade400, width: 1.5),
                      ),
                      child: isSelected ? const Icon(Icons.check, size: 10, color: Colors.white) : null,
                    ),
                    onTap: () {
                      setState(() {
                        _selectedTargetName = name;
                        _selectedTargetType = 'friend';
                        _selectedTargetEmoji = '👤';
                        _isSelectionOpen = false;
                        _paidBy = 'You';
                      });
                    },
                  ),
                );
              }).toList(),
            ),
            const Divider(height: 16),
            
            // Groups Section
            Text(
              'Groups :',
              style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w800, color: subtextColor),
            ),
            const SizedBox(height: 8),
            
            Column(
              children: mockGroups.map((group) {
                final isSelected = _selectedTargetName == group.name;
                final String emoji = group.avatarType == 'elephant' 
                    ? '🐘' 
                    : group.avatarType == 'scenic' 
                        ? '⛰️' 
                        : '💎';
                
                return Material(
                  color: Colors.transparent,
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                    leading: CircleAvatar(
                      radius: 12,
                      backgroundColor: group.avatarBgColor,
                      child: Icon(
                        group.avatarType == 'diamond' 
                            ? Icons.diamond_rounded 
                            : group.avatarType == 'scenic' 
                                ? Icons.landscape_rounded 
                                : Icons.terminal_rounded,
                        size: 11,
                        color: Colors.white,
                      ),
                    ),
                    title: Text(
                      group.name,
                      style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold, color: textColor),
                    ),
                    trailing: Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        color: isSelected ? Colors.blue : Colors.transparent,
                        shape: BoxShape.circle,
                        border: Border.all(color: isSelected ? Colors.blue : Colors.grey.shade400, width: 1.5),
                      ),
                      child: isSelected ? const Icon(Icons.check, size: 10, color: Colors.white) : null,
                    ),
                    onTap: () {
                      setState(() {
                        _selectedTargetName = group.name;
                        _selectedTargetType = 'group';
                        _selectedTargetEmoji = emoji;
                        _isSelectionOpen = false;
                        _paidBy = 'Kapuri';
                      });
                    },
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  // Key operations
  void _onKeypadPressed(String val) {
    setState(() {
      if (val == '.') {
        if (!_amount.contains('.')) {
          _amount = _amount.isEmpty ? '0.' : '$_amount.';
        }
      } else {
        if (_amount == '0') {
          _amount = val;
        } else {
          _amount = '$_amount$val';
        }
      }
    });
  }

  void _onBackspacePressed() {
    setState(() {
      if (_amount.isNotEmpty) {
        _amount = _amount.substring(0, _amount.length - 1);
      }
    });
  }

  void _pickCustomDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime(2026, 5, 30),
      firstDate: DateTime(2025),
      lastDate: DateTime(2028),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF007AFF),
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      final List<String> months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      setState(() {
        _selectedDateText = '${picked.day} ${months[picked.month - 1]} ${picked.year}';
      });
    }
  }

  void _saveExpense() {
    final title = _nameController.text.trim();
    final doubleAmt = double.tryParse(_amount) ?? 0.0;
    
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter an expense name'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    
    if (doubleAmt <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter an amount greater than zero'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (_selectedTargetType == 'group') {
      final matchedGroup = mockGroups.firstWhere(
        (g) => g.name.toLowerCase() == _selectedTargetName.toLowerCase(),
        orElse: () => mockGroups[0],
      );
      
      matchedGroup.expenses.insert(
        0,
        GroupExpense(
          id: 'new_e_${matchedGroup.expenses.length + 1}',
          title: title,
          amount: doubleAmt,
          date: _selectedDateText == 'Month 2026' ? 'Today, 8:00 PM' : _selectedDateText,
          paidBy: _paidBy,
          icon: _categoryController.text.toLowerCase().contains('coffee') 
              ? Icons.local_cafe_rounded 
              : Icons.receipt_long_rounded,
          color: Colors.blue,
        ),
      );
    }

    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: Colors.white),
            const SizedBox(width: 10),
            Text('Expense "\$$doubleAmt for $title" split successfully!'),
          ],
        ),
        backgroundColor: Colors.blue,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
