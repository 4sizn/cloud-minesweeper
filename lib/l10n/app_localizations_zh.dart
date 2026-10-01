// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get appName => '云朵扫雷';

  @override
  String get loadErrorTitle => '无法载入图鉴';

  @override
  String get loadErrorBody => '之前的云朵都还好好保存着。\n请检查存储空间后再试一次。';

  @override
  String get loadRetry => '重新载入';

  @override
  String get cameraSettingsHint => '请在手机设置中为云朵扫雷开启相机权限。';

  @override
  String get cameraSettingsFallback => '你可以在手机设置中更改相机权限。';

  @override
  String get howToPlay => '玩法说明';

  @override
  String get closeHelp => '关闭帮助';

  @override
  String get help1Title => '1. 拍下一朵云';

  @override
  String get help1Body =>
      '每张照片会以相同的概率分到简单、普通、困难、专家中的一种难度。修改同一张照片或重新挑战时，难度保持不变。';

  @override
  String get help2Title => '2. 打开安全的格子';

  @override
  String get help2Body =>
      '数字表示周围 8 个格子里藏着几颗地雷。怀疑有地雷的格子，可以长按或用插旗模式标记。第一个格子总是安全的。';

  @override
  String get help3Title => '3. 完成这朵云';

  @override
  String get help3Body =>
      '打开所有没有地雷的格子就成功了。在数字周围插上相同数量的旗子后点按数字，会一起打开其余格子。旗子插错的话，可能会踩到地雷。格子太小时，可以用两根手指放大。';

  @override
  String get help4Title => '4. 放进你的天空';

  @override
  String get help4Body =>
      '转动手机选好方向，再放下云朵。拖动可以移动云朵，用“近·远”滑块调整距离。点按“设备方向”按钮可以切换到触摸模式。';

  @override
  String get privacyText =>
      '云朵扫雷无需注册，也不做分析追踪，完全在设备上运行。\n\n广告\n在游戏失败或收藏云朵时，可能会出现 Google AdMob 全屏广告。为了展示和衡量广告，AdMob 会处理设备标识符、IP 地址、广告互动等信息。照片和云朵形状不会用于广告。详情请参阅 Google 隐私权政策（policies.google.com/privacy）。\n\n拍摄的照片\n相机权限用于寻找云朵的形状。照片在设备上分析，不会发送到服务器，也不会保存到相册。分析完成后，应用会尝试删除拍摄产生的临时文件；关闭拍摄界面时，会释放内存中的照片。因意外退出而残留的临时文件由操作系统负责清理。\n\n设备方向\n运动传感器仅用于计算你望向云朵的方向，不会记录或发送。不会收集 GPS 位置。切换到触摸模式后，会停止使用方向传感器。\n\n保存在设备上的信息\n应用会在内部保存已完成云朵的格子形状、名称、收集日期、游玩时间、难度和在天空中的位置。为了保证保存可靠，设备上还会保留上一次状态的备份文件。根据操作系统的备份设置，应用数据可能会包含在设备备份中。删除应用时，设备内的应用数据会被删除；操作系统的备份可以在相应服务的设置中管理。\n\n权限与联系\n你可以随时在手机设置中更改相机权限。如果你发送咨询邮件，为了回复你，邮箱地址和咨询内容会由邮件服务处理。应用不会自动发送邮件。\n联系方式：4sizn@naver.com\n更新日期：2026年9月26日';

  @override
  String get appInfo => '关于应用';

  @override
  String appIntro(String version) {
    return '发现云朵，把它们珍藏成谜题。\n版本 $version';
  }

  @override
  String get privacyTitle => '隐私说明';

  @override
  String get copyEmail => '复制联系邮箱';

  @override
  String get emailCopied => '已复制联系邮箱。';

  @override
  String get licenses => '开源许可';

  @override
  String difficulty(String level) {
    String _temp0 = intl.Intl.selectLogic(level, {
      'easy': '简单',
      'normal': '普通',
      'hard': '困难',
      'expert': '专家',
      'other': '$level',
    });
    return '$_temp0';
  }

  @override
  String difficultyBadge(int step, String level) {
    return '难度 $step/4 · $level';
  }

  @override
  String get sensorTouchOnly => '可以用触摸来环顾天空';

  @override
  String get sensorUnavailable => '无法使用方向传感器，改用触摸来环顾';

  @override
  String get saveFailedRetryBelow => '没能保存。请点按下方的“重新保存”。';

  @override
  String get renameTitle => '给云朵起个名字';

  @override
  String get cancel => '取消';

  @override
  String get save => '保存';

  @override
  String get collectionTitle => '收集的云朵';

  @override
  String pieceCount(int count) {
    return '$count 片';
  }

  @override
  String get waitingForSpot => '等待安放位置';

  @override
  String get homeTagline => '收集云朵的小习惯';

  @override
  String get showAllClouds => '查看全部云朵';

  @override
  String get mySky => '我的天空';

  @override
  String get skyEmptySubtitle => '点滴发现，汇成你的天空。';

  @override
  String skySubtitle(int count) {
    return '$count 朵云，延续着我的故事。';
  }

  @override
  String get collectedLabel => '已收集';

  @override
  String get motionMode => '设备方向';

  @override
  String get motionConnecting => '正在连接方向';

  @override
  String get touchMode => '触摸模式';

  @override
  String get emptySkyTitle => '来填满属于你的天空吧';

  @override
  String get emptySkyMotion => '转动手机，环顾天空';

  @override
  String get emptySkyTouch => '滑动空白的天空来环顾四周';

  @override
  String get undoMove => '撤销上次移动';

  @override
  String get hintPlaceMotion => '转动手机，找找放云朵的方向';

  @override
  String get hintPlaceTouch => '滑动空白的天空，找找放云朵的方向';

  @override
  String get hintDropToSave => '松开手指，就会保存在这里';

  @override
  String get hintEmpty => '在天空中发现，珍藏成谜题';

  @override
  String get hintBrowseMotion => '转动手机环顾 · 拖动云朵来移动';

  @override
  String get hintBrowseTouch => '滑动空白天空环顾 · 拖动云朵来移动';

  @override
  String get unsavedChanges => '有尚未保存的更改';

  @override
  String get saveAgain => '重新保存';

  @override
  String get newCloud => '新云朵';

  @override
  String cloudPieceSemantics(String name) {
    return '$name，云朵碎片';
  }

  @override
  String get near => '近';

  @override
  String get far => '远';

  @override
  String distanceSemantics(String scale) {
    return '云朵距离，默认的 $scale 倍';
  }

  @override
  String get renameCloud => '重命名云朵';

  @override
  String get findCloudDirection => '寻找云朵的方向';

  @override
  String get lookAtCloud => '看向这朵云';

  @override
  String get meetTodaysCloud => '去见见今天的云朵吧？';

  @override
  String get placeConnecting => '正在连接方向…';

  @override
  String get placeHere => '放在这里';

  @override
  String get findNewCloud => '寻找新云朵';

  @override
  String get placeLaterHint => '放下后也可以更改位置和距离';

  @override
  String directionRight(int degrees) {
    return '向右 → $degrees°';
  }

  @override
  String directionLeft(int degrees) {
    return '← 向左 $degrees°';
  }

  @override
  String directionUp(int degrees) {
    return '向上 ↑ $degrees°';
  }

  @override
  String directionDown(int degrees) {
    return '向下 ↓ $degrees°';
  }

  @override
  String get directionSearch => '慢慢转动手机找找看';

  @override
  String get cloudSaveFailed => '没能保存云朵。请再试一次。';

  @override
  String get exitWonTitle => '不收藏云朵就离开吗？';

  @override
  String get exitTitle => '要离开这局游戏吗？';

  @override
  String get exitBody => '这局游戏的进度不会保存。已收集的云朵会原样保留。';

  @override
  String get keepPlaying => '继续';

  @override
  String get leave => '离开';

  @override
  String get backToSky => '回到我的天空';

  @override
  String get wonTitle => '完成了一朵云';

  @override
  String get lostTitle => '再来一次，慢慢来吧';

  @override
  String get wonBody => '现在把它拼进你的天空吧。';

  @override
  String get lostBody => '这朵云还没有收集。';

  @override
  String get playBody => '打开安全的格子，完成这朵云。';

  @override
  String get minesLeft => '剩余地雷';

  @override
  String get timeSpent => '用时';

  @override
  String get openedCells => '已打开';

  @override
  String get openCell => '打开格子';

  @override
  String get placeFlag => '插旗';

  @override
  String get firstCellHint => '第一个格子是安全的 · 长按也可以插旗';

  @override
  String get zoomHint => '格子太小时，用两根手指放大看看';

  @override
  String get keepingCloud => '正在收藏云朵';

  @override
  String get placeInMySky => '放进我的天空';

  @override
  String get tryAgain => '再次挑战';

  @override
  String get playEyebrow => '慢慢来，一格一格';

  @override
  String get cellMine => '地雷';

  @override
  String get cellFlag => '旗子';

  @override
  String cellOpen(int count) {
    return '周围有 $count 颗地雷';
  }

  @override
  String get cellClosed => '未打开的格子';

  @override
  String cellSemantics(int row, int col, String description) {
    return '第 $row 行第 $col 列，$description';
  }

  @override
  String get cameraDenied => '相机权限已关闭。\n请在设置中开启相机权限。';

  @override
  String get cameraFailed => '无法连接相机。\n请稍后再试。';

  @override
  String get shotFailed => '没能拍摄。请再试一次。';

  @override
  String get analysing => '正在设备上分析云朵的形状。';

  @override
  String get analysisFailed => '自动分析没能完成。请重新分析，或亲手选出云朵。';

  @override
  String get findingTooDark => '太暗了，很难找到云朵。请在明亮的天空下重拍。';

  @override
  String get findingNoSky => '画面里的天空不够多。请把相机对准天空。';

  @override
  String get findingNoEdge => '很难找到云朵的边缘。请重拍让边缘清晰可见，或亲手选出想要的云朵。';

  @override
  String get findingNone => '没有找到清晰的云朵。请重拍让云朵入镜，或亲手选出。';

  @override
  String get findingSmall => '云朵拍得有点小。请靠近一点拍，或把选区稍微扩大。';

  @override
  String get findingFound => '已自动找到云朵。确认形状后就开始吧。';

  @override
  String needConnectedCells(int count) {
    return '请选择至少 $count 个相连的云朵格子。';
  }

  @override
  String get defaultCloudName => '我发现的云朵';

  @override
  String get captureTitle => '寻找今天的天空';

  @override
  String get foundTitle => '找到的云朵';

  @override
  String get captureHeading => '把天空收进画面里吧';

  @override
  String get searchingHeading => '正在寻找云朵';

  @override
  String get playHeading => '用这朵云来玩吧？';

  @override
  String get captureHint => '拍一张照片，就会自动找出云朵的形状。';

  @override
  String zoomSemantics(String scale) {
    return '放大 $scale 倍';
  }

  @override
  String difficultySemantics(int step, String level) {
    return '这朵云的难度 $step/4 · $level';
  }

  @override
  String selectionCount(int selected, int required) {
    return '已选 $selected 格 · 需要至少 $required 个相连格子';
  }

  @override
  String get restoreAuto => '恢复自动选择';

  @override
  String get clearAll => '全部清除';

  @override
  String get paintHint => '涂抹云朵来添加，再涂一次即可擦除。';

  @override
  String get startWithCloud => '用这朵云开始';

  @override
  String get reanalyse => '重新分析';

  @override
  String get finishEditing => '完成修改';

  @override
  String get editShape => '修改形状';

  @override
  String get retake => '重新拍摄';

  @override
  String get openSettings => '打开设置';

  @override
  String get reconnectCamera => '重新连接相机';

  @override
  String get capturing => '正在拍摄';

  @override
  String get captureSky => '拍下天空';

  @override
  String get difficultyRollHint => '每次拍摄都会从 4 个难度中定下一个。';

  @override
  String get privacyNote => '不会保存照片，只留下云朵的形状。\n所有处理都在设备上完成。';
}
