import 'package:flutter/material.dart';

class EditFieldDialog extends StatelessWidget {
  final String field;
  final String currentValue;
  final Function(String) onSave;

  const EditFieldDialog({
    super.key,
    required this.field,
    required this.currentValue,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    TextEditingController controller =
        TextEditingController(text: currentValue);

    return AlertDialog(
      title: Text('Edit $field'),
      content: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: 'Enter new $field',
          border: const OutlineInputBorder(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            onSave(controller.text);
            Navigator.pop(context);
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}
