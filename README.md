# krinry-flutter

A mobile-first Flutter CLI that lets you build, run and manage Flutter apps on Android phones using Termux and cloud builds — **without a PC**.

## ✨ Features

- 📱 **Mobile-first**: Designed for Termux on Android
- ☁️ **Cloud builds**: Build APKs using GitHub Actions (no heavy local tools needed)
- ⚡ **One-command experience**: Simple, intuitive CLI
- 🔒 **Secure**: Never stores tokens, uses GitHub CLI for auth

## 🚀 Quick Install

```bash
curl -fsSL https://raw.githubusercontent.com/krinry/krinry-flutter/main/install.sh | bash
```

This will:
- Install required packages (git, gh, curl, jq)
- Clone krinry-flutter
- Set up the CLI in your PATH
- Guide you through GitHub authentication

## 📖 Commands

### Install Flutter

```bash
krinry-flutter install flutter
```

Downloads and configures Flutter SDK for Termux.

### Check Setup

```bash
krinry-flutter doctor
```

Verifies all requirements:
- ✓ Flutter installed
- ✓ Git installed
- ✓ GitHub CLI authenticated
- ✓ Project configuration

### Initialize Project

```bash
krinry-flutter init
```

Sets up cloud build for your Flutter project:
- Creates GitHub Actions workflow
- Creates `.krinry-flutter.yaml` config

### Build APK

```bash
krinry-flutter build apk --release
krinry-flutter build apk --debug
```

Triggers a cloud build and downloads the APK:
1. Pushes your code to GitHub
2. Triggers GitHub Actions workflow
3. Shows real-time build progress
4. Downloads APK to `build/app/outputs/flutter-apk/`

## 📋 Requirements

- Android phone with [Termux](https://termux.dev/)
- GitHub account
- Internet connection

## 🔧 How It Works

```
┌─────────────┐     ┌─────────────┐     ┌─────────────┐
│   Termux    │────▶│   GitHub    │────▶│   Actions   │
│ krinry-cli  │     │    API      │     │   Runner    │
└─────────────┘     └─────────────┘     └─────────────┘
       ▲                                       │
       │                                       ▼
       │                               ┌─────────────┐
       └───────────────────────────────│  APK File   │
                  Download             └─────────────┘
```

1. **You code** on your phone using any editor
2. **Run** `krinry-flutter build apk`
3. **CLI pushes** your code to GitHub
4. **GitHub Actions** builds the APK in the cloud
5. **CLI downloads** the APK to your phone

## 🛠️ Configuration

Configuration is stored in `.krinry-flutter.yaml`:

```yaml
project:
  name: my_app
  type: flutter

build:
  apk:
    artifact: app-release.apk
    output_path: build/app/outputs/flutter-apk

cloud:
  provider: github
  workflow: krinry-flutter-build.yml
  poll_interval: 8
```

## 🐛 Troubleshooting

### "gh: command not found"

Install GitHub CLI:
```bash
pkg install gh
```

### "Not authenticated"

Login to GitHub:
```bash
gh auth login
```

### "Workflow not found"

Initialize your project:
```bash
krinry-flutter init
git add .
git commit -m "Add cloud build"
git push
```

### Build failed

Check the logs:
```bash
gh run view --log-failed
```

## 🤝 Contributing

Contributions welcome! Please read the PRD in `prd.md` before contributing.

## 📄 License

MIT License - see [LICENSE](LICENSE)

---

Made with ❤️ for mobile developers
