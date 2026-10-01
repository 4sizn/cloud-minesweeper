// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Japanese (`ja`).
class AppLocalizationsJa extends AppLocalizations {
  AppLocalizationsJa([String locale = 'ja']) : super(locale);

  @override
  String get appName => '雲のマインスイーパー';

  @override
  String get loadErrorTitle => '図鑑を読み込めませんでした';

  @override
  String get loadErrorBody => 'これまでの雲はそのまま残っています。\n空き容量を確認してから、もう一度お試しください。';

  @override
  String get loadRetry => 'もう一度読み込む';

  @override
  String get cameraSettingsHint => '端末の設定で、雲のマインスイーパーのカメラへのアクセスをオンにしてください。';

  @override
  String get cameraSettingsFallback => 'カメラへのアクセスは端末の設定で変更できます。';

  @override
  String get howToPlay => '遊び方';

  @override
  String get closeHelp => 'ヘルプを閉じる';

  @override
  String get help1Title => '1. 雲を撮影します';

  @override
  String get help1Body =>
      '写真ごとに、かんたん・ふつう・むずかしい・エキスパートのどれかが同じ確率で決まります。同じ写真なら、形を直しても再挑戦しても難易度は変わりません。';

  @override
  String get help2Title => '2. 安全なマスを開きます';

  @override
  String get help2Body =>
      '数字は、まわりの8マスに隠れている地雷の数です。地雷がありそうなマスは、長押しするか旗モードで印をつけましょう。最初のマスは必ず安全です。';

  @override
  String get help3Title => '3. 雲を完成させます';

  @override
  String get help3Body =>
      '地雷のないマスをすべて開けたら成功です。数字のまわりに同じ数の旗を置いて数字をタップすると、残りのマスをまとめて開けます。旗がまちがっていると地雷を踏むことがあります。小さなマスは2本の指で拡大してください。';

  @override
  String get help4Title => '4. 自分だけの空に置きます';

  @override
  String get help4Body =>
      'スマホを動かして向きを選び、雲を置きましょう。雲はドラッグで動かし、近く・遠くのスライダーで距離を調整します。「端末の向き」ボタンを押すとタッチモードに切り替えられます。';

  @override
  String get privacyText =>
      '雲のマインスイーパーは、会員登録や分析のためのトラッキングなしで、端末の中で動作します。\n\n広告\nゲームに負けたときや雲を保管するときに、Google AdMob の全画面広告が表示されることがあります。AdMob は広告の表示と効果測定のために、端末識別子、IP アドレス、広告の操作などの情報を処理します。写真や雲の形が広告に使われることはありません。詳しくは Google のプライバシーポリシー（policies.google.com/privacy）をご覧ください。\n\n撮影した写真\nカメラへのアクセスは、雲の形を見つけるために使います。写真は端末の中で分析し、サーバーに送ったり写真ライブラリに保存したりすることはありません。撮影の一時ファイルは分析が終わると削除を試み、メモリ上の写真は撮影画面を閉じると解放します。予期しない終了で残った一時ファイルは、OS によって整理されます。\n\n端末の向き\nモーションセンサーは、雲を眺める方向の計算にだけ使い、記録や送信はしません。GPS の位置情報は収集しません。タッチモードに切り替えると、方向センサーの使用を停止します。\n\n端末に保存する情報\n完成した雲のマスの形、名前、収集日、プレイ時間、難易度、空での配置をアプリ内に保存します。保存を安定させるため、ひとつ前の状態のバックアップファイルも端末に置きます。OS のバックアップ設定によっては、アプリのデータが端末のバックアップに含まれることがあります。アプリを削除すると端末内のアプリデータは削除されます。OS のバックアップは、各サービスの設定で管理できます。\n\n権限とお問い合わせ\nカメラへのアクセスは、端末の設定からいつでも変更できます。お問い合わせメールを送っていただいた場合、返信のためにメールアドレスとお問い合わせ内容がメールサービスで処理されます。アプリが自動でメールを送ることはありません。\nお問い合わせ: 4sizn@naver.com\n最終更新日: 2026年9月26日';

  @override
  String get appInfo => 'アプリについて';

  @override
  String appIntro(String version) {
    return '雲を見つけて、パズルとして残しましょう。\nバージョン $version';
  }

  @override
  String get privacyTitle => 'プライバシーについて';

  @override
  String get copyEmail => 'お問い合わせメールをコピー';

  @override
  String get emailCopied => 'メールアドレスをコピーしました。';

  @override
  String get licenses => 'オープンソースライセンス';

