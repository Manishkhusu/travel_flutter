import 'package:flutter/material.dart';

class TripCategories {
  static const List<String> weatherOptions = [
    'Sunny',
    'Rainy',
    'Foggy',
    'Cloudy',
    'Snowy',
    'Windy',
    'Hot',
    'Cold'
  ];

  static const List<String> behaviorOptions = [
    'Smoking Allowed',
    'Non-smoking',
    'Drinking',
    'Family Friendly',
    'Party',
    'Quiet',
    'Pet Friendly',
    'Photography',
    'Adventure',
    'Relaxing'
  ];
}

class TripCategoriesWidget extends StatefulWidget {
  final Map<String, dynamic> initialCategories;
  final Function(Map<String, dynamic>) onCategoriesChanged;
  final bool isEditable;

  const TripCategoriesWidget({
    Key? key,
    required this.initialCategories,
    required this.onCategoriesChanged,
    this.isEditable = true,
  }) : super(key: key);

  @override
  _TripCategoriesWidgetState createState() => _TripCategoriesWidgetState();
}

class _TripCategoriesWidgetState extends State<TripCategoriesWidget> {
  late Map<String, dynamic> _categories;
  final _budgetController = TextEditingController();
  final _daysController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _categories = {
      'weather': List<String>.from(widget.initialCategories['weather'] ?? []),
      'behavior': List<String>.from(widget.initialCategories['behavior'] ?? []),
      'budget': widget.initialCategories['budget'] ?? '',
      'travelDays': widget.initialCategories['travelDays'] ?? '',
    };
    _budgetController.text = _categories['budget'];
    _daysController.text = _categories['travelDays'];
  }

  void _updateCategories() {
    widget.onCategoriesChanged(_categories);
  }

  Widget _buildMultiSelect(
      String title, List<String> options, String categoryKey) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        widget.isEditable
            ? Wrap(
                spacing: 8,
                runSpacing: 8,
                children: options.map((option) {
                  final isSelected = (_categories[categoryKey] as List<String>)
                      .contains(option);
                  return FilterChip(
                    label: Text(option),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        if (selected) {
                          (_categories[categoryKey] as List<String>)
                              .add(option);
                        } else {
                          (_categories[categoryKey] as List<String>)
                              .remove(option);
                        }
                        _updateCategories();
                      });
                    },
                    selectedColor: Colors.blue[100],
                    checkmarkColor: Colors.blue,
                  );
                }).toList(),
              )
            : Wrap(
                spacing: 8,
                runSpacing: 8,
                children: (_categories[categoryKey] as List<String>)
                    .map((option) => Chip(
                          label: Text(option),
                          backgroundColor: Colors.blue[100],
                        ))
                    .toList(),
              ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildInputField(String title, TextEditingController controller,
      String categoryKey, String hint) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        widget.isEditable
            ? TextField(
                controller: controller,
                decoration: InputDecoration(
                  hintText: hint,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onChanged: (value) {
                  setState(() {
                    _categories[categoryKey] = value;
                    _updateCategories();
                  });
                },
              )
            : Text(
                _categories[categoryKey] ?? 'Not specified',
                style: const TextStyle(fontSize: 16),
              ),
        const SizedBox(height: 16),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildMultiSelect('Weather', TripCategories.weatherOptions, 'weather'),
        _buildInputField('Budget', _budgetController, 'budget',
            'Enter budget (e.g., 10-15k)'),
        _buildInputField('Travel Days', _daysController, 'travelDays',
            'Enter number of days (e.g., 12-14)'),
        _buildMultiSelect(
            'Behavior', TripCategories.behaviorOptions, 'behavior'),
      ],
    );
  }

  @override
  void dispose() {
    _budgetController.dispose();
    _daysController.dispose();
    super.dispose();
  }
}
