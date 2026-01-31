# krinry

A multi-purpose CLI for mobile developers. Build Flutter apps on Android phones using Termux and cloud builds — **without a PC**.

## ✨ Features

- 📱 **Mobile-first**: Designed for Termux on Android
- ☁️ **Cloud builds**: Build APKs using GitHub Actions (no heavy local tools needed)
- 🔌 **Extensible**: Modular tool system for future expansions
- ⚡ **One-command experience**: Simple, intuitive CLI
- 🔒 **Secure**: Never stores tokens, uses GitHub CLI for auth

## 🚀 Quick Install

```bash
curl -fsSL https://raw.githubusercontent.com/krinry/krinry/main/install.sh | bash
```

This will:
- Install required packages (git, gh, curl, jq, termux-api)
- Clone krinry
- Set up the CLI in your PATH
- Guide you through GitHub authentication

## 📖 Commands

### Global

```bash
krinry --help       # Show all commands
krinry update       # Update to latest version
```

### Flutter Tool

```bash
krinry flutter install      # Install Flutter SDK
krinry flutter doctor       # Check system requirements
krinry flutter init         # Initialize cloud build
krinry flutter build apk    # Build APK in cloud
krinry flutter run web      # Run Flutter web server locally
```

## 📋 Requirements

- Android phone with [Termux](https://termux.dev/)
- GitHub account
- Internet connection

## 🔧 How It Works

```
┌─────────────┐     ┌─────────────┐     ┌─────────────┐
│   Termux    │────▶│   GitHub    │────▶│   Actions   │
│ krinry cli  │     │    API      │     │   Runner    │
└─────────────┘     └─────────────┘     └─────────────┘
       ▲                                       │
       │                                       ▼
       │                               ┌─────────────┐
       └───────────────────────────────│  APK File   │
                  Download             └─────────────┘
```

1. **You code** on your phone using any editor
2. **Run** `krinry flutter build apk`
3. **CLI pushes** your code to GitHub
4. **GitHub Actions** builds the APK in the cloud
5. **CLI downloads** the APK to your phone

## 🛠️ Configuration

Configuration is stored in `.krinry.yaml`:

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
  workflow: krinry-build.yml
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
krinry flutter init
git add .
git commit -m "Init"
git push
```

### Build failed

Check the logs:
```bash
gh run view --log-failed
```

## 🔌 Extensibility

krinry is designed to be extensible. Future tools can be added under the `tools/` directory:

```
krinry xyz ...     # Custom tool
krinry abc ...     # Another tool
```

## 🤝 Contributing

Contributions welcome! Please read the PRD in `prd.md` before contributing.

## 📄 License

MIT License - see [LICENSE](LICENSE)

---

Made with ❤️ for mobile developers
