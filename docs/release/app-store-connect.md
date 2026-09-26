# App Store Connect 등록 자료

2026-09-21 작성. App Store Connect 앱 등록 화면과 1.0 버전 페이지에 그대로 붙여 넣을 값입니다.
앱 레코드(`6814490793`)를 만들고 이름·부제·설명·키워드·프로모션 텍스트·스크린샷까지 API로 올렸습니다.
확정되지 않은 항목은 "미확정"으로 표시했습니다.

## 앱 등록 (New App)

| 항목 | 값 |
|---|---|
| 플랫폼 | iOS |
| 이름 | 지뢰찾기:구름 |
| 기본 언어 | 한국어 |
| 번들 ID | `com.lotus.cloudMinesweeper` (Team VN497S6KK3) |
| SKU | `cloud-minesweeper-ios` |
| 사용자 액세스 | 전체 액세스 |

번들 ID는 Developer 포털의 Identifiers에 먼저 등록되어 있어야 목록에 나타납니다.

## 스토어 등록 정보 (한국어)

**부제 (30자 이내)**

```
오늘 하늘을 오래 간직하는 법
```

**프로모션 텍스트 (170자 이내)**

```
오늘 하늘이 예뻐서 찍었어요. 그 사진이 나만의 판이 되고, 풀어낸 구름은 도감에 남아요. 걸어둔 방향을 바라보면 그 하늘을 다시 만나요.
```

**설명**

```
오늘 하늘이 예뻤나요? 그냥 지나치기 아까운 날엔 한 장 찍어 두세요.
사진 속 구름이 그대로 오늘의 판이 됩니다.

네모반듯한 격자 대신, 그날 그 시간의 구름 윤곽을 따라 판이 만들어져요.
같은 하늘은 두 번 오지 않으니, 판도 매번 다릅니다.

■ 그날의 하늘로 만든 판
카메라로 하늘을 찍으면 구름 영역을 알아서 찾아 판을 만들어요.
모양이 마음에 들지 않으면 손으로 다듬어도 됩니다.

■ 천천히 해도 괜찮아요
첫 칸은 언제나 안전해요. 사진마다 쉬움부터 전문가까지 무작위로 정해지니
잘 풀리는 날도, 오래 붙잡는 날도 있습니다.

■ 지나간 하늘이 한 장씩
풀어낸 구름은 도감에 남아요. 언제 어떤 하늘이었는지, 얼마나 걸렸는지 함께 남습니다.

■ 걸어둔 구름을 다시 만나요
모은 구름을 휴대폰이 향한 방향에 걸어 둘 수 있어요.
동쪽에 둔 구름은 동쪽을 바라볼 때 다시 나타납니다.

■ 조용하게, 나에게만
사진과 구름 판독은 모두 휴대폰 안에서 끝납니다.
사진을 서버로 보내지 않고, 계정도 추적도 없어요.
```

**키워드 (100자 이내, 쉼표 구분, 공백 없음)**

```
마인스위퍼,하늘,사진퍼즐,수집,도감,카메라,오프라인,싱글,두뇌훈련,캐주얼,힐링,사진게임,혼자하는,무료게임,모으기
```

이름(`지뢰찾기`, `구름`)에 있는 단어는 키워드에 넣지 않았다. 반복은 순위에 도움이 되지 않고 자리만 쓴다.

**새로운 소식 (1.0)**

```
첫 출시입니다. 하늘 사진으로 지뢰찾기 판을 만들고, 풀어낸 구름을 나만의 하늘에 걸어 보세요.
```

**URL**

| 항목 | 값 |
|---|---|
| 지원 URL | `https://www.letspets.co.kr` (등록 완료) |
| 마케팅 URL | 없음 (선택) |
| 개인정보 처리방침 URL | `https://www.letspets.co.kr/privacy` (등록 완료) |

개인정보 처리방침은 letspets 브랜드 사이트(`4sizn/lotus-brandsite`)의 `/privacy` 한 페이지가
이 개발자의 모든 앱을 함께 다룹니다. 지뢰찾기:구름 항목(적용 범위, 카메라·방향 센서 권한,
기기 저장 정보, App Store 배포)을 추가해 `main`에 푸시했습니다.
저장소의 `docs/release/privacy.html`·`support.html`은 초안이며 게시하지 않습니다.

