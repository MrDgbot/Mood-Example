import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Packages
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:provider/provider.dart';
import 'package:remixicon/remixicon.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:animations/animations.dart';

///
import 'package:moodexample/themes/app_theme.dart';
import 'package:moodexample/generated/l10n.dart';
import 'package:moodexample/widgets/show_modal_bottom_detail/show_modal_bottom_detail.dart';
import 'package:moodexample/widgets/empty/empty.dart';
import 'package:moodexample/common/utils.dart';
import 'package:moodexample/common/utils_intl.dart';
import 'package:moodexample/widgets/action_button/action_button.dart';
import 'package:moodexample/widgets/animation/animation.dart';
import 'package:moodexample/views/mood/mood_content.dart';
import 'package:moodexample/views/mood/mood_category_select.dart'
    as mood_category_select;

///
import 'package:moodexample/services/mood/mood_service.dart';
import 'package:moodexample/view_models/mood/mood_view_model.dart';
import 'package:moodexample/models/mood/mood_model.dart';

/// 心情页（记录列表）
class MoodPage extends StatefulWidget {
  const MoodPage({Key? key}) : super(key: key);

  @override
  State<MoodPage> createState() => _MoodPageState();
}

class _MoodPageState extends State<MoodPage>
    with AutomaticKeepAliveClientMixin {
  /// AutomaticKeepAliveClientMixin
  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    init(context);
  }

  @override
  Widget build(BuildContext context) {
    /// AutomaticKeepAliveClientMixin
    super.build(context);
    // 屏幕自适应 设置尺寸（填写设计中设备的屏幕尺寸）如果设计基于360dp * 690dp的屏幕
    ScreenUtil.init(
      context,
      designSize: const Size(AppTheme.wdp, AppTheme.hdp),
    );
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      // 悬浮按钮
      floatingActionButton: AnimatedPress(
        child: OpenContainer(
          useRootNavigator: true,
          clipBehavior: Clip.none,
          transitionType: ContainerTransitionType.fadeThrough,
          transitionDuration: const Duration(milliseconds: 450),
          closedBuilder: (_, openContainer) {
            return FloatingActionButton.extended(
              key: const Key("widget_add_mood_button"),
              heroTag: "addmood",
              backgroundColor: Theme.of(context).primaryColor,
              hoverElevation: 0,
              focusElevation: 0,
              elevation: 0,
              highlightElevation: 0,
              label: Row(
                children: [
                  Icon(
                    Remix.add_fill,
                    color: Colors.white,
                    size: 16.sp,
                  ),
                  Padding(
                    padding: EdgeInsets.only(left: 4.sp),
                    child: Text(
                      S.of(context).mood_add_button,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  )
                ],
              ),
              onPressed: () {
                vibrate();
                openContainer();
              },
            );
          },
          openElevation: 0,
          openColor: Theme.of(context).scaffoldBackgroundColor,
          middleColor: Theme.of(context).primaryColor.withOpacity(0.2),
          closedElevation: 0,
          closedShape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(28.w)),
          closedColor: Theme.of(context).scaffoldBackgroundColor,
          openBuilder: (_, closeContainer) {
            return const mood_category_select.MoodCategorySelect(type: "add");
          },
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      body: const SafeArea(
        child: MoodBody(key: Key("widget_mood_body")),
      ),
    );
  }
}

/// 初始化
init(BuildContext context) {
  MoodViewModel moodViewModel =
      Provider.of<MoodViewModel>(context, listen: false);

  /// 获取所有有记录心情的日期
  MoodService.getMoodRecordedDate(moodViewModel);

  /// 处理日期
  String moodDatetime = moodViewModel.nowDateTime.toString().substring(0, 10);

  /// 获取心情数据
  MoodService.getMoodData(moodViewModel, moodDatetime);
}

/// 主体
class MoodBody extends StatefulWidget {
  const MoodBody({Key? key}) : super(key: key);

  @override
  State<MoodBody> createState() => _MoodBodyState();
}

