import 'package:flutter/material.dart';

class AppConstants {
  AppConstants._();

  static const double animationDuration = 300;
  static const double fadeDuration = 200;
  static const double slideDuration = 250;
  static const double scaleDuration = 150;

  static const Curve animationCurve = Curves.easeInOut;
  static const Curve fadeCurve = Curves.ease;
  static const Curve slideCurve = Curves.easeOut;
  static const Curve scaleCurve = Curves.easeOutBack;
}
