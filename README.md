# Cross-Platform Init Setup Guide

> [!NOTE]
> This initialization setup provides cross-platform compatibility for Windows (PowerShell), WSL (bash), and Android (Termux) environments.

## Project Structure

```
.
├── config/           # Configuration files
│   ├── git/         # Git configurations
│   ├── ssh/         # SSH configs
│   └── shell/       # Shell configurations
├── resources/       # Static resources
│   ├── desktop/     # Windows desktop files
│   └── startup/     # Windows startup items
├── scripts/         # Scripts for each platform
│   ├── android/     # Android scripts
│   │   ├── termux/  # Quick launch scripts (widgets)
│   │   └── utils/   # Utility scripts
│   ├── windows/     # PowerShell scripts
│   └── wsl/         # WSL/Linux scripts
├── secrets/         # Personal keys and configs (not in git)
├── setup.ps1        # Windows setup script
└── setup.sh         # WSL/Android setup script
```

## Configuration

> [!NOTE]
> The setup script will prompt for Git credentials during installation.
>
> For manual configuration:
>
> 1. Copy `config/git/.gitconfig-template` to `~/.gitconfig`
> 2. Replace `{USERNAME}` and `{EMAIL}` with your details

> [!CAUTION]
> Place your personal keys in the `secrets/` directory:
>
> ```
> secrets/
> ├── gpg/
> │   ├── private.asc
> │   └── public.asc
> └── ssh/
>     ├── id_*
>     └── *.pub
> ```

## Platform Setup

> [!WARNING]
> Windows: Enable PowerShell script execution
>
> ```powershell
> # Temporary (current session)
> Set-ExecutionPolicy Bypass -Scope Process
>
> # Permanent (current user)
> Set-ExecutionPolicy RemoteSigned -Scope CurrentUser
> ```

> [!NOTE]
> Android: Enable Termux storage access with `termux-setup-storage`
>
> Optional: Install "Termux:Widget" from F-Droid for quick launch functionality
