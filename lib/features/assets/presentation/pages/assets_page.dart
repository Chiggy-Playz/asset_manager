import 'package:flutter/material.dart';

import '../../../../core/utils/responsive.dart';

class AssetsPage extends StatelessWidget {
  const AssetsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Assets')),
      body: ResponsiveBuilder(
        builder: (context, screenSize) {
          final content = const Center(
            child: Text('Assets - Coming Soon'),
          );

          if (screenSize == ScreenSize.mobile) {
            return content;
          }

          return Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 800),
              child: content,
            ),
          );
        },
      ),
    );
  }
}
