{
  lib,
  stdenv,
  mcpelauncher-client-git,
  fetchFromGitHub,
  cmake,
  pkg-config,
  zlib,
  libzip,
  curl,
  protobuf,
  qt6,
  glfw,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "mcpelauncher-ui-qt";
  inherit (mcpelauncher-client-git) version;

  src = fetchFromGitHub {
    owner = "minecraft-linux";
    repo = "mcpelauncher-ui-manifest";
    tag = "v${finalAttrs.version}";
    fetchSubmodules = true;
    hash = "sha256-Oibi7+LJK7K1a1fFN2SKy4XiA0gSC4u7Wmk0t86SHaw=";
  };

  patches = [
    ./dont_download_glfw_ui.patch
    ./fix-cmake4-build.patch
  ];

  nativeBuildInputs = [
    cmake
    pkg-config
    qt6.wrapQtAppsHook
  ];

  buildInputs = [
    zlib
    libzip
    curl
    protobuf
    qt6.qtwebengine
    qt6.qtsvg
    qt6.qtwayland
    glfw
  ];

  # the program refuses to start when QT_STYLE_OVERRIDE is set
  # https://github.com/minecraft-linux/mcpelauncher-ui-qt/issues/25
  preFixup = ''
    qtWrapperArgs+=(
      --prefix PATH : ${lib.makeBinPath [ mcpelauncher-client-git ]}
      --unset QT_STYLE_OVERRIDE
    )
  '';

  passthru.updateScript = ./update.sh;

  meta = mcpelauncher-client-git.meta // {
    description = "Unofficial Minecraft Bedrock Edition launcher with GUI";
    mainProgram = "mcpelauncher-ui-qt";
  };
})
