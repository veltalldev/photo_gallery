// lib/screens/landing_page_screen.dart
import 'package:flutter/material.dart';

import 'package:photo_gallery/screens/gallery_screen.dart';
import 'package:photo_gallery/widgets/common/gradient_scaffold.dart';
import 'package:photo_gallery/widgets/decorative/wave_painter.dart';

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
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.width < 480; // Increased from 380 to 480

    return GradientScaffold(
      appBar: null,
      child: Stack(
        children: [
          // Top decorative wave
          Positioned(
            top: -MediaQuery.of(context).padding.top,
            left: 0,
            right: 0,
            child: CustomPaint(
              size: Size(
                double.infinity,
                150 + MediaQuery.of(context).padding.top,
              ),
              painter: WavePainter(
                color: Theme.of(context)
                    .colorScheme
                    .primaryContainer
                    .withOpacity(0.5),
              ),
            ),
          ),
          Center(
            child: SingleChildScrollView(
              child: Container(
                constraints: BoxConstraints(
                  maxWidth: isSmallScreen ? screenSize.width * 0.95 : 480,
                ),
                padding: EdgeInsets.symmetric(
                  horizontal: isSmallScreen ? 16.0 : 24.0,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Logo/Icon with responsive size
                    Icon(
                      Icons.photo_library_rounded,
                      size: isSmallScreen ? 48 : 64,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    SizedBox(height: isSmallScreen ? 16 : 24),

                    // Title with responsive text size
                    Text(
                      'Photo Gallery',
                      style:
                          Theme.of(context).textTheme.headlineMedium?.copyWith(
                                color: Theme.of(context).colorScheme.onSurface,
                                fontWeight: FontWeight.bold,
                                fontSize: isSmallScreen ? 24 : 32,
                              ),
                    ),
                    SizedBox(height: isSmallScreen ? 32 : 48),

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
                    const SizedBox(height: 48),
                    // Social login options
                    Text(
                      'Or continue with',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                    const SizedBox(height: 16),
                    // Social buttons in wrap for small screens
                    if (isSmallScreen)
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        alignment: WrapAlignment.center,
                        children: [
                          _buildSocialButton(
                            context,
                            icon: Icons.g_mobiledata_rounded,
                            label: 'Google',
                          ),
                          _buildSocialButton(
                            context,
                            icon: Icons.apple_rounded,
                            label: 'Apple',
                          ),
                          _buildSocialButton(
                            context,
                            icon: Icons.facebook_rounded,
                            label: 'Facebook',
                          ),
                          _buildSocialButton(
                            context,
                            icon: Icons.cloud_outlined,
                            label: 'Bluesky',
                          ),
                        ],
                      )
                    else
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildSocialButton(
                            context,
                            icon: Icons.g_mobiledata_rounded,
                            label: 'Google',
                          ),
                          _buildSocialButton(
                            context,
                            icon: Icons.apple_rounded,
                            label: 'Apple',
                          ),
                          _buildSocialButton(
                            context,
                            icon: Icons.facebook_rounded,
                            label: 'Facebook',
                          ),
                          _buildSocialButton(
                            context,
                            icon: Icons.cloud_outlined,
                            label: 'Bluesky',
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
          ),
          // Bottom decorative elements
          Positioned(
            bottom: 16,
            left: 0,
            right: 0,
            child: Column(
              children: [
                Text(
                  '© 2025 Photo Gallery',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    TextButton(
                      onPressed: () {},
                      child: const Text('Privacy Policy'),
                    ),
                    const Text('•'),
                    TextButton(
                      onPressed: () {},
                      child: const Text('Terms of Service'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSocialButton(
    BuildContext context, {
    required IconData icon,
    required String label,
  }) {
    final isSmallScreen = MediaQuery.of(context).size.width < 480;

    if (isSmallScreen) {
      // Icon-only button for small screens
      return Tooltip(
        message: label, // Shows label on long press
        child: SizedBox(
          width: 66, // Fixed size for icon buttons
          height: 44,
          child: OutlinedButton(
            onPressed: () {},
            style: OutlinedButton.styleFrom(
              padding: EdgeInsets.zero,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Icon(icon, size: 20),
          ),
        ),
      );
    }

    // Icon + label button for larger screens
    return SizedBox(
      width: 100,
      child: OutlinedButton.icon(
        onPressed: () {},
        icon: Icon(icon, size: 20),
        label: Text(
          label,
          style: const TextStyle(fontSize: 13),
          overflow: TextOverflow.ellipsis,
        ),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}
