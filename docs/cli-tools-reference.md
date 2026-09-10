---
title: 설치 도구 레퍼런스
tags:
  - mac
  - cli
  - reference
created: 2026-09-10
---

# 설치 도구 레퍼런스

[Mac Dev Setup](../README.md) · [스크립트 설명](script-guide.md)에서 설치하는 CLI 도구별 요약과 예제.

---

## 파일 / 디렉터리

### lsd — `ls` 대체 (아이콘 + 색상)

Nerd Font 아이콘, 트리, git 상태 표시를 지원하는 `ls`.

```bash
lsd                     # 기본 목록
lsd -la                 # 숨김 파일 + 상세
lsd -l --total-size     # 디렉터리 실제 용량 포함
lsd --tree              # 트리 뷰
lsd --tree --depth 2    # 깊이 제한
```

스크립트가 `~/.zshrc`에 추가하는 alias:

```bash
alias ls='lsd --group-dirs first'
alias ll='lsd -l --group-dirs first'
alias la='lsd -la --group-dirs first'
alias lt='lsd --tree'
```

### bat — `cat` 대체 (구문 강조 + 페이지네이션)

```bash
bat file.py             # 구문 강조 + 라인 번호
bat -p file.py          # plain (장식 없음, 파이프용)
bat -A file.txt         # 공백/탭/개행 문자 표시
bat -r 20:40 file.py    # 20~40행만
git diff | bat          # diff 강조
```

- git-delta가 페이저라면 `bat`은 파일 열람용으로만 쓰면 된다.
- `bat --list-themes`로 테마 확인, `export BAT_THEME="TwoDark"`.

### fd — `find` 대체 (빠르고 직관적)

```bash
fd report               # 이름에 report 포함된 파일/디렉터리
fd -e md                # 확장자 md
fd -H pattern           # 숨김 파일 포함
fd -t f -e log -x rm    # 찾은 .log 파일 전부 삭제
fd pattern src/         # src/ 하위에서만
```

- 기본적으로 `.gitignore`를 존중하고 숨김 파일을 제외한다.

### dust — `du` 대체 (디렉터리 용량 시각화)

```bash
dust                    # 현재 디렉터리 용량 트리
dust -d 2               # 깊이 2까지
dust -r                 # 큰 항목이 아래로
dust ~/Downloads        # 특정 경로
```

### duf — `df` 대체 (디스크 사용량, 표 형태)

```bash
duf                     # 마운트된 디스크 요약
duf --only local        # 로컬 디스크만
duf /System/Volumes/Data
```

---

## 검색

### ripgrep (`rg`) — `grep` 대체 (초고속 재귀 검색)

```bash
rg "TODO"                       # 재귀 검색 (.gitignore 존중)
rg -i "error"                   # 대소문자 무시
rg -t py "def "                 # 파이썬 파일만
rg -l "import numpy"            # 매칭된 파일 경로만
rg -C 3 "panic"                 # 매칭 전후 3줄
rg "foo" -g '!*.min.js'         # glob 제외
rg --hidden --no-ignore "key"   # 숨김 + ignore 무시
```

### fzf — 퍼지 파인더 (대화형 필터)

```bash
fzf                             # stdin 목록에서 대화형 선택
vim "$(fzf)"                    # 선택한 파일 열기
git branch | fzf                # 브랜치 고르기
history | fzf                   # 명령 히스토리 검색
fd -t f | fzf --preview 'bat --color=always {}'   # 미리보기 포함
```

셸 연동 (`source <(fzf --zsh)`로 활성화됨):

| 단축키 | 기능 |
| --- | --- |
| `Ctrl-T` | 파일/디렉터리 경로를 커맨드라인에 삽입 |
| `Ctrl-R` | 명령 히스토리 퍼지 검색 |
| `Alt-C` | 하위 디렉터리로 `cd` |
| `**<Tab>` | 트리거 자동완성 (`vim **<Tab>`, `cd **<Tab>`) |

---

## Git

### git-delta (`delta`) — diff 뷰어

스크립트가 `~/.gitconfig`의 `core.pager`로 설정한다.

```bash
git diff                        # delta로 렌더링됨
git show HEAD
git log -p
delta a.txt b.txt               # 임의 두 파일 비교
```

- `delta.navigate = true`라 페이저에서 `n` / `N`으로 파일 단위 이동.
- side-by-side를 원하면: `git config --global delta.side-by-side true`.

### lazygit — Git TUI

```bash
lazygit                         # 현재 저장소에서 실행
```

주요 키:

| 키 | 동작 |
| --- | --- |
| `Space` | 파일 스테이지 / 언스테이지 |
| `c` | 커밋 |
| `P` / `p` | push / pull |
| `b` | 브랜치 패널 |
| `<enter>` | 항목 진입 (파일별 hunk 스테이징) |
| `x` | 메뉴(현재 패널에서 가능한 동작) |
| `?` | 도움말 |

### SCM Breeze — git 단축키 + 번호 파일 참조

`source`되면 `git status` 출력의 파일에 번호가 붙고, `$e1`, `$e2` 같은 환경변수로 참조한다.

```bash
gs                              # git status (번호 표시)
ga 1 3                          # 1, 3번 파일 stage
gco 2                           # 2번 파일 checkout
git add $e1                     # 1번 파일 경로 사용
```

---

## 시스템 모니터링

