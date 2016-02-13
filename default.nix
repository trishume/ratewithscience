let
  pkgs = (import <nixpkgs> {});
in
pkgs.stdenv.mkDerivation rec {
  name = "ratewithscience";
  src = ./.;

  #builder = pkgs.writeScript "${name}-builder.sh" ''
  #  mkdir -p $out
  #'';
  shellHook = ''
    find ${vibed}/source -name '*.d' -exec ${dmd}/bin/dmd -ofratewithscience -version=VibeNoSSL -version=VibeLibeventDriver -version=VibeDefaultMain -L-L${sqlite}/lib -L-L${pkgs.libevent}/lib -L-lsqlite3 -L-levent -L-levent_pthreads -I${dmdpath} source/*.d ${d2sqlite3}/source/*.d ${gfm}/core/gfm/core/queue.d {} +
  '';

  libPath = with pkgs; stdenv.lib.makeLibraryPath [ sqlite libevent dmd ];

  dmd = pkgs.dmd;
  sqlite = pkgs.sqlite;

  vibed = pkgs.fetchFromGitHub {
    owner = "rejectedsoftware";
    repo = "vibe.d";
    rev = "v0.7.27";
    sha256 = "0bp695yxjxwhz9z7cvm3xjv0r95xz5kdqvd7gbi8p8p8r1xa1syd";
  };
  d2sqlite3 = pkgs.fetchFromGitHub {
    owner = "biozic";
    repo = "d2sqlite3";
    rev = "v0.9.7";
    sha256 = "0rn6l7d0hj75yd50qwijn3irzkyk88vpqzmi5l4h6gimgi2a0vs6";
  };
  gfm = pkgs.fetchFromGitHub {
    owner = "d-gamedev-team";
    repo = "gfm";
    rev = "v3.0.11";
    sha256 = "1z5zvyabpdl6hs7lhrd8d3faczw9rjj38hh07vsd00pvsgygl3v6";
  };
  libevent = pkgs.fetchFromGitHub {
    owner = "D-Programming-Deimos";
    repo = "libevent";
    rev = "6b7d0c9d26b88eaf94fc9cd04a11eba8fc77a0d1";
    sha256 = "1qvnh15ci8p8syvwwvv29dlqflq4c7sa5syc9sglssb3bm06zm70";
  };
  openssl = pkgs.fetchFromGitHub {
    owner = "D-Programming-Deimos";
    repo = "openssl";
    rev = "3365d3f9dd95778a8ca6281856e3392d1b08a9a0";
    sha256 = "01djnmh280rg2j4myjz08yf3qr25gclqvlh0x1xvqwl0c3wxk5px";
  };
  dmdpath = "source:${vibed}/source:${gfm}/core:${d2sqlite3}/source:${libevent}:${openssl}";
}