**분류**

| 항목 | 값 |
|---|---|
| 기본 카테고리 | 게임 > 퍼즐 |
| 보조 카테고리 | 게임 > 캐주얼 |
| 저작권 | 미확정 — 운영자명 필요 (예: `2026 <운영자명>`) |

## 연령 등급 설문 답변

모든 폭력·성적 표현·약물·도박 항목 **없음**, 무제한 웹 접근 **아니요**, 사용자 생성 콘텐츠 공유 **아니요**.
사용자가 찍은 사진은 기기 안에만 남고 다른 사용자에게 공유되지 않습니다. 예상 등급: 4+.

## 앱 개인정보 (App Privacy) 답변

- 데이터 수집: **수집하지 않음**. 서버·분석·광고 SDK·계정·추적이 없습니다.
- 사진과 모션 센서 값은 기기 안에서만 쓰고 전송하지 않습니다.
- 근거와 API 사용 사유는 [출시 준비 문서](README.md)의 "개인정보 선언 근거" 참조.
- 앱 내 개인정보 매니페스트: 파일 정보 `C617.1`, 경과 시간 `35F9.1`.

## 빌드·제출 설정

| 항목 | 값 |
|---|---|
| 버전 | 1.0.0 (빌드 7, 심사 대기 중) · 빌드 8 업로드됨, 미연결 |
| 최소 iOS | 16.0 |
| 방향 | 세로 고정 |
| 암호화 | `ITSAppUsesNonExemptEncryption=false` (추가 서류 없음) |
| 가격 | 무료 |
| 출시 방식 | 심사 승인 후 수동 출시 권장 |
| 광고 식별자(IDFA) | 사용 안 함 |

## 스크린샷

`appstore/framed-ko/` 에 1320×2868(6.9형 iPhone) 5장이 있고 App Store Connect에 업로드했습니다.
순서와 문구:

1. 오늘의 하늘 — 오늘 하늘이 예뻐서 찍었어요
2. 구름 모양 그대로 — 내가 본 하늘이 나만의 판이 돼요
3. 천천히 해도 돼요 — 첫 칸은 언제나 안전해요
4. 구름 도감 — 지나간 하늘이 한 장씩 쌓여요
5. 나만의 하늘 — 걸어둔 구름을 다시 만나요
원본 캡처는 `tools/store-screenshots/public/screenshots/apple/iphone/ko/` 에 있습니다.

iPhone 전용으로 출시하기로 하고 `TARGETED_DEVICE_FAMILY`를 `1`로 바꿨습니다. iPad 스크린샷은 필요하지 않습니다.

마케팅용 스크린샷은 `tools/store-screenshots/` 에디터(Next.js)에서 만듭니다.
`bun dev` 후 http://localhost:3000 에서 문구·레이아웃을 고치고 **Export bundle**을 누릅니다.
덱은 `tools/store-screenshots/app-store-screenshots.json`에 저장되므로 다시 열어 이어서 작업할 수 있습니다.

## 심사 메모 (App Review Information)

```
이 앱은 사용자가 촬영한 하늘 사진에서 구름 영역을 찾아 지뢰찾기 판을 만듭니다.
카메라 권한이 필요하며, 실행 후 화면의 촬영 버튼으로 하늘이나 구름이 보이는 사진을
찍으면 바로 게임이 시작됩니다. 실내라면 구름 사진이 인쇄되거나 표시된 화면을 촬영해도 됩니다.
자동 판독이 실패하면 '모양 수정'에서 직접 칸을 선택할 수 있습니다.
계정 로그인, 인앱 구매, 서버 통신이 없습니다.
```

연락처: 4sizn@naver.com. 데모 계정 불필요.

## 진행 상황 (2026-09-22)

완료: 앱 레코드 생성, 이름·부제·설명·프로모션·키워드 등록, 6.9형 스크린샷 5장 업로드,
연령 등급 4+(7단계 설문), 가격 무료·175개 지역, 앱 개인정보 "데이터 수집 안 함" 게시,
심사 연락처·메모, 저작권 `2026 letspets`, 수동 출시 선택, 구름 모델 라이선스 교체,
letspets.co.kr `/privacy`와 프로젝트 페이지 배포, 빌드 1.0.0(7) 업로드 및 버전 연결.

