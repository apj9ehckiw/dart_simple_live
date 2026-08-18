import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

/// 设备信息服务：同步检测平台版本，供 UI 层判断是否启用平台专属视觉效果。
class DeviceInfoService extends GetxService {
  static DeviceInfoService get instance => Get.find<DeviceInfoService>();

  /// iOS 主版本号（如 26）。非 iOS 平台为 0。
  int _iosMajorVersion = 0;

  /// iOS 主版本号；非 iOS 平台返回 0。
  int get iosMajorVersion => _iosMajorVersion;

  /// 当前是否为 iOS 平台。
  bool get isIOS => Platform.isIOS;

  /// 是否支持 iOS 26 Liquid Glass 效果。
  bool get supportsLiquidGlass => Platform.isIOS && _iosMajorVersion >= 26;

  @override
  void onInit() {
    _detectIOSVersion();
    super.onInit();
  }

  /// 同步解析 iOS 主版本号，确保在首帧渲染前即可判断。
  /// Platform.operatingSystemVersion 格式示例：
  ///   "Version 17.0 (Build 21B74)" / "Version 26.0 (Build 24A1234)"
  void _detectIOSVersion() {
    if (!Platform.isIOS) return;
    try {
      final versionStr = Platform.operatingSystemVersion;
      final match = RegExp(r'(\d+)').firstMatch(versionStr);
      if (match != null) {
        _iosMajorVersion = int.parse(match.group(1)!);
      }
    } catch (e) {
      debugPrint('DeviceInfoService: iOS version parse error: $e');
    }
  }
}
