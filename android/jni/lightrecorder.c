/*
 * Light Engine Native Hardware MP4 Screen Recorder (Android NDK API 21+)
 *
 * Zero-stall OpenGL ES 3.0 triple-buffered PBO async readback + hardware
 * AMediaCodec H.264 ("video/avc") + AAC-LC ("audio/mp4a-latm") + AMediaMuxer (.mp4).
 *
 * Loaded dynamically via LuaJIT FFI (`ffi.load("lightrecorder")`).
 */

#include <stdint.h>
#include <stdlib.h>
#include <string.h>
#include <stdio.h>
#include <pthread.h>
#include <fcntl.h>
#include <unistd.h>

#ifdef __ANDROID__
#include <dlfcn.h>
#include <EGL/egl.h>
#include <GLES2/gl2.h>
#include <media/NdkMediaCodec.h>
#include <media/NdkMediaFormat.h>
#include <media/NdkMediaMuxer.h>
#include <android/log.h>
#define LR_LOGI(...) __android_log_print(ANDROID_LOG_INFO, "LightRecorder", __VA_ARGS__)
#define LR_LOGE(...) __android_log_print(ANDROID_LOG_ERROR, "LightRecorder", __VA_ARGS__)
#else
#define LR_LOGI(...) ((void)0)
#define LR_LOGE(...) ((void)0)
#endif

#if defined(__GNUC__)
#define LR_EXPORT __attribute__((visibility("default")))
#else
#define LR_EXPORT
#endif

#define LR_PBO_COUNT 3
#define LR_VIDEO_RING 10
#define LR_AUDIO_CAP_FRAMES (48000 * 6)
#define LR_EARLY_PKT_MAX 256

#define LR_GL_PIXEL_PACK_BUFFER 0x88EB
#define LR_GL_STREAM_READ       0x88E1
#define LR_GL_MAP_READ_BIT      0x0001

#define LR_COLOR_FMT_NV12 21
#define LR_COLOR_FMT_I420 19

#define LR_FLAG_CODEC_CONFIG  2
#define LR_FLAG_END_OF_STREAM 4

#ifdef __ANDROID__
typedef void* (*pfn_glMapBufferRange)(GLenum target, GLintptr offset, GLsizeiptr length, GLbitfield access);
typedef GLboolean (*pfn_glUnmapBuffer)(GLenum target);

typedef struct {
    uint8_t *rgba;
    int64_t pts_us;
} lr_video_slot_t;

typedef struct {
    int is_audio;
    uint8_t *data;
    size_t size;
    int64_t pts_us;
    uint32_t flags;
} lr_early_pkt_t;

typedef struct {
    int active;
    int stopping;
    int error_code;
    char path[1024];
    int fd;

    int width;
    int height;
    int fps;
    int bitrate;
    int record_audio;
    int audio_rate;
    int color_format;

    /* GLES3 async PBO state (owned exclusively by GL thread) */
    int use_pbo;
    pfn_glMapBufferRange fn_map_buffer_range;
    pfn_glUnmapBuffer fn_unmap_buffer;
    GLuint pbos[LR_PBO_COUNT];
    int pbo_valid[LR_PBO_COUNT];
    int64_t pbo_pts[LR_PBO_COUNT];
    int pbo_write_idx;
    size_t frame_rgba_bytes;
    uint8_t *gl_scratch;

    /* Video ring buffer (GL thread -> Encoder thread) */
    pthread_mutex_t mtx;
    pthread_cond_t cv;
    pthread_cond_t space_cv;
    lr_video_slot_t v_ring[LR_VIDEO_RING];
    int v_head;
    int v_tail;
    int v_count;
    uint64_t submitted_frames;
    uint64_t encoded_frames;
    uint64_t dropped_frames;

    /* Audio S16LE stereo FIFO (Lua mixer thread -> Encoder thread) */
    int16_t *a_fifo;
    int a_head;
    int a_tail;
    int a_count; /* in stereo sample frames */
    int64_t a_pts_samples;

    /* NDK MediaCodec + MediaMuxer (owned by Encoder thread) */
    AMediaCodec *v_codec;
    AMediaCodec *a_codec;
    AMediaMuxer *muxer;
    ssize_t v_track;
    ssize_t a_track;
    int muxer_started;
    int has_pts_origin;
    int64_t pts_origin_us;
    int has_prev_yuv;
    int64_t prev_yuv_pts_us;
    int64_t last_v_pts_us;
    int64_t last_a_pts_us;

    lr_early_pkt_t early_pkts[LR_EARLY_PKT_MAX];
    int early_pkt_count;

    uint8_t *yuv_buf;
    size_t yuv_bytes;

    pthread_t worker;
    int worker_running;
} lr_ctx_t;

static lr_ctx_t g_lr;

static void lr_resolve_gles3(lr_ctx_t *ctx) {
    ctx->fn_map_buffer_range = (pfn_glMapBufferRange)eglGetProcAddress("glMapBufferRange");
    ctx->fn_unmap_buffer = (pfn_glUnmapBuffer)eglGetProcAddress("glUnmapBuffer");
    if (!ctx->fn_map_buffer_range) {
        ctx->fn_map_buffer_range = (pfn_glMapBufferRange)dlsym(RTLD_DEFAULT, "glMapBufferRange");
    }
    if (!ctx->fn_unmap_buffer) {
        ctx->fn_unmap_buffer = (pfn_glUnmapBuffer)dlsym(RTLD_DEFAULT, "glUnmapBuffer");
    }
}

