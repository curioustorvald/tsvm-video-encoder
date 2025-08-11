CC = gcc
CFLAGS = -std=c99 -O2 -Wall -Wextra
LDFLAGS = -lz -lm

TARGET = tvdos_encoder
SOURCE = encoder.c

.PHONY: all clean test

all: $(TARGET)

$(TARGET): $(SOURCE)
	$(CC) $(CFLAGS) -o $(TARGET) $(SOURCE) $(LDFLAGS)

clean:
	rm -f $(TARGET)

test: $(TARGET)
	@echo "Creating test video with FFmpeg..."
	@echo "This requires FFmpeg to be installed"
	@echo "Usage examples:"
	@echo "  ./$(TARGET) input.mp4 -o output.mov"
	@echo "  ./$(TARGET) input.avi -s 1024x768 -o output.mov"
	@echo "  ./$(TARGET) input.mkv > output.mov"

install-deps-ubuntu:
	sudo apt-get update
	sudo apt-get install build-essential zlib1g-dev ffmpeg

install-deps-fedora:
	sudo dnf install gcc zlib-devel ffmpeg

install-deps-arch:
	sudo pacman -S gcc zlib ffmpeg

help:
	@echo "TVDOS Movie Encoder Build System"
	@echo ""
	@echo "Targets:"
	@echo "  all        - Build the encoder"
	@echo "  clean      - Remove built files"
	@echo "  test       - Show test usage example"
	@echo "  help       - Show this help"
	@echo ""
	@echo "Dependency installation:"
	@echo "  install-deps-ubuntu  - Install dependencies on Ubuntu/Debian"
	@echo "  install-deps-fedora  - Install dependencies on Fedora"
	@echo "  install-deps-arch    - Install dependencies on Arch Linux"
	@echo ""
	@echo "New simplified usage:"
	@echo "  ./$(TARGET) [options] input_video"
	@echo ""
	@echo "Options:"
	@echo "  -o, --output FILE    Output TVDOS movie file (default: stdout)"
	@echo "  -s, --size WxH       Video resolution (default: 560x448)"
	@echo "  -h, --help           Show help message"
	@echo ""
	@echo "Examples:"
	@echo "  ./$(TARGET) input.mp4 -o output.mov"
	@echo "  ./$(TARGET) input.avi -s 1024x768 -o output.mov"
	@echo "  ./$(TARGET) input.mkv > output.mov"