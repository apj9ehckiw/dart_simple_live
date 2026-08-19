import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:simple_live_app/services/device_info_service.dart';

/// 单个 Dock Tab 项数据。
class LiquidGlassTabItem {
  final IconData icon;
  final String label;
  const LiquidGlassTabItem({required this.icon, required this.label});
}

/// 底部 Tab 栏容器：iOS 26+ 渲染为浮动 Dock 样式（仿 iOS 26 桌面 Dock），
/// 其他平台回退为标准 NavigationBar。
///
/// iOS 26+ 通过 UiKitView 嵌入原生 UIVisualEffectView，原生端运行时加载
/// `UIGlassEffect` 获得系统级液态玻璃。Dock 为浮动圆角胶囊，左右留白，
/// 浮于 home indicator 上方（不贴底）。选中项图标与文字变为 iOS 系统蓝，
/// 切换时带轻微弹跳动画。配合 Scaffold.extendBody 与内层 removePadding
/// 使滚动内容延伸至 Dock 后方，UIGlassEffect 得以折射内容。
class LiquidGlassTabBar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final List<LiquidGlassTabItem> items;

  const LiquidGlassTabBar({
    super.key,
    required this.selectedIndex,
    required this.onDestinationSelected,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    final supportsGlass = DeviceInfoService.instance.supportsLiquidGlass;

    if (!supportsGlass) {
      // 非 iOS 26+ 平台：回退标准 NavigationBar（仍使用蓝色选中态）
      return NavigationBar(
        selectedIndex: selectedIndex,
        onDestinationSelected: onDestinationSelected,
        height: 56,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        destinations: items
            .map((e) => NavigationDestination(
                  icon: Icon(e.icon),
                  label: e.label,
                ))
            .toList(),
      );
    }

    // iOS 系统蓝：自动适配亮/暗模式
    final selectedColor = CupertinoColors.systemBlue;
    final unselectedColor =
        CupertinoColors.systemGrey.resolveFrom(context);

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
        child: Container(
          height: 64,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(28),
                blurRadius: 20,
                spreadRadius: 0,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(30),
            child: Stack(
              children: [
                // 原生 UIVisualEffectView — iOS 26+ 渲染 UIGlassEffect 真液态玻璃
                const Positioned.fill(
                  child: UiKitView(viewType: 'liquid_glass_view'),
                ),
                // 自定义 Dock 内容：选中态图标+文字变蓝
                Row(
                  children: [
                    for (int i = 0; i < items.length; i++)
                      Expanded(
                        child: _DockItem(
                          item: items[i],
                          selected: i == selectedIndex,
                          selectedColor: selectedColor,
                          unselectedColor: unselectedColor,
                          onTap: () => onDestinationSelected(i),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// 单个 Dock 项：图标 + 文字，选中态变蓝并带弹跳放大动画。
class _DockItem extends StatelessWidget {
  final LiquidGlassTabItem item;
  final bool selected;
  final Color selectedColor;
  final Color unselectedColor;
  final VoidCallback onTap;

  const _DockItem({
    required this.item,
    required this.selected,
    required this.selectedColor,
    required this.unselectedColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = selected ? selectedColor : unselectedColor;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: AnimatedScale(
        scale: selected ? 1.12 : 1.0,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutBack,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(item.icon, size: 24, color: color),
            const SizedBox(height: 2),
            Text(
              item.label,
              style: TextStyle(
                fontSize: 10,
                color: color,
                fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
