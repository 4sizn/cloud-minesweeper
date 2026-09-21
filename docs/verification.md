# 1.0.0 출시 준비 검증

검증일: 2026-09-21. Flutter 3.47.5 / Dart 3.13.4 / Xcode 26.6.

- `flutter analyze`: 문제 없음. `flutter test`: **19개 통과**.
- 4개 난이도별 지뢰 수·첫 클릭 주변 안전·승리 가능, 균등 무작위 배정 경로 검증.
- 같은 사진의 분석 실패 후 재시도, 같은 게임 재도전에서 난이도 유지 확인.
- 난이도와 거리 저장·복원, 이전 도감 필드 누락 시 기본값 호환 확인.
- 390×844 / 320×640 화면과 작은 화면의 글씨 130% 확대 확인.
- 도움말 열기·닫기, 진행 중 나가기 취소·확인, 카메라 실패 재연결 안내 확인.
- iPhone 17 Pro / iOS 26.5에서 `integration_test/regression_test.dart` **5개 시나리오 통과**:
  검증 사진 3장의 모바일 추론 일치, 실제 사진→게임, 맑은 하늘·어두운 사진·분석 중 종료,
  방향별 배경 픽셀 변화, 두 사진의 승리→수집→거리 배치→드래그→복원.
- iOS 앱 아이콘 1024×1024·알파 없음 확인. iOS 개인정보 매니페스트와 Info.plist 구문 검사 통과.
- 최종 `integration_test/app_test.dart` 추가 실행 통과: 도움말 닫기, 문의 이메일 복사,
  번들 모델 라이선스 표시까지 실제 iOS UI로 확인. 최종 화면 캡처 직접 검토.
- 21:16 KST, iPhone 15 Pro / iOS 26.6.1에 **1.0.0(5)** 릴리스 업데이트 설치·실행 성공.
  설치 버전·실행 프로세스, 릴리스 번들 내 개인정보 매니페스트·암호화 선언 확인.
  기존 도감을 삭제하지 않았고 실기기에 테스트 번들을 설치하지 않았다. 스토어 제출은 하지 않았다.

구름 학습 모델은 이 버전에서 변경하지 않았다. 현재 모델의 사용권한과 실제 공개 개인정보·지원 URL,
운영자명·스토어 등록 등은 [출시 전 남은 항목](release/README.md)에 기록했다.
실제 야외 사진 다양성, 카메라 권한 거부 후 실기기 복구, VoiceOver 전체 검증과 Android 빌드는 아직 남아 있다.

# 0.1.3 검증 결과

검증일: 2026-09-21. 구름별 거리 조절 추가.

- `flutter analyze`: 문제 없음. `flutter test`: 16개 통과.
- 390×844 / 320×640 화면에서 미리보기·배치 대기·수집 구름의 거리 조절 확인.
- 거리를 늘리면 화면 중심은 유지하고 크기는 거리의 역수로 변함.
- 가까운 구름부터 선택되고, 거리 변경 후 겹침 순서도 갱신됨.
- 저장·복원·되돌리기, 기존 거리 필드가 없는 도감의 기본값 1 유지 확인.
- 6배 거리의 작은 구름도 처음 닿은 조각을 기준으로 드래그됨.
- iPhone 17 Pro / iOS 26.5 시뮬레이터의 `integration_test/app_test.dart` 통과:
  게임 승리 → 거리 조절 → 배치 → 작은 구름 드래그 → 되돌리기 → 두 번째 구름 수집 → 재로딩.
- `screenshots/depth-placement.png`, `screenshots/two-clouds.png` 직접 검토.
- 사진 판독 모델은 변경하지 않았으며 해당 iOS 추론 검증은 아래 0.1.2 결과를 유지한다.
- 20:53 KST, iPhone 15 Pro에 **0.1.3(4)** 릴리스 업데이트 설치·실행 성공.
  설치 버전과 실행 프로세스 확인. 실기기에 통합 테스트 앱을 설치하거나 도감을 삭제하지 않았다.

```sh
flutter analyze
flutter test
flutter build ios --simulator --debug --target=integration_test/app_test.dart
flutter drive --driver=test_driver/integration_test.dart \
  --target=integration_test/app_test.dart \
  --use-application-binary=build/ios/iphonesimulator/Runner.app -d <simulator-id>
```

# 0.1.2 검증 결과

검증일: 2026-09-21. Flutter 3.47.5 / Dart 3.13.4 / Xcode 26.6.

## 구름 판독

- 공개 SWIMSEG 1,013장 다운로드, 26장 중복 제외, 촬영 날짜별 분리 후 구름 전용 모델 학습.
- 별도 평가 347장: 셀 IoU **51.2% → 79.8%**, 최종 구름 조각 IoU **35.0% → 60.3%**.
- 검증 사진 0443 / 0478 / 0487을 실제 iOS ONNX 런타임으로 추론.
  Python 평가와 최종 선택 셀 집합이 각각 정확히 일치: 103칸 / 0칸 / 179칸.
