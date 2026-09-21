# Cloud Minesweeper PRD

## 1. 프로젝트 개요

### 1.1 프로젝트명
**Cloud Minesweeper**

### 1.2 한 줄 설명
스마트폰 카메라로 실제 하늘의 구름을 인식하고, 구름의 형태를 실시간 지뢰찾기 게임판으로 변환하는 완전 온디바이스 카메라 게임.

### 1.3 핵심 목표
사용자가 하늘을 촬영하면 앱이:

1. 하늘 영역을 인식하고
2. 구름 영역을 픽셀 단위로 분리하며
3. 구름 분포를 Grid Cell로 변환하고
4. 해당 Grid를 지뢰찾기 게임판으로 생성한다.

모든 AI 추론 및 영상 처리는 기기 내부에서 수행한다.

---

## 2. 핵심 원칙

### 2.1 Network Zero

앱의 핵심 기능은 네트워크 연결 없이 정상 동작해야 한다.

다음 기능은 서버를 사용하지 않는다.

- 카메라 영상 분석
- 구름 판별
- 구름 Segmentation
- 게임판 생성
- 지뢰 배치
- 게임 진행
- 기록 저장

AI 모델은 앱 패키지 내부에 포함한다.

```text
Camera
 ↓
On-device AI
 ↓
Cloud Mask
 ↓
Game
```

외부 API 호출 없음.

### 2.2 Cloud Shape First

구름을 단순히 다음과 같이 판단하지 않는다.

```text
Cloud: Yes / No
```

대신 픽셀 단위 확률을 추론한다.

```text
CloudProbability[x][y] = 0.0 ~ 1.0
```

예:

```text
0.02 0.08 0.25 0.63 0.91
0.01 0.11 0.57 0.86 0.96
0.03 0.29 0.74 0.92 0.84
```

이를 기반으로 실제 구름의 형태를 유지한다.

---

## 3. 사용자 경험

### 3.1 기본 사용자 플로우

```text
앱 실행
 ↓
카메라 권한
 ↓
하늘을 비춰주세요
 ↓
하늘 감지
 ↓
구름 분석
 ↓
구름 영역 고정
 ↓
지뢰찾기 Grid 생성
 ↓
게임 시작
```

---

## 4. 카메라 UX

사용자가 카메라를 실행하면 전체 화면 Camera Preview를 표시한다.

화면 위에는 최소한의 안내 UI만 출력한다.

```text
┌──────────────────────────┐
│                          │
│        실제 하늘          │
│                          │
│     ☁        ☁           │
│          ☁               │
│                          │
│                          │
│     하늘을 비춰주세요      │
│                          │
│          [SCAN]          │
└──────────────────────────┘
```

하늘이 충분히 검출되면 `하늘 감지됨`, 구름이 검출되면 `구름 분석 중`, 분석 완료 후 `게임판 생성` 상태를 표시한다.

---

## 5. AI Pipeline

```text
Camera Frame
      │
      ▼
Frame Downscale
      │
      ▼
Cloud Segmentation
      │
      ▼
Cloud Probability Map
      │
      ▼
Mask Refinement
      │
      ▼
Temporal Smoothing
      │
      ▼
Grid Aggregation
      │
      ▼
Stable Cloud Cells
      │
      ▼
Minesweeper Board
```

---

## 6. Camera Frame 처리

카메라 원본 해상도를 그대로 AI 입력으로 사용하지 않는다.

예:

```text
Camera: 1920 x 1080
AI Input: 512 x 512
```

성능이 낮은 기기에서는 `384 x 384`, `256 x 256`도 지원한다.

목표:

```text
AI 추론 빈도: 3 ~ 10 FPS
Camera Preview: 30 / 60 FPS
```

AI 모델을 매 프레임 실행하지 않는다.

---

## 7. Cloud Segmentation

화면의 각 Pixel에 대해 `Cloud Probability`를 계산한다.

```text
Clear Sky = 0.04
Thin Cloud = 0.41
Cloud = 0.82
Dense Cloud = 0.97
```

---

## 8. 추천 모델 구조

### Primary
- SegFormer-B0

### Alternative
- BiSeNetV2
- Fast-SCNN
- MobileNetV3 + DeepLabV3

---

## 9. 모델 선정 기준

우선순위:

1. 구름 경계 표현
2. 모바일 추론 성능
3. 모델 크기
4. iOS / Android 변환 용이성
5. 발열
6. 메모리 사용량

목표 모델 크기:

```text
5 ~ 30 MB
```

---

## 10. TinyCLIP

