// lib/screens/landing_page_screen.dart
import 'package:flutter/material.dart';

import 'package:photo_gallery/screens/gallery_screen.dart';
import 'package:photo_gallery/widgets/common/gradient_scaffold.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  bool _useExternalIp = false;
  final _prefs = SharedPreferences.getInstance();

  @override
  void initState() {
    super.initState();
    _loadNetworkPreference();
  }

  Future<void> _loadNetworkPreference() async {
    final prefs = await _prefs;
    setState(() {
      _useExternalIp = prefs.getBool('use_external_ip') ?? false;
    });
  }

  Future<void> _saveNetworkPreference(bool value) async {
    final prefs = await _prefs;
    await prefs.setBool('use_external_ip', value);
    setState(() {
      _useExternalIp = value;
    });
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
    return Scaffold(
      body: GradientScaffold(
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
                      style:
                          Theme.of(context).textTheme.headlineMedium?.copyWith(
                                color: Theme.of(context).colorScheme.onSurface,
                                fontWeight: FontWeight.bold,
                              ),
                    ),
                    const SizedBox(height: 48),
                    // Network Toggle
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Connection Type',
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleMedium,
                                      ),
                                      Text(
                                        _useExternalIp
                                            ? 'External IP'
                                            : 'Local Network',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyMedium
                                            ?.copyWith(
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .secondary,
                                            ),
                                      ),
                                    ],
                                  ),
                                ),
                                Switch(
                                  value: _useExternalIp,
                                  onChanged: _saveNetworkPreference,
                                ),
                              ],
                            ),
                          ],
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
      ),
    );
  }
}
