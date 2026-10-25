// Patched: the published iOS glue was generated for flutter_rust_bridge v1
// (wire_read, drop_dart_object, ...), but the prebuilt libaudiotags.a it
// downloads is built with flutter_rust_bridge v2 and exports different
// symbols, so the app failed to link. This references the v2 exports instead
// so the linker keeps them for Dart FFI to look up at runtime. Only the
// addresses are used, so the signatures are intentionally opaque.
#include <stdint.h>

void frb_get_rust_content_hash(void);
void frb_pde_ffi_dispatcher_primary(void);
void frb_pde_ffi_dispatcher_sync(void);
void frb_dart_fn_deliver_output(void);
void frb_dart_opaque_dart2rust_encode(void);
void frb_dart_opaque_drop_thread_box_persistent_handle(void);
void frb_dart_opaque_rust2dart_decode(void);
void frb_free_wire_sync_rust2dart_dco(void);
void frb_free_wire_sync_rust2dart_sse(void);
void frb_init_frb_dart_api_dl(void);
void frb_rust_vec_u8_free(void);
void frb_rust_vec_u8_new(void);
void frb_rust_vec_u8_resize(void);
void store_dart_post_cobject(void);
void free_zero_copy_buffer_f32(void);
void free_zero_copy_buffer_f64(void);
void free_zero_copy_buffer_i8(void);
void free_zero_copy_buffer_i16(void);
void free_zero_copy_buffer_i32(void);
void free_zero_copy_buffer_i64(void);
void free_zero_copy_buffer_u8(void);
void free_zero_copy_buffer_u16(void);
void free_zero_copy_buffer_u32(void);
void free_zero_copy_buffer_u64(void);

static int64_t dummy_method_to_enforce_bundling(void) {
    int64_t dummy_var = 0;
    dummy_var ^= ((int64_t) (void*) frb_get_rust_content_hash);
    dummy_var ^= ((int64_t) (void*) frb_pde_ffi_dispatcher_primary);
    dummy_var ^= ((int64_t) (void*) frb_pde_ffi_dispatcher_sync);
    dummy_var ^= ((int64_t) (void*) frb_dart_fn_deliver_output);
    dummy_var ^= ((int64_t) (void*) frb_dart_opaque_dart2rust_encode);
    dummy_var ^= ((int64_t) (void*) frb_dart_opaque_drop_thread_box_persistent_handle);
    dummy_var ^= ((int64_t) (void*) frb_dart_opaque_rust2dart_decode);
    dummy_var ^= ((int64_t) (void*) frb_free_wire_sync_rust2dart_dco);
    dummy_var ^= ((int64_t) (void*) frb_free_wire_sync_rust2dart_sse);
    dummy_var ^= ((int64_t) (void*) frb_init_frb_dart_api_dl);
    dummy_var ^= ((int64_t) (void*) frb_rust_vec_u8_free);
    dummy_var ^= ((int64_t) (void*) frb_rust_vec_u8_new);
    dummy_var ^= ((int64_t) (void*) frb_rust_vec_u8_resize);
    dummy_var ^= ((int64_t) (void*) store_dart_post_cobject);
    dummy_var ^= ((int64_t) (void*) free_zero_copy_buffer_f32);
    dummy_var ^= ((int64_t) (void*) free_zero_copy_buffer_f64);
    dummy_var ^= ((int64_t) (void*) free_zero_copy_buffer_i8);
    dummy_var ^= ((int64_t) (void*) free_zero_copy_buffer_i16);
    dummy_var ^= ((int64_t) (void*) free_zero_copy_buffer_i32);
    dummy_var ^= ((int64_t) (void*) free_zero_copy_buffer_i64);
    dummy_var ^= ((int64_t) (void*) free_zero_copy_buffer_u8);
    dummy_var ^= ((int64_t) (void*) free_zero_copy_buffer_u16);
    dummy_var ^= ((int64_t) (void*) free_zero_copy_buffer_u32);
    dummy_var ^= ((int64_t) (void*) free_zero_copy_buffer_u64);
    return dummy_var;
}
