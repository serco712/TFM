#if defined(D_NEXYS_A7)
   #include "bsp_printf.h"
   #include "bsp_mem_map.h"
   #include "bsp_version.h"
#else
   PRE_COMPILED_MSG("no platform was defined")
#endif

#include "psp_api.h"


#include <stdint.h>
#include <stdio.h>

#define RADDR_I   0x80001604
#define RDATA_O    0x80001608
#define RCAM    0x80001610

#define READ_ADDR(dir) (*(volatile unsigned *)dir)
#define WRITE_ADDR(dir, value) { (*(volatile unsigned *)dir) = (value); }

#include <stdlib.h>
#include <string.h>
#include <math.h>

// Para habilitar VLAs (Variable Length Arrays) si tu compilador lo soporta y lo deseas.
// O define un BLOCK_SIZE_MAX si no usas VLAs para los patches.
// #define BLOCK_SIZE_MAX 8 // Ejemplo


#define IMG_WIDTH 320
#define IMG_HEIGHT 240
#define BLOCK_SIZE 2       
#define TOT_BLOCK 4
#define K_NEIGHBORS 1       
#define MAX_PIXEL_VAL 255

#define MAX_DATASET_ITEMS 150 

typedef struct {
    unsigned char r, g, b;
} Pixel;

typedef struct {
    double r_avg, g_avg, b_avg; 
    char class_label;          
} DatasetItem;

typedef struct {
    double distance_sq; 
    char class_label;
} DistanceInfo;

static Pixel g_image_to_classify[IMG_HEIGHT][IMG_WIDTH];

