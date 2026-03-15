import 'package:flutter/material.dart';

import '../constants/arcadia_color.dart';
import '../constants/config.dart';
import '../providers/viewport_notifier_provider.dart';

const _viewportOverlayOffset = 12.0;
const _cursorSize = 40.0;
const _cursorHalfSize = _cursorSize / 2;

/// The viewport overlay for status labels and tool helpers.
class ViewportOverlay extends StatelessWidget {
  /// The default [ViewportOverlay] constructor.
  const ViewportOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    return const Stack(
      children: [
        _ViewportTopLeftLabels(),
        _ViewportZoomLabel(),
        _ViewportCursorPositionLabel(),
        _ViewportCursorInputLabel(),
      ],
    );
  }
}

class _ViewportZoomLabel extends StatelessWidget {
  const _ViewportZoomLabel();

  @override
  Widget build(BuildContext context) {
    final zoom = context.selectViewportState((state) {
      final zoom = state.zoom;
      final zoomText = (zoom * 100).toStringAsFixed(1);
      final formattedZoom = zoomText.endsWith('.0')
          ? zoomText.substring(0, zoomText.length - 2)
          : zoomText;

      return '$formattedZoom%';
    });

    return Positioned(
      left: _viewportOverlayOffset,
      bottom: _viewportOverlayOffset,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: context.viewportNotifier.resetZoomToDefault,
          child: _OverlayChip(text: zoom),
        ),
      ),
    );
  }
}

class _ViewportTopLeftLabels extends StatelessWidget {
  const _ViewportTopLeftLabels();

  @override
  Widget build(BuildContext context) {
    final overlayLabel = context.selectViewportState(
      (state) => state.overlayLabel,
    );

    if (overlayLabel == null) {
      return const SizedBox.shrink();
    }

    return Positioned(
      left: _viewportOverlayOffset,
      top: _viewportOverlayOffset,
      child: _OverlayChip(text: overlayLabel),
    );
  }
}

class _ViewportCursorInputLabel extends StatelessWidget {
  const _ViewportCursorInputLabel();

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final userInput = context.selectViewportState(
            (state) => state.userInput,
          );

          if (userInput == '') {
            return const SizedBox.shrink();
          }

          final viewportPosition = context.selectViewportState(
            (state) {
              final cursorPosition =
                  state.cursorPosition * unitVirtualPixelRatio;
              final viewportMidpoint = Offset(
                constraints.maxWidth / 2,
                constraints.maxHeight / 2,
              );
              final viewportOffset = viewportMidpoint + state.panOffset;

              return (cursorPosition * state.zoom) +
                  viewportOffset +
                  const Offset(
                    _cursorHalfSize + 4,
                    -_cursorHalfSize,
                  );
            },
          );

          return Stack(
            children: [
              Positioned(
                top: viewportPosition.dy,
                left: viewportPosition.dx,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(minHeight: _cursorSize),
                  child: Center(
                    child: _OverlayChip(text: userInput),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ViewportCursorPositionLabel extends StatelessWidget {
  const _ViewportCursorPositionLabel();

  @override
  Widget build(BuildContext context) {
    final label = context.selectViewportState((state) {
      final x = state.cursorPosition.dx.toStringAsFixed(1);
      final y = state.cursorPosition.dy.toStringAsFixed(1);

      return 'X: $x, Y: $y';
    });

    return Positioned(
      right: _viewportOverlayOffset,
      bottom: _viewportOverlayOffset,
      child: _OverlayChip(text: label),
    );
  }
}

class _OverlayChip extends StatelessWidget {
  const _OverlayChip({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: ShapeDecoration(
        color: ArcadiaColor.background,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
          side: const BorderSide(color: ArcadiaColor.border),
        ),
      ),
      child: Text(text),
    );
  }
}
