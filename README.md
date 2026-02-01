# Perfect NixOS

Omarchy-style Hyprland for Apple Silicon Macs.

## Install

```bash
# 1. From macOS - create Linux partition (50GB+)
curl https://alx.sh | sh
# Select "UEFI environment only" option

# 2. Download NixOS Asahi installer
# https://github.com/tpwrules/nixos-apple-silicon/releases

# 3. Flash to USB and boot (hold power button → Options → USB)

# 4. Connect WiFi and run installer
nmcli device wifi connect "SSID" password "PASS"
curl -sL https://raw.githubusercontent.com/p4ulcristian/nixos-asahi/main/install.sh | sudo bash
```

Reboot → hold power → select NixOS → done.

## After Install

```bash
# Edit config
sudo nano /etc/nixos/common.nix

# Apply changes
sudo nixos-rebuild switch --flake /etc/nixos#mac

# Or pull updates
cd /etc/nixos && git pull
sudo nixos-rebuild switch --flake .#mac
```

## Keys

`ALT` + `Return` terminal | `D` launcher | `Q` close | `1-6` workspaces

## Sidebar

- **1-5**: Switch workspace
- **VOL**: Click mute, scroll adjust
- **BRI**: Scroll adjust
- **NET**: Click → nmtui
- **SYS**: Click → btop