### btop — 리소스 모니터 TUI (`top` 대체)

```bash
btop                            # CPU / 메모리 / 네트워크 / 프로세스
```

- 마우스 지원. `m` 메모리, `p` preset 전환, `f` 프로세스 필터, `Esc` 메뉴, `q` 종료.

### fastfetch — 시스템 정보 요약 (`neofetch` 후속)

```bash
fastfetch                       # 로고 + OS/커널/CPU/메모리 요약
fastfetch -c all                # 가능한 모든 항목
fastfetch --logo none           # 로고 없이
```

- `~/.zshrc` 끝에 `fastfetch` 한 줄을 넣으면 터미널 열 때마다 표시.

---

## 셸 / 이동

### zoxide — 스마트 `cd` (자주 가는 디렉터리 학습)

`eval "$(zoxide init zsh)"`로 활성화됨.

```bash
z proj                          # 이름에 proj 포함된, 가장 자주 간 디렉터리로 이동
z work mac                      # 여러 키워드
zi                              # 대화형 선택 (fzf)
z -                             # 이전 디렉터리
```

- 한동안 써야 데이터가 쌓인다. `zoxide query -l`로 학습된 목록 확인.

### starship — 프롬프트

`eval "$(starship init zsh)"`로 활성화됨. git 브랜치/상태, 언어 버전, 실행 시간 등을 자동 표시.

```bash
starship config                 # 설정 파일 편집 ($EDITOR)
starship explain                # 현재 프롬프트 모듈 설명
starship preset nerd-font-symbols -o ~/.config/starship.toml
```

- 설정 파일: `~/.config/starship.toml`

### navi — 대화형 치트시트

```bash
navi                            # 치트시트 브라우징 (fzf)
navi --print                    # 선택한 명령을 실행 대신 출력
navi repo add denisidoro/cheats # 커뮤니티 치트시트 추가
```

- Ctrl-G 위젯: `eval "$(navi widget zsh)"`를 `~/.zshrc`에 추가하면 셸에서 바로 호출.

---

## 런타임 매니저

### mise — 다중 런타임 / 도구 버전 관리 (asdf 호환)

`eval "$(mise activate zsh)"`로 활성화됨.

```bash
mise use --global node@24       # 전역 기본 버전 (스크립트가 실행함)
mise use node@20                # 현재 디렉터리에 .mise.toml 생성 (프로젝트 고정)
mise install python@3.12        # 설치만
mise ls                         # 설치된 도구/버전
mise exec node@18 -- node -v    # 일회성 실행
mise upgrade                    # 최신 패치로 업그레이드
```

- 전역 설정: `~/.config/mise/config.toml`
- 프로젝트별: 디렉터리의 `.mise.toml` 또는 `.tool-versions`

---

## 에디터

### neovim (`nvim`) — Vim 기반 모달 에디터

```bash
nvim file.py
nvim .                          # 디렉터리 (netrw 탐색기)
nvim -d a.txt b.txt             # diff 모드
```

- 기본 상태에서는 설정이 없다. 설정: `~/.config/nvim/init.lua`
- 배포판을 쓰려면 LazyVim / kickstart.nvim / AstroNvim 등을 별도 설치.

---

## AI CLI

### Claude Code (`claude`) — Anthropic 코딩 에이전트

```bash
claude                          # 현재 디렉터리에서 대화형 세션
claude "이 버그 고쳐줘"            # 프롬프트 바로 전달
claude -p "요약해줘" < file.md    # 파이프 입력, 비대화형 출력
claude --version
claude update                   # 최신 버전으로 갱신
```

- 슬래시 명령: `/help`, `/model`, `/clear`, `/config`

### Codex CLI (`codex`) — OpenAI 코딩 에이전트

```bash
codex                           # 대화형 세션
codex "add tests for utils.py"
codex --version
```

### Gemini CLI (`gemini`) — Google 코딩 에이전트

```bash
gemini                          # 대화형 세션
gemini -p "explain this repo"
gemini --version
```

---

## 터미널 / 폰트

### Ghostty — GPU 가속 터미널 에뮬레이터

- 설정 파일: `~/.config/ghostty/config`

```ini
font-family = "D2KodingLigature Nerd Font Mono"
font-size = 14
theme = "catppuccin-mocha"
background-opacity = 0.95
```

- `Cmd+,` 설정 열기, `Cmd+Shift+,` 설정 리로드.

### D2Coding Nerd Font

- **D2KodingLigature Nerd Font Mono**: 영문·한글·Nerd 아이콘을 한 폰트로 통합. 네이버가 만든 국내 개발자 표준 코딩 폰트 D2Coding에 Nerd Font 글리프를 패치한 버전으로, lsd / starship / lazygit 아이콘까지 이 폰트 하나로 표시된다. 영문:한글 폭이 정확히 1:2, 코딩 리거처 포함. `font-d2coding-nerd-font` cask.
- 상표 문제로 패밀리명이 `D2Koding`(K)으로 표기된다 — 오타가 아님.
- 이전에는 Hack Nerd Font + Sarasa Mono K 조합을 썼으나, 한글 렌더링이 압축돼 보인다는 이유로 D2Coding 단일 폰트로 교체.

---

## 참고

- [스크립트 설명](script-guide.md) — 설치 순서와 멱등성
- [셸 환경 구성](shell-environment.md) — 프레임워크 계층 설명
