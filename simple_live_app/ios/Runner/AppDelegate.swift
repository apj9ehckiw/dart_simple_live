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
    // 使用 UIVisualEffectView + .systemUltraThinMaterial，
    // 在 iOS 26+ 上系统会自动应用 Liquid Glass 效果，
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

    // UIVisualEffectView + systemUltraThinMaterial：
    // - iOS 26+：系统自动渲染为 Liquid Glass 液态玻璃
    // - iOS 13~25：标准超薄材质毛玻璃
    let blurEffect = UIBlurEffect(style: .systemUltraThinMaterial)
    let effectView = UIVisualEffectView(effect: blurEffect)
    effectView.frame = container.bounds
    effectView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
    container.addSubview(effectView)
  }

  func view() -> UIView {
    return container
  }
}
