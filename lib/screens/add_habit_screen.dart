import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/habit_provider.dart';

class AddHabitScreen extends StatefulWidget {
  const AddHabitScreen({super.key});

  @override
  State<AddHabitScreen> createState() => _AddHabitScreenState();
}

class _AddHabitScreenState extends State<AddHabitScreen> {
  final _controller = TextEditingController();
  final _customCategoryController = TextEditingController();

  bool _isLoading = false;
  String _selectedFrequency = 'Daily';
  // Make _selectedDays final
  final List<bool> _selectedDays = List.filled(7, false);

  String _selectedCategoryOption = 'AI';
  final List<String> _defaultCategoryOptions = ['AI', 'Personal', 'Work', 'Education'];
  final List<String> _customCategories = [];
  List<String> get _categoryOptions => [
    ..._defaultCategoryOptions,
    ..._customCategories,
    'Custom',
  ];
  final List<String> _frequencies = ['Daily', 'Weekly', 'Monthly', 'Custom'];
  final List<String> _daysOfWeek = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  @override
  void initState() {
    super.initState();
    _loadCustomCategories();
  }

  Future<void> _loadCustomCategories() async {
    await Provider.of<HabitProvider>(context, listen: false).loadCategoriesFromFirestore();
    final provider = Provider.of<HabitProvider>(context, listen: false);
    if (!mounted) return;
    setState(() {
      _customCategories.clear();
      _customCategories.addAll(provider.categoryStyleCache.keys.where((cat) => !_defaultCategoryOptions.contains(cat) && cat != 'ai' && cat != 'custom'));
    });
  }

  void _addCustomCategory() async {
    final newCat = _customCategoryController.text.trim();
    if (newCat.isEmpty) return;
    if (_defaultCategoryOptions.contains(newCat) || _customCategories.contains(newCat)) return;
    setState(() {
      _customCategories.add(newCat);
      _selectedCategoryOption = newCat;
      _customCategoryController.clear();
    });
    // Save to Firestore immediately (category only, no task)
    await Provider.of<HabitProvider>(context, listen: false).addCategory(newCat);
  }

  Future<void> _deleteCustomCategory(String category) async {
    setState(() {
      _customCategories.remove(category);
      if (_selectedCategoryOption == category) {
        _selectedCategoryOption = 'AI';
      }
    });
    await Provider.of<HabitProvider>(context, listen: false).deleteCategoryFromFirestore(category);
  }

  Future<void> _submit() async {
    final name = _controller.text.trim();
    if (name.isEmpty) return;

    setState(() => _isLoading = true);

    // Use AI or user category as selected
    String? userCategory;
    if (_selectedCategoryOption != 'AI') {
      if (_selectedCategoryOption == 'Custom') {
        userCategory = _customCategoryController.text.trim();
      } else {
        userCategory = _selectedCategoryOption;
      }
    }

    List<int>? customDays;
    if (_selectedFrequency == 'Custom') {
      customDays = [];
      for (int i = 0; i < _selectedDays.length; i++) {
        if (_selectedDays[i]) {
          customDays.add(i + 1); // Monday is 1, Sunday is 7
        }
      }
    }

    await Provider.of<HabitProvider>(context, listen: false).addHabitAI(
      name,
      _selectedFrequency,
      userCategory: userCategory,
      customDays: customDays,
    );

    setState(() => _isLoading = false);
    if (!mounted) return;
    Navigator.pop(context);
  }

