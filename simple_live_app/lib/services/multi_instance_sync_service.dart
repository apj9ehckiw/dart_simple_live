import 'dart:async';
import 'dart:io';

import 'package:get/get.dart';
import 'package:simple_live_app/app/log.dart';
import 'package:simple_live_app/services/db_service.dart';
import 'package:simple_live_app/services/follow_service.dart';

/// 多开实例数据同步服务。
///
/// 桌面端支持多开后，多个实例共享同一 Hive 数据目录。本地补丁版
/// hive_ce 允许多进程同时打开 box（写入通过文件锁互斥），但各实例
/// 的内存缓存（keystore / RxList）不会自动感知其他实例的修改。
///
/// 本服务定时检查数据文件大小变化，检测到外部变更后重建 Hive box，
/// 并通知业务服务刷新界面数据，使多开实例之间保持数据一致。
class MultiInstanceSyncService extends GetxService {
  static MultiInstanceSyncService get instance =>
      Get.find<MultiInstanceSyncService>();

  /// 轮询间隔：兼顾响应速度与开销
  static const Duration _checkInterval = Duration(seconds: 3);

  Timer? _timer;
  String? _hiveDir;

  /// 参与同步的 box 文件名（不含扩展名）。
  /// 仅监控关注/历史等业务数据（DBService），设置类（LocalStorage）
  /// 不同步，避免其他实例改设置时触发无关的数据重建。
  static const List<String> _boxNames = [
    'history',
    'followuser',
    'followusertag',
  ];

  /// 各 box 文件最近一次检测到的大小（首次检测不触发刷新，避免启动即重建）
  final Map<String, int> _lastSizes = {};

  /// 启动轮询。hivePath 为 Hive 数据目录（桌面端共享目录）。
  void start(String hiveDir) {
    _hiveDir = hiveDir;
    _timer?.cancel();
    _timer = Timer.periodic(_checkInterval, (_) => _check());
  }

  @override
  void onClose() {
    _timer?.cancel();
    super.onClose();
  }

  Future<void> _check() async {
    final dir = _hiveDir;
    if (dir == null) return;

    var changed = false;
    for (final name in _boxNames) {
      final file = File('$dir${Platform.pathSeparator}$name.hive');
      try {
        if (!await file.exists()) continue;
        final size = await file.length();
        final last = _lastSizes[name];
        if (last != null && last != size) {
          changed = true;
        }
        _lastSizes[name] = size;
      } catch (e) {
        Log.logPrint(e);
      }
    }

    if (changed) {
      await _reloadData();
    }
  }

  /// 重建数据库连接并刷新各业务服务的数据。
  Future<void> _reloadData() async {
    try {
      await DBService.instance.reload();
      // 刷新关注列表等界面数据
      await FollowService.instance.refreshFromDb();
    } catch (e) {
      Log.logPrint(e);
    }
  }
}