  @override
  String difficulty(String level) {
    String _temp0 = intl.Intl.selectLogic(level, {
      'easy': 'かんたん',
      'normal': 'ふつう',
      'hard': 'むずかしい',
      'expert': 'エキスパート',
      'other': '$level',
    });
    return '$_temp0';
  }

  @override
  String difficultyBadge(int step, String level) {
    return '難易度 $step/4 · $level';
  }

  @override
  String get sensorTouchOnly => 'タッチで空を見渡せます';

  @override
  String get sensorUnavailable => '方向センサーが使えないので、タッチで見渡します';

  @override
  String get saveFailedRetryBelow => '保存できませんでした。下の「もう一度保存」を押してください。';

  @override
  String get renameTitle => '雲に名前をつける';

  @override
  String get cancel => 'キャンセル';

  @override
  String get save => '保存';

  @override
  String get collectionTitle => '集めた雲';

  @override
  String pieceCount(int count) {
    return '$count 個';
  }

  @override
  String get waitingForSpot => '置き場所を待っています';

  @override
  String get homeTagline => '雲を集める、小さな習慣';

  @override
  String get showAllClouds => 'すべての雲を見る';

  @override
  String get mySky => 'わたしの空';

  @override
  String get skyEmptySubtitle => '小さな発見が集まって、自分だけの空に。';

  @override
  String skySubtitle(int count) {
    return '$count個の雲、つづいていくわたしの物語。';
  }

  @override
  String get collectedLabel => '集めた雲';

  @override
  String get motionMode => '端末の向き';

  @override
  String get motionConnecting => '向きを接続中';

  @override
  String get touchMode => 'タッチモード';

  @override
  String get emptySkyTitle => 'あなたの空を満たしましょう';

  @override
  String get emptySkyMotion => 'スマホを動かして空を見渡してみましょう';

  @override
  String get emptySkyTouch => '空をスワイプして見渡しましょう';

  @override
  String get undoMove => '最後の移動を取り消す';

  @override
  String get hintPlaceMotion => 'スマホを動かして、雲を置く方向を探しましょう';

  @override
  String get hintPlaceTouch => '空をスワイプして、雲を置く方向を探しましょう';

  @override
  String get hintDropToSave => '指を離すと、この場所に保存されます';

  @override
  String get hintEmpty => '空で見つけて、パズルとして残しましょう';

  @override
  String get hintBrowseMotion => 'スマホを動かして見渡す · 雲はドラッグで移動';

  @override
  String get hintBrowseTouch => '空をスワイプして見渡す · 雲はドラッグで移動';

  @override
  String get unsavedChanges => '保存されていない変更があります';

  @override
  String get saveAgain => 'もう一度保存';

  @override
  String get newCloud => '新しい雲';

  @override
  String cloudPieceSemantics(String name) {
    return '$name、雲のかけら';
  }

  @override
  String get near => '近く';

  @override
  String get far => '遠く';

  @override
  String distanceSemantics(String scale) {
    return '雲の距離、基本の$scale倍';
  }

  @override
  String get renameCloud => '雲の名前を変える';

  @override
  String get findCloudDirection => '雲の方向を探す';

  @override
  String get lookAtCloud => 'この雲を眺める';

  @override
  String get meetTodaysCloud => '今日の雲に会いに行きませんか？';

  @override
  String get placeConnecting => '向きを接続中…';

  @override
  String get placeHere => 'ここに置く';

  @override
  String get findNewCloud => '新しい雲を探す';

  @override
  String get placeLaterHint => '置いたあとでも、位置と距離は変えられます';

  @override
  String directionRight(int degrees) {
    return '右 → $degrees°';
  }

  @override
  String directionLeft(int degrees) {
    return '← 左 $degrees°';
  }

  @override
  String directionUp(int degrees) {
    return '上 ↑ $degrees°';
  }

  @override
  String directionDown(int degrees) {
    return '下 ↓ $degrees°';
  }

  @override
  String get directionSearch => 'スマホをゆっくり動かして探してみましょう';

  @override
  String get cloudSaveFailed => '雲を保存できませんでした。もう一度お試しください。';

  @override
  String get exitWonTitle => '雲を保管せずに出ますか？';

  @override
  String get exitTitle => 'このゲームをやめますか？';

  @override
  String get exitBody => 'このゲームの進み具合は保存されません。集めた雲はそのまま残ります。';

  @override
  String get keepPlaying => '続ける';

  @override
  String get leave => 'やめる';

  @override
  String get backToSky => 'わたしの空に戻る';

  @override
  String get wonTitle => '雲がひとつ完成しました';

