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

## 4. Colima 옵션 사용 예제

### CPU·메모리·디스크 지정

처음 실행할 때 옵션으로 가상 머신에 할당할 자원을 지정할 수 있다.

```bash
colima start --cpus 4 --memory 8 --disk 100
```

| 옵션 | 의미 |
| --- | --- |
| `--cpus 4` | 가상 CPU 4개 할당 |
| `--memory 8` | 메모리 8 GiB 할당 |
| `--disk 100` | 가상 디스크 용량 100 GiB 설정 |

Mac의 전체 자원과 함께 실행할 앱을 고려해 값을 정한다. 이미 실행 중이라면 중지한 뒤 변경할 옵션을 지정해 시작한다.

```bash
colima stop
colima start --cpus 4 --memory 6
```

기존 가상 디스크는 용량을 늘릴 수 있지만 줄일 수는 없다.

### Apple Silicon에서 VZ·Rosetta 사용

macOS 13 이상인 Apple Silicon Mac에서는 Apple의 Virtualization Framework(`vz`)와 Rosetta를 사용하는 구성을 선택할 수 있다. Rosetta는 amd64 컨테이너 실행에 사용하며, `virtiofs`는 Mac과 가상 머신 사이의 파일 공유 방식이다.

아래는 `dev-vz`라는 새 프로필을 만드는 예제다. 프로필은 서로 별개의 실행 환경이며 이미지·컨테이너·볼륨이 자동으로 이전되지 않는다.

```bash
colima start dev-vz \
  --runtime docker \
  --arch aarch64 \
  --vm-type vz \
  --vz-rosetta \
  --mount-type virtiofs \
  --cpus 4 \
  --memory 8 \
  --disk 100
```

가상 머신 종류와 아키텍처, 마운트 방식은 생성 후 변경할 수 없으므로 기존 환경과 다른 구성을 사용할 때는 새 프로필 이름을 지정한다. 위 옵션 조합은 Intel Mac용 예제가 아니다.

```bash
# 해당 프로필의 Docker 환경 선택
docker context use colima-dev-vz

# amd64 이미지 실행 확인
docker run --rm --platform linux/amd64 hello-world

# 프로필 상태 확인 및 중지
colima status dev-vz
colima stop dev-vz

# 같은 프로필 다시 시작
colima start dev-vz
```

### 설정 파일 편집

기본 프로필의 설정을 편집하려면 다음을 실행한다. 실행 중인 환경은 먼저 중지한다.

```bash
colima stop
colima start --edit
```

기본 설정 파일은 `~/.colima/default/colima.yaml`이다. CLI의 `--cpus`에 대응하는 YAML 키는 `cpu`다.

```yaml
cpu: 4
memory: 8
disk: 100
```

