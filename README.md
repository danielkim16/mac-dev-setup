---
title: Mac Dev Setup
tags:
  - mac
  - dotfiles
  - setup
created: 2026-09-10
---

# mac-dev-setup

macOS 터미널 개발 환경을 한 번에 구성하는 스크립트(`mac-dev-setup.sh`)와 문서 모음.

## 문서

- [스크립트 설명](docs/script-guide.md) — `mac-dev-setup.sh`가 무엇을 어떤 순서로 하는지
- [설치 도구 레퍼런스](docs/cli-tools-reference.md) — 설치되는 CLI 도구별 설명과 사용 예제
- [셸 환경 구성](docs/shell-environment.md) — Zinit / SCM Breeze / Starship / mise
- [Docker Desktop 없이 Docker 사용하기](docs/docker-with-colima.md) — Colima 설치, Docker 실행, Compose 설정

## 빠른 시작

```bash
git clone <this-repo> ~/Workspace/mac-dev-setup
cd ~/Workspace/mac-dev-setup
chmod +x mac-dev-setup.sh
./mac-dev-setup.sh
```

- Xcode Command Line Tools가 없으면 설치 창을 띄우고 종료한다. 설치 완료 후 스크립트를 **다시 실행**한다.
- 스크립트는 **멱등적**이다. 여러 번 실행해도 안전하며, 이미 설치된 항목은 건너뛴다.
- 실행이 끝나면 새 터미널을 열거나 `exec zsh`로 셸을 다시 로드한다.

## 설치 항목 요약

| 분류 | 항목 |
| --- | --- |
| 패키지 매니저 | Homebrew |
| 터미널 / 폰트 | Ghostty, D2Coding Nerd Font (영문·한글·아이콘 통합) |
| CLI 도구 | lsd, bat, fzf, fd, ripgrep, git-delta, btop, dust, duf, fastfetch, neovim, zoxide, lazygit, navi, starship, mise, gemini-cli |
| 셸 플러그인 | Zinit (+ autosuggestions, completions, syntax-highlighting), SCM Breeze |
| 런타임 | Node.js 24 (mise 관리) |
| AI CLI | Claude Code, Codex CLI, Gemini CLI |
| Git 설정 | user.name / user.email, delta 페이저, 기본 브랜치 main 등 |
| `.zshrc` | 도구 init, Zinit 플러그인, alias (ls→lsd, cat→bat, vim→nvim 등) |