class _MoodBodyState extends State<MoodBody> {
  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(
        parent: BouncingScrollPhysics(),
      ),
      primary: false,
      shrinkWrap: false,
      slivers: [
        SliverAppBar(
          pinned: false,
          elevation: 0,
          backgroundColor: Colors.transparent,
          flexibleSpace: Align(
            child: Container(
              margin: EdgeInsets.only(
                left: 24.w,
                right: 24.w,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    S.of(context).mood_title,
                    style: Theme.of(context).textTheme.headline1?.copyWith(
                          fontSize: 36.sp,
                          fontWeight: FontWeight.bold,
                        ),
                    semanticsLabel:
                        S.of(context).app_bottomNavigationBar_title_mood,
                  ),
                  Image.asset(
                    "assets/images/woolly/woolly-heart.png",
                    height: 60.w,
                    excludeFromSemantics: true,
                  ),
                ],
              ),
            ),
          ),
          collapsedHeight: 100.w,
          expandedHeight: 100.w,
        ),

        /// 下拉加载
        CupertinoSliverRefreshControl(
          onRefresh: () async {
            vibrate();
            init(context);
          },
        ),

        /// 日历
        const SliverToBoxAdapter(
          child: Calendar(key: Key("widget_mood_body_calendar")),
        ),

        /// 心情数据列表
        Consumer<MoodViewModel>(
          builder: (_, moodViewModel, child) {
            /// 加载数据的占位
            if (moodViewModel.moodDataLoading) {
              return SliverFixedExtentList(
                itemExtent: 280.w,
                delegate: SliverChildBuilderDelegate(
                  (builder, index) {
                    return Align(
                      child: CupertinoActivityIndicator(radius: 12.sp),
                    );
                  },
                  childCount: 1,
                ),
              );
            }

            /// 没有数据的占位
            if ((moodViewModel.moodDataList?.length ?? 0) <= 0) {
              return SliverFixedExtentList(
                itemExtent: 280.w,
                delegate: SliverChildBuilderDelegate(
                  (builder, index) {
                    return Empty(
                      padding: EdgeInsets.only(top: 64.w),
                      height: 160.h,
                      width: 90.w,
                    );
                  },
                  childCount: 1,
                ),
              );
            }

            /// 有内容显示
            return SlidableAutoCloseBehavior(
              child: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    moodViewModel
                        .setMoodData(moodViewModel.moodDataList![index]);
                    MoodData? moodData = moodViewModel.moodData;

                    return MoodCard(
                      key: Key(moodViewModel.moodData?.moodId.toString() ?? ''),
                      moodId: moodData?.moodId ?? -1,
                      icon: moodData?.icon ?? '',
                      title: moodData?.title ?? '',
                      datetime: moodData?.createTime ?? '',
                      score: moodData?.score ?? 0,
                      content: moodData?.content,
                      createTime: moodData?.createTime ?? '',
                    );
                  },
                  childCount: moodViewModel.moodDataList?.length,
                ),
              ),
            );
          },
        ),

        /// 占位高度
        SliverToBoxAdapter(child: SizedBox(height: 64.w)),
      ],
    );
  }
}

/// 日历
class Calendar extends StatefulWidget {
  const Calendar({Key? key}) : super(key: key);

  @override
  State<Calendar> createState() => _CalendarState();
}

class _CalendarState extends State<Calendar> {
  /// 日历版式
  late CalendarFormat _calendarFormat = CalendarFormat.week;

