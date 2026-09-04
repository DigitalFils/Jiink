enum AccountType {
  asset('Asset'),
  liability('Liability'),
  equity('Equity'),
  revenue('Revenue'),
  expense('Expense');

  const AccountType(this.label);

  final String label;
}

class Account {
  const Account({required this.id, required this.name, required this.type});

  final String id;
  final String name;
  final AccountType type;
}

class Entry {
  const Entry({
    required this.id,
    required this.date,
    required this.description,
    required this.accountId,
    required this.amount,
  });

  final String id;
  final DateTime date;
  final String description;
  final String accountId;
  final double amount;
}

const List<Account> initialAccounts = [
  Account(id: 'cash', name: 'Cash', type: AccountType.asset),
  Account(id: 'bank', name: 'Bank', type: AccountType.asset),
  Account(id: 'sales', name: 'Sales Revenue', type: AccountType.revenue),
  Account(id: 'expenses', name: 'Operating Expense', type: AccountType.expense),
  Account(id: 'equity', name: 'Owner Equity', type: AccountType.equity),
];
