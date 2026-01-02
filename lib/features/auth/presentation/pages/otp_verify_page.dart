import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';

import '../../../../core/utils/responsive.dart';
import '../../bloc/auth_bloc.dart';
import '../../bloc/auth_event.dart';
import '../../bloc/auth_state.dart';

class OtpVerifyPage extends StatefulWidget {
  const OtpVerifyPage({super.key});

  @override
  State<OtpVerifyPage> createState() => _OtpVerifyPageState();
}

class _OtpVerifyPageState extends State<OtpVerifyPage> {
  final _formKey = GlobalKey<FormState>();
  final _otpController = TextEditingController();

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }

  void _onVerify(String email) {
    if (_formKey.currentState!.validate()) {
      context.read<AuthBloc>().add(
            VerifyOtpRequested(
              email: email,
              token: _otpController.text.trim(),
            ),
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: BackButton(
          onPressed: () {
            context.read<AuthBloc>().add(AuthCheckRequested());
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
                      child: Form(
                        key: _formKey,
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
                            TextFormField(
                              controller: _otpController,
                              keyboardType: TextInputType.number,
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.headlineMedium,
                              decoration: const InputDecoration(
                                hintText: '000000',
                                border: OutlineInputBorder(),
                              ),
                              maxLength: 6,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter the code';
                                }
                                if (value.length != 6) {
                                  return 'Code must be 6 digits';
                                }
                                return null;
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
                          ],
                        ),
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
