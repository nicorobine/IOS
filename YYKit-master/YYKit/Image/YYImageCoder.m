//
//  YYImageCoder.m
//  YYKit <https://github.com/ibireme/YYKit>
//
//  Created by ibireme on 15/5/13.
//  Copyright (c) 2015 ibireme.
//
//  This source code is licensed under the MIT-style license found in the
//  LICENSE file in the root directory of this source tree.
//

#import "YYImageCoder.h"
#import <CoreFoundation/CoreFoundation.h>
#import <ImageIO/ImageIO.h>
#import <Accelerate/Accelerate.h>
#import <QuartzCore/QuartzCore.h>
#import <MobileCoreServices/MobileCoreServices.h>
#import <AssetsLibrary/AssetsLibrary.h>
#import <objc/runtime.h>
#import <pthread.h>
#import <zlib.h>
#import "YYImage.h"
#import "YYKitMacro.h"

#ifndef YYIMAGE_WEBP_ENABLED
#if __has_include(<webp/decode.h>) && __has_include(<webp/encode.h>) && \
__has_include(<webp/demux.h>)  && __has_include(<webp/mux.h>)
#define YYIMAGE_WEBP_ENABLED 1
#import <webp/decode.h>
#import <webp/encode.h>
#import <webp/demux.h>
#import <webp/mux.h>
#elif __has_include("webp/decode.h") && __has_include("webp/encode.h") && \
__has_include("webp/demux.h")  && __has_include("webp/mux.h")
#define YYIMAGE_WEBP_ENABLED 1
#import "webp/decode.h"
#import "webp/encode.h"
#import "webp/demux.h"
#import "webp/mux.h"
#else
#define YYIMAGE_WEBP_ENABLED 0
#endif
#endif





////////////////////////////////////////////////////////////////////////////////
#pragma mark - Utility (for little endian platform)

#define YY_FOUR_CC(c1,c2,c3,c4) ((uint32_t)(((c4) << 24) | ((c3) << 16) | ((c2) << 8) | (c1)))
#define YY_TWO_CC(c1,c2) ((uint16_t)(((c2) << 8) | (c1)))

static inline uint16_t yy_swap_endian_uint16(uint16_t value) {
    return
    (uint16_t) ((value & 0x00FF) << 8) |
    (uint16_t) ((value & 0xFF00) >> 8) ;
}

static inline uint32_t yy_swap_endian_uint32(uint32_t value) {
    return
    (uint32_t)((value & 0x000000FFU) << 24) |
    (uint32_t)((value & 0x0000FF00U) <<  8) |
    (uint32_t)((value & 0x00FF0000U) >>  8) |
    (uint32_t)((value & 0xFF000000U) >> 24) ;
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark - APNG

/*
 PNG  spec: http://www.libpng.org/pub/png/spec/1.2/PNG-Structure.html
 APNG spec: https://wiki.mozilla.org/APNG_Specification
 
 ===============================================================================
 PNG format:
 header (8): 89 50 4e 47 0d 0a 1a 0a
 chunk, chunk, chunk, ...
 
 ===============================================================================
 chunk format:
 length (4): uint32_t big endian
 fourcc (4): chunk type code
 data   (length): data
 crc32  (4): uint32_t big endian crc32(fourcc + data)
 
 ===============================================================================
 PNG chunk define:
 
 IHDR (Image Header) required, must appear first, 13 bytes
 width              (4) pixel count, should not be zero
 height             (4) pixel count, should not be zero
 bit depth          (1) expected: 1, 2, 4, 8, 16
 color type         (1) 1<<0 (palette used), 1<<1 (color used), 1<<2 (alpha channel used)
 compression method (1) 0 (deflate/inflate)
 filter method      (1) 0 (adaptive filtering with five basic filter types)
 interlace method   (1) 0 (no interlace) or 1 (Adam7 interlace)
 
 IDAT (Image Data) required, must appear consecutively if there's multiple 'IDAT' chunk
 
 IEND (End) required, must appear last, 0 bytes
 
 ===============================================================================
 APNG chunk define:
 
 acTL (Animation Control) required, must appear before 'IDAT', 8 bytes
 num frames     (4) number of frames
 num plays      (4) number of times to loop, 0 indicates infinite looping
 
 fcTL (Frame Control) required, must appear before the 'IDAT' or 'fdAT' chunks of the frame to which it applies, 26 bytes
 sequence number   (4) sequence number of the animation chunk, starting from 0
 width             (4) width of the following frame
 height            (4) height of the following frame
 x offset          (4) x position at which to render the following frame
 y offset          (4) y position at which to render the following frame
 delay num         (2) frame delay fraction numerator
 delay den         (2) frame delay fraction denominator
 dispose op        (1) type of frame area disposal to be done after rendering this frame (0:none, 1:background 2:previous)
 blend op          (1) type of frame area rendering for this frame (0:source, 1:over)
 
 fdAT (Frame Data) required
 sequence number   (4) sequence number of the animation chunk
 frame data        (x) frame data for this frame (same as 'IDAT')
 
 ===============================================================================
 `dispose_op` specifies how the output buffer should be changed at the end of the delay 
 (before rendering the next frame).
 
 * NONE: no disposal is done on this frame before rendering the next; the contents
    of the output buffer are left as is.
 * BACKGROUND: the frame's region of the output buffer is to be cleared to fully
    transparent black before rendering the next frame.
 * PREVIOUS: the frame's region of the output buffer is to be reverted to the previous
    contents before rendering the next frame.

 `blend_op` specifies whether the frame is to be alpha blended into the current output buffer
 content, or whether it should completely replace its region in the output buffer.
 
 * SOURCE: all color components of the frame, including alpha, overwrite the current contents
    of the frame's output buffer region. 
 * OVER: the frame should be composited onto the output buffer based on its alpha,
    using a simple OVER operation as described in the "Alpha Channel Processing" section
    of the PNG specification
 */

typedef enum {
    YY_PNG_ALPHA_TYPE_PALEETE = 1 << 0,
    YY_PNG_ALPHA_TYPE_COLOR = 1 << 1,
    YY_PNG_ALPHA_TYPE_ALPHA = 1 << 2,
} yy_png_alpha_type;

typedef enum {
    YY_PNG_DISPOSE_OP_NONE = 0,
    YY_PNG_DISPOSE_OP_BACKGROUND = 1,
    YY_PNG_DISPOSE_OP_PREVIOUS = 2,
} yy_png_dispose_op;

typedef enum {
    YY_PNG_BLEND_OP_SOURCE = 0,
    YY_PNG_BLEND_OP_OVER = 1,
} yy_png_blend_op;

typedef struct {
    uint32_t width;             ///< pixel count, should not be zero
    uint32_t height;            ///< pixel count, should not be zero
    uint8_t bit_depth;          ///< expected: 1, 2, 4, 8, 16
    uint8_t color_type;         ///< see yy_png_alpha_type
    uint8_t compression_method; ///< 0 (deflate/inflate)
    uint8_t filter_method;      ///< 0 (adaptive filtering with five basic filter types)
    uint8_t interlace_method;   ///< 0 (no interlace) or 1 (Adam7 interlace)
} yy_png_chunk_IHDR;

typedef struct {
    uint32_t sequence_number;  ///< sequence number of the animation chunk, starting from 0
    uint32_t width;            ///< width of the following frame
    uint32_t height;           ///< height of the following frame
    uint32_t x_offset;         ///< x position at which to render the following frame
    uint32_t y_offset;         ///< y position at which to render the following frame
    uint16_t delay_num;        ///< frame delay fraction numerator
    uint16_t delay_den;        ///< frame delay fraction denominator
    uint8_t dispose_op;        ///< see yy_png_dispose_op
    uint8_t blend_op;          ///< see yy_png_blend_op
} yy_png_chunk_fcTL;

typedef struct {
    uint32_t offset; ///< chunk offset in PNG data
    uint32_t fourcc; ///< chunk fourcc
    uint32_t length; ///< chunk data length
    uint32_t crc32;  ///< chunk crc32
} yy_png_chunk_info;

typedef struct {
    uint32_t chunk_index; ///< the first `fdAT`/`IDAT` chunk index
    uint32_t chunk_num;   ///< the `fdAT`/`IDAT` chunk count
    uint32_t chunk_size;  ///< the `fdAT`/`IDAT` chunk bytes
    yy_png_chunk_fcTL frame_control;
} yy_png_frame_info;

typedef struct {
    yy_png_chunk_IHDR header;   ///< png header
    yy_png_chunk_info *chunks;      ///< chunks
    uint32_t chunk_num;          ///< count of chunks
    
    yy_png_frame_info *apng_frames; ///< frame info, NULL if not apng
    uint32_t apng_frame_num;     ///< 0 if not apng
    uint32_t apng_loop_num;      ///< 0 indicates infinite looping
    
    uint32_t *apng_shared_chunk_indexs; ///< shared chunk index
    uint32_t apng_shared_chunk_num;     ///< shared chunk count
    uint32_t apng_shared_chunk_size;    ///< shared chunk bytes
    uint32_t apng_shared_insert_index;  ///< shared chunk insert index
    bool apng_first_frame_is_cover;     ///< the first frame is same as png (cover)
} yy_png_info;

static void yy_png_chunk_IHDR_read(yy_png_chunk_IHDR *IHDR, const uint8_t *data) {
    IHDR->width = yy_swap_endian_uint32(*((uint32_t *)(data)));
    IHDR->height = yy_swap_endian_uint32(*((uint32_t *)(data + 4)));
    IHDR->bit_depth = data[8];
    IHDR->color_type = data[9];
    IHDR->compression_method = data[10];
    IHDR->filter_method = data[11];
    IHDR->interlace_method = data[12];
}

static void yy_png_chunk_IHDR_write(yy_png_chunk_IHDR *IHDR, uint8_t *data) {
    *((uint32_t *)(data)) = yy_swap_endian_uint32(IHDR->width);
    *((uint32_t *)(data + 4)) = yy_swap_endian_uint32(IHDR->height);
    data[8] = IHDR->bit_depth;
    data[9] = IHDR->color_type;
    data[10] = IHDR->compression_method;
    data[11] = IHDR->filter_method;
    data[12] = IHDR->interlace_method;
}

static void yy_png_chunk_fcTL_read(yy_png_chunk_fcTL *fcTL, const uint8_t *data) {
    fcTL->sequence_number = yy_swap_endian_uint32(*((uint32_t *)(data)));
    fcTL->width = yy_swap_endian_uint32(*((uint32_t *)(data + 4)));
    fcTL->height = yy_swap_endian_uint32(*((uint32_t *)(data + 8)));
    fcTL->x_offset = yy_swap_endian_uint32(*((uint32_t *)(data + 12)));
    fcTL->y_offset = yy_swap_endian_uint32(*((uint32_t *)(data + 16)));
    fcTL->delay_num = yy_swap_endian_uint16(*((uint16_t *)(data + 20)));
    fcTL->delay_den = yy_swap_endian_uint16(*((uint16_t *)(data + 22)));
    fcTL->dispose_op = data[24];
    fcTL->blend_op = data[25];
}

static void yy_png_chunk_fcTL_write(yy_png_chunk_fcTL *fcTL, uint8_t *data) {
    *((uint32_t *)(data)) = yy_swap_endian_uint32(fcTL->sequence_number);
    *((uint32_t *)(data + 4)) = yy_swap_endian_uint32(fcTL->width);
    *((uint32_t *)(data + 8)) = yy_swap_endian_uint32(fcTL->height);
    *((uint32_t *)(data + 12)) = yy_swap_endian_uint32(fcTL->x_offset);
    *((uint32_t *)(data + 16)) = yy_swap_endian_uint32(fcTL->y_offset);
    *((uint16_t *)(data + 20)) = yy_swap_endian_uint16(fcTL->delay_num);
    *((uint16_t *)(data + 22)) = yy_swap_endian_uint16(fcTL->delay_den);
    data[24] = fcTL->dispose_op;
    data[25] = fcTL->blend_op;
}

// convert double value to fraction
static void yy_png_delay_to_fraction(double duration, uint16_t *num, uint16_t *den) {
    if (duration >= 0xFF) {
        *num = 0xFF;
        *den = 1;
    } else if (duration <= 1.0 / (double)0xFF) {
        *num = 1;
        *den = 0xFF;
    } else {
        // Use continued fraction to calculate the num and den.
        long MAX = 10;
        double eps = (0.5 / (double)0xFF);
        long p[MAX], q[MAX], a[MAX], i, numl = 0, denl = 0;
        // The first two convergents are 0/1 and 1/0
        p[0] = 0; q[0] = 1;
        p[1] = 1; q[1] = 0;
        // The rest of the convergents (and continued fraction)
        for (i = 2; i < MAX; i++) {
            a[i] = lrint(floor(duration));
            p[i] = a[i] * p[i - 1] + p[i - 2];
            q[i] = a[i] * q[i - 1] + q[i - 2];
            if (p[i] <= 0xFF && q[i] <= 0xFF) { // uint16_t
                numl = p[i];
                denl = q[i];
            } else break;
            if (fabs(duration - a[i]) < eps) break;
            duration = 1.0 / (duration - a[i]);
        }
        
        if (numl != 0 && denl != 0) {
            *num = numl;
            *den = denl;
        } else {
            *num = 1;
            *den = 100;
        }
    }
}

// convert fraction to double value
static double yy_png_delay_to_seconds(uint16_t num, uint16_t den) {
    if (den == 0) {
        return num / 100.0;
    } else {
        return (double)num / (double)den;
    }
}

static bool yy_png_validate_animation_chunk_order(yy_png_chunk_info *chunks,  /* input */
                                                  uint32_t chunk_num,         /* input */
                                                  uint32_t *first_idat_index, /* output */
                                                  bool *first_frame_is_cover  /* output */) {
    /*
     PNG at least contains 3 chunks: IHDR, IDAT, IEND.
     `IHDR` must appear first.
     `IDAT` must appear consecutively.
     `IEND` must appear end.
     
     APNG must contains one `acTL` and at least one 'fcTL' and `fdAT`.
     `fdAT` must appear consecutively.
     `fcTL` must appear before `IDAT` or `fdAT`.
     */
    if (chunk_num <= 2) return false;
    if (chunks->fourcc != YY_FOUR_CC('I', 'H', 'D', 'R')) return false;
    if ((chunks + chunk_num - 1)->fourcc != YY_FOUR_CC('I', 'E', 'N', 'D')) return false;
    
    uint32_t prev_fourcc = 0;
    uint32_t IHDR_num = 0;
    uint32_t IDAT_num = 0;
    uint32_t acTL_num = 0;
    uint32_t fcTL_num = 0;
    uint32_t first_IDAT = 0;
    bool first_frame_cover = false;
    for (uint32_t i = 0; i < chunk_num; i++) {
        yy_png_chunk_info *chunk = chunks + i;
        switch (chunk->fourcc) {
            case YY_FOUR_CC('I', 'H', 'D', 'R'): {  // png header
                if (i != 0) return false;
                if (IHDR_num > 0) return false;
                IHDR_num++;
            } break;
            case YY_FOUR_CC('I', 'D', 'A', 'T'): {  // png data
                if (prev_fourcc != YY_FOUR_CC('I', 'D', 'A', 'T')) {
                    if (IDAT_num == 0)
                        first_IDAT = i;
                    else
                        return false;
                }
                IDAT_num++;
            } break;
            case YY_FOUR_CC('a', 'c', 'T', 'L'): {  // apng control
                if (acTL_num > 0) return false;
                acTL_num++;
            } break;
            case YY_FOUR_CC('f', 'c', 'T', 'L'): {  // apng frame control
                if (i + 1 == chunk_num) return false;
                if ((chunk + 1)->fourcc != YY_FOUR_CC('f', 'd', 'A', 'T') &&
                    (chunk + 1)->fourcc != YY_FOUR_CC('I', 'D', 'A', 'T')) {
                    return false;
                }
                if (fcTL_num == 0) {
                    if ((chunk + 1)->fourcc == YY_FOUR_CC('I', 'D', 'A', 'T')) {
                        first_frame_cover = true;
                    }
                }
                fcTL_num++;
            } break;
            case YY_FOUR_CC('f', 'd', 'A', 'T'): {  // apng data
                if (prev_fourcc != YY_FOUR_CC('f', 'd', 'A', 'T') && prev_fourcc != YY_FOUR_CC('f', 'c', 'T', 'L')) {
                    return false;
                }
            } break;
        }
        prev_fourcc = chunk->fourcc;
    }
    if (IHDR_num != 1) return false;
    if (IDAT_num == 0) return false;
    if (acTL_num != 1) return false;
    if (fcTL_num < acTL_num) return false;
    *first_idat_index = first_IDAT;
    *first_frame_is_cover = first_frame_cover;
    return true;
}

static void yy_png_info_release(yy_png_info *info) {
    if (info) {
        if (info->chunks) free(info->chunks);
        if (info->apng_frames) free(info->apng_frames);
        if (info->apng_shared_chunk_indexs) free(info->apng_shared_chunk_indexs);
        free(info);
    }
}

/**
 Create a png info from a png file. See struct png_info for more information.
 
 @param data   png/apng file data.
 @param length the data's length in bytes.
 @return A png info object, you may call yy_png_info_release() to release it.
 Returns NULL if an error occurs.
 */
static yy_png_info *yy_png_info_create(const uint8_t *data, uint32_t length) {
    if (length < 32) return NULL;
    if (*((uint32_t *)data) != YY_FOUR_CC(0x89, 0x50, 0x4E, 0x47)) return NULL;
    if (*((uint32_t *)(data + 4)) != YY_FOUR_CC(0x0D, 0x0A, 0x1A, 0x0A)) return NULL;
    
    uint32_t chunk_realloc_num = 16;
    yy_png_chunk_info *chunks = malloc(sizeof(yy_png_chunk_info) * chunk_realloc_num);
    if (!chunks) return NULL;
    
    // parse png chunks
    uint32_t offset = 8;
    uint32_t chunk_num = 0;
    uint32_t chunk_capacity = chunk_realloc_num;
    uint32_t apng_loop_num = 0;
    int32_t apng_sequence_index = -1;
    int32_t apng_frame_index = 0;
    int32_t apng_frame_number = -1;
    bool apng_chunk_error = false;
    do {
        if (chunk_num >= chunk_capacity) {
            yy_png_chunk_info *new_chunks = realloc(chunks, sizeof(yy_png_chunk_info) * (chunk_capacity + chunk_realloc_num));
            if (!new_chunks) {
                free(chunks);
                return NULL;
            }
            chunks = new_chunks;
            chunk_capacity += chunk_realloc_num;
        }
        yy_png_chunk_info *chunk = chunks + chunk_num;
        const uint8_t *chunk_data = data + offset;
        chunk->offset = offset;
        chunk->length = yy_swap_endian_uint32(*((uint32_t *)chunk_data));
        if ((uint64_t)chunk->offset + (uint64_t)chunk->length + 12 > length) {
            free(chunks);
            return NULL;
        }
        
        chunk->fourcc = *((uint32_t *)(chunk_data + 4));
        if ((uint64_t)chunk->offset + 4 + chunk->length + 4 > (uint64_t)length) break;
        chunk->crc32 = yy_swap_endian_uint32(*((uint32_t *)(chunk_data + 8 + chunk->length)));
        chunk_num++;
        offset += 12 + chunk->length;
        
        switch (chunk->fourcc) {
            case YY_FOUR_CC('a', 'c', 'T', 'L') : {
                if (chunk->length == 8) {
                    apng_frame_number = yy_swap_endian_uint32(*((uint32_t *)(chunk_data + 8)));
                    apng_loop_num = yy_swap_endian_uint32(*((uint32_t *)(chunk_data + 12)));
                } else {
                    apng_chunk_error = true;
                }
            } break;
            case YY_FOUR_CC('f', 'c', 'T', 'L') :
            case YY_FOUR_CC('f', 'd', 'A', 'T') : {
                if (chunk->fourcc == YY_FOUR_CC('f', 'c', 'T', 'L')) {
                    if (chunk->length != 26) {
                        apng_chunk_error = true;
                    } else {
                        apng_frame_index++;
                    }
                }
                if (chunk->length > 4) {
                    uint32_t sequence = yy_swap_endian_uint32(*((uint32_t *)(chunk_data + 8)));
                    if (apng_sequence_index + 1 == sequence) {
                        apng_sequence_index++;
                    } else {
                        apng_chunk_error = true;
                    }
                } else {
                    apng_chunk_error = true;
                }
            } break;
            case YY_FOUR_CC('I', 'E', 'N', 'D') : {
                offset = length; // end, break do-while loop
            } break;
        }
    } while (offset + 12 <= length);
    
    if (chunk_num < 3 ||
        chunks->fourcc != YY_FOUR_CC('I', 'H', 'D', 'R') ||
        chunks->length != 13) {
        free(chunks);
        return NULL;
    }
    
    // png info
    yy_png_info *info = calloc(1, sizeof(yy_png_info));
    if (!info) {
        free(chunks);
        return NULL;
    }
    info->chunks = chunks;
    info->chunk_num = chunk_num;
    yy_png_chunk_IHDR_read(&info->header, data + chunks->offset + 8);
    
    // apng info
    if (!apng_chunk_error && apng_frame_number == apng_frame_index && apng_frame_number >= 1) {
        bool first_frame_is_cover = false;
        uint32_t first_IDAT_index = 0;
        if (!yy_png_validate_animation_chunk_order(info->chunks, info->chunk_num, &first_IDAT_index, &first_frame_is_cover)) {
            return info; // ignore apng chunk
        }
        
        info->apng_loop_num = apng_loop_num;
        info->apng_frame_num = apng_frame_number;
        info->apng_first_frame_is_cover = first_frame_is_cover;
        info->apng_shared_insert_index = first_IDAT_index;
        info->apng_frames = calloc(apng_frame_number, sizeof(yy_png_frame_info));
        if (!info->apng_frames) {
            yy_png_info_release(info);
            return NULL;
        }
        info->apng_shared_chunk_indexs = calloc(info->chunk_num, sizeof(uint32_t));
        if (!info->apng_shared_chunk_indexs) {
            yy_png_info_release(info);
            return NULL;
        }
        
        int32_t frame_index = -1;
        uint32_t *shared_chunk_index = info->apng_shared_chunk_indexs;
        for (int32_t i = 0; i < info->chunk_num; i++) {
            yy_png_chunk_info *chunk = info->chunks + i;
            switch (chunk->fourcc) {
                case YY_FOUR_CC('I', 'D', 'A', 'T'): {
                    if (info->apng_shared_insert_index == 0) {
                        info->apng_shared_insert_index = i;
                    }
                    if (first_frame_is_cover) {
                        yy_png_frame_info *frame = info->apng_frames + frame_index;
                        frame->chunk_num++;
                        frame->chunk_size += chunk->length + 12;
                    }
                } break;
                case YY_FOUR_CC('a', 'c', 'T', 'L'): {
                } break;
                case YY_FOUR_CC('f', 'c', 'T', 'L'): {
                    frame_index++;
                    yy_png_frame_info *frame = info->apng_frames + frame_index;
                    frame->chunk_index = i + 1;
                    yy_png_chunk_fcTL_read(&frame->frame_control, data + chunk->offset + 8);
                } break;
                case YY_FOUR_CC('f', 'd', 'A', 'T'): {
                    yy_png_frame_info *frame = info->apng_frames + frame_index;
                    frame->chunk_num++;
                    frame->chunk_size += chunk->length + 12;
                } break;
                default: {
                    *shared_chunk_index = i;
                    shared_chunk_index++;
                    info->apng_shared_chunk_size += chunk->length + 12;
                    info->apng_shared_chunk_num++;
                } break;
            }
        }
    }
    return info;
}

/**
 Copy a png frame data from an apng file.
 
 @param data  apng file data
 @param info  png info
 @param index frame index (zero-based)
 @param size  output, the size of the frame data
 @return A frame data (single-frame png file), call free() to release the data.
 Returns NULL if an error occurs.
 */
static uint8_t *yy_png_copy_frame_data_at_index(const uint8_t *data,
                                                const yy_png_info *info,
                                                const uint32_t index,
                                                uint32_t *size) {
    if (index >= info->apng_frame_num) return NULL;
    
    yy_png_frame_info *frame_info = info->apng_frames + index;
    uint32_t frame_remux_size = 8 /* PNG Header */ + info->apng_shared_chunk_size + frame_info->chunk_size;
    if (!(info->apng_first_frame_is_cover && index == 0)) {
        frame_remux_size -= frame_info->chunk_num * 4; // remove fdAT sequence number
    }
    uint8_t *frame_data = malloc(frame_remux_size);
    if (!frame_data) return NULL;
    *size = frame_remux_size;
    
    uint32_t data_offset = 0;
    bool inserted = false;
    memcpy(frame_data, data, 8); // PNG File Header
    data_offset += 8;
    for (uint32_t i = 0; i < info->apng_shared_chunk_num; i++) {
        uint32_t shared_chunk_index = info->apng_shared_chunk_indexs[i];
        yy_png_chunk_info *shared_chunk_info = info->chunks + shared_chunk_index;
        
        if (shared_chunk_index >= info->apng_shared_insert_index && !inserted) { // replace IDAT with fdAT
            inserted = true;
            for (uint32_t c = 0; c < frame_info->chunk_num; c++) {
                yy_png_chunk_info *insert_chunk_info = info->chunks + frame_info->chunk_index + c;
                if (insert_chunk_info->fourcc == YY_FOUR_CC('f', 'd', 'A', 'T')) {
                    *((uint32_t *)(frame_data + data_offset)) = yy_swap_endian_uint32(insert_chunk_info->length - 4);
                    *((uint32_t *)(frame_data + data_offset + 4)) = YY_FOUR_CC('I', 'D', 'A', 'T');
                    memcpy(frame_data + data_offset + 8, data + insert_chunk_info->offset + 12, insert_chunk_info->length - 4);
                    uint32_t crc = (uint32_t)crc32(0, frame_data + data_offset + 4, insert_chunk_info->length);
                    *((uint32_t *)(frame_data + data_offset + insert_chunk_info->length + 4)) = yy_swap_endian_uint32(crc);
                    data_offset += insert_chunk_info->length + 8;
                } else { // IDAT
                    memcpy(frame_data + data_offset, data + insert_chunk_info->offset, insert_chunk_info->length + 12);
                    data_offset += insert_chunk_info->length + 12;
                }
            }
        }
        
        if (shared_chunk_info->fourcc == YY_FOUR_CC('I', 'H', 'D', 'R')) {
            uint8_t tmp[25] = {0};
            memcpy(tmp, data + shared_chunk_info->offset, 25);
            yy_png_chunk_IHDR IHDR = info->header;
            IHDR.width = frame_info->frame_control.width;
            IHDR.height = frame_info->frame_control.height;
            yy_png_chunk_IHDR_write(&IHDR, tmp + 8);
            *((uint32_t *)(tmp + 21)) = yy_swap_endian_uint32((uint32_t)crc32(0, tmp + 4, 17));
            memcpy(frame_data + data_offset, tmp, 25);
            data_offset += 25;
        } else {
            memcpy(frame_data + data_offset, data + shared_chunk_info->offset, shared_chunk_info->length + 12);
            data_offset += shared_chunk_info->length + 12;
        }
    }
    return frame_data;
}



////////////////////////////////////////////////////////////////////////////////
#pragma mark - Helper

/// Returns byte-aligned size.
static inline size_t YYImageByteAlign(size_t size, size_t alignment) {
    return ((size + (alignment - 1)) / alignment) * alignment;
}

/// Convert degree to radians
static inline CGFloat YYImageDegreesToRadians(CGFloat degrees) {
    return degrees * M_PI / 180;
}

CGColorSpaceRef YYCGColorSpaceGetDeviceRGB() {
    static CGColorSpaceRef space;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        space = CGColorSpaceCreateDeviceRGB();
    });
    return space;
}

