# Stripe's optional "push provisioning" module (adding cards to Google Pay
# from within the app) is a compileOnly dependency inside stripe_android —
# we never declare it ourselves and don't use the feature, so these classes
# are never present at runtime. Without this, R8 fails the release build
# over "missing classes" it can't resolve.
-dontwarn com.stripe.android.pushProvisioning.**
-dontwarn com.reactnativestripesdk.pushprovisioning.**
