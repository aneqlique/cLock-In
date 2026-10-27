import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/config/theme.dart';

class AppNavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  const AppNavItem({required this.icon, required this.activeIcon, required this.label});
}

/// Floating pill navigation bar. The active tab expands to show its label.
class AppNavBar extends StatelessWidget {
  final List<AppNavItem> items;
  final int currentIndex;
  final ValueChanged<int> onTap;

  const AppNavBar({super.key, required this.items, required this.currentIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return SafeArea(
      top: false,
      minimum: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Container(
          height: 64,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            color: c.navBar,
            borderRadius: BorderRadius.circular(AppRadius.xl),
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: 0.18), blurRadius: 24, offset: const Offset(0, 8)),
            ],
          ),
          child: Row(
            children: [
              for (var i = 0; i < items.length; i++)
                Expanded(
                  flex: i == currentIndex ? 2 : 1,
                  child: _NavButton(
                    item: items[i],
                    selected: i == currentIndex,
                    onTap: () {
                      if (i != currentIndex) HapticFeedback.selectionClick();
                      onTap(i);
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  final AppNavItem item;
  final bool selected;
  final VoidCallback onTap;

  const _NavButton({required this.item, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Semantics(
      selected: selected,
      button: true,
      label: item.label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Center(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 260),
            curve: Curves.easeOutCubic,
            height: 44,
            padding: EdgeInsets.symmetric(horizontal: selected ? 14 : 0),
            decoration: BoxDecoration(
              color: selected ? c.navActive : Colors.transparent,
              borderRadius: BorderRadius.circular(22),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  selected ? item.activeIcon : item.icon,
                  size: 22,
                  color: selected ? c.onNavActive : c.navIcon,
                ),
                if (selected) ...[
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      item.label,
                      maxLines: 1,
                      overflow: TextOverflow.fade,
                      softWrap: false,
                      style: context.tt.labelLarge?.copyWith(color: c.onNavActive),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
