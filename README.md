# Perfect NixOS

Omarchy-style Hyprland desktop for Apple Silicon Macs.

![Hyprland](https://img.shields.io/badge/Hyprland-wayland-blue)
![NixOS](https://img.shields.io/badge/NixOS-unstable-purple)
![Apple Silicon](https://img.shields.io/badge/Apple%20Silicon-M1%2FM2%2FM3-orange)

## Features

- **Hyprland** compositor with smooth animations, blur, rounded corners
- **QuickShell** Qt6/QML sidebar with workspace switcher
- **Fuzzel** app launcher + **hyprlock** screen lock
- Pre-configured dev tools (Clojure, JavaScript/Bun, VS Code)
- Apps: Chromium, Vesktop, 1Password

---

## Installation on Apple Silicon Mac

### Step 1: Prepare macOS

You need at least **50GB** of free disk space.

Open Terminal in macOS and run:

```bash
curl https://alx.sh | sh
```

This installs the Asahi Linux bootloader stub. Follow the prompts to:
- Resize your macOS partition
- Create space for Linux
- Install the UEFI boot environment

**Reboot** when prompted and hold the power button to enter startup options.

### Step 2: Boot NixOS Installer

Download the NixOS ARM64 installer with Apple Silicon support:

Option A - Use nixos-apple-silicon installer:
```bash
# See: https://github.com/tpwrules/nixos-apple-silicon/releases
```

Option B - Build your own installer ISO (from another NixOS machine):
```bash
nix build github:tpwrules/nixos-apple-silicon#installer-bootstrap
```

Write the ISO to a USB drive and boot from it (hold power button → Options → USB).

### Step 3: Connect to Network

Once booted into the NixOS installer:

```bash
# WiFi
nmcli device wifi connect "YOUR_SSID" password "YOUR_PASSWORD"

# Or wired
nmcli device connect eth0
```

### Step 4: Run the Installer

**One-liner install:**

```bash
curl -sL https://raw.githubusercontent.com/p4ulcristian/nixos-asahi/main/install.sh | sudo bash
```

**Or manual install:**

```bash
sudo -i

# Find your Linux partition (created by Asahi)
lsblk

# Format root partition
mkfs.ext4 -L nixos /dev/nvme0n1pX

# Mount
mount /dev/nvme0n1pX /mnt
mkdir -p /mnt/boot
mount /dev/nvme0n1p1 /mnt/boot  # EFI partition

# Clone config
git clone https://github.com/p4ulcristian/nixos-asahi.git /mnt/etc/nixos

# Edit username if needed
nano /mnt/etc/nixos/common.nix

# Install
nixos-install --flake /mnt/etc/nixos#mac

# Set password
nixos-enter --root /mnt -c "passwd paul"

# Reboot
reboot
```

### Step 5: First Boot

1. Hold power button during boot
2. Select **NixOS** from the boot menu
3. Login with your username and password
4. Hyprland starts automatically

---

## Keybindings

| Key | Action |
|-----|--------|
| `ALT + Return` | Terminal (foot) |
| `ALT + D` | App launcher (fuzzel) |
| `ALT + Q` | Close window |
| `ALT + F` | Fullscreen |
| `ALT + V` | Toggle floating |
| `ALT + L` | Lock screen |
| `ALT + M` | Exit Hyprland |
| `ALT + 1-6` | Switch workspace |
| `ALT + Shift + 1-6` | Move window to workspace |
| `ALT + Arrow/HJKL` | Move focus |
| `ALT + Mouse drag` | Move/resize windows |

---

## Updating Your System

After editing config files:

```bash
sudo nixos-rebuild switch --flake /etc/nixos#mac
```

Pull latest changes:

```bash
cd /etc/nixos
git pull
sudo nixos-rebuild switch --flake .#mac
```

---

## Testing in VM

Build and run the VM (on aarch64-linux):

```bash
nix build .#vm
./result/bin/run-perfect-vm
```

---

## Customization

### Change username

Edit `common.nix`:
```nix
users.users.YOUR_NAME = {
  isNormalUser = true;
  ...
};
```

### Change wallpaper

```bash
swww img ~/path/to/wallpaper.jpg --transition-type grow
```

### Add packages

Edit `common.nix` in `environment.systemPackages`:
```nix
environment.systemPackages = with pkgs; [
  # Add your packages here
  firefox
  spotify
];
```

---

## Project Structure

```
nixos-asahi/
├── flake.nix          # Nix flake (defines mac + vm builds)
├── common.nix         # Desktop config, packages, Hyprland settings
├── hardware-mac.nix   # Apple Silicon hardware config
├── hardware-vm.nix    # VM hardware config
├── install.sh         # Bootstrap installer script
└── README.md
```

---

## Troubleshooting

**WiFi not working?**
```bash
# Load firmware
sudo modprobe brcmfmac
```

**No sound?**
Apple Silicon audio requires additional firmware. Check nixos-apple-silicon docs.

**Touchpad not working?**
Add to `hardware-mac.nix`:
```nix
hardware.asahi.peripheralFirmwareDirectory = ./firmware;
```

---

## Credits

- Inspired by [Omarchy](https://omarchy.com)
- Built on [nixos-apple-silicon](https://github.com/tpwrules/nixos-apple-silicon)
- Desktop: [Hyprland](https://hyprland.org) + [QuickShell](https://quickshell.outfoxxed.me)
