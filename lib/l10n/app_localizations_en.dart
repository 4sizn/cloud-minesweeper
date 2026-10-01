// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'Cloud Minesweeper';

  @override
  String get loadErrorTitle => 'Couldn\'t open your collection';

  @override
  String get loadErrorBody =>
      'Your clouds are still safely kept.\nCheck your storage space and try again.';

  @override
  String get loadRetry => 'Reload';

  @override
  String get cameraSettingsHint =>
      'Please turn on camera access for Cloud Minesweeper in your phone\'s Settings.';

  @override
  String get cameraSettingsFallback =>
      'You can change camera access in your phone\'s Settings.';

  @override
  String get howToPlay => 'How to play';

  @override
  String get closeHelp => 'Close help';

  @override
  String get help1Title => '1. Photograph a cloud';

  @override
  String get help1Body =>
      'Each photo gets Easy, Normal, Hard or Expert, all equally likely. Editing the shape or retrying the same photo keeps its difficulty.';

  @override
  String get help2Title => '2. Open the safe cells';

  @override
  String get help2Body =>
      'A number shows how many mines hide in the 8 cells around it. Mark a cell you suspect with a long press or in flag mode. Your first cell is always safe.';

  @override
  String get help3Title => '3. Complete the cloud';

  @override
  String get help3Body =>
      'Open every cell without a mine and you\'re done. When a number has that many flags around it, tap the number to open the rest at once. If a flag is wrong, you may hit a mine. Pinch with two fingers to zoom in on small cells.';

  @override
  String get help4Title => '4. Place it in your sky';

  @override
  String get help4Body =>
      'Turn your phone to choose a direction, then place the cloud. Drag clouds to move them, and use the Near–Far slider to set their distance. Tap the Motion mode button to switch to touch mode.';

  @override
  String get privacyText =>
      'Cloud Minesweeper runs on your device, with no sign-up and no analytics tracking.\n\nAds\nA Google AdMob full-screen ad may appear when you lose a game or keep a cloud. To show and measure ads, AdMob processes information such as device identifiers, IP address and ad interactions. Your photos and cloud shapes are never used for ads. For details, see the Google Privacy Policy (policies.google.com/privacy).\n\nPhotos\nCamera access is used to find cloud shapes. Photos are analysed on your device. They are not sent to a server or saved to your photo library. The app tries to delete the temporary capture file once analysis finishes, and releases the photo from memory when you close the capture screen. Temporary files left behind by an unexpected shutdown are cleaned up by the operating system.\n\nDevice orientation\nThe motion sensor is used only to work out which way you are looking at your clouds. Its data is not recorded or sent anywhere. GPS location is not collected. Switching to touch mode stops the use of the orientation sensor.\n\nInformation stored on your device\nFor each cloud you complete, the app stores its cell shape, name, collection date, play time, difficulty and place in your sky inside the app. For reliable saving, a backup of the previous state is also kept on the device. Depending on your operating system\'s backup settings, app data may be included in device backups. Deleting the app removes its data from the device. Operating system backups can be managed in that service\'s settings.\n\nPermissions and contact\nYou can change camera access at any time in your phone\'s Settings. If you email us, your email address and message are processed by your email service so we can reply. The app never sends email on its own.\nContact: 4sizn@naver.com\nLast updated: September 26, 2026';

  @override
  String get appInfo => 'About';

  @override
  String appIntro(String version) {
    return 'Find clouds, and keep them as puzzles.\nVersion $version';
  }

  @override
  String get privacyTitle => 'Privacy';

  @override
  String get copyEmail => 'Copy contact email';

  @override
  String get emailCopied => 'Contact email copied.';

  @override
  String get licenses => 'Open source licenses';

  @override
  String difficulty(String level) {
    String _temp0 = intl.Intl.selectLogic(level, {
      'easy': 'Easy',
      'normal': 'Normal',
      'hard': 'Hard',
      'expert': 'Expert',
      'other': '$level',
    });
    return '$_temp0';
  }

  @override
  String difficultyBadge(int step, String level) {
    return 'Difficulty $step/4 · $level';
  }

  @override
  String get sensorTouchOnly => 'You can look around the sky by touch';

  @override
  String get sensorUnavailable =>
      'The motion sensor isn\'t available, so look around by touch';

  @override
  String get saveFailedRetryBelow =>
      'Couldn\'t save. Please tap Save again below.';

  @override
  String get renameTitle => 'Name this cloud';

  @override
  String get cancel => 'Cancel';

  @override
  String get save => 'Save';

  @override
  String get collectionTitle => 'Your clouds';

  @override
  String pieceCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count pieces',
      one: '1 piece',
    );
    return '$_temp0';
  }

  @override
  String get waitingForSpot => 'Waiting for a spot';

  @override
  String get homeTagline => 'A small habit of collecting clouds';

  @override
  String get showAllClouds => 'Show all clouds';

  @override
  String get mySky => 'My sky';

  @override
  String get skyEmptySubtitle =>
      'Small finds, gathering into a sky of your own.';

  @override
  String skySubtitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count clouds, and my story goes on.',
      one: '1 cloud, and my story goes on.',
    );
    return '$_temp0';
  }

  @override
  String get collectedLabel => 'collected';

  @override
  String get motionMode => 'Motion mode';

  @override
  String get motionConnecting => 'Connecting motion';

  @override
  String get touchMode => 'Touch mode';

  @override
  String get emptySkyTitle => 'Fill a sky of your own';

  @override
  String get emptySkyMotion => 'Turn your phone to look around the sky';

  @override
  String get emptySkyTouch => 'Swipe the empty sky to look around';

  @override
  String get undoMove => 'Undo last move';

  @override
  String get hintPlaceMotion => 'Turn your phone to find a spot for the cloud';

  @override
  String get hintPlaceTouch =>
      'Swipe the empty sky to find a spot for the cloud';

  @override
  String get hintDropToSave => 'Let go to save it here';

  @override
  String get hintEmpty => 'Find it in the sky, keep it as a puzzle';

  @override
  String get hintBrowseMotion =>
      'Turn your phone to look around · Drag clouds to move them';

  @override
  String get hintBrowseTouch =>
      'Swipe the empty sky to look around · Drag clouds to move them';

  @override
  String get unsavedChanges => 'Some changes aren\'t saved';

  @override
  String get saveAgain => 'Save again';

  @override
  String get newCloud => 'New cloud';

  @override
  String cloudPieceSemantics(String name) {
    return '$name, cloud piece';
  }

  @override
  String get near => 'Near';

  @override
  String get far => 'Far';

  @override
  String distanceSemantics(String scale) {
    return 'Cloud distance, $scale× the default';
  }

  @override
  String get renameCloud => 'Rename cloud';

  @override
  String get findCloudDirection => 'Find this cloud\'s direction';

  @override
  String get lookAtCloud => 'Look at this cloud';

  @override
  String get meetTodaysCloud => 'Shall we go meet today\'s cloud?';

  @override
  String get placeConnecting => 'Connecting motion…';

  @override
  String get placeHere => 'Place here';

  @override
  String get findNewCloud => 'Find a new cloud';

  @override
  String get placeLaterHint => 'You can change its position and distance later';

  @override
  String directionRight(int degrees) {
    return 'Right → $degrees°';
  }

  @override
  String directionLeft(int degrees) {
    return '← Left $degrees°';
  }

  @override
  String directionUp(int degrees) {
    return 'Up ↑ $degrees°';
  }

  @override
  String directionDown(int degrees) {
    return 'Down ↓ $degrees°';
  }

  @override
  String get directionSearch => 'Turn your phone slowly to find it';

  @override
  String get cloudSaveFailed => 'Couldn\'t save the cloud. Please try again.';

  @override
  String get exitWonTitle => 'Leave without keeping the cloud?';

  @override
  String get exitTitle => 'Leave this game?';

  @override
  String get exitBody =>
      'This game\'s progress won\'t be saved. The clouds you\'ve collected stay as they are.';

  @override
  String get keepPlaying => 'Keep playing';

  @override
  String get leave => 'Leave';

  @override
  String get backToSky => 'Back to my sky';

  @override
  String get wonTitle => 'You completed a cloud';

  @override
  String get lostTitle => 'Let\'s try again, slowly';

  @override
  String get wonBody => 'Now add it to a sky of your own.';

  @override
  String get lostBody => 'This cloud isn\'t collected yet.';

  @override
  String get playBody => 'Open the safe cells to complete the cloud.';

  @override
  String get minesLeft => 'Mines left';

  @override
  String get timeSpent => 'Time';

  @override
  String get openedCells => 'Opened';

  @override
  String get openCell => 'Open';

  @override
  String get placeFlag => 'Flag';

  @override
  String get firstCellHint =>
      'Your first cell is safe · Long-press to place a flag too';

  @override
  String get zoomHint => 'Pinch with two fingers to zoom in on small cells';

  @override
  String get keepingCloud => 'Keeping your cloud';

  @override
  String get placeInMySky => 'Place in my sky';

  @override
  String get tryAgain => 'Try again';

  @override
  String get playEyebrow => 'Slowly, one cell at a time';

  @override
  String get cellMine => 'Mine';

  @override
  String get cellFlag => 'Flag';

  @override
  String cellOpen(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count mines around',
      one: '1 mine around',
      zero: 'No mines around',
    );
    return '$_temp0';
  }

  @override
  String get cellClosed => 'Closed cell';

  @override
  String cellSemantics(int row, int col, String description) {
    return 'Row $row, column $col, $description';
  }

  @override
  String get cameraDenied =>
      'Camera access is turned off.\nPlease turn it on in Settings.';

  @override
  String get cameraFailed =>
      'Couldn\'t connect to the camera.\nPlease try again in a moment.';

  @override
  String get shotFailed => 'Couldn\'t take the photo. Please try again.';

  @override
  String get analysing => 'Finding the cloud\'s shape on your device.';

  @override
  String get analysisFailed =>
      'Couldn\'t finish the automatic analysis. Analyse again or pick the cloud yourself.';

  @override
  String get findingTooDark =>
      'It\'s too dark to find a cloud. Please try again under a brighter sky.';

  @override
  String get findingNoSky =>
      'Not enough sky is showing. Please point the camera at the sky.';

  @override
  String get findingNoEdge =>
      'It\'s hard to find the cloud\'s edges. Take another photo that shows them, or pick the cloud you want yourself.';

  @override
  String get findingNone =>
      'Couldn\'t find a clear cloud. Take another photo with a cloud in view, or pick one yourself.';

  @override
  String get findingSmall =>
      'The cloud came out small. Take a closer photo or widen the selection a little.';

  @override
  String get findingFound =>
      'Found the cloud for you. Check the shape and start right away.';

  @override
  String needConnectedCells(int count) {
    return 'Please pick at least $count connected cloud cells.';
  }

  @override
  String get defaultCloudName => 'A cloud I found';

  @override
  String get captureTitle => 'Find today\'s sky';

  @override
  String get foundTitle => 'The cloud you found';

  @override
  String get captureHeading => 'Frame the sky on screen';

  @override
  String get searchingHeading => 'Looking for the cloud';

  @override
  String get playHeading => 'Shall we play with this cloud?';

  @override
  String get captureHint =>
      'Take one photo and the cloud\'s shape is found for you.';

  @override
  String zoomSemantics(String scale) {
    return 'Zoom $scale×';
  }

  @override
  String difficultySemantics(int step, String level) {
    return 'This cloud\'s difficulty: $step/4 · $level';
  }

  @override
  String selectionCount(int selected, int required) {
    String _temp0 = intl.Intl.pluralLogic(
      selected,
      locale: localeName,
      other: '$selected cells selected',
      one: '1 cell selected',
    );
    return '$_temp0 · needs $required+ connected';
  }

  @override
  String get restoreAuto => 'Restore auto selection';

  @override
  String get clearAll => 'Clear all';

  @override
  String get paintHint =>
      'Paint over the cloud to add it, paint again to erase.';

  @override
  String get startWithCloud => 'Start with this cloud';

  @override
  String get reanalyse => 'Analyse again';

  @override
  String get finishEditing => 'Done editing';

  @override
  String get editShape => 'Edit shape';

  @override
  String get retake => 'Retake';

  @override
  String get openSettings => 'Open Settings';

  @override
  String get reconnectCamera => 'Reconnect camera';

  @override
  String get capturing => 'Taking the photo';

  @override
  String get captureSky => 'Capture the sky';

  @override
  String get difficultyRollHint =>
      'Each photo gets one of four difficulty levels.';

  @override
  String get privacyNote =>
      'Photos aren\'t kept, only the cloud\'s shape.\nEverything happens on your device.';
}
