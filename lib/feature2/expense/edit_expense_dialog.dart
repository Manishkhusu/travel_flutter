import 'package:flutter/material.dart';
import 'package:flutter_xploverse/feature2/expense/expenseservice.dart';
import 'package:flutter_xploverse/feature2/expense/tripexpensemodel.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';

class EditExpenseDialog extends ConsumerStatefulWidget {
  final Expense expense;

  EditExpenseDialog({required this.expense});

  @override
  ConsumerState<EditExpenseDialog> createState() => _EditExpenseDialogState();
}

class _EditExpenseDialogState extends ConsumerState<EditExpenseDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _amountController;

  late DateTime _selectedDate;
  late TimeOfDay _selectedTime;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.expense.name);
    _amountController =
        TextEditingController(text: widget.expense.amount.toString());
    _selectedDate = widget.expense.dateTime;
    _selectedTime = TimeOfDay.fromDateTime(widget.expense.dateTime);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );

    if (picked != null && picked != _selectedTime) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  void _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_isSubmitting) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      // Ensure Firebase is initialized
      final dateTime = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _selectedTime.hour,
        _selectedTime.minute,
      );

      // Create Expense object
      final updatedExpense = Expense(
        name: _nameController.text.trim(),
        amount: double.parse(_amountController.text.trim()),
        dateTime: dateTime,
        userId: widget.expense.userId,
        id: widget.expense.id,
      );

      // Add expense to the database
      final expenseService = ref.read(expenseServiceProvider);
      await expenseService.updateExpense(updatedExpense);

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Expense updated successfully! 🎉'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );

      Navigator.of(context).pop();
    } catch (e) {
      // Log error to console
      print('Error adding expense: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update expense. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFFE1F5FE),
      title:
          const Text('Edit Expense', style: TextStyle(color: Colors.black87)),
      content: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _nameController,
                  style: TextStyle(
                      color: Colors.black), // Change text color to black
                  decoration: InputDecoration(
                    labelText: 'Expense Name',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.description,
                        color: Colors.black54), // Icon color
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter expense name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _amountController,
                  style: TextStyle(color: Colors.black),
                  decoration: InputDecoration(
                    labelText: 'Amount',
                    border: OutlineInputBorder(),
                    prefixIcon: Padding(
                      // Added Padding
                      padding: const EdgeInsets.only(
                          left: 8.0), // Adjust the left padding value here
                      child: IntrinsicWidth(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('NPR ',
                                style: TextStyle(
                                    fontSize: 16, color: Colors.black54)),
                            SizedBox(width: 4), //Add a little space
                          ],
                        ),
                      ),
                    ),
                  ),
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter an amount';
                    }
                    if (double.tryParse(value) == null) {
                      return 'Please enter a valid number';
                    }
                    if (double.parse(value) <= 0) {
                      return 'Amount must be greater than zero';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                Card(
                  color: Colors.white,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Date and Time',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: InkWell(
                                onTap: () => _selectDate(context),
                                child: InputDecorator(
                                  decoration: const InputDecoration(
                                    labelText: 'Date',
                                    border: OutlineInputBorder(),
                                    prefixIcon: Icon(Icons.calendar_today,
                                        color: Colors.black54),
                                  ),
                                  child: Text(
                                    DateFormat('MMM dd, yyyy')
                                        .format(_selectedDate),
                                    style: TextStyle(
                                      color: Colors.black87,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: InkWell(
                                onTap: () => _selectTime(context),
                                child: InputDecorator(
                                  decoration: const InputDecoration(
                                    labelText: 'Time',
                                    border: OutlineInputBorder(),
                                    prefixIcon: Icon(Icons.access_time,
                                        color: Colors.black54),
                                  ),
                                  child: Text(
                                    _selectedTime.format(context),
                                    style: TextStyle(
                                      color: Colors.black87,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: const Text('Cancel', style: TextStyle(color: Colors.black87)),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.yellow[700],
          ),
          onPressed: _isSubmitting ? null : _submitForm,
          child: _isSubmitting
              ? const CircularProgressIndicator(color: Colors.white)
              : const Text(
                  'Update',
                  style: TextStyle(fontSize: 16, color: Colors.black87),
                ),
        ),
      ],
    );
  }
}