CGColorSpaceRef YYCGColorSpaceGetDeviceGray() {
    static CGColorSpaceRef space;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        space = CGColorSpaceCreateDeviceGray();
    });
    return space;
}

BOOL YYCGColorSpaceIsDeviceRGB(CGColorSpaceRef space) {
    return space && CFEqual(space, YYCGColorSpaceGetDeviceRGB());
}

BOOL YYCGColorSpaceIsDeviceGray(CGColorSpaceRef space) {
    return space && CFEqual(space, YYCGColorSpaceGetDeviceGray());
}

/**
 A callback used in CGDataProviderCreateWithData() to release data.
 
 Example:
 
 void *data = malloc(size);
 CGDataProviderRef provider = CGDataProviderCreateWithData(data, data, size, YYCGDataProviderReleaseDataCallback);
 */
static void YYCGDataProviderReleaseDataCallback(void *info, const void *data, size_t size) {
    if (info) free(info);
}

/**
 Decode an image to bitmap buffer with the specified format.
 
 @param srcImage   Source image.
 @param dest       Destination buffer. It should be zero before call this method.
                   If decode succeed, you should release the dest->data using free().
 @param destFormat Destination bitmap format.
 
 @return Whether succeed.
 
 @warning This method support iOS7.0 and later. If call it on iOS6, it just returns NO.
 CG_AVAILABLE_STARTING(__MAC_10_9, __IPHONE_7_0)
 
 @note 将图片使用特定的格式解压成位图缓存
 */
static BOOL YYCGImageDecodeToBitmapBufferWithAnyFormat(CGImageRef srcImage, vImage_Buffer *dest, vImage_CGImageFormat *destFormat) {
    // 如果没有原图，没有vImageConvert_AnyToAny方法（iOS7才支持）,没有目标格式或者没有目标缓存直接返回失败
    if (!srcImage || (((long)vImageConvert_AnyToAny) + 1 == 1) || !destFormat || !dest) return NO;
    // 获取图片的大小
    size_t width = CGImageGetWidth(srcImage);
    size_t height = CGImageGetHeight(srcImage);
    if (width == 0 || height == 0) return NO;
    // 写入数据之前，dest缓存应该是空的
    dest->data = NULL;
    
    vImage_Error error = kvImageNoError;
    // 原图像的data数据
    CFDataRef srcData = NULL;
    // 格式转换器
    vImageConverterRef convertor = NULL;
    // 原图片的格式
    vImage_CGImageFormat srcFormat = {0};
    // 获取组成每个分量占用的位数
    srcFormat.bitsPerComponent = (uint32_t)CGImageGetBitsPerComponent(srcImage);
    // 每个像素占用的位置
    srcFormat.bitsPerPixel = (uint32_t)CGImageGetBitsPerPixel(srcImage);
    // 图片的颜色空间
    srcFormat.colorSpace = CGImageGetColorSpace(srcImage);
    // 图片的位图信息
    srcFormat.bitmapInfo = CGImageGetBitmapInfo(srcImage) | CGImageGetAlphaInfo(srcImage);
    
    // 初始化格式转换器
    convertor = vImageConverter_CreateWithCGImageFormat(&srcFormat, destFormat, NULL, kvImageNoFlags, NULL);
    if (!convertor) goto fail;
    
    // 初始化数据提供者
    CGDataProviderRef srcProvider = CGImageGetDataProvider(srcImage);
    // 复制数据提供者的数据 🤔️不知道为什么注释了decode
    srcData = srcProvider ? CGDataProviderCopyData(srcProvider) : NULL; // decode
    // 获取数据长度
    size_t srcLength = srcData ? CFDataGetLength(srcData) : 0;
    // 获取数据指针
    const void *srcBytes = srcData ? CFDataGetBytePtr(srcData) : NULL;
    if (srcLength == 0 || !srcBytes) goto fail;
    
    // 初始化原图缓存
    vImage_Buffer src = {0};
    src.data = (void *)srcBytes;
    src.width = width;
    src.height = height;
    src.rowBytes = CGImageGetBytesPerRow(srcImage);
    
    error = vImageBuffer_Init(dest, height, width, 32, kvImageNoFlags);
    if (error != kvImageNoError) goto fail;
    
    // 将原图缓存使用转换器转换为dest缓存图
    error = vImageConvert_AnyToAny(convertor, &src, dest, NULL, kvImageNoFlags); // convert
    if (error != kvImageNoError) goto fail;
    
    CFRelease(convertor);
    CFRelease(srcData);
    return YES;
    
fail:
    if (convertor) CFRelease(convertor);
    if (srcData) CFRelease(srcData);
    if (dest->data) free(dest->data);
    dest->data = NULL;
    return NO;
}

/**
 Decode an image to bitmap buffer with the 32bit format (such as ARGB8888).
 
 @param srcImage   Source image.
 @param dest       Destination buffer. It should be zero before call this method.
                   If decode succeed, you should release the dest->data using free().
 @param bitmapInfo Destination bitmap format.
 
 @return Whether succeed.
 
 @note 使用32位格式将图片解压成位图缓存
 */