TinyCLIP은 MVP 필수 구성요소가 아니다.

초기 버전에서는 사용하지 않는다.

필요한 경우 후속 버전에서 보조 Classifier로 추가한다.

용도:

- cloud
- clear sky
- fog
- smoke
- snow
- indoor ceiling
- building

역할은 Segmentation 결과 검증이다.

---

## 11. Cloud Soft Mask

Binary Mask를 즉시 생성하지 않는다.

금지:

```text
cloud = 1
not cloud = 0
```

대신 `0.0 ~ 1.0` Soft Mask를 유지한다.

구름 가장자리처럼 반투명한 영역을 표현하기 위함이다.

---

## 12. Mask Refinement

AI 결과에 로컬 영상 처리를 추가한다.

사용 후보:

- Guided Filter
- Bilateral Filter
- Morphological Open
- Morphological Close
- Edge-aware smoothing

목표:

- 구름 경계 유지
- 작은 Noise 제거
- Mask Hole 제거
- 흔들리는 Pixel 감소

---

## 13. Temporal Smoothing

한 프레임의 결과만으로 판단하지 않는다.

```text
Frame 1 = 0.72
Frame 2 = 0.68
Frame 3 = 0.31
Frame 4 = 0.74
```

Frame 3 하나 때문에 구름이 사라졌다고 판단하지 않는다.

EMA 예시:

```text
smoothed =
current × 0.4
+
previous × 0.6
```

필요한 경우 최근 3~5 frame을 사용한다.

---

## 14. Grid System

구름 mask를 그대로 게임 오브젝트로 사용하지 않는다.

화면을 고정 Grid로 나눈다.

초기 후보:

- 8 × 12
- 10 × 14
- 12 × 16
- 16 × 20

기본:

```text
12 × 16
```

---

## 15. Grid Cloud Coverage

각 Cell 내부의 Cloud Probability 평균을 계산한다.

```text
CloudCoverage =
Σ CloudProbability
÷
Cell Pixel Count
```

예:

```text
Cell A = 0.12
Cell B = 0.31
Cell C = 0.76
Cell D = 0.93
```

---

## 16. Cell 판정

초기 기준:

```text
0.00 ~ 0.20 = Clear
0.20 ~ 0.45 = Boundary
0.45 ~ 1.00 = Cloud
```

실제 Threshold는 테스트를 통해 조정한다.

---

## 17. Hysteresis

구름 경계 Cell의 깜빡임을 방지한다.

```text
Cloud 진입: CloudCoverage >= 0.55
Cloud 해제: CloudCoverage <= 0.35
```

서로 다른 Threshold를 사용한다.

---

## 18. Game Board Freeze

게임이 시작된 이후에는 실시간 구름 이동 때문에 게임판 구조가 변경되지 않아야 한다.

사용자가 `SCAN` 버튼을 누르면 약 0.5~1초간 여러 Frame을 분석해 `Stable Cloud Mask`를 생성한다.

```text
Camera Cloud
      ↓
Snapshot
      ↓
Game Board
```

게임 중 실제 구름이 움직여도 Board는 유지한다.

---

## 19. Minesweeper Board 생성

Cloud Cell만 플레이 가능한 영역으로 사용한다.

```text
□ □ ■ ■ □ □
□ ■ ■ ■ ■ □
■ ■ ■ ■ ■ ■
□ ■ ■ ■ ■ □
□ □ ■ ■ □ □
```

- `■` = 구름 영역
- `□` = 게임 외부 영역

---

## 20. Mine Placement

구름 Cell 중 일부에 Mine을 배치한다.

기본 Mine Ratio:

```text
10 ~ 18%
```

예:

```text
구름 Cell: 80
Mine: 12
```

---

## 21. Mine 생성 조건

지뢰는 구름 Boundary보다 내부 영역을 우선한다.

예:

```text
CloudCoverage > 0.65
```

인 Cell을 Mine 후보로 우선 선택한다.

---

## 22. Minesweeper Rule

일반적인 Minesweeper 규칙을 사용한다.

Cell 상태:

- Hidden
- Opened
- Flagged
- Mine

숫자 `1 ~ 8`은 주변 8방향 Mine 개수를 의미한다.

---

## 23. Cloud Shape Board

일반 Minesweeper와 다른 점은 직사각형 전체가 Board가 아니라는 것이다.

```text
        ■ ■

    ■ ■ ■ ■ ■

  ■ ■ ■ ■ ■ ■ ■

    ■ ■ ■ ■ ■

        ■ ■
```

