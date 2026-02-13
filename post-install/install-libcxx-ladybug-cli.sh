#!/bin/bash
set -euo pipefail

/post-install/install-libcxx.sh
/post-install/install-ladybug.sh
/post-install/install-lbug-cli.sh

echo "==> Ladybug CLI container installation complete!"
