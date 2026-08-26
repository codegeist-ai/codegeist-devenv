#!/bin/sh
# code-wrapper.sh - launch VS Code inside default Docker isolation.
#
# Chromium's namespace sandbox cannot initialize in this test container. Keep
# the workaround scoped to the cgenv invocation instead of changing the product
# launcher or granting the container additional host capabilities.

exec /usr/bin/code --no-sandbox "$@"