이 형태 자체가 플레이 가능한 Board가 된다.

---

## 24. Edge Cells

구름 가장자리 Cell은 별도 상태 `Boundary`로 둘 수 있다.

### Mode A
게임에서 제외.

### Mode B
일반 Cell로 포함.

초기 MVP에서는 `Boundary 제외`를 기본값으로 한다.

---

## 25. Board Quality 검사

게임판을 만들기 전에 유효성을 검사한다.

권장 조건:

```text
Cloud Cell >= 30
```

또는 전체 Grid의:

```text
Cloud Coverage >= 15%
```

구름이 너무 적으면:

> 구름이 조금 더 많은 하늘을 찾아보세요.

를 표시한다.

---

## 26. Connected Component

구름이 여러 조각으로 분리될 수 있다.

기본적으로 가장 큰 Cloud Cluster를 Board로 사용한다.

선택적으로 `Multiple Cloud Island Mode`를 지원할 수 있다.

---

## 27. 작은 구름 제거

너무 작은 Cloud Cluster는 제거한다.

예:

```text
cluster < 3 cells
```

제외.

목표는 Noise 방지다.

---

## 28. Game Generation Pipeline

```text
Cloud Probability Map
↓
Temporal Smoothing
↓
Grid Coverage
↓
Hysteresis
↓
Connected Component
↓
Small Cluster Removal
↓
Boundary Removal
↓
Board Validation
↓
Mine Placement
↓
Minesweeper Numbers
↓
GAME START
```

---

## 29. 플랫폼 구조

### iOS

- AVFoundation
- Vision
- Core ML
- Metal

### Android

- CameraX
- TensorFlow Lite

또는:

- ONNX Runtime Mobile

---

## 30. 공통 Model

가능하면 하나의 원본 모델을 유지한다.

```text
PyTorch
↓
ONNX
├─ Core ML → iOS
└─ TFLite / ONNX → Android
```

모델 학습 코드는 플랫폼 앱 코드와 분리한다.

---

## 31. Core Interface

```ts
interface CloudDetector {
  detect(frame: Frame): Promise<CloudResult>
}
```

```ts
interface CloudResult {
  cloudProbabilityMap: Float32Array;
  cloudRatio: number;
  confidence: number;
  width: number;
  height: number;
}
```

---

## 32. Grid Result

```ts
interface CloudCell {
  x: number;
  y: number;
  cloudCoverage: number;
  confidence: number;
  state: "clear" | "boundary" | "cloud";
}
```

---

## 33. Minesweeper Cell

```ts
interface MineCell {
  x: number;
  y: number;
  mine: boolean;
  adjacentMines: number;
  opened: boolean;
  flagged: boolean;
}
```

---

## 34. 성능 목표

Mid-range Device 기준 목표:

```text
AI 추론: < 100 ms
권장: 30 ~ 70 ms
Game Board 생성: < 300 ms
전체 Scan: < 1 sec
```

---

## 35. 배터리 / 발열

AI inference는 Camera FPS와 분리한다.

```text
Camera: 60 FPS
AI: 5 FPS
```

사용자가 SCAN을 누른 경우 일시적으로 `10 FPS` 정도로 분석한다.

게임 시작 이후 AI inference는 중지한다.

---

## 36. Privacy

Camera Frame은 외부 서버로 전송하지 않는다.

저장하지 않는 것을 기본값으로 한다.

```text
Camera
↓
RAM
↓
AI Inference
↓
Dispose
```

사용자가 명시적으로 사진 저장을 선택한 경우에만 저장한다.

---

## 37. Offline Requirement

Airplane Mode에서도 다음 기능은 모두 정상 작동해야 한다.

- 앱 실행
- 카메라
- 구름 검출
- 게임판 생성
- 게임
- 기록

---

## 38. Failure Case

### 하늘을 찾을 수 없음
> 하늘을 화면에 조금 더 담아주세요.

### 구름 없음
> 구름이 거의 없어요. 다른 방향의 하늘을 찾아보세요.

### 구름 부족
> 게임판을 만들기엔 구름이 조금 부족해요.

### Camera 흔들림
> 휴대폰을 잠시 고정해주세요.

---

## 39. Sky Validation

초기 MVP에서는 별도 Sky Segmentation 모델을 반드시 사용하지 않는다.

Cloud Segmenter 자체와 색상/Frame 위치를 이용해 판단한다.

필요할 경우 후속으로 `Sky / Non-Sky` 전용 모델을 추가한다.

목표는 모델 개수를 최소화하는 것이다.