static BOOL YYCGImageDecodeToBitmapBufferWith32BitFormat(CGImageRef srcImage, vImage_Buffer *dest, CGBitmapInfo bitmapInfo) {
    // 没有图片源和目标直接返回
    if (!srcImage || !dest) return NO;
    // 获取图片大小
    size_t width = CGImageGetWidth(srcImage);
    size_t height = CGImageGetHeight(srcImage);
    if (width == 0 || height == 0) return NO;
    
    // 是否包含alpha通道
    BOOL hasAlpha = NO;
    // alpha通道在颜色分量的第一位 AGRB和RGBA的区别
    BOOL alphaFirst = NO;
    // 每个颜色分量是否已经预乘了alpha
    BOOL alphaPremultiplied = NO;
    // 是否是一般的字节序列
    BOOL byteOrderNormal = NO;
    
    // 根据位图信息确认alpha信息
    switch (bitmapInfo & kCGBitmapAlphaInfoMask) {
        case kCGImageAlphaPremultipliedLast: {
            hasAlpha = YES;
            alphaPremultiplied = YES;
        } break;
        case kCGImageAlphaPremultipliedFirst: {
            hasAlpha = YES;
            alphaPremultiplied = YES;
            alphaFirst = YES;
        } break;
        case kCGImageAlphaLast: {
            hasAlpha = YES;
        } break;
        case kCGImageAlphaFirst: {
            hasAlpha = YES;
            alphaFirst = YES;
        } break;
        case kCGImageAlphaNoneSkipLast: {
        } break;
        case kCGImageAlphaNoneSkipFirst: {
            alphaFirst = YES;
        } break;
        default: {
            return NO;
        } break;
    }
    
    // 确定字节序列
    switch (bitmapInfo & kCGBitmapByteOrderMask) {
        case kCGBitmapByteOrderDefault: {
            byteOrderNormal = YES;
        } break;
        case kCGBitmapByteOrder32Little: {
        } break;
        case kCGBitmapByteOrder32Big: {
            byteOrderNormal = YES;
        } break;
        default: {
            return NO;
        } break;
    }
    
    /*
     Try convert with vImageConvert_AnyToAny() (avaliable since iOS 7.0).
     If fail, try decode with CGContextDrawImage().
     CGBitmapContext use a premultiplied alpha format, unpremultiply may lose precision.
     @note 先尝试使用vImageConvert_AnyToAny()转换（iOS7.0），如果失败了，使用CGContextDrawImage()
     CGBitmapContext使用了预乘的alpha，没有预乘alpla可能会丢失精度
     */
    // 目标图像格式
    vImage_CGImageFormat destFormat = {0};
    // 每个组成元素8位
    destFormat.bitsPerComponent = 8;
    // 每个像素元素32位
    destFormat.bitsPerPixel = 32;
    // 颜色空间
    destFormat.colorSpace = YYCGColorSpaceGetDeviceRGB();
    // 位图信息
    destFormat.bitmapInfo = bitmapInfo;
    dest->data = NULL;
    // 解压成位图
    if (YYCGImageDecodeToBitmapBufferWithAnyFormat(srcImage, dest, &destFormat)) return YES;
    
    // CGBitmapContext 只能使用预乘的alpha信息
    CGBitmapInfo contextBitmapInfo = bitmapInfo & kCGBitmapByteOrderMask;
    if (!hasAlpha || alphaPremultiplied) {
        contextBitmapInfo |= (bitmapInfo & kCGBitmapAlphaInfoMask);
    } else {
        contextBitmapInfo |= alphaFirst ? kCGImageAlphaPremultipliedFirst : kCGImageAlphaPremultipliedLast;
    }
    // 创建位图上下文
    CGContextRef context = CGBitmapContextCreate(NULL, width, height, 8, 0, YYCGColorSpaceGetDeviceRGB(), contextBitmapInfo);
    if (!context) goto fail;
    
    // 将图片绘制到上下文（解码和转化）
    CGContextDrawImage(context, CGRectMake(0, 0, width, height), srcImage); // decode and convert
    // 每行的字节数
    size_t bytesPerRow = CGBitmapContextGetBytesPerRow(context);
    // 大小
    size_t length = height * bytesPerRow;
    // 获取图像数据指针
    void *data = CGBitmapContextGetData(context);
    if (length == 0 || !data) goto fail;
    
    // 分配数据的空间
    dest->data = malloc(length);
    // 设置大小
    dest->width = width;
    dest->height = height;
    dest->rowBytes = bytesPerRow;
    if (!dest->data) goto fail;
    
    // 如果有alpha通道而且没有预乘，生成临时的bufeer，然后解除alpha预乘
    // 反之将datacopy到预留的data空间
    if (hasAlpha && !alphaPremultiplied) {
        vImage_Buffer tmpSrc = {0};
        tmpSrc.data = data;
        tmpSrc.width = width;
        tmpSrc.height = height;
        tmpSrc.rowBytes = bytesPerRow;
        vImage_Error error;
        if (alphaFirst && byteOrderNormal) {
            error = vImageUnpremultiplyData_ARGB8888(&tmpSrc, dest, kvImageNoFlags);
        } else {
            error = vImageUnpremultiplyData_RGBA8888(&tmpSrc, dest, kvImageNoFlags);
        }
        if (error != kvImageNoError) goto fail;
    } else {
        memcpy(dest->data, data, length);
    }
    
    CFRelease(context);
    return YES;
    
fail:
    if (context) CFRelease(context);
    if (dest->data) free(dest->data);
    dest->data = NULL;
    return NO;
    return NO;
}

// 创建一个image的解压缩的copy
CGImageRef YYCGImageCreateDecodedCopy(CGImageRef imageRef, BOOL decodeForDisplay) {
    if (!imageRef) return NULL;
    size_t width = CGImageGetWidth(imageRef);
    size_t height = CGImageGetHeight(imageRef);
    if (width == 0 || height == 0) return NULL;
    
    if (decodeForDisplay) { //decode with redraw (may lose some precision)
        CGImageAlphaInfo alphaInfo = CGImageGetAlphaInfo(imageRef) & kCGBitmapAlphaInfoMask;
        BOOL hasAlpha = NO;
        if (alphaInfo == kCGImageAlphaPremultipliedLast ||
            alphaInfo == kCGImageAlphaPremultipliedFirst ||
            alphaInfo == kCGImageAlphaLast ||
            alphaInfo == kCGImageAlphaFirst) {
            hasAlpha = YES;
        }
        // BGRA8888 (premultiplied) or BGRX8888
        // same as UIGraphicsBeginImageContext() and -[UIView drawRect:]
        CGBitmapInfo bitmapInfo = kCGBitmapByteOrder32Host;
        bitmapInfo |= hasAlpha ? kCGImageAlphaPremultipliedFirst : kCGImageAlphaNoneSkipFirst;
        CGContextRef context = CGBitmapContextCreate(NULL, width, height, 8, 0, YYCGColorSpaceGetDeviceRGB(), bitmapInfo);
        if (!context) return NULL;
        CGContextDrawImage(context, CGRectMake(0, 0, width, height), imageRef); // decode
        CGImageRef newImage = CGBitmapContextCreateImage(context);
        CFRelease(context);
        return newImage;
        
    } else {
        CGColorSpaceRef space = CGImageGetColorSpace(imageRef);
        size_t bitsPerComponent = CGImageGetBitsPerComponent(imageRef);
        size_t bitsPerPixel = CGImageGetBitsPerPixel(imageRef);
        size_t bytesPerRow = CGImageGetBytesPerRow(imageRef);
        CGBitmapInfo bitmapInfo = CGImageGetBitmapInfo(imageRef);
        if (bytesPerRow == 0 || width == 0 || height == 0) return NULL;
        
        CGDataProviderRef dataProvider = CGImageGetDataProvider(imageRef);
        if (!dataProvider) return NULL;
        CFDataRef data = CGDataProviderCopyData(dataProvider); // decode
        if (!data) return NULL;
        
        CGDataProviderRef newProvider = CGDataProviderCreateWithCFData(data);
        CFRelease(data);
        if (!newProvider) return NULL;
        
        CGImageRef newImage = CGImageCreate(width, height, bitsPerComponent, bitsPerPixel, bytesPerRow, space, bitmapInfo, newProvider, NULL, false, kCGRenderingIntentDefault);
        CFRelease(newProvider);
        return newImage;
    }
}

// 创建一个image的仿射转换后的image
CGImageRef YYCGImageCreateAffineTransformCopy(CGImageRef imageRef, CGAffineTransform transform, CGSize destSize, CGBitmapInfo destBitmapInfo) {
    // 没有原图像直接返回
    if (!imageRef) return NULL;
    // 获取原图片和目标图片的大小
    size_t srcWidth = CGImageGetWidth(imageRef);
    size_t srcHeight = CGImageGetHeight(imageRef);
    size_t destWidth = round(destSize.width);
    size_t destHeight = round(destSize.height);
    if (srcWidth == 0 || srcHeight == 0 || destWidth == 0 || destHeight == 0) return NULL;
    
    // 声明临时数据提供者变量和目标数据提供者变量
    CGDataProviderRef tmpProvider = NULL, destProvider = NULL;
    // 声明临时image和目标image变量
    CGImageRef tmpImage = NULL, destImage = NULL;
    // 声明源图像，临时图像和目标图像的buffer
    vImage_Buffer src = {0}, tmp = {0}, dest = {0};
    // 将图像解压成位图
    if(!YYCGImageDecodeToBitmapBufferWith32BitFormat(imageRef, &src, kCGImageAlphaFirst | kCGBitmapByteOrderDefault)) return NULL;
    
    // 计算目标的每行字节
    size_t destBytesPerRow = YYImageByteAlign(destWidth * 4, 32);
    // 临时buffer分配内存空间
    tmp.data = malloc(destHeight * destBytesPerRow);
    if (!tmp.data) goto fail;
    
    // 临时buffer设置
    tmp.width = destWidth;
    tmp.height = destHeight;
    tmp.rowBytes = destBytesPerRow;
    
    // 仿射转换信息
    vImage_CGAffineTransform vTransform = *((vImage_CGAffineTransform *)&transform);
    // 设置转换的背景色
    uint8_t backColor[4] = {0};
    // 转换到临时buffer
    vImage_Error error = vImageAffineWarpCG_ARGB8888(&src, &tmp, NULL, &vTransform, backColor, kvImageBackgroundColorFill);
    if (error != kvImageNoError) goto fail;
    free(src.data);
    src.data = NULL;
    
    // 初始化临时位图提供对象
    tmpProvider = CGDataProviderCreateWithData(tmp.data, tmp.data, destHeight * destBytesPerRow, YYCGDataProviderReleaseDataCallback);
    if (!tmpProvider) goto fail;
    // 临时buffer的data指向NULL，但是data仍被tmpProvider持有
    tmp.data = NULL; // hold by provider
    
    // 创建临时图像
    tmpImage = CGImageCreate(destWidth, destHeight, 8, 32, destBytesPerRow, YYCGColorSpaceGetDeviceRGB(), kCGImageAlphaFirst | kCGBitmapByteOrderDefault, tmpProvider, NULL, false, kCGRenderingIntentDefault);
    if (!tmpImage) goto fail;
    CFRelease(tmpProvider);
    tmpProvider = NULL;
    
    // 如果位图信息满足kCGImageAlphaFirst 且 不满足kCGBitmapByteOrder32Little，直接返回临时图片
    if ((destBitmapInfo & kCGBitmapAlphaInfoMask) == kCGImageAlphaFirst &&
        (destBitmapInfo & kCGBitmapByteOrderMask) != kCGBitmapByteOrder32Little) {
        return tmpImage;
    }
    
    // 将临时图像解压到目标buffer
    if (!YYCGImageDecodeToBitmapBufferWith32BitFormat(tmpImage, &dest, destBitmapInfo)) goto fail;
    CFRelease(tmpImage);
    tmpImage = NULL;
    
    // 初始化目标数据提供者
    destProvider = CGDataProviderCreateWithData(dest.data, dest.data, destHeight * destBytesPerRow, YYCGDataProviderReleaseDataCallback);
    if (!destProvider) goto fail;
    dest.data = NULL; // hold by provider
    // 生成目标image
    destImage = CGImageCreate(destWidth, destHeight, 8, 32, destBytesPerRow, YYCGColorSpaceGetDeviceRGB(), destBitmapInfo, destProvider, NULL, false, kCGRenderingIntentDefault);
    if (!destImage) goto fail;
    CFRelease(destProvider);
    destProvider = NULL;
    
    return destImage;
    
fail:
    if (src.data) free(src.data);
    if (tmp.data) free(tmp.data);
    if (dest.data) free(dest.data);
    if (tmpProvider) CFRelease(tmpProvider);
    if (tmpImage) CFRelease(tmpImage);
    if (destProvider) CFRelease(destProvider);
    return NULL;
}

// 将EXIF转换为UIImageOrientation
UIImageOrientation YYUIImageOrientationFromEXIFValue(NSInteger value) {
    switch (value) {
        case kCGImagePropertyOrientationUp: return UIImageOrientationUp;
        case kCGImagePropertyOrientationDown: return UIImageOrientationDown;
        case kCGImagePropertyOrientationLeft: return UIImageOrientationLeft;
        case kCGImagePropertyOrientationRight: return UIImageOrientationRight;
        case kCGImagePropertyOrientationUpMirrored: return UIImageOrientationUpMirrored;
        case kCGImagePropertyOrientationDownMirrored: return UIImageOrientationDownMirrored;
        case kCGImagePropertyOrientationLeftMirrored: return UIImageOrientationLeftMirrored;
        case kCGImagePropertyOrientationRightMirrored: return UIImageOrientationRightMirrored;
        default: return UIImageOrientationUp;
    }
}

// 将UIImageOrientation转换为EXIF
NSInteger YYUIImageOrientationToEXIFValue(UIImageOrientation orientation) {
    switch (orientation) {
        case UIImageOrientationUp: return kCGImagePropertyOrientationUp;
        case UIImageOrientationDown: return kCGImagePropertyOrientationDown;
        case UIImageOrientationLeft: return kCGImagePropertyOrientationLeft;
        case UIImageOrientationRight: return kCGImagePropertyOrientationRight;
        case UIImageOrientationUpMirrored: return kCGImagePropertyOrientationUpMirrored;
        case UIImageOrientationDownMirrored: return kCGImagePropertyOrientationDownMirrored;
        case UIImageOrientationLeftMirrored: return kCGImagePropertyOrientationLeftMirrored;
        case UIImageOrientationRightMirrored: return kCGImagePropertyOrientationRightMirrored;
        default: return kCGImagePropertyOrientationUp;
    }
}

// 创建一个image的copy
CGImageRef YYCGImageCreateCopyWithOrientation(CGImageRef imageRef, UIImageOrientation orientation, CGBitmapInfo destBitmapInfo) {
    // 没有原始图像直接返回
    if (!imageRef) return NULL;
    // 如果方向向上，返回原图片的retain
    if (orientation == UIImageOrientationUp) return (CGImageRef)CFRetain(imageRef);
    
    // 获取原图片的大小
    size_t width = CGImageGetWidth(imageRef);
    size_t height = CGImageGetHeight(imageRef);
    
    // 声明转换
    CGAffineTransform transform = CGAffineTransformIdentity;
    // 是否交换高度和宽度
    BOOL swapWidthAndHeight = NO;
    
    // 设置仿射转换
    switch (orientation) {
        case UIImageOrientationDown: {
            transform = CGAffineTransformMakeRotation(YYImageDegreesToRadians(180));
            transform = CGAffineTransformTranslate(transform, -(CGFloat)width, -(CGFloat)height);
        } break;
        case UIImageOrientationLeft: {
            transform = CGAffineTransformMakeRotation(YYImageDegreesToRadians(90));
            transform = CGAffineTransformTranslate(transform, -(CGFloat)0, -(CGFloat)height);
            swapWidthAndHeight = YES;
        } break;
        case UIImageOrientationRight: {
            transform = CGAffineTransformMakeRotation(YYImageDegreesToRadians(-90));
            transform = CGAffineTransformTranslate(transform, -(CGFloat)width, (CGFloat)0);
            swapWidthAndHeight = YES;
        } break;
        case UIImageOrientationUpMirrored: {
            transform = CGAffineTransformTranslate(transform, (CGFloat)width, 0);
            transform = CGAffineTransformScale(transform, -1, 1);
        } break;
        case UIImageOrientationDownMirrored: {
            transform = CGAffineTransformTranslate(transform, 0, (CGFloat)height);
            transform = CGAffineTransformScale(transform, 1, -1);
        } break;
        case UIImageOrientationLeftMirrored: {
            transform = CGAffineTransformMakeRotation(YYImageDegreesToRadians(-90));
            transform = CGAffineTransformScale(transform, 1, -1);
            transform = CGAffineTransformTranslate(transform, -(CGFloat)width, -(CGFloat)height);
            swapWidthAndHeight = YES;
        } break;
        case UIImageOrientationRightMirrored: {
            transform = CGAffineTransformMakeRotation(YYImageDegreesToRadians(90));
            transform = CGAffineTransformScale(transform, 1, -1);
            swapWidthAndHeight = YES;
        } break;
        default: break;
    }
    if (CGAffineTransformIsIdentity(transform)) return (CGImageRef)CFRetain(imageRef);
    
    // 是否切换宽度和高度
    CGSize destSize = {width, height};
    if (swapWidthAndHeight) {
        destSize.width = height;
        destSize.height = width;
    }
    
    // 进行进行转换
    return YYCGImageCreateAffineTransformCopy(imageRef, transform, destSize, destBitmapInfo);
}