  @override
  void dispose() {
    _controller.dispose();
    _customCategoryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(24, 24, 24, 24 + bottomInset),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface.withAlpha(240),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(10),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                  border: Border.all(color: Theme.of(context).colorScheme.outline.withAlpha(120), width: 1.2),
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary.withAlpha(25),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.add_task_rounded,
                        color: Theme.of(context).colorScheme.primary,
                        size: 32,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Create New Task',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Add a new habit to track your progress',
                      style: TextStyle(
                        fontSize: 14,
                        color: Theme.of(context).colorScheme.onSurface.withAlpha(150),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Form Container
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface.withAlpha(240),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(10),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                  border: Border.all(color: Theme.of(context).colorScheme.outline.withAlpha(120), width: 1.2),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Task Name
                    Text(
                      'Task Name',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildTextField(
                      controller: _controller,
                      label: 'Enter task name',
                      icon: Icons.task_alt_rounded,
                    ),
                    const SizedBox(height: 24),

                    // Frequency
                    Text(
                      'Frequency',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 12,
                      runSpacing: 8,
                      children: _frequencies.map((f) {
                        final selected = _selectedFrequency == f;
                        return _buildChoiceChip(
                          label: f,
                          selected: selected,
                          onSelected: (_) => setState(() => _selectedFrequency = f),
                        );
                      }).toList(),
                    ),
                    if (_selectedFrequency == 'Custom') ...[
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: List.generate(7, (index) {
                          return _buildChoiceChip(
                            label: _daysOfWeek[index],
                            selected: _selectedDays[index],
                            onSelected: (_) {
                              setState(() {
                                _selectedDays[index] = !_selectedDays[index];
                              });
                            },
                          );
                        }),
                      ),
                    ],
                    const SizedBox(height: 24),

                    // Category
                    Text(
                      'Category',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 12,
                      runSpacing: 8,
                      children: [
                        ..._categoryOptions.sublist(0, _categoryOptions.length - 1).map((option) {
                          final selected = _selectedCategoryOption == option;
                          return GestureDetector(
                            onLongPress: _customCategories.contains(option)
                                ? () => _deleteCustomCategory(option)
                                : null,
                            child: _buildChoiceChip(
                              label: option,
                              selected: selected,
                              onSelected: (_) => setState(() => _selectedCategoryOption = option),
                            ),
                          );
                        }),
                        _buildChoiceChip(
                          label: '',
                          selected: _selectedCategoryOption == 'Custom',
                          onSelected: (_) => setState(() => _selectedCategoryOption = 'Custom'),
                          icon: Icons.add_rounded,
                        ),
                      ],
                    ),
                    if (_selectedCategoryOption == 'Custom') ...[
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: _buildTextField(
                              controller: _customCategoryController,
                              label: 'Custom category name',
                              icon: Icons.category_rounded,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Theme.of(context).colorScheme.primary.withAlpha(51),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: ElevatedButton(
                              onPressed: _addCustomCategory,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Theme.of(context).colorScheme.primary,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                                elevation: 0,
                              ),
                              child: const Icon(Icons.check_rounded, color: Colors.white, size: 20),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Submit Button
              _isLoading
                  ? Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Center(
                        child: CircularProgressIndicator(),
                      ),
                    )
                  : Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Theme.of(context).colorScheme.primary.withAlpha(51),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).colorScheme.primary,
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          'Create Task',
                          style: TextStyle(
                            fontSize: 16,
                            color: Theme.of(context).colorScheme.onPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
  }) {
    return TextField(
      controller: controller,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w500,
      ),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Theme.of(context).colorScheme.onSurface),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Theme.of(context).colorScheme.outline.withAlpha(120), width: 1.2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Theme.of(context).colorScheme.outline.withAlpha(120), width: 1.2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Theme.of(context).colorScheme.primary, width: 2),
        ),
        filled: true,
        fillColor: Theme.of(context).colorScheme.surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        labelStyle: TextStyle(
          color: Theme.of(context).colorScheme.onSurface,
          fontWeight: FontWeight.w500,
        ),
        floatingLabelBehavior: FloatingLabelBehavior.auto,
      ),
    );
  }

  Widget _buildChoiceChip({
    required String label,
    required bool selected,
    required Function(bool) onSelected,
    IconData? icon,
  }) {
    return ChoiceChip(
      label: icon != null
          ? Icon(icon, size: 20, color: selected ? Theme.of(context).colorScheme.onPrimary : Theme.of(context).colorScheme.onSurface)
          : Text(
              label,
              style: TextStyle(
                color: selected ? Theme.of(context).colorScheme.onPrimary : Theme.of(context).colorScheme.onSurface,
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
            ),
      selected: selected,
      onSelected: onSelected,
      selectedColor: Theme.of(context).colorScheme.primary,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: selected ? 2 : 0,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      showCheckmark: false,
    );
  }
}
