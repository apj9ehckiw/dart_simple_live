import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:simple_live_app/app/app_style.dart';
import 'package:simple_live_app/services/device_info_service.dart';
import 'package:simple_live_app/widgets/animated_indexed_stack.dart';
import 'package:simple_live_app/widgets/liquid_glass_dock_scope.dart';
import 'package:simple_live_app/widgets/liquid_glass_tab_bar.dart';

import 'indexed_controller.dart';

class IndexedPage extends GetView<IndexedController> {
  const IndexedPage({super.key});

  @override
  Widget build(BuildContext context) {
    return OrientationBuilder(
      builder: (context, orientation) {
        final supportsGlass =
            DeviceInfoService.instance.supportsLiquidGlass;
        final useGlassTab =
            supportsGlass && orientation == Orientation.portrait;
        return Scaffold(
          // iOS 26+ 液态玻璃 Tab 栏：内容延伸至底部，使原生 UIGlassEffect 能折射滚动内容
          extendBody: useGlassTab,
          body: LiquidGlassDockScope(
            // Dock 栏总高度 = 容器 64 + 上下 padding 各 4 + home indicator 安全区
            // + 4 间距，滚动组件据此在滚动内容底部预留空间避免遮挡
            bottomInset: useGlassTab
                ? MediaQuery.of(context).padding.bottom + 64 + 8 + 4
                : 0,
            child: MediaQuery(
              // 移除底部 padding，避免内层各页面 Scaffold 消费 bottom padding
              // 而把内容截断在 Tab 栏上方，导致 Tab 栏后方无内容可折射
              data: MediaQuery.of(context)
                  .removePadding(removeBottom: useGlassTab),
              child: Row(
                children: [
                Visibility(
                  visible: orientation == Orientation.landscape,
                  child: Obx(
                    () => NavigationRail(
                      selectedIndex: controller.index.value,
                      onDestinationSelected: controller.setIndex,
                      labelType: NavigationRailLabelType.none,
                      destinations: controller.items
                          .map(
                            (item) => NavigationRailDestination(
                              icon: Icon(item.iconData),
                              label: Text(item.title),
                              padding: AppStyle.edgeInsetsV8,
                            ),
                          )
                          .toList(),
                    ),
                  ),
                ),
                Expanded(
                  child: Obx(
                    () => Container(
                      decoration: BoxDecoration(
                        border: Border(
                          left: orientation == Orientation.landscape
                              ? BorderSide(
                                  color: Colors.grey.withAlpha(50),
                                  width: 1,
                                )
                              : BorderSide.none,
                        ),
                      ),
                      child: AnimatedIndexedStack(
                        index: controller.index.value,
                        children: controller.pages,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          ),
          bottomNavigationBar: Visibility(
            visible: orientation == Orientation.portrait,
            child: Obx(
              () => LiquidGlassTabBar(
                selectedIndex: controller.index.value,
                onDestinationSelected: controller.setIndex,
                items: controller.items
                    .map((item) => LiquidGlassTabItem(
                          icon: item.iconData,
                          label: item.title,
                        ))
                    .toList(),
              ),
            ),
          ),
        );
      },
    );
  }
}
