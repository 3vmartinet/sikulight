import 'package:flutter/material.dart';

class ExpandablePanel extends StatelessWidget {
  final Widget header;
  final Widget child;
  final bool isExpanded;
  final VoidCallback onToggle;

  const ExpandablePanel({
    super.key,
    required this.header,
    required this.child,
    required this.isExpanded,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: isExpanded ? 1 : 0,
      child: Column(
        children: [
          _PanelTitle(
            isExpanded: isExpanded,
            onToggle: onToggle,
            child: header,
          ),
          if (isExpanded) Expanded(child: child),
        ],
      ),
    );
  }
}

class _PanelTitle extends StatelessWidget {
  final bool isExpanded;
  final VoidCallback onToggle;
  final Widget child;

  const _PanelTitle({
    required this.isExpanded,
    required this.onToggle,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onToggle,
      child: Container(
        height: 48,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: Theme.of(context).dividerColor.withValues(alpha: 0.1),
          border: Border(
            bottom: BorderSide(color: Theme.of(context).dividerColor),
          ),
        ),
        child: Row(
          children: [
            Icon(
              isExpanded
                  ? Icons.keyboard_arrow_down
                  : Icons.keyboard_arrow_right,
            ),
            const SizedBox(width: 8),
            Expanded(child: child),
          ],
        ),
      ),
    );
  }
}