// 利用图像压缩类型
YYImageType YYImageDetectType(CFDataRef data) {
    if (!data) return YYImageTypeUnknown;
    uint64_t length = CFDataGetLength(data);
    if (length < 16) return YYImageTypeUnknown;
    
    // 获取数据指针
    const char *bytes = (char *)CFDataGetBytePtr(data);
    
    // 获取前32位
    uint32_t magic4 = *((uint32_t *)bytes);
    switch (magic4) {
        case YY_FOUR_CC(0x4D, 0x4D, 0x00, 0x2A): { // big endian TIFF
            return YYImageTypeTIFF;
        } break;
            
        case YY_FOUR_CC(0x49, 0x49, 0x2A, 0x00): { // little endian TIFF
            return YYImageTypeTIFF;
        } break;
            
        case YY_FOUR_CC(0x00, 0x00, 0x01, 0x00): { // ICO
            return YYImageTypeICO;
        } break;
            
        case YY_FOUR_CC(0x00, 0x00, 0x02, 0x00): { // CUR
            return YYImageTypeICO;
        } break;
            
        case YY_FOUR_CC('i', 'c', 'n', 's'): { // ICNS
            return YYImageTypeICNS;
        } break;
            
        case YY_FOUR_CC('G', 'I', 'F', '8'): { // GIF
            return YYImageTypeGIF;
        } break;
            
        case YY_FOUR_CC(0x89, 'P', 'N', 'G'): {  // PNG
            uint32_t tmp = *((uint32_t *)(bytes + 4));
            if (tmp == YY_FOUR_CC('\r', '\n', 0x1A, '\n')) {
                return YYImageTypePNG;
            }
        } break;
            
        case YY_FOUR_CC('R', 'I', 'F', 'F'): { // WebP
            uint32_t tmp = *((uint32_t *)(bytes + 8));
            if (tmp == YY_FOUR_CC('W', 'E', 'B', 'P')) {
                return YYImageTypeWebP;
            }
        } break;
        /*
        case YY_FOUR_CC('B', 'P', 'G', 0xFB): { // BPG
            return YYImageTypeBPG;
        } break;
        */
    }
    
    uint16_t magic2 = *((uint16_t *)bytes);
    switch (magic2) {
        case YY_TWO_CC('B', 'A'):
        case YY_TWO_CC('B', 'M'):
        case YY_TWO_CC('I', 'C'):
        case YY_TWO_CC('P', 'I'):
        case YY_TWO_CC('C', 'I'):
        case YY_TWO_CC('C', 'P'): { // BMP
            return YYImageTypeBMP;
        }
        case YY_TWO_CC(0xFF, 0x4F): { // JPEG2000
            return YYImageTypeJPEG2000;
        }
    }
    
    // JPG             FF D8 FF
    if (memcmp(bytes,"\377\330\377",3) == 0) return YYImageTypeJPEG;
    
    // JP2
    if (memcmp(bytes + 4, "\152\120\040\040\015", 5) == 0) return YYImageTypeJPEG2000;
    
    return YYImageTypeUnknown;
}

// 将YYImageType转换为UTI
CFStringRef YYImageTypeToUTType(YYImageType type) {
    switch (type) {
        case YYImageTypeJPEG: return kUTTypeJPEG;
        case YYImageTypeJPEG2000: return kUTTypeJPEG2000;
        case YYImageTypeTIFF: return kUTTypeTIFF;
        case YYImageTypeBMP: return kUTTypeBMP;
        case YYImageTypeICO: return kUTTypeICO;
        case YYImageTypeICNS: return kUTTypeAppleICNS;
        case YYImageTypeGIF: return kUTTypeGIF;
        case YYImageTypePNG: return kUTTypePNG;
        default: return NULL;
    }
}
// 将UTI转换为YYImageType
YYImageType YYImageTypeFromUTType(CFStringRef uti) {
    static NSDictionary *dic;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        dic = @{(id)kUTTypeJPEG : @(YYImageTypeJPEG),
                (id)kUTTypeJPEG2000 : @(YYImageTypeJPEG2000),
                (id)kUTTypeTIFF : @(YYImageTypeTIFF),
                (id)kUTTypeBMP : @(YYImageTypeBMP),
                (id)kUTTypeICO : @(YYImageTypeICO),
                (id)kUTTypeAppleICNS : @(YYImageTypeICNS),
                (id)kUTTypeGIF : @(YYImageTypeGIF),
                (id)kUTTypePNG : @(YYImageTypePNG)};
    });
    if (!uti) return YYImageTypeUnknown;
    NSNumber *num = dic[(__bridge __strong id)(uti)];
    return num.unsignedIntegerValue;
}

// 根据YYImageType获取图像后缀
NSString *YYImageTypeGetExtension(YYImageType type) {
    switch (type) {
        case YYImageTypeJPEG: return @"jpg";
        case YYImageTypeJPEG2000: return @"jp2";
        case YYImageTypeTIFF: return @"tiff";
        case YYImageTypeBMP: return @"bmp";
        case YYImageTypeICO: return @"ico";
        case YYImageTypeICNS: return @"icns";
        case YYImageTypeGIF: return @"gif";
        case YYImageTypePNG: return @"png";
        case YYImageTypeWebP: return @"webp";
        default: return nil;
    }
}

// 将图片进行编码
CFDataRef YYCGImageCreateEncodedData(CGImageRef imageRef, YYImageType type, CGFloat quality) {
    if (!imageRef) return nil;
    quality = quality < 0 ? 0 : quality > 1 ? 1 : quality;
 
    // 如果支持WebP则对WebP类型的图片编码，如果不支持返回NULL
    if (type == YYImageTypeWebP) {
#if YYIMAGE_WEBP_ENABLED
        if (quality == 1) {
            return YYCGImageCreateEncodedWebPData(imageRef, YES, quality, 4, YYImagePresetDefault);
        } else {
            return YYCGImageCreateEncodedWebPData(imageRef, NO, quality, 4, YYImagePresetDefault);
        }
#else
        return NULL;
#endif
    }
    
    // 转换成UTI类型
    CFStringRef uti = YYImageTypeToUTType(type);
    if (!uti) return nil;
    
    // 初始化可变数据
    CFMutableDataRef data = CFDataCreateMutable(CFAllocatorGetDefault(), 0);
    if (!data) return NULL;
    // 初始化图像目标变量
    CGImageDestinationRef dest = CGImageDestinationCreateWithData(data, uti, 1, NULL);
    if (!dest) {
        CFRelease(data);
        return NULL;
    }
    // 确定压缩比
    NSDictionary *options = @{(id)kCGImageDestinationLossyCompressionQuality : @(quality) };
    // 位图像目标添加图片 这个方法应该会直接将imageRef压缩成data
    CGImageDestinationAddImage(dest, imageRef, (CFDictionaryRef)options);
    if (!CGImageDestinationFinalize(dest)) {
        CFRelease(data);
        CFRelease(dest);
        return nil;
    }
    CFRelease(dest);
    
    if (CFDataGetLength(data) == 0) {
        CFRelease(data);
        return NULL;
    }
    return data;
}

#if YYIMAGE_WEBP_ENABLED

BOOL YYImageWebPAvailable() {
    return YES;
}

// 压缩WebP图片
CFDataRef YYCGImageCreateEncodedWebPData(CGImageRef imageRef, BOOL lossless, CGFloat quality, int compressLevel, YYImagePreset preset) {
    // 做一些验证判断是否可以压缩成WebP
    if (!imageRef) return nil;
    size_t width = CGImageGetWidth(imageRef);
    size_t height = CGImageGetHeight(imageRef);
    if (width == 0 || width > WEBP_MAX_DIMENSION) return nil;
    if (height == 0 || height > WEBP_MAX_DIMENSION) return nil;
    
    // 声明buffer变量
    vImage_Buffer buffer = {0};
    // 将图片解压到buffer
    if(!YYCGImageDecodeToBitmapBufferWith32BitFormat(imageRef, &buffer, kCGImageAlphaLast | kCGBitmapByteOrderDefault)) return nil;
    
    // 初始化WebP变量
    WebPConfig config = {0};
    WebPPicture picture = {0};
    WebPMemoryWriter writer = {0};
    CFDataRef webpData = NULL;
    BOOL pictureNeedFree = NO;
    
    // 压缩质量
    quality = quality < 0 ? 0 : quality > 1 ? 1 : quality;
    // 预置压缩成图片大小
    preset = preset > YYImagePresetText ? YYImagePresetDefault : preset;
    // 压缩等级
    compressLevel = compressLevel < 0 ? 0 : compressLevel > 6 ? 6 : compressLevel;
    // 初始化WebP设置
    if (!WebPConfigPreset(&config, (WebPPreset)preset, quality)) goto fail;
    
    // 质量从0-1变为0-100
    config.quality = round(quality * 100.0);
    // 是否是无损的
    config.lossless = lossless;
    // 压缩等级
    config.method = compressLevel;
    // 图片预置大小
    switch ((WebPPreset)preset) {
        case WEBP_PRESET_DEFAULT: {
            config.image_hint = WEBP_HINT_DEFAULT;
        } break;
        case WEBP_PRESET_PICTURE: {
            config.image_hint = WEBP_HINT_PICTURE;
        } break;
        case WEBP_PRESET_PHOTO: {
            config.image_hint = WEBP_HINT_PHOTO;
        } break;
        case WEBP_PRESET_DRAWING:
        case WEBP_PRESET_ICON:
        case WEBP_PRESET_TEXT: {
            config.image_hint = WEBP_HINT_GRAPH;
        } break;
    }
    // 验证设置是否有效
    if (!WebPValidateConfig(&config)) goto fail;
    
    // 初始化webpPicture
    if (!WebPPictureInit(&picture)) goto fail;
    pictureNeedFree = YES;
    picture.width = (int)buffer.width;
    picture.height = (int)buffer.height;
    picture.use_argb = lossless;
    if(!WebPPictureImportRGBA(&picture, buffer.data, (int)buffer.rowBytes)) goto fail;
    
    // 初始化writter
    WebPMemoryWriterInit(&writer);
    picture.writer = WebPMemoryWrite;
    picture.custom_ptr = &writer;
    if(!WebPEncode(&config, &picture)) goto fail;
    
    // 获取webpData
    webpData = CFDataCreate(CFAllocatorGetDefault(), writer.mem, writer.size);
    free(writer.mem);
    WebPPictureFree(&picture);
    free(buffer.data);
    return webpData;
    
fail:
    if (buffer.data) free(buffer.data);
    if (pictureNeedFree) WebPPictureFree(&picture);
    return nil;
}

NSUInteger YYImageGetWebPFrameCount(CFDataRef webpData) {
    if (!webpData || CFDataGetLength(webpData) == 0) return 0;
    
    WebPData data = {CFDataGetBytePtr(webpData), CFDataGetLength(webpData)};
    WebPDemuxer *demuxer = WebPDemux(&data);
    if (!demuxer) return 0;
    NSUInteger webpFrameCount = WebPDemuxGetI(demuxer, WEBP_FF_FRAME_COUNT);
    WebPDemuxDelete(demuxer);
    return webpFrameCount;
}

// 根据webpData生成image图片
CGImageRef YYCGImageCreateWithWebPData(CFDataRef webpData,
                                       BOOL decodeForDisplay,
                                       BOOL useThreads,
                                       BOOL bypassFiltering,
                                       BOOL noFancyUpsampling) {
    /*
     Call WebPDecode() on a multi-frame webp data will get an error (VP8_STATUS_UNSUPPORTED_FEATURE).
     Use WebPDemuxer to unpack it first.
     @note 直接使用WebPDecode()方法解压多帧的webP数据会报错，需要先使用webpDemuxer打开封装
     */
    // 声明webpData变量和多帧webp图片解压缩器
    WebPData data = {0};
    WebPDemuxer *demuxer = NULL;
    
    // 声明帧数，画布大小变量
    int frameCount = 0, canvasWidth = 0, canvasHeight = 0;
    WebPIterator iter = {0};
    BOOL iterInited = NO;
    const uint8_t *payload = NULL;
    size_t payloadSize = 0;
    WebPDecoderConfig config = {0};
    
    BOOL hasAlpha = NO;
    size_t bitsPerComponent = 0, bitsPerPixel = 0, bytesPerRow = 0, destLength = 0;
    CGBitmapInfo bitmapInfo = 0;
    WEBP_CSP_MODE colorspace = 0;
    void *destBytes = NULL;
    CGDataProviderRef provider = NULL;
    CGImageRef imageRef = NULL;
    
    if (!webpData || CFDataGetLength(webpData) == 0) return NULL;
    data.bytes = CFDataGetBytePtr(webpData);
    data.size = CFDataGetLength(webpData);
    demuxer = WebPDemux(&data);
    if (!demuxer) goto fail;
    
    frameCount = WebPDemuxGetI(demuxer, WEBP_FF_FRAME_COUNT);
    if (frameCount == 0) {
        goto fail;
        
    } else if (frameCount == 1) { // single-frame
        payload = data.bytes;
        payloadSize = data.size;
        if (!WebPInitDecoderConfig(&config)) goto fail;
        if (WebPGetFeatures(payload , payloadSize, &config.input) != VP8_STATUS_OK) goto fail;
        canvasWidth = config.input.width;
        canvasHeight = config.input.height;
        
    } else { // multi-frame
        canvasWidth = WebPDemuxGetI(demuxer, WEBP_FF_CANVAS_WIDTH);
        canvasHeight = WebPDemuxGetI(demuxer, WEBP_FF_CANVAS_HEIGHT);
        if (canvasWidth < 1 || canvasHeight < 1) goto fail;
        
        if (!WebPDemuxGetFrame(demuxer, 1, &iter)) goto fail;
        iterInited = YES;
        
        if (iter.width > canvasWidth || iter.height > canvasHeight) goto fail;
        payload = iter.fragment.bytes;
        payloadSize = iter.fragment.size;
        
        if (!WebPInitDecoderConfig(&config)) goto fail;
        if (WebPGetFeatures(payload , payloadSize, &config.input) != VP8_STATUS_OK) goto fail;
    }
    if (payload == NULL || payloadSize == 0) goto fail;
    
    hasAlpha = config.input.has_alpha;
    bitsPerComponent = 8;
    bitsPerPixel = 32;
    bytesPerRow = YYImageByteAlign(bitsPerPixel / 8 * canvasWidth, 32);
    destLength = bytesPerRow * canvasHeight;
    if (decodeForDisplay) {
        bitmapInfo = kCGBitmapByteOrder32Host;
        bitmapInfo |= hasAlpha ? kCGImageAlphaPremultipliedFirst : kCGImageAlphaNoneSkipFirst;
        colorspace = MODE_bgrA; // small endian
    } else {
        bitmapInfo = kCGBitmapByteOrderDefault;
        bitmapInfo |= hasAlpha ? kCGImageAlphaLast : kCGImageAlphaNoneSkipLast;
        colorspace = MODE_RGBA;
    }
    destBytes = calloc(1, destLength);
    if (!destBytes) goto fail;
    
    config.options.use_threads = useThreads; //speed up 23%
    config.options.bypass_filtering = bypassFiltering; //speed up 11%, cause some banding
    config.options.no_fancy_upsampling = noFancyUpsampling; //speed down 16%, lose some details
    config.output.colorspace = colorspace;
    config.output.is_external_memory = 1;
    config.output.u.RGBA.rgba = destBytes;
    config.output.u.RGBA.stride = (int)bytesPerRow;
    config.output.u.RGBA.size = destLength;
    
    VP8StatusCode result = WebPDecode(payload, payloadSize, &config);
    if ((result != VP8_STATUS_OK) && (result != VP8_STATUS_NOT_ENOUGH_DATA)) goto fail;
    
    if (iter.x_offset != 0 || iter.y_offset != 0) {
        void *tmp = calloc(1, destLength);
        if (tmp) {
            vImage_Buffer src = {destBytes, canvasHeight, canvasWidth, bytesPerRow};
            vImage_Buffer dest = {tmp, canvasHeight, canvasWidth, bytesPerRow};
            vImage_CGAffineTransform transform = {1, 0, 0, 1, iter.x_offset, -iter.y_offset};
            uint8_t backColor[4] = {0};
            vImageAffineWarpCG_ARGB8888(&src, &dest, NULL, &transform, backColor, kvImageBackgroundColorFill);
            memcpy(destBytes, tmp, destLength);
            free(tmp);
        }
    }
    
    provider = CGDataProviderCreateWithData(destBytes, destBytes, destLength, YYCGDataProviderReleaseDataCallback);
    if (!provider) goto fail;
    destBytes = NULL; // hold by provider
    
    imageRef = CGImageCreate(canvasWidth, canvasHeight, bitsPerComponent, bitsPerPixel, bytesPerRow, YYCGColorSpaceGetDeviceRGB(), bitmapInfo, provider, NULL, false, kCGRenderingIntentDefault);
    
    CFRelease(provider);
    if (iterInited) WebPDemuxReleaseIterator(&iter);
    WebPDemuxDelete(demuxer);
    
    return imageRef;
    
fail:
    if (destBytes) free(destBytes);
    if (provider) CFRelease(provider);
    if (iterInited) WebPDemuxReleaseIterator(&iter);
    if (demuxer) WebPDemuxDelete(demuxer);
    return NULL;
}

