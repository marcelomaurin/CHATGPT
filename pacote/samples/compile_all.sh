#!/bin/bash
LAZBUILD="/usr/bin/lazbuild"
if [ ! -f "$LAZBUILD" ]; then
    LAZBUILD="lazbuild"
fi

echo "Scanning and compiling Lazarus projects..."
FAILED_COUNT=0
SUCCESS_COUNT=0
FAILED_LIST=""

# Find all .lpi files under the current directory, ignoring backup and lib directories
find . -name "*.lpi" | while read -r lpi; do
    # Skip backup and lib directories
    if [[ "$lpi" =~ "backup" ]] || [[ "$lpi" =~ "lib" ]]; then
        continue
    fi
    echo "=================================================="
    echo "Compiling: $lpi"
    echo "=================================================="
    "$LAZBUILD" "$lpi"
    if [ $? -eq 0 ]; then
        echo "SUCCESS: $lpi"
        SUCCESS_COUNT=$((SUCCESS_COUNT + 1))
    else
        echo "FAILED: $lpi"
        FAILED_COUNT=$((FAILED_COUNT + 1))
        FAILED_LIST="$FAILED_LIST $(basename "$lpi")"
    fi
done

echo "=================================================="
echo "Compilation Summary:"
echo "Success: $SUCCESS_COUNT"
echo "Failed: $FAILED_COUNT"
if [ $FAILED_COUNT -gt 0 ]; then
    echo "Failed projects: $FAILED_LIST"
    echo "Some projects failed to compile."
    exit 1
else
    echo "All projects compiled successfully!"
    exit 0
fi