- 실제 풍경 사진 입력 → 자동 85칸 선택 → `camera-auto` 게임 시작 통과.
- 맑은 파란색 / 검정 이미지에서 잘못된 게임 생성 없음. 분석 중 화면 종료 안전.
- EXIF 회전, 사진/입력의 동일 중앙 크롭, 밝은 지면 제거, 가장 큰 연결 영역,
  보드 여백 제거 검증.
- 모델 파일과 iOS 테스트 앱에 포함된 파일의 SHA-256 일치 확인.

자세한 데이터·분할·학습·라이선스·전체 지표는 [판독 검증 보고서](cloud-evaluation.md).
낮 하늘 패치의 영역 일치도이며 실제 iPhone 야외 촬영 정답률을 의미하지 않는다.

## 기기 방향과 화면 이동

- 실제 iPhone Core Motion 쿼터니언 업데이트 수신 확인. 사용자도 각도 숫자 변화 확인.
- 사용자 피드백으로 첫 화면의 안내 구름과 배경이 고정 이미지였음을 확인하고 수정.
- 미리보기 구름도 최초 바라본 방향에 놓고, 이후 센서 방향으로 화면 좌표를 계산.
- 배경은 같은 방향 행렬을 쓰는 하늘 돔으로 렌더링. 별도 라이브러리 없이 Flutter shader 사용.
- 실제 iOS 형식의 센서 이벤트를 주입한 위젯 테스트: 미리보기/수집 구름의 화면 이동,
  뒤쪽 구름 숨김, 빈 곳 드래그·핀치·도감 선택 후 방향 모드 유지, 화면 복귀 시 재구독 통과.
- 시뮬레이터 GPU 렌더링 테스트: 북쪽/동쪽에서 실제 배경 픽셀 변화,
  360° 회전 후 원래 이미지로 복귀 통과. 숫자만 변경되는 테스트가 아님.
- 화면 밖 선택 구름의 좌우/상하 방향 안내. 터치 모드 전환은 모드 버튼으로 명시적으로 실행.

## 자동 검사

- `flutter analyze`: 문제 없음.
- `flutter test`: 14개 통과 (게임·저장·좌표 6, 화면 배치 2, 사진 5, 센서/제스처 1).
- `integration_test/regression_test.dart`: iPhone 17 Pro / iOS 26.5 시뮬레이터에서 5개 시나리오 통과.
  사진 3개 시나리오, 배경 렌더링 1개, 게임 승리→수집→배치→드래그→되돌리기→복원 1개.
- 390×844 / 320×640 논리 화면에서 빈 도감·샘플 선택 오버플로 없음.
- 캡처 `screenshots/empty.png`, `photo-auto-selection.png`, `photo-generated-game.png`,
  `sky-north.png`, `sky-east.png`, `two-clouds.png` 등을 직접 검토.

```sh
flutter analyze
flutter test
flutter build ios --simulator --debug --target=integration_test/regression_test.dart
flutter drive --driver=test_driver/integration_test.dart \
  --target=integration_test/regression_test.dart \
  --use-application-binary=build/ios/iphonesimulator/Runner.app -d <simulator-id>
```

테스트용 앱은 **시뮬레이터에만 설치**했다. 사용자의 실기기 앱을 테스트 번들로 대체하거나
도감을 삭제하지 않았다. Xcode 결과물과 실행 결과의 테스트 이름을 확인해 오래된 앱으로
검사 결과를 잘못 기록하지 않았다.

## 남은 검증 범위

- 최신 버전의 실제 iPhone 야외 카메라 사진을 다양한 날씨에서 평가.
- 센서의 자기 북쪽 절대 정확도, 다양한 롤·기울임과 장시간 발열·배터리.
- Android: SDK가 없어 빌드·실기기 검증하지 못함.
- 학습 데이터가 CC BY-NC이므로 현재 구름 모델은 비상업 개발용. 상용 출시에 별도 조치 필요.

## 실기기 배포

- 2026-09-21 20:38 KST, iPhone 15 Pro / iOS 26.6.1에 **0.1.2(3)** 릴리스 설치·실행 성공.
- `devicectl device info apps`로 설치 버전 확인. 릴리스 번들 내 구름 모델 SHA-256도 평가한 파일과 일치.
- 이번 설치는 기존 앱 업데이트이며 사용자 도감을 삭제하거나 테스트 데이터로 덮어쓰지 않음.
- 수정 전 실기기 센서 숫자 변화 확인 후, **0.1.2에서 구름 그림과 하늘 배경이 모두 움직인다고 사용자 확인을 받음** (20:39 KST).
