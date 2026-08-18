import UIKit
import Flutter

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)

    // 注册液态玻璃 PlatformView。
    // 原生视图在 iOS 26+ 运行时加载 UIGlassEffect 渲染真液态玻璃，
    // 在旧版 iOS 上回退为标准毛玻璃模糊。
    if let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "LiquidGlassPlugin") {
      registrar.register(LiquidGlassViewFactory(), withId: "liquid_glass_view")
    }
  }
}

// MARK: - Liquid Glass PlatformView

class LiquidGlassViewFactory: NSObject, FlutterPlatformViewFactory {
  func create(
    withFrame frame: CGRect,
    viewIdentifier viewId: Int64,
    arguments args: Any?
  ) -> FlutterPlatformView {
    return LiquidGlassPlatformView(frame: frame, viewId: viewId, args: args)
  }

  func createArgsCodec() -> FlutterMessageCodec & NSObjectProtocol {
    return FlutterStandardMessageCodec.sharedInstance()
  }

  /// 创建液态玻璃视觉效果。
  /// - iOS 26+：运行时加载 `UIGlassEffect`，获得系统级液态玻璃（光线折射 + 自适应着色 + 边缘高光）。
  /// - iOS 13~25：回退到 `UIBlurEffect(.systemUltraThinMaterial)` 标准毛玻璃。
  /// 通过 `NSClassFromString` 动态查找类，避免强依赖 iOS 26 SDK，旧版 Xcode 亦可编译。
  static func makeGlassEffect() -> UIVisualEffect {
    if #available(iOS 26.0, *) {
      if let glassClass = NSClassFromString("UIGlassEffect"),
         let glassType = glassClass as? NSObject.Type {
        let instance = glassType.init()
        if let glass = instance as? UIVisualEffect {
          return glass
        }
      }
    }
    return UIBlurEffect(style: .systemUltraThinMaterial)
  }
}

class LiquidGlassPlatformView: NSObject, FlutterPlatformView {
  private let container: UIView

  init(frame: CGRect, viewId: Int64, args: Any?) {
    self.container = UIView(frame: frame)
    super.init()

    container.isOpaque = false
    container.backgroundColor = .clear
    container.clipsToBounds = true
    // 禁用原生视图的触摸交互，让所有手势穿透到上层的 Flutter NavigationBar
    container.isUserInteractionEnabled = false

    // 选择视觉特效：iOS 26+ 优先使用 UIGlassEffect 真液态玻璃，否则回退标准毛玻璃。
    let effect = LiquidGlassViewFactory.makeGlassEffect()
    let effectView = UIVisualEffectView(effect: effect)
    effectView.frame = container.bounds
    effectView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
    container.addSubview(effectView)
  }

  func view() -> UIView {
    return container
  }
}
