package com.digitalfils.s8ll

import io.flutter.embedding.android.FlutterFragmentActivity

// flutter_stripe requires this instead of plain FlutterActivity — its
// PaymentSheet/3DS UI needs fragment support to launch.
class MainActivity: FlutterFragmentActivity()
