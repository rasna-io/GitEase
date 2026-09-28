#!/bin/bash
QT_PATH=$(find /opt/Qt -name "lib" -type d | grep "gcc_64" | sort -V | tail -n 1)
# or QT_PATH="/opt/Qt/6.10.1/gcc_64/lib" or QT_PATH="~/Qt/6.10.0/gcc_64/lib" or ...
export LD_LIBRARY_PATH="$QT_PATH:$LD_LIBRARY_PATH"
exec GitEase "$@"

# At the end shoud execute this command: chmod +x gitease-launcher.sh