static void lr_rgba_to_yuv420(const uint8_t *rgba, uint8_t *yuv, int w, int h, int nv12) {
    uint8_t *y_plane = yuv;
    uint8_t *uv_plane = yuv + (size_t)w * (size_t)h;
    uint8_t *u_plane = uv_plane;
    uint8_t *v_plane = uv_plane + ((size_t)w * (size_t)h) / 4;

    for (int j = 0; j < h; j += 2) {
        const uint8_t *row0 = rgba + (size_t)j * (size_t)w * 4;
        const uint8_t *row1 = row0 + (size_t)w * 4;
        uint8_t *y0 = y_plane + (size_t)j * (size_t)w;
        uint8_t *y1 = y0 + (size_t)w;
        size_t uv_row_idx = (size_t)(j >> 1) * (size_t)(w >> 1);

        for (int i = 0; i < w; i += 2) {
            int r00 = row0[0], g00 = row0[1], b00 = row0[2];
            int r01 = row0[4], g01 = row0[5], b01 = row0[6];
            int r10 = row1[0], g10 = row1[1], b10 = row1[2];
            int r11 = row1[4], g11 = row1[5], b11 = row1[6];

            int lum00 = ((66 * r00 + 129 * g00 + 25 * b00 + 128) >> 8) + 16;
            int lum01 = ((66 * r01 + 129 * g01 + 25 * b01 + 128) >> 8) + 16;
            int lum10 = ((66 * r10 + 129 * g10 + 25 * b10 + 128) >> 8) + 16;
            int lum11 = ((66 * r11 + 129 * g11 + 25 * b11 + 128) >> 8) + 16;

            y0[0] = (uint8_t)(lum00 < 0 ? 0 : (lum00 > 255 ? 255 : lum00));
            y0[1] = (uint8_t)(lum01 < 0 ? 0 : (lum01 > 255 ? 255 : lum01));
            y1[0] = (uint8_t)(lum10 < 0 ? 0 : (lum10 > 255 ? 255 : lum10));
            y1[1] = (uint8_t)(lum11 < 0 ? 0 : (lum11 > 255 ? 255 : lum11));

            int r_avg = (r00 + r01 + r10 + r11 + 2) >> 2;
            int g_avg = (g00 + g01 + g10 + g11 + 2) >> 2;
            int b_avg = (b00 + b01 + b10 + b11 + 2) >> 2;

            int u = ((-38 * r_avg - 74 * g_avg + 112 * b_avg + 128) >> 8) + 128;
            int v = ((112 * r_avg - 94 * g_avg - 18 * b_avg + 128) >> 8) + 128;
            uint8_t ub = (uint8_t)(u < 0 ? 0 : (u > 255 ? 255 : u));
            uint8_t vb = (uint8_t)(v < 0 ? 0 : (v > 255 ? 255 : v));

            size_t c_idx = uv_row_idx + (size_t)(i >> 1);
            if (nv12) {
                uv_plane[c_idx * 2] = ub;
                uv_plane[c_idx * 2 + 1] = vb;
            } else {
                u_plane[c_idx] = ub;
                v_plane[c_idx] = vb;
            }

            row0 += 8;
            row1 += 8;
            y0 += 2;
            y1 += 2;
        }
    }
}

static void lr_free_early_pkts(lr_ctx_t *ctx) {
    for (int i = 0; i < ctx->early_pkt_count; i++) {
        free(ctx->early_pkts[i].data);
        ctx->early_pkts[i].data = NULL;
    }
    ctx->early_pkt_count = 0;
}

static void lr_try_start_muxer(lr_ctx_t *ctx) {
    if (ctx->muxer_started || !ctx->muxer) return;
    if (ctx->v_track < 0) return;
    if (ctx->record_audio && ctx->a_track < 0) return;

    if (AMediaMuxer_start(ctx->muxer) == AMEDIA_OK) {
        ctx->muxer_started = 1;
        for (int i = 0; i < ctx->early_pkt_count; i++) {
            lr_early_pkt_t *p = &ctx->early_pkts[i];
            AMediaCodecBufferInfo info;
            info.offset = 0;
            info.size = (int32_t)p->size;
            info.presentationTimeUs = p->pts_us;
            info.flags = p->flags;
            ssize_t trk = p->is_audio ? ctx->a_track : ctx->v_track;
            if (trk >= 0 && p->data && p->size > 0) {
                AMediaMuxer_writeSampleData(ctx->muxer, (size_t)trk, p->data, &info);
            }
            free(p->data);
            p->data = NULL;
        }
        ctx->early_pkt_count = 0;
    } else {
        ctx->error_code = -10;
    }
}

