{ lib, pkgs, ... }:

let
  wbg = pkgs.wbg.override { enableWebp = false; };

  wallpaper = pkgs.runCommand "jardin-blanc.jpg" {
    nativeBuildInputs = [ pkgs.imagemagick ];
    src = pkgs.fetchurl {
      name = "le-jardin-blanc-au-crepuscule.jpg";
      url = "https://upload.wikimedia.org/wikipedia/commons/e/e2/Le_jardin_blanc_au_cr%C3%A9puscule.jpg";
      hash = "sha256-JEJ0htoF0D/Pu1UxUzSPseTTrBXKSpMlc2DYnpthERA=";
      curlOptsList = [ "--user-agent" "kore-nixos-config/1.0" ];
    };
  } ''
    magick "$src" \
      -distort Perspective '179,184 0,0  2830,184 2651,0  189,1891 0,1707  2832,1891 2651,1707' \
      -crop 2651x1707+0+0 +repage \
      -modulate 92,85 \
      -resize 1920x -gravity south -crop 1920x1080+0+38 +repage \
      -strip -quality 90 "jpg:$out"
  '';
in {
  systemd.user.services.wbg = {
    Unit = {
      Description = "wbg wallpaper";
      PartOf = [ "graphical-session.target" ];
      After = [ "graphical-session.target" ];
    };

    Service.ExecStart = "${lib.getExe wbg} ${wallpaper}";

    Install.WantedBy = [ "dwl-session.target" ];
  };
}
