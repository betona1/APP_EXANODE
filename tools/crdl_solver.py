"""
CRDL 패턴 솔버 / 검증기
------------------------
"차례대로" 패턴이 실제로 풀리는지 확인하고, 풀린다면 정답 경로를 찾아줍니다.

용도:
  - 옛날 모눈종이 패턴을 되찾았을 때 "이거 진짜 풀리나?" 확인
  - 손으로 직접 설계한 레벨을 게임에 넣기 전에 검증
  - 생성기(crdl_levelgen.py)가 만든 레벨 재확인

규칙(게임과 동일):
  - 숫자 1 칸에서 출발한다.
  - 상하좌우 인접한, 아직 안 지나간 칸으로만 이동한다.
  - 숫자 칸은 '지금 차례'일 때만 들어갈 수 있다(순서 게이트).
  - fill(땅파기): 모든 칸을 채우면 클리어.
  - path(길잇기): 숫자 1..N을 순서대로 다 먹으면 클리어(채울 필요 없음).

입력 형식 — 문자열 격자(가장 쉬움):
  '.' 은 빈 칸, 1~9 는 숫자, 10 이상은 A=10, B=11 ... 로 표기하거나
  parse_grid에 다중문자 토큰을 쓰려면 공백으로 구분된 격자를 넘기세요.
"""
from __future__ import annotations
from typing import Dict, List, Optional, Tuple

Cell = Tuple[int, int]
DIRS = ((-1, 0), (1, 0), (0, -1), (0, 1))


def parse_grid(text: str) -> Tuple[int, int, Dict[Cell, int]]:
    """줄바꿈으로 구분된 격자 텍스트 -> (rows, cols, {(r,c): n}).
    공백으로 나뉘면 다중문자 토큰(예: 10), 아니면 문자 단위. '.' 은 빈 칸."""
    rows = [ln for ln in text.strip("\n").splitlines() if ln.strip() != ""]
    numbers: Dict[Cell, int] = {}
    grid_rows = []
    for line in rows:
        toks = line.split() if " " in line.strip() else list(line.strip())
        grid_rows.append(toks)
    R = len(grid_rows)
    C = max(len(r) for r in grid_rows)
    for r, toks in enumerate(grid_rows):
        for c, t in enumerate(toks):
            if t in (".", "·", "0", ""):
                continue
            numbers[(r, c)] = int(t)
    return R, C, numbers


def solve(R: int, C: int, numbers: Dict[Cell, int],
          mode: str = "fill") -> Optional[List[Cell]]:
    """풀리면 정답 경로(칸들의 순서 리스트), 안 풀리면 None."""
    if not numbers:
        return None
    N = max(numbers.values())
    if sorted(numbers.values()) != list(range(1, N + 1)):
        raise ValueError(f"숫자는 1..{N} 이 각각 하나씩 있어야 합니다. 받은 값: {sorted(numbers.values())}")
    starts = [cell for cell, n in numbers.items() if n == 1]
    start = starts[0]
    total = R * C

    def neighbors(r: int, c: int):
        for dr, dc in DIRS:
            nr, nc = r + dr, c + dc
            if 0 <= nr < R and 0 <= nc < C:
                yield (nr, nc)

    visited = {start}
    path = [start]

    def remaining_reachable(cur: Cell) -> bool:
        """fill 모드 가지치기: 안 지나간 칸이 전부 현재 위치에서 도달 가능한가."""
        unvisited = total - len(visited)
        if unvisited == 0:
            return True
        seen = set()
        stack = [n for n in neighbors(*cur) if n not in visited]
        for s in stack:
            seen.add(s)
        while stack:
            r, c = stack.pop()
            for n in neighbors(r, c):
                if n not in visited and n not in seen:
                    seen.add(n)
                    stack.append(n)
        return len(seen) == unvisited

    def next_number_reachable(cur: Cell, target: int) -> bool:
        """path 모드 가지치기: 다음 숫자가 도달 가능한가."""
        tgt = [cell for cell, n in numbers.items() if n == target]
        if not tgt:
            return True
        seen = set()
        stack = [n for n in neighbors(*cur) if n not in visited]
        for s in stack:
            seen.add(s)
        while stack:
            r, c = stack.pop()
            for n in neighbors(r, c):
                if n not in visited and n not in seen:
                    seen.add(n)
                    stack.append(n)
        return tgt[0] in seen or tgt[0] == cur

    def dfs(cur: Cell, target: int) -> bool:
        if mode == "fill" and len(visited) == total:
            return True
        if mode == "path" and target > N:
            return True
        for nx in neighbors(*cur):
            if nx in visited:
                continue
            k = numbers.get(nx, 0)
            if k != 0 and k != target:
                continue
            visited.add(nx)
            path.append(nx)
            nt = target + 1 if k == target else target
            ok_prune = (remaining_reachable(nx) if mode == "fill"
                        else next_number_reachable(nx, nt))
            if ok_prune and dfs(nx, nt):
                return True
            visited.remove(nx)
            path.pop()
        return False

    return list(path) if dfs(start, 2) else None


def pretty(R: int, C: int, numbers: Dict[Cell, int], solution: Optional[List[Cell]]) -> str:
    order = {cell: i for i, cell in enumerate(solution)} if solution else {}
    out = []
    for r in range(R):
        row = []
        for c in range(C):
            if (r, c) in numbers:
                row.append(f"[{numbers[(r,c)]:>2}]")
            elif (r, c) in order:
                row.append(f"{order[(r,c)]:>3} ")
            else:
                row.append("  . ")
        out.append("".join(row))
    return "\n".join(out)


if __name__ == "__main__":
    # 예시 1: 손으로 그린 작은 패턴 (풀리는 것)
    demo = """
    1 . . 4
    . . . .
    2 . . 3
    """
    R, C, nums = parse_grid(demo)
    sol = solve(R, C, nums, mode="fill")
    print("=== 예시 (4x4, 숫자 1~4, 땅파기) ===")
    print("풀림!" if sol else "풀 수 없음")
    print(pretty(R, C, nums, sol))

    # 예시 2: 생성기 레벨을 불러와 재검증
    try:
        import json
        data = json.load(open("levels.json", encoding="utf-8"))
        lv = data["levels"][0]
        nums = {(d["r"], d["c"]): d["n"] for d in lv["numbers"]}
        sol = solve(lv["rows"], lv["cols"], nums, mode="fill")
        print("\n=== levels.json 첫 레벨 재검증 ===")
        print("풀림!" if sol else "풀 수 없음 (문제!)")
    except FileNotFoundError:
        pass
