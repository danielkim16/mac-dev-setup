---
title: 셸 환경 구성
tags:
  - mac
  - zsh
  - reference
created: 2026-09-10
---

# 셸 환경 구성

[Mac Dev Setup](../README.md) · Zsh 위에 얹히는 플러그인/도구 계층 설명.

## 계층 구조

```
Zsh (macOS 기본 셸)
├─ Zinit          — 플러그인 매니저 (지연 로딩, 터보 모드)
│   ├─ zsh-autosuggestions      — 히스토리 기반 입력 제안
│   ├─ zsh-completions          — 추가 자동완성 정의
│   └─ zsh-syntax-highlighting  — 명령어 실시간 색상 (반드시 마지막)
├─ SCM Breeze     — git 워크플로 (번호 파일 참조, 단축 함수)
├─ Starship       — 프롬프트
├─ mise           — 런타임 버전 관리 (PATH 주입)
├─ zoxide         — 디렉터리 점프
└─ fzf            — 키바인딩(Ctrl-T/R, Alt-C) + 자동완성
```

> Oh My Zsh 같은 **프레임워크는 쓰지 않는다.** 프롬프트는 Starship, 런타임은 mise,
> 플러그인은 Zinit이 각각 담당하므로 프레임워크 계층이 불필요하다. 필요한 플러그인만
> Zinit으로 직접 선언하는 편이 가볍고 시작 속도도 빠르다.

## `.zshrc` 로드 순서 (권장)

스크립트가 `append_if_missing`로 넣는 줄들은 파일 **끝**에 순서대로 추가된다.

```bash
# 1. Homebrew — 실제로는 .zprofile에서 이미 로드됨

# 2. 도구 초기화
eval "$(mise activate zsh)"
eval "$(zoxide init zsh)"
eval "$(starship init zsh)"
source <(fzf --zsh)

# 3. Zinit + 플러그인
source "$HOME/.local/share/zinit/zinit.git/zinit.zsh"
zinit light zsh-users/zsh-autosuggestions
zinit light zsh-users/zsh-completions

# 4. SCM Breeze (git 함수가 alias를 덮어쓸 수 있어 뒤쪽에)
[ -s "$HOME/.scm_breeze/scm_breeze.sh" ] && source "$HOME/.scm_breeze/scm_breeze.sh"

# 5. syntax-highlighting — ZLE를 건드리는 모든 것 뒤, 가장 마지막
zinit light zsh-users/zsh-syntax-highlighting

# 6. alias — 스크립트가 자동 추가 (ls/ll/la/lt → lsd, cat → bat, vim/vi → nvim, lg → lazygit)
```

## 각 구성요소

### Zinit

- 위치: `~/.local/share/zinit/zinit.git`
- 로드: `source .../zinit.zsh` (스크립트가 `.zshrc`에 추가함)
- 스크립트가 기본으로 선언하는 플러그인:

```bash
zinit light zsh-users/zsh-autosuggestions
zinit light zsh-users/zsh-completions
zinit light zsh-users/zsh-syntax-highlighting   # 항상 마지막
```

- 추가로 쓰고 싶으면 직접 선언. 터보 모드로 프롬프트 표시 후 지연 로딩:

```bash
zinit ice wait lucid
zinit light agkozak/zsh-z
```

- `zinit update --all`로 플러그인 갱신, `zinit times`로 로드 시간 확인.

### SCM Breeze

- 위치: `~/.scm_breeze`
- 설치 시 `install.sh`가 `~/.*rc`에 source 줄을 넣으려 시도한다. 스크립트에서도 `append_if_missing`로 보장.
- 핵심 기능:
  - `gs` → 번호가 붙은 `git status`
  - `$e1`, `$e2`, ... → 해당 번호 파일 경로
  - `ga`, `gco`, `grs` 등 숫자/범위 인자 지원 (`ga 1-3`)
- git alias와 충돌 시: `git_setup_aliases` 동작을 `~/.git.scmbrc`에서 조정.

### Starship

- 설정: `~/.config/starship.toml` (없으면 기본값)
- git 브랜치/상태, 언어 버전, 실행 시간 등을 자동 표시.
- 예시 설정:

```toml
add_newline = true
[time]
disabled = false
format = "[$time]($style) "
[nodejs]
format = "via [⬢ $version](bold green) "
```

### mise

- [도구 레퍼런스의 mise 항목](cli-tools-reference.md) 참고.
- `.zshrc`의 `eval "$(mise activate zsh)"`가 PATH에 shim을 주입한다.
- nvm / n 등 다른 Node 버전 매니저와 같이 쓰지 말 것.

## 트러블슈팅

| 증상 | 원인 / 해결 |
| --- | --- |
| 아이콘이 네모(□)로 보임 | 터미널 폰트를 `D2KodingLigature Nerd Font Mono`로 지정 |
| `mise: command not found` | 새 셸 열기 / `.zshrc`에 activate 줄 확인 / `~/.zprofile`의 brew shellenv 확인 |
| syntax-highlighting 안 먹음 | 해당 플러그인을 `.zshrc`에서 **가장 마지막**에 로드 |
| autosuggestion 색이 안 보임 | `ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=8'` 등으로 조정 |
| 셸 시작이 느림 | `zinit times`로 확인, 무거운 플러그인은 `zinit ice wait lucid`로 터보 로딩 |
| `z` 명령이 동작 안 함 | `eval "$(zoxide init zsh)"` 줄 확인, 데이터가 쌓일 시간 필요 |

## 관련 문서

- [Mac Dev Setup](../README.md)
- [스크립트 설명](script-guide.md)
- [설치 도구 레퍼런스](cli-tools-reference.md)
