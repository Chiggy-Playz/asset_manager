import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

import '../../../../core/utils/platform_utils.dart';
import '../../../../core/utils/responsive.dart';
import '../widgets/magic_link_form.dart';
import '../widgets/otp_form.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ResponsiveBuilder(
              builder: (context, screenSize) {
                final maxWidth = switch (screenSize) {
                  ScreenSize.mobile => double.infinity,
                  ScreenSize.tablet => 400.0,
                  ScreenSize.desktop => 400.0,
                };

                return ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: maxWidth),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Welcome',
                        style: Theme.of(context).textTheme.headlineLarge,
                        textAlign: TextAlign.center,
                      ),
                      const Gap(8),
                      Text(
                        'Sign in to continue',
                        style: Theme.of(context).textTheme.bodyLarge,
                        textAlign: TextAlign.center,
                      ),
                      const Gap(32),
                      // Platform-adaptive login form
                      if (PlatformUtils.isDesktop)
                        const OtpForm()
                      else
                        const MagicLinkForm(),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