static void lr_emit_sample(lr_ctx_t *ctx, int is_audio, const uint8_t *data, const AMediaCodecBufferInfo *info) {
    if (!data || info->size <= 0) return;
    if (info->flags & LR_FLAG_CODEC_CONFIG) return;

    AMediaCodecBufferInfo fixed = *info;
    fixed.offset = 0;
    if (is_audio) {
        if (fixed.presentationTimeUs < ctx->last_a_pts_us) {
            fixed.presentationTimeUs = ctx->last_a_pts_us;
        }
        ctx->last_a_pts_us = fixed.presentationTimeUs;
    } else {
        if (fixed.presentationTimeUs <= ctx->last_v_pts_us) {
            fixed.presentationTimeUs = ctx->last_v_pts_us + 1000;
        }
        ctx->last_v_pts_us = fixed.presentationTimeUs;
    }

    if (ctx->muxer_started) {
        ssize_t trk = is_audio ? ctx->a_track : ctx->v_track;
        if (trk >= 0) {
            AMediaMuxer_writeSampleData(ctx->muxer, (size_t)trk, data + info->offset, &fixed);
        }
    } else if (ctx->early_pkt_count < LR_EARLY_PKT_MAX) {
        uint8_t *copy = (uint8_t *)malloc((size_t)info->size);
        if (copy) {
            memcpy(copy, data + info->offset, (size_t)info->size);
            lr_early_pkt_t *slot = &ctx->early_pkts[ctx->early_pkt_count++];
            slot->is_audio = is_audio;
            slot->data = copy;
            slot->size = (size_t)info->size;
            slot->pts_us = fixed.presentationTimeUs;
            slot->flags = fixed.flags;
        }
    }
}

static int lr_drain_codec(lr_ctx_t *ctx, AMediaCodec *codec, int is_audio, int wait_eos) {
    if (!codec) return 1;
    int saw_eos = 0;
    int empty_tries = 0;
    while (1) {
        AMediaCodecBufferInfo info;
        memset(&info, 0, sizeof(info));
        ssize_t status = AMediaCodec_dequeueOutputBuffer(codec, &info, wait_eos ? 10000 : 0);
        if (status == AMEDIACODEC_INFO_TRY_AGAIN_LATER) {
            if (!wait_eos) break;
            if (++empty_tries > 300) break; /* 3s safety cap on EOS drain */
            continue;
        } else if (status == AMEDIACODEC_INFO_OUTPUT_FORMAT_CHANGED) {
            AMediaFormat *fmt = AMediaCodec_getOutputFormat(codec);
            if (fmt && ctx->muxer && !ctx->muxer_started) {
                ssize_t trk = AMediaMuxer_addTrack(ctx->muxer, fmt);
                if (is_audio) ctx->a_track = trk;
                else ctx->v_track = trk;
                lr_try_start_muxer(ctx);
            }
            if (fmt) AMediaFormat_delete(fmt);
        } else if (status == AMEDIACODEC_INFO_OUTPUT_BUFFERS_CHANGED) {
            continue;
        } else if (status >= 0) {
            empty_tries = 0;
            size_t out_sz = 0;
            uint8_t *out_buf = AMediaCodec_getOutputBuffer(codec, (size_t)status, &out_sz);
            if (out_buf && info.size > 0) {
                lr_emit_sample(ctx, is_audio, out_buf, &info);
                if (!is_audio && !(info.flags & LR_FLAG_CODEC_CONFIG)) {
                    ctx->encoded_frames++;
                }
            }
            AMediaCodec_releaseOutputBuffer(codec, (size_t)status, false);
            if (info.flags & LR_FLAG_END_OF_STREAM) {
                saw_eos = 1;
                break;
            }
        } else {
            break;
        }
    }
    return saw_eos;
}

static void lr_queue_yuv_frame(lr_ctx_t *ctx, int64_t pts_us) {
    if (!ctx->v_codec || !ctx->yuv_buf) return;
    ssize_t in_idx = AMediaCodec_dequeueInputBuffer(ctx->v_codec, 15000);
    if (in_idx >= 0) {
        size_t cap = 0;
        uint8_t *dst = AMediaCodec_getInputBuffer(ctx->v_codec, (size_t)in_idx, &cap);
        size_t copy_bytes = ctx->yuv_bytes <= cap ? ctx->yuv_bytes : cap;
        if (dst && copy_bytes > 0) {
            memcpy(dst, ctx->yuv_buf, copy_bytes);
            AMediaCodec_queueInputBuffer(ctx->v_codec, (size_t)in_idx, 0, copy_bytes,
                                         (uint64_t)(pts_us < 0 ? 0 : pts_us), 0);
        }
    }
    lr_drain_codec(ctx, ctx->v_codec, 0, 0);
}

