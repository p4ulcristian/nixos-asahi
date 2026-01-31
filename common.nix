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
    # Core tools
    git wget curl htop

    # Hyprland essentials
    foot wl-clipboard grim slurp swww
    brightnessctl pamixer playerctl

    # Dev - Clojure
    clojure leiningen babashka clojure-lsp

    # Dev - JavaScript
    bun nodejs

    # Apps
    firefox google-chrome vscode
    vesktop _1password-gui _1password-cli

    # Theming
    papirus-icon-theme
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
    exec-once = swww init && sleep 1 && swww img --fill-color 0f0f0f /dev/null 2>/dev/null || true

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

  # Symlink config and setup Caelestia
  system.activationScripts.hyprlandConfig = ''
    mkdir -p /home/paul/.config/hypr
    ln -sf /etc/hypr/hyprland.conf /home/paul/.config/hypr/hyprland.conf
    chown -R paul:users /home/paul/.config/hypr

    # Caelestia config - glossy dark theme
    mkdir -p /home/paul/.config/caelestia
    mkdir -p /home/paul/.local/state/caelestia/wallpaper

    # Shell config with transparency enabled
    cat > /home/paul/.config/caelestia/shell.json << 'SHELLJSON'
    {
      "appearance": {
        "transparency": {
          "enabled": true,
          "base": 0.85,
          "layers": 0.4
        }
      },
      "sidebar": {
        "enabled": true
      }
    }
    SHELLJSON

    # Dark color scheme
    cat > /home/paul/.local/state/caelestia/scheme.json << 'SCHEMEJSON'
    {"name":"glossy-dark","flavour":"dark","mode":"dark","colours":{"primary_paletteKeyColor":"6366F1","secondary_paletteKeyColor":"8B5CF6","tertiary_paletteKeyColor":"06B6D4","neutral_paletteKeyColor":"1E1E2E","neutralVariant_paletteKeyColor":"313244","background":"0F0F0F","onBackground":"E4E4E7","surface":"18181B","surfaceDim":"09090B","surfaceBright":"27272A","surfaceContainerLowest":"09090B","surfaceContainerLow":"18181B","surfaceContainer":"1F1F23","surfaceContainerHigh":"27272A","surfaceContainerHighest":"3F3F46","onSurface":"FAFAFA","surfaceVariant":"27272A","onSurfaceVariant":"A1A1AA","inverseSurface":"FAFAFA","inverseOnSurface":"18181B","outline":"52525B","outlineVariant":"3F3F46","shadow":"000000","scrim":"000000","surfaceTint":"6366F1","primary":"818CF8","onPrimary":"0F0F0F","primaryContainer":"312E81","onPrimaryContainer":"C7D2FE","inversePrimary":"4338CA","secondary":"A78BFA","onSecondary":"0F0F0F","secondaryContainer":"4C1D95","onSecondaryContainer":"DDD6FE","tertiary":"22D3EE","onTertiary":"0F0F0F","tertiaryContainer":"164E63","onTertiaryContainer":"A5F3FC","error":"F87171","onError":"0F0F0F","errorContainer":"7F1D1D","onErrorContainer":"FECACA"}}
    SCHEMEJSON

    # Empty notifs
    echo '[]' > /home/paul/.local/state/caelestia/notifs.json

    chown -R paul:users /home/paul/.config/caelestia
    chown -R paul:users /home/paul/.local/state/caelestia
  '';

  # ----- SYSTEM -----
  nixpkgs.config.allowUnfree = true;
  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  system.stateVersion = "24.11";
}
