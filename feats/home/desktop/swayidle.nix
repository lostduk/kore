{ config, lib, pkgs, ... }:

let
  lock = "${lib.getExe config.programs.swaylock.package} -f";
  wlopm = lib.getExe pkgs.wlopm;
in {
  services.swayidle = {
    enable = true;

    timeouts = [
      { timeout = 600; command = lock; }
      {
        timeout = 900;
        command = "${wlopm} --off '*'";
        resumeCommand = "${wlopm} --on '*'";
      }
    ];

    events = {
      before-sleep = lock;
      inherit lock;
    };
  };
}
