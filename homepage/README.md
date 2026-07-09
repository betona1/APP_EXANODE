# homepage/ — 홈페이지 게시용 자료 모음

이 폴더는 **CRDL을 개인 홈페이지에 소개·게시**할 때 필요한 문안·미디어·다운로드 정보를 모아둔 곳입니다.
홈페이지 쪽 자동화(예: Claude Code)가 이 폴더를 참조해 콘텐츠를 올릴 수 있도록 구성했습니다.

## 무엇을 먼저 봐야 하나
- **[`media-manifest.json`](./media-manifest.json)** ← 기계 판독용 진입점.
  앱 메타데이터, 문안(태그라인/설명), 모든 에셋 경로·크기·URL, 홍보영상 위치, 테스트 APK 다운로드 링크가 들어있습니다.
- [`manual.md`](./manual.md) — 사용 설명서 (KO/EN). 게임 방법·규칙·특징.
- [`intro.md`](./intro.md) — 소개서/홍보 문안 (KO/EN). 태그라인, 짧은/전체 설명, 팩트시트, SNS 문구.

## 자동화가 쓰는 법 (권장 순서)
1. `media-manifest.json`을 파싱한다.
2. `copy`에서 태그라인/설명을, `manual.md`·`intro.md`에서 본문을 가져온다.
3. `graphics`·`screenshots`의 `path`(저장소 상대경로)로 이미지를 첨부한다.
4. `video.promoShorts`·`download.testApk`는 저장소에 없을 수 있으니(`gitignored`) **`url`(GitHub 릴리스)** 을 사용한다.
5. 링크는 `links`(소스코드/개인정보처리방침/릴리스)를 그대로 건다.

## 경로 규칙
- 모든 `path`는 저장소 **루트 기준 상대경로**입니다. (예: `store/icon-512.png`)
- `gitignored: true`이면 저장소에 파일이 없으니 반드시 `url`을 사용하세요.

## 유지보수
- 새 빌드를 배포하면 [`../dist/RELEASES.md`](../dist/RELEASES.md)에 기록하고,
  `media-manifest.json`의 `app.testVersion`·`download.testApk`를 갱신하세요.