static void *lr_worker_main(void *arg) {
    lr_ctx_t *ctx = (lr_ctx_t *)arg;
    int16_t a_chunk[1024 * 2];
    int64_t a_rate = ctx->audio_rate > 0 ? ctx->audio_rate : 44100;
    int64_t frame_dur_us = 1000000LL / (ctx->fps > 0 ? ctx->fps : 60);
    if (frame_dur_us < 1000) frame_dur_us = 16667;

    while (1) {
        int have_video = 0;
        int64_t v_raw_pts = 0;
        const uint8_t *v_rgba_src = NULL;
        int a_frames_popped = 0;
        int64_t a_pts_sample_start = 0;
        int should_stop = 0;

        pthread_mutex_lock(&ctx->mtx);
        while (ctx->v_count == 0 &&
               (!ctx->record_audio || ctx->a_count < 1024) &&
               !ctx->stopping) {
            pthread_cond_wait(&ctx->cv, &ctx->mtx);
        }

        if (ctx->v_count > 0) {
            lr_video_slot_t *slot = &ctx->v_ring[ctx->v_tail];
            v_raw_pts = slot->pts_us;
            v_rgba_src = slot->rgba;
            have_video = 1;
        }

        if (ctx->record_audio && ctx->a_codec &&
            (ctx->a_count >= 1024 || (ctx->stopping && ctx->a_count > 0))) {
            int take = ctx->a_count >= 1024 ? 1024 : ctx->a_count;
            a_pts_sample_start = ctx->a_pts_samples;
            for (int i = 0; i < take; i++) {
                int idx = (ctx->a_tail + i) % LR_AUDIO_CAP_FRAMES;
                a_chunk[i * 2] = ctx->a_fifo[idx * 2];
                a_chunk[i * 2 + 1] = ctx->a_fifo[idx * 2 + 1];
            }
            ctx->a_tail = (ctx->a_tail + take) % LR_AUDIO_CAP_FRAMES;
            ctx->a_count -= take;
            ctx->a_pts_samples += take;
            a_frames_popped = take;
            pthread_cond_broadcast(&ctx->space_cv);
        }

        should_stop = (ctx->stopping && (ctx->v_count - have_video) <= 0 &&
                       (!ctx->record_audio || ctx->a_count == 0));
        pthread_mutex_unlock(&ctx->mtx);

        if (have_video && ctx->v_codec && v_rgba_src) {
            if (!ctx->has_pts_origin) {
                ctx->pts_origin_us = v_raw_pts;
                ctx->has_pts_origin = 1;
            }
            int64_t v_pts = v_raw_pts - ctx->pts_origin_us;
            if (v_pts < 0) v_pts = 0;

            /* Duplicate the previous YUV frame across dropped-frame PTS gaps before overwriting yuv_buf */
            if (ctx->has_prev_yuv && (v_pts - ctx->prev_yuv_pts_us) >= (frame_dur_us * 2)) {
                int dup_emitted = 0;
                int64_t dup_pts = ctx->prev_yuv_pts_us + frame_dur_us;
                while ((dup_pts + (frame_dur_us / 2)) < v_pts && dup_emitted < 60) {
                    lr_queue_yuv_frame(ctx, dup_pts);
                    ctx->prev_yuv_pts_us = dup_pts;
                    dup_pts += frame_dur_us;
                    dup_emitted++;
                }
            }

            lr_rgba_to_yuv420(v_rgba_src, ctx->yuv_buf, ctx->width, ctx->height,
                              ctx->color_format == LR_COLOR_FMT_NV12);

            pthread_mutex_lock(&ctx->mtx);
            ctx->v_tail = (ctx->v_tail + 1) % LR_VIDEO_RING;
            ctx->v_count--;
            should_stop = (ctx->stopping && ctx->v_count == 0 &&
                           (!ctx->record_audio || ctx->a_count == 0));
            pthread_mutex_unlock(&ctx->mtx);

            if (ctx->has_prev_yuv && v_pts <= ctx->prev_yuv_pts_us) {
                v_pts = ctx->prev_yuv_pts_us + 1000;
            }
            lr_queue_yuv_frame(ctx, v_pts);
            ctx->has_prev_yuv = 1;
            ctx->prev_yuv_pts_us = v_pts;
        }

        if (a_frames_popped > 0 && ctx->a_codec) {
            ssize_t in_idx = AMediaCodec_dequeueInputBuffer(ctx->a_codec, 15000);
            if (in_idx >= 0) {
                size_t cap = 0;
                uint8_t *dst = AMediaCodec_getInputBuffer(ctx->a_codec, (size_t)in_idx, &cap);
                size_t pcm_bytes = (size_t)a_frames_popped * 4;
                if (pcm_bytes > cap) pcm_bytes = cap;
                if (dst && pcm_bytes > 0) {
                    memcpy(dst, a_chunk, pcm_bytes);
                    uint64_t a_pts_us = (uint64_t)((a_pts_sample_start * 1000000LL) / a_rate);
                    AMediaCodec_queueInputBuffer(ctx->a_codec, (size_t)in_idx, 0, pcm_bytes, a_pts_us, 0);
                }
            }
            lr_drain_codec(ctx, ctx->a_codec, 1, 0);
        }

        if (should_stop) {
            /* Ensure audio codec produces format + at least 1 frame if video was recorded */
            if (ctx->record_audio && ctx->a_codec && ctx->a_pts_samples == 0 && ctx->submitted_frames > 0) {
                memset(a_chunk, 0, sizeof(a_chunk));
                ssize_t in_idx = AMediaCodec_dequeueInputBuffer(ctx->a_codec, 20000);
                if (in_idx >= 0) {
                    size_t cap = 0;
                    uint8_t *dst = AMediaCodec_getInputBuffer(ctx->a_codec, (size_t)in_idx, &cap);
                    size_t sz = sizeof(a_chunk) <= cap ? sizeof(a_chunk) : cap;
                    if (dst && sz > 0) {
                        memcpy(dst, a_chunk, sz);
                        AMediaCodec_queueInputBuffer(ctx->a_codec, (size_t)in_idx, 0, sz, 0, 0);
                        ctx->a_pts_samples = (int64_t)(sz / 4);
                    }
                }
            }

            if (ctx->v_codec) {
                int64_t target_end_us = (ctx->record_audio && ctx->a_pts_samples > 0)
                    ? ((ctx->a_pts_samples * 1000000LL) / a_rate)
                    : (ctx->prev_yuv_pts_us + frame_dur_us);
                if (ctx->has_prev_yuv && (target_end_us - ctx->prev_yuv_pts_us) >= (frame_dur_us * 2)) {
                    int dup_emitted = 0;
                    int64_t dup_pts = ctx->prev_yuv_pts_us + frame_dur_us;
                    while ((dup_pts + (frame_dur_us / 2)) < target_end_us && dup_emitted < 60) {
                        lr_queue_yuv_frame(ctx, dup_pts);
                        ctx->prev_yuv_pts_us = dup_pts;
                        dup_pts += frame_dur_us;
                        dup_emitted++;
                    }
                }

                ssize_t in_idx = AMediaCodec_dequeueInputBuffer(ctx->v_codec, 30000);
                if (in_idx >= 0) {
                    int64_t eos_v = target_end_us > (ctx->last_v_pts_us + 1000)
                        ? target_end_us
                        : (ctx->last_v_pts_us > 0 ? ctx->last_v_pts_us + frame_dur_us : 0);
                    AMediaCodec_queueInputBuffer(ctx->v_codec, (size_t)in_idx, 0, 0, (uint64_t)eos_v, LR_FLAG_END_OF_STREAM);
                }
                lr_drain_codec(ctx, ctx->v_codec, 0, 1);
            }

            if (ctx->record_audio && ctx->a_codec) {
                ssize_t in_idx = AMediaCodec_dequeueInputBuffer(ctx->a_codec, 30000);
                if (in_idx >= 0) {
                    uint64_t eos_pts = (uint64_t)((ctx->a_pts_samples * 1000000LL) / a_rate);
                    AMediaCodec_queueInputBuffer(ctx->a_codec, (size_t)in_idx, 0, 0, eos_pts, LR_FLAG_END_OF_STREAM);
                }
                lr_drain_codec(ctx, ctx->a_codec, 1, 1);
            }
            break;
        }
    }

    return NULL;
}

