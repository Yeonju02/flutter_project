import 'package:flutter/material.dart';

class CustomNightAlertDialog extends StatelessWidget {
  final String title;
  final String description;

  const CustomNightAlertDialog({
    super.key,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Color(0xFF182333),
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.block, size: 50, color: Color(0xFFFFC83E)),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold,  color: Colors.white),
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: const TextStyle(fontSize: 14, color: Colors.white),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF5C5E7C),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('확인', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
