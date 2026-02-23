import 'package:flutter/widgets.dart';

import '../constants/arcadia_color.dart';

/// A horizontal separator that fits the width.
class HorizontalSeparator extends StatelessWidget {
  /// The default constructor for [HorizontalSeparator].
  const HorizontalSeparator({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(height: 1, color: ArcadiaColor.separator);
  }
}
