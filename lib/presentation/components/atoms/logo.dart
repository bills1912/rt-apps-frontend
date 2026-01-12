import 'package:flutter/material.dart';

import 'dart:math' as math;

import 'package:rt_app_apk/core/theme/text_styleS.dart';

class Logo extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Transform.rotate(
          angle: -math.pi / 6,
          child: Image.asset(
            'assets/img/logo.png',
            width: 60,
          ),
        ),
        Text('WARGA-PAY', style: TextStyles.h1),
      ],
    );
  }
}
