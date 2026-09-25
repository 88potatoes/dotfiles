//! N-API addon exposing the Zig ports of pi-tui's hot text functions.
//! Built with: zig build-lib -dynamic (see build.sh)

const std = @import("std");
const c = @cImport({
    @cInclude("node_api.h");
});
const impl = @import("tui_width.zig");

fn argStr(env: c.napi_env, argv: []c.napi_value, idx: usize) ?[]u8 {
    if (idx >= argv.len) return null;
    var len: usize = 0;
    if (c.napi_get_value_string_utf8(env, argv[idx], null, 0, &len) != c.napi_ok) return null;
    const buf = std.heap.c_allocator.alloc(u8, len + 1) catch return null;
    if (c.napi_get_value_string_utf8(env, argv[idx], buf.ptr, len + 1, &len) != c.napi_ok) {
        std.heap.c_allocator.free(buf);
        return null;
    }
    return buf[0..len];
}

fn makeString(env: c.napi_env, s: []const u8) ?c.napi_value {
    var out: c.napi_value = null;
    if (c.napi_create_string_utf8(env, s.ptr, @intCast(s.len), &out) != c.napi_ok) return null;
    return out;
}

// --- extractAnsiCode(str, pos): JS-index-aware, returns {code, length} | null ---
fn napiAnsiCodeAt(env: c.napi_env, info: c.napi_callback_info) callconv(.c) c.napi_value {
    var argc: usize = 2;
    var argv: [2]c.napi_value = undefined;
    if (c.napi_get_cb_info(env, info, &argc, &argv, null, null) != c.napi_ok) return null;
    const str = argStr(env, &argv, 0) orelse return null;
    var pos: u32 = 0;
    if (argc > 1) {
        if (c.napi_get_value_uint32(env, argv[1], &pos) != c.napi_ok) return null;
    }
    const bytePos = impl.u16PosToByte(str, pos);
    var result: c.napi_value = null;
    if (impl.ansiCodeAt(str, bytePos)) |len| {
        const code = str[bytePos .. bytePos + len];
        var obj: c.napi_value = null;
        if (c.napi_create_object(env, &obj) != c.napi_ok) return null;
        const codeVal = makeString(env, code) orelse return null;
        var lenVal: c.napi_value = null;
        // length in UTF-16 units (ASCII sequences: same as bytes)
        if (c.napi_create_uint32(env, @intCast(u16Len(code)), &lenVal) != c.napi_ok) return null;
        _ = c.napi_set_named_property(env, obj, "code", codeVal);
        _ = c.napi_set_named_property(env, obj, "length", lenVal);
        result = obj;
    } else {
        if (c.napi_get_null(env, &result) != c.napi_ok) return null;
    }
    return result;
}

fn u16Len(s: []const u8) usize {
    var units: usize = 0;
    var i: usize = 0;
    while (i < s.len) {
        const b = s[i];
        if (b < 0x80) {
            i += 1;
            units += 1;
        } else if (b < 0xf0) {
            i += @min(2, s.len - i);
            units += 1;
        } else {
            i += @min(4, s.len - i);
            units += 2;
        }
    }
    return units;
}

// --- visibleWidth(str): width | -1 (fallback) ---
fn napiVisibleWidth(env: c.napi_env, info: c.napi_callback_info) callconv(.c) c.napi_value {
    var argc: usize = 1;
    var argv: [1]c.napi_value = undefined;
    if (c.napi_get_cb_info(env, info, &argc, &argv, null, null) != c.napi_ok) return null;
    const str = argStr(env, &argv, 0) orelse return null;
    var out: c.napi_value = null;
    if (c.napi_create_int32(env, impl.visibleWidth(str), &out) != c.napi_ok) return null;
    return out;
}

// --- graphemeWidth(segment): width | -1 (fallback) ---
fn napiGraphemeWidth(env: c.napi_env, info: c.napi_callback_info) callconv(.c) c.napi_value {
    var argc: usize = 1;
    var argv: [1]c.napi_value = undefined;
    if (c.napi_get_cb_info(env, info, &argc, &argv, null, null) != c.napi_ok) return null;
    const str = argStr(env, &argv, 0) orelse return null;
    var out: c.napi_value = null;
    if (c.napi_create_int32(env, impl.graphemeWidth(str), &out) != c.napi_ok) return null;
    return out;
}

// --- splitIntoTokensWithAnsi(text): string[] | null (fallback) ---
fn napiSplitTokens(env: c.napi_env, info: c.napi_callback_info) callconv(.c) c.napi_value {
    var argc: usize = 1;
    var argv: [1]c.napi_value = undefined;
    if (c.napi_get_cb_info(env, info, &argc, &argv, null, null) != c.napi_ok) return null;
    const str = argStr(env, &argv, 0) orelse return null;
    var result: c.napi_value = null;

    if (impl.splitIntoTokensWithAnsi(std.heap.c_allocator, str)) |tokens| {
        if (c.napi_create_array(env, &result) != c.napi_ok) return null;
        for (tokens.items, 0..) |tok, i| {
            const val = makeString(env, tok) orelse return null;
            if (c.napi_set_element(env, result, @intCast(i), val) != c.napi_ok) return null;
        }
    } else {
        if (c.napi_get_null(env, &result) != c.napi_ok) return null;
    }
    return result;
}

/// Node calls this symbol to register the module.
export fn napi_register_module_v1(env: c.napi_env, exports: c.napi_value) c.napi_value {
    const fns = [_]struct { name: [*:0]const u8, fnptr: c.napi_callback }{
        .{ .name = "visibleWidth", .fnptr = napiVisibleWidth },
        .{ .name = "graphemeWidth", .fnptr = napiGraphemeWidth },
        .{ .name = "ansiCodeAt", .fnptr = napiAnsiCodeAt },
        .{ .name = "splitIntoTokensWithAnsi", .fnptr = napiSplitTokens },
    };
    for (fns) |f| {
        var fnval: c.napi_value = null;
        if (c.napi_create_function(env, f.name, @intCast(std.mem.len(f.name)), f.fnptr, null, &fnval) != c.napi_ok) {
            return exports;
        }
        _ = c.napi_set_named_property(env, exports, f.name, fnval);
    }
    return exports;
}