  @override
  String get lostTitle => 'もう一度、ゆっくりやってみましょう';

  @override
  String get wonBody => 'さあ、自分だけの空につなげてみましょう。';

  @override
  String get lostBody => 'この雲はまだ集めていません。';

  @override
  String get playBody => '安全なマスを開けて、雲を完成させましょう。';

  @override
  String get minesLeft => '残りの地雷';

  @override
  String get timeSpent => '経過時間';

  @override
  String get openedCells => '開いたマス';

  @override
  String get openCell => 'マスを開く';

  @override
  String get placeFlag => '旗を置く';

  @override
  String get firstCellHint => '最初のマスは安全です · 長押しでも旗を置けます';

  @override
  String get zoomHint => '小さなマスは2本の指で拡大してみましょう';

  @override
  String get keepingCloud => '雲を保管しています';

  @override
  String get placeInMySky => 'わたしの空に置く';

  @override
  String get tryAgain => 'もう一度挑戦';

  @override
  String get playEyebrow => 'ゆっくり、ひとマスずつ';

  @override
  String get cellMine => '地雷';

  @override
  String get cellFlag => '旗';

  @override
  String cellOpen(int count) {
    return '周囲の地雷 $count個';
  }

  @override
  String get cellClosed => '閉じたマス';

  @override
  String cellSemantics(int row, int col, String description) {
    return '$row行$col列、$description';
  }

  @override
  String get cameraDenied => 'カメラへのアクセスがオフになっています。\n設定でカメラへのアクセスをオンにしてください。';

  @override
  String get cameraFailed => 'カメラに接続できませんでした。\nしばらくしてからもう一度お試しください。';

  @override
  String get shotFailed => '撮影できませんでした。もう一度お試しください。';

  @override
  String get analysing => '端末の中で雲の形を分析しています。';

  @override
  String get analysisFailed => '自動分析を完了できませんでした。もう一度分析するか、雲を自分で選んでください。';

  @override
  String get findingTooDark => '暗すぎて雲を見つけにくいです。明るい空でもう一度撮ってください。';

  @override
  String get findingNoSky => '空があまり写っていません。カメラを空に向けてください。';

  @override
  String get findingNoEdge => '雲の輪郭が見つけにくいです。輪郭が見えるように撮り直すか、好きな雲を自分で選んでください。';

  @override
  String get findingNone => 'はっきりした雲が見つかりませんでした。雲が見えるように撮り直すか、自分で選んでください。';

  @override
  String get findingSmall => '雲が小さく写りました。もっと近くで撮るか、選択範囲を少し広げてください。';

  @override
  String get findingFound => '雲を自動で見つけました。形を確かめて、すぐに始めましょう。';

  @override
  String needConnectedCells(int count) {
    return 'つながった雲のマスを$count個以上選んでください。';
  }

  @override
  String get defaultCloudName => '見つけた雲';

  @override
  String get captureTitle => '今日の空を探す';

  @override
  String get foundTitle => '見つけた雲';

  @override
  String get captureHeading => '空を画面に収めてください';

  @override
  String get searchingHeading => '雲を探しています';

  @override
  String get playHeading => 'この雲で遊んでみましょうか？';

  @override
  String get captureHint => '1枚撮ると、雲の形を自動で見つけます。';

  @override
  String zoomSemantics(String scale) {
    return 'ズーム $scale倍';
  }

  @override
  String difficultySemantics(int step, String level) {
    return 'この雲の難易度 $step/4 · $level';
  }

  @override
  String selectionCount(int selected, int required) {
    return '$selectedマス選択 · つながった$requiredマス以上が必要';
  }

  @override
  String get restoreAuto => '自動選択に戻す';

  @override
  String get clearAll => 'すべて消す';

  @override
  String get paintHint => 'なぞると雲に追加され、もう一度なぞると消えます。';

  @override
  String get startWithCloud => 'この雲で始める';

  @override
  String get reanalyse => 'もう一度分析';

  @override
  String get finishEditing => '修正を終える';

  @override
  String get editShape => '形を直す';

  @override
  String get retake => '撮り直す';

  @override
  String get openSettings => '設定を開く';

  @override
  String get reconnectCamera => 'カメラに再接続';

  @override
  String get capturing => '撮影しています';

  @override
  String get captureSky => '空を撮る';

  @override
  String get difficultyRollHint => '撮影するたびに、4段階の難易度からひとつが決まります。';

  @override
  String get privacyNote => '写真は保存せず、雲の形だけを残します。\nすべての処理は端末の中で行われます。';
}
