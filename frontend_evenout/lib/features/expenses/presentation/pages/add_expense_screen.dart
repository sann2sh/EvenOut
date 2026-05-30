import 'package:flutter/material.dart';
import 'package:frontend_evenout/features/groups/data/models/group_model.dart';

class AddExpenseScreen extends StatefulWidget {
  const AddExpenseScreen({super.key});

  @override
  State<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen> {
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
  Color _selectedTargetColor = const Color(0xFF78909C);
  
  // Active selected Date
  String _selectedDateText = 'Month 2026';

  final List<Map<String, String>> _mockFriends = [
    {'name': 'Asmit Ghimire', 'avatar': 'AG', 'color': '0xFFE91E63'},
    {'name': 'Anuska Parajuli', 'avatar': 'AP', 'color': '0xFF9C27B0'},
    {'name': 'Santosh Ray', 'avatar': 'SR', 'color': '0xFF3F51B5'},
    {'name': 'Subash Gaire', 'avatar': 'SG', 'color': '0xFF009688'},
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    final Color backgroundColor = isDark ? const Color(0xFF1E1E1E) : const Color(0xFFF3F3F3);
    final Color inputFillColor = isDark ? Colors.white10 : Colors.white;
    final Color textColor = isDark ? Colors.white : const Color(0xFF1B1B3A);
    final Color subtextColor = isDark ? Colors.white60 : Colors.black54;
    final Color brandGreen = const Color(0xFF429246);

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                // 1. Sleek Header Bar matching mockup
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Circular close icon
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: isDark ? Colors.white10 : Colors.grey.shade300,
                        child: IconButton(
                          icon: const Icon(Icons.close_rounded, size: 18),
                          color: textColor,
                          onPressed: () => Navigator.pop(context),
                        ),
                      ),
                      
                      // Center swipe bar indicator
                      Container(
                        width: 44,
                        height: 5,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade400,
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      
                      // Save floppy icon button
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: isDark ? Colors.white10 : Colors.grey.shade300,
                        child: IconButton(
                          icon: const Icon(Icons.save_rounded, size: 18),
                          color: brandGreen,
                          onPressed: _saveExpense,
                        ),
                      ),
                    ],
                  ),
                ),
                
                Expanded(
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 10),
                          
                          // 2. You and: Target capsule selector chip
                          Row(
                            children: [
                              Text(
                                'You and: ',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: textColor,
                                ),
                              ),
                              const SizedBox(width: 8),
                              
                              GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _isSelectionOpen = !_isSelectionOpen;
                                  });
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: isDark ? Colors.white10 : Colors.white,
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: isDark ? Colors.white24 : Colors.grey.shade300,
                                      width: 1.5,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.02),
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      if (_selectedTargetEmoji.isNotEmpty) ...[
                                        Text(_selectedTargetEmoji, style: const TextStyle(fontSize: 14)),
                                        const SizedBox(width: 8),
                                      ],
                                      Text(
                                        _selectedTargetName,
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          color: textColor,
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Icon(Icons.arrow_drop_down, color: subtextColor, size: 18),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          
                          // 3. Grid Form Fields ROW 1: Coffee & Category
                          Row(
                            children: [
                              // Expense Title Field
                              Expanded(
                                flex: 3,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildFormTextField(
                                      controller: _nameController,
                                      hintText: 'Expense name...',
                                      fillColor: inputFillColor,
                                      textColor: textColor,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 16),
                              
                              // Category Selector Field
                              Expanded(
                                flex: 2,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildFormTextField(
                                      controller: _categoryController,
                                      hintText: 'Category...',
                                      fillColor: inputFillColor,
                                      textColor: textColor,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          
                          // 4. Grid Form Fields ROW 2: Currency Flag & Amount Input
                          Row(
                            children: [
                              // Nepal flag NPR selector
                              Expanded(
                                flex: 2,
                                child: _buildCurrencyDropdown(isDark, textColor, subtextColor),
                              ),
                              const SizedBox(width: 16),
                              
                              // Numeric display visual cursor text
                              Expanded(
                                flex: 3,
                                child: Container(
                                  height: 52,
                                  alignment: Alignment.centerRight,
                                  padding: const EdgeInsets.symmetric(horizontal: 16),
                                  decoration: BoxDecoration(
                                    color: inputFillColor,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: brandGreen.withOpacity(0.4),
                                      width: 1.5,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        _selectedCurrency,
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.bold,
                                          color: subtextColor,
                                        ),
                                      ),
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            _amount.isEmpty ? '0' : _amount,
                                            style: TextStyle(
                                              fontSize: 22,
                                              fontWeight: FontWeight.w900,
                                              color: brandGreen,
                                              fontFamily: 'monospace',
                                            ),
                                          ),
                                          // Pulsating active typing cursor mock
                                          _buildCursorIndicator(brandGreen),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          
                          // 5. Grid Form Fields ROW 3: Paid By & Split Method
                          Row(
                            children: [
                              // Paid By selector
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildSelectionDropdown(
                                      label: 'Paid By',
                                      val: _paidBy,
                                      options: ['Kapuri', 'You', 'Asmit', 'Elle', 'Earl'],
                                      isDark: isDark,
                                      textColor: textColor,
                                      subtextColor: subtextColor,
                                      onChanged: (v) => setState(() => _paidBy = v),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 16),
                              
                              // Split method selector
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildSelectionDropdown(
                                      label: 'Split Method',
                                      val: _splitMethod,
                                      options: ['Split Equally', 'Split by %', 'Split by exact amount'],
                                      isDark: isDark,
                                      textColor: textColor,
                                      subtextColor: subtextColor,
                                      onChanged: (v) => setState(() => _splitMethod = v),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ),
                ),
                
                // 6. Premium custom high-contrast keypad grid at the bottom!
                _buildCustomKeypad(isDark, textColor, subtextColor, brandGreen),
              ],
            ),
            
            // 7. Expandable floating overlay for "You and" selections matching mockup
            if (_isSelectionOpen)
              _buildSelectionOverlay(isDark, textColor, subtextColor, brandGreen),
          ],
        ),
      ),
    );
  }

  // Visual helper to draw custom form textfield
  Widget _buildFormTextField({
    required TextEditingController controller,
    required String hintText,
    required Color fillColor,
    required Color textColor,
  }) {
    return Container(
      height: 52,
      decoration: BoxDecoration(
        color: fillColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.01),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 15),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }

  // Visual custom Nepal Flag 🇳🇵 & NPR selector dropdown
  Widget _buildCurrencyDropdown(bool isDark, Color textColor, Color subtextColor) {
    return Container(
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: isDark ? Colors.white10 : Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              // Nepal Flag icon vector
              Container(
                width: 22,
                height: 18,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(2),
                  color: const Color(0xFFDC143C), // Crimson
                  border: Border.all(color: const Color(0xFF003893), width: 1.5), // Royal Blue Outline
                ),
                child: Center(
                  child: Text(
                    '🇳🇵',
                    style: TextStyle(fontSize: 10, height: 1.0),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                _selectedCurrency,
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: textColor),
              ),
            ],
          ),
          Icon(Icons.keyboard_arrow_down_rounded, color: subtextColor, size: 18),
        ],
      ),
    );
  }

  // Visual helper dropdown item picker
  Widget _buildSelectionDropdown({
    required String label,
    required String val,
    required List<String> options,
    required bool isDark,
    required Color textColor,
    required Color subtextColor,
    required Function(String) onChanged,
  }) {
    return Container(
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      decoration: BoxDecoration(
        color: isDark ? Colors.white10 : Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: DropdownButton<String>(
        value: val,
        icon: Icon(Icons.keyboard_arrow_down_rounded, color: subtextColor, size: 18),
        underline: const SizedBox(),
        isExpanded: true,
        style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 13),
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

  // Pulsating mock cursor line
  Widget _buildCursorIndicator(Color color) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 500),
      builder: (context, val, child) {
        return Opacity(
          opacity: val > 0.5 ? 1.0 : 0.0,
          child: Container(
            width: 2.5,
            height: 22,
            margin: const EdgeInsets.only(left: 4),
            color: color,
          ),
        );
      },
      onEnd: () {},
    );
  }

  // 1. Expandable Floating Selection Drawer
  Widget _buildSelectionOverlay(bool isDark, Color textColor, Color subtextColor, Color brandGreen) {
    return Positioned(
      top: 60,
      left: 24,
      right: 24,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF2E2E2E) : Colors.white,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.18),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Search field
            Container(
              height: 38,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: isDark ? Colors.white10 : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.search, color: subtextColor, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      style: TextStyle(color: textColor, fontSize: 13),
                      decoration: InputDecoration(
                        hintText: 'Search friends or groups...',
                        hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 12),
                        border: InputBorder.none,
                        isDense: true,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            
            // Friends section
            Text(
              'Friends :',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: subtextColor),
            ),
            const SizedBox(height: 8),
            
            // Friends items list
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _mockFriends.length,
              itemBuilder: (context, index) {
                final friend = _mockFriends[index];
                final name = friend['name']!;
                final avatar = friend['avatar']!;
                final isSelected = _selectedTargetName == name;
                
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  leading: CircleAvatar(
                    radius: 14,
                    backgroundColor: Color(int.parse(friend['color']!)),
                    child: Text(avatar, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                  ),
                  title: Text(
                    name,
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: textColor),
                  ),
                  trailing: Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      color: isSelected ? brandGreen : Colors.transparent,
                      shape: BoxShape.circle,
                      border: Border.all(color: isSelected ? brandGreen : Colors.grey.shade400, width: 1.5),
                    ),
                    child: isSelected ? const Icon(Icons.check, size: 10, color: Colors.white) : null,
                  ),
                  onTap: () {
                    setState(() {
                      _selectedTargetName = name;
                      _selectedTargetType = 'friend';
                      _selectedTargetEmoji = '👤';
                      _isSelectionOpen = false;
                      // Instantly adjust default PaidBy options
                      _paidBy = 'You';
                    });
                  },
                );
              },
            ),
            const Divider(height: 20),
            
            // Groups Section
            Text(
              'Groups :',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: subtextColor),
            ),
            const SizedBox(height: 8),
            
            // Group lists item matching mockup
            Column(
              children: mockGroups.map((group) {
                final isSelected = _selectedTargetName == group.name;
                final String emoji = group.avatarType == 'elephant' 
                    ? '🐘' 
                    : group.avatarType == 'scenic' 
                        ? '⛰️' 
                        : '💎';
                
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  leading: CircleAvatar(
                    radius: 14,
                    backgroundColor: group.avatarBgColor,
                    child: Icon(
                      group.avatarType == 'diamond' 
                          ? Icons.diamond_rounded 
                          : group.avatarType == 'scenic' 
                              ? Icons.landscape_rounded 
                              : Icons.terminal_rounded,
                      size: 14,
                      color: Colors.white,
                    ),
                  ),
                  title: Text(
                    group.name,
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: textColor),
                  ),
                  trailing: Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      color: isSelected ? brandGreen : Colors.transparent,
                      shape: BoxShape.circle,
                      border: Border.all(color: isSelected ? brandGreen : Colors.grey.shade400, width: 1.5),
                    ),
                    child: isSelected ? const Icon(Icons.check, size: 10, color: Colors.white) : null,
                  ),
                  onTap: () {
                    setState(() {
                      _selectedTargetName = group.name;
                      _selectedTargetType = 'group';
                      _selectedTargetEmoji = emoji;
                      _selectedTargetColor = group.avatarBgColor;
                      _isSelectionOpen = false;
                      // Auto-populate PaidBy list with actual group members
                      _paidBy = 'Kapuri';
                    });
                  },
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  // 2. High-Contrast Keypad Grid View Drawer
  Widget _buildCustomKeypad(bool isDark, Color textColor, Color subtextColor, Color brandGreen) {
    final keypadColor = isDark ? const Color(0xFF252525) : const Color(0xFFD6D8DD);
    final keyColor = isDark ? const Color(0xFF333333) : Colors.white;
    
    return Container(
      color: keypadColor,
      child: Column(
        children: [
          // A. Custom Date Banner Picker "Month 2026 >"
          GestureDetector(
            onTap: _pickCustomDate,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12),
              color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.04),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _selectedDateText,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(Icons.chevron_right_rounded, color: brandGreen, size: 18),
                ],
              ),
            ),
          ),
          
          // B. Numeric Keys grid
          Padding(
            padding: const EdgeInsets.only(left: 8.0, right: 8.0, bottom: 15.0, top: 4.0),
            child: Column(
              children: [
                Row(
                  children: [
                    _buildKeypadButton('1', '', keyColor, textColor),
                    _buildKeypadButton('2', 'ABC', keyColor, textColor),
                    _buildKeypadButton('3', 'DEF', keyColor, textColor),
                  ],
                ),
                Row(
                  children: [
                    _buildKeypadButton('4', 'GHI', keyColor, textColor),
                    _buildKeypadButton('5', 'JKL', keyColor, textColor),
                    _buildKeypadButton('6', 'MNO', keyColor, textColor),
                  ],
                ),
                Row(
                  children: [
                    _buildKeypadButton('7', 'PQRS', keyColor, textColor),
                    _buildKeypadButton('8', 'TUV', keyColor, textColor),
                    _buildKeypadButton('9', 'WXYZ', keyColor, textColor),
                  ],
                ),
                Row(
                  children: [
                    _buildKeypadButton('.', '', keyColor, textColor),
                    _buildKeypadButton('0', '', keyColor, textColor),
                    _buildKeypadBackspace(keyColor, textColor),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Key item helper
  Widget _buildKeypadButton(String digit, String subtitle, Color btnBgColor, Color txtColor) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.all(4.0),
        height: 48,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: btnBgColor,
            elevation: 1,
            shadowColor: Colors.black.withOpacity(0.1),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
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
                  fontWeight: FontWeight.bold,
                  color: txtColor,
                ),
              ),
              if (subtitle.isNotEmpty)
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 8,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // Backspace key item helper
  Widget _buildKeypadBackspace(Color btnBgColor, Color txtColor) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.all(4.0),
        height: 48,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: btnBgColor,
            elevation: 1,
            shadowColor: Colors.black.withOpacity(0.1),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          onPressed: _onBackspacePressed,
          child: Icon(
            Icons.backspace_outlined,
            color: txtColor,
            size: 18,
          ),
        ),
      ),
    );
  }

  // Appends characters on pressing numbers
  void _onKeypadPressed(String val) {
    setState(() {
      if (val == '.') {
        // Prevent multiple dots
        if (!_amount.contains('.')) {
          _amount = _amount.isEmpty ? '0.' : '$_amount.';
        }
      } else {
        // Prevent multiple leading zeroes
        if (_amount == '0') {
          _amount = val;
        } else {
          _amount = '$_amount$val';
        }
      }
    });
  }

  // Backspace function
  void _onBackspacePressed() {
    setState(() {
      if (_amount.isNotEmpty) {
        _amount = _amount.substring(0, _amount.length - 1);
      }
    });
  }

  // Custom date picker drawer
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
              primary: Color(0xFF429246),
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

  // Save the manual expense dynamically inside group datasets
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

    // Dynamic Database integration! If a group is selected, append the expense live so they immediately see the charts update!
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
          color: const Color(0xFF4CAF50),
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
        backgroundColor: const Color(0xFF429246),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