static void lr_enqueue_rgba_slot(lr_ctx_t *ctx, const uint8_t *src, int64_t pts_us) {
    pthread_mutex_lock(&ctx->mtx);
    if (!ctx->stopping && ctx->v_count < LR_VIDEO_RING) {
        lr_video_slot_t *slot = &ctx->v_ring[ctx->v_head];
        memcpy(slot->rgba, src, ctx->frame_rgba_bytes);
        slot->pts_us = pts_us;
        ctx->v_head = (ctx->v_head + 1) % LR_VIDEO_RING;
        ctx->v_count++;
        ctx->submitted_frames++;
        pthread_cond_signal(&ctx->cv);
    } else if (!ctx->stopping) {
        ctx->dropped_frames++;
    }
    pthread_mutex_unlock(&ctx->mtx);
}
#endif /* __ANDROID__ */

LR_EXPORT int lightrecorder_is_available(void) {
#ifdef __ANDROID__
    return 1;
#else
    return 0;
#endif
}

LR_EXPORT int lightrecorder_start_ex(const char *path, int width, int height, int fps, int bitrate, int record_audio, int audio_rate) {
#ifdef __ANDROID__
    if (!path || !path[0] || width < 64 || height < 64) return -1;
    if (g_lr.active) return -2;

    memset(&g_lr, 0, sizeof(g_lr));
    strncpy(g_lr.path, path, sizeof(g_lr.path) - 1);
    g_lr.width = (width + 15) & ~15;
    g_lr.height = (height + 15) & ~15;
    g_lr.fps = fps > 0 ? fps : 60;
    g_lr.bitrate = bitrate > 500000 ? bitrate : 6000000;
    g_lr.record_audio = record_audio ? 1 : 0;
    g_lr.audio_rate = (audio_rate == 48000) ? 48000 : 44100;
    g_lr.v_track = -1;
    g_lr.a_track = -1;
    g_lr.last_v_pts_us = -1;
    g_lr.last_a_pts_us = 0;
    g_lr.frame_rgba_bytes = (size_t)g_lr.width * (size_t)g_lr.height * 4;
    g_lr.yuv_bytes = ((size_t)g_lr.width * (size_t)g_lr.height * 3) / 2;

    g_lr.fd = open(g_lr.path, O_CREAT | O_TRUNC | O_RDWR, 0664);
    if (g_lr.fd < 0) {
        LR_LOGE("Failed to open output file: %s", g_lr.path);
        return -3;
    }

    g_lr.muxer = AMediaMuxer_new(g_lr.fd, AMEDIAMUXER_OUTPUT_FORMAT_MPEG_4);
    if (!g_lr.muxer) {
        close(g_lr.fd);
        g_lr.fd = -1;
        return -4;
    }

    /* Configure H.264 hardware encoder (try NV12 first, fallback I420) */
    int fmts[2] = {LR_COLOR_FMT_NV12, LR_COLOR_FMT_I420};
    int configured = 0;
    for (int i = 0; i < 2; i++) {
        g_lr.v_codec = AMediaCodec_createEncoderByType("video/avc");
        if (!g_lr.v_codec) break;
        AMediaFormat *vfmt = AMediaFormat_new();
        AMediaFormat_setString(vfmt, "mime", "video/avc");
        AMediaFormat_setInt32(vfmt, "width", g_lr.width);
        AMediaFormat_setInt32(vfmt, "height", g_lr.height);
        AMediaFormat_setInt32(vfmt, "color-format", fmts[i]);
        AMediaFormat_setInt32(vfmt, "bitrate", g_lr.bitrate);
        AMediaFormat_setInt32(vfmt, "frame-rate", g_lr.fps);
        AMediaFormat_setInt32(vfmt, "i-frame-interval", 2);
        AMediaFormat_setInt32(vfmt, "bitrate-mode", 1); /* VBR */
        AMediaFormat_setInt32(vfmt, "priority", 0);
        media_status_t st = AMediaCodec_configure(g_lr.v_codec, vfmt, NULL, NULL, AMEDIACODEC_CONFIGURE_FLAG_ENCODE);
        AMediaFormat_delete(vfmt);
        if (st != AMEDIA_OK) {
            AMediaCodec_delete(g_lr.v_codec);
            g_lr.v_codec = AMediaCodec_createEncoderByType("video/avc");
            if (g_lr.v_codec) {
                AMediaFormat *vfmt2 = AMediaFormat_new();
                AMediaFormat_setString(vfmt2, "mime", "video/avc");
                AMediaFormat_setInt32(vfmt2, "width", g_lr.width);
                AMediaFormat_setInt32(vfmt2, "height", g_lr.height);
                AMediaFormat_setInt32(vfmt2, "color-format", fmts[i]);
                AMediaFormat_setInt32(vfmt2, "bitrate", g_lr.bitrate);
                AMediaFormat_setInt32(vfmt2, "frame-rate", g_lr.fps);
                AMediaFormat_setInt32(vfmt2, "i-frame-interval", 2);
                st = AMediaCodec_configure(g_lr.v_codec, vfmt2, NULL, NULL, AMEDIACODEC_CONFIGURE_FLAG_ENCODE);
                AMediaFormat_delete(vfmt2);
            }
        }
        if (st == AMEDIA_OK && g_lr.v_codec && AMediaCodec_start(g_lr.v_codec) == AMEDIA_OK) {
            g_lr.color_format = fmts[i];
            configured = 1;
            break;
        }
        if (g_lr.v_codec) {
            AMediaCodec_delete(g_lr.v_codec);
            g_lr.v_codec = NULL;
        }
    }

    if (!configured) {
        AMediaMuxer_delete(g_lr.muxer);
        close(g_lr.fd);
        unlink(g_lr.path);
        memset(&g_lr, 0, sizeof(g_lr));
        return -5;
    }

    if (g_lr.record_audio) {
        g_lr.a_codec = AMediaCodec_createEncoderByType("audio/mp4a-latm");
        if (g_lr.a_codec) {
            AMediaFormat *afmt = AMediaFormat_new();
            AMediaFormat_setString(afmt, "mime", "audio/mp4a-latm");
            AMediaFormat_setInt32(afmt, "sample-rate", g_lr.audio_rate);
            AMediaFormat_setInt32(afmt, "channel-count", 2);
            AMediaFormat_setInt32(afmt, "bitrate", 192000);
            AMediaFormat_setInt32(afmt, "aac-profile", 2); /* AACObjectLC */
            AMediaFormat_setInt32(afmt, "max-input-size", 16384);
            if (AMediaCodec_configure(g_lr.a_codec, afmt, NULL, NULL, AMEDIACODEC_CONFIGURE_FLAG_ENCODE) != AMEDIA_OK ||
                AMediaCodec_start(g_lr.a_codec) != AMEDIA_OK) {
                AMediaCodec_delete(g_lr.a_codec);
                g_lr.a_codec = NULL;
                g_lr.record_audio = 0;
            }
            AMediaFormat_delete(afmt);
        } else {
            g_lr.record_audio = 0;
        }
    }

    g_lr.yuv_buf = (uint8_t *)malloc(g_lr.yuv_bytes);
    for (int i = 0; i < LR_VIDEO_RING; i++) {
        g_lr.v_ring[i].rgba = (uint8_t *)malloc(g_lr.frame_rgba_bytes);
        if (!g_lr.v_ring[i].rgba) g_lr.error_code = -6;
    }
    if (g_lr.record_audio) {
        g_lr.a_fifo = (int16_t *)malloc((size_t)LR_AUDIO_CAP_FRAMES * 4);
        if (!g_lr.a_fifo) g_lr.record_audio = 0;
    }

    if (!g_lr.yuv_buf || g_lr.error_code != 0) {
        for (int i = 0; i < LR_VIDEO_RING; i++) free(g_lr.v_ring[i].rgba);
        free(g_lr.yuv_buf);
        free(g_lr.a_fifo);
        if (g_lr.a_codec) { AMediaCodec_stop(g_lr.a_codec); AMediaCodec_delete(g_lr.a_codec); }
        AMediaCodec_stop(g_lr.v_codec);
        AMediaCodec_delete(g_lr.v_codec);
        AMediaMuxer_delete(g_lr.muxer);
        close(g_lr.fd);
        unlink(g_lr.path);
        memset(&g_lr, 0, sizeof(g_lr));
        return -6;
    }

    /* Set up GLES3 triple-buffered PBOs on the current GL context */
    lr_resolve_gles3(&g_lr);
    if (g_lr.fn_map_buffer_range && g_lr.fn_unmap_buffer) {
        while (glGetError() != GL_NO_ERROR) {}
        glGenBuffers(LR_PBO_COUNT, g_lr.pbos);
        for (int i = 0; i < LR_PBO_COUNT; i++) {
            glBindBuffer(LR_GL_PIXEL_PACK_BUFFER, g_lr.pbos[i]);
            glBufferData(LR_GL_PIXEL_PACK_BUFFER, (GLsizeiptr)g_lr.frame_rgba_bytes, NULL, LR_GL_STREAM_READ);
        }
        glBindBuffer(LR_GL_PIXEL_PACK_BUFFER, 0);
        if (glGetError() == GL_NO_ERROR && g_lr.pbos[0] != 0) {
            g_lr.use_pbo = 1;
        } else {
            glDeleteBuffers(LR_PBO_COUNT, g_lr.pbos);
            memset(g_lr.pbos, 0, sizeof(g_lr.pbos));
        }
    }
    if (!g_lr.use_pbo) {
        g_lr.gl_scratch = (uint8_t *)malloc(g_lr.frame_rgba_bytes);
    }

    pthread_mutex_init(&g_lr.mtx, NULL);
    pthread_cond_init(&g_lr.cv, NULL);
    pthread_cond_init(&g_lr.space_cv, NULL);
    g_lr.active = 1;
    if (pthread_create(&g_lr.worker, NULL, lr_worker_main, &g_lr) == 0) {
        g_lr.worker_running = 1;
    } else {
        g_lr.active = 0;
        return -7;
    }

    LR_LOGI("Started H.264 MP4 recording %dx%d@%dfps pbo=%d audio=%d@%dHz -> %s",
            g_lr.width, g_lr.height, g_lr.fps, g_lr.use_pbo, g_lr.record_audio, g_lr.audio_rate, g_lr.path);
    return 0;
#else
    (void)path; (void)width; (void)height; (void)fps; (void)bitrate; (void)record_audio; (void)audio_rate;
    return -1;
#endif
}

