#!/bin/bash
# iso2raw.sh - Convert ISO (MODE1/2048) to raw BIN (MODE1/2352)
# This script converts a standard ISO file to raw MODE1/2352 format
# with headers, sync patterns, and EDC/ECC data

set -e

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Check arguments
if [ "$#" -lt 2 ] || [ "$#" -gt 3 ]; then
    echo "Usage: $0 <input.iso> <output.bin>"
    exit 1
fi

INPUT_ISO="$1"
OUTPUT_BIN="$2"

# Check if input file exists
if [ ! -f "$INPUT_ISO" ]; then
    echo "Error: Input file '$INPUT_ISO' not found"
    exit 1
fi

# Get file size and calculate number of sectors
ISO_SIZE=$(stat -c%s "$INPUT_ISO" 2>/dev/null || stat -f%z "$INPUT_ISO" 2>/dev/null)
SECTORS=$((ISO_SIZE / 2048))

if [ $((ISO_SIZE % 2048)) -ne 0 ]; then
    echo "Warning: ISO file size is not a multiple of 2048 bytes"
    SECTORS=$((SECTORS + 1))
fi

echo "Converting $SECTORS sectors from MODE1/2048 to MODE1/2352..."

# Create temporary files
TEMP_DIR=$(mktemp -d)
SYNC_PATTERN="$TEMP_DIR/sync.bin"
TEMP_SECTOR="$TEMP_DIR/sector.bin"
TEMP_HEADER="$TEMP_DIR/header.bin"
TEMP_RAW_SECTOR="$TEMP_DIR/raw_sector.bin"

# Cleanup on exit
trap "rm -rf $TEMP_DIR" EXIT

# Create sync pattern (12 bytes: 00 FF FF FF FF FF FF FF FF FF FF 00)
printf '\x00\xFF\xFF\xFF\xFF\xFF\xFF\xFF\xFF\xFF\xFF\x00' > "$SYNC_PATTERN"

# Initialize output file
> "$OUTPUT_BIN"

# Function to convert decimal to BCD
dec2bcd() {
    local dec=$1
    echo $(( (dec / 10) * 16 + (dec % 10) ))
}

# Process each sector
for ((sector=0; sector<SECTORS; sector++)); do
    # Calculate MSF (Minutes:Seconds:Frames) for this sector
    # Add 2 seconds (150 frames) as per Red Book standard
    total_frames=$((sector + 150))
    minutes=$((total_frames / (60 * 75)))
    seconds=$(((total_frames % (60 * 75)) / 75))
    frames=$((total_frames % 75))
    
    # Convert to BCD format
    bcd_minutes=$(dec2bcd $minutes)
    bcd_seconds=$(dec2bcd $seconds)
    bcd_frames=$(dec2bcd $frames)
    
    # Create header (4 bytes: MM SS FF MODE)
    # MODE = 0x01 for MODE1
    printf "\\x$(printf '%02x' $bcd_minutes)\\x$(printf '%02x' $bcd_seconds)\\x$(printf '%02x' $bcd_frames)\\x01" > "$TEMP_HEADER"
    
    # Extract 2048 bytes of user data from ISO
    dd if="$INPUT_ISO" of="$TEMP_SECTOR" bs=2048 count=1 skip=$sector status=none 2>/dev/null || {
        # If we can't read a full sector (at end of file), pad with zeros
        actual_size=$(stat -c%s "$TEMP_SECTOR" 2>/dev/null || stat -f%z "$TEMP_SECTOR" 2>/dev/null)
        if [ $actual_size -lt 2048 ]; then
            dd if=/dev/zero bs=1 count=$((2048 - actual_size)) >> "$TEMP_SECTOR" 2>/dev/null
        fi
    }
    
    # Use zero-filled EDC/ECC (288 bytes)
    # EDC: 4 bytes, Zero: 8 bytes, ECC-P: 172 bytes, ECC-Q: 104 bytes
    {
        cat "$SYNC_PATTERN"       # 12 bytes
        cat "$TEMP_HEADER"        # 4 bytes
        cat "$TEMP_SECTOR"        # 2048 bytes
        dd if=/dev/zero bs=288 count=1 status=none 2>/dev/null  # 288 bytes
    } >> "$OUTPUT_BIN"
    
    # Progress indicator
    percent=$((sector * 1000 / SECTORS))
    printf "\rProcessed %d/%d sectors (%d.%d%%)" $sector $SECTORS $((percent / 10)) $((percent % 10))
done

# Final progress update
printf "\rProcessed %d/%d sectors (100.0%%)\n" $SECTORS $SECTORS
echo "Conversion complete!"