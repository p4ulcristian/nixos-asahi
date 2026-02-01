# Perfect NixOS

Omarchy-style Hyprland desktop for Apple Silicon Macs.

## Install

1. Run Asahi installer from macOS (needs 50GB free):
   ```bash
   curl https://alx.sh | sh
   ```

2. Boot NixOS installer from USB ([download](https://github.com/tpwrules/nixos-apple-silicon/releases))

3. Connect to WiFi and install:
   ```bash
   nmcli device wifi connect "SSID" password "PASSWORD"
   curl -sL https://raw.githubusercontent.com/p4ulcristian/nixos-asahi/main/install.sh | sudo bash
   ```

4. Reboot and select NixOS from boot menu

## Keybindings

`ALT` + `Return` terminal | `D` launcher | `Q` close | `1-6` workspaces
