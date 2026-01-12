import 'package:flutter/material.dart';
import 'package:rt_app_apk/core/theme/color_list.dart';

class TextStyles {
  static TextStyle h1 = TextStyle(
    color: ColorList.primary,
    fontWeight: FontWeight.bold,
    fontSize: 24,
  );
  static TextStyle h2 = TextStyle(
    color: ColorList.primary,
    fontWeight: FontWeight.bold,
    fontSize: 20,
  );

  static TextStyle h3 = TextStyle(
    color: ColorList.primary,
    fontWeight: FontWeight.bold,
    fontSize: 16,
  );

  static TextStyle p = TextStyle(
    color: ColorList.primary,
    fontWeight: FontWeight.normal,
    fontSize: 12,
  );

  static TextStyle chip = TextStyle(
    color: Colors.white,
    fontWeight: FontWeight.normal,
    fontSize: 8,
  );

  static TextStyle link = TextStyle(
    color: ColorList.primary,
    fontWeight: FontWeight.bold,
    fontSize: 12,
    decoration: TextDecoration.underline,
  );
}
