import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ja.dart';
import 'app_localizations_ko.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('ja'),
    Locale('ko'),
    Locale('zh'),
  ];

  /// No description provided for @appName.
  ///
  /// In ko, this message translates to:
  /// **'지뢰찾기:구름'**
  String get appName;

  /// No description provided for @loadErrorTitle.
  ///
  /// In ko, this message translates to:
  /// **'도감을 불러오지 못했어요'**
  String get loadErrorTitle;

  /// No description provided for @loadErrorBody.
  ///
  /// In ko, this message translates to:
  /// **'기존 구름은 그대로 보관하고 있어요.\n저장 공간을 확인한 뒤 다시 시도해주세요.'**
  String get loadErrorBody;

  /// No description provided for @loadRetry.
  ///
  /// In ko, this message translates to:
  /// **'다시 불러오기'**
  String get loadRetry;

  /// No description provided for @cameraSettingsHint.
  ///
  /// In ko, this message translates to:
  /// **'휴대폰 설정에서 지뢰찾기:구름의 카메라 권한을 켜주세요.'**
  String get cameraSettingsHint;

  /// No description provided for @cameraSettingsFallback.
  ///
  /// In ko, this message translates to:
  /// **'휴대폰 설정에서 카메라 권한을 변경할 수 있어요.'**
  String get cameraSettingsFallback;

  /// No description provided for @howToPlay.
  ///
  /// In ko, this message translates to:
  /// **'플레이 방법'**
  String get howToPlay;

  /// No description provided for @closeHelp.
  ///
  /// In ko, this message translates to:
  /// **'도움말 닫기'**
  String get closeHelp;

  /// No description provided for @help1Title.
  ///
  /// In ko, this message translates to:
  /// **'1. 구름을 촬영해요'**
  String get help1Title;

  /// No description provided for @help1Body.
  ///
  /// In ko, this message translates to:
  /// **'사진마다 쉬움·보통·어려움·전문가 중 하나가 같은 확률로 정해져요. 같은 사진의 수정과 재도전에서는 난이도가 유지돼요.'**
  String get help1Body;

  /// No description provided for @help2Title.
  ///
  /// In ko, this message translates to:
  /// **'2. 안전한 칸을 열어요'**
  String get help2Title;

  /// No description provided for @help2Body.
  ///
  /// In ko, this message translates to:
  /// **'숫자는 주변 8칸에 숨어 있는 지뢰 수예요. 지뢰가 의심되는 칸은 길게 누르거나 깃발 모드로 표시하세요. 첫 칸은 항상 안전해요.'**
  String get help2Body;

  /// No description provided for @help3Title.
  ///
  /// In ko, this message translates to:
  /// **'3. 구름을 완성해요'**
  String get help3Title;

  /// No description provided for @help3Body.
  ///
  /// In ko, this message translates to:
  /// **'지뢰가 없는 칸을 모두 열면 성공이에요. 숫자 칸 주위에 같은 수의 깃발을 놓고 숫자를 누르면 나머지 칸을 함께 열어요. 깃발이 틀리면 지뢰를 밟을 수 있어요. 작은 칸은 두 손가락으로 확대하세요.'**
  String get help3Body;

  /// No description provided for @help4Title.
  ///
  /// In ko, this message translates to:
  /// **'4. 나만의 하늘에 놓아요'**
  String get help4Title;

  /// No description provided for @help4Body.
  ///
  /// In ko, this message translates to:
  /// **'휴대폰을 돌려 방향을 고르고 구름을 놓으세요. 구름은 드래그로 옮기고, 가까이·멀리 슬라이더로 거리를 조절해요. 기기 방향 버튼을 누르면 터치 모드로 바꿀 수 있어요.'**
  String get help4Body;

  /// No description provided for @privacyText.
  ///
  /// In ko, this message translates to:
  /// **'지뢰찾기:구름은 회원가입과 분석용 추적 없이 기기 안에서 동작합니다.\n\n광고\n게임에서 졌을 때와 구름을 보관할 때 Google AdMob 전면 광고가 나올 수 있습니다. AdMob은 광고를 보여주고 측정하기 위해 기기 식별자, IP 주소, 광고 상호작용 같은 정보를 처리합니다. 사진과 구름 모양은 광고에 쓰지 않습니다. 자세한 내용은 Google 개인정보처리방침(policies.google.com/privacy)을 참고하세요.\n\n촬영 사진\n카메라 권한은 구름 모양을 찾는 데 사용합니다. 사진은 기기 안에서 분석하며 서버로 보내거나 사진 보관함에 저장하지 않습니다. 촬영 임시 파일은 분석 처리가 끝나면 삭제를 시도하고, 메모리에 남은 사진은 촬영 화면을 닫으면 해제합니다. 예기치 않은 종료로 남은 임시 파일은 운영체제의 정리 대상입니다.\n\n기기 방향\n모션 센서는 구름을 바라보는 방향 계산에만 사용하며 기록하거나 전송하지 않습니다. GPS 위치를 수집하지 않습니다. 터치 모드로 전환하면 방향 센서 사용을 중단합니다.\n\n기기에 저장하는 정보\n완성한 구름의 칸 모양, 이름, 수집 날짜, 플레이 시간, 난이도, 하늘 배치를 앱 내부에 저장합니다. 저장 안정성을 위해 직전 상태의 백업 파일도 기기에 둡니다. 운영체제 백업 설정에 따라 앱 데이터가 기기 백업에 포함될 수 있습니다. 앱 삭제 시 기기 내부 앱 데이터가 삭제되며, 운영체제 백업은 해당 서비스의 설정에서 관리할 수 있습니다.\n\n권한과 문의\n카메라 권한은 휴대폰 설정에서 언제든 변경할 수 있습니다. 문의 메일을 직접 보내면 답변을 위해 이메일 주소와 문의 내용이 이메일 서비스에서 처리됩니다. 앱에서 메일을 자동 전송하지 않습니다.\n문의: 4sizn@naver.com\n안내 갱신일: 2026년 9월 26일'**
  String get privacyText;

  /// No description provided for @appInfo.
  ///
  /// In ko, this message translates to:
  /// **'앱 안내'**
  String get appInfo;

  /// No description provided for @appIntro.
  ///
  /// In ko, this message translates to:
  /// **'구름을 발견하고, 퍼즐로 간직해요.\n버전 {version}'**
  String appIntro(String version);

  /// No description provided for @privacyTitle.
  ///
  /// In ko, this message translates to:
  /// **'개인정보 처리 안내'**
  String get privacyTitle;

  /// No description provided for @copyEmail.
  ///
  /// In ko, this message translates to:
  /// **'문의 이메일 복사'**
  String get copyEmail;

  /// No description provided for @emailCopied.
  ///
  /// In ko, this message translates to:
  /// **'문의 이메일을 복사했어요.'**
  String get emailCopied;

  /// No description provided for @licenses.
  ///
  /// In ko, this message translates to:
  /// **'오픈소스 라이선스'**
  String get licenses;

  /// No description provided for @difficulty.
  ///
  /// In ko, this message translates to:
  /// **'{level, select, easy{쉬움} normal{보통} hard{어려움} expert{전문가} other{{level}}}'**
  String difficulty(String level);

  /// No description provided for @difficultyBadge.
  ///
  /// In ko, this message translates to:
  /// **'난이도 {step}/4 · {level}'**
  String difficultyBadge(int step, String level);

  /// No description provided for @sensorTouchOnly.
  ///
  /// In ko, this message translates to:
  /// **'터치로 하늘을 둘러볼 수 있어요'**
  String get sensorTouchOnly;

  /// No description provided for @sensorUnavailable.
  ///
  /// In ko, this message translates to:
  /// **'방향 센서를 사용할 수 없어 터치로 둘러봐요'**
  String get sensorUnavailable;

  /// No description provided for @saveFailedRetryBelow.
  ///
  /// In ko, this message translates to:
  /// **'저장하지 못했어요. 아래의 다시 저장을 눌러주세요.'**
  String get saveFailedRetryBelow;

  /// No description provided for @renameTitle.
  ///
  /// In ko, this message translates to:
  /// **'구름에 이름 붙이기'**
  String get renameTitle;

  /// No description provided for @cancel.
  ///
  /// In ko, this message translates to:
  /// **'취소'**
  String get cancel;

  /// No description provided for @save.
  ///
  /// In ko, this message translates to:
  /// **'저장'**
  String get save;

  /// No description provided for @collectionTitle.
  ///
  /// In ko, this message translates to:
  /// **'모아온 구름'**
  String get collectionTitle;

  /// No description provided for @pieceCount.
  ///
  /// In ko, this message translates to:
  /// **'{count} 조각'**
  String pieceCount(int count);

  /// No description provided for @waitingForSpot.
  ///
  /// In ko, this message translates to:
  /// **'놓을 자리 기다리는 중'**
  String get waitingForSpot;

  /// No description provided for @homeTagline.
  ///
  /// In ko, this message translates to:
  /// **'구름을 모으는 작은 습관'**
  String get homeTagline;

  /// No description provided for @showAllClouds.
  ///
  /// In ko, this message translates to:
  /// **'모든 구름 보기'**
  String get showAllClouds;

  /// No description provided for @mySky.
  ///
  /// In ko, this message translates to:
  /// **'나의 하늘'**
  String get mySky;

  /// No description provided for @skyEmptySubtitle.
  ///
  /// In ko, this message translates to:
  /// **'작은 발견들이 모여, 나만의 하늘로.'**
  String get skyEmptySubtitle;

  /// No description provided for @skySubtitle.
  ///
  /// In ko, this message translates to:
  /// **'{count}개의 구름, 이어지는 나의 이야기.'**
  String skySubtitle(int count);

  /// No description provided for @collectedLabel.
  ///
  /// In ko, this message translates to:
  /// **'모은 구름'**
  String get collectedLabel;

  /// No description provided for @motionMode.
  ///
  /// In ko, this message translates to:
  /// **'기기 방향'**
  String get motionMode;

  /// No description provided for @motionConnecting.
  ///
  /// In ko, this message translates to:
  /// **'방향 연결 중'**
  String get motionConnecting;

  /// No description provided for @touchMode.
  ///
  /// In ko, this message translates to:
  /// **'터치 모드'**
  String get touchMode;

  /// No description provided for @emptySkyTitle.
  ///
  /// In ko, this message translates to:
  /// **'나만의 하늘을 채워보세요'**
  String get emptySkyTitle;

  /// No description provided for @emptySkyMotion.
  ///
  /// In ko, this message translates to:
  /// **'휴대폰을 돌려 하늘을 둘러보세요'**
  String get emptySkyMotion;

  /// No description provided for @emptySkyTouch.
  ///
  /// In ko, this message translates to:
  /// **'빈 하늘을 밀어 둘러보세요'**
  String get emptySkyTouch;

  /// No description provided for @undoMove.
  ///
  /// In ko, this message translates to:
  /// **'마지막 이동 되돌리기'**
  String get undoMove;

  /// No description provided for @hintPlaceMotion.
  ///
  /// In ko, this message translates to:
  /// **'휴대폰을 돌려 구름을 놓을 방향을 찾아보세요'**
  String get hintPlaceMotion;

  /// No description provided for @hintPlaceTouch.
  ///
  /// In ko, this message translates to:
  /// **'빈 하늘을 밀어 구름을 놓을 방향을 찾아보세요'**
  String get hintPlaceTouch;

  /// No description provided for @hintDropToSave.
  ///
  /// In ko, this message translates to:
  /// **'손을 놓으면 이 자리에 저장돼요'**
  String get hintDropToSave;

  /// No description provided for @hintEmpty.
  ///
  /// In ko, this message translates to:
  /// **'하늘에서 발견하고, 퍼즐로 간직해요'**
  String get hintEmpty;

  /// No description provided for @hintBrowseMotion.
  ///
  /// In ko, this message translates to:
  /// **'휴대폰을 돌려 둘러보고 · 구름은 끌어서 옮겨요'**
  String get hintBrowseMotion;

  /// No description provided for @hintBrowseTouch.
  ///
  /// In ko, this message translates to:
  /// **'빈 하늘을 밀어 둘러보고 · 구름은 끌어서 옮겨요'**
  String get hintBrowseTouch;

  /// No description provided for @unsavedChanges.
  ///
  /// In ko, this message translates to:
  /// **'저장되지 않은 변경이 있어요'**
  String get unsavedChanges;

  /// No description provided for @saveAgain.
  ///
  /// In ko, this message translates to:
  /// **'다시 저장'**
  String get saveAgain;

  /// No description provided for @newCloud.
  ///
  /// In ko, this message translates to:
  /// **'새 구름'**
  String get newCloud;

  /// No description provided for @cloudPieceSemantics.
  ///
  /// In ko, this message translates to:
  /// **'{name}, 구름 조각'**
  String cloudPieceSemantics(String name);

  /// No description provided for @near.
  ///
  /// In ko, this message translates to:
  /// **'가까이'**
  String get near;

  /// No description provided for @far.
  ///
  /// In ko, this message translates to:
  /// **'멀리'**
  String get far;

  /// No description provided for @distanceSemantics.
  ///
  /// In ko, this message translates to:
  /// **'구름 거리, 기본의 {scale}배'**
  String distanceSemantics(String scale);

  /// No description provided for @renameCloud.
  ///
  /// In ko, this message translates to:
  /// **'구름 이름 바꾸기'**
  String get renameCloud;

  /// No description provided for @findCloudDirection.
  ///
  /// In ko, this message translates to:
  /// **'구름 방향 찾기'**
  String get findCloudDirection;

  /// No description provided for @lookAtCloud.
  ///
  /// In ko, this message translates to:
  /// **'이 구름 바라보기'**
  String get lookAtCloud;

  /// No description provided for @meetTodaysCloud.
  ///
  /// In ko, this message translates to:
  /// **'오늘의 구름을 만나러 갈까요?'**
  String get meetTodaysCloud;

  /// No description provided for @placeConnecting.
  ///
  /// In ko, this message translates to:
  /// **'방향 연결 중…'**
  String get placeConnecting;

  /// No description provided for @placeHere.
  ///
  /// In ko, this message translates to:
  /// **'여기에 놓기'**
  String get placeHere;

  /// No description provided for @findNewCloud.
  ///
  /// In ko, this message translates to:
  /// **'새 구름 찾기'**
  String get findNewCloud;

  /// No description provided for @placeLaterHint.
  ///
  /// In ko, this message translates to:
  /// **'놓은 뒤에도 위치와 거리를 바꿀 수 있어요'**
  String get placeLaterHint;

  /// No description provided for @directionRight.
  ///
  /// In ko, this message translates to:
  /// **'오른쪽 → {degrees}°'**
  String directionRight(int degrees);

  /// No description provided for @directionLeft.
  ///
  /// In ko, this message translates to:
  /// **'← 왼쪽 {degrees}°'**
  String directionLeft(int degrees);

  /// No description provided for @directionUp.
  ///
  /// In ko, this message translates to:
  /// **'위 ↑ {degrees}°'**
  String directionUp(int degrees);

  /// No description provided for @directionDown.
  ///
  /// In ko, this message translates to:
  /// **'아래 ↓ {degrees}°'**
  String directionDown(int degrees);

  /// No description provided for @directionSearch.
  ///
  /// In ko, this message translates to:
  /// **'휴대폰을 천천히 돌려 찾아보세요'**
  String get directionSearch;

  /// No description provided for @cloudSaveFailed.
  ///
  /// In ko, this message translates to:
  /// **'구름을 저장하지 못했어요. 다시 시도해주세요.'**
  String get cloudSaveFailed;

  /// No description provided for @exitWonTitle.
  ///
  /// In ko, this message translates to:
  /// **'구름을 보관하지 않고 나갈까요?'**
  String get exitWonTitle;

  /// No description provided for @exitTitle.
  ///
  /// In ko, this message translates to:
  /// **'이번 게임에서 나갈까요?'**
  String get exitTitle;

  /// No description provided for @exitBody.
  ///
  /// In ko, this message translates to:
  /// **'이 게임의 진행 상황은 저장되지 않아요. 모아둔 구름은 그대로 유지돼요.'**
  String get exitBody;

  /// No description provided for @keepPlaying.
  ///
  /// In ko, this message translates to:
  /// **'계속하기'**
  String get keepPlaying;

  /// No description provided for @leave.
  ///
  /// In ko, this message translates to:
  /// **'나가기'**
  String get leave;

  /// No description provided for @backToSky.
  ///
  /// In ko, this message translates to:
  /// **'내 하늘로 돌아가기'**
  String get backToSky;

  /// No description provided for @wonTitle.
  ///
  /// In ko, this message translates to:
  /// **'구름 하나를 완성했어요'**
  String get wonTitle;

  /// No description provided for @lostTitle.
  ///
  /// In ko, this message translates to:
  /// **'다시, 천천히 해볼까요'**
  String get lostTitle;

  /// No description provided for @wonBody.
  ///
  /// In ko, this message translates to:
  /// **'이제 나만의 하늘에 이어 붙여보세요.'**
  String get wonBody;

  /// No description provided for @lostBody.
  ///
  /// In ko, this message translates to:
  /// **'이번 구름은 아직 모으지 않았어요.'**
  String get lostBody;

  /// No description provided for @playBody.
  ///
  /// In ko, this message translates to:
  /// **'안전한 칸을 열어 구름을 완성하세요.'**
  String get playBody;

  /// No description provided for @minesLeft.
  ///
  /// In ko, this message translates to:
  /// **'남은 지뢰'**
  String get minesLeft;

  /// No description provided for @timeSpent.
  ///
  /// In ko, this message translates to:
  /// **'보낸 시간'**
  String get timeSpent;

  /// No description provided for @openedCells.
  ///
  /// In ko, this message translates to:
  /// **'열린 칸'**
  String get openedCells;

  /// No description provided for @openCell.
  ///
  /// In ko, this message translates to:
  /// **'칸 열기'**
  String get openCell;

  /// No description provided for @placeFlag.
  ///
  /// In ko, this message translates to:
  /// **'깃발 놓기'**
  String get placeFlag;

  /// No description provided for @firstCellHint.
  ///
  /// In ko, this message translates to:
  /// **'첫 칸은 안전해요 · 길게 눌러도 깃발을 놓을 수 있어요'**
  String get firstCellHint;

  /// No description provided for @zoomHint.
  ///
  /// In ko, this message translates to:
  /// **'작은 칸은 두 손가락으로 확대해보세요'**
  String get zoomHint;

  /// No description provided for @keepingCloud.
  ///
  /// In ko, this message translates to:
  /// **'구름을 보관하고 있어요'**
  String get keepingCloud;

  /// No description provided for @placeInMySky.
  ///
  /// In ko, this message translates to:
  /// **'내 하늘에 놓기'**
  String get placeInMySky;

  /// No description provided for @tryAgain.
  ///
  /// In ko, this message translates to:
  /// **'다시 도전'**
  String get tryAgain;

  /// No description provided for @playEyebrow.
  ///
  /// In ko, this message translates to:
  /// **'천천히, 한 칸씩'**
  String get playEyebrow;

  /// No description provided for @cellMine.
  ///
  /// In ko, this message translates to:
  /// **'지뢰'**
  String get cellMine;

  /// No description provided for @cellFlag.
  ///
  /// In ko, this message translates to:
  /// **'깃발'**
  String get cellFlag;

  /// No description provided for @cellOpen.
  ///
  /// In ko, this message translates to:
  /// **'주변 지뢰 {count}개'**
  String cellOpen(int count);

  /// No description provided for @cellClosed.
  ///
  /// In ko, this message translates to:
  /// **'닫힌 칸'**
  String get cellClosed;

  /// No description provided for @cellSemantics.
  ///
  /// In ko, this message translates to:
  /// **'{row}행 {col}열, {description}'**
  String cellSemantics(int row, int col, String description);

  /// No description provided for @cameraDenied.
  ///
  /// In ko, this message translates to:
  /// **'카메라 접근이 꺼져 있어요.\n설정에서 카메라 권한을 켜주세요.'**
  String get cameraDenied;

  /// No description provided for @cameraFailed.
  ///
  /// In ko, this message translates to:
  /// **'카메라를 연결하지 못했어요.\n잠시 후 다시 시도해주세요.'**
  String get cameraFailed;

  /// No description provided for @shotFailed.
  ///
  /// In ko, this message translates to:
  /// **'촬영하지 못했어요. 다시 시도해주세요.'**
  String get shotFailed;

  /// No description provided for @analysing.
  ///
  /// In ko, this message translates to:
  /// **'기기 안에서 구름 모양을 분석하고 있어요.'**
  String get analysing;

  /// No description provided for @analysisFailed.
  ///
  /// In ko, this message translates to:
  /// **'자동 분석을 마치지 못했어요. 다시 분석하거나 구름을 직접 골라주세요.'**
  String get analysisFailed;

  /// No description provided for @findingTooDark.
  ///
  /// In ko, this message translates to:
  /// **'너무 어두워 구름을 찾기 어려워요. 밝은 하늘에서 다시 찍어주세요.'**
  String get findingTooDark;

  /// No description provided for @findingNoSky.
  ///
  /// In ko, this message translates to:
  /// **'하늘이 충분히 보이지 않아요. 카메라를 하늘로 향해주세요.'**
  String get findingNoSky;

  /// No description provided for @findingNoEdge.
  ///
  /// In ko, this message translates to:
  /// **'구름의 경계를 찾기 어려워요. 경계가 보이게 다시 찍거나 원하는 구름을 직접 골라주세요.'**
  String get findingNoEdge;

  /// No description provided for @findingNone.
  ///
  /// In ko, this message translates to:
  /// **'뚜렷한 구름을 찾지 못했어요. 구름이 보이게 다시 찍거나 직접 골라주세요.'**
  String get findingNone;

  /// No description provided for @findingSmall.
  ///
  /// In ko, this message translates to:
  /// **'구름이 작게 잡혔어요. 더 가까이 찍거나 선택 영역을 조금 넓혀주세요.'**
  String get findingSmall;

  /// No description provided for @findingFound.
  ///
  /// In ko, this message translates to:
  /// **'구름을 자동으로 찾았어요. 모양을 확인하고 바로 시작하세요.'**
  String get findingFound;

  /// No description provided for @needConnectedCells.
  ///
  /// In ko, this message translates to:
  /// **'서로 이어진 구름 칸을 {count}개 이상 골라주세요.'**
  String needConnectedCells(int count);

  /// No description provided for @defaultCloudName.
  ///
  /// In ko, this message translates to:
  /// **'내가 찾은 구름'**
  String get defaultCloudName;

  /// No description provided for @captureTitle.
  ///
  /// In ko, this message translates to:
  /// **'오늘의 하늘 찾기'**
  String get captureTitle;

  /// No description provided for @foundTitle.
  ///
  /// In ko, this message translates to:
  /// **'찾아낸 구름'**
  String get foundTitle;

  /// No description provided for @captureHeading.
  ///
  /// In ko, this message translates to:
  /// **'하늘을 화면에 담아주세요'**
  String get captureHeading;

  /// No description provided for @searchingHeading.
  ///
  /// In ko, this message translates to:
  /// **'구름을 찾고 있어요'**
  String get searchingHeading;

  /// No description provided for @playHeading.
  ///
  /// In ko, this message translates to:
  /// **'이 구름으로 놀아볼까요?'**
  String get playHeading;

  /// No description provided for @captureHint.
  ///
  /// In ko, this message translates to:
  /// **'한 장 찍으면 구름 모양을 자동으로 찾아요.'**
  String get captureHint;

  /// No description provided for @zoomSemantics.
  ///
  /// In ko, this message translates to:
  /// **'확대 {scale}배'**
  String zoomSemantics(String scale);

  /// No description provided for @difficultySemantics.
  ///
  /// In ko, this message translates to:
  /// **'이번 구름 난이도 {step}/4 · {level}'**
  String difficultySemantics(int step, String level);

  /// No description provided for @selectionCount.
  ///
  /// In ko, this message translates to:
  /// **'{selected}칸 선택 · 연결된 {required}칸 이상 필요'**
  String selectionCount(int selected, int required);

  /// No description provided for @restoreAuto.
  ///
  /// In ko, this message translates to:
  /// **'자동 선택 복원'**
  String get restoreAuto;

  /// No description provided for @clearAll.
  ///
  /// In ko, this message translates to:
  /// **'전체 지우기'**
  String get clearAll;

  /// No description provided for @paintHint.
  ///
  /// In ko, this message translates to:
  /// **'구름을 칠해 추가하고, 다시 칠해 지워요.'**
  String get paintHint;

  /// No description provided for @startWithCloud.
  ///
  /// In ko, this message translates to:
  /// **'이 구름으로 시작'**
  String get startWithCloud;

  /// No description provided for @reanalyse.
  ///
  /// In ko, this message translates to:
  /// **'다시 분석'**
  String get reanalyse;

  /// No description provided for @finishEditing.
  ///
  /// In ko, this message translates to:
  /// **'수정 마치기'**
  String get finishEditing;

  /// No description provided for @editShape.
  ///
  /// In ko, this message translates to:
  /// **'모양 수정'**
  String get editShape;

  /// No description provided for @retake.
  ///
  /// In ko, this message translates to:
  /// **'다시 촬영'**
  String get retake;

  /// No description provided for @openSettings.
  ///
  /// In ko, this message translates to:
  /// **'설정 열기'**
  String get openSettings;

  /// No description provided for @reconnectCamera.
  ///
  /// In ko, this message translates to:
  /// **'카메라 다시 연결'**
  String get reconnectCamera;

  /// No description provided for @capturing.
  ///
  /// In ko, this message translates to:
  /// **'촬영하고 있어요'**
  String get capturing;

  /// No description provided for @captureSky.
  ///
  /// In ko, this message translates to:
  /// **'하늘 담기'**
  String get captureSky;

  /// No description provided for @difficultyRollHint.
  ///
  /// In ko, this message translates to:
  /// **'촬영할 때마다 4단계 난이도 중 하나가 정해져요.'**
  String get difficultyRollHint;

  /// No description provided for @privacyNote.
  ///
  /// In ko, this message translates to:
  /// **'사진은 보관하지 않고 구름 모양만 남겨요.\n모든 과정은 기기 안에서 이루어져요.'**
  String get privacyNote;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'ja', 'ko', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'ja':
      return AppLocalizationsJa();
    case 'ko':
      return AppLocalizationsKo();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
