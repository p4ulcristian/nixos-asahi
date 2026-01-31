# Shared config for both VM and real M2 Mac
{ config, pkgs, lib, caelestia-shell, system, ... }:

{
  # ----- NETWORKING -----
  networking.hostName = "perfect";
  networking.networkmanager.enable = true;

  # ----- DESKTOP: Hyprland + Caelestia -----
  programs.hyprland.enable = true;

  # Auto-login
  services.getty.autologinUser = "paul";
  environment.loginShellInit = ''
    if [ -z "$DISPLAY" ] && [ "$XDG_VTNR" = 1 ]; then
      exec Hyprland
    fi
  '';

  # XDG Portal
  xdg.portal = {
    enable = true;
    extraPortals = [ pkgs.xdg-desktop-portal-hyprland ];
  };

  # ----- USER -----
  users.users.paul = {
    isNormalUser = true;
    extraGroups = [ "wheel" "networkmanager" "video" "input" "audio" ];
    initialPassword = "nixos";
    packages = [
      caelestia-shell.packages.${system}.default
    ];
  };
  security.sudo.wheelNeedsPassword = false;

  # ----- PACKAGES -----
  environment.systemPackages = with pkgs; [
    # Core
    vim neovim git htop btop fastfetch wget curl

    # Hyprland
    kitty foot wofi fuzzel wl-clipboard grim slurp
    swww mako brightnessctl pamixer playerctl

    # Dev - Clojure
    clojure
    leiningen
    babashka
    clojure-lsp

    # Dev - JavaScript
    bun
    nodejs

    # Apps
    firefox
    vesktop          # Discord client (works on ARM)
    _1password-gui
    _1password-cli

    # Theming
    adwaita-icon-theme papirus-icon-theme
  ];

  # ----- FONTS -----
  fonts.fontconfig.enable = true;
  fonts.packages = with pkgs; [
    noto-fonts noto-fonts-cjk-sans noto-fonts-color-emoji
    nerd-fonts.jetbrains-mono nerd-fonts.fira-code
    nerd-fonts.caskaydia-cove
    rubik
    material-symbols
  ];

  # ----- SERVICES -----
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    pulse.enable = true;
  };

  services.upower.enable = true;
  services.power-profiles-daemon.enable = true;
  hardware.bluetooth.enable = true;
  services.blueman.enable = true;
  services.openssh.enable = true;

  # ----- HYPRLAND CONFIG -----
  environment.etc."hypr/hyprland.conf".text = ''
    # Monitor - VM uses 1080p, Mac will auto-detect
    monitor=,1920x1080@60,auto,1

    # Auto-start
    exec-once = caelestia-shell
    exec-once = swww init

    # Input
    input {
      kb_layout = us
      follow_mouse = 1
      sensitivity = 0.3
    }

    # General
    general {
      gaps_in = 5
      gaps_out = 10
      border_size = 2
      col.active_border = rgba(33ccffee)
      col.inactive_border = rgba(595959aa)
      layout = dwindle
    }

    # Decoration
    decoration {
      rounding = 10
      blur {
        enabled = true
        size = 3
        passes = 1
      }
      shadow {
        enabled = true
        range = 4
        render_power = 3
      }
    }

    # Animations
    animations {
      enabled = true
      bezier = myBezier, 0.05, 0.9, 0.1, 1.05
      animation = windows, 1, 7, myBezier
      animation = windowsOut, 1, 7, default, popin 80%
      animation = fade, 1, 7, default
      animation = workspaces, 1, 6, default
    }

    dwindle {
      pseudotile = true
      preserve_split = true
    }

    # Keybindings
    $mod = SUPER

    bind = $mod, Return, exec, foot
    bind = $mod, Q, killactive
    bind = $mod, M, exit
    bind = $mod, E, exec, firefox
    bind = $mod, V, togglefloating
    bind = $mod, D, exec, fuzzel
    bind = $mod, F, fullscreen

    bind = $mod, left, movefocus, l
    bind = $mod, right, movefocus, r
    bind = $mod, up, movefocus, u
    bind = $mod, down, movefocus, d

    bind = $mod, 1, workspace, 1
    bind = $mod, 2, workspace, 2
    bind = $mod, 3, workspace, 3
    bind = $mod, 4, workspace, 4
    bind = $mod, 5, workspace, 5

    bind = $mod SHIFT, 1, movetoworkspace, 1
    bind = $mod SHIFT, 2, movetoworkspace, 2
    bind = $mod SHIFT, 3, movetoworkspace, 3
    bind = $mod SHIFT, 4, movetoworkspace, 4
    bind = $mod SHIFT, 5, movetoworkspace, 5

    # Media keys
    bind = , XF86MonBrightnessUp, exec, brightnessctl set +5%
    bind = , XF86MonBrightnessDown, exec, brightnessctl set 5%-
    bind = , XF86AudioRaiseVolume, exec, pamixer -i 5
    bind = , XF86AudioLowerVolume, exec, pamixer -d 5
    bind = , XF86AudioMute, exec, pamixer -t

    bindm = $mod, mouse:272, movewindow
    bindm = $mod, mouse:273, resizewindow
  '';

  # Symlink config
  system.activationScripts.hyprlandConfig = ''
    mkdir -p /home/paul/.config/hypr
    ln -sf /etc/hypr/hyprland.conf /home/paul/.config/hypr/hyprland.conf
    chown -R paul:users /home/paul/.config/hypr
    mkdir -p /home/paul/.config/caelestia
    mkdir -p /home/paul/.local/state/caelestia
    chown -R paul:users /home/paul/.config/caelestia
    chown -R paul:users /home/paul/.local/state/caelestia
  '';

  # ----- SYSTEM -----
  nixpkgs.config.allowUnfree = true;
  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  system.stateVersion = "24.11";
}
