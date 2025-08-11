# TVDOS Movie Encoder - Automatic Version

A simplified, user-friendly C program that automatically encodes videos into TVDOS-compatible movie files. This version internally uses FFmpeg and FFprobe to handle all video processing, making it as simple as a single command.

## Features

- **Automatic video analysis**: Uses FFprobe to detect frame count, FPS, duration, and audio
- **Built-in FFmpeg integration**: No manual pipe setup required
- **Automatic audio conversion**: Converts audio streams to MP2 format internally
- **Simple command-line interface**: Just specify input and output files
- **Flexible resolution**: Default 560x448 optimized for TSVM, or custom resolution
- **Stdout support**: Can output to stdout for piping to other tools

## Quick Start

### Installation

```bash
# Install dependencies (Ubuntu/Debian)
sudo apt-get install build-essential zlib1g-dev ffmpeg

# Build the encoder
make

# Test with sample video
./test.sh
```

### Basic Usage

```bash
# Simple conversion with default settings
./tvdos_encoder input.mp4 -o output.mov

# Custom resolution
./tvdos_encoder input.avi -s 1024x768 -o output.mov

# Output to stdout (for piping)
./tvdos_encoder input.mkv > output.mov
```

## Command Syntax

```
tvdos_encoder [options] input_video

Options:
  -o, --output FILE    Output TVDOS movie file (default: stdout)
  -s, --size WxH       Video resolution (default: 560x448)
  -h, --help           Show help message
```

## What Happens Automatically

1. **Video Analysis**: FFprobe extracts:
   - Frame count
   - Frame rate (FPS)
   - Duration
   - Audio stream detection

2. **Audio Processing**: If audio is present:
   - Converts to MP2 format at 32kHz
   - Uses optimal bitrate (256k) and psychoacoustic model
   - Creates temporary file for muxing

3. **Video Processing**: 
   - Scales video to specified resolution
   - Converts to raw RGB24 format
   - Pipes directly to encoder

4. **Encoding**: 
   - iPF Format 1-delta compression
   - Automatic keyframe detection (every 30 frames)
   - Zlib compression
   - TVDOS container format

## Examples

### Converting Different Video Formats

```bash
# Convert MP4 video
./tvdos_encoder movie.mp4 -o movie.mov

# Convert AVI with custom resolution
./tvdos_encoder video.avi -s 800x600 -o video.mov

# Convert MKV to stdout
./tvdos_encoder show.mkv > show.mov
```

### Batch Processing

```bash
#!/bin/bash
# Convert all MP4 files in directory
for file in *.mp4; do
    output="${file%.mp4}.mov"
    echo "Converting $file to $output..."
    ./tvdos_encoder "$file" -o "$output"
done
```

### Integration with Other Tools

```bash
# Download YouTube video and convert directly
yt-dlp -o - "https://youtube.com/watch?v=VIDEO_ID" | \
  ffmpeg -i pipe:0 -c copy temp.mp4 && \
  ./tvdos_encoder temp.mp4 -o youtube_video.mov

# Convert and immediately test in TSVM
./tvdos_encoder input.mp4 -o test.mov && \
  cp test.mov assets/disk0/
```

## Technical Details

### Automatic Resolution Handling

- **Default**: 560×448 (TSVM optimal)
- **Custom**: Any resolution supported by FFmpeg
- **Scaling**: Maintains aspect ratio with FFmpeg's scale filter

### Audio Processing Pipeline

```
Input Video → FFmpeg → MP2 (32kHz, 224k, stereo) → TVDOS Muxer
```

### Video Processing Pipeline

```
Input Video → FFmpeg → RGB24 frames → iPF1 Encoder → TVDOS Container
```

### Delta Compression

- **Keyframes**: Every 30 frames or when delta > 57.6% of original
- **P-frames**: Only changed 4×4 blocks are encoded
- **Opcodes**: SKIP, PATCH, END commands for efficient delta representation

## Performance

- **Speed**: Typically 50-100 FPS on modern hardware
- **Compression**: 70-90% reduction from raw RGB24
- **Memory**: Scales with resolution, ~10MB for 560×448

## Troubleshooting

### Common Issues

1. **"Failed to analyze video metadata"**
   - Check if input file exists and is a valid video
   - Ensure FFprobe is installed and accessible

2. **"Failed to start video conversion"** 
   - Verify FFmpeg installation
   - Check if input format is supported

3. **"Warning: Failed to convert audio"**
   - Audio conversion failed but video will proceed
   - May indicate unsupported audio codec

### Debugging

Enable verbose FFmpeg output by modifying the source:

```c
// Change this line in start_video_conversion():
"ffmpeg -i \"%s\" -f rawvideo -pix_fmt rgb24 -vf scale=%d:%d -y - 2>/dev/null"
// To:
"ffmpeg -i \"%s\" -f rawvideo -pix_fmt rgb24 -vf scale=%d:%d -y -"
```

### Supported Input Formats

Any format supported by your FFmpeg installation:
- MP4, AVI, MKV, MOV, WMV, FLV
- WebM, OGV, 3GP, M4V
- Raw formats, image sequences

## Comparison with Manual Pipeline

| Feature | Manual Pipeline | Auto Encoder |
|---------|----------------|---------------|
| Command complexity | High (3+ commands) | Low (1 command) |
| Error handling | Manual | Automatic |
| Metadata detection | Manual calculation | Automatic |
| Audio conversion | Separate step | Integrated |
| Ease of use | Expert | Beginner-friendly |

## Integration with TSVM

Generated .mov files are directly compatible with TSVM:

1. Copy to `assets/disk0/` directory
2. Load via TVDOS file operations
3. Play using TVDOS movie player

## Building from Source

### Dependencies

- GCC or compatible C compiler
- zlib development headers
- FFmpeg and FFprobe executables

### Compilation

```bash
make                    # Build encoder
make help              # Show build options
make test              # Show usage examples
make install-deps-ubuntu  # Install dependencies (Ubuntu)
```

## License

Part of the TSVM project ecosystem. Refer to main TSVM license for terms of use.
