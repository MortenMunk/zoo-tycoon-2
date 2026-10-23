{...}: {
  flake.homeModules.zooTycoon2 = {pkgs, ...}: let
    gameZip = pkgs.fetchurl {
      # update link and sha if expired
      url = "https://d1.xp.myabandonware.com/t/be39003d-108e-46e9-910f-d7e97e63da07/Zoo-Tycoon-2-Ultimate-Collection_Win_EN_Repack.zip";
      sha256 = "113vcdxsd128fj3yc4kj22xc6s1fhscqacyb7cg7nq5xvscxqnaw";
    };

    zt2GameFiles = pkgs.stdenvNoCC.mkDerivation {
      name = "zoo-tycoon-2-files";
      dontUnpack = true;
      nativeBuildInputs = with pkgs; [
        p7zip
        innoextract
      ];
      buildPhase = ''
        7z x "${gameZip}" -y
        mkdir -p "$out"
        innoextract -e "Zoo Tycoon 2_Repack_Setup.exe" -d "$out"
      '';
    };

    zt2Script = pkgs.writeShellScriptBin "zoo-tycoon-2" ''
      export PATH="${pkgs.lib.makeBinPath [pkgs.wineWow64Packages.staging pkgs.winetricks pkgs.cabextract pkgs.coreutils]}:$PATH"
      export WINEPREFIX="$HOME/.local/share/zoo-tycoon-2"
      GAME_DIR="$WINEPREFIX/drive_c/ZT2"
      if [ ! -f "$WINEPREFIX/.initialized" ]; then
        rm -rf "$WINEPREFIX"
        mkdir -p "$GAME_DIR"
        cp -r "${zt2GameFiles}/." "$GAME_DIR/"
        if [ -d "$GAME_DIR/app" ]; then
          cp -r "$GAME_DIR/app/." "$GAME_DIR/"
          rm -rf "$GAME_DIR/app"
        fi

        chmod -R u+w "$GAME_DIR"
        # Remove broken d3d9.dll wrapper bundled by repack
        rm -f "$GAME_DIR/d3d9.dll" "$GAME_DIR/dxgi.dll"
        wine wineboot -u
        # Install d3dx9, d3dcompiler and dxvk
        winetricks -q d3dx9 d3dcompiler_43 dxvk
        touch "$WINEPREFIX/.initialized"
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
