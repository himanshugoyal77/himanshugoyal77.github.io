import 'package:flutter/material.dart';

/// Entrypoint of the application.
void main() {
  runApp(const MyApp());
}

/// [MyApp] is the main widget building the [MaterialApp].
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: Dock(
            items: const [
              Icons.person,
              Icons.message,
              Icons.call,
              Icons.camera,
              Icons.photo,
            ],
            builder: (icon) => DockItem(icon: icon),
          ),
        ),
      ),
    );
  }
}

/// A custom dock item that accepts an [IconData] and styles it.
class DockItem extends StatelessWidget {
  final IconData icon;

  const DockItem({required this.icon, super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 48),
      height: 48,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: Colors.primaries[icon.hashCode % Colors.primaries.length],
      ),
      child: Center(child: Icon(icon, color: Colors.white)),
    );
  }
}

/// A widget that displays a dock of reorderable [items].
class Dock<T> extends StatefulWidget {
  const Dock({
    super.key,
    this.items = const [],
    required this.builder,
  });

  /// Initial [T] items to display in this [Dock].
  final List<IconData> items;

  /// Builds the provided [T] item.
  final Widget Function(IconData) builder;

  @override
  State<Dock<T>> createState() => _DockState<T>();
}

/// State of the [Dock], used to manipulate the dock items.
class _DockState<T> extends State<Dock<T>> {
  late final List<IconData> _items = widget.items.toList();
  bool isItemInDock = false;

  /// List of icon labels for tooltips.
  final List<String> _itemLabels = const [
    "Contacts",
    "Messages",
    "Calls",
    "Camera",
    "Photos",
  ];

  /// List of open apps to display an indicator.
  List<IconData> openApps = [Icons.person];

  /// The item currently being dragged, if any.
  IconData? _draggingItem;

  /// Tracks the hover state by index for highlighting.
  int hoveredItemIndex = -1;

  /// Position where the dock is located.
  final Offset dockPosition = const Offset(136.8, 331.7);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black12,
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: _items
            .asMap()
            .entries
            .map((entry) => _buildDraggableIcon(entry))
            .toList(),
      ),
    );
  }

  /// Builds a draggable icon widget for each item in the dock.
  /// Adds spacing when the icon is near the dragged item.
  Widget _buildDraggableIcon(MapEntry<int, IconData> entry) {
    final int index = entry.key;
    final IconData item = entry.value;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: EdgeInsets.symmetric(
        horizontal: isItemInDock &&
                _draggingItem != null &&
                (index == _items.indexOf(_draggingItem!) ||
                    index == _items.indexOf(_draggingItem!) + 1)
            ? 20
            : 4,
      ),
      child: Draggable<IconData>(
        data: item,
        maxSimultaneousDrags: 1,
        feedback: widget.builder(item),
        childWhenDragging: const SizedBox.shrink(),
        onDragStarted: () => setState(() => _draggingItem = item),
        onDragCompleted: () => _resetDragState(),
        onDragEnd: (_) => _resetDragState(),
        onDragUpdate: (details) => _updateDockState(details),
        onDraggableCanceled: (_, __) => _resetDragState(),
        child: _buildDragTarget(item, index),
      ),
    );
  }

  /// Updates the dock state based on the drag position.
  void _updateDockState(DragUpdateDetails details) {
    setState(() {
      isItemInDock = details.globalPosition.dy >= dockPosition.dy &&
          details.globalPosition.dy < dockPosition.dy + 60;
    });
  }

  /// Resets the drag state after a drag is completed or canceled.
  void _resetDragState() {
    setState(() {
      _draggingItem = null;
      hoveredItemIndex = -1;
      isItemInDock = false;
    });
  }

  /// Builds a `DragTarget` for each item, enabling it to accept dragged items.
  Widget _buildDragTarget(IconData item, int index) {
    return DragTarget<IconData>(
      onWillAcceptWithDetails: (details) {
        setState(() {
          isItemInDock = false;
        });
        return true;
      },
      onAcceptWithDetails: (_) => setState(() => _draggingItem = null),
      builder: (context, _, __) => _buildTooltipItem(item, index),
    );
  }

  /// Builds a widget with a tooltip and hover effect for each item.
  Widget _buildTooltipItem(IconData item, int index) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onHover: (_) => setState(() => hoveredItemIndex = index),
      onExit: (_) => setState(() => hoveredItemIndex = -1),
      child: Tooltip(
        message: _draggingItem == null ? _itemLabels[index] : "",
        decoration: BoxDecoration(
          color: Colors.black87,
          borderRadius: BorderRadius.circular(5),
        ),
        textStyle: const TextStyle(color: Colors.white),
        waitDuration: const Duration(milliseconds: 200),
        showDuration: const Duration(seconds: 2),
        child: _buildIconColumn(item),
      ),
    );
  }

  /// Builds a column with hover scaling and open-app indicator for each icon.
  Widget _buildIconColumn(IconData item) {
    return AnimatedScale(
      scale: hoveredItemIndex == _items.indexOf(item) ? 1.1 : 1.0,
      duration: const Duration(milliseconds: 200),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 5),
          GestureDetector(
            onTap: () {
              setState(() {
                openApps.contains(item)
                    ? openApps.remove(item)
                    : openApps.add(item);
              });
            },
            child: widget.builder(item),
          ),
          const SizedBox(height: 5),
          Icon(
            Icons.circle,
            size: 5,
            color: openApps.contains(item) ? Colors.white : Colors.transparent,
          ),
        ],
      ),
    );
  }
}
