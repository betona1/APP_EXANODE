# CRDL 빌드/배포 관리 (Releases)

테스트·정식 빌드 이력을 여기서 관리합니다. `dist/`의 APK 원본은 저장소 용량을 아끼기 위해
git에 커밋하지 않고 **GitHub 릴리스**로 배포합니다. (이 폴더의 `.gitignore` 참조)

## 채널
- **test (prerelease)**: 내부 테스트·사이드로드용. Play 스토어 미제출.
- **production**: Play 스토어 정식 배포용. (예정)

## 이력

| 버전 | versionCode | 채널 | 날짜 | 크기 | SHA-256 | 배포 |
|------|-------------|------|------|------|---------|------|
| 0.1.0-test.1 | 2 | test | 2026-07-09 | 49,072,410 B | `90318b688551f27c5e98a61b9c5dd48a41eca3922ffa6e9eec24e1e87500f7d1` | [릴리스](https://github.com/betona1/APP_CRDL/releases/tag/v0.1.0-test.1) |

### 0.1.0-test.1 (2026-07-09)
- 20개 언어 로컬라이제이션 (인도 5개 언어 포함)
- 물소리(오디오 포커스) 버그 수정
- monkey 1500 이벤트 크래시 퍼즈 통과, 테스트 23개 통과, analyze 무결
- 다운로드: https://github.com/betona1/APP_CRDL/releases/download/v0.1.0-test.1/CRDL-v0.1.0-test.1.apk

## 새 테스트 빌드 만드는 법
```bash
cd app
# pubspec은 그대로 두고 test 라벨만 붙여 빌드
flutter build apk --release --build-name=0.1.0-test.<N> --build-number=<code>
cp build/app/outputs/flutter-apk/app-release.apk ../dist/CRDL-v0.1.0-test.<N>.apk
sha256sum ../dist/CRDL-v0.1.0-test.<N>.apk
# GitHub 프리릴리스로 배포
gh release create v0.1.0-test.<N> ../dist/CRDL-v0.1.0-test.<N>.apk --prerelease --title "..." --notes "..."
```
이후 이 표와 `../homepage/media-manifest.json`을 갱신하세요.
