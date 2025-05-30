{
  lib,
  rustPlatform,
  fetchFromGitLab,
  pkg-config,
  sqlite,
  stdenv,
  nixosTests,
  rocksdb,
  rust-jemalloc-sys,
}:

rustPlatform.buildRustPackage rec {
  pname = "matrix-conduit";
  version = "0.9.0";

  src = fetchFromGitLab {
    owner = "famedly";
    repo = "conduit";
    rev = "v${version}";
    hash = "sha256-mQLfRAun2G/LDnw3jyFGJbOqpxh2PL8IGzFELRfAgAI=";
  };

  useFetchCargoVendor = true;
  cargoHash = "sha256-r7fOzTug0cKQUGrpXDn1JKb6/lLQDgnA3/colmldA4c=";

  # Conduit enables rusqlite's bundled feature by default, but we'd rather use our copy of SQLite.
  preBuild = ''
    substituteInPlace Cargo.toml --replace "features = [\"bundled\"]" "features = []"
    cargo update --offline -p rusqlite
  '';

  nativeBuildInputs = [
    rustPlatform.bindgenHook
    pkg-config
  ];

  buildInputs = [
    sqlite
    rust-jemalloc-sys
  ];

  env = {
    ROCKSDB_INCLUDE_DIR = "${rocksdb}/include";
    ROCKSDB_LIB_DIR = "${rocksdb}/lib";
  };

  # tests failed on x86_64-darwin with SIGILL: illegal instruction
  doCheck = !(stdenv.hostPlatform.isx86_64 && stdenv.hostPlatform.isDarwin);

  passthru.tests = {
    inherit (nixosTests) matrix-conduit;
  };

  meta = with lib; {
    description = "Matrix homeserver written in Rust";
    homepage = "https://conduit.rs/";
    license = licenses.asl20;
    maintainers = with maintainers; [
      pstn
      pimeys
    ];
    mainProgram = "conduit";
  };
}
