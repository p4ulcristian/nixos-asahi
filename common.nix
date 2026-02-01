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

    # AGS Desktop Shell
    ags                 # Aylur's GTK Shell v2
    swaybg              # Wallpaper
    swww                # Animated wallpaper daemon
    fuzzel              # Launcher
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

    # Autostart - AGS shell + wallpaper
    exec-once = swww-daemon
    exec-once = sleep 1 && swww img ~/.config/wallpaper.jpg --transition-type grow --transition-pos center
    exec-once = ags run ~/.config/ags/bar.tsx
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

  # ----- AGS BAR CONFIG -----
  environment.etc."ags/bar.tsx".text = ''
    #!/usr/bin/env -S ags run
    import { App, Astal, Gdk, Gtk } from "astal/gtk3"
    import { Variable, bind } from "astal"
    import { exec, execAsync } from "astal/process"

    // Get Hyprland socket dynamically
    const SOCK = exec("ls /run/user/1000/hypr/").trim()
    const hyprctl = (cmd: string) => exec(`bash -c "HYPRLAND_INSTANCE_SIGNATURE=''${SOCK} hyprctl ''${cmd}"`)

    const time = Variable("").poll(1000, () => exec("date \"+%a %b %d  %H:%M\""))
    const user = exec("whoami").trim()

    const volume = Variable("N/A").poll(2000, () => {
      try { return exec("pamixer --get-volume") + "%" } catch { return "N/A" }
    })

    const activeWs = Variable(1).poll(200, () => {
      try {
        return JSON.parse(hyprctl("activeworkspace -j")).id
      } catch { return 1 }
    })

    function Bar(gdkmonitor: Gdk.Monitor) {
      return <window
        gdkmonitor={gdkmonitor}
        exclusivity={Astal.Exclusivity.EXCLUSIVE}
        anchor={Astal.WindowAnchor.TOP | Astal.WindowAnchor.LEFT | Astal.WindowAnchor.RIGHT}
        application={App}>
        <centerbox className="bar">
          <box halign={Gtk.Align.START}>
            <label className="logo" label={" " + user} />
            <box className="workspaces">
              {[1, 2, 3, 4, 5].map(i => (
                <button
                  className={bind(activeWs).as(a => a === i ? "ws active" : "ws")}
                  onClicked={() => execAsync(`bash -c "HYPRLAND_INSTANCE_SIGNATURE=''${SOCK} hyprctl dispatch workspace ''${i}"`)}>
                  <label label={String(i)} />
                </button>
              ))}
            </box>
          </box>
          <label className="clock" label={bind(time)} />
          <box halign={Gtk.Align.END} className="right">
            <label className="volume" label={bind(volume).as(v => " " + v)} />
          </box>
        </centerbox>
      </window>
    }

    App.start({
      css: `
        .bar {
          background: linear-gradient(180deg, rgba(20, 20, 30, 0.92) 0%, rgba(10, 10, 18, 0.88) 100%);
          color: #e0e0e0;
          font-family: JetBrainsMono Nerd Font;
          font-size: 13px;
          padding: 6px 14px;
          border-bottom: 1px solid rgba(80, 200, 255, 0.3);
        }
        .logo { color: #33ccff; font-size: 16px; font-weight: bold; margin-right: 16px; }
        .clock { color: #ffffff; font-weight: bold; font-size: 14px; }
        .workspaces { margin-left: 4px; }
        .ws {
          background: rgba(255,255,255,0.1);
          color: #666;
          border: none;
          border-radius: 50%;
          min-width: 28px;
          min-height: 28px;
          padding: 0;
          margin: 0 4px;
        }
        .ws label { margin: 0; padding: 0; }
        .ws:hover { background: rgba(255,255,255,0.2); color: #aaa; }
        .ws.active {
          background: linear-gradient(135deg, #33ccff 0%, #00ff99 100%);
          color: #000;
          font-weight: bold;
        }
        .volume { color: #33ccff; margin-left: 16px; }
      `,
      main() {
        App.get_monitors().forEach(Bar)
      },
    })
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
    cp /etc/ags/bar.tsx /home/paul/.config/ags/bar.tsx
    chmod +x /home/paul/.config/ags/bar.tsx

    # Download a nice dark wallpaper if not present
    if [ ! -f /home/paul/.config/wallpaper.jpg ]; then
      ${pkgs.curl}/bin/curl -sL "https://images.unsplash.com/photo-1534796636912-3b95b3ab5986?w=1920&q=80" -o /home/paul/.config/wallpaper.jpg || true
    fi

    chown -R paul:users /home/paul/.config
  '';

  # ----- SYSTEM -----
  nixpkgs.config.allowUnfree = true;
  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  system.stateVersion = "24.11";
}
