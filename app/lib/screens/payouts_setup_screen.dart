import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../services/payments_service.dart';
import '../theme.dart';

/// Stripe hosts the whole onboarding form (identity, bank details) — this
/// screen only kicks the seller out to it and explains what's happening.
///
/// TODO: the return/refresh URLs below are placeholders. Point them at a
/// real page you control (even a one-line "You're set up — reopen S8LL")
/// once you have a domain, or wire up Android App Links so Stripe can hand
/// the seller straight back into the app instead of a browser tab.
class PayoutsSetupScreen extends StatefulWidget {
  const PayoutsSetupScreen({super.key, required this.paymentsService});

  final PaymentsService paymentsService;

  @override
  State<PayoutsSetupScreen> createState() => _PayoutsSetupScreenState();
}

class _PayoutsSetupScreenState extends State<PayoutsSetupScreen> {
  bool _loading = false;
  String? _error;

  Future<void> _startOnboarding() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final url = await widget.paymentsService.createPayoutOnboardingLink(
        returnUrl: 'https://s8ll.app/onboarding/return',
        refreshUrl: 'https://s8ll.app/onboarding/refresh',
      );
      final launched =
          await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
      if (!launched && mounted) {
        setState(() => _error = "Couldn't open the payout setup page.");
      }
    } catch (e) {
      if (mounted) setState(() => _error = 'Something went wrong: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Get paid')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.account_balance_outlined, size: 40, color: S8llColors.lime),
            const SizedBox(height: 16),
            const Text(
              'Set up payouts with Stripe',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 10),
            Text(
              "You'll need this before buyers can pay for a \"Ship it\" listing "
              'in the app. Stripe handles your bank details and identity check '
              "directly — S8LL never sees them. Takes a few minutes.",
              style: TextStyle(color: context.s8ll.textSecondary),
            ),
            if (_error != null) ...[
              const SizedBox(height: 16),
              Text(_error!, style: const TextStyle(color: Colors.redAccent)),
            ],
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loading ? null : _startOnboarding,
              child: Text(_loading ? 'Opening…' : 'Continue to Stripe'),
            ),
          ],
        ),
      ),
    );
  }
}