제출 전 남은 일:

1. **대한민국 GRAC 등급분류번호(RCN).** 연령 등급 화면에 `대한민국 · RCN 추가` 경고가 있다.
   게임은 조건 충족 시 한국 App Store 게시에 RCN이 필요하다. 번호를 받거나 한국 지역을 제외해야 한다.
2. 심사 제출(`심사에 추가`). 승인 후 수동 출시 버튼을 눌러야 공개된다.

## 서명

Xcode에 로그인된 계정이 없고 배포 인증서의 비밀키도 이 맥에 없어서, App Store Connect API로
배포 인증서(`4ZA9SB9NMR`)와 App Store 프로파일(`Cloud Minesweeper App Store`)을 새로 발급했다.
인증서와 비밀키는 `asc-signing.keychain`에 있고, 비밀키와 키체인 비밀번호는
`~/.appstoreconnect/signing/`에 둔다(저장소에 넣지 않는다).

```sh
security unlock-keychain ~/Library/Keychains/asc-signing.keychain-db
flutter build ipa --release --export-options-plist <manual signing plist>
xcrun altool --upload-app --type ios -f build/ios/ipa/*.ipa --apiKey $ASC_KEY_ID --apiIssuer $ASC_ISSUER_ID
```

## 업로드 명령

App Store Connect API 키는 이미 설정되어 있습니다(`ASC_KEY_ID`, `ASC_ISSUER_ID`).
앱 레코드를 만든 뒤 아래 순서로 올립니다.

```sh
ASC=~/.claude/skills/appstore-aso/scripts/asc.swift
swift $ASC status --bundle-id com.lotus.cloudMinesweeper
swift $ASC pull --bundle-id com.lotus.cloudMinesweeper --out appstore/metadata.remote.json
swift $ASC push --bundle-id com.lotus.cloudMinesweeper --in appstore/metadata.json --dry-run
swift $ASC push --bundle-id com.lotus.cloudMinesweeper --in appstore/metadata.json
swift $ASC screenshots --bundle-id com.lotus.cloudMinesweeper --locale ko --dir appstore/framed-ko --replace
```

1.0에는 `whatsNew`를 넣을 수 없습니다. 위 `appstore/metadata.json`에도 넣지 않았습니다.

## 빌드 8 (2026-09-23)

빌드 8은 카메라 줌과 Android 권한 팝업 수정을 담아 업로드했지만 1.0에 연결하지 않았다.
iPhone에서 첫 권한 허용 시 카메라가 정상으로 열리는 것을 확인했으므로 빌드 7 심사를 그대로 둔다.
빌드 8 이후 변경은 1.0.1로 낸다. 서명은 `asc-signing-2.keychain-db`
(`~/.appstoreconnect/signing/keychain-2-password.txt`)와 수동 서명 export plist
(`method` `app-store-connect`, 프로파일 `Cloud Minesweeper App Store`)로 했다.

## 1.0.1 (2026-09-26)

1.0은 빌드 7로 출시되었다(READY_FOR_SALE). 1.0.1은 빌드 9(1.0.1)를 연결했고, 카메라 줌과
AdMob 전면 광고가 들어간다. 출시 방식은 수동이다.

- 앱 개인정보: "데이터 수집 안 함"에서 Google Mobile Ads SDK 기준 7개 유형으로 바꿔 게시했다.
  대략적인 위치, 기기 ID, 제품 상호 작용, 광고 데이터, 충돌 데이터, 실적 데이터, 기타 진단 데이터.
  모두 사용 목적은 분석과 타사 광고이고, 사용자 신원에 연결하지 않으며, 추적에 쓰지 않는다.
  ATT를 묻지 않으므로 IDFA는 쓰지 않는다. 이 변경은 게시 즉시 1.0 제품 페이지에도 나타난다.
- 설명에서 "광고도"를 빼고, 새로운 소식에 줌과 광고 안내를 넣었다(`appstore/metadata.json`).