#else

BOOL YYImageWebPAvailable() {
    return NO;
}

CFDataRef YYCGImageCreateEncodedWebPData(CGImageRef imageRef, BOOL lossless, CGFloat quality, int compressLevel, YYImagePreset preset) {
    NSLog(@"WebP decoder is disabled");
    return NULL;
}

NSUInteger YYImageGetWebPFrameCount(CFDataRef webpData) {
    NSLog(@"WebP decoder is disabled");
    return 0;
}

CGImageRef YYCGImageCreateWithWebPData(CFDataRef webpData,
                                       BOOL decodeForDisplay,
                                       BOOL useThreads,
                                       BOOL bypassFiltering,
                                       BOOL noFancyUpsampling) {
    NSLog(@"WebP decoder is disabled");
    return NULL;
}

#endif


////////////////////////////////////////////////////////////////////////////////
#pragma mark - Decoder

@implementation YYImageFrame
+ (instancetype)frameWithImage:(UIImage *)image {
    YYImageFrame *frame = [self new];
    frame.image = image;
    return frame;
}
- (id)copyWithZone:(NSZone *)zone {
    YYImageFrame *frame = [self.class new];
    frame.index = _index;
    frame.width = _width;
    frame.height = _height;
    frame.offsetX = _offsetX;
    frame.offsetY = _offsetY;
    frame.duration = _duration;
    frame.dispose = _dispose;
    frame.blend = _blend;
    frame.image = _image.copy;
    return frame;
}
@end

// Internal frame object.
@interface _YYImageDecoderFrame : YYImageFrame
@property (nonatomic, assign) BOOL hasAlpha;                ///< Whether frame has alpha.
@property (nonatomic, assign) BOOL isFullSize;              ///< Whether frame fill the canvas.
@property (nonatomic, assign) NSUInteger blendFromIndex;    ///< Blend from frame index to current frame.
@end

@implementation _YYImageDecoderFrame
- (id)copyWithZone:(NSZone *)zone {
    _YYImageDecoderFrame *frame = [super copyWithZone:zone];
    frame.hasAlpha = _hasAlpha;
    frame.isFullSize = _isFullSize;
    frame.blendFromIndex = _blendFromIndex;
    return frame;
}
@end


@implementation YYImageDecoder {
    // 递归锁
    pthread_mutex_t _lock; // recursive lock
    
    // 是否知道源数据的类型
    BOOL _sourceTypeDetected;
    // 源图片
    CGImageSourceRef _source;
    // png信息
    yy_png_info *_apngSource;
#if YYIMAGE_WEBP_ENABLED
    WebPDemuxer *_webpSource;
#endif
    
    // 图片方向
    UIImageOrientation _orientation;
    // 帧锁
    dispatch_semaphore_t _framesLock;
    // 🤔️
    NSArray *_frames; ///< Array<GGImageDecoderFrame>, without image
    // 是否需要混合
    BOOL _needBlend;
    // 混合帧的索引
    NSUInteger _blendFrameIndex;
    // 混合的画布
    CGContextRef _blendCanvas;
}

- (void)dealloc {
    if (_source) CFRelease(_source);
    if (_apngSource) yy_png_info_release(_apngSource);
#if YYIMAGE_WEBP_ENABLED
    if (_webpSource) WebPDemuxDelete(_webpSource);
#endif
    if (_blendCanvas) CFRelease(_blendCanvas);
    pthread_mutex_destroy(&_lock);
}

// 根据data生成解压器
+ (instancetype)decoderWithData:(NSData *)data scale:(CGFloat)scale {
    if (!data) return nil;
    YYImageDecoder *decoder = [[YYImageDecoder alloc] initWithScale:scale];
    [decoder updateData:data final:YES];
    if (decoder.frameCount == 0) return nil;
    return decoder;
}

- (instancetype)init {
    return [self initWithScale:[UIScreen mainScreen].scale];
}

// 根据比例初始化解压器
- (instancetype)initWithScale:(CGFloat)scale {
    self = [super init];
    if (scale <= 0) scale = 1;
    _scale = scale;
    _framesLock = dispatch_semaphore_create(1);
    // 创建递归锁
    // @note 递归锁：允许在同一个线程对同一个锁获取多次，并通过对应次数的Unlock解锁，在未完全解锁的时候其他线程的请求在等待状态
    //             当锁全部解除后，会根据线程优先级重新获取锁
    pthread_mutex_init_recursive(&_lock, true);
    return self;
}

// 更新数据
- (BOOL)updateData:(NSData *)data final:(BOOL)final {
    // 线程安全的更新数据
    BOOL result = NO;
    pthread_mutex_lock(&_lock);
    result = [self _updateData:data final:final];
    pthread_mutex_unlock(&_lock);
    return result;
}

// 获取指定索引的帧
- (YYImageFrame *)frameAtIndex:(NSUInteger)index decodeForDisplay:(BOOL)decodeForDisplay {
    YYImageFrame *result = nil;
    pthread_mutex_lock(&_lock);
    result = [self _frameAtIndex:index decodeForDisplay:decodeForDisplay];
    pthread_mutex_unlock(&_lock);
    return result;
}

// 获取指定索引的帧持续时间
- (NSTimeInterval)frameDurationAtIndex:(NSUInteger)index {
    NSTimeInterval result = 0;
    dispatch_semaphore_wait(_framesLock, DISPATCH_TIME_FOREVER);
    if (index < _frames.count) {
        result = ((_YYImageDecoderFrame *)_frames[index]).duration;
    }
    dispatch_semaphore_signal(_framesLock);
    return result;
}

// 获取指定帧的属性
- (NSDictionary *)framePropertiesAtIndex:(NSUInteger)index {
    NSDictionary *result = nil;
    pthread_mutex_lock(&_lock);
    result = [self _framePropertiesAtIndex:index];
    pthread_mutex_unlock(&_lock);
    return result;
}

// 获取图片的属性
- (NSDictionary *)imageProperties {
    NSDictionary *result = nil;
    pthread_mutex_lock(&_lock);
    result = [self _imageProperties];
    pthread_mutex_unlock(&_lock);
    return result;
}

#pragma private (wrap)
// 更新解压器的数据
- (BOOL)_updateData:(NSData *)data final:(BOOL)final {
    // 如果已经完成或者新数据的长度比老数据的长度小返回失败
    if (_finalized) return NO;
    if (data.length < _data.length) return NO;
    // 实力变量赋值
    _finalized = final;
    _data = data;
    
    // 获取图片类型
    YYImageType type = YYImageDetectType((__bridge CFDataRef)data);
    // 判断是不是已经获取到了图片类型，如果没有对实力变量赋值，更新数据，如过已经赋值了判断是否更新
    if (_sourceTypeDetected) {
        if (_type != type) {
            return NO;
        } else {
            [self _updateSource];
        }
    } else {
        if (_data.length > 16) {
            _type = type;
            _sourceTypeDetected = YES;
            [self _updateSource];
        }
    }
    return YES;
}

// 获取指定索引的帧
- (YYImageFrame *)_frameAtIndex:(NSUInteger)index decodeForDisplay:(BOOL)decodeForDisplay {
    // 是否超出范围
    if (index >= _frames.count) return 0;
    // 获取当前帧的copy
    _YYImageDecoderFrame *frame = [(_YYImageDecoderFrame *)_frames[index] copy];
    // 是否解压了
    BOOL decoded = NO;
    // 是否在画布展开
    BOOL extendToCanvas = NO;
    
    // ICO格式的图片各帧的大小可能不一样，不在画布展开
    if (_type != YYImageTypeICO && decodeForDisplay) { // ICO contains multi-size frame and should not extend to canvas.
        extendToCanvas = YES;
    }
    
    // 不需要混合
    if (!_needBlend) {
        // 获取不混合的图像
        CGImageRef imageRef = [self _newUnblendedImageAtIndex:index extendToCanvas:extendToCanvas decoded:&decoded];
        if (!imageRef) return nil;
        // 如果需要解压显示而且生成图片的时候没有解压，解压图像
        if (decodeForDisplay && !decoded) {
            CGImageRef imageRefDecoded = YYCGImageCreateDecodedCopy(imageRef, YES);
            if (imageRefDecoded) {
                CFRelease(imageRef);
                imageRef = imageRefDecoded;
                decoded = YES;
            }
        }
        // 生成image图像
        UIImage *image = [UIImage imageWithCGImage:imageRef scale:_scale orientation:_orientation];
        CFRelease(imageRef);
        if (!image) return nil;
        // 设置图像是否解压了
        image.isDecodedForDisplay = decoded;
        frame.image = image;
        return frame;
    }
    
    // blend
    // 创建混合的画布
    if (![self _createBlendContextIfNeeded]) return nil;
    CGImageRef imageRef = NULL;
    
    // 如果上一帧绘制好了，绘制这一帧
    if (_blendFrameIndex + 1 == frame.index) {
        imageRef = [self _newBlendedImageWithFrame:frame];
        _blendFrameIndex = index;
    } else { // should draw canvas from previous frame
        // 如果上一帧的索引找不到，清空画布
        _blendFrameIndex = NSNotFound;
        CGContextClearRect(_blendCanvas, CGRectMake(0, 0, _width, _height));
        
        // 如果帧开始渲染的索引和当前的索引相同，则直接绘制到画布上，并且根据disopose决定是否清空画布
        if (frame.blendFromIndex == frame.index) {
            CGImageRef unblendedImage = [self _newUnblendedImageAtIndex:index extendToCanvas:NO decoded:NULL];
            if (unblendedImage) {
                CGContextDrawImage(_blendCanvas, CGRectMake(frame.offsetX, frame.offsetY, frame.width, frame.height), unblendedImage);
                CFRelease(unblendedImage);
            }
            imageRef = CGBitmapContextCreateImage(_blendCanvas);
            if (frame.dispose == YYImageDisposeBackground) {
                CGContextClearRect(_blendCanvas, CGRectMake(frame.offsetX, frame.offsetY, frame.width, frame.height));
            }
            _blendFrameIndex = index;
        }
        // 🤔️
        else { // canvas is not ready
            for (uint32_t i = (uint32_t)frame.blendFromIndex; i <= (uint32_t)frame.index; i++) {
                if (i == frame.index) {
                    if (!imageRef) imageRef = [self _newBlendedImageWithFrame:frame];
                } else {
                    [self _blendImageWithFrame:_frames[i]];
                }
            }
            _blendFrameIndex = index;
        }
    }
    
    // 生成UIImage对象和_YYImageDecoderFrame对象
    if (!imageRef) return nil;
    UIImage *image = [UIImage imageWithCGImage:imageRef scale:_scale orientation:_orientation];
    CFRelease(imageRef);
    if (!image) return nil;
    
    image.isDecodedForDisplay = YES;
    frame.image = image;
    if (extendToCanvas) {
        frame.width = _width;
        frame.height = _height;
        frame.offsetX = 0;
        frame.offsetY = 0;
        frame.dispose = YYImageDisposeNone;
        frame.blend = YYImageBlendNone;
    }
    return frame;
}

// 获取指定帧的属性
- (NSDictionary *)_framePropertiesAtIndex:(NSUInteger)index {
    if (index >= _frames.count) return nil;
    if (!_source) return nil;
    CFDictionaryRef properties = CGImageSourceCopyPropertiesAtIndex(_source, index, NULL);
    if (!properties) return nil;
    return CFBridgingRelease(properties);
}
// 获取图像的属性
- (NSDictionary *)_imageProperties {
    if (!_source) return nil;
    CFDictionaryRef properties = CGImageSourceCopyProperties(_source, NULL);
    if (!properties) return nil;
    return CFBridgingRelease(properties);
}

#pragma private
// 更新数据源
- (void)_updateSource {
    switch (_type) {
        case YYImageTypeWebP: {
            [self _updateSourceWebP];
        } break;
            
        case YYImageTypePNG: {
            [self _updateSourceAPNG];
        } break;
            
        default: {
            [self _updateSourceImageIO];
        } break;
    }
}

- (void)_updateSourceWebP {
#if YYIMAGE_WEBP_ENABLED
    _width = 0;
    _height = 0;
    _loopCount = 0;
    if (_webpSource) WebPDemuxDelete(_webpSource);
    _webpSource = NULL;
    dispatch_semaphore_wait(_framesLock, DISPATCH_TIME_FOREVER);
    _frames = nil;
    dispatch_semaphore_signal(_framesLock);
    
    /*
     https://developers.google.com/speed/webp/docs/api
     The documentation said we can use WebPIDecoder to decode webp progressively, 
     but currently it can only returns an empty image (not same as progressive jpegs),
     so we don't use progressive decoding.
     
     When using WebPDecode() to decode multi-frame webp, we will get the error
     "VP8_STATUS_UNSUPPORTED_FEATURE", so we first use WebPDemuxer to unpack it.
     */
    
    WebPData webPData = {0};
    webPData.bytes = _data.bytes;
    webPData.size = _data.length;
    WebPDemuxer *demuxer = WebPDemux(&webPData);
    if (!demuxer) return;
    
    uint32_t webpFrameCount = WebPDemuxGetI(demuxer, WEBP_FF_FRAME_COUNT);
    uint32_t webpLoopCount =  WebPDemuxGetI(demuxer, WEBP_FF_LOOP_COUNT);
    uint32_t canvasWidth = WebPDemuxGetI(demuxer, WEBP_FF_CANVAS_WIDTH);
    uint32_t canvasHeight = WebPDemuxGetI(demuxer, WEBP_FF_CANVAS_HEIGHT);
    if (webpFrameCount == 0 || canvasWidth < 1 || canvasHeight < 1) {
        WebPDemuxDelete(demuxer);
        return;
    }
    
    NSMutableArray *frames = [NSMutableArray new];
    BOOL needBlend = NO;
    uint32_t iterIndex = 0;
    uint32_t lastBlendIndex = 0;
    WebPIterator iter = {0};
    if (WebPDemuxGetFrame(demuxer, 1, &iter)) { // one-based index...
        do {
            _YYImageDecoderFrame *frame = [_YYImageDecoderFrame new];
            [frames addObject:frame];
            if (iter.dispose_method == WEBP_MUX_DISPOSE_BACKGROUND) {
                frame.dispose = YYImageDisposeBackground;
            }
            if (iter.blend_method == WEBP_MUX_BLEND) {
                frame.blend = YYImageBlendOver;
            }
            
            int canvasWidth = WebPDemuxGetI(demuxer, WEBP_FF_CANVAS_WIDTH);
            int canvasHeight = WebPDemuxGetI(demuxer, WEBP_FF_CANVAS_HEIGHT);
            frame.index = iterIndex;
            frame.duration = iter.duration / 1000.0;
            frame.width = iter.width;
            frame.height = iter.height;
            frame.hasAlpha = iter.has_alpha;
            frame.blend = iter.blend_method == WEBP_MUX_BLEND;
            frame.offsetX = iter.x_offset;
            frame.offsetY = canvasHeight - iter.y_offset - iter.height;
            
            BOOL sizeEqualsToCanvas = (iter.width == canvasWidth && iter.height == canvasHeight);
            BOOL offsetIsZero = (iter.x_offset == 0 && iter.y_offset == 0);
            frame.isFullSize = (sizeEqualsToCanvas && offsetIsZero);
            
            if ((!frame.blend || !frame.hasAlpha) && frame.isFullSize) {
                frame.blendFromIndex = lastBlendIndex = iterIndex;
            } else {
                if (frame.dispose && frame.isFullSize) {
                    frame.blendFromIndex = lastBlendIndex;
                    lastBlendIndex = iterIndex + 1;
                } else {
                    frame.blendFromIndex = lastBlendIndex;
                }
            }
            if (frame.index != frame.blendFromIndex) needBlend = YES;
            iterIndex++;
        } while (WebPDemuxNextFrame(&iter));
        WebPDemuxReleaseIterator(&iter);
    }
    if (frames.count != webpFrameCount) {
        WebPDemuxDelete(demuxer);
        return;
    }
    
    _width = canvasWidth;
    _height = canvasHeight;
    _frameCount = frames.count;
    _loopCount = webpLoopCount;
    _needBlend = needBlend;
    _webpSource = demuxer;
    dispatch_semaphore_wait(_framesLock, DISPATCH_TIME_FOREVER);
    _frames = frames;
    dispatch_semaphore_signal(_framesLock);
#else
    static const char *func = __FUNCTION__;
    static const int line = __LINE__;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSLog(@"[%s: %d] WebP is not available, check the documentation to see how to install WebP component: https://github.com/ibireme/YYImage#installation", func, line);
    });
