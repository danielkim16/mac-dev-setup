---
title: Docker Desktop 없이 Docker 사용하기
tags:
  - mac
  - docker
  - colima
created: 2026-09-16
---

# Docker Desktop 없이 Mac에서 Docker 사용하기

**Colima + Docker CLI**를 사용하면 Docker Desktop을 설치하지 않고 Docker 컨테이너를 실행할 수 있다. 터미널 중심의 개발 환경에 적합하며, Intel Mac과 Apple Silicon Mac을 모두 지원한다.

Colima는 Linux 가상 머신과 그 안의 Docker 엔진을 실행한다. Mac에서는 Docker CLI의 `docker` 명령으로 컨테이너를 관리한다. 따라서 Docker CLI만 설치해서는 컨테이너를 실행할 수 없고, Colima 같은 실행 환경도 필요하다.

## 1. 사전 준비

Homebrew가 설치되어 있어야 한다. 터미널에서 다음 명령으로 확인한다.

```bash
brew --version
```

Homebrew가 없다면 [Homebrew 공식 사이트](https://brew.sh/)의 안내에 따라 설치한다.

## 2. Colima와 Docker CLI 설치

```bash
brew install colima docker
```

이 명령은 Colima와 Docker 명령줄 클라이언트를 설치한다. Docker Desktop 설치는 필요하지 않다.

## 3. 실행 및 동작 확인

```bash
# Linux 가상 머신과 Docker 엔진 시작
colima start

# Colima 상태 확인
colima status

# 테스트 컨테이너 실행 후 자동 삭제
docker run --rm hello-world

# 실행 중인 컨테이너 목록 확인
docker ps
```

`hello-world`의 정상 실행 메시지가 출력되면 사용할 준비가 된 것이다. 테스트 컨테이너는 실행을 마치고 삭제되므로, 다른 컨테이너가 없다면 `docker ps` 목록은 비어 있어도 정상이다.

## 4. Docker Compose 설치 및 사용

여러 컨테이너를 `compose.yaml`로 관리하려면 Compose 플러그인을 추가한다.

```bash
brew install docker-compose

# Docker CLI가 Compose 플러그인을 찾도록 연결
mkdir -p ~/.docker/cli-plugins
ln -sfn "$(brew --prefix)/opt/docker-compose/bin/docker-compose" \
  ~/.docker/cli-plugins/docker-compose

# 설치 확인
docker compose version
```

`compose.yaml`이 있는 프로젝트 디렉터리에서 실행한다.

```bash
# 백그라운드 실행
docker compose up -d

# 서비스 상태 확인
docker compose ps

# 로그 확인
docker compose logs -f

# 프로젝트 컨테이너와 네트워크 정리
docker compose down
```

## 5. 자주 사용하는 명령

| 명령 | 설명 |
| --- | --- |
| `colima start` | Colima 실행 환경 시작 |
| `colima stop` | Colima 실행 환경 중지 |
| `colima status` | Colima 상태 확인 |
| `docker ps` | 실행 중인 컨테이너 목록 |
| `docker ps -a` | 중지된 컨테이너를 포함한 목록 |
| `docker images` | 로컬 이미지 목록 |
| `docker logs <컨테이너>` | 컨테이너 로그 확인 |
| `docker stop <컨테이너>` | 지정한 컨테이너 중지 |

Colima를 중지하면 그 안에서 실행 중이던 컨테이너도 중지된다. 다시 작업할 때는 `colima start`로 실행 환경을 시작한다.

## 다른 선택지

GUI로 컨테이너를 관리하고 싶다면 [OrbStack](https://docs.orbstack.dev/)도 Docker Desktop의 대안이다. 터미널에서 Docker 명령을 사용하는 것이 목적이라면 Colima로 시작하면 된다.

## 참고 문서

- [Colima 시작하기](https://colima.run/docs/getting-started/)
- [Colima 설치 및 Docker 플러그인 설정](https://colima.run/docs/installation/)
- [Homebrew Docker Compose 패키지](https://formulae.brew.sh/formula/docker-compose)
- [OrbStack 공식 문서](https://docs.orbstack.dev/)
