import 'package:flutter/material.dart';
import 'package:simple_live_app/services/device_info_service.dart';

/// 底部 Tab 栏容器：在 iOS 26+ 上渲染原生液态玻璃（Liquid Glass）效果，
/// 其他平台回退为标准 NavigationBar。
///
/// iOS 26+ 通过 UiKitView 嵌入原生 UIVisualEffectView，系统自动应用
/// Liquid Glass 液态玻璃渲染（含光线折射、自适应着色），配合浮动胶囊外形
/// 还原 iOS 26 设计语言。需配合 Scaffold.extendBody = true 使内容滚动至
/// 半透明 Tab 栏后方产生模糊。
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
    final isDark = theme.brightness == Brightness.dark;
    final viewPadding = MediaQuery.of(context).viewPadding;
    final bottomInset = viewPadding.bottom;

    // 玻璃边框 & 阴影
    final borderColor =
        isDark ? Colors.white.withAlpha(40) : Colors.white.withAlpha(160);
    final shadowColor =
        isDark ? Colors.black.withAlpha(80) : Colors.black.withAlpha(30);

    return SafeArea(
      top: false,
      bottom: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(12, 0, 12, 8 + bottomInset),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: shadowColor,
                blurRadius: 20,
                spreadRadius: 0,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: borderColor, width: 0.5),
              ),
              child: Stack(
                children: [
                  // 原生 UIVisualEffectView — iOS 26+ 自动渲染 Liquid Glass
                  Positioned.fill(
                    child: const UiKitView(viewType: 'liquid_glass_view'),
                  ),
                  // NavigationBar 浮于玻璃之上，背景透明
                  NavigationBar(
                    selectedIndex: selectedIndex,
                    onDestinationSelected: onDestinationSelected,
                    height: 60,
                    labelBehavior:
                        NavigationDestinationLabelBehavior.alwaysHide,
                    backgroundColor: Colors.transparent,
                    elevation: 0,
                    surfaceTintColor: Colors.transparent,
                    indicatorColor:
                        theme.colorScheme.primary.withAlpha(40),
                    destinations: destinations,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
