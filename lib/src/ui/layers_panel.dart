import 'package:flutter/material.dart';

import '../constants/arcadia_color.dart';
import '../data/layer.dart';
import '../providers/viewport_notifier_provider.dart';

/// A panel that displays and manages drawing layers.
class LayersPanel extends StatefulWidget {
  /// The default constructor for [LayersPanel].
  const LayersPanel({super.key});

  @override
  State<LayersPanel> createState() => _LayersPanelState();
}

class _LayersPanelState extends State<LayersPanel> {
  double _panelWidth = 180;
  bool _collapsed = false;
  String? _editingLayerId;

  static const _minWidth = 120.0;
  static const _maxWidth = 400.0;
  static const _collapsedWidth = 32.0;

  @override
  Widget build(BuildContext context) {
    if (_collapsed) {
      return GestureDetector(
        onTap: () => setState(() => _collapsed = false),
        child: Container(
          width: _collapsedWidth,
          color: ArcadiaColor.surface,
          child: const Center(
            child: RotatedBox(
              quarterTurns: 3,
              child: Text(
                'LAYERS',
                style: TextStyle(fontSize: 10),
              ),
            ),
          ),
        ),
      );
    }

    final layers = context.selectViewportState(
      (state) => state.layers,
    );
    final activeLayerId = context.selectViewportState(
      (state) => state.activeLayerId,
    );

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        MouseRegion(
          cursor: SystemMouseCursors.resizeColumn,
          child: GestureDetector(
            onHorizontalDragUpdate: (details) {
              setState(() {
                _panelWidth = (_panelWidth - details.delta.dx)
                    .clamp(_minWidth, _maxWidth);
              });
            },
            child: Container(
              width: 1,
              color: ArcadiaColor.border,
            ),
          ),
        ),
        SizedBox(
          width: _panelWidth,
          child: ColoredBox(
            color: ArcadiaColor.surface,
            child: Column(
              children: [
                _Header(
                  onCollapse: () {
                    setState(() => _collapsed = true);
                  },
                  onAdd: () {
                    final notifier = context.viewportNotifier;
                    final index = notifier.value.layers.length;
                    notifier.addLayer('Layer $index');
                  },
                ),
                Container(
                  height: 1,
                  color: ArcadiaColor.border,
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: layers.length,
                    itemBuilder: (context, index) {
                      final layer = layers[index];
                      return _LayerRow(
                        layer: layer,
                        isActive: layer.id == activeLayerId,
                        isEditing:
                            _editingLayerId == layer.id,
                        showDelete: layers.length > 1,
                        onTap: () {
                          context.viewportNotifier
                              .setActiveLayer(layer.id);
                        },
                        onDoubleTap: () {
                          setState(() {
                            _editingLayerId = layer.id;
                          });
                        },
                        onRename: (name) {
                          context.viewportNotifier
                              .renameLayer(layer.id, name);
                          setState(() {
                            _editingLayerId = null;
                          });
                          // Restore focus so keyboard shortcuts
                          // continue working after the rename
                          // TextField is removed.
                          Focus.maybeOf(context)?.requestFocus();
                        },
                        onToggleVisibility: () {
                          context.viewportNotifier
                              .toggleLayerVisibility(
                            layer.id,
                          );
                        },
                        onDelete: () {
                          context.viewportNotifier
                              .deleteLayer(layer.id);
                          if (_editingLayerId == layer.id) {
                            setState(() {
                              _editingLayerId = null;
                            });
                          }
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.onCollapse,
    required this.onAdd,
  });

  final VoidCallback onCollapse;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 32,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: [
          GestureDetector(
            onTap: onCollapse,
            child: const MouseRegion(
              cursor: SystemMouseCursors.click,
              child: Icon(
                Icons.chevron_right,
                size: 16,
                color: ArcadiaColor.primary,
              ),
            ),
          ),
          const SizedBox(width: 4),
          const Text(
            'LAYERS',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: ArcadiaColor.primary,
            ),
          ),
          const Spacer(),
          GestureDetector(
            onTap: onAdd,
            child: const MouseRegion(
              cursor: SystemMouseCursors.click,
              child: Icon(
                Icons.add,
                size: 16,
                color: ArcadiaColor.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LayerRow extends StatelessWidget {
  const _LayerRow({
    required this.layer,
    required this.isActive,
    required this.isEditing,
    required this.showDelete,
    required this.onTap,
    required this.onDoubleTap,
    required this.onRename,
    required this.onToggleVisibility,
    required this.onDelete,
  });

  final Layer layer;
  final bool isActive;
  final bool isEditing;
  final bool showDelete;
  final VoidCallback onTap;
  final VoidCallback onDoubleTap;
  final ValueChanged<String> onRename;
  final VoidCallback onToggleVisibility;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 28,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      color: isActive ? ArcadiaColor.active : null,
      child: Row(
        children: [
          GestureDetector(
            onTap: onToggleVisibility,
            child: MouseRegion(
              cursor: SystemMouseCursors.click,
              child: Icon(
                layer.visible
                    ? Icons.visibility
                    : Icons.visibility_off,
                size: 14,
                color: ArcadiaColor.primary,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: GestureDetector(
              onTap: onTap,
              onDoubleTap: onDoubleTap,
              child: isEditing
                  ? _RenameField(
                      initialName: layer.name,
                      onSubmit: onRename,
                    )
                  : Text(
                      layer.name,
                      style: const TextStyle(fontSize: 12),
                      overflow: TextOverflow.ellipsis,
                    ),
            ),
          ),
          if (showDelete)
            GestureDetector(
              onTap: onDelete,
              child: const MouseRegion(
                cursor: SystemMouseCursors.click,
                child: Icon(
                  Icons.close,
                  size: 14,
                  color: ArcadiaColor.primary,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _RenameField extends StatefulWidget {
  const _RenameField({
    required this.initialName,
    required this.onSubmit,
  });

  final String initialName;
  final ValueChanged<String> onSubmit;

  @override
  State<_RenameField> createState() => _RenameFieldState();
}

class _RenameFieldState extends State<_RenameField> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: widget.initialName,
    );
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
      autofocus: true,
      style: const TextStyle(fontSize: 12),
      decoration: const InputDecoration(
        isDense: true,
        contentPadding: EdgeInsets.zero,
        border: InputBorder.none,
      ),
      onSubmitted: widget.onSubmit,
      onTapOutside: (_) => widget.onSubmit(_controller.text),
    );
  }
}
