// ignore_for_file: invalid_use_of_protected_member

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:remixicon/remixicon.dart';
import 'package:simple_live_app/app/constant.dart';
import 'package:simple_live_app/app/controller/app_settings_controller.dart';
import 'package:simple_live_app/app/controller/base_controller.dart';
import 'package:simple_live_app/app/event_bus.dart';
import 'package:simple_live_app/app/utils.dart';
import 'package:simple_live_app/models/db/follow_user.dart';
import 'package:simple_live_app/models/db/follow_user_tag.dart';
import 'package:simple_live_app/routes/app_navigation.dart';
import 'package:simple_live_app/services/follow_service.dart';

class FollowUserController extends BasePageController<FollowUser> {
  StreamSubscription<dynamic>? onUpdatedIndexedStream;
  StreamSubscription<dynamic>? onUpdatedListStream;

  /// 0:全部 1:直播中 2:未直播
  var filterMode = FollowUserTag(id: "0", tag: "全部", userId: []).obs;
  RxList<FollowUserTag> tagList = [
    FollowUserTag(id: "0", tag: "全部", userId: []),
    FollowUserTag(id: "1", tag: "直播中", userId: []),
    FollowUserTag(id: "2", tag: "未开播", userId: []),
  ].obs;

  // 用户自定义标签
  RxList<FollowUserTag> userTagList = <FollowUserTag>[].obs;

  // 用户自定义显示顺序 - default：watchDuration
  Rx<SortMethod> sortMethod = SortMethod.watchDuration.obs;

  // 排序方式
  var sortMap = {
    SortMethod.watchDuration: "观看时长",
    SortMethod.siteId: "直播平台",
    SortMethod.recently: "最近添加",
    SortMethod.userNameASC: "用户名A-Z",
    SortMethod.userNameDESC: "用户名Z-A",
    SortMethod.tag: "自定义标签",
  };

  // 关注列表样式
  var followStyleMap = {true: "紧凑模式", false: "卡片模式"};

  @override
  void onInit() {
    onUpdatedIndexedStream = EventBus.instance.listen(
      EventBus.kBottomNavigationBarClicked,
      (index) {
        if (index == 1) {
          scrollToTopOrRefresh();
        }
      },
    );
    onUpdatedListStream = FollowService.instance.updatedListStream.listen(
      (event) {
        updateTagList();
        filterData();
      },
    );

    sortMethod = AppSettingsController.instance.followSortMethod;

    // 主动从 FollowService 同步当前数据，避免依赖 firstRefresh 的时序。
    // iOS 冷启动时 FollowService.onInit 可能尚未完成，followList 为空；
    // 若此时 firstRefresh 先返回空列表，pageEmpty 会置为 true 导致页面空白。
    // 此处预先填充 list，后续 stream 事件会进一步刷新。
    updateTagList();
    filterData();

    super.onInit();
  }

  @override
  Future refreshData() async {
    await FollowService.instance.loadData();
    updateTagList();
    super.refreshData();
  }

  @override
  Future<List<FollowUser>> getData(int page, int pageSize) async {
    if (page > 1) {
      return Future.value([]);
    }
    if (filterMode.value.tag == "全部") {
      // 返回副本，避免与 FollowService.followList 共享底层 List 引用，
      // 否则后续 assignAll 会发生自清空导致页面空白
      return FollowService.instance.followList.toList();
    } else if (filterMode.value.tag == "直播中") {
      return FollowService.instance.liveList.toList();
    } else if (filterMode.value.tag == "未开播") {
      return FollowService.instance.notLiveList.toList();
    } else {
      FollowService.instance.filterDataByTag(filterMode.value);
      return FollowService.instance.curTagFollowList.toList();
    }
  }

  void updateTagList() {
    userTagList.assignAll(FollowService.instance.followTagList);
    tagList.value = tagList.take(3).toList();
    for (var i in userTagList) {
      if (!tagList.contains(i)) {
        tagList.add(i);
      }
    }
  }

  // 数据清洗：不关心中间 data_flow，最终由filterData决定显示数据
  void filterData() {
    bool hideOffline = AppSettingsController.instance.hideOfflineFollow.value;

    if (filterMode.value.tag == "全部") {
      // 使用副本赋值，避免 list 与 FollowService 列表共享同一底层 List 引用，
      // 否则 assignAll 内部 clear() 会把源数据一并清空，导致页面空白
      list.assignAll(FollowService.instance.followList.toList());
    } else if (filterMode.value.tag == "直播中") {
      list.assignAll(FollowService.instance.liveList.toList());
    } else if (filterMode.value.tag == "未开播") {
      list.assignAll(FollowService.instance.notLiveList.toList());
    } else {
      FollowService.instance.filterDataByTag(filterMode.value);
      list.assignAll(FollowService.instance.curTagFollowList.toList());
    }

    if (hideOffline && filterMode.value.tag != "未开播") {
      // 保留直播中(2)和状态未知(0)的用户：
      // 状态未知（如多开同步后尚未刷新）时不应被误隐藏，
      // 否则列表会被全部过滤导致页面白屏，等状态更新后再过滤。
      list.retainWhere((user) =>
          user.liveStatus.value == 2 || user.liveStatus.value == 0);
    }

    // 同步空白遮罩状态。filterData 可能由 stream 事件在 loadData 之后触发，
    // 此时 followList 已有数据但 pageEmpty 仍为 true（loadData 在 followList
    // 为空时设置），导致 AppEmptyWidget 遮罩覆盖在列表上方，页面呈现空白。
    if (list.isNotEmpty) {
      pageEmpty.value = false;
    }
  }

