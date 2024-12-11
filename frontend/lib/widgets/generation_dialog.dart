// lib/widgets/generation_dialog.dart

import 'package:flutter/material.dart';

class GenerationDialog extends StatefulWidget {
  final Function(String additionalPrompt, int count, int? seed) onSubmit;

  const GenerationDialog({
    Key? key,
    required this.onSubmit,
  }) : super(key: key);

  @override
  _GenerationDialogState createState() => _GenerationDialogState();
}

class _GenerationDialogState extends State<GenerationDialog> {
  final _promptController = TextEditingController();
  int _count = 1;
  bool _useRandomSeed = true;
  final _seedController = TextEditingController();

  @override
  void dispose() {
    _promptController.dispose();
    _seedController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Generate Similar Images'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _promptController,
              decoration: const InputDecoration(
                labelText: 'Additional Prompt (Optional)',
                hintText: 'Add more details to guide the generation',
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Text('Number of Images: '),
                Expanded(
                  child: Slider(
                    value: _count.toDouble(),
                    min: 1,
                    max: 10,
                    divisions: 9,
                    label: _count.toString(),
                    onChanged: (value) {
                      setState(() {
                        _count = value.round();
                      });
                    },
                  ),
                ),
                Text(_count.toString()),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Text('Seed: '),
                Switch(
                  value: _useRandomSeed,
                  onChanged: (value) {
                    setState(() {
                      _useRandomSeed = value;
                    });
                  },
                ),
                const Text('Random'),
              ],
            ),
            if (!_useRandomSeed)
              TextField(
                controller: _seedController,
                decoration: const InputDecoration(
                  labelText: 'Seed Value',
                ),
                keyboardType: TextInputType.number,
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            final seed =
                _useRandomSeed ? null : int.tryParse(_seedController.text);
            widget.onSubmit(_promptController.text, _count, seed);
            Navigator.of(context).pop();
          },
          child: const Text('Generate'),
        ),
      ],
    );
  }
}
