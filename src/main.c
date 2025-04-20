//--------------------------------------
// compile with gcc main.c -o main -lrt
//--------------------------------------

#include <stdio.h>
#include <stdint.h>
#include <stdbool.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <fcntl.h>
#include <sys/mman.h>
#include "time.h"

// LW bus: PIO.
#define FPGA_LW_BASE 0xff200000
#define FPGA_LW_SPAN 0x00001000

// Define address offsets.
#define LW_PIO_WRITE_0     0x00
#define LW_PIO_WRITE_1	   0x10
#define LW_PIO_READ        0x20
#define LW_PIO_READ_COUNT  0x30
#define LW_PIO_READ_COUNT2 0x40

// Prototypes for functions used to access physical memory addresses.
int open_physical (int);
void * map_physical (int, unsigned int, unsigned int);
void close_physical (int);
int unmap_physical (void *, unsigned int);

// Bit serialization function.
uint32_t get_bit_bus(uint8_t array[5][5], uint8_t bit_index) {
	uint32_t bus = 0;
  int bit_pos = 0;  // Current bit position in the 32-bit bus.
  int i, j;
  for (i = 0; i < 5; ++i) {
		for (j = 0; j < 5; ++j) {
			uint8_t value = (uint8_t)array[i][j];
      uint16_t bit = (value >> bit_index) & 0x1;  // Extract specific bit.
      bus |= (bit << bit_pos);
      ++bit_pos;
    }
	}
	return bus;
}

