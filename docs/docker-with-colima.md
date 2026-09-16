---
title: Docker Desktop 없이 Docker 사용하기
tags:
  - mac
  - docker
  - colima
created: 2026-09-16
updated: 2026-09-16
---

# Docker Desktop 없이 Mac 개발 환경 만들기

이 문서는 Colima로 **MySQL·RabbitMQ·Redis를 실행하고, Mac의 IntelliJ·DataGrip에서 연결하는 과정**을 설명한다. 처음 설정한다면 1~7단계를 순서대로 진행하고, 이후에는 8단계의 명령만 사용하면 된다.

예제는 현재 노트북인 **Apple Silicon, 메모리 48 GiB, 논리 CPU 18개**를 기준으로 한다. Colima는 Intel Mac도 지원하지만, 아래 `aarch64`·`vz` 조합은 Apple Silicon용이다.

## 먼저 이해하기: 무엇을 설치하는가?

| 구성 요소 | 역할 | 비유 |
| --- | --- | --- |
| Colima 프로필 | Linux 가상 머신과 실행 설정을 관리 | 개발용 서버 한 대 |
| Docker 엔진 | 가상 머신 안에서 컨테이너 실행 | 서버 안의 컨테이너 실행 프로그램 |
| Docker CLI | Mac에서 `docker` 명령으로 엔진에 요청 | 서버를 조작하는 클라이언트 |
| Docker context | CLI가 접속할 엔진의 연결 정보 | DataGrip에 저장한 DB 연결 설정 |
| Docker Compose | 여러 컨테이너의 구성을 파일로 관리 | 서비스 실행 명세서 |

Context는 가상 서버 자체가 아니다. 같은 `docker ps`도 어느 context를 선택했는지에 따라 조회하는 서버가 달라지므로, 명령의 실행 대상이라는 의미로 context라고 부른다.

이 문서에서는 프로필과 직접 만드는 context 이름을 모두 `shortchall-server`로 사용한다. 이름은 같지만 역할은 다르다.

```text
Mac: IntelliJ / DataGrip / Docker CLI
                           │ context: shortchall-server
                           ▼
Colima 프로필: shortchall-server
  └─ Linux 가상 머신
      └─ Docker 엔진
          ├─ MySQL
          ├─ RabbitMQ
          └─ Redis
```

## 1단계. Homebrew 확인하고 도구 설치하기

터미널에서 실행한다.

```bash
brew --version
```

