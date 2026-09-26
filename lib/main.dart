import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'ads.dart';
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
    title: '지뢰찾기:구름',
    debugShowCheckedModeBanner: false,
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
                        const Text(
                          '도감을 불러오지 못했어요',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          '기존 구름은 그대로 보관하고 있어요.\n저장 공간을 확인한 뒤 다시 시도해주세요.',
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                        PrimaryButton(
                          label: '다시 불러오기',
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
