{...}: {
  flake.homeModules.zooTycoon2 = {pkgs, ...}: let
    gameZip = pkgs.fetchurl {
      # update link and sha if expired
      url = "https://d1.xp.myabandonware.com/t/be39003d-108e-46e9-910f-d7e97e63da07/Zoo-Tycoon-2-Ultimate-Collection_Win_EN_Repack.zip";
      sha256 = "113vcdxsd128fj3yc4kj22xc6s1fhscqacyb7cg7nq5xvscxqnaw";
    };

    zt2Installer = pkgs.stdenvNoCC.mkDerivation {
      name = "zoo-tycoon-2-installer";
      dontUnpack = true;
      nativeBuildInputs = [pkgs.p7zip];

      buildPhase = ''
        mkdir -p "$out"
        7z x "${gameZip}" -o"$out" -y
      '';
    };
    zt2Script = pkgs.writeShellScriptBin "zoo-tycoon-2" ''
      export PATH="${pkgs.lib.makeBinPath [pkgs.wineWow64Packages.staging pkgs.winetricks pkgs.cabextract pkgs.coreutils]}:$PATH"
      export WINEPREFIX="$HOME/.local/share/zoo-tycoon-2"
      GAME_DIR="$WINEPREFIX/drive_c/ZT2"

      if [ ! -f "$WINEPREFIX/.initialized" ]; then
        wine wineboot -u
        winetricks -q d3dx9 d3dcompiler_43 dxvk
        touch "$WINEPREFIX/.initialized"
      fi

      # avoid wiping existing saves, if any
      if [ ! -f "$WINEPREFIX/.installed_repack" ]; then
        wine "${zt2Installer}/Zoo Tycoon 2_Repack_Setup.exe" /VERYSILENT /SUPPRESSMSGBOXES /NORESTART /DIR="C:\ZT2"

        mkdir -p "$WINEPREFIX/drive_c/ProgramData/Microsoft Games/Zoo Tycoon 2/downloads"
        if [ -d "$GAME_DIR/DLC" ]; then
          cp -r "$GAME_DIR/DLC/." "$WINEPREFIX/drive_c/ProgramData/Microsoft Games/Zoo Tycoon 2/downloads/"
        fi

        rm -f "$GAME_DIR/d3d9.dll" "$GAME_DIR/dxgi.dll"
        rm -rf "$GAME_DIR/app"
        touch "$WINEPREFIX/.installed_repack"
      fi

      cd "$GAME_DIR"
      exec wine ZT.exe
    '';

    zt2Desktop = pkgs.makeDesktopItem {
      name = "zoo-tycoon-2";
      desktopName = "Zoo Tycoon 2";
      exec = "${zt2Script}/bin/zoo-tycoon-2";
      icon = "applications-games";
      categories = ["Game"];
    };
  in {
    home.packages = [
      zt2Script
      zt2Desktop
    ];
  };
}
