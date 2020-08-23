self: super:

with super;
with lib;

{
  super-slicer = stdenv.mkDerivation rec {
    pname = "super-slicer";
    version = "2.2.53.0";

    enableParallelBuilding = true;

    nativeBuildInputs = [
      cmake
      pkgconfig
    ];

    buildInputs = [
      boost
      cereal
      cgal_5
      curl
      eigen
      expat
      glew
      gmp
      ilmbase
      libpng
      mpfr
      nlopt
      openvdb
      systemd
      tbb
      wxGTK31
      xorg.libX11
    ] ++ checkInputs;

    checkInputs = [ gtest ];

    # The build system uses custom logic - defined in
    # cmake/modules/FindNLopt.cmake in the package source - for finding the nlopt
    # library, which doesn't pick up the package in the nix store.  We
    # additionally need to set the path via the NLOPT environment variable.
    NLOPT = nlopt;

    # Disable compiler warnings that clutter the build log.
    # It seems to be a known issue for Eigen:
    # http://eigen.tuxfamily.org/bz/show_bug.cgi?id=1221
    NIX_CFLAGS_COMPILE = "-Wno-ignored-attributes";

    # super-slicer uses dlopen on `libudev.so` at runtime
    NIX_LDFLAGS = "-ludev";

    prePatch = ''
      # In nix ioctls.h isn't available from the standard kernel-headers package
      # like in other distributions. The copy in glibc seems to be identical to the
      # one in the kernel though, so we use that one instead.
      sed -i 's|"/usr/include/asm-generic/ioctls.h"|<asm-generic/ioctls.h>|g' src/libslic3r/GCodeSender.cpp

      # Since version 2.5.0 of nlopt we need to link to libnlopt, as libnlopt_cxx
      # now seems to be integrated into the main lib.
      sed -i 's|nlopt_cxx|nlopt|g' cmake/modules/FindNLopt.cmake
    '';

    src = fetchFromGitHub {
      owner = "supermerill";
      repo = "SuperSlicer";
      sha256 = "03wjzl2h6mrbymfnw0krnzjzfiza20bbswxkmf76x2wdwawp585m";
      rev = "${version}";
    };

    cmakeFlags = [
      "-DSLIC3R_FHS=1"
      "-DSLIC3R_BUILD_TESTS=OFF"
    ];

    postInstall = ''
      mkdir -p "$out/share/pixmaps/"
      ln -s "$out/share/slic3r++/icons/Slic3r.png" "$out/share/pixmaps/Slic3r.png"
      mkdir -p "$out/share/applications"
      cp "$desktopItem"/share/applications/* "$out/share/applications/"
    '';

    desktopItem = makeDesktopItem {
      name = "SuperSlicer";
      exec = "superslicer";
      icon = "Slic3r";
      comment = "G-code generator for 3D printers";
      desktopName = "SuperSlicer";
      genericName = "3D printer tool";
      categories = "Development;";
    };

    meta = with stdenv.lib; {
      description = "G-code generator for 3D printer";
      homepage = "https://github.com/supermerill/SuperSlicer";
      license = licenses.agpl3;
    };
  };
}
