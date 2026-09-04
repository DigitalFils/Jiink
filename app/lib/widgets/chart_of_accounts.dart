import 'package:flutter/material.dart';

import '../models.dart';

class ChartOfAccounts extends StatelessWidget {
  const ChartOfAccounts({super.key, required this.accounts});

  final List<Account> accounts;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Chart of Accounts', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            DataTable(
              columns: const [
                DataColumn(label: Text('Name')),
                DataColumn(label: Text('Type')),
              ],
              rows: [
                for (final account in accounts)
                  DataRow(cells: [
                    DataCell(Text(account.name)),
                    DataCell(Text(account.type.label)),
                  ]),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
