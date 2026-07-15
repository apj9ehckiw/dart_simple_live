import 'dart:io';

import 'package:flutter/scheduler.dart';
import 'package:get/get.dart';
import 'package:nativeapi/nativeapi.dart';
import 'package:simple_live_app/services/local_storage_service.dart';

class WindowService extends GetxService {
  static WindowService get instance => Get.find<WindowService>();

  late final WindowManager _windowManager;
  late final Window _window;
  Window get window => _window;

  bool isPIP = false;

  WindowService()
      : _windowManager = WindowManager.instance,
        _window = WindowManager.instance.getCurrent()!;

  void init() {
    _window.setMinimumSize(280, 280);
    _window.title = "Slive";
    resize();
    _setupEventListeners();

    // 延迟显示窗口，等待 Flutter 引擎完成窗口准备
    SchedulerBinding.instance.addPostFrameCallback((_) {
      _window.show();
      _window.focus();
    });
  }

  void _setupEventListeners() {
    _windowManager.addCallbackListener<WindowMovedEvent>((event) {
      if (!isPIP) {
        _saveBounds(_window.bounds);
      }
    });

    _windowManager.addCallbackListener<WindowResizedEvent>((event) {
      if (!isPIP) {
        _saveBounds(_window.bounds);
      }
    });

    _windowManager.addCallbackListener<WindowRestoredEvent>((event) {
      _window.titleBarStyle = isPIP ? TitleBarStyle.hidden : TitleBarStyle.normal;
    });

    _windowManager.addCallbackListener<WindowClosedEvent>((event) {
      if (Platform.isLinux) {
        exit(0);
      }
    });
  }

  void resize() {
    final width = LocalStorageService.instance
        .getValue(LocalStorageService.kWindowWidth, 1280.0);
    final height = LocalStorageService.instance
        .getValue(LocalStorageService.kWindowHeight, 720.0);
    final x = LocalStorageService.instance
        .getValue(LocalStorageService.kWindowX, 320.0);
    final y = LocalStorageService.instance
        .getValue(LocalStorageService.kWindowY, 180.0);
    _window.bounds = Rect.fromLTWH(x, y, width, height);
  }

  void _saveBounds(Rect bounds) {
    LocalStorageService.instance
        .setValue(LocalStorageService.kWindowX, bounds.left);
    LocalStorageService.instance
        .setValue(LocalStorageService.kWindowY, bounds.top);
    LocalStorageService.instance
        .setValue(LocalStorageService.kWindowWidth, bounds.width);
    LocalStorageService.instance
        .setValue(LocalStorageService.kWindowHeight, bounds.height);
  }
}
