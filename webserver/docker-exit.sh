#!/bin/bash
##

#set -euo pipefail
echo "Exiting: 0";

if [ -z "$CIRCLECI" ]; then
echo "Exiting: 1";

    # keep alive if not circleci
    tail -f /dev/null
echo "Exiting: 2";

fi

echo "Exiting: 3";
