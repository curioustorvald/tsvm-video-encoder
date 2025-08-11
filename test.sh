#!/bin/bash

# Test script for TVDOS Movie Encoder (Auto version)

echo "TVDOS Movie Encoder Test Script (Auto Version)"
echo "=============================================="

# Check if encoder is built
if [ ! -f "./tvdos_encoder" ]; then
    echo "Building encoder..."
    make
    if [ $? -ne 0 ]; then
        echo "Build failed!"
        exit 1
    fi
fi

# Check if FFmpeg is available
if ! command -v ffmpeg &> /dev/null; then
    echo "FFmpeg is required but not installed."
    echo "Please install FFmpeg first."
    echo ""
    echo "Ubuntu/Debian: sudo apt-get install ffmpeg"
    echo "Fedora:        sudo dnf install ffmpeg" 
    echo "Arch:          sudo pacman -S ffmpeg"
    echo "macOS:         brew install ffmpeg"
    exit 1
fi

echo "Creating test video with audio..."

# Create test video (5 seconds, various frame rates)
echo "Generating test pattern video with sine wave audio..."
ffmpeg -f lavfi -i testsrc=duration=5:size=720x480:rate=30 \
       -f lavfi -i sine=frequency=440:duration=5 \
       -shortest -y test_input.mp4 -v quiet

if [ ! -f "test_input.mp4" ]; then
    echo "Failed to create test video"
    exit 1
fi

echo ""
echo "Test 1: Default resolution (560x448) with output file"
./tvdos_encoder test_input.mp4 -o test_output_default.mov

if [ $? -eq 0 ] && [ -f "test_output_default.mov" ]; then
    echo "✓ SUCCESS! Default resolution test passed"
    echo "File size: $(ls -lh test_output_default.mov | awk '{print $5}')"
else
    echo "✗ FAILED! Default resolution test failed"
    exit 1
fi

echo ""
echo "Test 2: Custom resolution (1024x768) with output file"
./tvdos_encoder test_input.mp4 -s 1024x768 -o test_output_custom.mov

if [ $? -eq 0 ] && [ -f "test_output_custom.mov" ]; then
    echo "✓ SUCCESS! Custom resolution test passed"
    echo "File size: $(ls -lh test_output_custom.mov | awk '{print $5}')"
else
    echo "✗ FAILED! Custom resolution test failed"
    exit 1
fi

echo ""
echo "Test 3: Output to stdout (piped to file)"
./tvdos_encoder test_input.mp4 > test_output_stdout.mov 2>/dev/null

if [ $? -eq 0 ] && [ -f "test_output_stdout.mov" ] && [ -s "test_output_stdout.mov" ]; then
    echo "✓ SUCCESS! Stdout output test passed"
    echo "File size: $(ls -lh test_output_stdout.mov | awk '{print $5}')"
else
    echo "✗ FAILED! Stdout output test failed"
    exit 1
fi

echo ""
echo "Analyzing output files..."
echo ""

for file in test_output_*.mov; do
    if [ -f "$file" ]; then
        echo "=== $file ==="
        echo "Size: $(ls -lh "$file" | awk '{print $5}')"
        echo "Magic header:"
        xxd -l 16 "$file" | head -1
        echo ""
    fi
done

# Test with a video that has no audio
echo "Test 4: Video without audio"
ffmpeg -f lavfi -i testsrc=duration=2:size=560x448:rate=15 -an -y test_no_audio.mp4 -v quiet

./tvdos_encoder test_no_audio.mp4 -o test_output_no_audio.mov

if [ $? -eq 0 ] && [ -f "test_output_no_audio.mov" ]; then
    echo "✓ SUCCESS! No audio test passed"
    echo "File size: $(ls -lh test_output_no_audio.mov | awk '{print $5}')"
else
    echo "✗ FAILED! No audio test failed"
fi

echo ""
echo "Testing help output..."
./tvdos_encoder --help | head -10

echo ""
echo "All tests completed!"
echo ""
echo "Generated files:"
ls -lh test_output_*.mov test_input.mp4 test_no_audio.mp4 2>/dev/null

echo ""
echo "To test with your own video files:"
echo "  ./tvdos_encoder input.mp4 -o output.mov"
echo "  ./tvdos_encoder input.avi -s 1024x768 -o output.mov"
echo "  ./tvdos_encoder input.mkv > output.mov"

# Clean up test files
echo ""
read -p "Clean up test files? (y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    rm -f test_input.mp4 test_no_audio.mp4 test_output_*.mov
    echo "Test files cleaned up."
fi

echo "Test complete!"