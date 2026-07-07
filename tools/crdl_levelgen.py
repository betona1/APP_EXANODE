"""
CRDL 레벨 생성기
------------------
"차례대로" 게임의 '풀 수 있는' 레벨을 무한히 만들어 JSON으로 저장합니다.

원리:
  1) 격자 전체를 한 붓 그리기로 지나는 경로(해밀턴 경로)를 먼저 만든다.
     - snake(지그재그) 경로에서 시작해 backbite 연산으로 무작위화한다.
     - 이 경로는 정의상 "모든 칸을 한 번씩, 겹치지 않고" 지나므로 항상 완주 가능하다.
  2) 그 경로를 따라 숫자 1..N을 순서대로 심는다(1은 시작, N은 끝).
  => 생성된 경로 자체가 정답이므로 "반드시 풀리는" 레벨이 보장된다.

사용:
  python crdl_levelgen.py --rows 8 --cols 6 --numbers 10 --count 50 --out levels.json
  python crdl_levelgen.py --self-test
"""
from __future__ import annotations
import argparse, json, random
from typing import List, Tuple, Dict

Cell = Tuple[int, int]
DIRS = ((1, 0), (-1, 0), (0, 1), (0, -1))


def snake(rows: int, cols: int) -> List[Cell]:
    path: List[Cell] = []
    for r in range(rows):
        rng = range(cols) if r % 2 == 0 else range(cols - 1, -1, -1)
        for c in rng:
            path.append((r, c))
    return path


def neighbors(r: int, c: int, rows: int, cols: int) -> List[Cell]:
    return [(r + dr, c + dc) for dr, dc in DIRS
            if 0 <= r + dr < rows and 0 <= c + dc < cols]


def backbite(path: List[Cell], rows: int, cols: int, iters: int) -> List[Cell]:
    """해밀턴 경로를 유지하며 무작위로 재배열."""
    L = len(path)
    pos: Dict[Cell, int] = {cell: i for i, cell in enumerate(path)}
    for _ in range(iters):
        if random.random() < 0.5:  # head 쪽 backbite
            head = path[0]
            cands = [n for n in neighbors(*head, rows, cols) if pos[n] >= 2]
            if not cands:
                continue
            j = pos[random.choice(cands)]
            path[0:j] = path[0:j][::-1]
            for i in range(j):
                pos[path[i]] = i
        else:                       # tail 쪽 backbite
            tail = path[-1]
            cands = [n for n in neighbors(*tail, rows, cols) if pos[n] <= L - 3]
            if not cands:
                continue
            j = pos[random.choice(cands)]
            path[j + 1:L] = path[j + 1:L][::-1]
            for i in range(j + 1, L):
                pos[path[i]] = i
    return path


def is_hamiltonian(path: List[Cell], rows: int, cols: int) -> bool:
    if len(set(path)) != rows * cols:
        return False
    return all(abs(path[i][0] - path[i + 1][0]) + abs(path[i][1] - path[i + 1][1]) == 1
               for i in range(len(path) - 1))


def generate_level(rows: int, cols: int, numbers: int) -> dict:
    path = backbite(snake(rows, cols), rows, cols, iters=8 * rows * cols)
    assert is_hamiltonian(path, rows, cols), "해밀턴 경로 생성 실패"
    L = len(path)
    numbers = min(numbers, L)
    idxs = sorted({round(k * (L - 1) / (numbers - 1)) for k in range(numbers)})
    nums = [{"r": path[i][0], "c": path[i][1], "n": k + 1} for k, i in enumerate(idxs)]
    return {
        "rows": rows,
        "cols": cols,
        "numbers": nums,                       # 화면에 심을 숫자들
        "solution": [[r, c] for r, c in path], # 정답 경로(검증/힌트용)
        "start": [path[0][0], path[0][1]],
    }


def validate_level(level: dict) -> bool:
    """정답 경로가 실제로 규칙(겹침 없음 + 숫자 순서)을 만족하는지 확인."""
    rows, cols = level["rows"], level["cols"]
    sol = [tuple(p) for p in level["solution"]]
    if not is_hamiltonian(sol, rows, cols):
        return False
    num_at = {(d["r"], d["c"]): d["n"] for d in level["numbers"]}
    order = [num_at[c] for c in sol if c in num_at]
    return order == sorted(order) and order == list(range(1, len(order) + 1))


def self_test(trials: int = 500) -> None:
    random.seed(0)
    for rows, cols, n in [(6, 5, 6), (8, 6, 10), (11, 7, 12), (13, 8, 14)]:
        for _ in range(trials // 4):
            lv = generate_level(rows, cols, n)
            assert validate_level(lv), f"검증 실패 @ {rows}x{cols}"
    print(f"OK — {trials}개 레벨 전부 풀 수 있음(해밀턴 경로 + 숫자 순서 확인).")


def main() -> None:
    ap = argparse.ArgumentParser(description="CRDL 풀 수 있는 레벨 생성기")
    ap.add_argument("--rows", type=int, default=8)
    ap.add_argument("--cols", type=int, default=6)
    ap.add_argument("--numbers", type=int, default=10)
    ap.add_argument("--count", type=int, default=50, help="생성할 레벨 수")
    ap.add_argument("--out", default="levels.json")
    ap.add_argument("--seed", type=int, default=None)
    ap.add_argument("--self-test", action="store_true")
    args = ap.parse_args()

    if args.self_test:
        self_test()
        return

    if args.seed is not None:
        random.seed(args.seed)

    levels = []
    for i in range(args.count):
        lv = generate_level(args.rows, args.cols, args.numbers)
        assert validate_level(lv)
        lv["id"] = i + 1
        levels.append(lv)

    with open(args.out, "w", encoding="utf-8") as f:
        json.dump({"version": 1, "levels": levels}, f, ensure_ascii=False)
    print(f"'{args.out}' 저장 완료 — {len(levels)}개 레벨 "
          f"({args.rows}x{args.cols}, 숫자 1~{args.numbers}), 전부 검증 통과.")


if __name__ == "__main__":
    main()