int main(void) {
  int fd = -1;               // used to open /dev/mem for access to physical addresses.
  void *h2p_lw_virtual_base; // used to map physical addresses for the light-weight bridge.

  // PIO used for communication.
  volatile uint32_t * lw_pio_write_0     = NULL;
  volatile uint32_t * lw_pio_write_1     = NULL;
  volatile uint32_t * lw_pio_read        = NULL;
  volatile uint32_t * lw_pio_read_count  = NULL;
  volatile uint32_t * lw_pio_read_count2 = NULL;
   
  // Create virtual memory access to the FPGA light-weight bridge.
  if ((fd = open_physical (fd)) == -1)
	  return (-1);
  if ((h2p_lw_virtual_base = map_physical (fd, FPGA_LW_BASE, FPGA_LW_SPAN)) == NULL)
	  return (-1);

	// Get the addresses that map to the two parallel ports on the light-weight bus.
	lw_pio_write_0      = (uint32_t *)(h2p_lw_virtual_base + LW_PIO_WRITE_0    );
	lw_pio_write_1      = (uint32_t *)(h2p_lw_virtual_base + LW_PIO_WRITE_1    );
	lw_pio_read         = (uint32_t *)(h2p_lw_virtual_base + LW_PIO_READ       );
	lw_pio_read_count   = (uint32_t *)(h2p_lw_virtual_base + LW_PIO_READ_COUNT );
	lw_pio_read_count2  = (uint32_t *)(h2p_lw_virtual_base + LW_PIO_READ_COUNT2);

  // Variable for "for" loop.
	int i, j, c, ki, kj;

	//-----------------------------------------------------
	// Initialize input array.
  // Format in .txt file:
  // height width channels
  // R G B  R G B  R G B  ... (for all pixels in row 0)
  // R G B  R G B  R G B  ... (for all pixels in row 1)
  // ...
	//----------------------------------------------------
  FILE *file = fopen("input_x.txt", "r");
  if (!file) {
		perror("Failed to open file");
		return (-1);
  }

  // Read dimensions from first line
  int height_in, width_in, channels;
  if (fscanf(file, "%d %d %d", &height_in, &width_in, &channels) != 3) {
    printf("Error reading image dimensions\n");
    fclose(file);
    return (-1);
  }
  printf("Image dimensions: %d rows, %d columns, %d channels\n", height_in, width_in, channels);
   
  // Allocate 3D array
  uint8_t ***x_array = malloc(height_in * sizeof(uint8_t **));
  for (i = 0; i < height_in; i++) {
    x_array[i] = malloc(width_in * sizeof(uint8_t *));
    for (j = 0; j < width_in; j++) {
			x_array[i][j] = malloc(channels * sizeof(uint8_t));
    }
  }
   
  // Read pixel values.
  for (i = 0; i < height_in; i++) {
    for (j = 0; j < width_in; j++) {
      for (c = 0; c < 3; c++) {
        if (fscanf(file, "%hhu", &x_array[i][j][c]) != 1) {
          printf("Error reading value at position [%d][%d][%d]\n", i, j, c);
        }
      }
    }
  }
   
  fclose(file);

	// Center-weighted filter with a blurring and smoothing effects.
	uint8_t k_array[5][5] = {
		{1, 1,  1, 1, 1},
		{1, 1,  1, 1, 1},
		{1, 1, 25, 1, 1},
		{1, 1,  1, 1, 1},
		{1, 1,  1, 1, 1}
	};
	
  // Performance counters.
	struct timespec start_conv_c, end_conv_c;
	double cpu_time_used;

	int stride_size = 1;
  int height_out  = (height_in - 5 + 1) / stride_size;
	int width_out   = (width_in - 5 + 1) / stride_size;

  // Allocate 3D array dynamically for output.
  uint16_t ***conv_out_c = malloc(height_out * sizeof(uint16_t **));
  for (i = 0; i < height_out; i++) {
    conv_out_c[i] = malloc(width_out * sizeof(uint16_t *));
    for (j = 0; j < width_out; j++) {
			conv_out_c[i][j] = malloc(channels * sizeof(uint16_t));
	    memset(conv_out_c[i][j], 0, channels * sizeof(uint16_t)); // Init to all zeros.
    }
  }

  uint16_t ***conv_out_fpga = malloc(height_out * sizeof(uint16_t **));
  for (i = 0; i < height_out; i++) {
    conv_out_fpga[i] = malloc(width_out * sizeof(uint16_t *));
    for (j = 0; j < width_out; j++) {
      conv_out_fpga[i][j] = malloc(channels * sizeof(uint16_t));
	    memset(conv_out_fpga[i][j], 0, channels * sizeof(uint16_t));
    }
  }

	//---------------------------------------
	// Convolution computation in C.
	//---------------------------------------
	clock_gettime(CLOCK_MONOTONIC_RAW, &start_conv_c);
	for (c = 0; c < 3; ++c){
	  for (i = 0; i < height_out; ++i){
	    for (j = 0; j < width_out; ++j){
	    	for (ki = 0; ki < 5; ++ki){
	    		for (kj = 0; kj < 5; ++kj){
						conv_out_c[i][j][c] += x_array[i*stride_size + ki][j*stride_size + kj][c] * k_array[ki][kj];
	    		}
	    	}
	    }
	  }
  }
	clock_gettime(CLOCK_MONOTONIC_RAW, &end_conv_c);
	cpu_time_used = (end_conv_c.tv_sec - start_conv_c.tv_sec) + ((end_conv_c.tv_nsec - start_conv_c.tv_nsec) / 1e9);

	printf("\nPerformance metrics in C code:\n");
	printf("Total time in C                  : %.9f seconds\n", cpu_time_used);
	printf("Average time per computation in C: %.9f useconds\n", 1e6*cpu_time_used/(height_out*width_out*3));

	//------------------------------------
	// Computation in FPGA.
	//------------------------------------
	uint8_t bits_sent = 0;
	uint8_t bits_read = 0;
	uint16_t read_value = 0;

	//------------------------------------
	// lw_pio_write_1 bit structure:
	// bit 24:0 - Input X bits.
	//------------------------------------

	//------------------------------------
	// lw_pio_write_1 bit structure:
	// bit 29   - perf. counter2 enable.
	// bit 28   - perf. counter reset.
    // bit 27  - reset.
	// bit 26   - ready.
	// bit 25   - valid.
	// bit 24:0 - Input kernel K bits.
	//------------------------------------

	//------------------------------------
	// lw_pio_read bit structure:
	// bit 3   - ready.
	// bit 2   - valid.
	// bit 1:0 - Convolution output bits.
	//------------------------------------
	
	// Initialize.
  *(lw_pio_write_0) = 0;
	*(lw_pio_write_1) = 0;
	*(lw_pio_write_1) |= (0x1 << 26);

	uint8_t x_array_small[5][5] = {0};

	// Reset performance counter.
	*(lw_pio_write_1) |= (0x1 << 28);
   *(lw_pio_write_1) &= ~(0x1 << 28);


	for (c = 0; c < 3; c++){
		for (i = 0; i < height_out; ++i) {
			for (j = 0; j < width_out; ++j) {
				for (ki = 0; ki < 5; ++ki) {
					for (kj = 0; kj < 5; ++kj) {
					  x_array_small[ki][kj] = x_array[ki + i*stride_size][kj + j*stride_size][c];
					}
				}
				
				bits_read = 0;
				bits_sent = 0;
	
				// Reset.
				*(lw_pio_write_1) |= (0x1 << 27);
				*(lw_pio_write_1) &= ~(0x1 << 27);
	
			
				// Enable performance counter2.
				*(lw_pio_write_1) |= (0x1 << 29);
	
				while(bits_read < 16) 
				{
				  // 1. Wait until ready is set. Unnecessary since 
					// by the time all other operations 
					// complete the FPGA will be always ready.
					// while( ~(*(lw_pio_read)) & (0x1 << 3));
			
					// 2. Set values.
					*(lw_pio_write_0) = get_bit_bus(x_array_small, bits_sent);
					*(lw_pio_write_1) = (0x1<<26)|(get_bit_bus(k_array, bits_sent));
					
					// 3. Set valid.
					*(lw_pio_write_1) |= (0x1 << 25);
			
					// 4. Reset valid. 
					*(lw_pio_write_1) &= ~(0x1 << 25);
			
					// 5. Read output.
					read_value = *(lw_pio_read);
			
					// 6. Check if there is valid data.
					if (read_value & (0x1 << 2)){
						conv_out_fpga[i][j][c] = ((read_value & 0x3) << bits_read)| (conv_out_fpga[i][j][c]);
						bits_read += 2;
						*(lw_pio_write_1) &= ~(0x1 << 26); // If there is: deassert the ready as an acknowledgement of successfull read.
						*(lw_pio_write_1) |= (0x1 << 26); // Then set ready again to clear successfull read flag.
					} // If there is none: continue.
			
					++bits_sent; // Calculate the number of bits sent.
				}
	
				// Disbale performance counter2.
				*(lw_pio_write_1) &= ~(0x1 << 29);
	
			}
		}
	}


	//------------------------------------
	// Compare results: Performance.
	//------------------------------------
	double fpga_time_used;
	fpga_time_used = (double)(*(lw_pio_read_count) / 50e6);
	printf("\nPerformance metrics in FPGA with no overhead:\n");
	printf("Total number of clock cycles required in FPGA                  : %.9f\n", (double)*(lw_pio_read_count));
	printf("Total time in FPGA                                             : %.9f seconds\n", fpga_time_used);
	printf("Average number of clock cycles required per computation in FPGA: %.9f\n", (double)(*(lw_pio_read_count))/(height_out*width_out*3));
	printf("Average time per computation in FPGA                           : %.9f useconds\n", 1e6*fpga_time_used/(height_out*width_out*3));

	double fpga_time_used2;
	fpga_time_used2 = (double)(*(lw_pio_read_count2) / 50e6);
	printf("\nPerformance metrics in FPGA with communication and scheduling overhead:\n");
	printf("Total number of clock cycles required in FPGA                  : %.9f\n", (double)*(lw_pio_read_count2));
	printf("Total time in FPGA                                             : %.9f seconds\n", fpga_time_used2);
	printf("Average number of clock cycles required per computation in FPGA: %.9f\n", (double)(*(lw_pio_read_count2))/(height_out*width_out*3));
	printf("Average time per computation in FPGA                           : %.9f useconds\n", 1e6*fpga_time_used2/(height_out*width_out*3));


	//------------------------------------
	// Compare results: Output.
	//------------------------------------
	bool pass = true;
	for (c = 0; c < 3; ++c){
		for (i = 0; i < height_out; ++i){
			for (j = 0; j < width_out; ++j){
				if (conv_out_c[i][j][c] != conv_out_fpga[i][j][c]) {
					pass = false;
				}
			}
		}
	}

	if (pass) printf("\nPASS\n");
	else      printf("\nFAIL\n");



	//------------------------------------
	// Write output into a file.
	//------------------------------------
  FILE *file_out = fopen("output_fpga.txt", "w");
  if (!file_out) {
    perror("Failed to open file for writing");
    return (-1);
  }
   
  // Write dimensions as header.
  fprintf(file_out, "%d %d %d\n", height_out, width_out, 3);
   
  // Write data.
  for (i = 0; i < height_out; i++) {
    for (j = 0; j < width_out; j++) {
      for (c = 0; c < 3; c++) {
        fprintf(file_out, "%hu ", conv_out_c[i][j][c]);
      }
      // Add a small separator between pixels.
      if (j < width_out - 1) {
        fprintf(file_out, " ");
      }
    }
    fprintf(file_out, "\n");
  }
  
	fclose(file_out);   
   
  // Free allocated memory.
  for (i = 0; i < height_in; i++) {
    for (j = 0; j < width_in; j++) {
      free(x_array[i][j]);
    }
    free(x_array[i]);
  }
  free(x_array);
	 
	for (i = 0; i < height_out; i++) {
    for (j = 0; j < width_out; j++) {
      free(conv_out_c[i][j]);
      free(conv_out_fpga[i][j]);
    }
    free(conv_out_c[i]);
    free(conv_out_fpga[i]);
  }
  free(conv_out_c);
  free(conv_out_fpga);
    
  unmap_physical (h2p_lw_virtual_base, FPGA_LW_SPAN);   // release the physical-memory mapping
  close_physical (fd);                                  // close /dev/mem
  return 0;
}

