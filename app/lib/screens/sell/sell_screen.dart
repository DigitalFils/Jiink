import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class SellScreen extends StatefulWidget {
  const SellScreen({super.key});

  @override
  State<SellScreen> createState() => _SellScreenState();
}

class _SellScreenState extends State<SellScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController(text: 'Nike Air Zoom Black');
  final _priceController = TextEditingController(text: '85');
  String _selectedCity = 'Manchester';
  String _selectedCategory = 'Shoes • Sneakers';
  bool _dewuAuth = true;
  bool _groupBuy = false;

  final List<String> _cities = ['Manchester', 'London', 'Birmingham', 'Liverpool', 'Leeds'];
  final List<String> _categories = [
    'Shoes • Sneakers',
    'Clothing • Jackets',
    'Clothing • Hoodies',
    'Accessories • Bags',
    'Electronics',
    'Home & Garden',
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Публикация товара /\nSell Product',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.textPrimary,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 24),
                      _buildPhotoUpload(),
                      const SizedBox(height: 24),
                      _buildTextField(
                        label: 'Название',
                        controller: _titleController,
                        hint: 'Enter product title',
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        label: 'Цена, £',
                        controller: _priceController,
                        hint: '0.00',
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 16),
                      _buildDropdown(
                        label: 'Город',
                        value: _selectedCity,
                        items: _cities,
                        onChanged: (value) => setState(() => _selectedCity = value!),
                      ),
                      const SizedBox(height: 16),
                      _buildDropdown(
                        label: 'Категория',
                        value: _selectedCategory,
                        items: _categories,
                        onChanged: (value) => setState(() => _selectedCategory = value!),
                      ),
                      const SizedBox(height: 24),
                      _buildSwitchRow(
                        title: 'Аутентификация Dewu',
                        subtitle: 'Dewu | 正品保证',
                        value: _dewuAuth,
                        onChanged: (value) => setState(() => _dewuAuth = value),
                      ),
                      const SizedBox(height: 16),
                      _buildSwitchRow(
                        title: 'Enable Group Buy',
                        subtitle: '拼团 • min 5 people',
                        value: _groupBuy,
                        onChanged: (value) => setState(() => _groupBuy = value),
                      ),
                      const SizedBox(height: 32),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            if (_formKey.currentState!.validate()) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Listing published successfully!'),
                                  backgroundColor: AppTheme.accent,
                                ),
                              );
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 18),
                          ),
                          child: const Text(
                            'Опубликовать товар',
                            style: TextStyle(fontSize: 18),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(
                Icons.diamond_outlined,
                color: AppTheme.accent,
                size: 24,
              ),
              const SizedBox(width: 6),
              const Text(
                'S8LL',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: AppTheme.textPrimary,
                  letterSpacing: -1,
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'Sell',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.close, color: AppTheme.textSecondary, size: 26),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoUpload() {
    return Container(
      width: double.infinity,
      height: 160,
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.accent.withOpacity(0.5),
          width: 1.5,
          style: BorderStyle.solid,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppTheme.surfaceLight,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.accent, width: 1.5),
            ),
            child: const Icon(Icons.add, color: AppTheme.accent, size: 24),
          ),
          const SizedBox(height: 12),
          const Text(
            'Фото товара',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Добавить до 9 фото',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 13,
              color: AppTheme.textMuted,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    String? hint,
    TextInputType? keyboardType,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppTheme.textSecondary,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          style: const TextStyle(color: AppTheme.textPrimary),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: AppTheme.textMuted),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter $label';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildDropdown({
    required String label,
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppTheme.textSecondary,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppTheme.border),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              dropdownColor: AppTheme.surface,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
              icon: const Icon(Icons.keyboard_arrow_down, color: AppTheme.textMuted),
              items: items.map((String item) {
                return DropdownMenuItem<String>(
                  value: item,
                  child: Text(item),
                );
              }).toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSwitchRow({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 13,
                  color: AppTheme.accent,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        Switch(
          value: value,
          onChanged: onChanged,
          activeColor: AppTheme.accent,
          activeTrackColor: AppTheme.accent.withOpacity(0.3),
          inactiveThumbColor: AppTheme.textMuted,
          inactiveTrackColor: AppTheme.surfaceLight,
        ),
      ],
    );
  }
}
