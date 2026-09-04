import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_stripe/flutter_stripe.dart';

class PayoutsNotReadyException implements Exception {
  const PayoutsNotReadyException(this.message);
  final String message;
}

class PaymentsService {
  PaymentsService({FirebaseFunctions? functions})
      : _functions = functions ?? FirebaseFunctions.instance;

  final FirebaseFunctions _functions;

  /// Starts (or resumes) Stripe Connect onboarding for the current seller
  /// and returns the hosted onboarding URL to open in a browser.
  Future<String> createPayoutOnboardingLink({
    required String returnUrl,
    required String refreshUrl,
  }) async {
    final callable = _functions.httpsCallable('createPayoutOnboardingLink');
    final result = await callable.call<Map<String, dynamic>>({
      'returnUrl': returnUrl,
      'refreshUrl': refreshUrl,
    });
    return result.data['url'] as String;
  }

  /// Creates the PaymentIntent for a listing, then presents Stripe's
  /// PaymentSheet so the buyer enters card details directly with Stripe —
  /// they never pass through our app or backend.
  Future<void> buyListing({required String listingId}) async {
    final callable = _functions.httpsCallable('createListingPaymentIntent');
    final Map<String, dynamic> result;
    try {
      final response =
          await callable.call<Map<String, dynamic>>({'listingId': listingId});
      result = response.data;
    } on FirebaseFunctionsException catch (e) {
      if (e.code == 'failed-precondition') {
        throw PayoutsNotReadyException(
          e.message ?? 'This listing cannot be bought right now.',
        );
      }
      rethrow;
    }

    await Stripe.instance.initPaymentSheet(
      paymentSheetParameters: SetupPaymentSheetParameters(
        paymentIntentClientSecret: result['clientSecret'] as String,
        merchantDisplayName: 'S8LL',
      ),
    );
    await Stripe.instance.presentPaymentSheet();
  }
}
