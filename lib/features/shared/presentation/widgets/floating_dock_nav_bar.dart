import 'package:flutter/material.dart';
import 'package:sistema_dental/core/theme/app_colors.dart';

class DockItemData {
  final IconData icon;
  final IconData? selectedIcon;
  final String label;
  final VoidCallback? onTapOverride;

  const DockItemData({
    required this.icon,
    this.selectedIcon,
    required this.label,
    this.onTapOverride,
  });
}

class FloatingDockNavBar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onItemSelected;
  final List<DockItemData> items;

  const FloatingDockNavBar({
    super.key,
    required this.selectedIndex,
    required this.onItemSelected,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;

    return Align(
      alignment: Alignment.bottomCenter,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.only(bottom: isLandscape ? 6 : 14),
          child: Material(
            elevation: 10,
            shadowColor: const Color(0x40000000),
            borderRadius: BorderRadius.circular(30),
            color: const Color(0xFFE4E6EA),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFE4E6EA),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(
                  color: const Color(0xAAFFFFFF),
                  width: 1.5,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(items.length, (index) {
                  final item = items[index];
                  final isSelected =
                      selectedIndex == index && item.onTapOverride == null;
                  return _DockItem(
                    item: item,
                    isSelected: isSelected,
                    isLandscape: isLandscape,
                    onTap: () {
                      if (item.onTapOverride != null) {
                        item.onTapOverride!();
                      } else {
                        onItemSelected(index);
                      }
                    },
                  );
                }),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DockItem extends StatefulWidget {
  final DockItemData item;
  final bool isSelected;
  final bool isLandscape;
  final VoidCallback onTap;

  const _DockItem({
    required this.item,
    required this.isSelected,
    required this.isLandscape,
    required this.onTap,
  });

  @override
  State<_DockItem> createState() => _DockItemState();
}

class _DockItemState extends State<_DockItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _pressCtrl;
  late Animation<double> _pressAnim;

  @override
  void initState() {
    super.initState();
    _pressCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 90),
      reverseDuration: const Duration(milliseconds: 180),
    );
    _pressAnim = Tween<double>(begin: 1.0, end: 0.85).animate(
      CurvedAnimation(parent: _pressCtrl, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _pressCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final iconSize = widget.isLandscape ? 22.0 : 24.0;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => _pressCtrl.forward(),
      onTapUp: (_) {
        _pressCtrl.reverse();
        widget.onTap();
      },
      onTapCancel: () => _pressCtrl.reverse(),
      child: ScaleTransition(
        scale: _pressAnim,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 3),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOutCubic,
            padding: EdgeInsets.symmetric(
              horizontal: widget.isSelected ? 16 : 12,
              vertical: widget.isLandscape ? 6 : 8,
            ),
            decoration: BoxDecoration(
              color: widget.isSelected ? Colors.white : Colors.transparent,
              borderRadius: BorderRadius.circular(22),
              boxShadow: widget.isSelected
                  ? const [
                      BoxShadow(
                        color: Color(0x18000000),
                        blurRadius: 10,
                        offset: Offset(0, 3),
                      ),
                    ]
                  : null,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Icono con animación de color
                TweenAnimationBuilder<Color?>(
                  tween: ColorTween(
                    begin: widget.isSelected
                        ? const Color(0xFF6B7280)
                        : AppColors.primaryBlue,
                    end: widget.isSelected
                        ? AppColors.primaryBlue
                        : const Color(0xFF6B7280),
                  ),
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeOutCubic,
                  builder: (context, color, _) => AnimatedScale(
                    scale: widget.isSelected ? 1.1 : 1.0,
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeOutBack,
                    child: Icon(
                      widget.isSelected
                          ? (widget.item.selectedIcon ?? widget.item.icon)
                          : widget.item.icon,
                      color: color ?? const Color(0xFF6B7280),
                      size: iconSize,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                // Punto indicador animado
                AnimatedScale(
                  scale: widget.isSelected ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeOutBack,
                  child: Container(
                    width: 5,
                    height: 5,
                    decoration: const BoxDecoration(
                      color: AppColors.primaryBlue,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
