# Perfect NixOS

Omarchy-style Hyprland for Apple Silicon Macs.

## Install

```bash
# 1. From macOS - create Linux partition (50GB+)
curl https://alx.sh | sh

# 2. Boot NixOS USB, connect WiFi, install
nmcli device wifi connect "SSID" password "PASS"
curl -sL https://raw.githubusercontent.com/p4ulcristian/nixos-asahi/main/install.sh | sudo bash
```

Reboot → select NixOS → done.

## Keys

`ALT` + `Return` terminal | `D` launcher | `Q` close | `1-6` workspaces
