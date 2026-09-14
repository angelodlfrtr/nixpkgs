{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.programs.outlinevpn-client;
in
{
  options.programs.outlinevpn-client = {
    enable = lib.mkEnableOption "Outline VPN client, with the capabilities it needs to set up the VPN";

    package = lib.mkPackageOption pkgs "outlinevpn-client" { };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = config.networking.networkmanager.enable;
        message = "programs.outlinevpn-client requires networking.networkmanager.enable, as the client configures the VPN through NetworkManager.";
      }
    ];

    environment.systemPackages = [ cfg.package ];

    # The client routes traffic through the TUN device with a policy rule
    # that exempts its own fwmarked proxy socket. A strict reverse-path test
    # evaluates the (unmarked) replies from the server against that rule,
    # concludes they should have arrived on the TUN device, and drops them.
    networking.firewall.checkReversePath = lib.mkDefault "loose";

    # The Linux client sets up the TUN device, routes and DNS from within the
    # Electron process, so it needs these capabilities. This mirrors what the
    # upstream Debian package does with setcap at install time.
    security.wrappers.outlinevpn-client = {
      owner = "root";
      group = "root";
      capabilities = "cap_net_admin,cap_dac_override+ep";
      source = lib.getExe cfg.package;
    };
  };

  meta.maintainers = with lib.maintainers; [ angelodlfrtr ];
}
