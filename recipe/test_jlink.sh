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
"${JLINK_TEST_IMAGE}/bin/java" -version
rm -rf "${JLINK_TEST_IMAGE}"

echo "=== jlink linkable-runtime regression test (#218) PASSED ==="
