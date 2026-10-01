import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'ads.dart';
import 'l10n/app_localizations.dart';
import 'collection.dart';
import 'app_info.dart';
import 'sky_home.dart';
import 'style.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  registerAssetLicenses();
  Ads.start();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.dark);
  runApp(const CloudApp());
}

class CloudApp extends StatelessWidget {
  const CloudApp({
    super.key,
    this.collection,
    this.enableSensors = true,
    this.capturePhoto,
  });
  final CloudCollection? collection;
  final bool enableSensors;
  final Uint8List? capturePhoto;
  @override
  Widget build(BuildContext context) => MaterialApp(
    onGenerateTitle: (context) => AppLocalizations.of(context).appName,
    debugShowCheckedModeBanner: false,
    // English first: other device languages fall back to it.
    supportedLocales: const [
      Locale('en'),
      Locale('ko'),
      Locale('ja'),
      Locale('zh'),
    ],
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    theme: ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: ink,
        primary: ink,
        surface: paper,
      ),
      scaffoldBackgroundColor: paper,
      textTheme: ThemeData.light().textTheme.apply(
        bodyColor: ink,
        displayColor: ink,
      ),
      appBarTheme: const AppBarTheme(
        foregroundColor: ink,
        centerTitle: false,
        elevation: 0,
      ),
      iconTheme: const IconThemeData(color: ink),
      snackBarTheme: const SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
      ),
    ),
    home: collection != null
        ? SkyHome(
            collection: collection!,
            enableSensors: enableSensors,
            capturePhoto: capturePhoto,
          )
        : const _LoadCollection(),
  );
}

class _LoadCollection extends StatefulWidget {
  const _LoadCollection();
  @override
  State<_LoadCollection> createState() => _LoadCollectionState();
}

class _LoadCollectionState extends State<_LoadCollection> {
  late Future<CloudCollection> loading = CloudCollection.open();
  @override
  Widget build(BuildContext context) => FutureBuilder(
    future: loading,
    builder: (context, snapshot) {
      if (snapshot.hasData) return SkyHome(collection: snapshot.data!);
      final l = AppLocalizations.of(context);
      return Scaffold(
        body: SkyBackground(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: snapshot.hasError
                  ? Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.cloud_off_outlined, size: 40),
                        const SizedBox(height: 20),
                        Text(
                          l.loadErrorTitle,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(l.loadErrorBody, textAlign: TextAlign.center),
                        const SizedBox(height: 24),
                        PrimaryButton(
                          label: l.loadRetry,
                          onPressed: () =>
                              setState(() => loading = CloudCollection.open()),
                        ),
                      ],
                    )
                  : const CircularProgressIndicator(),
            ),
          ),
        ),
      );
    },
  );
}
