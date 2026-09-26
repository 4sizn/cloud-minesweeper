import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'style.dart';

const supportEmail = '4sizn@naver.com';
const appVersion = '1.0.0';

Future<void> openDeviceSettings(BuildContext context) async {
  try {
    await const MethodChannel('cloud_minesweeper/settings')
        .invokeMethod<void>('openSettings');
  } on PlatformException {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('휴대폰 설정에서 지뢰찾기:구름의 카메라 권한을 켜주세요.')),
      );
    }
  } on MissingPluginException {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('휴대폰 설정에서 카메라 권한을 변경할 수 있어요.')),
      );
    }
  }
}

void registerAssetLicenses() {
  LicenseRegistry.addLicense(() async* {
    for (final entry in {
      'U²-Net': 'U2NET.txt',
      'U²-Net sky model': 'U2NET-sky.txt',
      'COCO-Stuff attribution': 'COCO-STUFF-attribution.txt',
      'COCO-Stuff license': 'CC-BY-4.0.txt',
    }.entries) {
      yield LicenseEntryWithLineBreaks([
        entry.key,
      ], await rootBundle.loadString('assets/licenses/${entry.value}'));
    }
  });
}

Future<void> showPlayHelp(BuildContext context) => showModalBottomSheet<void>(
  context: context,
  showDragHandle: true,
  isScrollControlled: true,
  useSafeArea: true,
  backgroundColor: paper,
  builder: (sheetContext) => SafeArea(
    child: SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(24, 8, 24, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  '플레이 방법',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
                ),
              ),
              IconButton(
                tooltip: '도움말 닫기',
                onPressed: () => Navigator.pop(sheetContext),
                icon: const Icon(Icons.close),
              ),
            ],
          ),
          SizedBox(height: 20),
          Text('1. 구름을 촬영해요', style: TextStyle(fontWeight: FontWeight.w700)),
          Text(
            '사진마다 쉬움·보통·어려움·전문가 중 하나가 같은 확률로 정해져요. 같은 사진의 수정과 재도전에서는 난이도가 유지돼요.',
          ),
          SizedBox(height: 18),
          Text('2. 안전한 칸을 열어요', style: TextStyle(fontWeight: FontWeight.w700)),
          Text(
            '숫자는 주변 8칸에 숨어 있는 지뢰 수예요. 지뢰가 의심되는 칸은 길게 누르거나 깃발 모드로 표시하세요. 첫 칸은 항상 안전해요.',
          ),
          SizedBox(height: 18),
          Text('3. 구름을 완성해요', style: TextStyle(fontWeight: FontWeight.w700)),
          Text(
            '지뢰가 없는 칸을 모두 열면 성공이에요. 숫자 칸 주위에 같은 수의 깃발을 놓고 숫자를 누르면 나머지 칸을 함께 열어요. 깃발이 틀리면 지뢰를 밟을 수 있어요. 작은 칸은 두 손가락으로 확대하세요.',
          ),
          SizedBox(height: 18),
          Text('4. 나만의 하늘에 놓아요', style: TextStyle(fontWeight: FontWeight.w700)),
          Text(
            '휴대폰을 돌려 방향을 고르고 구름을 놓으세요. 구름은 드래그로 옮기고, 가까이·멀리 슬라이더로 거리를 조절해요. 기기 방향 버튼을 누르면 터치 모드로 바꿀 수 있어요.',
          ),
        ],
      ),
    ),
  ),
);

const privacyText = '''지뢰찾기:구름은 회원가입과 분석용 추적 없이 기기 안에서 동작합니다.

광고
게임에서 졌을 때와 구름을 보관할 때 Google AdMob 전면 광고가 나올 수 있습니다. AdMob은 광고를 보여주고 측정하기 위해 기기 식별자, IP 주소, 광고 상호작용 같은 정보를 처리합니다. 사진과 구름 모양은 광고에 쓰지 않습니다. 자세한 내용은 Google 개인정보처리방침(policies.google.com/privacy)을 참고하세요.

촬영 사진
카메라 권한은 구름 모양을 찾는 데 사용합니다. 사진은 기기 안에서 분석하며 서버로 보내거나 사진 보관함에 저장하지 않습니다. 촬영 임시 파일은 분석 처리가 끝나면 삭제를 시도하고, 메모리에 남은 사진은 촬영 화면을 닫으면 해제합니다. 예기치 않은 종료로 남은 임시 파일은 운영체제의 정리 대상입니다.

기기 방향
모션 센서는 구름을 바라보는 방향 계산에만 사용하며 기록하거나 전송하지 않습니다. GPS 위치를 수집하지 않습니다. 터치 모드로 전환하면 방향 센서 사용을 중단합니다.

기기에 저장하는 정보
완성한 구름의 칸 모양, 이름, 수집 날짜, 플레이 시간, 난이도, 하늘 배치를 앱 내부에 저장합니다. 저장 안정성을 위해 직전 상태의 백업 파일도 기기에 둡니다. 운영체제 백업 설정에 따라 앱 데이터가 기기 백업에 포함될 수 있습니다. 앱 삭제 시 기기 내부 앱 데이터가 삭제되며, 운영체제 백업은 해당 서비스의 설정에서 관리할 수 있습니다.

권한과 문의
카메라 권한은 휴대폰 설정에서 언제든 변경할 수 있습니다. 문의 메일을 직접 보내면 답변을 위해 이메일 주소와 문의 내용이 이메일 서비스에서 처리됩니다. 앱에서 메일을 자동 전송하지 않습니다.
문의: 4sizn@naver.com
안내 갱신일: 2026년 9월 26일''';

class AppInfoScreen extends StatelessWidget {
  const AppInfoScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('앱 안내')),
    body: ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const Text(
          '지뢰찾기:구름',
          style: TextStyle(fontSize: 30, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        const Text('구름을 발견하고, 퍼즐로 간직해요.\n버전 $appVersion'),
        const SizedBox(height: 24),
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.help_outline),
          title: const Text('플레이 방법'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => showPlayHelp(context),
        ),
        ExpansionTile(
          tilePadding: EdgeInsets.zero,
          leading: const Icon(Icons.privacy_tip_outlined),
          title: const Text('개인정보 처리 안내'),
          children: const [
            Padding(
              padding: EdgeInsets.only(bottom: 20),
              child: SelectableText(privacyText, style: TextStyle(height: 1.6)),
            ),
          ],
        ),
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.mail_outline),
          title: const Text('문의 이메일 복사'),
          subtitle: const Text(supportEmail),
          trailing: const Icon(Icons.copy_outlined),
          onTap: () async {
            await Clipboard.setData(const ClipboardData(text: supportEmail));
            if (context.mounted) {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('문의 이메일을 복사했어요.')));
            }
          },
        ),
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.description_outlined),
          title: const Text('오픈소스 라이선스'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => showLicensePage(
            context: context,
            applicationName: '지뢰찾기:구름',
            applicationVersion: appVersion,
          ),
        ),
      ],
    ),
  );
}
