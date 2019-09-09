# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

let secrets = import /home/william/.william/etc/secrets.nix; in

{ config, pkgs, ... }:

{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix

      <nixos-hardware/lenovo/thinkpad/x1/6th-gen>
    ];

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.systemd-boot.editor = false;
  boot.loader.efi.canTouchEfiVariables = true;

  boot.kernelPackages = pkgs.linuxPackages_latest;

  networking.hostName = "helium"; # Define your hostname.
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.
  networking.networkmanager.enable = true;

  hardware.bluetooth.enable = true;

  # Select internationalisation properties.
  i18n = {
    consoleFont = "Lat2-Terminus16";
    consoleKeyMap = "us";
    defaultLocale = "en_CA.UTF-8";
  };

  fonts.fonts = with pkgs; [
    aegan
    aegyptus
    agave
    aileron
    akkadian
    amiri
    andagii
    andika
    ankacoder
    ankacoder-condensed
    anonymousPro
    arkpandora_ttf
    arphic-ukai
    arphic-uming
    assyrian
    aurulent-sans
    b612
    babelstone-han
    baekmuk-ttf
    bakoma_ttf
    behdad-fonts
    cabin
    caladea
    # camingo-code
    cantarell-fonts
    carlito
    charis-sil
    cherry
    clearlyU
    cm_unicode
    cnstrokeorder
    comfortaa
    comic-neue
    comic-relief
    cooper-hewitt
    # corefonts
    creep
    crimson
    culmus
    d2coding
    dejavu_fonts
    denemo
    dina-font
    dina-font-pcf
    dosemu_fonts
    dosis
    doulos-sil
    eb-garamond
    eemusic
    emacs-all-the-icons-fonts
    emojione
    encode-sans
    envypn-font
    etBook
    eunomia
    f5_6
    fantasque-sans-mono
    ferrum
    fira
    fira-code
    fira-code-symbols
    fira-mono
    fixedsys-excelsior
    font-awesome-ttf
    font-awesome_4
    fontconfig-penultimate
    freefont_ttf
    gandom-fonts
    gentium
    gentium-book-basic
    go-font
    gohufont
    google-fonts
    gyre-fonts
    hack-font
    hanazono
    hasklig
    # helvetica-neue-lt-std
    hermit
    hyperscrypt-font
    ia-writer-duospace
    ibm-plex
    inconsolata
    inconsolata-lgc
    # input-fonts
    inriafonts
    inter
    inter-ui
    iosevka
    iosevka-bin
    ipaexfont
    ipafont
    # ir-standard-fonts
    iwona
    jost
    junicode
    kanji-stroke-order-font
    kawkab-mono-font
    kochi-substitute
    # kochi-substitute-naga10
    lalezar-fonts
    latinmodern-math
    lato
    league-of-moveable-type
    liberastika
    liberation_ttf_v1_from_source
    liberation_ttf_v2_from_source
    liberationsansnarrow
    libertine
    libertinus
    libre-baskerville
    libre-bodoni
    libre-caslon
    libre-franklin
    libreoffice-fresh-unwrapped
    libreoffice-still-unwrapped
    lmmath
    lmodern
    # lobster-two
    lohit-fonts.assamese
    lohit-fonts.bengali
    lohit-fonts.devanagari
    lohit-fonts.gujarati
    lohit-fonts.gurmukhi
    lohit-fonts.kannada
    lohit-fonts.kashmiri
    lohit-fonts.konkani
    lohit-fonts.maithili
    lohit-fonts.malayalam
    lohit-fonts.marathi
    lohit-fonts.nepali
    lohit-fonts.odia
    lohit-fonts.sindhi
    lohit-fonts.tamil
    lohit-fonts.tamil-classical
    lohit-fonts.telugu
    luculent
    manrope
    marathi-cursive
    material-design-icons
    material-icons
    maya
    medio
    meslo-lg
    migmix
    migu
    mno16
    monoid
    mononoki
    montserrat
    mph_2b_damase
    mplus-outline-fonts
    mro-unicode
    myrica
    nafees
    nahid-fonts
    nanum-gothic-coding
    national-park-typeface
    nerdfonts
    nika-fonts
    norwester-font
    noto-fonts
    noto-fonts-cjk-sans
    noto-fonts-emoji
    noto-fonts-extra
    office-code-pro
    oldsindhi
    oldstandard
    open-dyslexic
    openimageio
    openimageio2
    opensans-ttf
    orbitron
    overpass
    oxygenfonts
    pantheon.elementary-redacted-script
    parastoo-fonts
    paratype-pt-mono
    paratype-pt-sans
    paratype-pt-serif
    pecita
    penna
    poly
    powerline-fonts
    profont
    proggyfonts
    public-sans
    python27Packages.powerline
    python37Packages.powerline
    quattrocento
    quattrocento-sans
    quilter
    raleway
    redhat-official-fonts
    # ricty
    rictydiminished-with-firacode
    roboto
    roboto-mono
    roboto-slab
    rounded-mgenplus
    route159
    rt
    sahel-fonts
    samim-fonts
    sampradaya
    sarasa-gothic
    scheherazade
    seshat
    shabnam-fonts
    shrikhand
    signwriting
    siji
    source-code-pro
    source-han-code-jp
    source-han-sans-japanese
    source-han-sans-korean
    source-han-sans-simplified-chinese
    source-han-sans-traditional-chinese
    source-han-serif-japanese
    source-han-serif-korean
    source-han-serif-simplified-chinese
    source-han-serif-traditional-chinese
    source-sans-pro
    source-serif-pro
    spleen
    stix-otf
    stix-two
    sudo-font
    symbola
    tai-ahom
    tamsyn
    tempora_lgc
    tenderness
    terminus_font
    terminus_font_ttf
    tewi-font
    tex-gyre-bonum-math
    tex-gyre-pagella-math
    tex-gyre-schola-math
    tex-gyre-termes-math
    tex-gyre.adventor
    tex-gyre.bonum
    tex-gyre.chorus
    tex-gyre.cursor
    tex-gyre.heros
    tex-gyre.pagella
    tex-gyre.schola
    tex-gyre.termes
    theano
    tipa
    tlwg
    # ttf-envy-code-r
    ttf_bitstream_vera
    twemoji-color-font
    ubuntu_font_family
    ucsFonts
    ultimate-oldschool-pc-font-pack
    undefined-medium
    uni-vga
    unidings
    unifont
    unifont_upper
    unscii
    vazir-fonts
    vdrsymbols
    vegur
    victor-mono
    # vistafonts
    # vistafonts-chs
    weather-icons
    winePackages.fonts
    wqy_microhei
    wqy_zenhei
    xits-math
    # xkcd-font
    xlibs.encodings
    xlibs.fontalias
    xlibs.fontutil
    yanone-kaffeesatz
    zilla-slab
  ];

  # Set your time zone.
  time.timeZone = "America/Toronto";

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    neovim
  ];

  environment.shellAliases = {
    vi = "nvim";
  };

  environment.shellInit = ''
    export EDITOR=nvim
    export VISUAL=nvim

    gpg-connect-agent /bye
    export SSH_AUTH_SOCK=$(gpgconf --list-dirs agent-ssh-socket)
  '';

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.bash.enableCompletion = true;
  # programs.mtr.enable = true;
  # programs.gnupg.agent = { enable = true; enableSSHSupport = true; };

  programs.zsh = {
    enable = true;
    enableCompletion = true;
    autosuggestions.enable = true;
    syntaxHighlighting.enable = true;
    ohMyZsh = {
      enable = true;
      theme = "robbyrussell";
    };
  };

  programs.sway = {
    enable = true;

    extraPackages = with pkgs; [
      bemenu
      grim
      j4-dmenu-desktop
      mako
      (redshift.overrideAttrs (oldAttrs: {
        src = fetchFromGitHub {
          owner = "minus7";
          repo = "redshift";
          rev = "7da875d34854a6a34612d5ce4bd8718c32bec804";
          sha256 = "0nbkcw3avmzjg1jr1g9yfpm80kzisy55idl09b6wvzv2sz27n957";
          fetchSubmodules = true;
        };
      }))
      slurp
      swaybg
      swayidle
      swaylock
      (waybar.override {
        pulseSupport = true;
      })
      wf-recorder
      wl-clipboard
      xwayland
    ];

    extraSessionCommands = ''
      export GDK_BACKEND=wayland
    '';
  };

  programs.gnupg.agent = {
    enable = true;
    enableSSHSupport = true;
  };

  programs.ssh.startAgent = false;

  programs.light.enable = true;

  # List services that you want to enable:

  services.logind.extraConfig = ''
    RuntimeDirectorySize=25%
  '';

  services.avahi = {
    enable = true;
    nssmdns4 = true;
    publish = {
      enable = true;
      userServices = true;
      addresses = true;
      domain = true;
    };
  };

  # Enable the OpenSSH daemon.
  services.openssh = {
    enable = true;
    passwordAuthentication = false;
  };

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;

  # Enable CUPS to print documents.
  # services.printing.enable = true;

  # Enable sound.
  sound.enable = true;
  hardware.pulseaudio.enable = true;

  # Enable the X11 windowing system.
  # services.xserver.enable = true;
  # services.xserver.layout = "us";
  # services.xserver.xkbOptions = "eurosign:e";

  # Enable touchpad support.
  # services.xserver.libinput.enable = true;

  # Enable the KDE Desktop Environment.
  # services.xserver.displayManager.sddm.enable = true;
  # services.xserver.desktopManager.plasma5.enable = true;

  services.gvfs.enable = true;

  services.pcscd.enable = true;

  services.openvpn.servers = {
    canada = {
      autoStart = false;
      updateResolvConf = true;
      config = ''
        # ==============================================================================
        # Copyright (c) 2016-2017 ProtonVPN A.G. (Switzerland)
        # Email: contact@protonvpn.com
        #
        # The MIT License (MIT)
        #
        # Permission is hereby granted, free of charge, to any person obtaining a copy
        # of this software and associated documentation files (the "Software"), to deal
        # in the Software without restriction, including without limitation the rights
        # to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
        # copies of the Software, and to permit persons to whom the Software is
        # furnished to do so, subject to the following conditions:
        #
        # The above copyright notice and this permission notice shall be included in all
        # copies or substantial portions of the Software.
        #
        # THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
        # IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
        # FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
        # AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
        # LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR # OTHERWISE, ARISING
        # FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS
        # IN THE SOFTWARE.
        # ==============================================================================

        client
        dev tun
        proto udp

        remote ca.protonvpn.com 80
        remote ca.protonvpn.com 443
        remote ca.protonvpn.com 4569
        remote ca.protonvpn.com 1194
        remote ca.protonvpn.com 5060

        remote-random
        resolv-retry infinite
        nobind
        cipher AES-256-CBC
        auth SHA512
        comp-lzo no
        verb 3

        tun-mtu 1500
        tun-mtu-extra 32
        mssfix 1450
        persist-key
        persist-tun

        reneg-sec 0

        remote-cert-tls server
        auth-user-pass
        pull
        fast-io

        script-security 2
        # up /etc/openvpn/update-resolv-conf
        # down /etc/openvpn/update-resolv-conf

        <ca>
        -----BEGIN CERTIFICATE-----
        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
        A1gTTlpi7A==
        -----END CERTIFICATE-----
        </ca>

        key-direction 1
        <tls-auth>
        # 2048 bit OpenVPN static key
        -----BEGIN OpenVPN Static key V1-----
        6acef03f62675b4b1bbd03e53b187727
        423cea742242106cb2916a8a4c829756
        3d22c7e5cef430b1103c6f66eb1fc5b3
        75a672f158e2e2e936c3faa48b035a6d
        e17beaac23b5f03b10b868d53d03521d
        8ba115059da777a60cbfd7b2c9c57472
        78a15b8f6e68a3ef7fd583ec9f398c8b
        d4735dab40cbd1e3c62a822e97489186
        c30a0b48c7c38ea32ceb056d3fa5a710
        e10ccc7a0ddb363b08c3d2777a3395e1
        0c0b6080f56309192ab5aacd4b45f55d
        a61fc77af39bd81a19218a79762c3386
        2df55785075f37d8c71dc8a42097ee43
        344739a0dd48d03025b0450cf1fb5e8c
        aeb893d9a96d1f15519bb3c4dcb40ee3
        16672ea16c012664f8a9f11255518deb
        -----END OpenVPN Static key V1-----
        </tls-auth>
      '';
      authUserPass = {
        inherit (secrets.vpn) username password;
      };
    };
  };

  services.flatpak.enable = true;
  xdg.portal.enable = true;

  virtualisation = {
    docker.enable = true;
    lxd.enable = true;
  };

  users.mutableUsers = false;

  users.defaultUserShell = pkgs.zsh;

  users.users.root.hashedPassword = secrets.users.root.hashedPassword;

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.william = {
    uid = 1000;
    description = "William Hua";
    isNormalUser = true;
    hashedPassword = secrets.users.william.hashedPassword;
    extraGroups = [
      "docker"
      "lxd"
      "sway"
      "video"
      "wheel"
    ];
  };

  # users.extraUsers.guest = {
  #   isNormalUser = true;
  #   uid = 1000;
  # };

  # This value determines the NixOS release with which your system is to be
  # compatible, in order to avoid breaking some software such as database
  # servers. You should change this only after NixOS release notes say you
  # should.
  system.stateVersion = "18.03"; # Did you read the comment?

}
