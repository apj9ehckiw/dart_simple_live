import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
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
/// 浮于 home indicator 上方（不贴底）。选中项图标与文字变为 iOS 系统蓝。
///
/// 切换动画复刻 iOS 26 Liquid Glass Dock：玻璃容器保持连续不重建，
/// 内部选中指示器以 spring 物理曲线在槽位间位移，所有图标根据与选中
/// 位置的连续距离同步缩放/变色/挤压，产生液态形变与惯性流动感。
class LiquidGlassTabBar extends StatefulWidget {
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
  State<LiquidGlassTabBar> createState() => _LiquidGlassTabBarState();
}

class _LiquidGlassTabBarState extends State<LiquidGlassTabBar>
    with TickerProviderStateMixin {
  /// 无界 AnimationController：其 value 即"当前选中位置"的连续浮点值，
  /// 由 spring 物理仿真驱动，图标与指示器据此同步形变。
  late final AnimationController _posController;

  @override
  void initState() {
    super.initState();
    _posController = AnimationController(
      vsync: this,
      lowerBound: double.negativeInfinity,
      upperBound: double.infinity,
    );
    _posController.value = widget.selectedIndex.toDouble();
  }

  @override
  void didUpdateWidget(covariant LiquidGlassTabBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedIndex != widget.selectedIndex) {
      _springTo(widget.selectedIndex.toDouble());
    }
  }

  /// spring 物理位移：欠阻尼（ratio<1）带来惯性弹性，模拟液体流动。
  void _springTo(double target) {
    final spring = SpringDescription.withDampingRatio(
      mass: 1.0,
      stiffness: 320.0,
      ratio: 0.62,
    );
    final sim =
        SpringSimulation(spring, _posController.value, target, 0.0);
    _posController.animateWith(sim);
  }

  @override
  void dispose() {
    _posController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final supportsGlass = DeviceInfoService.instance.supportsLiquidGlass;

    if (!supportsGlass) {
      return NavigationBar(
        selectedIndex: widget.selectedIndex,
        onDestinationSelected: widget.onDestinationSelected,
        height: 56,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        destinations: widget.items
            .map((e) => NavigationDestination(
                  icon: Icon(e.icon),
                  label: e.label,
                  selectedIcon: Icon(e.icon,
                      color: CupertinoColors.systemBlue),
                ))
            .toList(),
      );
    }

    final selectedColor = CupertinoColors.systemBlue;
    final unselectedColor = CupertinoColors.systemGrey.resolveFrom(context);

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
            child: LayoutBuilder(
              builder: (context, constraints) {
                final n = widget.items.length;
                final slotWidth = constraints.maxWidth / n;
                return Stack(
                  fit: StackFit.expand,
                  children: [
                    // 1. 玻璃背景：连续不重建，UIGlassEffect 折射后方滚动内容
                    const UiKitView(viewType: 'liquid_glass_view'),

                    // 2. 选中指示器（吸附胶囊）：spring 驱动连续位移
                    AnimatedBuilder(
                      animation: _posController,
                      builder: (context, _) {
                        final pos = _posController.value;
                        final indicatorWidth = slotWidth * 0.72;
                        final left =
                            slotWidth * pos + (slotWidth - indicatorWidth) / 2;
                        return Positioned(
                          left: left,
                          top: 7,
                          bottom: 7,
                          width: indicatorWidth,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(22),
                              // 半透明蓝胶囊，与液态玻璃融合
                              color: selectedColor.withAlpha(38),
                              border: Border.all(
                                color: selectedColor.withAlpha(90),
                                width: 0.5,
                              ),
                            ),
                          ),
                        );
                      },
                    ),

                    // 3. 图标行：根据与选中位置的连续距离同步缩放/变色/挤压
                    Positioned.fill(
                      child: AnimatedBuilder(
                        animation: _posController,
                        builder: (context, _) {
                          final pos = _posController.value;
                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              for (int i = 0; i < n; i++)
                                Expanded(
                                  child: _DockIcon(
                                    item: widget.items[i],
                                    distance: (i - pos).abs(),
                                    selectedColor: selectedColor,
                                    unselectedColor: unselectedColor,
                                    onTap: () =>
                                        widget.onDestinationSelected(i),
                                  ),
                                ),
                            ],
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

/// 单个 Dock 图标：根据与选中位置的连续距离做缩放/颜色/挤压。
class _DockIcon extends StatelessWidget {
  final LiquidGlassTabItem item;
  final double distance;
  final Color selectedColor;
  final Color unselectedColor;
  final VoidCallback onTap;

  const _DockIcon({
    required this.item,
    required this.distance,
    required this.selectedColor,
    required this.unselectedColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // t: 1=选中(distance0), 0=远离(distance>=1)，平滑插值产生液态过渡
    final t = (1.0 - distance.clamp(0.0, 1.0)).clamp(0.0, 1.0);
    // 缩放：选中1.16，相邻0.88（受挤压让出空间），形成吸附与连锁位移感
    final scale = 0.88 + 0.28 * t;
    // 颜色连续插值
    final color = Color.lerp(unselectedColor, selectedColor, t)!;
    // 轻微纵向位移：选中项上浮一点，强化吸附层次
    final translateY = -2.0 * t;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Center(
        child: Transform.translate(
          offset: Offset(0, translateY),
          child: Transform.scale(
            scale: scale,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(item.icon, size: 22, color: color),
                const SizedBox(height: 2),
                Text(
                  item.label,
                  style: TextStyle(
                    fontSize: 10,
                    color: color,
                    fontWeight:
                        t > 0.5 ? FontWeight.w600 : FontWeight.normal,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