DatasetItem g_training_dataset[MAX_DATASET_ITEMS] = {{255.0, 255.0, 255.0, 'c'}, {255.0, 255.0, 255.0, 'c'}, {255.0, 255.0, 255.0, 'c'}, {253.9375, 252.875, 251.8125, 'c'}, {250.75, 235.875, 218.875, 'c'}, {136.0, 139.1875, 136.0, 'c'}, {136.0, 136.0, 137.0625, 'c'}, {136.0, 136.0, 136.0, 'c'}, {136.0, 136.0, 136.0, 'c'}, {136.0, 136.0, 136.0, 'c'}, {227.375, 206.125, 197.625, 'c'}, {136.0, 131.75, 136.0, 'c'}, {136.0, 133.875, 134.9375, 'c'}, {136.0, 136.0, 133.875, 'c'}, {136.0, 133.875, 136.0, 'c'}, {136.0, 128.5625, 136.0, 'c'}, {134.9375, 122.1875, 136.0, 'c'}, {134.9375, 119.0, 136.0, 'c'}, {133.875, 119.0, 134.9375, 'c'}, {136.0, 122.1875, 134.9375, 'c'}, {136.0, 136.0, 136.0, 'c'}, {151.9375, 151.9375, 175.3125, 'c'}, {138.125, 136.0, 140.25, 'c'}, {137.0625, 137.0625, 141.3125, 'c'}, {137.0625, 136.0, 143.4375, 'c'}, {136.0, 138.125, 142.375, 'c'}, {136.0, 148.75, 139.1875, 'c'}, {136.0, 151.9375, 142.375, 'c'}, {136.0, 144.5, 141.3125, 'c'}, {136.0, 136.0, 138.125, 'c'}, {136.0, 133.875, 136.0, 'c'}, {136.0, 138.125, 136.0, 'c'}, {182.75, 182.75, 208.25, 'c'}, {136.0, 139.1875, 136.0, 'c'}, {136.0, 138.125, 136.0, 'c'}, {136.0, 139.1875, 136.0, 'c'}, {136.0, 136.0, 136.0, 'c'}, {136.0, 136.0, 136.0, 'c'}, {136.0, 136.0, 136.0, 'c'}, {137.0625, 136.0, 136.0, 'c'}, {136.0, 136.0, 133.875, 'c'}, {136.0, 136.0, 134.9375, 'c'}, {136.0, 134.9375, 136.0, 'c'}, {249.6875, 251.8125, 255.0, 'c'}, {134.9375, 131.75, 134.9375, 'c'}, {136.0, 120.0625, 131.75, 'c'}, {136.0, 119.0, 136.0, 'c'}, {136.0, 121.125, 134.9375, 'c'}, {134.9375, 119.0, 130.6875, 'c'}, {132.8125, 122.1875, 133.875, 'c'}, {134.9375, 132.8125, 136.0, 'c'}, {136.0, 134.9375, 138.125, 'c'}, {136.0, 136.0, 141.3125, 'c'}, {136.0, 138.125, 142.375, 'c'}, {255.0, 255.0, 255.0, 'c'}, {136.0, 146.625, 136.0, 'c'}, {136.0, 145.5625, 137.0625, 'c'}, {136.0, 141.3125, 139.1875, 'c'}, {255.0, 255.0, 255.0, 'c'}, {255.0, 255.0, 255.0, 'c'}, {255.0, 255.0, 255.0, 'c'}, {255.0, 255.0, 255.0, 'c'}, {35.0625, 58.4375, 44.625, 'n'}, {28.6875, 54.1875, 41.4375, 'n'}, {60.5625, 78.625, 51.0, 'n'}, {109.4375, 105.1875, 66.9375, 'n'}, {128.5625, 114.75, 69.0625, 'n'}, {137.0625, 125.375, 72.25, 'n'}, {141.3125, 128.5625, 71.1875, 'n'}, {87.125, 80.75, 57.375, 'n'}, {102.0, 100.9375, 68.0, 'n'}, {100.9375, 94.5625, 69.0625, 'n'}, {112.625, 105.1875, 62.6875, 'n'}, {123.25, 113.6875, 82.875, 'n'}, {125.375, 117.9375, 88.1875, 'n'}, {106.25, 104.125, 68.0, 'n'}, {104.125, 83.9375, 54.1875, 'n'}, {96.6875, 74.375, 51.0, 'n'}, {113.6875, 99.875, 64.8125, 'n'}, {117.9375, 105.1875, 62.6875, 'n'}, {124.3125, 111.5625, 95.625, 'n'}, {146.625, 123.25, 102.0, 'n'}, {127.5, 117.9375, 98.8125, 'n'}, {95.625, 100.9375, 51.0, 'n'}, {130.6875, 117.9375, 96.6875, 'n'}, {127.5, 110.5, 89.25, 'n'}, {110.5, 93.5, 79.6875, 'n'}, {119.0, 100.9375, 75.4375, 'n'}, {137.0625, 121.125, 102.0, 'n'}, {161.5, 138.125, 112.625, 'n'}, {168.9375, 142.375, 114.75, 'n'}, {168.9375, 139.1875, 117.9375, 'n'}, {26.5625, 59.5, 55.25, 'n'}, {30.8125, 57.375, 57.375, 'n'}, {89.25, 95.625, 52.0625, 'n'}, {24.4375, 53.125, 53.125, 'n'}, {25.5, 55.25, 52.0625, 'n'}, {31.875, 52.0625, 51.0, 'n'}, {51.0, 69.0625, 48.875, 'n'}, {108.375, 100.9375, 58.4375, 'n'}, {127.5, 117.9375, 68.0, 'n'}, {126.4375, 116.875, 66.9375, 'n'}, {92.4375, 100.9375, 53.125, 'n'}, {113.6875, 110.5, 61.625, 'n'}, {112.625, 108.375, 51.0, 'n'}, {103.0625, 105.1875, 57.375, 'n'}, {60.5625, 75.4375, 42.5, 'n'}, {83.9375, 93.5, 47.8125, 'n'}, {82.875, 93.5, 53.125, 'n'}, {65.875, 83.9375, 51.0, 'n'}, {75.4375, 81.8125, 51.0, 'n'}, {73.3125, 81.8125, 53.125, 'n'}, {81.8125, 86.0625, 56.3125, 'n'}, {96.6875, 104.125, 63.75, 'n'}, {91.375, 91.375, 53.125, 'n'}, {129.625, 121.125, 109.4375, 'n'}, {137.0625, 124.3125, 64.8125, 'n'}, {149.8125, 125.375, 100.9375, 'n'}, {136.0, 126.4375, 107.3125, 'n'}, {122.1875, 108.375, 103.0625, 'n'}, {86.0625, 87.125, 47.8125, 'n'}, {55.25, 71.1875, 51.0, 'n'}, {106.25, 109.4375, 56.3125, 'n'}, {123.25, 115.8125, 59.5, 'n'}};
static int g_training_dataset_actual_count = 144; 
static DistanceInfo g_knn_distances[MAX_DATASET_ITEMS];

#define CALCULATE_EUCLIDEAN_DIST_SQ(r1, g1, b1, item_ptr) ( \
    (((double)(r1)) - (item_ptr)->r_avg) * (((double)(r1)) - (item_ptr)->r_avg) + \
    (((double)(g1)) - (item_ptr)->g_avg) * (((double)(g1)) - (item_ptr)->g_avg) + \
    (((double)(b1)) - (item_ptr)->b_avg) * (((double)(b1)) - (item_ptr)->b_avg) \
)

