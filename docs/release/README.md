# 1.0.0 출시 준비

2026-09-21. 앱 코드·실기기 검증 준비와 스토어 제출을 구분한다. 아직 App Store에 업로드하지 않았다.

## 반영한 제품 변경

- 샘플 시작 버튼 2곳과 샘플 선택 화면 제거. 사진 촬영을 기본 진입점으로 통일.
- 홈의 개발용 각도 숫자, 빈 도감의 거리 조절·비활성 도감 버튼 제거.
- 자동 판독 결과의 편집 도구를 ‘모양 수정’ 안으로 정리. 자동 판독 실패 시 수동 편집 제공.
- 사진마다 4단계 난이도를 균등 무작위 배정. 수정·재분석·재도전에서는 유지.
- 난이도·성공 기록 저장, 기존 도감 호환, 게임 이탈 확인, 플레이 방법 추가.
- 카메라 권한 거부 시 시스템 앱 설정으로 이동. 일시적 연결 실패는 재연결 제공.
- 문의 `4sizn@naver.com`, 개인정보 처리 안내, 번들 모델·오픈소스 라이선스 추가.
- 기본 Flutter 아이콘을 [새 앱 아이콘](../../assets/branding/app-icon.png)으로 교체.
- iOS 개인정보 매니페스트와 면제 암호화 선언 추가. 파일 정보는 앱 내부 저장,
  부팅 시간 관련 API는 플레이 경과 시간 측정에만 사용한다.

## 난이도 규칙

| 단계 | 표시 | 지뢰 비율 | 사진별 배정 확률 |
|---|---|---|---|
| 1 | 쉬움 | 8% | 25% |
| 2 | 보통 | 12% | 25% |
| 3 | 어려움 | 17% | 25% |
| 4 | 전문가 | 22% | 25% |

비율은 선택된 구름 칸 수에 적용하고 내림한다. 첫 칸 안전 보장은 모든 난이도에서 동일하다.
같은 난이도가 연속으로 배정될 수 있다. 기존 도감 기록은 ‘보통’으로 복원한다.

## 출시 전에 확정해야 하는 항목

1. **모델 사용권한:** 현재 구름 모델은 SWIMSEG로 학습했고 원본은
   [CC BY-NC 4.0](https://creativecommons.org/licenses/by-nc/4.0/)이다.
   [원 제공자 안내](https://malea.winkler.site/swimseg.html)에서 확인했다.
   상업 목적 배포라면 별도 허가 또는 사용권한이 맞는 모델·데이터로 교체해야 한다.
   판독 정확도가 낮았던 이전 방식으로 임의 되돌리지 않았다. 현재 모델 사용 범위에 대한 최종 판단은 미확정이다.
2. **공개 페이지 URL:** [개인정보 처리방침](privacy.html)과 [지원 안내](support.html) 파일은 작성했다.
   실제 공개 HTTPS 주소에 게시한 뒤 App Store Connect에 등록해야 한다. 가짜 URL을 넣지 않았다.
   [Apple 안내](https://developer.apple.com/help/app-store-connect/manage-app-information/manage-app-privacy)는
   개인정보 처리방침 URL을 요구한다. 지원·개인정보 링크와 완성된 앱 제출 요건은
   [App Review 안내](https://developer.apple.com/app-store/review/)를 확인했다.
3. **운영자 정보:** 문의 이메일은 확정. 운영자명은 아직 제공받지 않아 임의 기재하지 않았다.
4. **스토어 배포:** 계정의 배포 서명, 앱 등록, 설명·연령 등급·개인정보 응답,
   TestFlight 및 심사 제출은 아직 하지 않았다. 현재 실기기 개발 서명을 스토어 배포 서명으로 간주하지 않는다.
5. **기기 검증 범위:** 실제 야외 카메라·권한 거부 후 복구와 다양한 기기 방향·발열을 추가 확인한다.
   Android 코드는 포함하지만 이 Mac에 Android SDK가 없어 Android 빌드·실기기 검증은 미완료다.

## 개인정보 선언 근거

- 서버·분석·광고 SDK·계정·추적 없음. 사진과 모션을 서버로 전송하지 않음.
- 사진 처리가 끝나면 촬영 임시 파일 삭제를 시도하고, 저장 실패·비정상 종료의 한계도 안내한다.
- 기기 내부 도감과 직전 상태 백업, 운영체제 백업 가능성을 설명한다.
- 이메일 문의는 사용자가 직접 보낸 경우에만 메일 서비스에서 처리한다.
- [Apple의 허용 API 사용 사유](https://developer.apple.com/documentation/bundleresources/app-privacy-configuration/nsprivacyaccessedapitypes/nsprivacyaccessedapitypereasons):
  앱 컨테이너 파일 정보 C617.1, 앱 내 경과 시간 35F9.1.
- [암호화 선언](https://developer.apple.com/documentation/security/complying-with-encryption-export-regulations):
  자체 비면제 암호화 구현 없음. `ITSAppUsesNonExemptEncryption=false`.

## 검증 자료

[화면 점검](../production/audit.md), [자동 검사·실기기 결과](../verification.md).
[아이콘 생성 방식과 프롬프트](../../assets/branding/README.md).
