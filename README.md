# Perfect NixOS

Omarchy-style Hyprland for Apple Silicon Macs.

## One-Command Install

From macOS Terminal:

```bash
curl -sL https://raw.githubusercontent.com/p4ulcristian/nixos-asahi/main/asahi-install.sh | sh
```

This will:
1. Install Asahi partition (if needed)
2. Download Perfect NixOS installer
3. Flash to USB
4. Give you boot instructions

## Manual Install

```bash
# 1. From macOS - create partition
curl https://alx.sh | sh

# 2. Download installer ISO from Releases
# 3. Flash to USB and boot

# 4. In installer, run:
curl -sL https://raw.githubusercontent.com/p4ulcristian/nixos-asahi/main/install.sh | sudo bash
```

## After Install

```bash
# Edit config
sudo nano /etc/nixos/common.nix

# Apply changes
sudo nixos-rebuild switch --flake /etc/nixos#mac
```

## Keys

| Key | Action |
|-----|--------|
| `ALT + Return` | Terminal |
| `ALT + D` | Walker launcher |
| `ALT + Q` | Close window |
| `ALT + 1-6` | Switch workspace |

## Sidebar

| Button | Action |
|--------|--------|
| 1-5 | Switch workspace |
| VOL | Click mute, scroll adjust |
| BRI | Scroll adjust |
| NET | Click → nmtui |
| SYS | Click → btop |
