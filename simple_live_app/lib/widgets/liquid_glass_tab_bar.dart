import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:simple_live_app/services/device_info_service.dart';

/// 底部 Tab 栏容器：在 iOS 26+ 上渲染原生液态玻璃（Liquid Glass）效果，
/// 其他平台回退为标准 NavigationBar。
///
/// iOS 26+ 通过 UiKitView 嵌入原生 UIVisualEffectView，原生端运行时加载
/// `UIGlassEffect` 获得系统级液态玻璃渲染（光线折射 + 自适应着色 + 边缘高光），
/// 配合浮动胶囊外形还原 iOS 26 设计语言。需配合 Scaffold.extendBody = true
/// 使内容滚动至半透明 Tab 栏后方产生折射模糊。
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

    // 玻璃边框：亮色下偏白高光、暗色下淡白描边，模拟液态玻璃边缘反光
    final borderColor =
        isDark ? Colors.white.withAlpha(36) : Colors.white.withAlpha(180);
    // 顶部高光线：模拟玻璃上边缘的光线反射
    final highlightColor = isDark
        ? Colors.white.withAlpha(22)
        : Colors.white.withAlpha(120);
    // 投影：浮动胶囊悬浮于内容之上
    final shadowColor =
        isDark ? Colors.black.withAlpha(100) : Colors.black.withAlpha(28);

    return SafeArea(
      top: false,
      bottom: false,
      child: Padding(
        // 浮动胶囊：左右留白，底部留出安全区 + 额外悬浮间距
        padding: EdgeInsets.fromLTRB(12, 0, 12, 8 + bottomInset),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: shadowColor,
                blurRadius: 24,
                spreadRadius: 0,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(30),
            child: BackdropFilter(
              // 额外的 Dart 层轻量模糊，作为原生 UIGlassEffect 的兜底增强，
              // 在原生效果不可用或弱化时仍保持半透明质感
              filter: ImageFilter.blur(sigmaX: 0.5, sigmaY: 0.5),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: borderColor, width: 0.5),
                  // 顶部 1px 高光渐变，强化液态玻璃边缘立体感
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      highlightColor,
                      highlightColor.withAlpha(0),
                    ],
                    stops: const [0.0, 0.08],
                  ),
                ),
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
                      height: 62,
                      labelBehavior:
                          NavigationDestinationLabelBehavior.alwaysHide,
                      backgroundColor: Colors.transparent,
                      elevation: 0,
                      surfaceTintColor: Colors.transparent,
                      // 选中指示器：半透明主色胶囊，与液态玻璃融合
                      indicatorColor:
                          theme.colorScheme.primary.withAlpha(50),
                      destinations: destinations,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
