import 'package:flutter/material.dart';

import '../models.dart';

class BalanceSheet extends StatelessWidget {
  const BalanceSheet({super.key, required this.accounts, required this.entries});

  final List<Account> accounts;
  final List<Entry> entries;

  @override
  Widget build(BuildContext context) {
    final totals = {for (final type in AccountType.values) type: 0.0};
    for (final entry in entries) {
      Account? account;
      for (final candidate in accounts) {
        if (candidate.id == entry.accountId) {
          account = candidate;
          break;
        }
      }
      if (account != null) {
        totals[account.type] = totals[account.type]! + entry.amount;
      }
    }
    // Simplistic profit computation: Revenue + Expense (Expense should be
    // negative for outflows).
    final equityWithProfit =
        totals[AccountType.equity]! + (totals[AccountType.revenue]! + totals[AccountType.expense]!);

    return Card(
      margin: const EdgeInsets.all(12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Balance Sheet (simplified)', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            _BalanceRow(label: 'Assets', value: totals[AccountType.asset]!),
            _BalanceRow(label: 'Liabilities', value: totals[AccountType.liability]!),
            _BalanceRow(label: 'Equity', value: equityWithProfit),
          ],
        ),
      ),
    );
  }
}

class _BalanceRow extends StatelessWidget {
  const _BalanceRow({required this.label, required this.value});

  final String label;
  final double value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(value.toStringAsFixed(2)),
        ],
      ),
    );
  }
}
