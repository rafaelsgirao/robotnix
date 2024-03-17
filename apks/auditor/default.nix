{ androidSdk
, stdenv
, jdk
, gradle
, fetchFromGitHub
, version ? "78"
}:
let
  src = fetchFromGitHub {
    owner = "GrapheneOS";
    repo = "Auditor";
    rev = version;
    hash = "sha256-uOXBUkoh3GWTgnz+BB//p+76Vswz+yfb7i7udlDkx4o=";
  };

  sdk = androidSdk (p: with p; [ cmdline-tools-latest platform-tools platforms-android-34 build-tools-34-0-0 ]);
  ANDROID_HOME = "${sdk}/share/android-sdk";

  GRADLE_ARGS = "--console plain --no-daemon --write-verification-metadata sha512 -Dorg.gradle.project.android.aapt2FromMavenOverride=${sdk}/share/android-sdk/build-tools/34.0.0/aapt2";

  dependencies = stdenv.mkDerivation {
    name = "gradle-home-dependencies";
    nativeBuildInputs = [ jdk gradle ];
    inherit src ANDROID_HOME;
    dontFixup = true;

    buildPhase = ''
      set -x
      GRADLE_USER_HOME=$(pwd)/.gradle gradle ${GRADLE_ARGS} help lint
    '';
    installPhase = ''
      set -x
      # See here for a mapping of gradle version and the respective cache paths:
      # https://docs.gradle.org/8.4/userguide/dependency_resolution.html#sub:ephemeral-ci-cache

      mkdir -p $out/caches/modules-2
      cp -a .gradle/caches/modules-2/. $out/caches/modules-2/
      find $out -type f -regex '.+\\(\\.lastUpdated\\|resolver-status\\.properties\\|_remote\\.repositories\\|\\.lock\\)' -delete
      find $out -type f \( -name "*.log" -o -name "*.lock" -o -name "gc.properties" \) -delete
    '';
    outputHashAlgo = "sha256";
    outputHashMode = "recursive";
    # outputHash = lib.fakeHash;
    outputHash = "sha256-NYol439do1IDk4Qpq1sNXNZOV1mn+8VDwgr+uu1Cu/4=";
  };
in
stdenv.mkDerivation rec {
  pname = "auditor";
  inherit version;
  name = "${pname}-${version}";

  inherit src dependencies ANDROID_HOME;
  nativeBuildInputs = [ jdk gradle ];
  buildPhase = ''
    mkdir .gradle
    cp -R --no-preserve=all ${dependencies}/. .gradle/
    GRADLE_USER_HOME=$(pwd)/.gradle gradle build --offline ${GRADLE_ARGS}
  '';

  installPhase = ''
    # create the bin directory
    mkdir -p $out
    # Keep only apks to ensure reproducible builds
    cp -R app/build/outputs/apk/. $out/
  '';
}
