const std = @import("std");

// Cross-platform event system
pub const EventType = enum {
    close,
    paint,
    resize,
    key_down,
    key_up,
    mouse_down,
    mouse_up,
    mouse_move,
    mouse_wheel,
    focus_gained,
    focus_lost,
    dpi_changed,
    timer,
    custom,
};

pub const MouseButton = enum {
    left,
    right,
    middle,
    x1,
    x2,
};

pub const KeyCode = enum(u32) {
    // Standard keys
    escape,
    space,
    enter,
    tab,
    backspace,
    delete,
    insert,
    
    // Arrow keys
    left,
    up,
    right,
    down,
    
    // Function keys
    f1,
    f2,
    f3,
    f4,
    f5,
    f6,
    f7,
    f8,
    f9,
    f10,
    f11,
    f12,
    
    // Letters (lowercase codes)
    a,
    b,
    c,
    d,
    e,
    f,
    g,
    h,
    i,
    j,
    k,
    l,
    m,
    n,
    o,
    p,
    q,
    r,
    s,
    t,
    u,
    v,
    w,
    x,
    y,
    z,
    
    // Numbers
    @"0",
    @"1",
    @"2",
    @"3",
    @"4",
    @"5",
    @"6",
    @"7",
    @"8",
    @"9",
    
    // Symbols
    minus,
    equals,
    left_bracket,
    right_bracket,
    backslash,
    semicolon,
    apostrophe,
    comma,
    period,
    slash,
    
    _,
};

pub const Event = union(EventType) {
    close: void,
    paint: PaintEvent,
    resize: ResizeEvent,
    key_down: KeyEvent,
    key_up: KeyEvent,
    mouse_down: MouseEvent,
    mouse_up: MouseEvent,
    mouse_move: MouseMoveEvent,
    mouse_wheel: MouseWheelEvent,
    focus_gained: void,
    focus_lost: void,
    dpi_changed: DpiEvent,
    timer: TimerEvent,
    custom: CustomEvent,
};

pub const PaintEvent = struct {
    width: i32,
    height: i32,
};

pub const ResizeEvent = struct {
    width: i32,
    height: i32,
};

pub const KeyEvent = struct {
    key: KeyCode,
    modifiers: KeyModifiers = .{},
};

pub const MouseEvent = struct {
    button: MouseButton,
    x: i32,
    y: i32,
    modifiers: KeyModifiers = .{},
};

pub const MouseMoveEvent = struct {
    x: i32,
    y: i32,
    modifiers: KeyModifiers = .{},
};

pub const MouseWheelEvent = struct {
    delta: f32,
    x: i32,
    y: i32,
    modifiers: KeyModifiers = .{},
};

pub const DpiEvent = struct {
    dpi: u32,
};

pub const TimerEvent = struct {
    id: u32,
};

pub const CustomEvent = struct {
    id: u32,
    data: ?*anyopaque = null,
};

pub const KeyModifiers = packed struct {
    shift: bool = false,
    ctrl: bool = false,
    alt: bool = false,
    meta: bool = false, // Windows key, Command key, etc.
    
    pub fn any(self: KeyModifiers) bool {
        return self.shift or self.ctrl or self.alt or self.meta;
    }
};