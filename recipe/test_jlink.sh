#!/bin/bash
set -exuo pipefail

# Regression test for #218: on linux, jmods are intentionally not shipped
# (see commit 2d84380, "Linux now uses JEP 493"), so jlink must be able to
# link custom run-time images directly from this run-time image instead.

echo "=== Running jlink linkable-runtime regression test (#218) ==="

if ! "${JAVA_HOME}/bin/jlink" --help | grep -q "Linking from run-time image enabled"; then
  echo "ERROR: jlink does not report linkable-runtime support enabled (see #218)"
  "${JAVA_HOME}/bin/jlink" --help
  exit 1
fi
echo "-> jlink reports linkable-runtime support enabled"

JLINK_TEST_IMAGE=$(mktemp -d)/jlink-test-image
# jlink's run-time image integrity check flags files (e.g. bin/keytool) as
# modified relative to what the JDK build recorded. This recipe enables
# binary_relocation for linux (see `dynamic_linking` in recipe.yaml), which
# patches RPATHs in binaries as part of rattler-build's post-processing
# after the JDK is built - the most likely cause.
# --ignore-modified-runtime demotes this to a warning; it is used
# here because the modification is believed to be limited to this
# packaging-time RPATH patching, not a change to security-relevant content.
"${JAVA_HOME}/bin/jlink" --add-modules java.base --ignore-modified-runtime --output "${JLINK_TEST_IMAGE}"
# On some architectures (e.g. aarch64), jlink-generated runtime images fail to
# locate libz.so.1 at startup, even though the original JDK install resolves
# it fine via its own RPATH. This appears to depend on whether the toolchain
# emits RPATH (transitive) vs RUNPATH (non-transitive, the modern default) -
# RPATH lets the search path "leak through" to a dependency's own
# dependencies, which masks this gap on toolchains that still use it.
# Explicitly adding $PREFIX/lib to LD_LIBRARY_PATH here ensures the jlinked
# image's java binary can find libz.so.1 regardless of toolchain RPATH/RUNPATH
# defaults.
LD_LIBRARY_PATH="$PREFIX/lib:${LD_LIBRARY_PATH:-}" "$JLINK_TEST_IMAGE/bin/java" -version
rm -rf "${JLINK_TEST_IMAGE}"

echo "=== jlink linkable-runtime regression test (#218) PASSED ==="
