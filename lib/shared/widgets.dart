import 'package:flutter/material.dart';

class SpacedRow extends StatelessWidget {
  final Widget widget1;
  final Widget widget2;

  const SpacedRow({super.key, required this.widget1, required this.widget2});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        widget1,
        const Spacer(),
        widget2,
      ],
    );
  }
}
