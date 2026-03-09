import 'package:flutter/material.dart';
import 'package:local_vault/core/constants/app_theme.dart';

class AppErrorHandler {
  AppErrorHandler._();

  static String handleError(dynamic error) {
    if (error is Exception) {
      return error.toString();
    }
    return '未知错误';
  }

  static void showError(BuildContext context, dynamic error) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(handleError(error)),
        backgroundColor: AppColors.error,
      ),
    );
  }
}
