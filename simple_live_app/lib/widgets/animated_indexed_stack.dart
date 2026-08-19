import 'package:flutter/material.dart';

/// 带 iOS 风格切换动画的 IndexedStack 替代品。
///
/// 保持所有子页面保活（与 IndexedStack 一致），切换 index 时新页面以
/// 交叉淡入 + 轻微缩放的方式出现，旧页面淡出，模拟 iOS 原生 tab 切换
/// 的平滑过渡，而非 IndexedStack 的瞬间切换。
class AnimatedIndexedStack extends StatefulWidget {
  final int index;
  final List<Widget> children;
  final Duration duration;

  const AnimatedIndexedStack({
    super.key,
    required this.index,
    required this.children,
    this.duration = const Duration(milliseconds: 300),
  });

  @override
  State<AnimatedIndexedStack> createState() => _AnimatedIndexedStackState();
}

class _AnimatedIndexedStackState extends State<AnimatedIndexedStack>
    with TickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _curve;
  int _current = 0;
  int _previous = 0;

  @override
  void initState() {
    super.initState();
    _current = widget.index;
    _previous = widget.index;
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );
    _curve = CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic);
    _controller.value = 1.0; // 初始直接显示，无动画
  }

  @override
  void didUpdateWidget(covariant AnimatedIndexedStack oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.index != widget.index) {
      _previous = _current;
      _current = widget.index;
      _controller.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final t = _curve.value;
        // 新页面：淡入 + 轻微放大（0.96 -> 1.0），模拟 iOS tab 切换进入
        final newOpacity = t;
        final newScale = 0.96 + 0.04 * t;
        // 旧页面：淡出
        final oldOpacity = 1.0 - t;

        final List<Widget> stackChildren = [];

        // 所有非当前、非上一个的页面：保活但隐藏
        for (int i = 0; i < widget.children.length; i++) {
          if (i == _current || i == _previous) continue;
          stackChildren.add(Offstage(child: widget.children[i]));
        }

        // 旧页面（动画期间淡出，结束后隐藏）
        if (_previous != _current) {
          stackChildren.add(
            Offstage(
              offstage: _controller.isCompleted,
              child: Opacity(
                opacity: oldOpacity,
                child: widget.children[_previous],
              ),
            ),
          );
        }

        // 新页面（淡入 + 缩放），置于最上层
        stackChildren.add(
          Opacity(
            opacity: newOpacity,
            child: Transform.scale(
              scale: newScale,
              alignment: Alignment.center,
              child: widget.children[_current],
            ),
          ),
        );

        return Stack(
          fit: StackFit.expand,
          children: stackChildren,
        );
      },
    );
  }
}
