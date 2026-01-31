1. Product name

krinry-flutter

2. One-line vision

A mobile-first Flutter CLI that lets users build, run and manage Flutter apps on Android phones using Termux and cloud builds — without a PC.

3. Background & problem

Aaj Flutter ecosystem almost poora PC-centric hai.

Mobile-only users (especially students) ko ye problems hoti hain:

Android phone par Flutter install karna mushkil

Local flutter build apk Termux me fail ho jata hai

Heavy build tools (SDK, Gradle, Java) phone par stable nahi

Koi simple CLI nahi jo:

phone ko primary dev machine bana sake

aur build ko cloud par shift kar de

Tum khud iss problem ko face kar chuke ho (Termux + APK build fail).

4. Target users
Primary users

Students

Low-end PC ya no-PC users

Android phone + Termux users

Flutter beginners

Secondary users

Developers jo cloud build + CLI automation chahte hain

5. Goals

krinry-flutter ke goals:

Phone ko Flutter development device banana

Flutter installation ko automate karna (Termux focused)

Local Flutter commands ka cloud equivalent dena

One-command experience dena

6. Non-goals (out of scope – v1)

iOS build support

Emulator management

Desktop OS support

GUI / app UI

7. Core philosophy

krinry-flutter Flutter ko replace nahi karega.

Ye:

Flutter CLI ke upar ek mobile-friendly automation layer hoga.

8. High-level architecture
User (Termux)
   |
krinry-flutter CLI
   |
GitHub API (via gh CLI)
   |
Cloud runner
   |
APK artifact
   |
Download → local build folder


Cloud build backend:
GitHub Actions

9. Installation experience
Primary install method

Single command:

curl -fsSL <install_url> | bash


Installer responsibilities:

Detect Termux

Install required packages

Install GitHub CLI

Login / verify GitHub auth

Clone krinry-flutter repo

Install binary in $PREFIX/bin

Print quick help

10. Supported platforms (v1)
Platform	Supported
Termux on Android	Yes
Linux desktop	Experimental
Windows / macOS	No
11. Command structure (v1)

Base command:

krinry-flutter

11.1 Flutter setup
krinry-flutter install flutter


Responsibilities:

Download Flutter SDK

Configure PATH

Run flutter doctor

Cache common artifacts

Store install metadata

11.2 Doctor command
krinry-flutter doctor


Checks:

Flutter binary available

Git installed

gh installed

GitHub auth valid

Workflow file present

Repo linked

11.3 Build command (main feature)
krinry-flutter build apk [--release|--debug]


Behaviour:

Validate git repo

Commit working tree (or warn)

Trigger cloud workflow

Poll build status

Stream progress

Download artifact

Save at:

build/app/outputs/flutter-apk/


Goal:

Same path as official Flutter output.

11.4 Run command (future v2)
krinry-flutter run


Planned behaviour:

Trigger cloud build

Download APK

Install locally using adb

Launch app

11.5 Init command
krinry-flutter init


Responsibilities:

Create GitHub workflow

Add default build.yml

Validate Flutter project

Configure artifact name

Save krinry-flutter config

12. Required cloud workflow

krinry-flutter will generate and manage:

.github/workflows/krinry-flutter-build.yml


The workflow must:

Checkout repo

Setup Flutter

Run flutter pub get

Run flutter build apk

Upload artifact

13. Configuration file

A local project file:

.krinry-flutter.yaml


Example:

project:
  type: flutter
build:
  apk:
    artifact: app-release.apk
    output_path: build/app/outputs/flutter-apk
cloud:
  provider: github
  workflow: krinry-flutter-build.yml

14. Authentication model

Authentication is delegated to:

GitHub CLI (gh auth login)

krinry-flutter never stores:

tokens

passwords

It only checks auth state.

15. Progress & logging

During build:

krinry-flutter build apk


Output must show:

build start

queued

in_progress

completed

success / failure

On failure:

automatically fetch workflow logs

16. Error handling
Typical errors and behaviour
Case	Behaviour
No gh installed	auto install gh
Not logged in	prompt gh auth login
Workflow missing	offer to run krinry-flutter init
Build failed	show logs + run link
No internet	show offline message
17. Security model

CLI only triggers workflows in current repo

No arbitrary repo execution

No secret injection from CLI

All secrets remain inside GitHub repository settings

18. Performance requirements

CLI startup < 1 second

Poll interval configurable (default 8 seconds)

APK download must resume on retry

19. Telemetry

None.

No tracking, no analytics.

20. Versioning

Semantic versioning:

vMAJOR.MINOR.PATCH


Example:

v1.0.0

21. Licensing

MIT License

22. Branding

CLI name:

krinry-flutter


Repo name:

krinry-flutter


Command prefix:

krinry-flutter <command>

23. MVP scope (first public release)

Only these commands:

krinry-flutter install flutter
krinry-flutter init
krinry-flutter doctor
krinry-flutter build apk --release

24. Success criteria

The product is successful if:

A user can:

install Flutter on phone

create a Flutter app

run one command

get a working APK in build folder

without touching any PC

25. Roadmap
v1

Install

Init

Doctor

Build APK (cloud)

v2

run (adb install + launch)

build appbundle

log streaming

cache flutter version

v3

plugin system

multiple cloud backends

template workflows