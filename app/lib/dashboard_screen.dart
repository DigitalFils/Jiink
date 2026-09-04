import 'package:flutter/material.dart';

import 'models.dart';
import 'widgets/balance_sheet.dart';
import 'widgets/chart_of_accounts.dart';
import 'widgets/entry_form.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final List<Entry> _entries = [];

  void _addEntry({
    required DateTime date,
    required String description,
    required String accountId,
    required double amount,
  }) {
    setState(() {
      _entries.add(Entry(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        date: date,
        description: description,
        accountId: accountId,
        amount: amount,
      ));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Accounting Dashboard')),
      body: ListView(
        children: [
          const ChartOfAccounts(accounts: initialAccounts),
          EntryForm(accounts: initialAccounts, onAdd: _addEntry),
          BalanceSheet(accounts: initialAccounts, entries: _entries),
        ],
      ),
    );
  }
}
