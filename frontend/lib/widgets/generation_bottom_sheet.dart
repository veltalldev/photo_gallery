// lib/widgets/generation_bottom_sheet.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class GenerationBottomSheet extends StatefulWidget {
  final Function(String additionalPrompt, int count, int? seed) onSubmit;
  final bool isGenerating;

  const GenerationBottomSheet({
    super.key,
    required this.onSubmit,
    this.isGenerating = false,
  });

  @override
  State<GenerationBottomSheet> createState() => _GenerationBottomSheetState();
}

class _GenerationBottomSheetState extends State<GenerationBottomSheet> {
  final TextEditingController _promptController = TextEditingController();
  final TextEditingController _seedController = TextEditingController();
  int _imageCount = 1;
  bool _useRandomSeed = true;

  @override
  void dispose() {
    _promptController.dispose();
    _seedController.dispose();
    super.dispose();
  }

  void _handleSubmit() {
    final prompt = _promptController.text.trim();
    final seed = _useRandomSeed ? null : int.tryParse(_seedController.text);
    widget.onSubmit(prompt, _imageCount, seed);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Generate Similar Images',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Additional Prompt Input
            TextField(
              controller: _promptController,
              decoration: InputDecoration(
                labelText: 'Additional Prompt (Optional)',
                hintText: 'Add details to modify the generation...',
                hintStyle: TextStyle(color: Colors.grey.withOpacity(0.3)),
                border: const OutlineInputBorder(),
              ),
              maxLines: 2,
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 16),

            // Image Count Selector
            Row(
              children: [
                const Text('Number of Images:'),
                const SizedBox(width: 16),
                Expanded(
                  child: Slider(
                    value: _imageCount.toDouble(),
                    min: 1,
                    max: 10,
                    divisions: 9,
                    label: _imageCount.toString(),
                    onChanged: (value) {
                      setState(() {
                        _imageCount = value.round();
                      });
                    },
                  ),
                ),
                SizedBox(
                  width: 40,
                  child: Text(
                    _imageCount.toString(),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Seed Controls
            SizedBox(
              height: 60,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Seed Input Field
                  Expanded(
                    child: TextField(
                      controller: _seedController,
                      decoration: const InputDecoration(
                        labelText: 'Seed Value',
                        border: OutlineInputBorder(),
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                      ],
                      enabled: !_useRandomSeed,
                    ),
                  ),
                  // Random Toggle
                  Padding(
                    padding: const EdgeInsets.only(left: 16),
                    child: Row(
                      children: [
                        Text(
                          'Random',
                          style: TextStyle(
                            fontSize: 12,
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                        Switch(
                          value: _useRandomSeed,
                          onChanged: (value) {
                            setState(() {
                              _useRandomSeed = value;
                              if (value) {
                                _seedController.clear();
                              }
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Generate Button
            FilledButton.icon(
              onPressed: widget.isGenerating ? null : _handleSubmit,
              icon: widget.isGenerating
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.auto_awesome),
              label: Text(
                widget.isGenerating ? 'Generating...' : 'Generate',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Usage example:
void showGenerationOptions(
  BuildContext context, {
  required Function(String, int, int?) onSubmit,
  bool isGenerating = false,
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Theme.of(context).colorScheme.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) => GenerationBottomSheet(
      onSubmit: onSubmit,
      isGenerating: isGenerating,
    ),
  );
}
