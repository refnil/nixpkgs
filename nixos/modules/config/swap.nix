{ config, lib, pkgs, utils, ... }:

with utils;
with lib;

let

  randomEncryptionCoerce = enable: { inherit enable; };

  randomEncryptionOpts = { ... }: {

    options = {

      enable = mkOption {
        default = false;
        type = types.bool;
        description = ''
          Encrypt swap device with a random key. This way you won't have a persistent swap device.

          WARNING: Don't try to hibernate when you have at least one swap partition with
          this option enabled! We have no way to set the partition into which hibernation image
          is saved, so if your image ends up on an encrypted one you would lose it!

          WARNING #2: Do not use /dev/disk/by-uuid/… or /dev/disk/by-label/… as your swap device
          when using randomEncryption as the UUIDs and labels will get erased on every boot when
          the partition is encrypted. Best to use /dev/disk/by-partuuid/…
        '';
      };

      cipher = mkOption {
        default = "aes-xts-plain64";
        example = "serpent-xts-plain64";
        type = types.str;
        description = ''
          Use specified cipher for randomEncryption.

          Hint: Run "cryptsetup benchmark" to see which one is fastest on your machine.
        '';
      };

      source = mkOption {
        default = "/dev/urandom";
        example = "/dev/random";
        type = types.str;
        description = ''
          Define the source of randomness to obtain a random key for encryption.
        '';
      };

    };

  };

  swapCfg = {config, options, ...}: {

    options = {

      device = mkOption {
        example = "/dev/sda3";
        type = types.str;
        description = "Path of the device or swap file.";
      };

      label = mkOption {
        example = "swap";
        type = types.str;
        description = ''
          Label of the device.  Can be used instead of <varname>device</varname>.
        '';
      };

      size = mkOption {
        default = null;
        example = 2048;
        type = types.nullOr types.int;
        description = ''
          If this option is set, ‘device’ is interpreted as the
          path of a swapfile that will be created automatically
          with the indicated size (in megabytes).
        '';
      };

      priority = mkOption {
        default = null;
        example = 2048;
        type = types.nullOr types.int;
        description = ''
          Specify the priority of the swap device. Priority is a value between 0 and 32767.
          Higher numbers indicate higher priority.
          null lets the kernel choose a priority, which will show up as a negative value.
        '';
      };

      randomEncryption = mkOption {
        default = false;
        example = {
          enable = true;
          cipher = "serpent-xts-plain64";
          source = "/dev/random";
        };
        type = types.coercedTo types.bool randomEncryptionCoerce (types.submodule randomEncryptionOpts);
        description = ''
          Encrypt swap device with a random key. This way you won't have a persistent swap device.

          HINT: run "cryptsetup benchmark" to test cipher performance on your machine.

          WARNING: Don't try to hibernate when you have at least one swap partition with
          this option enabled! We have no way to set the partition into which hibernation image
          is saved, so if your image ends up on an encrypted one you would lose it!

          WARNING #2: Do not use /dev/disk/by-uuid/… or /dev/disk/by-label/… as your swap device
          when using randomEncryption as the UUIDs and labels will get erased on every boot when
          the partition is encrypted. Best to use /dev/disk/by-partuuid/…
        '';
      };

      deviceName = mkOption {
        type = types.str;
        internal = true;
      };

      realDevice = mkOption {
        type = types.path;
        internal = true;
      };

    };

    config = rec {
      device = mkIf options.label.isDefined
        "/dev/disk/by-label/${config.label}";
      deviceName = lib.replaceChars ["\\"] [""] (escapeSystemdPath config.device);
      realDevice = if config.randomEncryption.enable then "/dev/mapper/${deviceName}" else config.device;
    };

  };

in

{

  ###### interface

  options = {

    swapDevices = mkOption {
      default = [];
      example = [
        { device = "/dev/hda7"; }
        { device = "/var/swapfile"; }
        { label = "bigswap"; }
      ];
      description = ''
        The swap devices and swap files.  These must have been
        initialised using <command>mkswap</command>.  Each element
        should be an attribute set specifying either the path of the
        swap device or file (<literal>device</literal>) or the label
        of the swap device (<literal>label</literal>, see
        <command>mkswap -L</command>).  Using a label is
        recommended.
      '';

      type = types.listOf (types.submodule swapCfg);
    };

  };

  config = mkIf ((length config.swapDevices) != 0) {

    system.requiredKernelConfig = with config.lib.kernelConfig; [
      (isYes "SWAP")
    ];

    # Create missing swapfiles.
    # FIXME: support changing the size of existing swapfiles.
    systemd.services =
      let

        createSwapDevice = sw:
          assert sw.device != "";
          assert !(sw.randomEncryption.enable && lib.hasPrefix "/dev/disk/by-uuid"  sw.device);
          assert !(sw.randomEncryption.enable && lib.hasPrefix "/dev/disk/by-label" sw.device);
          let realDevice' = escapeSystemdPath sw.realDevice;
          in nameValuePair "mkswap-${sw.deviceName}"
          { description = "Initialisation of swap device ${sw.device}";
            wantedBy = [ "${realDevice'}.swap" ];
            before = [ "${realDevice'}.swap" ];
            # If swap is encrypted, depending on rngd resolves a possible entropy starvation during boot
            after = mkIf (config.security.rngd.enable && sw.randomEncryption.enable) [ "rngd.service" ];
            path = [ pkgs.util-linux ] ++ optional sw.randomEncryption.enable pkgs.cryptsetup;

            script =
              ''
                ${optionalString (sw.size != null) ''
                  currentSize=$(( $(stat -c "%s" "${sw.device}" 2>/dev/null || echo 0) / 1024 / 1024 ))
                  if [ "${toString sw.size}" != "$currentSize" ]; then
                    fallocate -l ${toString sw.size}M "${sw.device}" ||
                      dd if=/dev/zero of="${sw.device}" bs=1M count=${toString sw.size}
                    if [ "${toString sw.size}" -lt "$currentSize" ]; then
                      truncate --size "${toString sw.size}M" "${sw.device}"
                    fi
                    chmod 0600 ${sw.device}
                    ${optionalString (!sw.randomEncryption.enable) "mkswap ${sw.realDevice}"}
                  fi
                ''}
                ${optionalString sw.randomEncryption.enable ''
                  cryptsetup plainOpen -c ${sw.randomEncryption.cipher} -d ${sw.randomEncryption.source} ${sw.device} ${sw.deviceName}
                  mkswap ${sw.realDevice}
                ''}
              '';

            unitConfig.RequiresMountsFor = [ "${dirOf sw.device}" ];
            unitConfig.DefaultDependencies = false; # needed to prevent a cycle
            serviceConfig.Type = "oneshot";
            serviceConfig.RemainAfterExit = sw.randomEncryption.enable;
            serviceConfig.ExecStop = optionalString sw.randomEncryption.enable "${pkgs.cryptsetup}/bin/cryptsetup luksClose ${sw.deviceName}";
            restartIfChanged = false;
          };

      in listToAttrs (map createSwapDevice (filter (sw: sw.size != null || sw.randomEncryption.enable) config.swapDevices));

  };

}
