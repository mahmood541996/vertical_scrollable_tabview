import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:scroll_to_index/scroll_to_index.dart';

/// Detect TabBar Status, isOnTap = is to check TabBar is on Tap or not, isOnTapIndex = is on Tap Index
/// 增廁 TabBar 的狀態，isOnTap 是用來判斷是否是被點擊的狀態，isOnTapIndex 是用來儲存 TapBar 的 Index 的。
class VerticalScrollableTabBarStatus {
  static bool isOnTap = false;
  static int isOnTapIndex = 0;

  static void resetToDefaults() {
    isOnTap = false;
    isOnTapIndex = 0;
  }

  static void setIndex(int index) {
    if (isOnTapIndex == index) return;
    VerticalScrollableTabBarStatus.isOnTap = true;
    VerticalScrollableTabBarStatus.isOnTapIndex = index;
  }
}

/// VerticalScrollPosition = is ann Animation style from scroll_to_index plugin's preferPosition,
/// It's show the item position in listView.builder
/// 用來設定動畫狀態的（參考 scroll_to_index 的 preferPosition 屬性）
enum VerticalScrollPosition { begin, middle, end }

class VerticalScrollableTabView extends StatefulWidget {
  /// TabBar Controller to let widget listening TabBar changed
  /// TabBar Controller 用來讓 widget 監聽 TabBar 的 index 是否有更動
  final TabController _tabController;

  /// Required a List<dynamic> Type，you can put your data that you wanna put in item
  /// 要求 List<dynamic> 的結構，List 裡面可以放自己建立的 Object
  final List<dynamic> _listItemData;

  /// A callback that return an Object inside _listItemData and the index of ListView.Builder
  /// A callback 用來回傳一個 _listItemData 裡面的 Object 型態和 ListView.Builder 的 index
  final Widget Function(dynamic aaa, int index) _eachItemChild;

  /// VerticalScrollPosition = is ann Animation style from scroll_to_index,
  /// It's show the item position in listView.builder
  final VerticalScrollPosition _verticalScrollPosition;

  /// Required SliverAppBar, And TabBar must inside of SliverAppBar, and In the TabBar
  /// onTap: (index) => VerticalScrollableTabBarStatus.setIndex(index);
  final List<Widget> _slivers;

  final AutoScrollController _autoScrollController;

  /// Copy Scrollbar
  final bool? _thumbVisibility;
  final bool? _trackVisibility;
  final double? _thickness;
  final Radius? _radius;
  final bool Function(ScrollNotification)? _notificationPredicate;
  final bool? _interactive;
  final ScrollbarOrientation? _scrollbarOrientation;

  /// Copy CustomScrollView parameters
  final Axis _scrollDirection;
  final bool _reverse;
  final bool? _primary;
  final ScrollPhysics? _physics;
  final ScrollBehavior? _scrollBehavior;
  final bool _shrinkWrap;
  final Key? _center;
  final double _anchor;
  final double? _cacheExtent;
  final int? _semanticChildCount;
  final DragStartBehavior _dragStartBehavior;
  final ScrollViewKeyboardDismissBehavior _keyboardDismissBehavior;
  final String? _restorationId;
  final Clip _clipBehavior;
  final double _heightAboveChildren;

  const VerticalScrollableTabView({
    Key? key,

    /// Custom parameters
    required AutoScrollController autoScrollController,
    required TabController tabController,
    required List<dynamic> listItemData,
    required Widget Function(dynamic aaa, int index) eachItemChild,
    VerticalScrollPosition verticalScrollPosition =
        VerticalScrollPosition.begin,

    /// Copy Scrollbar
    bool? scrollbarThumbVisibility,
    bool? scrollbarTrackVisibility,
    double? scrollbarThickness,
    Radius? scrollbarRadius,
    bool Function(ScrollNotification)? scrollbarNotificationPredicate,
    bool? scrollInteractive,
    ScrollbarOrientation? scrollbarOrientation,

    /// Copy CustomScrollView parameters
    Axis scrollDirection = Axis.vertical,
    bool reverse = false,
    bool? primary,
    ScrollPhysics? physics,
    ScrollBehavior? scrollBehavior,
    bool shrinkWrap = false,
    Key? center,
    double anchor = 0.0,
    double? cacheExtent,
    required double collapsedHeightAboveChildren,
    required List<Widget> slivers,
    int? semanticChildCount,
    DragStartBehavior dragStartBehavior = DragStartBehavior.start,
    ScrollViewKeyboardDismissBehavior keyboardDismissBehavior =
        ScrollViewKeyboardDismissBehavior.manual,
    String? restorationId,
    Clip clipBehavior = Clip.hardEdge,
  })  : _tabController = tabController,
        _listItemData = listItemData,
        _eachItemChild = eachItemChild,
        _verticalScrollPosition = verticalScrollPosition,
        _autoScrollController = autoScrollController,