LR_EXPORT int lightrecorder_start(const char *path, int width, int height, int fps, int bitrate, int record_audio) {
    return lightrecorder_start_ex(path, width, height, fps, bitrate, record_audio, 44100);
}

LR_EXPORT int lightrecorder_capture_gl_frame(int64_t pts_us) {
#ifdef __ANDROID__
    if (!g_lr.active || g_lr.stopping) return -1;

    glPixelStorei(GL_PACK_ALIGNMENT, 4);
    if (g_lr.use_pbo) {
        int write_idx = g_lr.pbo_write_idx;
        int read_idx = (write_idx + 1) % LR_PBO_COUNT;

        /* 1. Harvest 2-frames-old PBO (DMA already finished, zero GPU stall) */
        if (g_lr.pbo_valid[read_idx]) {
            glBindBuffer(LR_GL_PIXEL_PACK_BUFFER, g_lr.pbos[read_idx]);
            const uint8_t *mapped = (const uint8_t *)g_lr.fn_map_buffer_range(
                LR_GL_PIXEL_PACK_BUFFER, 0, (GLsizeiptr)g_lr.frame_rgba_bytes, LR_GL_MAP_READ_BIT
            );
            if (mapped) {
                lr_enqueue_rgba_slot(&g_lr, mapped, g_lr.pbo_pts[read_idx]);
                g_lr.fn_unmap_buffer(LR_GL_PIXEL_PACK_BUFFER);
            }
            g_lr.pbo_valid[read_idx] = 0;
        }

        /* 2. Kick async DMA readback of currently bound FBO into write_idx PBO */
        glBindBuffer(LR_GL_PIXEL_PACK_BUFFER, g_lr.pbos[write_idx]);
        glReadPixels(0, 0, g_lr.width, g_lr.height, GL_RGBA, GL_UNSIGNED_BYTE, (void *)0);
        glBindBuffer(LR_GL_PIXEL_PACK_BUFFER, 0);
        glFlush();

        g_lr.pbo_pts[write_idx] = pts_us;
        g_lr.pbo_valid[write_idx] = 1;
        g_lr.pbo_write_idx = read_idx;
        return 0;
    } else if (g_lr.gl_scratch) {
        glReadPixels(0, 0, g_lr.width, g_lr.height, GL_RGBA, GL_UNSIGNED_BYTE, g_lr.gl_scratch);
        lr_enqueue_rgba_slot(&g_lr, g_lr.gl_scratch, pts_us);
        return 0;
    }
    return -2;
#else
    (void)pts_us;
    return -1;
#endif
}

