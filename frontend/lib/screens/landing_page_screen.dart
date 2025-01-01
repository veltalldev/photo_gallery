// lib/screens/landing_page_screen.dart
import 'package:flutter/material.dart';

import 'package:photo_gallery/screens/gallery_screen.dart';
import 'package:photo_gallery/widgets/common/gradient_scaffold.dart';

class LandingPageScreen extends StatelessWidget {
  const LandingPageScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const _LandingPageContent();
  }
}

class _LandingPageContent extends StatefulWidget {
  const _LandingPageContent();

  @override
  State<_LandingPageContent> createState() => _LandingPageContentState();
}

class _LandingPageContentState extends State<_LandingPageContent> {
  bool obscurePassword = true;

  @override
  void initState() {
    super.initState();
  }

  void _handleLogin() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const GalleryScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GradientScaffold(
      child: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo/Icon
                  Icon(
                    Icons.photo_library_rounded,
                    size: 64,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(height: 24),
                  // Title
                  Text(
                    'Photo Gallery',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 48),
                  // Email field
                  TextField(
                    decoration: InputDecoration(
                      labelText: 'Email',
                      hintText: 'Enter your email',
                      prefixIcon: const Icon(Icons.email_outlined),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Theme.of(context)
                          .colorScheme
                          .surface
                          .withOpacity(0.8),
                    ),
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: 16),

                  // Password field
                  TextField(
                    decoration: InputDecoration(
                      labelText: 'Password',
                      hintText: 'Enter your password',
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(
                          obscurePassword
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                        ),
                        onPressed: () {
                          setState(() {
                            obscurePassword = !obscurePassword;
                          });
                        },
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Theme.of(context)
                          .colorScheme
                          .surface
                          .withOpacity(0.8),
                    ),
                    obscureText: obscurePassword,
                    textInputAction: TextInputAction.done,
                  ),
                  const SizedBox(height: 8),

                  // Forgot password link
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () {
                        // TODO: Implement forgot password
                      },
                      child: Text(
                        'Forgot Password?',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  // Login Button
                  FilledButton.icon(
                    onPressed: _handleLogin,
                    icon: const Icon(Icons.login),
                    label: const Text('Login'),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 48,
                        vertical: 16,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
