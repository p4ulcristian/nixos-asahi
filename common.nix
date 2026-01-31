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

    # AGS Desktop Shell (replaces waybar, mako, etc)
    ags                 # Aylur's GTK Shell
    dart-sass           # For AGS styling

    # Hyprland utilities
    fuzzel              # Backup launcher
    swaybg              # Wallpaper
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

    # Autostart - AGS shell
    exec-once = ags run
    exec-once = swaybg -c "#0f0f0f"
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

    # Media keys
    bind = , XF86MonBrightnessUp, exec, brightnessctl set +5%
    bind = , XF86MonBrightnessDown, exec, brightnessctl set 5%-
    bind = , XF86AudioRaiseVolume, exec, pamixer -i 5
    bind = , XF86AudioLowerVolume, exec, pamixer -d 5
    bind = , XF86AudioMute, exec, pamixer -t

    # Mouse bindings
    bindm = $mod, mouse:272, movewindow
    bindm = $mod, mouse:273, resizewindow
  '';

  # ----- AGS CONFIG -----
  environment.etc."ags/config.js".text = ''
    const hyprland = await Service.import("hyprland");
    const audio = await Service.import("audio");
    const battery = await Service.import("battery");
    const systemtray = await Service.import("systemtray");

    // Workspaces widget
    function Workspaces() {
      const activeId = hyprland.active.workspace.bind("id");
      const workspaces = hyprland.bind("workspaces").as(ws =>
        ws.sort((a, b) => a.id - b.id).map(({ id }) =>
          Widget.Button({
            on_clicked: () => hyprland.messageAsync(`dispatch workspace ''${id}`),
            child: Widget.Label(`''${id}`),
            class_name: activeId.as(i => i === id ? "active" : ""),
          })
        )
      );
      return Widget.Box({
        class_name: "workspaces",
        children: workspaces,
      });
    }

    // Clock widget
    function Clock() {
      const time = Variable("", {
        poll: [1000, 'date "+%H:%M"'],
      });
      return Widget.Label({
        class_name: "clock",
        label: time.bind(),
      });
    }

    // Volume widget
    function Volume() {
      const icons = { muted: "󰝟", low: "󰕿", medium: "󰖀", high: "󰕾" };
      function getIcon() {
        const vol = audio.speaker.volume * 100;
        if (audio.speaker.is_muted) return icons.muted;
        if (vol < 33) return icons.low;
        if (vol < 66) return icons.medium;
        return icons.high;
      }
      return Widget.Button({
        class_name: "volume",
        on_clicked: () => audio.speaker.is_muted = !audio.speaker.is_muted,
        child: Widget.Label().hook(audio.speaker, self => {
          self.label = `''${getIcon()} ''${Math.round(audio.speaker.volume * 100)}%`;
        }),
      });
    }

    // Battery widget
    function BatteryWidget() {
      const icons = ["󰂎", "󰁺", "󰁻", "󰁼", "󰁽", "󰁾", "󰁿", "󰂀", "󰂁", "󰂂", "󰁹"];
      return Widget.Label({
        class_name: "battery",
        visible: battery.bind("available"),
        label: battery.bind("percent").as(p => `''${icons[Math.floor(p / 10)]} ''${p}%`),
      });
    }

    // System tray
    function SysTray() {
      const items = systemtray.bind("items").as(items =>
        items.map(item => Widget.Button({
          child: Widget.Icon({ icon: item.bind("icon") }),
          on_primary_click: (_, event) => item.activate(event),
          on_secondary_click: (_, event) => item.openMenu(event),
          tooltip_markup: item.bind("tooltip_markup"),
        }))
      );
      return Widget.Box({ children: items });
    }

    // Bar
    function Bar(monitor = 0) {
      return Widget.Window({
        monitor,
        name: `bar-''${monitor}`,
        anchor: ["top", "left", "right"],
        exclusivity: "exclusive",
        child: Widget.CenterBox({
          class_name: "bar",
          start_widget: Widget.Box({ children: [Workspaces()] }),
          center_widget: Clock(),
          end_widget: Widget.Box({
            hpack: "end",
            spacing: 8,
            children: [Volume(), BatteryWidget(), SysTray()],
          }),
        }),
      });
    }

    App.config({
      style: "/etc/ags/style.css",
      windows: [Bar()],
    });
  '';

  environment.etc."ags/style.css".text = ''
    * {
      font-family: "JetBrainsMono Nerd Font";
      font-size: 13px;
    }
    .bar {
      background: rgba(15, 15, 15, 0.9);
      color: #ffffff;
      padding: 0 10px;
    }
    .workspaces button {
      padding: 0 8px;
      color: #888888;
      background: transparent;
      border: none;
    }
    .workspaces button.active {
      color: #33ccff;
    }
    .clock {
      color: #ffffff;
    }
    .volume, .battery {
      padding: 0 5px;
    }
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
    mkdir -p /home/paul/.config/ags

    ln -sf /etc/hypr/hyprland.conf /home/paul/.config/hypr/hyprland.conf
    ln -sf /etc/xdg/hypr/hyprlock.conf /home/paul/.config/hypr/hyprlock.conf
    ln -sf /etc/xdg/hypr/hypridle.conf /home/paul/.config/hypr/hypridle.conf
    ln -sf /etc/ags/config.js /home/paul/.config/ags/config.js
    ln -sf /etc/ags/style.css /home/paul/.config/ags/style.css

    chown -R paul:users /home/paul/.config
  '';

  # ----- SYSTEM -----
  nixpkgs.config.allowUnfree = true;
  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  system.stateVersion = "24.11";
}
