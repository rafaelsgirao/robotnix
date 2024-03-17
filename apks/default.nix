# SPDX-FileCopyrightText: 2020 Daniel Fullmer and robotnix contributors
# SPDX-License-Identifier: MIT

{ pkgs }:

let
  inherit (pkgs) callPackage;
in

rec {
  auditor = callPackage ./auditor { };

  # fdroid = callPackage ./fdroid { inherit gradleToNixPatchedFetchers; };

  # seedvault_10 = callPackage ./seedvault_10 {}; # Old version that works with Android 10

  # # Chromium-based browsers
  # chromium = callPackage ./chromium/default.nix {};
  # vanadium = import ./chromium/vanadium.nix {
  #   inherit chromium;
  #   inherit (pkgs) fetchFromGitHub git fetchcipd linkFarmFromDrvs fetchurl;
  # };
  # bromite = import ./chromium/bromite.nix {
  #   inherit chromium;
  #   inherit (pkgs) fetchFromGitHub git python3;
  # };
}
