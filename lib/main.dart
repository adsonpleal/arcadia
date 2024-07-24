import 'package:flutter/material.dart';

import 'src/providers/viewport_notifier_provider.dart';
import 'src/ui/project_page.dart';

void main() {
  runApp(const Arcadia());
}

/// The arcadia app root widget.
class Arcadia extends StatelessWidget {
  /// Default constructor for [Arcadia].
  const Arcadia({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: Scaffold(
        body: ViewportNotifierProvider(
          child: ProjectPage(),
        ),
      ),
    );
  }
}
