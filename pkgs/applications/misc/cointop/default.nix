{ lib, buildGoPackage, fetchFromGitHub }:

buildGoPackage rec {
  pname = "cointop";
  version = "1.6.2";

  src = fetchFromGitHub {
    owner = "miguelmota";
    repo = pname;
    rev = "v${version}";
    sha256 = "sha256-4Ae8lzaec7JeYfmeLleatUS/xQUjea7O4XJ9DOgJIMs=";
  };

  goPackagePath = "github.com/miguelmota/cointop";

  buildFlagsArray = [ "-ldflags=-s -w -X ${goPackagePath}/cointop.version=${version}" ];

  meta = with lib; {
    description = "The fastest and most interactive terminal based UI application for tracking cryptocurrencies";
    longDescription = ''
      cointop is a fast and lightweight interactive terminal based UI
      application for tracking and monitoring cryptocurrency coin stats in
      real-time.

      The interface is inspired by htop and shortcut keys are inspired by vim.
    '';
    homepage = "https://cointop.sh";
    maintainers = [ maintainers.marsam ];
    license = licenses.asl20;
  };
}
