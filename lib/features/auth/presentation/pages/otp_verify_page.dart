import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';

import '../../../../core/utils/responsive.dart';
import '../../bloc/auth_bloc.dart';
import '../../bloc/auth_event.dart';
import '../../bloc/auth_state.dart';
import '../widgets/otp_input_field.dart';

class OtpVerifyPage extends StatefulWidget {
  const OtpVerifyPage({super.key});

  @override
  State<OtpVerifyPage> createState() => _OtpVerifyPageState();
}

class _OtpVerifyPageState extends State<OtpVerifyPage> {
  final _otpController = TextEditingController();

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }

  void _onVerify(String email) {
    final otp = _otpController.text.trim();
    if (otp.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a 6-digit code')),
      );
      return;
    }
    context.read<AuthBloc>().add(
          VerifyOtpRequested(
            email: email,
            token: otp,
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: BackButton(
          onPressed: () {
            context.read<AuthBloc>().add(CancelOtpRequested());
          },
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: BlocConsumer<AuthBloc, AuthState>(
              listener: (context, state) {
                if (state is AuthError) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(state.message)),
                  );
                }
              },
              builder: (context, state) {
                final email =
                    state is AuthOtpSent ? state.email : 'your email';
                final isLoading = state is AuthLoading;

                return ResponsiveBuilder(
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
                            'Enter Code',
                            style: Theme.of(context).textTheme.headlineLarge,
                            textAlign: TextAlign.center,
                          ),
                          const Gap(8),
                          Text(
                            'We sent a code to $email',
                            style: Theme.of(context).textTheme.bodyLarge,
                            textAlign: TextAlign.center,
                          ),
                          const Gap(32),
                          OtpInputField(
                            controller: _otpController,
                            onCompleted: (_) {
                              if (!isLoading) {
                                _onVerify(
                                  state is AuthOtpSent ? state.email : '',
                                );
                              }
                            },
                          ),
                          const Gap(16),
                          FilledButton(
                            onPressed: isLoading
                                ? null
                                : () => _onVerify(
                                      state is AuthOtpSent
                                          ? state.email
                                          : '',
                                    ),
                            child: isLoading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2),
                                  )
                                : const Text('Verify'),
                          ),
                          const Gap(24),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                "Didn't receive the code? ",
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                              TextButton(
                                onPressed: isLoading
                                    ? null
                                    : () {
                                        if (state is AuthOtpSent) {
                                          context.read<AuthBloc>().add(
                                                SendOtpRequested(state.email),
                                              );
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            const SnackBar(
                                              content:
                                                  Text('Code resent to your email'),
                                            ),
                                          );
                                        }
                                      },
                                child: const Text('Resend'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