  // 用户自定义关注样式
  Future<void> showFollowStyleDialog() async {
    var res = await Utils.showMapOptionDialog(
      title: "关注样式切换",
      followStyleMap,
      AppSettingsController.instance.followStyleNotGrid.value,
    );
    if (res != null) {
      AppSettingsController.instance.setFollowStyleNotGrid(res);
    }
  }

  // 用户自定义顺序dialog
  Future<void> showSortDialog() async {
    var res = await Utils.showMapOptionDialog(sortMap, sortMethod.value,
        title: "排序方式");
    if (res != null) {
      sortMethod.value = res;
      AppSettingsController.instance.setFollowSortMethod(sortMethod.value);
      if (filterMode.value.tag == "未开播" ||
          filterMode.value.tag == "全部" ||
          filterMode.value.tag == "直播中") {
        FollowService.instance.liveListSort();
      }
      filterData();
    }
  }

  void setFilterMode(FollowUserTag tag) {
    filterMode.value = tag;
    filterData();
  }

  void removeFollow(FollowUser follow) async {
    var result = await Utils.showAlertDialog("确定要取消关注${follow.userName}吗?",
        title: "取消关注");
    if (!result) {
      return;
    }
    // 取消关注同时删除标签内的 userId
    if (follow.tag != "全部") {
      var tag = tagList.firstWhereOrNull((tag) => tag.tag == follow.tag);
      if (tag != null) {
        tag.userId.remove(follow.id);
        updateTag(tag);
      }
    }
    await FollowService.instance.removeFollowUser(follow.id);
    filterData();
  }

  Future<void> updateFollow(FollowUser follow) async {
    await FollowService.instance.addFollow(follow);
  }

  void setFollowTag(FollowUser follow, FollowUserTag targetTag) {
    FollowService.instance.setFollowTag(follow, targetTag);
    filterData();
  }

  Future<void> updateTag(FollowUserTag followUserTag) async {
    await FollowService.instance.updateFollowUserTag(followUserTag);
  }

  // 弹出底部菜单栏
  void showBottomMenu(FollowUser item) {
    Get.bottomSheet(
      SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Remix.price_tag_3_line),
              title: const Text('设置标签'),
              onTap: () {
                Get.back();
                setFollowTagDialog(item);
              },
            ),
            ListTile(
              leading: const Icon(Remix.information_line),
              title: const Text('查看详情'),
              onTap: () {
                Get.back();
                AppNavigator.toFollowInfo(item);
              },
            ),
          ],
        ),
      ),
      backgroundColor: Get.theme.cardColor,
    );
  }

  void setFollowTagDialog(FollowUser follow) {
    /// 控制单选ui
    List<FollowUserTag> copiedList = [
      tagList.first,
      ...tagList.skip(3),
    ];
    Rx<FollowUserTag> checkTag = tagList.indexOf(filterMode.value) < 3
        ? copiedList.first.obs
        : filterMode.value.obs;
    final ScrollController scrollController = ScrollController();
    Get.dialog(
      AlertDialog(
        contentPadding: const EdgeInsets.all(16.0),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.0),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 标题栏
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '设置标签',
                  style: TextStyle(
                    fontSize: 18,
                  ),
                ),
                IconButton(
                  icon: const Icon(
                    Icons.check,
                  ),
                  onPressed: () {
                    setFollowTag(follow, checkTag.value);
                    Get.back();
                  },
                ),
              ],
            ),
            const Divider(),
            Obx(
              () {
                int selectedIndex = copiedList.indexOf(checkTag.value);
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (selectedIndex >= 0) {
                    scrollController.animateTo(
                      selectedIndex * 60.0, // 假设每项高度为 60
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                  }
                });
                return SizedBox(
                  height: 300,
                  width: 300,
                  child: RadioGroup<FollowUserTag>(
                    groupValue: checkTag.value,
                    onChanged: (value) {
                      checkTag.value = value!;
                    },
                    child: ListView.builder(
                      controller: scrollController,
                      itemCount: copiedList.length,
                      itemBuilder: (context, index) {
                        var tagItem = copiedList[index];
                        return Container(
                          decoration: BoxDecoration(
                            border: Border(
                              bottom: BorderSide(
                                  color: Colors.grey.shade300, width: 1.0),
                            ),
                          ),
                          child: RadioListTile<FollowUserTag>(
                            title: Text(tagItem.tag),
                            value: tagItem,
                          ),
                        );
                      },
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  void onClose() {
    onUpdatedIndexedStream?.cancel();
    onUpdatedListStream?.cancel();
    super.onClose();
  }
}
