# Shared config for both VM and real M2 Mac
# Using Omarchy-style stack: Walker + QuickShell + Swaybg
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
      command = "uwsm start hyprland-uwsm.desktop";
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

    # Desktop Shell
    quickshell          # Qt/QML shell
    uwsm                # Universal Wayland Session Manager
    swaybg              # Wallpaper
    swww                # Animated wallpaper daemon
    walker              # Spotlight-like launcher
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

    # Autostart - QuickShell + wallpaper
    exec-once = swww-daemon
    exec-once = sleep 1 && swww img ~/.config/wallpaper.jpg --transition-type grow --transition-pos center
    exec-once = quickshell -p ~/.config/quickshell
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

    # General
    general {
      gaps_in = 4
      gaps_out = 8
      border_size = 2
      col.active_border = rgba(33ccffee) rgba(00ff99ee) 45deg
      col.inactive_border = rgba(595959aa)
      layout = dwindle
      resize_on_border = true
    }

    # Decoration - rounded corners, blur, transparency
    decoration {
      rounding = 12
      active_opacity = 0.95
      inactive_opacity = 0.90
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
    bind = $mod, D, exec, walker
    bind = $mod, Space, exec, walker
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

  # ----- QUICKSHELL VERTICAL SIDEBAR -----
  environment.etc."quickshell/shell.qml".text = ''
    import QtQuick
    import QtQuick.Layouts
    import Quickshell
    import Quickshell.Wayland
    import Quickshell.Io

    ShellRoot {
        id: root

        property int activeWorkspace: 1
        property string hyprSock: ""

        Component.onCompleted: {
            sockProcess.running = true
        }

        Process {
            id: sockProcess
            command: ["ls", "/run/user/1000/hypr/"]
            stdout: SplitParser {
                onRead: data => {
                    root.hyprSock = data.trim()
                }
            }
        }

        Timer {
            interval: 150
            running: true
            repeat: true
            onTriggered: {
                if (root.hyprSock !== "") {
                    wsProcess.running = true
                }
            }
        }

        Process {
            id: wsProcess
            command: ["bash", "-c", "HYPRLAND_INSTANCE_SIGNATURE=" + root.hyprSock + " hyprctl activeworkspace -j"]
            stdout: SplitParser {
                splitMarker: ""
                onRead: data => {
                    try {
                        var obj = JSON.parse(data)
                        root.activeWorkspace = obj.id
                    } catch(e) {}
                }
            }
        }

        PanelWindow {
            id: bar
            anchors {
                top: true
                left: true
                bottom: true
            }
            implicitWidth: 44
            color: "#14141e"

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 8
                spacing: 6

                Repeater {
                    model: 5
                    Rectangle {
                        id: wsBtn
                        property int wsNum: index + 1
                        property bool isActive: wsNum === root.activeWorkspace

                        width: 28
                        height: 28
                        radius: 14
                        Layout.alignment: Qt.AlignHCenter

                        color: isActive ? "#33ccff" : "#333340"

                        Behavior on color { ColorAnimation { duration: 150 } }
                        Behavior on scale { NumberAnimation { duration: 100; easing.type: Easing.OutQuad } }

                        scale: mouseArea.containsMouse ? 1.2 : 1.0

                        Text {
                            anchors.centerIn: parent
                            text: parent.wsNum
                            color: parent.isActive ? "#000000" : "#888888"
                            font.pixelSize: 12
                            font.bold: parent.isActive
                        }

                        MouseArea {
                            id: mouseArea
                            anchors.fill: parent
                            hoverEnabled: true
                            onClicked: {
                                clickProcess.command = ["bash", "-c", "HYPRLAND_INSTANCE_SIGNATURE=" + root.hyprSock + " hyprctl dispatch workspace " + parent.wsNum]
                                clickProcess.running = true
                            }
                        }

                        Process {
                            id: clickProcess
                        }
                    }
                }

                Item { Layout.fillHeight: true }

                Text {
                    id: clock
                    color: "#ffffff"
                    font.pixelSize: 10
                    font.bold: true
                    Layout.alignment: Qt.AlignHCenter

                    Timer {
                        interval: 1000
                        running: true
                        repeat: true
                        triggeredOnStart: true
                        onTriggered: clock.text = Qt.formatTime(new Date(), "hh:mm")
                    }
                }

                Item { Layout.fillHeight: true }

                Text {
                    text: "VOL"
                    color: "#33ccff"
                    font.pixelSize: 9
                    Layout.alignment: Qt.AlignHCenter
                }
            }
        }
    }
  '';

  # ----- WALKER CONFIG (Spotlight-like launcher) -----
  environment.etc."walker/config.toml".text = ''
    [ui]
    fullscreen = false
    show_initial_entries = true
    orientation = "vertical"
    width = 600
    height = 400

    [ui.anchors]
    top = true

    [search]
    placeholder = "Search..."
    delay = 0

    [list]
    height = 300
    margin_top = 10
    show_icons = true

    [activation_mode]
    labels = "jkl;asdf"

    [[modules]]
    name = "applications"
    prefix = ""

    [[modules]]
    name = "runner"
    prefix = ">"

    [[modules]]
    name = "calc"
    prefix = "="
  '';

  environment.etc."walker/style.css".text = ''
    * {
      font-family: "JetBrainsMono Nerd Font", monospace;
      font-size: 14px;
    }

    #window {
      background: rgba(20, 20, 30, 0.95);
      border-radius: 16px;
      border: 2px solid rgba(51, 204, 255, 0.5);
    }

    #search {
      background: rgba(40, 40, 50, 0.9);
      border-radius: 12px;
      padding: 12px 16px;
      margin: 16px;
      color: #ffffff;
      border: 1px solid rgba(255, 255, 255, 0.1);
    }

    #search:focus {
      border: 1px solid rgba(51, 204, 255, 0.5);
    }

    #list {
      background: transparent;
      margin: 0 16px 16px 16px;
    }

    #item {
      padding: 10px 16px;
      border-radius: 8px;
      margin: 2px 0;
    }

    #item:selected {
      background: rgba(51, 204, 255, 0.2);
    }

    #item:hover {
      background: rgba(255, 255, 255, 0.05);
    }

    #text {
      color: #ffffff;
    }

    #icon {
      margin-right: 12px;
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
    mkdir -p /home/paul/.config/quickshell
    mkdir -p /home/paul/.config/walker

    ln -sf /etc/hypr/hyprland.conf /home/paul/.config/hypr/hyprland.conf
    ln -sf /etc/xdg/hypr/hyprlock.conf /home/paul/.config/hypr/hyprlock.conf
    ln -sf /etc/xdg/hypr/hypridle.conf /home/paul/.config/hypr/hypridle.conf
    cp /etc/quickshell/shell.qml /home/paul/.config/quickshell/shell.qml
    ln -sf /etc/walker/config.toml /home/paul/.config/walker/config.toml
    ln -sf /etc/walker/style.css /home/paul/.config/walker/style.css

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