#endif
}

- (void)_updateSourceAPNG {
    /*
     APNG extends PNG format to support animation, it was supported by ImageIO
     since iOS 8.
     
     We use a custom APNG decoder to make APNG available in old system, so we
     ignore the ImageIO's APNG frame info. Typically the custom decoder is a bit
     faster than ImageIO.
     */
    
    yy_png_info_release(_apngSource);
    _apngSource = nil;
    
    [self _updateSourceImageIO]; // decode first frame
    if (_frameCount == 0) return; // png decode failed
    if (!_finalized) return; // ignore multi-frame before finalized
    
    yy_png_info *apng = yy_png_info_create(_data.bytes, (uint32_t)_data.length);
    if (!apng) return; // apng decode failed
    if (apng->apng_frame_num == 0 ||
        (apng->apng_frame_num == 1 && apng->apng_first_frame_is_cover)) {
        yy_png_info_release(apng);
        return; // no animation
    }
    if (_source) { // apng decode succeed, no longer need image souce
        CFRelease(_source);
        _source = NULL;
    }
    
    uint32_t canvasWidth = apng->header.width;
    uint32_t canvasHeight = apng->header.height;
    NSMutableArray *frames = [NSMutableArray new];
    BOOL needBlend = NO;
    uint32_t lastBlendIndex = 0;
    for (uint32_t i = 0; i < apng->apng_frame_num; i++) {
        _YYImageDecoderFrame *frame = [_YYImageDecoderFrame new];
        [frames addObject:frame];
        
        yy_png_frame_info *fi = apng->apng_frames + i;
        frame.index = i;
        frame.duration = yy_png_delay_to_seconds(fi->frame_control.delay_num, fi->frame_control.delay_den);
        frame.hasAlpha = YES;
        frame.width = fi->frame_control.width;
        frame.height = fi->frame_control.height;
        frame.offsetX = fi->frame_control.x_offset;
        frame.offsetY = canvasHeight - fi->frame_control.y_offset - fi->frame_control.height;
        
        BOOL sizeEqualsToCanvas = (frame.width == canvasWidth && frame.height == canvasHeight);
        BOOL offsetIsZero = (fi->frame_control.x_offset == 0 && fi->frame_control.y_offset == 0);
        frame.isFullSize = (sizeEqualsToCanvas && offsetIsZero);
        
        switch (fi->frame_control.dispose_op) {
            case YY_PNG_DISPOSE_OP_BACKGROUND: {
                frame.dispose = YYImageDisposeBackground;
            } break;
            case YY_PNG_DISPOSE_OP_PREVIOUS: {
                frame.dispose = YYImageDisposePrevious;
            } break;
            default: {
                frame.dispose = YYImageDisposeNone;
            } break;
        }
        switch (fi->frame_control.blend_op) {
            case YY_PNG_BLEND_OP_OVER: {
                frame.blend = YYImageBlendOver;
            } break;
                
            default: {
                frame.blend = YYImageBlendNone;
            } break;
        }
        
        if (frame.blend == YYImageBlendNone && frame.isFullSize) {
            frame.blendFromIndex  = i;
            if (frame.dispose != YYImageDisposePrevious) lastBlendIndex = i;
        } else {
            if (frame.dispose == YYImageDisposeBackground && frame.isFullSize) {
                frame.blendFromIndex = lastBlendIndex;
                lastBlendIndex = i + 1;
            } else {
                frame.blendFromIndex = lastBlendIndex;
            }
        }
        if (frame.index != frame.blendFromIndex) needBlend = YES;
    }
    
    _width = canvasWidth;
    _height = canvasHeight;
    _frameCount = frames.count;
    _loopCount = apng->apng_loop_num;
    _needBlend = needBlend;
    _apngSource = apng;
    dispatch_semaphore_wait(_framesLock, DISPATCH_TIME_FOREVER);
    _frames = frames;
    dispatch_semaphore_signal(_framesLock);
}

// 通过imageIO更新数据
- (void)_updateSourceImageIO {
    // 初始化数据
    _width = 0;
    _height = 0;
    _orientation = UIImageOrientationUp;
    _loopCount = 0;
    dispatch_semaphore_wait(_framesLock, DISPATCH_TIME_FOREVER);
    _frames = nil;
    dispatch_semaphore_signal(_framesLock);
    
    // 如果不存在_source根据是否是完整图片数据创建或者更新源图片数据
    // 如果存在_source 更新_source
    if (!_source) {
        if (_finalized) {
            _source = CGImageSourceCreateWithData((__bridge CFDataRef)_data, NULL);
        } else {
            _source = CGImageSourceCreateIncremental(NULL);
            if (_source) CGImageSourceUpdateData(_source, (__bridge CFDataRef)_data, false);
        }
    } else {
        CGImageSourceUpdateData(_source, (__bridge CFDataRef)_data, _finalized);
    }
    if (!_source) return;
    
    // 获取帧数
    _frameCount = CGImageSourceGetCount(_source);
    if (_frameCount == 0) return;
    
    // 在数据不完整的时候忽略多帧
    if (!_finalized) { // ignore multi-frame before finalized
        _frameCount = 1;
    } else {
        // PNG只有一帧
        if (_type == YYImageTypePNG) { // use custom apng decoder and ignore multi-frame
            _frameCount = 1;
        }
        // 如果是GIF图片获取循环次数
        if (_type == YYImageTypeGIF) { // get gif loop count
            // 获取_source的属性
            CFDictionaryRef properties = CGImageSourceCopyProperties(_source, NULL);
            if (properties) {
                // 获取GIF属性
                CFDictionaryRef gif = CFDictionaryGetValue(properties, kCGImagePropertyGIFDictionary);
                if (gif) {
                    // 获取循环次数
                    CFTypeRef loop = CFDictionaryGetValue(gif, kCGImagePropertyGIFLoopCount);
                    if (loop) CFNumberGetValue(loop, kCFNumberNSIntegerType, &_loopCount);
                }
                CFRelease(properties);
            }
        }
    }
    
    /*
     ICO, GIF, APNG may contains multi-frame.
     处理多帧图片
     */
    NSMutableArray *frames = [NSMutableArray new];
    for (NSUInteger i = 0; i < _frameCount; i++) {
        // 生成_YYImageDecoderFrame对象
        _YYImageDecoderFrame *frame = [_YYImageDecoderFrame new];
        frame.index = i;
        frame.blendFromIndex = i;
        frame.hasAlpha = YES;
        frame.isFullSize = YES;
        [frames addObject:frame];
        
        // 获取_source属性
        CFDictionaryRef properties = CGImageSourceCopyPropertiesAtIndex(_source, i, NULL);
        if (properties) {
            // 声明一些相关的属性变量
            NSTimeInterval duration = 0;
            NSInteger orientationValue = 0, width = 0, height = 0;
            CFTypeRef value = NULL;
            
            // 获取宽度（像素）
            value = CFDictionaryGetValue(properties, kCGImagePropertyPixelWidth);
            if (value) CFNumberGetValue(value, kCFNumberNSIntegerType, &width);
            // 获取高度（像素）
            value = CFDictionaryGetValue(properties, kCGImagePropertyPixelHeight);
            if (value) CFNumberGetValue(value, kCFNumberNSIntegerType, &height);
            
            // 如果是GIF图片，获取帧持续时间
            if (_type == YYImageTypeGIF) {
                CFDictionaryRef gif = CFDictionaryGetValue(properties, kCGImagePropertyGIFDictionary);
                if (gif) {
                    // Use the unclamped frame delay if it exists.
                    value = CFDictionaryGetValue(gif, kCGImagePropertyGIFUnclampedDelayTime);
                    if (!value) {
                        // Fall back to the clamped frame delay if the unclamped frame delay does not exist.
                        value = CFDictionaryGetValue(gif, kCGImagePropertyGIFDelayTime);
                    }
                    if (value) CFNumberGetValue(value, kCFNumberDoubleType, &duration);
                }
            }
            
            frame.width = width;
            frame.height = height;
            frame.duration = duration;
            
            // 如果画布大小没有赋值给画布大小赋值
            if (i == 0 && _width + _height == 0) { // init first frame
                _width = width;
                _height = height;
                value = CFDictionaryGetValue(properties, kCGImagePropertyOrientation);
                if (value) {
                    CFNumberGetValue(value, kCFNumberNSIntegerType, &orientationValue);
                    _orientation = YYUIImageOrientationFromEXIFValue(orientationValue);
                }
            }
            CFRelease(properties);
        }
    }
    // 帧锁
    dispatch_semaphore_wait(_framesLock, DISPATCH_TIME_FOREVER);
    _frames = frames;
    dispatch_semaphore_signal(_framesLock);
}

// 获取不展开的帧图像
- (CGImageRef)_newUnblendedImageAtIndex:(NSUInteger)index
                         extendToCanvas:(BOOL)extendToCanvas
                                decoded:(BOOL *)decoded CF_RETURNS_RETAINED {
    // 如果没有完成返回NULL
    if (!_finalized && index > 0) return NULL;
    if (_frames.count <= index) return NULL;
    // 获取要处理的帧
    _YYImageDecoderFrame *frame = _frames[index];
    
    // 如果有_source根据_source生成图像
    if (_source) {
        CGImageRef imageRef = CGImageSourceCreateImageAtIndex(_source, index, (CFDictionaryRef)@{(id)kCGImageSourceShouldCache:@(YES)});
        
        // 如果需要展开到画布
        if (imageRef && extendToCanvas) {
            // 获取图像大小
            size_t width = CGImageGetWidth(imageRef);
            size_t height = CGImageGetHeight(imageRef);
            // 如果画布大小与图像大小相同，解压图像
            if (width == _width && height == _height) {
                CGImageRef imageRefExtended = YYCGImageCreateDecodedCopy(imageRef, YES);
                if (imageRefExtended) {
                    CFRelease(imageRef);
                    imageRef = imageRefExtended;
                    if (decoded) *decoded = YES;
                }
            } else {
                // 生成上下文，并将在上下文解压图像
                CGContextRef context = CGBitmapContextCreate(NULL, _width, _height, 8, 0, YYCGColorSpaceGetDeviceRGB(), kCGBitmapByteOrder32Host | kCGImageAlphaPremultipliedFirst);
                if (context) {
                    CGContextDrawImage(context, CGRectMake(0, _height - height, width, height), imageRef);
                    CGImageRef imageRefExtended = CGBitmapContextCreateImage(context);
                    CFRelease(context);
                    if (imageRefExtended) {
                        CFRelease(imageRef);
                        imageRef = imageRefExtended;
                        if (decoded) *decoded = YES;
                    }
                }
            }
        }
        return imageRef;
    }
    
    // 如果是apng类型的source
    if (_apngSource) {
        uint32_t size = 0;
        uint8_t *bytes = yy_png_copy_frame_data_at_index(_data.bytes, _apngSource, (uint32_t)index, &size);
        if (!bytes) return NULL;
        CGDataProviderRef provider = CGDataProviderCreateWithData(bytes, bytes, size, YYCGDataProviderReleaseDataCallback);
        if (!provider) {
            free(bytes);
            return NULL;
        }
        bytes = NULL; // hold by provider
        
        CGImageSourceRef source = CGImageSourceCreateWithDataProvider(provider, NULL);
        if (!source) {
            CFRelease(provider);
            return NULL;
        }
        CFRelease(provider);
        
        if(CGImageSourceGetCount(source) < 1) {
            CFRelease(source);
            return NULL;
        }
        
        CGImageRef imageRef = CGImageSourceCreateImageAtIndex(source, 0, (CFDictionaryRef)@{(id)kCGImageSourceShouldCache:@(YES)});
        CFRelease(source);
        if (!imageRef) return NULL;
        if (extendToCanvas) {
            CGContextRef context = CGBitmapContextCreate(NULL, _width, _height, 8, 0, YYCGColorSpaceGetDeviceRGB(), kCGBitmapByteOrder32Host | kCGImageAlphaPremultipliedFirst); //bgrA
            if (context) {
                CGContextDrawImage(context, CGRectMake(frame.offsetX, frame.offsetY, frame.width, frame.height), imageRef);
                CFRelease(imageRef);
                imageRef = CGBitmapContextCreateImage(context);
                CFRelease(context);
                if (decoded) *decoded = YES;
            }
        }
        return imageRef;
    }
    
#if YYIMAGE_WEBP_ENABLED
    if (_webpSource) {
        WebPIterator iter;
        if (!WebPDemuxGetFrame(_webpSource, (int)(index + 1), &iter)) return NULL; // demux webp frame data
        // frame numbers are one-based in webp -----------^
        
        int frameWidth = iter.width;
        int frameHeight = iter.height;
        if (frameWidth < 1 || frameHeight < 1) return NULL;
        
        int width = extendToCanvas ? (int)_width : frameWidth;
        int height = extendToCanvas ? (int)_height : frameHeight;
        if (width > _width || height > _height) return NULL;
        
        const uint8_t *payload = iter.fragment.bytes;
        size_t payloadSize = iter.fragment.size;
        
        WebPDecoderConfig config;
        if (!WebPInitDecoderConfig(&config)) {
            WebPDemuxReleaseIterator(&iter);
            return NULL;
        }
        if (WebPGetFeatures(payload , payloadSize, &config.input) != VP8_STATUS_OK) {
            WebPDemuxReleaseIterator(&iter);
            return NULL;
        }
        
        size_t bitsPerComponent = 8;
        size_t bitsPerPixel = 32;
        size_t bytesPerRow = YYImageByteAlign(bitsPerPixel / 8 * width, 32);
        size_t length = bytesPerRow * height;
        CGBitmapInfo bitmapInfo = kCGBitmapByteOrder32Host | kCGImageAlphaPremultipliedFirst; //bgrA
        
        void *pixels = calloc(1, length);
        if (!pixels) {
            WebPDemuxReleaseIterator(&iter);
            return NULL;
        }
        
        config.output.colorspace = MODE_bgrA;
        config.output.is_external_memory = 1;
        config.output.u.RGBA.rgba = pixels;
        config.output.u.RGBA.stride = (int)bytesPerRow;
        config.output.u.RGBA.size = length;
        VP8StatusCode result = WebPDecode(payload, payloadSize, &config); // decode
        if ((result != VP8_STATUS_OK) && (result != VP8_STATUS_NOT_ENOUGH_DATA)) {
            WebPDemuxReleaseIterator(&iter);
            free(pixels);
            return NULL;
        }
        WebPDemuxReleaseIterator(&iter);
        
        if (extendToCanvas && (iter.x_offset != 0 || iter.y_offset != 0)) {
            void *tmp = calloc(1, length);
            if (tmp) {
                vImage_Buffer src = {pixels, height, width, bytesPerRow};
                vImage_Buffer dest = {tmp, height, width, bytesPerRow};
                vImage_CGAffineTransform transform = {1, 0, 0, 1, iter.x_offset, -iter.y_offset};
                uint8_t backColor[4] = {0};
                vImage_Error error = vImageAffineWarpCG_ARGB8888(&src, &dest, NULL, &transform, backColor, kvImageBackgroundColorFill);
                if (error == kvImageNoError) {
                    memcpy(pixels, tmp, length);
                }
                free(tmp);
            }
        }
        
        CGDataProviderRef provider = CGDataProviderCreateWithData(pixels, pixels, length, YYCGDataProviderReleaseDataCallback);
        if (!provider) {
            free(pixels);
            return NULL;
        }
        pixels = NULL; // hold by provider
        
        CGImageRef image = CGImageCreate(width, height, bitsPerComponent, bitsPerPixel, bytesPerRow, YYCGColorSpaceGetDeviceRGB(), bitmapInfo, provider, NULL, false, kCGRenderingIntentDefault);
        CFRelease(provider);
        if (decoded) *decoded = YES;
        return image;
    }
#endif
    
    return NULL;
}