**이유:** 필요한 도구를 Homebrew로 설치하기 전에 Homebrew가 있는지 확인한다. 버전이 출력되면 다음으로 진행한다. 명령을 찾을 수 없다면 [Homebrew 공식 사이트](https://brew.sh/)에서 설치한다.

```bash
brew install colima docker docker-compose
```

**이유:** Colima는 실행 환경, Docker CLI는 제어 명령, Compose는 세 서비스를 함께 관리하는 기능을 제공한다. Docker CLI만 설치하면 컨테이너를 실행할 엔진이 없으므로 Colima도 필요하다. [Colima 설치 문서](https://colima.run/docs/installation/)

## 2단계. Docker가 Compose를 찾도록 설정하기

먼저 Homebrew 설치 경로를 확인한다.

```bash
brew --prefix
```

**이유:** Compose는 Docker 플러그인이다. Docker에 Homebrew의 플러그인 디렉터리를 알려 줘야 `docker compose`로 사용할 수 있다. 설치 중 출력된 `cliPluginsExtraDirs` 메시지는 이 설정을 안내하는 것이다. [Homebrew Compose 안내](https://formulae.brew.sh/formula/docker-compose)

설정 디렉터리를 만들고 파일을 연다.

```bash
mkdir -p ~/.docker
nano ~/.docker/config.json
```

`mkdir -p`는 디렉터리가 이미 있어도 사용할 수 있다. `nano`는 터미널에서 파일을 편집하는 프로그램이다.

`brew --prefix` 결과가 `/opt/homebrew`이고 파일이 비어 있다면 다음 전체 내용을 입력한다.

```json
{
  "cliPluginsExtraDirs": [
    "/opt/homebrew/lib/docker/cli-plugins"
  ]
}
```

**파일에 기존 내용이 있다면 덮어쓰지 말고** 최상위 `{ ... }` 안에 `cliPluginsExtraDirs` 항목을 추가한다. 기존 항목과 쉼표로 구분하고, 같은 키가 이미 있으면 배열에 경로만 추가한다. 아래는 4단계까지 완료해 `shortchall-server` context를 선택한 뒤의 설정 예시다.

```json
{
  "currentContext": "shortchall-server",
  "cliPluginsExtraDirs": [
    "/opt/homebrew/lib/docker/cli-plugins"
  ]
}
```

`currentContext`는 현재 선택한 Docker context 이름이다. 처음 따라 하는 중이라면 이 단계에서는 기존 값을 유지하고, 항목이 없다면 추가하지 않는다. 4단계에서 context를 만든 뒤 `docker context use shortchall-server`를 실행하면 해당 값이 설정되므로 직접 수정할 필요가 없다.

Homebrew 경로가 `/usr/local`이면 플러그인 경로도 `/usr/local/lib/docker/cli-plugins`로 바꾼다. JSON에는 실제 경로를 적어야 하며 `$(brew --prefix)`는 실행되지 않는다.

`nano`에서 `Control+O`, Enter로 저장하고 `Control+X`로 종료한다. 다음 명령으로 확인한다.

```bash
docker compose version
```

**확인할 결과:** Compose 버전이 출력되면 성공이다. 이미 심볼릭 링크 방식으로 설정했고 이 명령이 정상이라면 검색 경로를 추가로 설정할 필요는 없다.

## 3단계. shortchall-server 가상 머신 시작하기

처음 만드는 환경이라면 다음을 실행한다.

```bash
colima start shortchall-server \
  --runtime docker \
  --arch aarch64 \
  --vm-type vz \
  --mount-type virtiofs \
  --cpus 4 \
  --memory 8 \
  --disk 100
```

**이유:** 세 서비스를 실행할 Linux 가상 머신을 만들고 Docker 엔진을 시작한다. 줄 끝의 `\`는 명령이 다음 줄로 이어진다는 뜻이다.

| 인자·옵션 | 사용하는 이유 |
| --- | --- |
| `shortchall-server` | 이 개발 환경을 이름으로 구분하고 나중에 다시 시작하기 위해 |
| `--runtime docker` | Docker CLI와 연결할 Docker 엔진을 사용하기 위해 |
| `--arch aarch64` | Apple Silicon에서 ARM64 이미지를 실행하기 위해 |
| `--vm-type vz` | macOS의 가상화 프레임워크를 사용하기 위해 |
| `--mount-type virtiofs` | Mac 폴더를 가상 머신에 공유할 때 사용할 방식 지정 |
| `--cpus 4` | 가상 CPU 4개 할당 |
| `--memory 8` | 세 서비스와 Linux에 메모리 8 GiB 할당 |
| `--disk 100` | 이미지·데이터 저장용 가상 디스크 용량을 100 GiB로 설정 |

CPU 4개·메모리 8 GiB는 일반적인 로컬 개발을 위한 시작값이다. IntelliJ·DataGrip·애플리케이션 JVM·빌드 작업에 사용할 Mac 자원도 남겨 둔다. 부족할 때 측정 후 늘린다. VZ 구성은 macOS 13 이상을 전제로 한다. [Colima 설정 문서](https://colima.run/docs/configuration/)

```bash
colima status shortchall-server
```

**확인할 결과:** 실행 중이라는 상태와 Docker runtime이 표시되어야 한다.

이미 같은 프로필을 만들었다면 `colima start shortchall-server`로 다시 시작하면 된다. 다른 프로필의 이미지·컨테이너·볼륨은 자동 이전되지 않는다. 기존 프로필의 VM 종류·아키텍처를 바꾸려는 경우에는 뒤의 선택 설정을 참고한다.

## 4단계. Docker 연결 이름을 shortchall-server로 만들기

먼저 등록된 연결 설정을 확인한다.

```bash
docker context ls
```

**이유:** Colima 프로필 이름은 `shortchall-server`지만 자동 생성된 Docker context 이름은 `colima-shortchall-server`이기 때문이다. 목록의 `*`는 현재 선택된 context다.

`shortchall-server` context가 아직 없다면 최초 한 번 실행한다.

```bash
docker context create \
  --from colima-shortchall-server \
  shortchall-server
```

**이유:** 기존 context의 연결 정보를 복사해 짧은 이름의 context를 만든다. 새로운 가상 머신을 만드는 명령이 아니다. 두 context는 같은 Docker 엔진을 가리키므로 컨테이너·이미지·볼륨도 동일하게 보인다. [Docker context 생성 문서](https://docs.docker.com/reference/cli/docker/context/create/)

```bash
docker context use shortchall-server
docker context show
```

**이유:** 이후 `docker` 명령의 작업 대상을 선택하고 이름을 확인한다. 결과가 `shortchall-server`이면 성공이다. `use`는 이미 있는 context를 선택하므로 생성보다 먼저 실행할 수 없다.

Colima는 시작할 때 자동 생성한 context를 다시 선택할 수 있다. 따라서 재시작 뒤에도 `docker context use shortchall-server`를 실행하는 순서를 사용한다. [Colima 자동 선택 설정](https://colima.run/docs/configuration/#auto-activation)

## 5단계. 테스트 컨테이너로 연결 확인하기

```bash
docker run --rm hello-world
```

**이유:** 이미지 다운로드부터 컨테이너 실행까지 한 번에 확인한다. `--rm`은 실행이 끝난 테스트 컨테이너를 자동 삭제한다. 정상 실행 메시지가 나오면 Docker CLI와 엔진 연결이 준비된 것이다.

```bash
docker ps
```

**확인할 결과:** 오류 없이 목록이 출력되어야 한다. `hello-world`는 이미 종료·삭제되었으므로 목록이 비어 있어도 정상이다.

## 6단계. MySQL·RabbitMQ·Redis 실행하기

### 6-1. Compose 파일 준비

IntelliJ에서 개발 프로젝트를 열고 프로젝트 루트에 `compose.yaml`을 만든다. 이미 파일이 있다면 기존 프로젝트의 구성을 사용하며, 아래 예제로 덮어쓰지 않는다.

아래는 새 로컬 개발 환경용 예제다. 이미지 버전은 프로젝트와 맞추고 ARM64 지원 태그를 사용한다. 예제 비밀번호는 로컬 개발용이며 실제 서비스 비밀번호로 사용하지 않는다.

```yaml
name: shortchall-server

services:
  mysql:
    image: mysql:8.4
    environment:
      MYSQL_ROOT_PASSWORD: local-root-password
      MYSQL_DATABASE: shortchall
      MYSQL_USER: shortchall
      MYSQL_PASSWORD: local-dev-password
    ports:
      - "127.0.0.1:3306:3306"
    volumes:
      - mysql-data:/var/lib/mysql

  rabbitmq:
    image: rabbitmq:4-management
    hostname: shortchall-rabbitmq
    environment:
      RABBITMQ_DEFAULT_USER: shortchall
      RABBITMQ_DEFAULT_PASS: local-dev-password
    ports:
      - "127.0.0.1:5672:5672"
      - "127.0.0.1:15672:15672"
    volumes:
      - rabbitmq-data:/var/lib/rabbitmq

  redis:
    image: redis:8
    command: ["redis-server", "--appendonly", "yes"]
    ports:
      - "127.0.0.1:6379:6379"
    volumes:
      - redis-data:/data

volumes:
  mysql-data:
  rabbitmq-data:
  redis-data:
```

| 항목 | 설정 이유 |
| --- | --- |
| `name` | Compose 프로젝트 이름을 고정한다. Colima 프로필·context와는 별개의 이름이다. |
| `image` | 실행할 서비스와 버전을 선택한다. `management` 태그는 RabbitMQ 관리 UI를 포함한다. |
| `environment` | 초기 데이터베이스와 개발용 계정을 설정한다. |
| `ports` | Mac의 포트를 컨테이너 포트에 연결한다. `127.0.0.1`은 로컬 접속용 바인딩이다. |
| `volumes` | 컨테이너를 다시 만들어도 데이터를 보존할 저장소를 연결한다. |
| RabbitMQ `hostname` | 컨테이너 재생성 시에도 노드의 호스트 이름을 일정하게 유지한다. |
| Redis `--appendonly yes` | 데이터를 파일에 기록하는 AOF 영속화를 켠다. |

Named volume은 Colima VM 내부에 저장되므로 DB 파일이 Mac 폴더 공유를 거치지 않는다. 이 용도로 별도 `--network-address` 옵션은 필요하지 않다. [Docker 볼륨](https://docs.docker.com/engine/storage/volumes/), [포트 공개](https://docs.docker.com/engine/network/port-publishing/)

초기 계정 설정은 새 데이터 볼륨을 처음 초기화할 때 적용된다. 기존 데이터를 둔 채 환경 변수의 비밀번호만 바꿔도 저장된 계정 비밀번호가 자동으로 변경되지는 않는다. 이미지 설정은 [MySQL](https://hub.docker.com/_/mysql), [RabbitMQ](https://hub.docker.com/_/rabbitmq/), [Redis](https://hub.docker.com/_/redis) 공식 이미지 문서를 참고한다.

### 6-2. 구성 확인 후 실행

IntelliJ의 터미널 등에서 **`compose.yaml`이 있는 디렉터리**로 이동한 뒤 실행한다.

```bash
docker compose config --quiet
```

**이유:** 실행 전에 YAML과 Compose 설정 형식이 올바른지 확인한다. 출력 없이 성공하면 다음으로 진행한다.

```bash
docker compose up -d
```

**이유:** 파일에 정의한 세 서비스를 함께 생성·시작한다. `-d`는 백그라운드 실행으로 터미널을 계속 사용할 수 있게 한다. 처음에는 이미지 다운로드와 DB 초기화에 시간이 걸린다.

```bash
docker compose ps
docker compose logs -f
```

**확인할 결과:** 세 서비스가 실행 중이어야 한다. 실행 상태만으로 DB 초기화 완료가 보장되지는 않으므로 로그에서 준비 완료 여부나 오류를 확인한다. `logs -f`는 새 로그를 계속 보여 주며, `Control+C`로 로그 보기만 종료할 수 있다. 컨테이너는 계속 실행된다.

## 7단계. DataGrip과 IntelliJ에서 연결하기

위 Compose 예제를 사용했다면 다음 값으로 접속한다.

| 대상 | 주소 | 계정·설정 |
| --- | --- | --- |
| MySQL | `127.0.0.1:3306` | DB `shortchall`, 사용자 `shortchall`, 비밀번호 `local-dev-password` |
| RabbitMQ | `127.0.0.1:5672` | 사용자 `shortchall`, 비밀번호 `local-dev-password`, vhost `/` |
| RabbitMQ 관리 UI | `http://127.0.0.1:15672` | RabbitMQ와 같은 계정 |
| Redis | `127.0.0.1:6379` | 예제에서는 인증 미설정 |

DataGrip에서 MySQL 데이터 소스를 만들고 표의 호스트·포트·DB·계정을 입력해 연결을 테스트한다. IntelliJ에서 실행하는 애플리케이션의 DB·메시지 큐·캐시 설정에도 같은 값을 사용한다.

**이유:** 애플리케이션과 DataGrip은 Mac에서 실행되므로 Compose가 공개한 Mac 포트로 접속한다. 나중에 애플리케이션도 같은 Compose 안에서 실행한다면 호스트는 `mysql`, `rabbitmq`, `redis`라는 서비스 이름을 사용한다. 컨테이너 안의 `127.0.0.1`은 그 컨테이너 자신을 뜻한다.

접속되지 않으면 먼저 `docker compose ps`와 해당 서비스 로그(예: `docker compose logs mysql`)를 확인한다. 포트가 이미 사용 중이라면 호스트 쪽 포트를 바꾼다. 예를 들어 `127.0.0.1:3307:3306`으로 설정하면 DataGrip에서도 포트 `3307`을 사용한다.

## 8단계. 다음 날 다시 시작하고 작업 종료하기

### 작업 시작

```bash
colima start shortchall-server
docker context use shortchall-server
```

가상 머신을 시작하고 Docker의 작업 대상을 선택한다. 처음 지정한 자원 옵션은 저장되어 있으므로 매번 반복할 필요가 없다.

프로젝트의 `compose.yaml`이 있는 디렉터리에서 실행한다.

```bash
docker compose up -d
docker compose ps
```

필요한 서비스를 시작하고 실행 상태를 확인한다.

### 작업 종료

```bash
docker compose stop
colima stop shortchall-server
```

먼저 프로젝트의 컨테이너를 중지하고, 이어서 가상 머신을 중지해 자원을 반환한다. 데이터 볼륨은 유지된다. Colima를 중지하면 그 프로필 안의 모든 컨테이너가 중지된다.

컨테이너와 프로젝트 네트워크까지 정리하고 싶을 때는 `stop` 대신 다음을 사용한다.

```bash
docker compose down
```

Named volume은 남으므로 다음 `up -d`에서 재사용한다. **`down -v`는 볼륨 데이터도 삭제하므로 데이터를 유지할 때 사용하지 않는다.**

## 선택 설정 A. 자원이 부족할 때 조정하기

```bash
docker context use shortchall-server
docker stats
```

**이유:** 컨테이너별 CPU·메모리 사용량을 확인하고 증설 필요성을 판단한다. Mac의 활성 상태 보기에서 메모리 압력도 함께 확인한다. `Control+C`로 조회를 종료한다.

대량 데이터 적재나 메시지 처리 중 부족함이 확인되면 다음과 같이 늘려 본다.

```bash
colima stop shortchall-server
colima start shortchall-server --cpus 6 --memory 12
docker context use shortchall-server
```

재시작 후 프로젝트 디렉터리에서 `docker compose up -d`를 실행한다. 디스크를 늘리려면 현재보다 큰 값으로 `--disk`를 추가한다. 기존 디스크는 축소할 수 없다.

파일로 설정을 편집하려면 다음을 사용한다.

```bash
colima stop shortchall-server
colima start shortchall-server --edit
docker context use shortchall-server
```

설정 파일은 `~/.colima/shortchall-server/colima.yaml`이다. 기존 파일의 해당 항목을 수정한다. CLI의 `--cpus`는 YAML에서는 `cpu`다.

```yaml
cpu: 6
memory: 12
disk: 100
```

전체 옵션은 `colima start --help`로 확인한다. VM 종류·아키텍처·마운트 방식처럼 생성 이후 변경에 제약이 있는 설정은 새 프로필로 구성한다. 기존 데이터는 자동 이전되지 않는다. 기본 프로필을 사용하는 경우에는 Colima 명령의 프로필 이름을 생략하며, 설정 파일은 `~/.colima/default/colima.yaml`이다. [Colima 설정 문서](https://colima.run/docs/configuration/)

## 선택 설정 B. amd64 전용 이미지가 필요할 때

ARM64 이미지로 개발할 때는 Rosetta가 필요하지 않다. Apple Silicon의 VZ 환경에서 amd64 전용 이미지를 실행해야 할 때 다음 옵션을 추가한다.

```bash
colima stop shortchall-server
colima start shortchall-server --vz-rosetta
docker context use shortchall-server
docker run --rm --platform linux/amd64 hello-world
```

**이유:** `--vz-rosetta`는 amd64 실행을 위한 Rosetta 지원을 켜고, `--platform linux/amd64`는 테스트할 이미지 아키텍처를 명시한다. VM 자체는 ARM64로 유지한다. [Colima Rosetta 설정](https://colima.run/docs/configuration/#rosetta)

## 선택 설정 C. 자동 생성된 context 정리하기

이 단계는 선택 사항이다. 두 context를 그대로 두어도 같은 가상 머신에 연결한다.

```bash
docker context use shortchall-server
docker context rm colima-shortchall-server
docker context ls
```

**이유:** 사용할 context로 먼저 전환하고, 불필요한 연결 설정만 제거한다. 가상 머신과 컨테이너·이미지·볼륨은 삭제되지 않는다.

Colima가 관리하는 context이므로 다음 `colima start shortchall-server`에서 다시 생성될 수 있다. 영구적인 이름 변경은 아니며, 재시작 후 원하는 context를 다시 선택하면 된다.

## 선택 설정 D. 원격 서버의 Docker 조회하기

### 등록된 연결 확인

```bash
docker context ls
```

**이유:** 현재 Mac에 저장된 연결 설정을 확인한다. 원격 서버를 자동 검색하는 명령은 아니다. `DOCKER ENDPOINT`가 실제 연결 대상이며 다음은 예시다.

```text
NAME                   DOCKER ENDPOINT
shortchall-server *    unix:///Users/<사용자>/.colima/shortchall-server/docker.sock
remote-dev             ssh://ubuntu@dev.example.com
```

이미 등록된 원격 context의 상세 정보를 보려면 실행한다.

```bash
docker context inspect remote-dev
```

이 명령은 저장된 설정을 보여 주며, 서버 연결 성공을 보장하지는 않는다. [Docker context 문서](https://docs.docker.com/engine/manage-resources/contexts/)

### 원격 서버가 등록되어 있지 않다면

원격 서버에 Docker가 실행 중이고 SSH 접속이 가능해야 한다. SSH 계정에는 원격 Docker 소켓 접근 권한도 필요하다. 아래 계정과 주소를 실제 값으로 바꿔 최초 한 번 등록한다.

```bash
docker context create remote-dev \
  --docker "host=ssh://ubuntu@dev.example.com"
```

**이유:** SSH를 통해 원격 Docker 엔진에 접속할 연결 정보를 Mac에 저장한다. 서버 생성이나 Docker 설치를 수행하는 명령은 아니다. [Docker SSH 연결 안내](https://docs.docker.com/engine/security/protect-access/)

### 원격 컨테이너 조회

```bash
docker --context remote-dev ps -a
```

**이유:** 이 명령만 원격 엔진에 실행한다. 현재 선택된 로컬 context는 유지되며, `-a`로 중지된 컨테이너까지 확인한다.

원격 서버를 계속 작업 대상으로 사용하려면 다음과 같이 전환한다.

```bash
docker context use remote-dev
docker ps -a

# 원격 작업 후 로컬 개발 환경으로 복귀
docker context use shortchall-server
```

## 명령 빠르게 찾기

| 목적 | 명령 |
| --- | --- |
| 가상 머신 상태 | `colima status shortchall-server` |
| 현재 Docker 연결 확인 | `docker context show` |
| 전체 연결 설정 목록 | `docker context ls` |
| 현재 프로젝트 상태 | `docker compose ps` |
| MySQL 로그 확인 | `docker compose logs -f mysql` |
| 모든 컨테이너 조회 | `docker ps -a` |
| 이미지 목록 | `docker images` |
| 데이터 볼륨 목록 | `docker volume ls` |
| 자원 사용량 | `docker stats` |

## 참고 문서와 다른 선택지

- [Colima 설치](https://colima.run/docs/installation/)
- [Colima 옵션과 설정 파일](https://colima.run/docs/configuration/)
- [Homebrew Compose 플러그인 설정](https://formulae.brew.sh/formula/docker-compose)
- [Docker Compose 시작하기](https://docs.docker.com/compose/gettingstarted/)
- [Docker context 관리](https://docs.docker.com/engine/manage-resources/contexts/)
- [원격 Docker에 SSH로 연결하기](https://docs.docker.com/engine/security/protect-access/)

GUI로 컨테이너를 관리하고 싶다면 [OrbStack](https://docs.orbstack.dev/)도 Docker Desktop의 대안이다.
