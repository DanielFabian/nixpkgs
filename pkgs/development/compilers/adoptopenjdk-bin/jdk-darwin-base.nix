sourcePerArch:

{ swingSupport ? true # not used for now
, stdenv
, fetchurl
}:

let cpuName = stdenv.hostPlatform.parsed.cpu.name;
    result = stdenv.mkDerivation rec {
  name = if sourcePerArch.packageType == "jdk"
    then "adoptopenjdk-${sourcePerArch.vmType}-bin-${sourcePerArch.${cpuName}.version}"
    else "adoptopenjdk-${sourcePerArch.packageType}-${sourcePerArch.vmType}-bin-${sourcePerArch.${cpuName}.version}";

  src = fetchurl {
    inherit (sourcePerArch.${cpuName}) url sha256;
  };

  # See: https://github.com/NixOS/patchelf/issues/10
  dontStrip = 1;

  installPhase = ''
    cd ..

    mv $sourceRoot $out

    rm -rf $out/Home/demo

    # Remove some broken manpages.
    rm -rf $out/Home/man/ja*

    # for backward compatibility
    ln -s $out/Contents/Home $out/jre

    ln -s $out/Contents/Home/* $out/

    mkdir -p $out/nix-support

    # Set JAVA_HOME automatically.
    cat <<EOF >> $out/nix-support/setup-hook
    if [ -z "\$JAVA_HOME" ]; then export JAVA_HOME=$out; fi
    EOF
  '';

  # FIXME: use multiple outputs or return actual JRE package
  passthru.jre = result;

  passthru.home = result;

  # for backward compatibility
  passthru.architecture = "";

  meta = with stdenv.lib; {
    license = licenses.gpl2Classpath;
    description = "AdoptOpenJDK, prebuilt OpenJDK binary";
    platforms = [ "x86_64-darwin" ]; # some inherit jre.meta.platforms
    maintainers = with stdenv.lib.maintainers; [ taku0 ];
  };

}; in result