// 创建混合的上下文
- (BOOL)_createBlendContextIfNeeded {
    if (!_blendCanvas) {
        _blendFrameIndex = NSNotFound;
        _blendCanvas = CGBitmapContextCreate(NULL, _width, _height, 8, 0, YYCGColorSpaceGetDeviceRGB(), kCGBitmapByteOrder32Host | kCGImageAlphaPremultipliedFirst);
    }
    BOOL suc = _blendCanvas != NULL;
    return suc;
}

// 混合帧
// @note 根据disopse类型和blend类型，决定是否清空画布
- (void)_blendImageWithFrame:(_YYImageDecoderFrame *)frame {
    if (frame.dispose == YYImageDisposePrevious) {
        // nothing
    } else if (frame.dispose == YYImageDisposeBackground) {
        CGContextClearRect(_blendCanvas, CGRectMake(frame.offsetX, frame.offsetY, frame.width, frame.height));
    } else { // no dispose
        if (frame.blend == YYImageBlendOver) {
            CGImageRef unblendImage = [self _newUnblendedImageAtIndex:frame.index extendToCanvas:NO decoded:NULL];
            if (unblendImage) {
                CGContextDrawImage(_blendCanvas, CGRectMake(frame.offsetX, frame.offsetY, frame.width, frame.height), unblendImage);
                CFRelease(unblendImage);
            }
        } else {
            CGContextClearRect(_blendCanvas, CGRectMake(frame.offsetX, frame.offsetY, frame.width, frame.height));
            CGImageRef unblendImage = [self _newUnblendedImageAtIndex:frame.index extendToCanvas:NO decoded:NULL];
            if (unblendImage) {
                CGContextDrawImage(_blendCanvas, CGRectMake(frame.offsetX, frame.offsetY, frame.width, frame.height), unblendImage);
                CFRelease(unblendImage);
            }
        }
    }
}

// 根据图像解压器帧生成图像
- (CGImageRef)_newBlendedImageWithFrame:(_YYImageDecoderFrame *)frame CF_RETURNS_RETAINED{
    CGImageRef imageRef = NULL;
    if (frame.dispose == YYImageDisposePrevious) {
        if (frame.blend == YYImageBlendOver) {
            // 获取当前画布上的图像
            CGImageRef previousImage = CGBitmapContextCreateImage(_blendCanvas);
            // 获取当前帧的图像
            CGImageRef unblendImage = [self _newUnblendedImageAtIndex:frame.index extendToCanvas:NO decoded:NULL];
            // 将当前帧的图像绘制到画布上
            if (unblendImage) {
                CGContextDrawImage(_blendCanvas, CGRectMake(frame.offsetX, frame.offsetY, frame.width, frame.height), unblendImage);
                CFRelease(unblendImage);
            }
            // 获取混合后的图像
            imageRef = CGBitmapContextCreateImage(_blendCanvas);
            // 将画板清空
            CGContextClearRect(_blendCanvas, CGRectMake(0, 0, _width, _height));
            // 再将原来的图像绘制到画板
            if (previousImage) {
                CGContextDrawImage(_blendCanvas, CGRectMake(0, 0, _width, _height), previousImage);
                CFRelease(previousImage);
            }
        } else {
            // 获取当前画布上的图像
            CGImageRef previousImage = CGBitmapContextCreateImage(_blendCanvas);
            // 获取当前帧的图像
            CGImageRef unblendImage = [self _newUnblendedImageAtIndex:frame.index extendToCanvas:NO decoded:NULL];
            // 清空画板，然后将当前帧的图像绘制到画板上
            if (unblendImage) {
                CGContextClearRect(_blendCanvas, CGRectMake(frame.offsetX, frame.offsetY, frame.width, frame.height));
                CGContextDrawImage(_blendCanvas, CGRectMake(frame.offsetX, frame.offsetY, frame.width, frame.height), unblendImage);
                CFRelease(unblendImage);
            }
            // 获取画板上的图像
            imageRef = CGBitmapContextCreateImage(_blendCanvas);
            // 清空画板的内容
            CGContextClearRect(_blendCanvas, CGRectMake(0, 0, _width, _height));
            // 将原来的图像绘制到画板上
            if (previousImage) {
                CGContextDrawImage(_blendCanvas, CGRectMake(0, 0, _width, _height), previousImage);
                CFRelease(previousImage);
            }
        }
    } else if (frame.dispose == YYImageDisposeBackground) {
        if (frame.blend == YYImageBlendOver) {
            // 获取当前帧的图像
            CGImageRef unblendImage = [self _newUnblendedImageAtIndex:frame.index extendToCanvas:NO decoded:NULL];
            // 将当前帧的图像绘制到画布
            if (unblendImage) {
                CGContextDrawImage(_blendCanvas, CGRectMake(frame.offsetX, frame.offsetY, frame.width, frame.height), unblendImage);
                CFRelease(unblendImage);
            }
            // 获取当前画布上的图像
            imageRef = CGBitmapContextCreateImage(_blendCanvas);
            // 清空画布
            CGContextClearRect(_blendCanvas, CGRectMake(frame.offsetX, frame.offsetY, frame.width, frame.height));
        } else {
            // 获取当前帧的图像
            CGImageRef unblendImage = [self _newUnblendedImageAtIndex:frame.index extendToCanvas:NO decoded:NULL];
            // 先清空画布在把图像绘制到画布上
            if (unblendImage) {
                CGContextClearRect(_blendCanvas, CGRectMake(frame.offsetX, frame.offsetY, frame.width, frame.height));
                CGContextDrawImage(_blendCanvas, CGRectMake(frame.offsetX, frame.offsetY, frame.width, frame.height), unblendImage);
                CFRelease(unblendImage);
            }
            // 获取画布上的图像
            imageRef = CGBitmapContextCreateImage(_blendCanvas);
            // 清空画布
            CGContextClearRect(_blendCanvas, CGRectMake(frame.offsetX, frame.offsetY, frame.width, frame.height));
        }
    } else { // no dispose
        if (frame.blend == YYImageBlendOver) {
            // 获取当前帧的图像
            CGImageRef unblendImage = [self _newUnblendedImageAtIndex:frame.index extendToCanvas:NO decoded:NULL];
            // 绘制当前帧的图像到画布
            if (unblendImage) {
                CGContextDrawImage(_blendCanvas, CGRectMake(frame.offsetX, frame.offsetY, frame.width, frame.height), unblendImage);
                CFRelease(unblendImage);
            }
            // 获取画布的图像
            imageRef = CGBitmapContextCreateImage(_blendCanvas);
        } else {
            // 获取当前帧的图像
            CGImageRef unblendImage = [self _newUnblendedImageAtIndex:frame.index extendToCanvas:NO decoded:NULL];
            // 先清理画布，然后把当前帧的图像绘制到画布
            if (unblendImage) {
                CGContextClearRect(_blendCanvas, CGRectMake(frame.offsetX, frame.offsetY, frame.width, frame.height));
                CGContextDrawImage(_blendCanvas, CGRectMake(frame.offsetX, frame.offsetY, frame.width, frame.height), unblendImage);
                CFRelease(unblendImage);
            }
            // 获取画布上的图像
            imageRef = CGBitmapContextCreateImage(_blendCanvas);
        }
    }
    return imageRef;
}

@end


////////////////////////////////////////////////////////////////////////////////
#pragma mark - Encoder

@implementation YYImageEncoder {
    NSMutableArray *_images;
    NSMutableArray *_durations;
}

// 不支持直接初始化，需要使用带类型的初始化方法
- (instancetype)init {
    @throw [NSException exceptionWithName:@"YYImageEncoder init error" reason:@"YYImageEncoder must be initialized with a type. Use 'initWithType:' instead." userInfo:nil];
    return [self initWithType:YYImageTypeUnknown];
}

- (instancetype)initWithType:(YYImageType)type {
    // 不支持位置类型的压缩
    if (type == YYImageTypeUnknown || type >= YYImageTypeOther) {
        NSLog(@"[%s: %d] Unsupported image type:%d",__FUNCTION__, __LINE__, (int)type);
        return nil;
    }
    
    // 不支持WebP类型的压缩
#if !YYIMAGE_WEBP_ENABLED
    if (type == YYImageTypeWebP) {
        NSLog(@"[%s: %d] WebP is not available, check the documentation to see how to install WebP component: https://github.com/ibireme/YYImage#installation", __FUNCTION__, __LINE__);
        return nil;
    }
#endif
    
    self = [super init];
    if (!self) return nil;
    _type = type;
    _images = [NSMutableArray new];
    _durations = [NSMutableArray new];

    switch (type) {
        case YYImageTypeJPEG:
        case YYImageTypeJPEG2000: {
            _quality = 0.9;
        } break;
        case YYImageTypeTIFF:
        case YYImageTypeBMP:
        case YYImageTypeGIF:
        case YYImageTypeICO:
        case YYImageTypeICNS:
        case YYImageTypePNG: {
            _quality = 1;
            _lossless = YES;
        } break;
        case YYImageTypeWebP: {
            _quality = 0.8;
        } break;
        default:
            break;
    }
    
    return self;
}

// 设置压缩质量
- (void)setQuality:(CGFloat)quality {
    _quality = quality < 0 ? 0 : quality > 1 ? 1 : quality;
}

// 根据UIImag添加图片
- (void)addImage:(UIImage *)image duration:(NSTimeInterval)duration {
    if (!image.CGImage) return;
    duration = duration < 0 ? 0 : duration;
    [_images addObject:image];
    [_durations addObject:@(duration)];
}

// 根据NSData添加图像
- (void)addImageWithData:(NSData *)data duration:(NSTimeInterval)duration {
    if (data.length == 0) return;
    duration = duration < 0 ? 0 : duration;
    [_images addObject:data];
    [_durations addObject:@(duration)];
}

// 根据图像路径添加图像
- (void)addImageWithFile:(NSString *)path duration:(NSTimeInterval)duration {
    if (path.length == 0) return;
    duration = duration < 0 ? 0 : duration;
    NSURL *url = [NSURL URLWithString:path];
    if (!url) return;
    [_images addObject:url];
    [_durations addObject:@(duration)];
}

// 是否支持imageIO解压
- (BOOL)_imageIOAvaliable {
    switch (_type) {
        case YYImageTypeJPEG:
        case YYImageTypeJPEG2000:
        case YYImageTypeTIFF:
        case YYImageTypeBMP:
        case YYImageTypeICO:
        case YYImageTypeICNS:
        case YYImageTypeGIF: {
            return _images.count > 0;
        } break;
        case YYImageTypePNG: {
            return _images.count == 1;
        } break;
        case YYImageTypeWebP: {
            return NO;
        } break;
        default: return NO;
    }
}

// 生成ImageDestination
- (CGImageDestinationRef)_newImageDestination:(id)dest imageCount:(NSUInteger)count CF_RETURNS_RETAINED {
    if (!dest) return nil;
    CGImageDestinationRef destination = NULL;
    if ([dest isKindOfClass:[NSString class]]) {
        NSURL *url = [[NSURL alloc] initFileURLWithPath:dest];
        if (url) {
            destination = CGImageDestinationCreateWithURL((CFURLRef)url, YYImageTypeToUTType(_type), count, NULL);
        }
    } else if ([dest isKindOfClass:[NSMutableData class]]) {
        destination = CGImageDestinationCreateWithData((CFMutableDataRef)dest, YYImageTypeToUTType(_type), count, NULL);
    }
    return destination;
}

// 压缩图像
- (void)_encodeImageWithDestination:(CGImageDestinationRef)destination imageCount:(NSUInteger)count {
    // 如果是GIF图像生成属性，并添加为destination的属性
    if (_type == YYImageTypeGIF) {
        NSDictionary *gifProperty = @{(__bridge id)kCGImagePropertyGIFDictionary:
                                        @{(__bridge id)kCGImagePropertyGIFLoopCount: @(_loopCount)}};
        CGImageDestinationSetProperties(destination, (__bridge CFDictionaryRef)gifProperty);
    }
    
    for (int i = 0; i < count; i++) {
        // 这里内存比较高，创建一个pool，及时释放内存
        @autoreleasepool {
            id imageSrc = _images[i];
            NSDictionary *frameProperty = NULL;
            // 如果是GIF图片，设置每帧持续时间，GIF不支持压缩
            // 其他图片设置压缩比
            if (_type == YYImageTypeGIF && count > 1) {
                frameProperty = @{(NSString *)kCGImagePropertyGIFDictionary : @{(NSString *) kCGImagePropertyGIFDelayTime:_durations[i]}};
            } else {
                frameProperty = @{(id)kCGImageDestinationLossyCompressionQuality : @(_quality)};
            }
            
            // 根据imageScr的类型进行对应的压缩处理
            if ([imageSrc isKindOfClass:[UIImage class]]) {
                UIImage *image = imageSrc;
                // 如果需要，调整图像方向
                if (image.imageOrientation != UIImageOrientationUp && image.CGImage) {
                    CGBitmapInfo info = CGImageGetBitmapInfo(image.CGImage) | CGImageGetAlphaInfo(image.CGImage);
                    CGImageRef rotated = YYCGImageCreateCopyWithOrientation(image.CGImage, image.imageOrientation, info);
                    if (rotated) {
                        image = [UIImage imageWithCGImage:rotated];
                        CFRelease(rotated);
                    }
                }
                // 添加到destination
                if (image.CGImage) CGImageDestinationAddImage(destination, ((UIImage *)imageSrc).CGImage, (CFDictionaryRef)frameProperty);
            } else if ([imageSrc isKindOfClass:[NSURL class]]) {
                // 根据source添加
                CGImageSourceRef source = CGImageSourceCreateWithURL((CFURLRef)imageSrc, NULL);
                if (source) {
                    CGImageDestinationAddImageFromSource(destination, source, 0, (CFDictionaryRef)frameProperty);
                    CFRelease(source);
                }
            } else if ([imageSrc isKindOfClass:[NSData class]]) {
                // 根据source添加
                CGImageSourceRef source = CGImageSourceCreateWithData((CFDataRef)imageSrc, NULL);
                if (source) {
                    CGImageDestinationAddImageFromSource(destination, source, 0, (CFDictionaryRef)frameProperty);
                    CFRelease(source);
                }
            }
        }
    }
}

// 获取指定帧的图像copy
- (CGImageRef)_newCGImageFromIndex:(NSUInteger)index decoded:(BOOL)decoded CF_RETURNS_RETAINED {
    UIImage *image = nil;
    id imageSrc= _images[index];
    // 根据数据源类型获取UIImage图像
    if ([imageSrc isKindOfClass:[UIImage class]]) {
        image = imageSrc;
    } else if ([imageSrc isKindOfClass:[NSURL class]]) {
        image = [UIImage imageWithContentsOfFile:((NSURL *)imageSrc).absoluteString];
    } else if ([imageSrc isKindOfClass:[NSData class]]) {
        image = [UIImage imageWithData:imageSrc];
    }
    if (!image) return NULL;
    // 对图像进行解压
    CGImageRef imageRef = image.CGImage;
    if (!imageRef) return NULL;
    if (image.imageOrientation != UIImageOrientationUp) {
        return YYCGImageCreateCopyWithOrientation(imageRef, image.imageOrientation, kCGBitmapByteOrder32Host | kCGImageAlphaPremultipliedFirst);
    }
    if (decoded) {
        return YYCGImageCreateDecodedCopy(imageRef, YES);
    }
    return (CGImageRef)CFRetain(imageRef);
}

// 编码图像
- (NSData *)_encodeWithImageIO {
    NSMutableData *data = [NSMutableData new];
    NSUInteger count = _type == YYImageTypeGIF ? _images.count : 1;
    CGImageDestinationRef destination = [self _newImageDestination:data imageCount:count];
    BOOL suc = NO;
    if (destination) {
        [self _encodeImageWithDestination:destination imageCount:count];
        suc = CGImageDestinationFinalize(destination);
        CFRelease(destination);
    }
    if (suc && data.length > 0) {
        return data;
    } else {
        return nil;
    }
}

// 根据图片路径使用imageIO压缩
- (BOOL)_encodeWithImageIO:(NSString *)path {
    NSUInteger count = _type == YYImageTypeGIF ? _images.count : 1;
    CGImageDestinationRef destination = [self _newImageDestination:path imageCount:count];
    BOOL suc = NO;
    if (destination) {
        [self _encodeImageWithDestination:destination imageCount:count];
        suc = CGImageDestinationFinalize(destination);
        CFRelease(destination);
    }
    return suc;
}