LR_EXPORT void lightrecorder_flush_gl(void) {
#ifdef __ANDROID__
    if (!g_lr.active || !g_lr.use_pbo) return;
    /* Drain remaining valid PBOs in chronological order on the GL thread */
    for (int step = 1; step <= LR_PBO_COUNT; step++) {
        int idx = (g_lr.pbo_write_idx + step - 1) % LR_PBO_COUNT;
        if (g_lr.pbo_valid[idx]) {
            glBindBuffer(LR_GL_PIXEL_PACK_BUFFER, g_lr.pbos[idx]);
            const uint8_t *mapped = (const uint8_t *)g_lr.fn_map_buffer_range(
                LR_GL_PIXEL_PACK_BUFFER, 0, (GLsizeiptr)g_lr.frame_rgba_bytes, LR_GL_MAP_READ_BIT
            );
            if (mapped) {
                lr_enqueue_rgba_slot(&g_lr, mapped, g_lr.pbo_pts[idx]);
                g_lr.fn_unmap_buffer(LR_GL_PIXEL_PACK_BUFFER);
            }
            g_lr.pbo_valid[idx] = 0;
        }
    }
    glBindBuffer(LR_GL_PIXEL_PACK_BUFFER, 0);
#endif
}

LR_EXPORT int lightrecorder_push_audio_pcm(const int16_t *pcm, int num_stereo_frames) {
#ifdef __ANDROID__
    if (!g_lr.active || g_lr.stopping || !g_lr.record_audio || !pcm || num_stereo_frames <= 0) {
        return 0;
    }
    int total_written = 0;
    pthread_mutex_lock(&g_lr.mtx);
    while (total_written < num_stereo_frames && g_lr.active && !g_lr.stopping && g_lr.record_audio) {
        int space = LR_AUDIO_CAP_FRAMES - g_lr.a_count;
        if (space <= 0) {
            pthread_cond_wait(&g_lr.space_cv, &g_lr.mtx);
            continue;
        }
        int rem = num_stereo_frames - total_written;
        int to_write = rem <= space ? rem : space;
        const int16_t *src = pcm + (size_t)total_written * 2;
        for (int i = 0; i < to_write; i++) {
            int idx = (g_lr.a_head + i) % LR_AUDIO_CAP_FRAMES;
            g_lr.a_fifo[idx * 2] = src[i * 2];
            g_lr.a_fifo[idx * 2 + 1] = src[i * 2 + 1];
        }
        g_lr.a_head = (g_lr.a_head + to_write) % LR_AUDIO_CAP_FRAMES;
        g_lr.a_count += to_write;
        total_written += to_write;
        if (g_lr.a_count >= 1024) {
            pthread_cond_signal(&g_lr.cv);
        }
    }
    pthread_mutex_unlock(&g_lr.mtx);
    return total_written;
#else
    (void)pcm; (void)num_stereo_frames;
    return 0;
#endif
}

