import 'package:flutter/material.dart';
import '../user_session.dart';
import '../profile_pages/subscriptions.dart';
import '../main.dart';

Future<void> openSubscriptionsPage(BuildContext context, {bool autoNavigateOnActivation = false}) async {
  await UserSession.instance.load();
  if (UserSession.instance.token == null) {
    // Not logged in, redirect to login
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => AuthPage()));
  } else {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SubscriptionsPage(autoNavigateOnActivation: autoNavigateOnActivation),
      ),
    );
  }
}