- (NSData *)_encodeAPNG {
    // encode APNG (ImageIO doesn't support APNG encoding, so we use a custom encoder)
    NSMutableArray *pngDatas = [NSMutableArray new];
    NSMutableArray *pngSizes = [NSMutableArray new];
    NSUInteger canvasWidth = 0, canvasHeight = 0;
    for (int i = 0; i < _images.count; i++) {
        CGImageRef decoded = [self _newCGImageFromIndex:i decoded:YES];
        if (!decoded) return nil;
        CGSize size = CGSizeMake(CGImageGetWidth(decoded), CGImageGetHeight(decoded));
        [pngSizes addObject:[NSValue valueWithCGSize:size]];
        if (canvasWidth < size.width) canvasWidth = size.width;
        if (canvasHeight < size.height) canvasHeight = size.height;
        CFDataRef frameData = YYCGImageCreateEncodedData(decoded, YYImageTypePNG, 1);
        CFRelease(decoded);
        if (!frameData) return nil;
        [pngDatas addObject:(__bridge id)(frameData)];
        CFRelease(frameData);
        if (size.width < 1 || size.height < 1) return nil;
    }
    CGSize firstFrameSize = [(NSValue *)[pngSizes firstObject] CGSizeValue];
    if (firstFrameSize.width < canvasWidth || firstFrameSize.height < canvasHeight) {
        CGImageRef decoded = [self _newCGImageFromIndex:0 decoded:YES];
        if (!decoded) return nil;
        CGContextRef context = CGBitmapContextCreate(NULL, canvasWidth, canvasHeight, 8,
                                                     0, YYCGColorSpaceGetDeviceRGB(), kCGBitmapByteOrder32Host | kCGImageAlphaPremultipliedFirst);
        if (!context) {
            CFRelease(decoded);
            return nil;
        }
        CGContextDrawImage(context, CGRectMake(0, canvasHeight - firstFrameSize.height, firstFrameSize.width, firstFrameSize.height), decoded);
        CFRelease(decoded);
        CGImageRef extendedImage = CGBitmapContextCreateImage(context);
        CFRelease(context);
        if (!extendedImage) return nil;
        CFDataRef frameData = YYCGImageCreateEncodedData(extendedImage, YYImageTypePNG, 1);
        if (!frameData) {
            CFRelease(extendedImage);
            return nil;
        }
        pngDatas[0] = (__bridge id)(frameData);
        CFRelease(frameData);
    }
    
    NSData *firstFrameData = pngDatas[0];
    yy_png_info *info = yy_png_info_create(firstFrameData.bytes, (uint32_t)firstFrameData.length);
    if (!info) return nil;
    NSMutableData *result = [NSMutableData new];
    BOOL insertBefore = NO, insertAfter = NO;
    uint32_t apngSequenceIndex = 0;
    
    uint32_t png_header[2];
    png_header[0] = YY_FOUR_CC(0x89, 0x50, 0x4E, 0x47);
    png_header[1] = YY_FOUR_CC(0x0D, 0x0A, 0x1A, 0x0A);
    
    [result appendBytes:png_header length:8];
    
    for (int i = 0; i < info->chunk_num; i++) {
        yy_png_chunk_info *chunk = info->chunks + i;
        
        if (!insertBefore && chunk->fourcc == YY_FOUR_CC('I', 'D', 'A', 'T')) {
            insertBefore = YES;
            // insert acTL (APNG Control)
            uint32_t acTL[5] = {0};
            acTL[0] = yy_swap_endian_uint32(8); //length
            acTL[1] = YY_FOUR_CC('a', 'c', 'T', 'L'); // fourcc
            acTL[2] = yy_swap_endian_uint32((uint32_t)pngDatas.count); // num frames
            acTL[3] = yy_swap_endian_uint32((uint32_t)_loopCount); // num plays
            acTL[4] = yy_swap_endian_uint32((uint32_t)crc32(0, (const Bytef *)(acTL + 1), 12)); //crc32
            [result appendBytes:acTL length:20];
            
            // insert fcTL (first frame control)
            yy_png_chunk_fcTL chunk_fcTL = {0};
            chunk_fcTL.sequence_number = apngSequenceIndex;
            chunk_fcTL.width = (uint32_t)firstFrameSize.width;
            chunk_fcTL.height = (uint32_t)firstFrameSize.height;
            yy_png_delay_to_fraction([(NSNumber *)_durations[0] doubleValue], &chunk_fcTL.delay_num, &chunk_fcTL.delay_den);
            chunk_fcTL.delay_num = chunk_fcTL.delay_num;
            chunk_fcTL.delay_den = chunk_fcTL.delay_den;
            chunk_fcTL.dispose_op = YY_PNG_DISPOSE_OP_BACKGROUND;
            chunk_fcTL.blend_op = YY_PNG_BLEND_OP_SOURCE;
            
            uint8_t fcTL[38] = {0};
            *((uint32_t *)fcTL) = yy_swap_endian_uint32(26); //length
            *((uint32_t *)(fcTL + 4)) = YY_FOUR_CC('f', 'c', 'T', 'L'); // fourcc
            yy_png_chunk_fcTL_write(&chunk_fcTL, fcTL + 8);
            *((uint32_t *)(fcTL + 34)) = yy_swap_endian_uint32((uint32_t)crc32(0, (const Bytef *)(fcTL + 4), 30));
            [result appendBytes:fcTL length:38];
            
            apngSequenceIndex++;
        }
        
        if (!insertAfter && insertBefore && chunk->fourcc != YY_FOUR_CC('I', 'D', 'A', 'T')) {
            insertAfter = YES;
            // insert fcTL and fdAT (APNG frame control and data)
            
            for (int i = 1; i < pngDatas.count; i++) {
                NSData *frameData = pngDatas[i];
                yy_png_info *frame = yy_png_info_create(frameData.bytes, (uint32_t)frameData.length);
                if (!frame) {
                    yy_png_info_release(info);
                    return nil;
                }
                
                // insert fcTL (first frame control)
                yy_png_chunk_fcTL chunk_fcTL = {0};
                chunk_fcTL.sequence_number = apngSequenceIndex;
                chunk_fcTL.width = frame->header.width;
                chunk_fcTL.height = frame->header.height;
                yy_png_delay_to_fraction([(NSNumber *)_durations[i] doubleValue], &chunk_fcTL.delay_num, &chunk_fcTL.delay_den);
                chunk_fcTL.delay_num = chunk_fcTL.delay_num;
                chunk_fcTL.delay_den = chunk_fcTL.delay_den;
                chunk_fcTL.dispose_op = YY_PNG_DISPOSE_OP_BACKGROUND;
                chunk_fcTL.blend_op = YY_PNG_BLEND_OP_SOURCE;
                
                uint8_t fcTL[38] = {0};
                *((uint32_t *)fcTL) = yy_swap_endian_uint32(26); //length
                *((uint32_t *)(fcTL + 4)) = YY_FOUR_CC('f', 'c', 'T', 'L'); // fourcc
                yy_png_chunk_fcTL_write(&chunk_fcTL, fcTL + 8);
                *((uint32_t *)(fcTL + 34)) = yy_swap_endian_uint32((uint32_t)crc32(0, (const Bytef *)(fcTL + 4), 30));
                [result appendBytes:fcTL length:38];
                
                apngSequenceIndex++;
                
                // insert fdAT (frame data)
                for (int d = 0; d < frame->chunk_num; d++) {
                    yy_png_chunk_info *dchunk = frame->chunks + d;
                    if (dchunk->fourcc == YY_FOUR_CC('I', 'D', 'A', 'T')) {
                        uint32_t length = yy_swap_endian_uint32(dchunk->length + 4);
                        [result appendBytes:&length length:4]; //length
                        uint32_t fourcc = YY_FOUR_CC('f', 'd', 'A', 'T');
                        [result appendBytes:&fourcc length:4]; //fourcc
                        uint32_t sq = yy_swap_endian_uint32(apngSequenceIndex);
                        [result appendBytes:&sq length:4]; //data (sq)
                        [result appendBytes:(((uint8_t *)frameData.bytes) + dchunk->offset + 8) length:dchunk->length]; //data
                        uint8_t *bytes = ((uint8_t *)result.bytes) + result.length - dchunk->length - 8;
                        uint32_t crc = yy_swap_endian_uint32((uint32_t)crc32(0, bytes, dchunk->length + 8));
                        [result appendBytes:&crc length:4]; //crc
                        
                        apngSequenceIndex++;
                    }
                }
                yy_png_info_release(frame);
            }
        }
        
        [result appendBytes:((uint8_t *)firstFrameData.bytes) + chunk->offset length:chunk->length + 12];
    }
    yy_png_info_release(info);
    return result;
}

- (NSData *)_encodeWebP {
#if YYIMAGE_WEBP_ENABLED
    // encode webp
    NSMutableArray *webpDatas = [NSMutableArray new];
    for (NSUInteger i = 0; i < _images.count; i++) {
        CGImageRef image = [self _newCGImageFromIndex:i decoded:NO];
        if (!image) return nil;
        CFDataRef frameData = YYCGImageCreateEncodedWebPData(image, _lossless, _quality, 4, YYImagePresetDefault);
        CFRelease(image);
        if (!frameData) return nil;
        [webpDatas addObject:(__bridge id)frameData];
        CFRelease(frameData);
    }
    if (webpDatas.count == 1) {
        return webpDatas.firstObject;
    } else {
        // multi-frame webp
        WebPMux *mux = WebPMuxNew();
        if (!mux) return nil;
        for (NSUInteger i = 0; i < _images.count; i++) {
            NSData *data = webpDatas[i];
            NSNumber *duration = _durations[i];
            WebPMuxFrameInfo frame = {0};
            frame.bitstream.bytes = data.bytes;
            frame.bitstream.size = data.length;
            frame.duration = (int)(duration.floatValue * 1000.0);
            frame.id = WEBP_CHUNK_ANMF;
            frame.dispose_method = WEBP_MUX_DISPOSE_BACKGROUND;
            frame.blend_method = WEBP_MUX_NO_BLEND;
            if (WebPMuxPushFrame(mux, &frame, 0) != WEBP_MUX_OK) {
                WebPMuxDelete(mux);
                return nil;
            }
        }
        
        WebPMuxAnimParams params = {(uint32_t)0, (int)_loopCount};
        if (WebPMuxSetAnimationParams(mux, &params) != WEBP_MUX_OK) {
            WebPMuxDelete(mux);
            return nil;
        }
        
        WebPData output_data;
        WebPMuxError error = WebPMuxAssemble(mux, &output_data);
        WebPMuxDelete(mux);
        if (error != WEBP_MUX_OK) {
            return nil;
        }
        NSData *result = [NSData dataWithBytes:output_data.bytes length:output_data.size];
        WebPDataClear(&output_data);
        return result.length ? result : nil;
    }
#else
    return nil;
#endif
}

// 编码图片
- (NSData *)encode {
    if (_images.count == 0) return nil;
    
    if ([self _imageIOAvaliable]) return [self _encodeWithImageIO];
    if (_type == YYImageTypePNG) return [self _encodeAPNG];
    if (_type == YYImageTypeWebP) return [self _encodeWebP];
    return nil;
}

// 将图像压缩并写入指定路径
- (BOOL)encodeToFile:(NSString *)path {
    if (_images.count == 0 || path.length == 0) return NO;
    
    if ([self _imageIOAvaliable]) return [self _encodeWithImageIO:path];
    NSData *data = [self encode];
    if (!data) return NO;
    return [data writeToFile:path atomically:YES];
}

// 解压指定图像
+ (NSData *)encodeImage:(UIImage *)image type:(YYImageType)type quality:(CGFloat)quality {
    YYImageEncoder *encoder = [[YYImageEncoder alloc] initWithType:type];
    encoder.quality = quality;
    [encoder addImage:image duration:0];
    return [encoder encode];
}

// 使用指定的decoder解压
+ (NSData *)encodeImageWithDecoder:(YYImageDecoder *)decoder type:(YYImageType)type quality:(CGFloat)quality {
    if (!decoder || decoder.frameCount == 0) return nil;
    YYImageEncoder *encoder = [[YYImageEncoder alloc] initWithType:type];
    encoder.quality = quality;
    for (int i = 0; i < decoder.frameCount; i++) {
        UIImage *frame = [decoder frameAtIndex:i decodeForDisplay:YES].image;
        [encoder addImageWithData:UIImagePNGRepresentation(frame) duration:[decoder frameDurationAtIndex:i]];
    }
    return encoder.encode;
}

@end

// UIImage 分类
@implementation UIImage (YYImageCoder)

// 解压图像
- (instancetype)imageByDecoded {
    if (self.isDecodedForDisplay) return self;
    CGImageRef imageRef = self.CGImage;
    if (!imageRef) return self;
    CGImageRef newImageRef = YYCGImageCreateDecodedCopy(imageRef, YES);
    if (!newImageRef) return self;
    UIImage *newImage = [[self.class alloc] initWithCGImage:newImageRef scale:self.scale orientation:self.imageOrientation];
    CGImageRelease(newImageRef);
    if (!newImage) newImage = self; // decode failed, return self.
    newImage.isDecodedForDisplay = YES;
    return newImage;
}

// 动态绑定
- (BOOL)isDecodedForDisplay {
    if (self.images.count > 1) return YES;
    NSNumber *num = objc_getAssociatedObject(self, @selector(isDecodedForDisplay));
    return [num boolValue];
}

- (void)setIsDecodedForDisplay:(BOOL)isDecodedForDisplay {
    objc_setAssociatedObject(self, @selector(isDecodedForDisplay), @(isDecodedForDisplay), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

// 保存到相册
- (void)saveToAlbumWithCompletionBlock:(void(^)(NSURL *assetURL, NSError *error))completionBlock {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSData *data = [self _imageDataRepresentationForSystem:YES];
        ALAssetsLibrary *library = [[ALAssetsLibrary alloc] init];
        [library writeImageDataToSavedPhotosAlbum:data metadata:nil completionBlock:^(NSURL *assetURL, NSError *error){
            if (!completionBlock) return;
            if (pthread_main_np()) {
                completionBlock(assetURL, error);
            } else {
                dispatch_async(dispatch_get_main_queue(), ^{
                    completionBlock(assetURL, error);
                });
            }
        }];
    });
}

- (NSData *)imageDataRepresentation {
    return [self _imageDataRepresentationForSystem:NO];
}

/// @param forSystem YES: used for system album (PNG/JPEG/GIF), NO: used for YYImage (PNG/JPEG/GIF/WebP)
- (NSData *)_imageDataRepresentationForSystem:(BOOL)forSystem {
    NSData *data = nil;
    if ([self isKindOfClass:[YYImage class]]) {
        YYImage *image = (id)self;
        if (image.animatedImageData) {
            if (forSystem) { // system only support GIF and PNG
                if (image.animatedImageType == YYImageTypeGIF ||
                    image.animatedImageType == YYImageTypePNG) {
                    data = image.animatedImageData;
                }
            } else {
                data = image.animatedImageData;
            }
        }
    }
    if (!data) {
        CGImageRef imageRef = self.CGImage ? (CGImageRef)CFRetain(self.CGImage) : nil;
        if (imageRef) {
            CGBitmapInfo bitmapInfo = CGImageGetBitmapInfo(imageRef);
            CGImageAlphaInfo alphaInfo = CGImageGetAlphaInfo(imageRef) & kCGBitmapAlphaInfoMask;
            BOOL hasAlpha = NO;
            if (alphaInfo == kCGImageAlphaPremultipliedLast ||
                alphaInfo == kCGImageAlphaPremultipliedFirst ||
                alphaInfo == kCGImageAlphaLast ||
                alphaInfo == kCGImageAlphaFirst) {
                hasAlpha = YES;
            }
            if (self.imageOrientation != UIImageOrientationUp) {
                CGImageRef rotated = YYCGImageCreateCopyWithOrientation(imageRef, self.imageOrientation, bitmapInfo | alphaInfo);
                if (rotated) {
                    CFRelease(imageRef);
                    imageRef = rotated;
                }
            }
            @autoreleasepool {
                UIImage *newImage = [UIImage imageWithCGImage:imageRef];
                if (newImage) {
                    if (hasAlpha) {
                        data = UIImagePNGRepresentation([UIImage imageWithCGImage:imageRef]);
                    } else {
                        data = UIImageJPEGRepresentation([UIImage imageWithCGImage:imageRef], 0.9); // same as Apple's example
                    }
                }
            }
            CFRelease(imageRef);
        }
    }
    if (!data) {
        data = UIImagePNGRepresentation(self);
    }
    return data;
}

@end
