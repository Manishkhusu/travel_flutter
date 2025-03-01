import 'package:flutter/material.dart';
import 'package:flutter_xploverse/feature2/expense/expenseservice.dart';
import 'package:flutter_xploverse/feature2/expense/tripexpensemodel.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AddExpenseScreen extends ConsumerStatefulWidget {
  @override
  ConsumerState<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends ConsumerState<AddExpenseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _amountController = TextEditingController();

  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();
  bool _isSubmitting = false;

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
      User? user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Error: User not logged in!'),
              backgroundColor: Colors.red),
        );
        return;
      }
      final String userId = user.uid;

      final dateTime = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _selectedTime.hour,
        _selectedTime.minute,
      );

      final expense = Expense(
        name: _nameController.text.trim(),
        amount: double.parse(_amountController.text.trim()),
        dateTime: dateTime,
        userId: userId,
        id: '',
      );

      try {
        // Use Riverpod's ref.read to get the ExpenseService instance
        final expenseService = ref.read(expenseServiceProvider);
        await expenseService.addExpense(expense);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Expense added successfully! 🎉'),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating),
        );

        Navigator.of(context).pop();
      } catch (e) {
        // Log the FULL error message here!  Important!
        print('Error during addExpense: $e'); // <--- IMPORTANT

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Failed to add expense. Please try again.'),
              backgroundColor: Colors.red),
        );
      }
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
      // Changed to AlertDialog
      backgroundColor:
          const Color(0xFFE1F5FE), // Background color from LandingPage
      title: Text('Add Expense',
          style:
              TextStyle(color: Colors.black87)), // Text color from LandingPage
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Expense Name',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.description,
                      color: Colors.black54), // Text color from LandingPage
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter expense name';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _amountController,
                decoration: InputDecoration(
                  labelText: 'Amount',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.attach_money,
                      color: Colors.black54), // Text color from LandingPage
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
              SizedBox(height: 16),
              Card(
                color: Colors.white, // Card color
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Date and Time',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87, // Text color from LandingPage
                        ),
                      ),
                      SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: InkWell(
                              onTap: () => _selectDate(context),
                              child: InputDecorator(
                                decoration: InputDecoration(
                                  labelText: 'Date',
                                  border: OutlineInputBorder(),
                                  prefixIcon: Icon(Icons.calendar_today,
                                      color: Colors
                                          .black54), // Text color from LandingPage
                                ),
                                child: Text(
                                  DateFormat('MMM dd, yyyy')
                                      .format(_selectedDate),
                                  style: TextStyle(
                                      color: Colors
                                          .black87), // Text color from LandingPage
                                ),
                              ),
                            ),
                          ),
                          SizedBox(width: 16),
                          Expanded(
                            child: InkWell(
                              onTap: () => _selectTime(context),
                              child: InputDecorator(
                                decoration: InputDecoration(
                                  labelText: 'Time',
                                  border: OutlineInputBorder(),
                                  prefixIcon: Icon(Icons.access_time,
                                      color: Colors
                                          .black54), // Text color from LandingPage
                                ),
                                child: Text(
                                  _selectedTime.format(context),
                                  style: TextStyle(
                                      color: Colors
                                          .black87), // Text color from LandingPage
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
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop(); // Close the dialog
          },
          child: Text('Cancel',
              style: TextStyle(
                  color: Colors.black87)), // Text color from LandingPage
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.yellow[700], // Button color
          ),
          onPressed: _isSubmitting ? null : _submitForm,
          child: _isSubmitting
              ? CircularProgressIndicator(color: Colors.white)
              : Text(
                  'Save',
                  style: TextStyle(
                      fontSize: 16,
                      color: Colors.black87), // Text color from LandingPage
                ),
        ),
      ],
    );
  }
}
