import 'package:flutter/material.dart';
import 'package:simple_live_app/services/device_info_service.dart';

/// 底部 Tab 栏容器：iOS 26+ 渲染为浮动 Dock 样式（仿 iOS 26 桌面 Dock），
/// 其他平台回退为标准 NavigationBar。
///
/// iOS 26+ 通过 UiKitView 嵌入原生 UIVisualEffectView，原生端运行时加载
/// `UIGlassEffect` 获得系统级液态玻璃。Dock 为浮动圆角胶囊，左右留白，
/// 浮于 home indicator 上方（不贴底），配合 Scaffold.extendBody 与内层
/// removePadding 使滚动内容延伸至 Dock 后方，UIGlassEffect 得以折射内容。
class LiquidGlassTabBar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final List<NavigationDestination> destinations;

  const LiquidGlassTabBar({
    super.key,
    required this.selectedIndex,
    required this.onDestinationSelected,
    required this.destinations,
  });

  @override
  Widget build(BuildContext context) {
    final supportsGlass = DeviceInfoService.instance.supportsLiquidGlass;

    if (!supportsGlass) {
      return NavigationBar(
        selectedIndex: selectedIndex,
        onDestinationSelected: onDestinationSelected,
        height: 56,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysHide,
        destinations: destinations,
      );
    }

    final theme = Theme.of(context);

    // iOS 26 浮动 Dock：圆角胶囊，左右留白，浮于 home indicator 上方。
    // SafeArea(top:false) 仅处理底部 home indicator，Dock 自然位于其上方；
    // 上下各留 4pt 悬浮间距，避免 Dock 顶到 home indicator 显得局促。
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
        child: Container(
          height: 60,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
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
            borderRadius: BorderRadius.circular(28),
            child: Stack(
              children: [
                // 原生 UIVisualEffectView — iOS 26+ 渲染 UIGlassEffect 真液态玻璃
                const Positioned.fill(
                  child: UiKitView(viewType: 'liquid_glass_view'),
                ),
                // NavigationBar 浮于玻璃之上，背景透明，仅保留图标与指示器
                NavigationBar(
                  selectedIndex: selectedIndex,
                  onDestinationSelected: onDestinationSelected,
                  height: 60,
                  labelBehavior: NavigationDestinationLabelBehavior.alwaysHide,
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  surfaceTintColor: Colors.transparent,
                  // 选中指示器：半透明主色胶囊，与液态玻璃融合
                  indicatorColor: theme.colorScheme.primary.withAlpha(50),
                  destinations: destinations,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