---

## 40. 색상 기반 보조 로직

구름 판별 정확도를 높이기 위한 보조 feature:

- Brightness
- Saturation
- Blue ratio
- Local Contrast
- RGB channel variance

단독 판별에는 사용하지 않는다.

AI Prediction 보정 용도로만 사용한다.

---

## 41. MVP

### MVP 1

목표:

```text
하늘 촬영
↓
구름 추출
↓
Grid 생성
```

포함:

- Camera
- Cloud Segmentation
- Soft Mask
- Grid Conversion
- Mask Preview

게임 없음.

### MVP 2

추가:

- Board Freeze
- Connected Component
- Minesweeper Board 생성
- Mine 생성
- Cell Open
- Flag

### MVP 3

추가:

- Temporal Smoothing
- Hysteresis
- Mask Refinement
- 모델 성능 최적화
- 저사양 Device 최적화

---

## 42. 후속 기능

### Cloud Difficulty

구름 밀도에 따라 난이도를 결정한다.

```text
Thin Cloud → Easy
Normal Cloud → Normal
Dense Cloud → Hard
```

---

## 43. Cloud Shape Score

실제 구름 형태에 따라 특별 Board 생성.

예:

- Long Cloud
- Island Cloud
- Ring Cloud
- Massive Cloud

---

## 44. Daily Sky

같은 날 같은 하늘에서도 구름 모양이 계속 달라지므로 사실상 매번 새로운 Board를 생성할 수 있다.

```text
Real Sky
=
Procedural Map Generator
```

---

## 45. 게임 철학

게임이 구름 이미지를 단순 배경으로 사용하는 것이 아니다.

**구름 자체가 Level Design이다.**

```text
Sky
↓
Cloud
↓
Map
↓
Game
```

실제 자연환경이 실시간으로 Procedural Level Generator 역할을 한다.

---

## 46. 핵심 성공 기준

기술적으로 가장 중요한 지표는 Pixel Accuracy 자체가 아니다.

최우선은 다음이다.

1. 구름 형태가 사용자 눈에 보이는 형태와 유사해야 한다.
2. Grid 변환 후 Board가 흔들리지 않아야 한다.
3. 동일한 장면을 연속 Scan했을 때 비슷한 Board가 생성되어야 한다.
4. 구름 경계의 작은 AI 오차가 게임 경험에 영향을 주지 않아야 한다.

따라서 평가 기준은:

```text
Segmentation Accuracy
+
Grid Stability
+
Board Consistency
```

로 정의한다.

---

## 47. 핵심 기술 결정

초기 제품의 기본 기술 방향:

```text
Cloud Segmentation
+
Soft Probability Mask
+
Temporal Smoothing
+
Grid Aggregation
+
Hysteresis
```

TinyCLIP 및 별도 Cloud Classifier는 필수 요소에서 제외한다.

필요한 경우 오검출 감소용으로 후속 추가한다.

---

## 48. 최종 목표 구조

```text
┌─────────────────────────┐
│       CAMERA            │
└────────────┬────────────┘
             │
             ▼
     Resize / Normalize
             │
             ▼
┌─────────────────────────┐
│ Cloud Segmentation AI   │
└────────────┬────────────┘
             │
             ▼
     Probability Mask
             │
             ▼
      Mask Refinement
             │
             ▼
     Temporal Smoothing
             │
             ▼
       Grid Sampling
             │
             ▼
        Hysteresis
             │
             ▼
   Connected Components
             │
             ▼
       Board Freeze
             │
             ▼
      Mine Generation
             │
             ▼
┌─────────────────────────┐
│      MINESWEEPER        │
└─────────────────────────┘
```

---

## 49. 비기능 요구사항

- 핵심 기능 100% 오프라인 동작
- 외부 AI API 금지
- Camera Frame 외부 전송 금지
- iOS / Android 지원
- 모델 App Bundle 포함
- 저사양 기기에서도 동작 가능해야 함
- AI 추론 실패 시 앱 Crash 금지
- 게임 중 AI 추론 중지 가능
- 동일 장면의 Board 생성 일관성 확보

---

## 50. 최종 제품 정의

Cloud Minesweeper는 단순한 AR 지뢰찾기가 아니다.

실제 하늘에서 구름의 형태를 읽고,

```text
Cloud → Geometry → Grid → Game
```

로 변환하는 Camera-native Game이다.

게임의 Map은 미리 만들어진 데이터가 아니라,

**사용자가 바라보고 있는 실제 하늘이 직접 생성한다.**
