# Shared config for both VM and real M2 Mac
# Using Omarchy-style stack: Waybar + Mako + Fuzzel + Swaybg
{ config, pkgs, lib, ... }:

{
  # ----- NETWORKING -----
  networking.hostName = "perfect";
  networking.networkmanager.enable = true;

  # ----- DESKTOP: Hyprland + Omarchy Stack -----
  programs.hyprland.enable = true;

  # Auto-login with greetd
  services.greetd = {
    enable = true;
    settings.default_session = {
      command = "Hyprland";
      user = "paul";
    };
  };

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
  };
  security.sudo.wheelNeedsPassword = false;

  # ----- PACKAGES -----
  environment.systemPackages = with pkgs; [
    # Core tools
    git wget curl htop

    # Omarchy Desktop Stack
    waybar              # Bar
    mako                # Notifications
    fuzzel              # Launcher
    swaybg              # Wallpaper
    swayosd             # Volume/brightness OSD
    hyprlock            # Lock screen
    hypridle            # Idle management

    # Hyprland utilities
    foot                # Terminal
    wl-clipboard grim slurp
    brightnessctl pamixer playerctl

    # Dev - Clojure
    clojure leiningen babashka clojure-lsp

    # Dev - JavaScript
    bun nodejs

    # Apps
    chromium vscode
    vesktop _1password-gui _1password-cli

    # Theming
    papirus-icon-theme
  ];

  # ----- FONTS -----
  fonts.fontconfig.enable = true;
  fonts.packages = with pkgs; [
    noto-fonts noto-fonts-cjk-sans noto-fonts-color-emoji
    nerd-fonts.jetbrains-mono nerd-fonts.fira-code
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

  # ----- HYPRLAND CONFIG (Omarchy Style) -----
  environment.etc."hypr/hyprland.conf".text = ''
    # Monitor
    monitor=,1920x1080@60,auto,1

    # Autostart - Omarchy stack
    exec-once = waybar
    exec-once = mako
    exec-once = swaybg -i ~/.config/wallpaper.jpg -m fill || swaybg -c "#0f0f0f"
    exec-once = swayosd-server
    exec-once = hypridle

    # Environment
    env = XCURSOR_SIZE,24
    env = QT_QPA_PLATFORMTHEME,qt5ct

    # Input
    input {
      kb_layout = us
      follow_mouse = 1
      sensitivity = 0.3
      touchpad {
        natural_scroll = true
        tap-to-click = true
      }
    }

    # General - Omarchy style (sharp corners)
    general {
      gaps_in = 5
      gaps_out = 10
      border_size = 2
      col.active_border = rgba(33ccffee) rgba(00ff99ee) 45deg
      col.inactive_border = rgba(595959aa)
      layout = dwindle
      resize_on_border = true
    }

    # Decoration - blur enabled, no rounding
    decoration {
      rounding = 0
      blur {
        enabled = true
        size = 2
        passes = 2
        brightness = 0.60
        contrast = 0.75
      }
      shadow {
        enabled = true
        range = 2
        render_power = 3
        color = rgba(1a1a1aee)
      }
    }

    # Animations - Omarchy smooth
    animations {
      enabled = true
      bezier = easeOutQuint,0.23,1,0.32,1
      bezier = quick,0.15,0,0.1,1
      animation = windows, 1, 4.79, easeOutQuint
      animation = windowsIn, 1, 4.1, easeOutQuint, popin 87%
      animation = windowsOut, 1, 1.49, quick, popin 87%
      animation = fade, 1, 1.46, quick
      animation = workspaces, 1, 3.5, easeOutQuint
    }

    dwindle {
      pseudotile = true
      preserve_split = true
    }

    misc {
      disable_hyprland_logo = true
      disable_splash_rendering = true
      focus_on_activate = true
    }

    cursor {
      hide_on_key_press = true
    }

    # Keybindings (ALT works better in VM since host catches SUPER)
    $mod = ALT

    bind = $mod, Return, exec, foot
    bind = $mod, Q, killactive
    bind = $mod, M, exit
    bind = $mod, E, exec, chromium
    bind = $mod, V, togglefloating
    bind = $mod, D, exec, fuzzel
    bind = $mod, F, fullscreen
    bind = $mod, L, exec, hyprlock

    # Focus
    bind = $mod, left, movefocus, l
    bind = $mod, right, movefocus, r
    bind = $mod, up, movefocus, u
    bind = $mod, down, movefocus, d
    bind = $mod, H, movefocus, l
    bind = $mod, L, movefocus, r
    bind = $mod, K, movefocus, u
    bind = $mod, J, movefocus, d

    # Workspaces
    bind = $mod, 1, workspace, 1
    bind = $mod, 2, workspace, 2
    bind = $mod, 3, workspace, 3
    bind = $mod, 4, workspace, 4
    bind = $mod, 5, workspace, 5
    bind = $mod, 6, workspace, 6

    bind = $mod SHIFT, 1, movetoworkspace, 1
    bind = $mod SHIFT, 2, movetoworkspace, 2
    bind = $mod SHIFT, 3, movetoworkspace, 3
    bind = $mod SHIFT, 4, movetoworkspace, 4
    bind = $mod SHIFT, 5, movetoworkspace, 5
    bind = $mod SHIFT, 6, movetoworkspace, 6

    # Media keys with OSD
    bind = , XF86MonBrightnessUp, exec, swayosd-client --brightness raise
    bind = , XF86MonBrightnessDown, exec, swayosd-client --brightness lower
    bind = , XF86AudioRaiseVolume, exec, swayosd-client --output-volume raise
    bind = , XF86AudioLowerVolume, exec, swayosd-client --output-volume lower
    bind = , XF86AudioMute, exec, swayosd-client --output-volume mute-toggle

    # Mouse bindings
    bindm = $mod, mouse:272, movewindow
    bindm = $mod, mouse:273, resizewindow
  '';

  # ----- WAYBAR CONFIG -----
  environment.etc."xdg/waybar/config".text = builtins.toJSON {
    layer = "top";
    position = "top";
    height = 30;
    modules-left = [ "hyprland/workspaces" ];
    modules-center = [ "clock" ];
    modules-right = [ "pulseaudio" "battery" "network" "tray" ];

    clock = {
      format = "{:%H:%M}";
      format-alt = "{:%Y-%m-%d %H:%M}";
    };
    battery = {
      format = "{icon} {capacity}%";
      format-icons = [ "" "" "" "" "" ];
    };
    network = {
      format-wifi = " {signalStrength}%";
      format-ethernet = "";
      format-disconnected = "";
    };
    pulseaudio = {
      format = "{icon} {volume}%";
      format-muted = "";
      format-icons.default = [ "" "" "" ];
    };
  };

  environment.etc."xdg/waybar/style.css".text = ''
    * {
      font-family: "JetBrainsMono Nerd Font";
      font-size: 13px;
    }
    window#waybar {
      background: rgba(15, 15, 15, 0.9);
      color: #ffffff;
    }
    #workspaces button {
      padding: 0 8px;
      color: #888888;
    }
    #workspaces button.active {
      color: #33ccff;
    }
    #clock, #battery, #network, #pulseaudio {
      padding: 0 10px;
    }
  '';

  # ----- MAKO CONFIG -----
  environment.etc."xdg/mako/config".text = ''
    font=JetBrainsMono Nerd Font 11
    background-color=#1a1a1aee
    text-color=#ffffff
    border-color=#33ccff
    border-radius=0
    default-timeout=5000
    padding=10
    margin=10
  '';

  # ----- FUZZEL CONFIG -----
  environment.etc."xdg/fuzzel/fuzzel.ini".text = ''
    [main]
    font=JetBrainsMono Nerd Font:size=12
    terminal=foot
    layer=overlay

    [colors]
    background=0f0f0fdd
    text=ffffffff
    selection=33ccffff
    selection-text=000000ff
    border=33ccffff
  '';

  # ----- HYPRLOCK CONFIG -----
  environment.etc."xdg/hypr/hyprlock.conf".text = ''
    background {
      path = screenshot
      blur_passes = 3
      blur_size = 5
    }
    input-field {
      size = 250, 50
      outline_thickness = 2
      outer_color = rgb(33ccff)
      inner_color = rgb(0f0f0f)
      font_color = rgb(ffffff)
    }
  '';

  # ----- HYPRIDLE CONFIG -----
  environment.etc."xdg/hypr/hypridle.conf".text = ''
    listener {
      timeout = 300
      on-timeout = hyprlock
    }
    listener {
      timeout = 600
      on-timeout = hyprctl dispatch dpms off
      on-resume = hyprctl dispatch dpms on
    }
  '';

  # Setup user config dirs
  system.activationScripts.hyprlandConfig = ''
    mkdir -p /home/paul/.config/hypr
    mkdir -p /home/paul/.config/waybar
    mkdir -p /home/paul/.config/mako
    mkdir -p /home/paul/.config/fuzzel

    ln -sf /etc/hypr/hyprland.conf /home/paul/.config/hypr/hyprland.conf
    ln -sf /etc/xdg/waybar/config /home/paul/.config/waybar/config
    ln -sf /etc/xdg/waybar/style.css /home/paul/.config/waybar/style.css
    ln -sf /etc/xdg/mako/config /home/paul/.config/mako/config
    ln -sf /etc/xdg/fuzzel/fuzzel.ini /home/paul/.config/fuzzel/fuzzel.ini
    ln -sf /etc/xdg/hypr/hyprlock.conf /home/paul/.config/hypr/hyprlock.conf
    ln -sf /etc/xdg/hypr/hypridle.conf /home/paul/.config/hypr/hypridle.conf

    chown -R paul:users /home/paul/.config
  '';

  # ----- SYSTEM -----
  nixpkgs.config.allowUnfree = true;
  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  system.stateVersion = "24.11";
}
