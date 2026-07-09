# CRDL 빌드/배포 관리 (Releases)

테스트·정식 빌드 이력을 여기서 관리합니다. `dist/`의 APK 원본은 저장소 용량을 아끼기 위해
git에 커밋하지 않고 **GitHub 릴리스**로 배포합니다. (이 폴더의 `.gitignore` 참조)

## 채널
- **test (prerelease)**: 내부 테스트·사이드로드용. Play 스토어 미제출.
- **production**: Play 스토어 정식 배포용. (예정)

## 이력

| 버전 | versionCode | 형식 | 채널 | 날짜 | 크기 | SHA-256 | 배포 |
|------|-------------|------|------|------|------|---------|------|
| 0.1.0 | 1 | AAB | Play 업로드용 | 2026-07-09 | 48,877,859 B | `f2e47bfd4f0a08012d1aae847d69428fbb887c6bbe727fa274880c970f75d995` | `dist/CRDL-v0.1.0.aab` (로컬) |
| 0.1.0-test.1 | 2 | APK | test | 2026-07-09 | 49,072,410 B | `90318b688551f27c5e98a61b9c5dd48a41eca3922ffa6e9eec24e1e87500f7d1` | [릴리스](https://github.com/betona1/APP_CRDL/releases/tag/v0.1.0-test.1) |

### 0.1.0 (AAB, Play Console 업로드용)
- **서명**: 업로드 키 `CN=betona`(upload-keystore.jks, alias `upload`)로 서명됨 — debug 아님.
- Play Console → 내부 테스트/프로덕션 트랙에 `dist/CRDL-v0.1.0.aab` 업로드.
- Play App Signing 활성화 시 구글이 실제 배포 서명을 대신 관리(업로드 키는 분실해도 재설정 가능).
- **주의**: AAB는 직접 설치 불가(사이드로드 X). 테스트 설치는 위 test APK 사용.

## 🔐 서명 키 (중요 — 반드시 백업)
- 키스토어: `app/android/upload-keystore.jks` (git 제외됨)
- 설정: `app/android/key.properties` (git 제외됨) — alias `upload`
- **이 두 파일과 비밀번호를 저장소 밖 안전한 곳에 반드시 백업하세요.**
- 분실 시: Play App Signing을 쓰면 Play Console에서 업로드 키 재설정 요청 가능.

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
