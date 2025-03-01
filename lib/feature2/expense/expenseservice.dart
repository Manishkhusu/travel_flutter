import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_xploverse/feature2/expense/tripexpensemodel.dart';

final expenseServiceProvider =
    Provider<ExpenseService>((ref) => ExpenseService());

class ExpenseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> addExpense(Expense expense) async {
    try {
      await _firestore.collection('expenses').add({
        'name': expense.name,
        'amount': expense.amount,
        'dateTime': expense.dateTime,
        'userId': expense.userId,
      });
    } catch (error) {
      print('Error adding expense to Firestore: $error');
      rethrow;
    }
  }

  Stream<List<Expense>> getExpensesForUser(String userId) {
    return _firestore
        .collection('expenses')
        .where('userId', isEqualTo: userId)
        .orderBy('dateTime', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return Expense(
          id: doc.id,
          name: doc['name'],
          amount: doc['amount'].toDouble(),
          dateTime: (doc['dateTime'] as Timestamp).toDate(),
          userId: doc['userId'],
        );
      }).toList();
    });
  }

  Future<void> updateExpense(Expense expense) async {
    try {
      await _firestore.collection('expenses').doc(expense.id).update({
        'name': expense.name,
        'amount': expense.amount,
        'dateTime': expense.dateTime,
        'userId': expense.userId,
      });
    } catch (e) {
      print('Error updating expense: $e');
      rethrow;
    }
  }

  Future<void> deleteExpense(String expenseId) async {
    try {
      await _firestore.collection('expenses').doc(expenseId).delete();
    } catch (error) {
      print('Error deleting expense: $error');
      rethrow;
    }
  }
}
