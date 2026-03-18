import 'package:flutter/material.dart';

class AppNavigation {
  AppNavigation._();

  static Future<void> push(BuildContext context, String routeName, {dynamic arguments}) async {
    await Navigator.pushNamed(context, routeName, arguments: arguments);
  }

  static Future<void> pushReplacement(BuildContext context, String routeName, {dynamic arguments}) async {
    await Navigator.pushReplacementNamed(context, routeName, arguments: arguments);
  }

  static void pop(BuildContext context) {
    Navigator.pop(context);
  }

  static void popUntil(BuildContext context, String routeName) {
    Navigator.popUntil(context, ModalRoute.withName(routeName));
  }
}
