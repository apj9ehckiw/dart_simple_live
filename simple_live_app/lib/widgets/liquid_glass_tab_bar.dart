import 'package:flutter/material.dart';
import 'package:simple_live_app/services/device_info_service.dart';

/// 底部 Tab 栏容器：在 iOS 26+ 上渲染原生液态玻璃（Liquid Glass）效果，
/// 其他平台回退为标准 NavigationBar。
///
/// iOS 26+ 通过 UiKitView 嵌入原生 UIVisualEffectView，原生端运行时加载
/// `UIGlassEffect` 获得系统级液态玻璃渲染（光线折射 + 自适应着色 + 边缘高光）。
/// 全宽贴底布局，需配合 Scaffold.extendBody = true 并移除内层 bottom padding，
/// 使页面内容延伸至 Tab 栏后方，UIGlassEffect 才能折射到滚动内容。
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

    // 全宽贴底：UiKitView 填满整个 Tab 栏区域（含底部安全区），
    // iOS 26+ 渲染真液态玻璃并折射 extendBody 延伸至后方的滚动内容；
    // NavigationBar 浮于玻璃之上、背景透明，SafeArea 让图标避开 home indicator。
    return Stack(
      children: [
        const Positioned.fill(
          child: UiKitView(viewType: 'liquid_glass_view'),
        ),
        SafeArea(
          top: false,
          child: NavigationBar(
            selectedIndex: selectedIndex,
            onDestinationSelected: onDestinationSelected,
            height: 56,
            labelBehavior: NavigationDestinationLabelBehavior.alwaysHide,
            backgroundColor: Colors.transparent,
            elevation: 0,
            surfaceTintColor: Colors.transparent,
            // 选中指示器：半透明主色胶囊，与液态玻璃融合
            indicatorColor: theme.colorScheme.primary.withAlpha(50),
            destinations: destinations,
          ),
        ),
      ],
    );
  }
}