        /// Scrollbar
        _thumbVisibility = scrollbarThumbVisibility,
        _trackVisibility = scrollbarTrackVisibility,
        _thickness = scrollbarThickness,
        _radius = scrollbarRadius,
        _notificationPredicate = scrollbarNotificationPredicate,
        _interactive = scrollInteractive,
        _scrollbarOrientation = scrollbarOrientation,

        /// CustomScrollView
        _scrollDirection = scrollDirection,
        _reverse = reverse,
        _primary = primary,
        _physics = physics,
        _scrollBehavior = scrollBehavior,
        _shrinkWrap = shrinkWrap,
        _center = center,
        _anchor = anchor,
        _cacheExtent = cacheExtent,
        _slivers = slivers,
        _semanticChildCount = semanticChildCount,
        _dragStartBehavior = dragStartBehavior,
        _keyboardDismissBehavior = keyboardDismissBehavior,
        _restorationId = restorationId,
        _clipBehavior = clipBehavior,
        _heightAboveChildren = collapsedHeightAboveChildren,
        super(key: key);

  @override
  State<VerticalScrollableTabView> createState() =>
      _VerticalScrollableTabViewState();
}

class _VerticalScrollableTabViewState extends State<VerticalScrollableTabView>
    with SingleTickerProviderStateMixin {
  /// Instantiate RectGetter（套件提供的方法）
  final listViewKey = GlobalKey();

  /// To save the item's Rect
  /// 用來儲存 items 的 Rect 的 Map
  Map<int, GlobalKey> itemsKeys = {};

  late final VoidCallback _tabControllerListener;
  late final VoidCallback _scrollControllerListener;

  late TabController _tabController;
  late AutoScrollController _autoScrollController;

  @override
  void initState() {
    _tabControllerListener = _handleTabControllerTick;
    _scrollControllerListener = _moveToTabOnScrolling;

    _tabController = widget._tabController;
    _autoScrollController = widget._autoScrollController;

    _tabController.addListener(_tabControllerListener);
    _autoScrollController.addListener(_scrollControllerListener);
    super.initState();
  }

  @override
  void didUpdateWidget(covariant VerticalScrollableTabView oldWidget) {
    if (oldWidget._tabController != _tabController) {
      _tabController = widget._tabController;
      _tabController.addListener(_tabControllerListener);
      VerticalScrollableTabBarStatus.resetToDefaults();
    }

    if (oldWidget._autoScrollController != _autoScrollController) {
      _autoScrollController = widget._autoScrollController;
      _autoScrollController.addListener(_scrollControllerListener);
    }

    super.didUpdateWidget(oldWidget);
  }

  @override
  void dispose() {
    _tabController.removeListener(_tabControllerListener);
    _autoScrollController.removeListener(_scrollControllerListener);
    VerticalScrollableTabBarStatus.resetToDefaults();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      key: listViewKey,
      child: Scrollbar(
        controller: _autoScrollController,
        thumbVisibility: widget._thumbVisibility,
        trackVisibility: widget._trackVisibility,
        thickness: widget._thickness,
        radius: widget._radius,
        notificationPredicate: widget._notificationPredicate,
        interactive: widget._interactive,
        scrollbarOrientation: widget._scrollbarOrientation,
        child: CustomScrollView(
          scrollDirection: widget._scrollDirection,
          reverse: widget._reverse,
          controller: _autoScrollController,
          primary: widget._primary,
          physics: widget._physics,
          scrollBehavior: widget._scrollBehavior,
          shrinkWrap: widget._shrinkWrap,
          center: widget._center,
          anchor: widget._anchor,
          cacheExtent: widget._cacheExtent,
          slivers: [...widget._slivers, _buildVerticalSliverList()],
          semanticChildCount: widget._semanticChildCount,
          dragStartBehavior: widget._dragStartBehavior,
          keyboardDismissBehavior: widget._keyboardDismissBehavior,
          restorationId: widget._restorationId,
          clipBehavior: widget._clipBehavior,
        ),
      ),
    );
  }

  Widget _buildVerticalSliverList() {
    return SliverList(
      delegate: SliverChildListDelegate(
        List.generate(
          widget._listItemData.length,
          (index) {
            itemsKeys[index] ??= GlobalKey();
            return _buildItem(index);
          },
        ),
      ),
    );
  }

  Widget _buildItem(int index) {
    dynamic category = widget._listItemData[index];
    return SizedBox(
      key: itemsKeys[index],
      child: AutoScrollTag(
        key: ValueKey(index),
        index: index,
        controller: _autoScrollController,
        child: widget._eachItemChild(category, index),
      ),
    );
  }

  /// Animation Function for tabBarListener
  /// This need to put inside TabBar onTap, but in this case we put inside tabBarListener
  void _animateAndScrollTo(int index) async {
    _tabController.removeListener(_tabControllerListener);
    _autoScrollController.removeListener(_scrollControllerListener);

    _tabController.animateTo(index);

    await _autoScrollController.scrollToIndex(
      index,
      preferPosition: switch (widget._verticalScrollPosition) {
        (VerticalScrollPosition.begin) => AutoScrollPosition.begin,
        (VerticalScrollPosition.middle) => AutoScrollPosition.middle,
        (VerticalScrollPosition.end) => AutoScrollPosition.end,
      },
    );

    _tabController.addListener(_tabControllerListener);
    _autoScrollController.addListener(_scrollControllerListener);
  }

  void _moveToTabOnScrolling() {
    List<int> visibleItems = getVisibleItemsIndex();
    _tabController.animateTo(visibleItems[0]);
    VerticalScrollableTabBarStatus.resetToDefaults();
  }

  /// getVisibleItemsIndex on Screen
  /// 取得現在畫面上可以看得到的 Items Index
  List<int> getVisibleItemsIndex() {
    // get ListView Rect
    Rect? rect = listViewKey.widgetRect();

    List<int> items = [];
    if (rect == null) return items;

    bool isHorizontalScroll = widget._scrollDirection == Axis.horizontal;
    itemsKeys.forEach((index, key) {
      Rect? itemRect = key.widgetRect();

      if (itemRect == null) return;

      // y 軸座越大，代表越下面
      // 如果 item 上方的座標 比 listView 的下方的座標 的位置的大 代表不在畫面中。
      // bottom meaning => The offset of the bottom edge of this widget from the y axis.
      // top meaning => The offset of the top edge of this widget from the y axis.
      //Change offset based on AxisOrientation [horizontal] [vertical]
      switch (isHorizontalScroll) {
        case true:
          if (itemRect.left > rect.right) return;
          if (itemRect.right < rect.left) return;
          break;
        case false:
          if (itemRect.top > rect.bottom) return;
          // 如果 item 下方的座標 比 listView 的上方的座標 的位置的小 代表不在畫面中。
          if (itemRect.bottom <
              rect.top +
                  MediaQuery.of(context).viewPadding.top +
                  widget._heightAboveChildren) {
            return;
          }
          break;
      }

      items.add(index);
    });

    return items;
  }

  void _handleTabControllerTick() {
    if (VerticalScrollableTabBarStatus.isOnTap) {
      VerticalScrollableTabBarStatus.isOnTap = false;
      _animateAndScrollTo(VerticalScrollableTabBarStatus.isOnTapIndex);
    }
  }
}

extension WidgetRectFromKey on GlobalKey {
  Rect? widgetRect() {
    return switch (currentContext?.findRenderObject()) {
      RenderBox box => switch (box.localToGlobal(Offset.zero)) {
          final offset =>
            offset.dx.isNaN || offset.dy.isNaN ? null : offset & box.size,
        },
      _ => null,
    };
  }
}
