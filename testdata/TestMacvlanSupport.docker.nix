{ pkgs, lib, ... }:

{
  # Runtime
  virtualisation.docker = {
    enable = true;
    autoPrune.enable = true;
  };
  virtualisation.oci-containers.backend = "docker";

  # Containers
  virtualisation.oci-containers.containers."container" = {
    image = "ghcr.io/container/container:latest";
    volumes = [
      "/opt/container/certs:/container/certs:rw"
    ];
    ports = [
      "80:80/tcp"
      "443:443/tcp"
    ];
    log-driver = "journald";
    autoStart = false;
    extraOptions = [
      "--dns=192.168.8.1"
      "--hostname=tc"
      "--ip=192.168.8.10"
      "--mac-address=10:50:02:01:00:02"
      "--network-alias=teddycloud"
      "--network=myproject_homenet"
    ];
  };
  systemd.services."docker-container" = {
    serviceConfig = {
      Restart = lib.mkOverride 500 "always";
      RestartMaxDelaySec = lib.mkOverride 500 "1m";
      RestartSec = lib.mkOverride 500 "100ms";
      RestartSteps = lib.mkOverride 500 9;
    };
    after = [
      "docker-network-myproject_homenet.service"
    ];
    requires = [
      "docker-network-myproject_homenet.service"
    ];
    partOf = [
      "docker-compose-myproject-root.target"
    ];
    wantedBy = [
      "docker-compose-myproject-root.target"
    ];
  };

  # Networks
  systemd.services."docker-network-myproject_homenet" = {
    path = [ pkgs.docker ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStop = "${pkgs.docker}/bin/docker network rm -f myproject_homenet";
    };
    script = ''
      docker network inspect myproject_homenet || docker network create myproject_homenet --driver=macvlan --opt=parent=enp2s0 --subnet=192.168.8.0/24 --gateway=192.168.8.1 --aux-address="host1=192.168.8.5"
    '';
    partOf = [ "docker-compose-myproject-root.target" ];
    wantedBy = [ "docker-compose-myproject-root.target" ];
  };

  # Root service
  # When started, this will automatically create all resources and start
  # the containers. When stopped, this will teardown all resources.
  systemd.targets."docker-compose-myproject-root" = {
    unitConfig = {
      Description = "Root target generated by compose2nix.";
    };
  };
}
