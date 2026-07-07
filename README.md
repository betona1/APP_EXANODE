# CRDL (차례대로)

30년 전 모눈종이에 설계했던 격자 퍼즐을 되살린 모바일 게임. 숫자를 **1 → N 순서대로** 먹으며
격자를 훑고, 지나간 칸은 다시 지날 수 없습니다. 길이 엉켜 갇히면 게임 오버.

## 장르

- **땅파기 (fill)** — 모든 칸을 채우며 숫자를 순서대로. (해밀턴 경로 퍼즐)
- **길잇기 (path)** — 숫자만 순서대로 이으면 클리어.

## 바로 해보기

`prototype/crdl.html`을 브라우저로 여세요. 방향키 / WASD / 스와이프 / 화면 D패드로 조작합니다.

## 구성

| 경로 | 설명 |
|------|------|
| `data/levels.json` | 검증된 레벨 200개 (앱 번들용) |
| `tools/crdl_levelgen.py` | 항상 풀리는 레벨 생성기 |
| `tools/crdl_solver.py` | 패턴 솔버/검증기 |
| `prototype/crdl.html` | 플레이 가능한 레퍼런스 구현 |
| `CLAUDE.md` | 프로젝트 상세 안내(규칙·데이터 형식·원리) |

## 레벨 생성

```bash
python tools/crdl_levelgen.py --rows 8 --cols 6 --numbers 10 --count 200 --out data/levels.json
```

모든 레벨은 "정답 경로를 먼저 만들고 숫자를 나중에 심는" 방식이라 **반드시 풀립니다**.
자세한 내용은 `CLAUDE.md` 참고.

## 라이선스

TBD
