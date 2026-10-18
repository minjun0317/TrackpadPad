# TrackpadPad

맥북 트랙패드를 숫자 키패드로 쓰는 메뉴바 앱.
`⌃ Control`을 누르고 있는 동안만 트랙패드가 키패드로 바뀌고, 떼면 원래 트랙패드로 돌아온다.

```
┌───┬───┬───┐
│ 7 │ 8 │ 9 │
├───┼───┼───┤
│ 4 │ 5 │ 6 │
├───┼───┼───┤
│ 1 │ 2 │ 3 │
├───┴───┴───┤
│     0     │
└───────────┘
```

## 사용법

| 동작 | 결과 |
| --- | --- |
| `⌃` 누르고 있기 | 키패드 표시, 커서 고정 |
| `⌃` 누른 채 트랙패드 탭 | 손을 뗄 때 해당 숫자 입력 |
| `⌃⌃` (두 번) | 키패드 고정 |
| 고정 중 `⌃⌃` 또는 `esc` | 고정 해제 |

- 키에 손가락이 닿으면 트랙패드 햅틱이 울리고, 손을 뗄 때 입력된다.
- 누른 채로 다른 칸으로 미끄러지면 입력이 취소된다.
- `⌃C` 같은 단축키를 누르면 키패드가 뜨지 않는다.
- 화면 오버레이는 macOS 26 Liquid Glass로 그린다.

## 설치

macOS 26 이상, Force Touch 트랙패드가 필요하다.

```bash
git clone https://github.com/minjun0317/TrackpadPad.git
cd TrackpadPad
./build.sh
open build/TrackpadPad.app
```

처음 실행하면 **시스템 설정 → 개인정보 보호 및 보안 → 손쉬운 사용**에서 TrackpadPad를 허용해야 한다.
메뉴바 아이콘에 "실행 중"이 보이면 준비 완료.

`build.sh`는 키체인에 Apple Development 인증서가 있으면 그걸로, 없으면 ad-hoc으로 서명한다.
ad-hoc 서명은 빌드할 때마다 손쉬운 사용 권한을 다시 켜야 한다.

## 구조

| 파일 | 역할 |
| --- | --- |
| `CPrivate/` | `MultitouchSupport.framework`를 `dlopen`해 트랙패드 원시 터치 좌표를 받는다 |
| `InputController.swift` | `CGEventTap`으로 `⌃` 홀드/더블탭 감지, 키패드가 열린 동안 포인터 이벤트 차단 |
| `PadController.swift` | 터치 → 키 매핑, 탭 판정, 햅틱 |
| `KeySender.swift` | 키패드 숫자 키 이벤트 전송 (`⌃` 플래그 제거) |
| `OverlayPanel.swift` | Liquid Glass 오버레이 |

## 주의

비공개 API(`MultitouchSupport`)를 사용하므로 App Store에는 배포할 수 없다.
macOS 업데이트로 동작이 바뀔 수 있다.