// Open /dev/mem, if not already done, to give access to physical addresses
int open_physical (int fd)
{
	if (fd == -1)
    if ((fd = open( "/dev/mem", (O_RDWR | O_SYNC))) == -1)
    {
			printf ("ERROR: could not open \"/dev/mem\"...\n");
      return (-1);
    }
  return fd;
}

// Close /dev/mem to give access to physical addresses
void close_physical (int fd)
{
   close (fd);
}

/*
 * Establish a virtual address mapping for the physical addresses starting at base, and
 * extending by span bytes.
 */
void* map_physical(int fd, unsigned int base, unsigned int span)
{
	void *virtual_base;

  // Get a mapping from physical addresses to virtual addresses
  virtual_base = mmap (NULL, span, (PROT_READ | PROT_WRITE), MAP_SHARED, fd, base);
  if (virtual_base == MAP_FAILED)
  {
    printf ("ERROR: mmap() failed...\n");
    close (fd);
    return (NULL);
  }
  return virtual_base;
}

/*
 * Close the previously-opened virtual address mapping
 */
int unmap_physical(void * virtual_base, unsigned int span)
{
	if (munmap (virtual_base, span) != 0)
  {
		printf ("ERROR: munmap() failed...\n");
    return (-1);
  }
  return 0;
}
