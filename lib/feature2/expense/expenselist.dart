import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'add_expense_dialog.dart';
import 'edit_expense_dialog.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_xploverse/feature2/expense/tripexpensemodel.dart';
import 'package:flutter_xploverse/feature2/expense/expenseservice.dart';

final expenseStreamProvider = StreamProvider.autoDispose<List<Expense>>((ref) {
  final userId = FirebaseAuth.instance.currentUser?.uid;
  if (userId == null) {
    // If the user is not logged in, return an empty stream
    return Stream<List<Expense>>.value([]);
  }
  // If the user is logged in, return the stream of expenses for that user
  return ref.watch(expenseServiceProvider).getExpensesForUser(userId);
});

class ExpenseListScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currencyFormat =
        NumberFormat.currency(locale: 'en_US', symbol: 'NPR ');

    return Scaffold(
      backgroundColor: const Color(0xFFE1F5FE),
      appBar: AppBar(
        title: const Text('Trip Expenses',
            style: TextStyle(color: Colors.black87)),
        backgroundColor: const Color.fromARGB(255, 45, 165, 251),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: Colors.black87),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AddExpenseScreen(),
              );
            },
          ),
        ],
      ),
      body: Consumer(
        builder: (context, ref, _) {
          final expensesAsyncValue = ref.watch(expenseStreamProvider);

          return expensesAsyncValue.when(
            data: (expenses) {
              if (expenses.isEmpty) {
                return const Center(
                  child: Text(
                    'No expenses yet. Add your first expense!',
                    style: TextStyle(fontSize: 16, color: Colors.black87),
                  ),
                );
              }

              double totalAmount =
                  expenses.fold(0, (sum, item) => sum + item.amount);

              return Column(
                children: [
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0),
                      itemCount: expenses.length,
                      itemBuilder: (context, index) {
                        final expense = expenses[index];
                        final expenseNumber = index + 1;

                        return AnimatedContainer(
                          duration: Duration(milliseconds: 400 + (index * 100)),
                          curve: Curves.easeInOut,
                          margin: EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                spreadRadius: 2,
                                blurRadius: 6,
                                offset: Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(16),
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            '$expenseNumber. ${expense.name}',
                                            style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 18,
                                                color: Colors.black87),
                                          ),
                                          SizedBox(height: 8),
                                          Text(
                                            '${DateFormat('MMM dd, yyyy').format(expense.dateTime)} at ${DateFormat('hh:mm a').format(expense.dateTime)}',
                                            style: const TextStyle(
                                                color: Colors.black54),
                                          ),
                                          Text(
                                            currencyFormat
                                                .format(expense.amount),
                                            style: TextStyle(
                                              color: Colors.yellow[700],
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Row(
                                      children: [
                                        IconButton(
                                          icon: const Icon(Icons.edit,
                                              color: Colors.blue),
                                          onPressed: () {
                                            showDialog(
                                              context: context,
                                              builder: (context) =>
                                                  EditExpenseDialog(
                                                      expense: expense),
                                            );
                                          },
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.delete,
                                              color: Colors.red),
                                          onPressed: () async {
                                            bool confirmDelete =
                                                await showDialog(
                                                      context: context,
                                                      builder: (context) =>
                                                          AlertDialog(
                                                        title: const Text(
                                                            'Delete Expense'),
                                                        content: const Text(
                                                          'Are you sure you want to delete this expense?',
                                                          style: TextStyle(
                                                              color: Colors
                                                                  .black), // Set text color to black
                                                        ),
                                                        actions: [
                                                          TextButton(
                                                            onPressed: () =>
                                                                Navigator.of(
                                                                        context)
                                                                    .pop(false),
                                                            child: const Text(
                                                                'Cancel'),
                                                          ),
                                                          TextButton(
                                                            onPressed: () =>
                                                                Navigator.of(
                                                                        context)
                                                                    .pop(true),
                                                            child: const Text(
                                                                'Delete'),
                                                          ),
                                                        ],
                                                      ),
                                                    ) ??
                                                    false;

                                            if (confirmDelete) {
                                              try {
                                                await ref
                                                    .read(
                                                        expenseServiceProvider)
                                                    .deleteExpense(expense.id);
                                                ScaffoldMessenger.of(context)
                                                    .showSnackBar(
                                                  const SnackBar(
                                                      content: Text(
                                                          'Expense deleted'),
                                                      backgroundColor:
                                                          Colors.green,
                                                      behavior: SnackBarBehavior
                                                          .floating),
                                                );
                                              } catch (e) {
                                                print(
                                                    'Error deleting expense: $e');
                                                ScaffoldMessenger.of(context)
                                                    .showSnackBar(
                                                  const SnackBar(
                                                      content: Text(
                                                          'Failed to delete expense'),
                                                      backgroundColor:
                                                          Colors.green,
                                                      behavior: SnackBarBehavior
                                                          .floating),
                                                );
                                              }
                                            }
                                          },
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(20),
                    color: Colors.grey[200],
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Number of Expenses:',
                              style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87),
                            ),
                            Text(
                              '${expenses.length}',
                              style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Total Amount:',
                              style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87),
                            ),
                            Text(
                              currencyFormat.format(totalAmount),
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.yellow[700],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
            loading: () => const Center(
                child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.yellow))),
            error: (error, _) {
              debugPrint("ExpenseListScreen: Error loading expenses: $error");
              return Center(
                child: Text(
                  'Failed to load expenses: $error',
                  style: const TextStyle(color: Colors.red),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