  /// 日历样式构建
  ///
  /// @param DateTime day 当前日期
  ///
  /// @param List? moodRecordedDate 所有已记录心情的日期
  ///
  /// @param List<Color>? bodyColors 主背景渐变颜色 - 至少两个
  ///
  /// @param TextStyle textStyle 字体样式
  static Widget calenderBuilder({
    required DateTime day,
    List? moodRecordedDate,
    List<Color>? bodyColors,
    List<BoxShadow>? boxShadow,
    required TextStyle textStyle,
  }) {
    final String nowDate = DateFormat("yyyy-MM-dd").format(day);

    /// 所有已记录心情的日期
    late List list = moodRecordedDate ?? [];

    return SizedBox(
      width: 36.w,
      height: 48.w,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: bodyColors ?? [Colors.transparent, Colors.transparent],
          ),
          boxShadow: boxShadow,
          borderRadius: BorderRadius.circular(12.sp),
        ),
        child: Center(
          child: Stack(
            alignment: AlignmentDirectional.center,
            children: [
              Text(
                nowDate.substring(8, 10),
                style: textStyle,
              ),
              Builder(
                builder: (context) {
                  late int recordedIndex = -1;
                  for (int i = 0; i < list.length; i++) {
                    if (list[i]["recordedDate"] ==
                        DateFormat("yyyy-MM-dd").format(day)) {
                      recordedIndex = i;
                    }
                  }
                  if (recordedIndex > -1) {
                    return Container(
                      margin: EdgeInsets.only(top: 28.w),
                      child: Text(
                        list[recordedIndex]["icon"],
                        style: TextStyle(
                          fontSize: 8.sp,
                        ),
                      ),
                    );
                  }
                  return Container();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    /// 当前日期
    final nowDateTime =
        Provider.of<MoodViewModel>(context, listen: false).nowDateTime;

    /// 当前选择日期
    late DateTime selectedDay = nowDateTime;

    /// 选中的日期
    late DateTime focusedDay = nowDateTime;

    return Container(
      margin: EdgeInsets.only(left: 24.w, right: 24.w, top: 12.w, bottom: 12.w),
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Theme.of(context).cardColor,
              Theme.of(context).cardColor,
            ],
          ),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 6)
          ],
          borderRadius: BorderRadius.circular(18.w),
        ),
        child: Padding(
          padding: EdgeInsets.only(left: 12.w, right: 12.w, bottom: 12.w),
          child: TableCalendar(
            firstDay: DateTime.utc(2021, 10, 01),
            lastDay: DateTime.now(),
            focusedDay: focusedDay,
            startingDayOfWeek: StartingDayOfWeek.monday,
            calendarFormat: _calendarFormat,
            formatAnimationCurve: Curves.linearToEaseOut,
            pageAnimationCurve: Curves.linearToEaseOut,
            rowHeight: 52.w,
            daysOfWeekHeight: 24.w,

            // 头部样式
            headerStyle: HeaderStyle(
              formatButtonVisible: false,
              titleCentered: true,
              titleTextStyle: Theme.of(context)
                  .textTheme
                  .bodyText1!
                  .copyWith(fontSize: 14.sp),
              leftChevronIcon: Icon(
                Remix.arrow_left_s_line,
                size: 24.sp,
                color: AppTheme.subColor,
                semanticLabel: "日历向前翻页",
              ),
              rightChevronIcon: Icon(
                Remix.arrow_right_s_line,
                size: 24.sp,
                color: AppTheme.subColor,
                semanticLabel: "日历向后翻页",
              ),
              formatButtonTextStyle: TextStyle(
                fontSize: 10.sp,
                color: AppTheme.subColor,
              ),
              formatButtonDecoration: BoxDecoration(
                  border: const Border.fromBorderSide(
                    BorderSide(
                      color: AppTheme.backgroundColor1,
                    ),
                  ),
                  borderRadius: BorderRadius.all(Radius.circular(6.w))),
            ),
            daysOfWeekStyle: DaysOfWeekStyle(
              weekdayStyle: TextStyle(
                fontSize: 12.sp,
                color: AppTheme.subColor,
              ),
              weekendStyle: TextStyle(
                fontSize: 12.sp,
                fontWeight: FontWeight.bold,
                color: AppTheme.subColor,
              ),
            ),
            // 自定义界面构建
            calendarBuilders: CalendarBuilders(
              defaultBuilder: (context, day, focusedDay) {
                final List moodRecordedDate =
                    Provider.of<MoodViewModel>(context, listen: false)
                        .moodRecordedDate;
                return calenderBuilder(
                  day: day,
                  moodRecordedDate: moodRecordedDate,
                  textStyle: TextStyle(
                      color:
                          isDarkMode(context) ? Colors.white : Colors.black87),
                );
              },
              selectedBuilder: (context, day, focusedDay) {
                return calenderBuilder(
                  day: day,
                  bodyColors: [
                    Theme.of(context).primaryColor,
                    Theme.of(context).primaryColor
                  ],
                  boxShadow: [
                    BoxShadow(
                      color: Theme.of(context).primaryColor.withOpacity(0.2),
                      blurRadius: 6,
                    )
                  ],
                  textStyle: const TextStyle(color: Colors.white),
                );
              },
              outsideBuilder: (context, day, focusedDay) {
                return calenderBuilder(
                  day: day,
                  textStyle: TextStyle(
                      color: isDarkMode(context)
                          ? AppTheme.subColor.withOpacity(0.6)
                          : AppTheme.subColor),
                );
              },
              todayBuilder: (context, day, focusedDay) {
                final List moodRecordedDate =
                    Provider.of<MoodViewModel>(context, listen: false)
                        .moodRecordedDate;
                return calenderBuilder(
                  day: day,
                  moodRecordedDate: moodRecordedDate,
                  bodyColors: [
                    Theme.of(context).primaryColor.withOpacity(0.2),
                    Theme.of(context).primaryColor.withOpacity(0.2),
                  ],
                  textStyle: TextStyle(
                      color:
                          isDarkMode(context) ? Colors.white : Colors.black87),
                );
              },
              disabledBuilder: (context, day, focusedDay) {
                return calenderBuilder(
                  day: day,
                  textStyle: TextStyle(
                      color: isDarkMode(context)
                          ? const Color(0x20BFBFBF)
                          : const Color(0x50BFBFBF)),
                );
              },
            ),
            onFormatChanged: (format) {
              setState(() {
                _calendarFormat = format;
              });
            },
            availableCalendarFormats: const {
              CalendarFormat.month: '小',
              CalendarFormat.twoWeeks: '大',
              CalendarFormat.week: '中',
            },
            selectedDayPredicate: (day) {
              return isSameDay(selectedDay, day);
            },
            onDaySelected: (selectedDay, focusedDay) {
              MoodViewModel moodViewModel =
                  Provider.of<MoodViewModel>(context, listen: false);

              /// 之前选择的日期
              DateTime oldSelectedDay = moodViewModel.nowDateTime;

              /// 选择的日期相同则不操作
              if (oldSelectedDay == selectedDay) {
                return;
              }

              /// 赋值
              setState(() {
                selectedDay = selectedDay;
                focusedDay = focusedDay;
              });

              /// 赋值当前选择的日期
              moodViewModel.setNowDateTime(selectedDay);

              /// 处理赋值新日期
              String moodDatetime = selectedDay.toString().substring(0, 10);

              /// 开启加载
              moodViewModel.setMoodDataLoading(true);

              /// 获取心情数据
              MoodService.getMoodData(moodViewModel, moodDatetime);
            },
            onCalendarCreated: (pageController) {
              /// 初始化触发一次
              Future.delayed(const Duration(milliseconds: 1), () {
                pageController.previousPage(
                    duration: const Duration(milliseconds: 400),
                    curve: Curves.linearToEaseOut);
              });
              Future.delayed(const Duration(milliseconds: 2000), () {
                pageController.nextPage(
                    duration: const Duration(milliseconds: 400),
                    curve: Curves.linearToEaseOut);
              });
            },
          ),
        ),
      ),
    );
  }
}

