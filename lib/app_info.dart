import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'l10n/app_localizations.dart';
import 'style.dart';

const supportEmail = '4sizn@naver.com';
const appVersion = '1.0.2';

Future<void> openDeviceSettings(BuildContext context) async {
  try {
    await const MethodChannel('cloud_minesweeper/settings')
        .invokeMethod<void>('openSettings');
  } on PlatformException {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).cameraSettingsHint),
        ),
      );
    }
  } on MissingPluginException {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).cameraSettingsFallback),
        ),
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
  builder: (sheetContext) {
    final l = AppLocalizations.of(sheetContext);
    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(24, 8, 24, 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    l.howToPlay,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: l.closeHelp,
                  onPressed: () => Navigator.pop(sheetContext),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            SizedBox(height: 20),
            Text(
              l.help1Title,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            Text(l.help1Body),
            SizedBox(height: 18),
            Text(
              l.help2Title,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            Text(l.help2Body),
            SizedBox(height: 18),
            Text(
              l.help3Title,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            Text(l.help3Body),
            SizedBox(height: 18),
            Text(
              l.help4Title,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            Text(l.help4Body),
          ],
        ),
      ),
    );
  },
);

class AppInfoScreen extends StatelessWidget {
  const AppInfoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l.appInfo)),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text(
            l.appName,
            style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(l.appIntro(appVersion)),
          const SizedBox(height: 24),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.help_outline),
            title: Text(l.howToPlay),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => showPlayHelp(context),
          ),
          ExpansionTile(
            tilePadding: EdgeInsets.zero,
            leading: const Icon(Icons.privacy_tip_outlined),
            title: Text(l.privacyTitle),
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 20),
                child: SelectableText(
                  l.privacyText,
                  style: const TextStyle(height: 1.6),
                ),
              ),
            ],
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.mail_outline),
            title: Text(l.copyEmail),
            subtitle: const Text(supportEmail),
            trailing: const Icon(Icons.copy_outlined),
            onTap: () async {
              await Clipboard.setData(const ClipboardData(text: supportEmail));
              if (context.mounted) {
                ScaffoldMessenger.of(context)
                    .showSnackBar(SnackBar(content: Text(l.emailCopied)));
              }
            },
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.description_outlined),
            title: Text(l.licenses),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => showLicensePage(
              context: context,
              applicationName: l.appName,
              applicationVersion: appVersion,
            ),
          ),
        ],
      ),
    );
  }
}