LR_EXPORT int lightrecorder_stop(void) {
#ifdef __ANDROID__
    if (!g_lr.active) return -1;

    pthread_mutex_lock(&g_lr.mtx);
    g_lr.stopping = 1;
    pthread_cond_broadcast(&g_lr.cv);
    pthread_cond_broadcast(&g_lr.space_cv);
    pthread_mutex_unlock(&g_lr.mtx);

    if (g_lr.worker_running) {
        pthread_join(g_lr.worker, NULL);
        g_lr.worker_running = 0;
    }

    if (g_lr.use_pbo && g_lr.pbos[0] != 0) {
        glBindBuffer(LR_GL_PIXEL_PACK_BUFFER, 0);
        glDeleteBuffers(LR_PBO_COUNT, g_lr.pbos);
        memset(g_lr.pbos, 0, sizeof(g_lr.pbos));
    }

    if (g_lr.v_codec) {
        AMediaCodec_stop(g_lr.v_codec);
        AMediaCodec_delete(g_lr.v_codec);
        g_lr.v_codec = NULL;
    }
    if (g_lr.a_codec) {
        AMediaCodec_stop(g_lr.a_codec);
        AMediaCodec_delete(g_lr.a_codec);
        g_lr.a_codec = NULL;
    }

    int saved_ok = (g_lr.muxer_started && g_lr.encoded_frames > 0 && g_lr.error_code == 0);
    if (g_lr.muxer) {
        if (g_lr.muxer_started) {
            if (AMediaMuxer_stop(g_lr.muxer) != AMEDIA_OK) {
                saved_ok = 0;
            }
        }
        AMediaMuxer_delete(g_lr.muxer);
        g_lr.muxer = NULL;
    }

    lr_free_early_pkts(&g_lr);

    if (g_lr.fd >= 0) {
        fsync(g_lr.fd);
        close(g_lr.fd);
        g_lr.fd = -1;
    }

    if (!saved_ok && g_lr.path[0]) {
        unlink(g_lr.path);
    }

    for (int i = 0; i < LR_VIDEO_RING; i++) {
        free(g_lr.v_ring[i].rgba);
    }
    free(g_lr.yuv_buf);
    free(g_lr.a_fifo);
    free(g_lr.gl_scratch);

    pthread_cond_destroy(&g_lr.space_cv);
    pthread_cond_destroy(&g_lr.cv);
    pthread_mutex_destroy(&g_lr.mtx);

    uint64_t total_frames = g_lr.encoded_frames;
    LR_LOGI("Stopped H.264 MP4 recording saved=%d frames=%llu dropped=%llu path=%s",
            saved_ok, (unsigned long long)total_frames,
            (unsigned long long)g_lr.dropped_frames, g_lr.path);

    memset(&g_lr, 0, sizeof(g_lr));
    return saved_ok ? (int)(total_frames > 0x7FFFFFFF ? 0x7FFFFFFF : total_frames) : -2;
#else
    return -1;
#endif
}