/// 心情卡片
class MoodCard extends StatefulWidget {
  /// moodId
  final int moodId;

  /// Icon
  final String icon;

  /// 标题
  final String title;

  /// 日期时间
  final String datetime;

  /// 内容
  final String? content;

  /// 分数
  final int score;

  /// 创建日期
  final String createTime;

  const MoodCard({
    Key? key,
    required this.moodId,
    required this.icon,
    required this.title,
    required this.datetime,
    required this.content,
    required this.score,
    required this.createTime,
  }) : super(key: key);

  @override
  State<MoodCard> createState() => _MoodCardState();
}

class _MoodCardState extends State<MoodCard> {
  @override
  Widget build(BuildContext context) {
    return Slidable(
      key: widget.key,
      endActionPane: ActionPane(
        motion: const DrawerMotion(),
        children: [
          Expanded(
            child: Align(
              child: OpenContainer(
                useRootNavigator: true,
                transitionType: ContainerTransitionType.fadeThrough,
                transitionDuration: const Duration(milliseconds: 450),
                closedBuilder: (_, openContainer) {
                  return ActionButton(
                    key: const Key(
                        "widget_mood_card_slidable_action_button_edit"),
                    semanticsLabel: "编辑",
                    width: 56.w,
                    height: 56.w,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [
                          Color(0xFFD6F2E2),
                          Color(0xFFD6F2E2),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(18.w),
                    ),
                    child: const Icon(
                      Remix.edit_box_line,
                      color: Color(0xFF587966),
                    ),
                    onTap: () {
                      openContainer();
                    },
                  );
                },
                openElevation: 0,
                openColor: Theme.of(context).scaffoldBackgroundColor,
                middleColor: Theme.of(context).scaffoldBackgroundColor,
                closedElevation: 0,
                closedShape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18.w)),
                closedColor: const Color(0xFFD6F2E2),
                openBuilder: (_, closeContainer) {
                  /// 赋值编辑心情详细数据
                  MoodData moodData = MoodData();
                  moodData.moodId = widget.moodId;
                  moodData.icon = widget.icon;
                  moodData.title = widget.title;
                  moodData.score = widget.score;
                  moodData.content = widget.content;
                  moodData.createTime = widget.createTime;
                  return MoodContent(moodData: moodData);
                },
              ),
            ),
          ),
          Expanded(
            child: Align(
              child: ActionButton(
                key:
                    const Key("widget_mood_card_slidable_action_button_delete"),
                semanticsLabel: "删除",
                width: 56.w,
                height: 56.w,
                margin: EdgeInsets.only(right: 24.w),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFFFEE5E4),
                      Color(0xFFFEE5E4),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(18.w),
                ),
                child: const Icon(
                  Remix.delete_bin_line,
                  color: Color(0xFFC04A4A),
                ),
                onTap: () {
                  showCupertinoDialog<void>(
                    context: context,
                    builder: (BuildContext context) => Theme(
                      data: isDarkMode(context)
                          ? ThemeData.dark()
                          : ThemeData.light(),
                      child: CupertinoAlertDialog(
                        title:
                            Text(S.of(context).mood_data_delete_button_title),
                        content:
                            Text(S.of(context).mood_data_delete_button_content),
                        actions: <CupertinoDialogAction>[
                          CupertinoDialogAction(
                            child: Text(
                                S.of(context).mood_data_delete_button_cancel),
                            onPressed: () {
                              Navigator.pop(context);
                            },
                          ),
                          CupertinoDialogAction(
                            isDestructiveAction: true,
                            onPressed: () async {
                              MoodData moodData = MoodData();
                              moodData.moodId = widget.moodId;
                              bool result = await MoodService.delMood(moodData);
                              if (!mounted) return;
                              if (result) {
                                // 重新初始化
                                init(context);
                                Navigator.pop(context);
                              }
                            },
                            child: Text(
                                S.of(context).mood_data_delete_button_confirm),
                          )
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
      // 内容
      child: AnimatedPress(
        child: Container(
          margin:
              EdgeInsets.only(left: 24.w, right: 24.w, top: 12.w, bottom: 12.w),
          child: GestureDetector(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: 120.w,
              ),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Theme.of(context).cardColor,
                      Theme.of(context).cardColor,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(18.w),
                ),
                child: Padding(
                  padding: EdgeInsets.all(12.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      /// 头部
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          /// 标题
                          Expanded(
                            child: Row(
                              children: [
                                SizedBox(
                                  width: 48.w,
                                  height: 48.w,
                                  child: DecoratedBox(
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: isDarkMode(context)
                                            ? [
                                                const Color(0xFF2B3034),
                                                const Color(0xFF2B3034),
                                              ]
                                            : [
                                                AppTheme.backgroundColor3,
                                                AppTheme.backgroundColor3,
                                              ],
                                      ),
                                      borderRadius: BorderRadius.circular(14.w),
                                    ),
                                    child: Align(
                                      child: ExcludeSemantics(
                                        child: Text(
                                          widget.icon,
                                          style: TextStyle(fontSize: 20.w),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: Padding(
                                    padding: EdgeInsets.only(
                                      left: 12.w,
                                      right: 12.w,
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        ExcludeSemantics(
                                          child: Text(
                                            widget.title,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: Theme.of(context)
                                                .textTheme
                                                .headline1!
                                                .copyWith(
                                                  fontSize: 20.sp,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                          ),
                                        ),
                                        Padding(
                                          padding: EdgeInsets.only(top: 4.w),
                                          child: Text(
                                            widget.datetime,
                                            style: TextStyle(
                                              color: AppTheme.subColor,
                                              fontSize: 12.sp,
                                              fontWeight: FontWeight.normal,
                                            ),
                                            semanticsLabel:
                                                "${LocaleDatetime().yMMMd(widget.datetime)} 心情：${widget.title}",
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: isDarkMode(context)
                                    ? [
                                        const Color(0xFF2B3034),
                                        const Color(0xFF2B3034),
                                      ]
                                    : [
                                        AppTheme.backgroundColor3,
                                        AppTheme.backgroundColor3,
                                      ],
                              ),
                              borderRadius: BorderRadius.circular(10.w),
                            ),
                            child: SizedBox(
                              width: 42.w,
                              height: 24.w,
                              child: Align(
                                child: Text(
                                  widget.score.toString(),
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyText1!
                                      .copyWith(
                                        fontSize: 12.sp,
                                        fontWeight: FontWeight.bold,
                                      ),
                                  semanticsLabel:
                                      "${S.of(context).mood_data_score_title}：${widget.score}",
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),

                      /// 内容
                      Padding(
                        padding: EdgeInsets.only(
                          left: 60.w,
                          top: 20.w,
                          bottom: 20.w,
                        ),
                        child: Text(
                          widget.content ??
                              S.of(context).mood_data_content_empty,
                          maxLines: 5,
                          overflow: TextOverflow.ellipsis,
                          softWrap: true,
                          style: TextStyle(
                            color: widget.content != null
                                ? Theme.of(context).textTheme.bodyText1!.color
                                : AppTheme.subColor,
                            fontSize: 14.sp,
                          ),
                          semanticsLabel: widget.content != null
                              ? "记录内容：${widget.content}"
                              : "没有记录内容",
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            onTap: () {
              /// 底部详情内容弹出
              showModalBottomDetail(
                context: context,
                child: MoodDetail(
                  icon: widget.icon,
                  title: widget.title,
                  score: widget.score,
                  content: widget.content,
                  createTime: widget.createTime,
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

/// 心情详情详情展示
class MoodDetail extends StatelessWidget {
  /// 图标
  final String icon;

  /// 标题
  final String title;

  /// 分数
  final int score;

  /// 内容
  final String? content;

  /// 创建日期
  final String createTime;

  const MoodDetail({
    Key? key,
    required this.icon,
    required this.title,
    required this.score,
    required this.createTime,
    this.content,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(
        parent: BouncingScrollPhysics(),
      ),
      children: [
        Align(
          heightFactor: 2.w,
          child: Text(
            LocaleDatetime().yMMMd(createTime),
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
              color: AppTheme.subColor,
            ),
            semanticsLabel: "${LocaleDatetime().yMMMd(createTime)} 心情：$title",
          ),
        ),
        Padding(
          padding: EdgeInsets.only(
            top: 12.w,
            left: 24.w,
            right: 24.w,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              /// 心情卡片
              ExcludeSemantics(
                child: MoodChoiceCard(
                  icon: icon,
                  title: title,
                ),
              ),

              /// 打分
              Align(
                child: Column(
                  children: [
                    Padding(
                      padding: EdgeInsets.only(
                        bottom: 12.w,
                        left: 0.w,
                        right: 48.w,
                      ),
                      child: Text(
                        S.of(context).mood_data_score_title,
                        style: Theme.of(context)
                            .textTheme
                            .bodyText1!
                            .copyWith(fontSize: 16.w),
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.only(
                        left: 0.w,
                        right: 48.w,
                      ),
                      child: Text(
                        score.toString(),
                        style: Theme.of(context).textTheme.bodyText1!.copyWith(
                              fontSize: 24.w,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        /// 内容
        Padding(
          padding: EdgeInsets.only(
            top: 24.w,
            bottom: 48.w,
            left: 24.w,
            right: 24.w,
          ),
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDarkMode(context)
                    ? [
                        const Color(0xFF202427),
                        const Color(0xFF202427),
                      ]
                    : [
                        Colors.white,
                        Colors.white,
                      ],
              ),
              borderRadius: BorderRadius.circular(32.w),
            ),
            child: Padding(
              padding: EdgeInsets.only(
                top: 24.w,
                bottom: 24.w,
                left: 24.w,
                right: 24.w,
              ),
              child: Text(
                content ?? S.of(context).mood_data_content_empty,
                style: TextStyle(
                  color: content != null
                      ? isDarkMode(context)
                          ? Colors.white
                          : Colors.black87
                      : AppTheme.subColor,
                  fontSize: 14.sp,
                ),
                semanticsLabel: content != null ? "记录内容：$content" : "没有记录内容",
              ),
            ),
          ),
        ),
      ],
    );
  }
}