전체 옵션은 `colima start --help`와 [Colima 설정 문서](https://colima.run/docs/configuration/)에서 확인할 수 있다.

## 5. Docker Compose 설치 및 사용

여러 컨테이너를 `compose.yaml`로 관리하려면 Compose 플러그인을 추가한다.

```bash
brew install docker-compose
```

설치 후 Homebrew가 출력하는 `cliPluginsExtraDirs` 안내에 따라 Docker의 플러그인 검색 경로를 설정한다. 이 메시지는 오류가 아니라 추가 설정 안내다.

먼저 Homebrew 설치 경로를 확인한다.

```bash
brew --prefix
```

출력이 `/opt/homebrew`라면 `~/.docker/config.json`에 다음 항목을 추가한다. 아래는 파일을 새로 만들 때 사용할 수 있는 완전한 JSON 예시다.

```json
{
  "cliPluginsExtraDirs": [
    "/opt/homebrew/lib/docker/cli-plugins"
  ]
}
```

- 파일이 이미 있다면 기존 내용을 덮어쓰지 말고, 최상위 객체에 `cliPluginsExtraDirs` 항목을 추가한다. 기존 항목과의 쉼표 구분도 유지한다.
- `cliPluginsExtraDirs`가 이미 있다면 기존 배열에 경로를 추가한다. 같은 키를 중복으로 만들지 않는다.
- `brew --prefix` 출력이 `/usr/local`이라면 `/usr/local/lib/docker/cli-plugins`를 사용한다. 실제 Homebrew 경로 뒤에 `/lib/docker/cli-plugins`를 붙이면 된다.
- JSON에는 실제 절대 경로를 입력한다. `$(brew --prefix)` 같은 셸 명령은 JSON 안에서 실행되지 않는다.
- `~/.docker` 디렉터리가 없다면 `mkdir -p ~/.docker`로 만든 뒤 파일을 생성한다.

설정 후 Compose가 인식되는지 확인한다.

```bash
docker compose version
```

기존 안내대로 `~/.docker/cli-plugins/docker-compose` 심볼릭 링크를 만들었고 위 명령이 정상 동작한다면 그 방식도 유효하다. 두 방식을 모두 설정할 필요는 없다. 이 문서는 [Homebrew 패키지 안내](https://formulae.brew.sh/formula/docker-compose)에 맞춰 `cliPluginsExtraDirs` 방식을 사용한다.

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

## 6. MySQL·RabbitMQ·Redis 개발 환경 권장 구성

### 현재 노트북 기준 권장 자원

2026-09-16에 확인한 노트북 사양은 Apple Silicon, 메모리 48 GiB, 논리 CPU 18개다. IntelliJ와 DataGrip, 개발 애플리케이션은 Mac에서 실행하고 MySQL·RabbitMQ·Redis는 각각 컨테이너 하나로 실행하는 구성을 가정한다.

일반적인 개발용 데이터와 요청량에서는 **CPU 4개·메모리 8 GiB·디스크 100 GiB**를 시작값으로 권장한다. 실제 사용량을 측정해 조정할 값이며, IDE·애플리케이션 JVM·빌드 작업에 사용할 메모리도 확보할 수 있다.

| 설정 | 추천값 | 용도 |
| --- | --- | --- |
| CPU | 4개 | 세 서비스의 로컬 개발 작업 처리 |
| 메모리 | 8 GiB | DB·메시지 큐·Linux 실행 환경 |
| 디스크 | 100 GiB | 이미지·DB 데이터·로그 저장 |
| VM | `vz` | macOS 가상화 프레임워크 |
| 아키텍처 | `aarch64` | Apple Silicon에서 ARM 이미지 실행 |
| 파일 공유 | `virtiofs` | Mac 디렉터리 공유 |

### 새 개발 환경 생성

`shortchall-server`라는 프로필로 새 환경을 생성한다. VZ·VirtioFS 설정은 [Colima 공식 설정 문서](https://colima.run/docs/configuration/)를 참고한다.

```bash
colima start shortchall-server \
  --runtime docker \
  --arch aarch64 \
  --vm-type vz \
  --mount-type virtiofs \
  --cpus 4 \
  --memory 8 \
  --disk 100

# 최초 한 번: Colima가 생성한 연결 설정을 복사
docker context create \
  --from colima-shortchall-server \
  shortchall-server

docker context use shortchall-server
```

Colima 프로필 이름은 `shortchall-server`이고, Colima가 자동 생성하는 Docker context 이름은 `colima-shortchall-server`다. 위 명령은 같은 Docker 엔진에 연결하는 `shortchall-server` context를 추가한다. 두 context에서 보이는 컨테이너·이미지·볼륨은 동일하다. [Docker context 생성 문서](https://docs.docker.com/reference/cli/docker/context/create/)

`docker context use`는 이미 존재하는 context를 선택하는 명령이므로 생성 단계를 먼저 실행해야 한다. `shortchall-server` context를 이미 만들었다면 생성 명령은 생략한다. 등록된 이름과 현재 선택 상태는 다음으로 확인한다.

```bash
docker context ls      # 전체 목록, 현재 선택은 * 표시
docker context show    # 현재 선택된 이름
```

Colima는 시작할 때 자신이 관리하는 context를 자동 선택할 수 있다. 이후 재시작할 때도 아래처럼 원하는 context를 선택한다. Context 선택 자체는 컨테이너를 이동하거나 시작·중지하지 않는다. [Colima 자동 선택 설정](https://colima.run/docs/configuration/#auto-activation)

```bash
colima start shortchall-server
docker context use shortchall-server
```

기존 프로필의 이미지·컨테이너·볼륨은 새 프로필로 자동 이전되지 않는다. 기존 기본 프로필의 데이터를 계속 사용하면서 자원만 조정하려면 다음을 실행한다.

```bash
colima stop
colima start --cpus 4 --memory 8
```

이 명령은 기존 디스크 크기를 유지한다. 디스크를 늘릴 때만 `--disk`로 현재보다 큰 값을 지정한다. 디스크 축소는 지원하지 않는다.

### 이미지와 데이터 저장

- MySQL·RabbitMQ·Redis 이미지 버전은 프로젝트의 요구사항에 맞추고 ARM64를 지원하는 태그를 선택한다.
- ARM64 이미지 사용 시 Rosetta는 필요하지 않다. amd64 전용 이미지가 필요한 경우 VZ 환경에서 `--vz-rosetta` 옵션을 사용한다.
- DB와 메시지 데이터는 Docker named volume에 저장하는 것을 권장한다. Colima VM 내부에 저장되므로 Mac 폴더 공유를 거치지 않는다. Docker도 영속 데이터와 높은 I/O 성능이 필요한 용도로 볼륨을 권장한다. [Docker 볼륨 문서](https://docs.docker.com/engine/storage/volumes/)

### IntelliJ·DataGrip에서 서비스 접속

Compose에서 각 서비스에 아래 포트를 공개한다. 표의 값은 각 서비스의 `ports` 배열에 넣는 항목이다. RabbitMQ 관리 UI 포트는 관리 플러그인을 활성화한 경우에 사용한다.

| 서비스 | Compose의 `ports` 항목 | Mac에서 접속 |
| --- | --- | --- |
| MySQL | `"127.0.0.1:3306:3306"` | `127.0.0.1:3306` |
| RabbitMQ | `"127.0.0.1:5672:5672"` | `127.0.0.1:5672` |
| RabbitMQ 관리 UI | `"127.0.0.1:15672:15672"` | `http://127.0.0.1:15672` |
| Redis | `"127.0.0.1:6379:6379"` | `127.0.0.1:6379` |

DataGrip의 MySQL 연결에는 호스트 `127.0.0.1`, 포트 `3306`, 컨테이너에 설정한 데이터베이스 이름과 계정을 입력한다. IntelliJ에서 실행하는 애플리케이션도 표의 주소를 사용한다.

`127.0.0.1` 바인딩은 해당 Mac에서 접근하도록 제한한다. 이 구성에는 별도 `--network-address` 옵션이 필요하지 않다. [Docker 포트 공개 문서](https://docs.docker.com/engine/network/port-publishing/), [Colima 포트 전달](https://colima.run/docs/configuration/#port-forwarding)

### 사용량 확인과 자원 증설

먼저 해당 Docker 환경을 선택하고 컨테이너별 사용량을 확인한다.

```bash
docker context use shortchall-server
docker stats
```

대량 데이터 적재나 메시지 처리 테스트 중 자원 부족이 확인되면 CPU 6개·메모리 12 GiB로 늘려 본다. Mac의 활성 상태 보기에서 메모리 압력도 함께 확인한다.

```bash
colima stop shortchall-server
colima start shortchall-server --cpus 6 --memory 12
docker context use shortchall-server
```

중지 과정에서 서비스도 중단된다. 다시 시작한 뒤 프로젝트 디렉터리에서 `docker compose up -d`로 필요한 서비스를 실행한다. 기본 프로필을 사용한다면 위 명령의 `shortchall-server`를 생략하고 Docker context는 `colima`를 사용한다.

## 7. 자주 사용하는 명령

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
- [Colima 실행 옵션과 설정 파일](https://colima.run/docs/configuration/)
- [Homebrew Docker Compose 패키지](https://formulae.brew.sh/formula/docker-compose)
- [OrbStack 공식 문서](https://docs.orbstack.dev/)
