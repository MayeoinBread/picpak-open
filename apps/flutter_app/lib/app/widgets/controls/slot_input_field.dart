import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class SlotInputField extends StatefulWidget {
  final int? value;
  final ValueChanged<int?> onChanged;

  const SlotInputField({
    super.key,
    required this.value,
    required this.onChanged
  });

  @override
  State<SlotInputField> createState() => _SlotInputFieldState();
}

class _SlotInputFieldState extends State<SlotInputField> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();

    _controller = TextEditingController(
      text: widget.value?.toString() ?? ''
    );
  }

  @override
  void didUpdateWidget(covariant SlotInputField oldWidget) {
    super.didUpdateWidget(oldWidget);

    final newText = widget.value?.toString() ?? '';

    if (_controller.text != newText) {
      _controller.text = newText;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,

      decoration: const InputDecoration(
        labelText: 'Slot Number',
        border: OutlineInputBorder()
      ),

      keyboardType: TextInputType.number,

      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly
      ],

      onChanged: (value) {
        if (value.isEmpty) {
          widget.onChanged(null);
          return;
        }

        widget.onChanged(int.tryParse(value));
      }
    );
  }
}