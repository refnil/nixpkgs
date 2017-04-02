# This file was auto-generated by cabal2nix. Please do NOT edit manually!

{ cabal, cmdargs, configurator, dyre, filepath, hoodleCore, mtl }:

cabal.mkDerivation (self: {
  pname = "hoodle";
  version = "0.3";
  sha256 = "01wz7bwdr3i43ikaiaq8vpn6b0clxjnjyaw6nl6zaq489dhj6fv5";
  isLibrary = true;
  isExecutable = true;
  buildDepends = [
    cmdargs configurator dyre filepath hoodleCore mtl
  ];
  meta = {
    homepage = "http://ianwookim.org/hoodle";
    description = "Executable for hoodle";
    license = self.stdenv.lib.licenses.gpl3;
    platforms = self.ghc.meta.platforms;
    maintainers = [ self.stdenv.lib.maintainers.ianwookim ];
  };
})
