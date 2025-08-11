#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <string.h>

typedef struct {
    uint8_t magic[8];
    uint16_t width;
    uint16_t height;
    uint16_t fps;
    uint32_t frame_count;
    uint16_t unused;
    uint16_t audio_queue_info;
    uint8_t reserved[10];
} __attribute__((packed)) tvdos_header_t;

void print_header_analysis(tvdos_header_t *header) {
    printf("TVDOS File Analysis\n");
    printf("===================\n\n");
    
    printf("Magic: ");
    for (int i = 0; i < 8; i++) {
        printf("%02X ", header->magic[i]);
    }
    
    char expected[] = {0x1F, 0x54, 0x53, 0x56, 0x4D, 0x4D, 0x4F, 0x56};
    int magic_ok = memcmp(header->magic, expected, 8) == 0;
    printf("(%s)\n", magic_ok ? "OK" : "INVALID");
    
    printf("Dimensions: %dx%d\n", header->width, header->height);
    printf("FPS: %d\n", header->fps);
    printf("Frame Count: %d\n", header->frame_count);
    printf("Unused: 0x%04X\n", header->unused);
    
    // Decode audio queue info
    uint16_t audio_info = header->audio_queue_info;
    int queue_size = (audio_info >> 12) & 0xF;
    int block_size = (audio_info & 0xFFF) * 4;
    
    printf("Audio Queue Info: 0x%04X\n", audio_info);
    printf("  Queue Size: %d\n", queue_size);
    printf("  Block Size: %d bytes\n", block_size);
    printf("  Has Audio: %s\n", (queue_size > 0) ? "Yes" : "No");
    
    printf("Reserved: ");
    for (int i = 0; i < 10; i++) {
        printf("%02X ", header->reserved[i]);
    }
    printf("\n\n");
}

void analyze_packets(FILE *file, long start_pos) {
    fseek(file, start_pos, SEEK_SET);
    
    int packet_num = 0;
    uint8_t packet_type[2];
    
    printf("Packet Analysis\n");
    printf("===============\n\n");
    
    while (fread(packet_type, 1, 2, file) == 2) {
        long pos = ftell(file) - 2;
        printf("Packet %d @ 0x%lX: Type [%02X %02X] ", packet_num++, pos, packet_type[0], packet_type[1]);
        
        if (packet_type[0] == 0xFF && packet_type[1] == 0xFF) {
            printf("(SYNC)\n");
        }
        else if (packet_type[0] == 0xFF && packet_type[1] == 0xFE) {
            printf("(BACKGROUND COLOR)\n");
            uint8_t colors[4];
            if (fread(colors, 1, 4, file) == 4) {
                printf("  RGB: %d, %d, %d\n", colors[0], colors[1], colors[2]);
            }
        }
        else if (packet_type[0] == 0x04) {
            if (packet_type[1] == 0x00) {
                printf("(iPF Type 1)\n");
            } else if (packet_type[1] == 0x01) {
                printf("(iPF Type 2)\n");
            } else if (packet_type[1] == 0x02) {
                printf("(iPF Type 1-delta)\n");
            } else {
                printf("(iPF Type %d)\n", packet_type[1] + 1);
            }
            
            uint32_t size;
            if (fread(&size, 4, 1, file) == 1) {
                printf("  Size: %d bytes\n", size);
                fseek(file, size, SEEK_CUR); // Skip payload
            } else {
                printf("  ERROR: Could not read size\n");
                break;
            }
        }
        else if (packet_type[1] == 0x11) {
            printf("(MP2 Audio, rate index %d)\n", packet_type[0]);
            // MP2 has no size prefix, need to determine size from rate
            int mp2_sizes[] = {144, 216, 252, 288, 360, 432, 504, 576, 720, 864, 1008, 1152, 1440, 1728};
            int rate_idx = packet_type[0];
            
            // Handle extended rate indices
            if (rate_idx < 28) {
                int size = mp2_sizes[rate_idx / 2];
                printf("  Expected size: %d bytes\n", size);
                fseek(file, size, SEEK_CUR);
            } else {
                // For unknown rates, try to guess based on common sizes
                printf("  Extended rate index, guessing 576 bytes\n");
                fseek(file, 576, SEEK_CUR);
            }
        }
        else {
            printf("(UNKNOWN)\n");
            // Try to read size and skip
            uint32_t size;
            if (fread(&size, 4, 1, file) == 1 && size < 1000000) {
                printf("  Guessing size: %d bytes\n", size);
                fseek(file, size, SEEK_CUR);
            } else {
                printf("  Cannot determine packet size, stopping analysis\n");
                break;
            }
        }
        
        if (packet_num > 50) {
            printf("... (truncated after 50 packets)\n");
            break;
        }
    }
    
    printf("\nTotal packets analyzed: %d\n\n", packet_num);
}

int main(int argc, char *argv[]) {
    if (argc != 2) {
        printf("Usage: %s <tvdos_file.mov>\n", argv[0]);
        return 1;
    }
    
    FILE *file = fopen(argv[1], "rb");
    if (!file) {
        printf("Error: Cannot open file %s\n", argv[1]);
        return 1;
    }
    
    // Read header
    tvdos_header_t header;
    if (fread(&header, sizeof(header), 1, file) != 1) {
        printf("Error: Cannot read header\n");
        fclose(file);
        return 1;
    }
    
    print_header_analysis(&header);
    analyze_packets(file, sizeof(header));
    
    // Show file size info
    fseek(file, 0, SEEK_END);
    long file_size = ftell(file);
    printf("File size: %ld bytes\n", file_size);
    
    fclose(file);
    return 0;
}