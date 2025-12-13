import 'package:flutter/material.dart';

class WardenScreen extends StatelessWidget {
  const WardenScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Warden Dashboard'),
      ),
      body: const Center(
        child: Text('Warden screen'),
      ),
    );
  }
}
