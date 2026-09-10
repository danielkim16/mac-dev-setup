---
title: 스크립트 설명
tags:
  - mac
  - setup
  - bash
created: 2026-09-10
---

# 스크립트 설명

[Mac Dev Setup](../README.md) · 대상 파일: `mac-dev-setup.sh`

`set -euo pipefail`로 실행된다. 명령 실패(`-e`), 미정의 변수 참조(`-u`), 파이프 중간 실패(`pipefail`) 시 즉시 중단한다.

## 실행 흐름

### 1. 안전장치

```bash
trap 'echo "❌ Setup failed (line $LINENO)" >&2' ERR
```

- 어떤 명령이 실패하면 **몇 번째 줄**에서 죽었는지 출력한다.

```bash
if [ -z "${MAC_DEV_SETUP_CAFFEINATED:-}" ] && command -v caffeinate >/dev/null 2>&1; then
  export MAC_DEV_SETUP_CAFFEINATED=1
  exec caffeinate -i "$0" "$@"
fi
```

- `caffeinate -i`로 자기 자신을 다시 실행해 **설치 중 맥이 잠들지 않게** 한다.
- `MAC_DEV_SETUP_CAFFEINATED` 환경변수로 재귀 재실행을 1회로 막는다.

### 2. 헬퍼 함수

**`append_if_missing <line> <file>`**
- 해당 줄이 파일에 이미 있으면 아무것도 안 하고, 없으면 추가한다 (`grep -qxF`: 전체 줄 완전 일치, 정규식 아님).
- `.zprofile` / `.zshrc`에 설정 줄을 중복 없이 넣을 때 사용한다.

**`brew_install <formula|cask> <pkg...>`**
- 패키지를 **하나씩** 설치한다.
- 하나가 실패해도 `⚠️`만 출력하고 다음 패키지로 계속 진행한다 (`set -e`에 의한 전체 중단 방지).

### 3. Xcode Command Line Tools

```bash
if ! xcode-select -p >/dev/null 2>&1; then
  xcode-select --install
  exit 0
fi
```

- git, 컴파일러 등의 전제 조건. GUI 설치라 스크립트가 기다릴 수 없어 **설치 창을 띄우고 종료**한다. 설치 후 재실행 필요.

### 4. Homebrew

- 없으면 공식 설치 스크립트로 설치한다.
- **경로 자동 탐지**: Apple Silicon은 `/opt/homebrew/bin/brew`, Intel은 `/usr/local/bin/brew`.
- `eval "$("$BREW_BIN" shellenv)"`로 현재 스크립트에서 brew를 쓸 수 있게 하고, 같은 줄을 `~/.zprofile`에 추가해 이후 로그인 셸에서도 자동 적용되게 한다.
- `brew update`로 포뮬러 정보 갱신.

### 5. 패키지 설치

- **Cask**: `ghostty`, `font-d2coding-nerd-font`
- **Formula (CLI)**: `lsd bat fzf fd ripgrep git-delta btop dust duf fastfetch neovim zoxide lazygit navi starship mise gemini-cli`
- 각 도구 설명은 [설치 도구 레퍼런스](cli-tools-reference.md) 참고.

### 6. Git 전역 설정

```bash
git config --global user.name "danielkim"
git config --global user.email "danielkim.@shortchall.com"
git config --global init.defaultBranch main
git config --global pull.rebase true
git config --global push.autoSetupRemote true
```

- `git-delta`가 설치돼 있으면 diff 페이저를 delta로 지정하고 `merge.conflictStyle`을 `zdiff3`로 바꾼다.

### 7. 셸 플러그인

- **Zinit**: `~/.local/share/zinit/zinit.git`에 clone (Zsh 플러그인 매니저). 프롬프트는 Starship, 런타임은 mise가 담당하므로 Oh My Zsh 같은 프레임워크는 쓰지 않는다.
- **SCM Breeze**: `~/.scm_breeze`에 clone 후 `install.sh` 실행 (git 단축키/번호 파일 참조).
- 자세한 내용은 [셸 환경 구성](shell-environment.md).

### 8. 런타임 (mise)

```bash
eval "$(mise activate bash)"
mise use --global node@24
```

- mise를 현재 셸에 활성화하고 Node.js 24를 **전역 기본 버전**으로 설치·고정한다 (`~/.config/mise/config.toml`).

### 9. `.zshrc` 자동 구성

`append_if_missing`로 다음 줄들을 `~/.zshrc`에 추가한다.

```bash
eval "$(mise activate zsh)"
eval "$(zoxide init zsh)"
eval "$(starship init zsh)"
source <(fzf --zsh)
source "$HOME/.local/share/zinit/zinit.git/zinit.zsh"
zinit light zsh-users/zsh-autosuggestions
zinit light zsh-users/zsh-completions
[ -s "$HOME/.scm_breeze/scm_breeze.sh" ] && source "$HOME/.scm_breeze/scm_breeze.sh"
zinit light zsh-users/zsh-syntax-highlighting   # ZLE를 건드리는 다른 플러그인 뒤에 로드

# alias — 안전한 드롭인 / 새 이름만
alias ls='lsd --group-dirs first'
alias ll='lsd -l --group-dirs first'
alias la='lsd -la --group-dirs first'
alias lt='lsd --tree'
alias cat='bat --paging=never'
alias vim='nvim'
alias vi='nvim'
alias lg='lazygit'
```

> `du`→dust, `df`→duf, `grep`→rg는 인자 문법이 달라 alias하지 않는다. 새 이름(`dust`, `duf`, `rg`)으로 직접 호출한다.

### 10. AI CLI

- `claude`가 없으면 `npm install --global @anthropic-ai/claude-code` (설치 스크립트 허용 플래그 포함).
- `codex`가 없으면 `npm install --global @openai/codex`.
- Gemini CLI는 5단계에서 Homebrew로 이미 설치됨(`gemini-cli`).

### 11. 마무리

- `brew cleanup`으로 오래된 버전과 캐시 정리.
- `brew / node / npm / claude / codex / gemini` 버전 출력.

## 재실행 시 동작

| 상황 | 결과 |
| --- | --- |
| 이미 설치된 Homebrew 패키지 | 건너뜀 (개별 `brew install`이 no-op) |
| 이미 있는 `.zprofile` / `.zshrc` 줄 | `append_if_missing`가 중복 추가 안 함 |
| 이미 clone된 Zinit / SCM Breeze | 디렉터리 존재 체크로 건너뜀 |
| Git 설정 | 매번 덮어씀 (동일 값이라 무해) |

## 커스터마이즈 포인트

- CLI 도구 목록: `brew_install formula \` 블록
- Node 버전: `mise use --global node@24`
- `.zshrc` 초기화 줄 / alias: 9단계 `append_if_missing` 목록
- `pull.rebase` / `push.autoSetupRemote`가 취향에 안 맞으면 6단계에서 제거
- alias가 마음에 안 들면 9단계 `alias ...` 줄을 지우고 `~/.zshrc`에서도 해당 줄 삭제
