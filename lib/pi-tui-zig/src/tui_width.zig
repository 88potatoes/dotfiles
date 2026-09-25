//! Ports of the four hot functions from pi-tui utils.js:
//!   visibleWidth, graphemeWidth, extractAnsiCode, splitIntoTokensWithAnsi
//!
//! Strategy: byte-exact for printable-ASCII input (with ANSI/OSC/APC
//! sequences), which is what pi renders 99% of the time (styled markdown).
//! Anything requiring Intl.Segmenter / Unicode property tables (CJK, emoji,
//! combining marks) returns a sentinel (-1 / null) so the JS wrapper can fall
//! back to the original TS implementation. Correctness is never traded for speed.

const std = @import("std");
const c_allocator = std.heap.c_allocator;

/// Fallback sentinel values understood by the JS loader.
pub const FALLBACK: i32 = -1;

/// Port of extractAnsiCode(str, pos): byte length of the escape sequence
/// starting at byte offset `pos`, or null. All delimiters are ASCII, and
/// UTF-8 continuation bytes are >= 0x80, so byte scanning is safe.
pub fn ansiCodeAt(str: []const u8, pos: usize) ?usize {
    if (pos >= str.len or str[pos] != 0x1b) return null;
    if (pos + 1 >= str.len) return null;
    const next = str[pos + 1];
    switch (next) {
        '[' => { // CSI: ESC [ ... terminated by m/G/K/H/J
            var j = pos + 2;
            while (j < str.len) : (j += 1) {
                switch (str[j]) {
                    'm', 'G', 'K', 'H', 'J' => return j + 1 - pos,
                    else => {},
                }
            }
            return null;
        },
        ']', '_' => { // OSC/APC: terminated by BEL or ESC backslash
            var j = pos + 2;
            while (j < str.len) : (j += 1) {
                if (str[j] == 0x07) return j + 1 - pos;
                if (str[j] == 0x1b and j + 1 < str.len and str[j + 1] == '\\') return j + 2 - pos;
            }
            return null;
        },
        else => return null,
    }
}

/// Convert a UTF-16 code-unit index (JS string index semantics) to a UTF-8
/// byte offset. Astral codepoints (4-byte UTF-8) count as 2 UTF-16 units,
/// everything else as 1.
pub fn u16PosToByte(str: []const u8, u16pos: usize) usize {
    var units: usize = 0;
    var i: usize = 0;
    while (i < str.len) {
        if (units >= u16pos) return i;
        const b = str[i];
        if (b < 0x80) {
            units += 1;
            i += 1;
        } else if (b < 0xc0) { // continuation byte (invalid start): skip
            i += 1;
        } else if (b < 0xf0) {
            units += 1;
            i += @min(2, str.len - i);
        } else { // astral: 4-byte UTF-8 = 2 UTF-16 units
            units += 2;
            i += @min(4, str.len - i);
        }
    }
    return str.len;
}

fn isPrintableAsciiByte(b: u8) bool {
    return b >= 0x20 and b <= 0x7e;
}

/// Port of visibleWidth(str) fast paths.
/// Returns width, or FALLBACK (-1) when the input needs Intl.Segmenter /
/// Unicode width tables (non-ASCII content).
pub fn visibleWidth(str: []const u8) i32 {
    if (str.len == 0) return 0;

    // Fast path: pure printable ASCII
    var all_ascii = true;
    for (str) |b| {
        if (!isPrintableAsciiByte(b)) {
            all_ascii = false;
            break;
        }
    }
    if (all_ascii) return @intCast(str.len);

    // One pass: skip ANSI/OSC/APC sequences, expand tabs to 3 columns,
    // count remaining codepoints. Bail to fallback on non-ASCII.
    var width: i32 = 0;
    var i: usize = 0;
    while (i < str.len) {
        if (ansiCodeAt(str, i)) |len| {
            i += len;
            continue;
        }
        const b = str[i];
        if (b == '\t') {
            width += 3;
        } else if (b < 0x20 or b == 0x7f) {
            // control char: zero-width in TS after strip/segmentation
            // (C0 controls are in \p{Control} => zero-width clusters)
        } else if (b < 0x80) {
            width += 1;
        } else {
            return FALLBACK; // non-ASCII: defer to TS
        }
        i += 1;
    }
    return width;
}

/// Port of graphemeWidth(segment) fast path.
/// 3 for tab, 1 for printable ASCII, FALLBACK for anything else.
pub fn graphemeWidth(seg: []const u8) i32 {
    if (seg.len == 1) {
        if (seg[0] == '\t') return 3;
        if (isPrintableAsciiByte(seg[0])) return 1;
    }
    for (seg) |b| {
        if (!isPrintableAsciiByte(b)) return FALLBACK;
    }
    return 1;
}

/// Port of splitIntoTokensWithAnsi(text) for printable-ASCII input
/// (grapheme segmentation == per byte; the CJK break regex cannot match ASCII).
/// Returns null when the input contains non-ASCII bytes (caller falls back).
pub fn splitIntoTokensWithAnsi(alloc: std.mem.Allocator, text: []const u8) ?std.ArrayList([]const u8) {
    var tokens = std.ArrayList([]const u8){};
    errdefer tokens.deinit(alloc);
    var current = std.ArrayList(u8){};
    errdefer current.deinit(alloc);
    var pending = std.ArrayList(u8){};
    errdefer pending.deinit(alloc);
    var current_kind: enum { none, space, word } = .none;

    var i: usize = 0;
    while (i < text.len) {
        if (ansiCodeAt(text, i)) |len| {
            pending.appendSlice(alloc, text[i .. i + len]) catch return null;
            i += len;
            continue;
        }
        const b = text[i];
        if (b >= 0x80) return null; // non-ASCII: caller falls back to TS
        const kind: @TypeOf(current_kind) = if (b == ' ') .space else .word;
        if (current.items.len > 0 and current_kind != kind) {
            tokens.append(alloc, current.toOwnedSlice(alloc) catch return null) catch return null;
            current = .{};
        }
        if (pending.items.len > 0) {
            current.appendSlice(alloc, pending.items) catch return null;
            pending.clearRetainingCapacity();
        }
        current_kind = kind;
        current.append(alloc, b) catch return null;
        i += 1;
    }
    // Remaining pending ANSI attaches to the last token, or to current.
    if (pending.items.len > 0) {
        if (current.items.len > 0) {
            current.appendSlice(alloc, pending.items) catch return null;
        } else if (tokens.items.len > 0) {
            const last = tokens.items[tokens.items.len - 1];
            const merged = alloc.alloc(u8, last.len + pending.items.len) catch return null;
            @memcpy(merged[0..last.len], last);
            @memcpy(merged[last.len..], pending.items);
            tokens.items[tokens.items.len - 1] = merged;
        } else {
            current.appendSlice(alloc, pending.items) catch return null;
        }
    }
    if (current.items.len > 0) {
        tokens.append(alloc, current.toOwnedSlice(alloc) catch return null) catch return null;
    }
    return tokens;
}