int main() {

    unsigned int pixel;
    unsigned int cyc_beg, cyc_end;
    uint64_t cyc_tot = 0;
    unsigned int instr_beg, instr_end;
    unsigned int LdSt_beg, LdSt_end;
    unsigned int Inst_beg, Inst_end;

    uartInit();

    for (int r_idx = 0; r_idx < IMG_HEIGHT; ++r_idx) {
        for (int c_idx = 0; c_idx < IMG_WIDTH; ++c_idx) {
            WRITE_ADDR(RADDR_I,r_idx*IMG_WIDTH+c_idx);
            pixel = READ_ADDR(RDATA_O);
            g_image_to_classify[r_idx][c_idx].r = ((pixel >> 8) & 0x0F) * 17;
            g_image_to_classify[r_idx][c_idx].g = ((pixel >> 4) & 0x0F) * 17;
            g_image_to_classify[r_idx][c_idx].b = (pixel & 0x0F) * 17;
        }
    }

    const int num_blocks_y = IMG_HEIGHT / BLOCK_SIZE;
    const int num_blocks_x = IMG_WIDTH / BLOCK_SIZE;
    const double num_pixels_per_block = (double)BLOCK_SIZE * BLOCK_SIZE;

    unsigned int cloud_counter = 0;

    pspEnableAllPerformanceMonitor(1);

    pspPerformanceCounterSet(D_PSP_COUNTER0, E_CYCLES_CLOCKS_ACTIVE);


    for (int block_y_idx = 0; block_y_idx < num_blocks_y; ++block_y_idx) {
        for (int block_x_idx = 0; block_x_idx < num_blocks_x; ++block_x_idx) {
            cyc_beg = pspPerformanceCounterGet(D_PSP_COUNTER0);
            double current_block_sum_r = 0.0;
            double current_block_sum_g = 0.0;
            double current_block_sum_b = 0.0;

            int block_start_row = block_y_idx * BLOCK_SIZE;
            int block_start_col = block_x_idx * BLOCK_SIZE;

            for (int r_in_block = 0; r_in_block < BLOCK_SIZE; ++r_in_block) {
                for (int c_in_block = 0; c_in_block < BLOCK_SIZE; ++c_in_block) {
                    Pixel px = g_image_to_classify[block_start_row + r_in_block][block_start_col + c_in_block];
                    current_block_sum_r += px.r;
                    current_block_sum_g += px.g;
                    current_block_sum_b += px.b;
                }
            }
            double block_avg_r = current_block_sum_r / num_pixels_per_block;
            double block_avg_g = current_block_sum_g / num_pixels_per_block;
            double block_avg_b = current_block_sum_b / num_pixels_per_block;

            for (int i = 0; i < g_training_dataset_actual_count; ++i) {
                g_knn_distances[i].distance_sq = CALCULATE_EUCLIDEAN_DIST_SQ(block_avg_r, block_avg_g, block_avg_b, &g_training_dataset[i]);
                g_knn_distances[i].class_label = g_training_dataset[i].class_label;
            }

            for (int i = 1; i < g_training_dataset_actual_count; ++i) {
                DistanceInfo key = g_knn_distances[i];
                int j = i - 1;
                while (j >= 0 && g_knn_distances[j].distance_sq > key.distance_sq) {
                    g_knn_distances[j + 1] = g_knn_distances[j];
                    j = j - 1;
                }
                g_knn_distances[j + 1] = key;
            }

            int cloud_votes = 0;
            int nocloud_votes = 0;
            for (int i = 0; i < K_NEIGHBORS; ++i) {
                if (g_knn_distances[i].class_label == 'c') {
                    cloud_votes++;
                } else { 
                    nocloud_votes++;
                }
            }
            if (cloud_votes > nocloud_votes) {
                cloud_counter += TOT_BLOCK;
            }
            cyc_end = pspPerformanceCounterGet(D_PSP_COUNTER0);
            if (cyc_end > cyc_beg)
                cyc_tot += cyc_end-cyc_beg;
            else
                cyc_tot += cyc_end+(4294967294U-cyc_beg);
        } 
    } 


    printfNexys("Hay un total de %d píxeles de nube en la imagen de tamaño %d\n", cloud_counter, (IMG_HEIGHT*IMG_WIDTH));
    printfNexys("Ciclos = %lu\n", cyc_tot);

    return 0; 
}
