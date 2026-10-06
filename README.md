# Cinematic Loading Screen

A loading screen replacement for Project Zomboid Build 42

Plays a full-screen looping video with synchronized audio while the game is loading

The mod runs on the client and does not modify your world, character, inventory, server database, or save files

## English

### Install

Subscribe to Cinematic Loading Screen on the Steam Workshop and wait for Steam to finish downloading it

Download `Install.bat` from this repository and run it once

The installer finds the Workshop files automatically, so you do not need to locate the Steam Workshop folder yourself

Restart Project Zomboid after installation

### Uninstall

Run `Uninstall.bat` or `UNINSTALL.ps1`

### Installer

Administrator privileges are not required

The installer does not download external files, send telemetry, install background services, or change the Windows registry

It copies the included runtime to your local Zomboid folder and adds the Java agent required for video playback

`ProjectZomboid64.json` is backed up before it is changed

If PZ_Optimization is installed, the installer can adjust its loading screen setting when required and backs up the original configuration first

### Multiplayer

The loading screen runs on the client

Dedicated servers do not need the Java agent installed

Dedicated server connection, loading, and normal world entry have been tested on Project Zomboid Build 42

### Compatibility

Made for Project Zomboid Build 42

PZ_Optimization has also been tested together with this mod

Changes to Project Zomboid's loading or rendering system may require another compatibility update

### Mod

**Mod Name:** Cinematic Loading Screen  
**Mod ID:** `CinematicLoadingScreen`  
**Author:** `bongmyung-ye`

---

## 한국어

Cinematic Loading Screen은 프로젝트 좀보이드의 기존 로딩 화면을 전체 화면 영상과 동기화된 오디오로 변경하는 모드입니다.

클라이언트에서 동작하며 월드, 캐릭터, 인벤토리, 서버 데이터베이스 또는 세이브 파일은 수정하지 않습니다.

### 설치

Steam 창작마당에서 Cinematic Loading Screen을 구독한 뒤 다운로드가 완료될 때까지 기다려 주세요.

이 저장소에서 `Install.bat` 파일을 다운로드한 뒤 한 번 실행해 주세요.

설치 파일이 Steam 라이브러리에서 해당 창작마당 모드를 자동으로 찾기 때문에 Workshop 폴더를 직접 찾아갈 필요는 없습니다.

설치가 완료되면 프로젝트 좀보이드를 다시 실행해 주세요.

### 제거

`Uninstall.bat` 또는 `UNINSTALL.ps1`을 실행하면 제거할 수 있습니다.

### 설치 파일

관리자 권한은 필요하지 않습니다.

설치 과정에서 외부 파일을 다운로드하거나 텔레메트리를 전송하지 않으며, 백그라운드 서비스를 설치하거나 Windows 레지스트리를 변경하지 않습니다.

모드에 포함된 런타임을 사용자의 Zomboid 폴더에 복사하고 영상 재생에 필요한 Java agent 항목을 게임 시작 설정에 추가합니다.

`ProjectZomboid64.json`은 변경하기 전에 자동으로 백업됩니다.

PZ_Optimization을 함께 사용하고 있는 경우 필요한 경우에만 로딩 화면 관련 설정을 조정하며, 기존 설정은 변경 전에 백업됩니다.

### 멀티플레이

로딩 화면은 클라이언트에서 동작합니다.

데디케이트 서버 자체에는 Java agent를 설치할 필요가 없습니다.

Project Zomboid Build 42 데디케이트 서버에서 접속, 로딩 화면 표시, 정상적인 월드 진입까지 테스트했습니다.

### 호환성

Project Zomboid Build 42를 대상으로 제작되었습니다.

PZ_Optimization과 함께 사용하는 환경도 테스트했습니다.

향후 프로젝트 좀보이드의 로딩 또는 렌더링 구조가 변경될 경우 호환성 업데이트가 필요할 수 있습니다.

### 모드 정보

**모드 이름:** Cinematic Loading Screen  
**모드 ID:** `CinematicLoadingScreen`  
**제작자:** `bongmyung-ye`
