import 'package:flutter/widgets.dart';

/// 向子树传递 iOS 26+ 液态玻璃 Dock 栏需要预留的底部空间。
///
/// IndexedPage 在液态玻璃模式下通过 extendBody + removePadding 让滚动内容
/// 延伸至 Dock 栏后方供 UIGlassEffect 折射，同时内部页面的 MediaQuery
/// bottom padding 被移除为 0，滚动视图因此不知道底部存在 Dock，导致
/// 滚动到底部时最后一项被 Dock 遮挡。
///
/// IndexedPage 用本 Scope 包裹其 body，并传入 Dock 栏总高度（含
/// home indicator 安全区与浮动间距）。页面中的滚动组件（PageGridView、
/// PageListView 等）通过 [of] 读取该值，追加到滚动内容的底部 padding，
/// 既保证最后一项可滚动至 Dock 上方，又不影响内容延伸供玻璃折射。
///
/// 不在 Scope 内（独立页面、横向模式、非 iOS 26+）时 [of] 返回 0。
class LiquidGlassDockScope extends InheritedWidget {
  /// 需要为滚动内容预留的底部空间（像素）。
  final double bottomInset;

  const LiquidGlassDockScope({
    super.key,
    required this.bottomInset,
    required super.child,
  });

  /// 读取底部预留空间；不在 Scope 内返回 0。
  static double of(BuildContext context) {
    return context
            .dependOnInheritedWidgetOfExactType<LiquidGlassDockScope>()
            ?.bottomInset ??
        0;
  }

  @override
  bool updateShouldNotify(LiquidGlassDockScope oldWidget) =>
      bottomInset != oldWidget.bottomInset;
}
