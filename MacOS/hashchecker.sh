#!/bin/bash

# File hash verification script
# Usage: checkhash.sh -f <file> -h <hash> [-a algorithm]

usage() {
    echo "Usage: $0 -f <file> -h <expected_hash> [-a algorithm]"
    echo "  -f    Path to the file to verify"
    echo "  -h    Expected hash value"
    echo "  -a    Algorithm: md5, sha1, sha256 (auto-detected if omitted)"
    exit 1
}

# Parse arguments
while getopts "f:h:a:" opt; do
    case $opt in
        f) FILE="$OPTARG" ;;
        h) EXPECTED="$OPTARG" ;;
        a) ALGO="$OPTARG" ;;
        *) usage ;;
    esac
done

# Validate inputs
[ -z "$FILE" ] || [ -z "$EXPECTED" ] && usage
[ ! -f "$FILE" ] && echo "Error: File '$FILE' not found" && exit 1


decision_maker(){
    
    if [ "$answer" = "Yes" ] || [ "$answer" = "yes" ] || [ "$answer" = "Y" ] || [ "$answer" = "y" ]; then
        rm -rf "$FILE"
        echo "File '$FILE' has been deleted."
    elif [ "$answer" = "No" ] || [ "$answer" = "no" ] || [ "$answer" = "N" ] || [ "$answer" = "n" ]; then
        echo "You said $answer, the file will not be deleted. Check before installing"
    else
        echo "This is not a supported value. Only Yes/No/yes/no/Y/N/y/n are supported."
    fi
   
}


# Auto-detect algorithm based on hash length if not specified
if [ -z "$ALGO" ]; then
    case ${#EXPECTED} in
        32) ALGO="md5" ;;
        40) ALGO="sha1" ;;
        64) ALGO="sha256" ;;
	    128) ALGO="sha512" ;;
        *)  echo "Error: Cannot auto-detect algorithm. Use -a to specify."; read -p "Do you want to delete $FILE (Yes/No/yes/no/Y/N/y/n): " answer; decision_maker; exit 1 ;;
    esac
    echo "Auto-detected algorithm: $ALGO"
fi

# Select the appropriate command
case $ALGO in
    md5)    ACTUAL=$(md5sum "$FILE" | awk '{print $1}') ;;
    sha1)   ACTUAL=$(sha1sum "$FILE" | awk '{print $1}') ;;
    sha256) ACTUAL=$(sha256sum "$FILE" | awk '{print $1}') ;;
    sha512) ACTUAL=$(sha512sum "$FILE" | awk '{print $1}') ;;
    *)      echo "Error: Unsupported algorithm '$ALGO'";read -p "Do you want to delete $FILE (Yes/No/yes/no/Y/N/y/n): " answer; decision_maker; exit 1 ;;
esac

# Compare
echo "File:     $FILE"
echo "Expected: $EXPECTED"
echo "Actual:   $ACTUAL"
echo "----------------------------------------"

if [ "$ACTUAL" = "$EXPECTED" ]; then
    echo "✓ Hash verified successfully"
    exit 0
else
    echo "✗ Hash mismatch — file may be corrupted or tampered with"
    read -p "Do you want to delete $FILE (Yes/No/yes/no/Y/N/y/n): " answer; decision_maker
    exit 1
fi
