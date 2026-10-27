import 'package:flutter/material.dart';

/// "< Back" do protótipo. Mantém o texto em inglês como no Figma.
class BackLabelButton extends StatelessWidget {
  const BackLabelButton({super.key, this.label = 'Back'});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: TextButton.icon(
        onPressed: () => Navigator.of(context).maybePop(),
        icon: const Icon(Icons.chevron_left, size: 24),
        label: Text(label),
        style: TextButton.styleFrom(
          foregroundColor: Colors.black,
          padding: const EdgeInsets.only(left: 4, right: 12),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
      ),
    );
  }
}
