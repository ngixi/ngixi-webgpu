const std = @import("std");
const win32 = @import("win32").everything;
const App = @import("../app.zig").App;
const Window = @import("../window.zig").Window;
const WindowOptions = @import("../window.zig").WindowOptions;
const GraphicsContext = @import("../graphics.zig").GraphicsContext;
const Color = @import("../graphics.zig").Color;
const Event = @import("../event.zig").Event;
const array_list = @import("std").array_list;

// Windows-specific implementations
pub const WindowsApp = struct {
    allocator: std.mem.Allocator,
    windows: array_list.AlignedManaged(*WindowsWindow, null),
    running: bool,
    
    const Self = @This();
    
    pub fn create(allocator: std.mem.Allocator) !*WindowsApp {
        const app = try allocator.create(WindowsApp);
        app.* = WindowsApp{
            .allocator = allocator,
            .windows = array_list.AlignedManaged(*WindowsWindow, null).init(allocator),
            .running = false,
        };
        return app;
    }
    
    pub fn createWindow(self: *WindowsApp, options: WindowOptions) App.Error!Window {
        const window = WindowsWindow.create(self.allocator, options) catch return App.Error.WindowCreationFailed;
        self.windows.append(window) catch return App.Error.OutOfMemory;
        return window.toInterface();
    }
    
    pub fn run(self: *WindowsApp) i32 {
        self.running = true;
        
        // Show all windows
        for (self.windows.items) |w| {
            w.show();
        }
        
        // Run message loop
        var msg: win32.MSG = undefined;
        while (self.running and win32.GetMessageW(&msg, null, 0, 0) > 0) {
            _ = win32.TranslateMessage(&msg);
            _ = win32.DispatchMessageW(&msg);
        }
        
        return @intCast(msg.wParam);
    }
    
    pub fn quit(self: *WindowsApp) void {
        self.running = false;
        win32.PostQuitMessage(0);
    }
    
    pub fn deinit(self: *WindowsApp) void {
        for (self.windows.items) |w| {
            w.deinit();
        }
        self.windows.deinit();
        self.allocator.destroy(self);
    }
    
    pub fn toInterface(self: *WindowsApp) App {
        return App{
            .ptr = self,
            .vtable = &.{
                .createWindow = createWindowImpl,
                .run = runImpl,
                .quit = quitImpl,
                .getAllocator = getAllocatorImpl,
                .deinit = deinitImpl,
            },
        };
    }
    
    fn createWindowImpl(app_ptr: *anyopaque, options: WindowOptions) App.Error!Window {
        const app = @as(*WindowsApp, @alignCast(@ptrCast(app_ptr)));
        return app.createWindow(options);
    }
    
    fn runImpl(app_ptr: *anyopaque) i32 {
        const app = @as(*WindowsApp, @alignCast(@ptrCast(app_ptr)));
        return app.run();
    }
    
    fn quitImpl(app_ptr: *anyopaque) void {
        const app = @as(*WindowsApp, @alignCast(@ptrCast(app_ptr)));
        app.quit();
    }
    
    fn getAllocatorImpl(app_ptr: *anyopaque) std.mem.Allocator {
        const app = @as(*WindowsApp, @alignCast(@ptrCast(app_ptr)));
        return app.allocator;
    }
    
    fn deinitImpl(app_ptr: *anyopaque) void {
        const app = @as(*WindowsApp, @alignCast(@ptrCast(app_ptr)));
        app.deinit();
    }
};

pub const WindowsWindow = struct {
    hwnd: win32.HWND,
    title: []u8,
    width: i32,
    height: i32,
    event_handler: ?*const fn (window: *Window, event: Event) void,
    allocator: std.mem.Allocator,
    
    const Self = @This();
    
    pub fn create(allocator: std.mem.Allocator, options: WindowOptions) !*WindowsWindow {
        const instance = win32.GetModuleHandleW(null);
        
        // Generate a unique class name
        const class_name = win32.L("ZephyrWindow");
        
        const wc = win32.WNDCLASSW{
            .style = .{ .HREDRAW = 1, .VREDRAW = 1 },
            .lpfnWndProc = windowProc,
            .cbClsExtra = 0,
            .cbWndExtra = @sizeOf(usize),
            .hInstance = instance,
            .hIcon = null,
            .hCursor = win32.LoadCursorW(null, win32.IDC_ARROW),
            .hbrBackground = null,
            .lpszMenuName = win32.L(""),
            .lpszClassName = class_name,
        };
        
        if (0 == win32.RegisterClassW(&wc)) {
            return error.RegisterClassFailed;
        }
        
        // Convert title to UTF-16
        var title_buf: [256:0]u16 = std.mem.zeroes([256:0]u16);
        const title_utf16 = std.unicode.utf8ToUtf16Le(title_buf[0..255], options.title) catch return error.InvalidTitle;
        _ = title_utf16;
        
        const window_style = if (options.resizable) 
            win32.WS_OVERLAPPEDWINDOW 
        else 
            @as(win32.WINDOW_STYLE, @bitCast(@as(u32, @bitCast(win32.WS_OVERLAPPED)) | @as(u32, @bitCast(win32.WS_CAPTION)) | @as(u32, @bitCast(win32.WS_SYSMENU))));
        
        const x = if (options.x == -1) win32.CW_USEDEFAULT else options.x;
        const y = if (options.y == -1) win32.CW_USEDEFAULT else options.y;
        
        const hwnd = win32.CreateWindowExW(
            .{},
            class_name,
            &title_buf,
            window_style,
            x,
            y,
            options.width,
            options.height,
            null,
            null,
            instance,
            null,
        ) orelse return error.CreateWindowFailed;
        
        const window = try allocator.create(WindowsWindow);
        window.* = WindowsWindow{
            .hwnd = hwnd,
            .title = try allocator.dupe(u8, options.title),
            .width = options.width,
            .height = options.height,
            .event_handler = null,
            .allocator = allocator,
        };
        
        // Store window pointer in window data
        _ = win32.SetWindowLongPtrW(hwnd, win32.GWLP_USERDATA, @intCast(@intFromPtr(window)));
        
        return window;
    }
    
    pub fn show(self: *WindowsWindow) void {
        _ = win32.ShowWindow(self.hwnd, win32.SW_SHOWNORMAL);
        _ = win32.UpdateWindow(self.hwnd);
    }
    
    pub fn hide(self: *WindowsWindow) void {
        _ = win32.ShowWindow(self.hwnd, win32.SW_HIDE);
    }
    
    pub fn close(self: *WindowsWindow) void {
        _ = win32.DestroyWindow(self.hwnd);
        // If this was the last window, quit the app
        // This will be handled by the app checking window count
    }
    
    pub fn setTitle(self: *WindowsWindow, title: []const u8) void {
        var title_buf: [256:0]u16 = std.mem.zeroes([256:0]u16);
        const title_utf16 = std.unicode.utf8ToUtf16Le(title_buf[0..255], title) catch return;
        _ = title_utf16;
        _ = win32.SetWindowTextW(self.hwnd, &title_buf);
        
        // Update stored title
        self.allocator.free(self.title);
        self.title = self.allocator.dupe(u8, title) catch return;
    }
    
    pub fn getTitle(self: *WindowsWindow, allocator: std.mem.Allocator) ![]u8 {
        return allocator.dupe(u8, self.title);
    }
    
    pub fn setSize(self: *WindowsWindow, width: i32, height: i32) void {
        _ = win32.SetWindowPos(self.hwnd, null, 0, 0, width, height, .{ .NOMOVE = 1, .NOZORDER = 1 });
        self.width = width;
        self.height = height;
    }
    
    pub fn getSize(self: *WindowsWindow) Window.Size {
        return .{ .width = self.width, .height = self.height };
    }
    
    pub fn setPosition(self: *WindowsWindow, x: i32, y: i32) void {
        _ = win32.SetWindowPos(self.hwnd, null, x, y, 0, 0, .{ .NOSIZE = 1, .NOZORDER = 1 });
    }
    
    pub fn getPosition(self: *WindowsWindow) Window.Position {
        var rect: win32.RECT = undefined;
        _ = win32.GetWindowRect(self.hwnd, &rect);
        return .{ .x = rect.left, .y = rect.top };
    }
    
    pub fn beginPaint(self: *WindowsWindow) GraphicsContext {
        const ctx = WindowsGraphicsContext.create(self.hwnd);
        return ctx.toInterface();
    }
    
    pub fn endPaint(self: *WindowsWindow, ctx: GraphicsContext) void {
        _ = self;
        ctx.deinit();
    }
    
    pub fn invalidate(self: *WindowsWindow) void {
        _ = win32.InvalidateRect(self.hwnd, null, 1);
    }
    
    pub fn setEventHandler(self: *WindowsWindow, handler: ?*const fn (window: *Window, event: Event) void) void {
        self.event_handler = handler;
    }
    
    pub fn getNativeHandle(self: *WindowsWindow) *anyopaque {
        return @ptrCast(self.hwnd);
    }
    
    pub fn deinit(self: *WindowsWindow) void {
        self.allocator.free(self.title);
        self.allocator.destroy(self);
        
        // Notify the app that a window was destroyed
        // This is a bit hacky, but we need to find the app instance
        // For now, we'll handle this in the window procedure
    }
    
    pub fn toInterface(self: *WindowsWindow) Window {
        return Window{
            .ptr = self,
            .vtable = &.{
                .show = showImpl,
                .hide = hideImpl,
                .close = closeImpl,
                .setTitle = setTitleImpl,
                .getTitle = getTitleImpl,
                .setSize = setSizeImpl,
                .getSize = getSizeImpl,
                .setPosition = setPositionImpl,
                .getPosition = getPositionImpl,
                .beginPaint = beginPaintImpl,
                .endPaint = endPaintImpl,
                .invalidate = invalidateImpl,
                .setEventHandler = setEventHandlerImpl,
                .getNativeHandle = getNativeHandleImpl,
                .deinit = deinitImpl,
            },
        };
    }
    
    // VTable implementations
    fn showImpl(window_ptr: *anyopaque) void {
        const window = @as(*WindowsWindow, @alignCast(@ptrCast(window_ptr)));
        window.show();
    }
    
    fn hideImpl(window_ptr: *anyopaque) void {
        const window = @as(*WindowsWindow, @alignCast(@ptrCast(window_ptr)));
        window.hide();
    }
    
    fn closeImpl(window_ptr: *anyopaque) void {
        const window = @as(*WindowsWindow, @alignCast(@ptrCast(window_ptr)));
        window.close();
    }
    
    fn setTitleImpl(window_ptr: *anyopaque, title: []const u8) void {
        const window = @as(*WindowsWindow, @alignCast(@ptrCast(window_ptr)));
        window.setTitle(title);
    }
    
    fn getTitleImpl(window_ptr: *anyopaque, allocator: std.mem.Allocator) std.mem.Allocator.Error![]u8 {
        const window = @as(*WindowsWindow, @alignCast(@ptrCast(window_ptr)));
        return window.getTitle(allocator);
    }
    
    fn setSizeImpl(window_ptr: *anyopaque, width: i32, height: i32) void {
        const window = @as(*WindowsWindow, @alignCast(@ptrCast(window_ptr)));
        window.setSize(width, height);
    }
    
    fn getSizeImpl(window_ptr: *anyopaque) Window.Size {
        const window = @as(*WindowsWindow, @alignCast(@ptrCast(window_ptr)));
        return window.getSize();
    }
    
    fn setPositionImpl(window_ptr: *anyopaque, x: i32, y: i32) void {
        const window = @as(*WindowsWindow, @alignCast(@ptrCast(window_ptr)));
        window.setPosition(x, y);
    }
    
    fn getPositionImpl(window_ptr: *anyopaque) Window.Position {
        const window = @as(*WindowsWindow, @alignCast(@ptrCast(window_ptr)));
        return window.getPosition();
    }
    
    fn beginPaintImpl(window_ptr: *anyopaque) GraphicsContext {
        const window = @as(*WindowsWindow, @alignCast(@ptrCast(window_ptr)));
        return window.beginPaint();
    }
    
    fn endPaintImpl(window_ptr: *anyopaque, ctx: GraphicsContext) void {
        const window = @as(*WindowsWindow, @alignCast(@ptrCast(window_ptr)));
        window.endPaint(ctx);
    }
    
    fn invalidateImpl(window_ptr: *anyopaque) void {
        const window = @as(*WindowsWindow, @alignCast(@ptrCast(window_ptr)));
        window.invalidate();
    }
    
    fn setEventHandlerImpl(window_ptr: *anyopaque, handler: ?*const fn (window: *Window, event: Event) void) void {
        const window = @as(*WindowsWindow, @alignCast(@ptrCast(window_ptr)));
        window.setEventHandler(handler);
    }
    
    fn getNativeHandleImpl(window_ptr: *anyopaque) *anyopaque {
        const window = @as(*WindowsWindow, @alignCast(@ptrCast(window_ptr)));
        return window.getNativeHandle();
    }
    
    fn deinitImpl(window_ptr: *anyopaque) void {
        const window = @as(*WindowsWindow, @alignCast(@ptrCast(window_ptr)));
        window.deinit();
    }
    
    fn windowProc(hwnd: win32.HWND, uMsg: u32, wParam: win32.WPARAM, lParam: win32.LPARAM) callconv(.winapi) win32.LRESULT {
        const window_ptr = win32.GetWindowLongPtrW(hwnd, win32.GWLP_USERDATA);
        const window: ?*WindowsWindow = if (window_ptr != 0) @ptrFromInt(@as(usize, @intCast(window_ptr))) else null;
        
        if (window) |w| {
            if (w.event_handler) |handler| {
                const event = translateWin32Event(uMsg, wParam, lParam);
                if (event) |e| {
                    var window_interface = w.toInterface();
                    handler(&window_interface, e);
                }
            }
        }
        
        switch (uMsg) {
            win32.WM_DESTROY => {
                // Post quit message when window is destroyed
                win32.PostQuitMessage(0);
            },
            else => {},
        }
        
        return win32.DefWindowProcW(hwnd, uMsg, wParam, lParam);
    }
};

pub const WindowsGraphicsContext = struct {
    hwnd: win32.HWND,
    hdc: win32.HDC,
    ps: win32.PAINTSTRUCT,
    
    pub fn create(hwnd: win32.HWND) *WindowsGraphicsContext {
        var ps: win32.PAINTSTRUCT = undefined;
        const hdc = win32.BeginPaint(hwnd, &ps) orelse unreachable;
        
        const ctx = std.heap.c_allocator.create(WindowsGraphicsContext) catch unreachable;
        ctx.* = WindowsGraphicsContext{
            .hwnd = hwnd,
            .hdc = hdc,
            .ps = ps,
        };
        return ctx;
    }
    
    pub fn clear(self: *WindowsGraphicsContext, color: Color) void {
        const brush = win32.createSolidBrush(color.toU32());
        defer win32.deleteObject(brush);
        win32.fillRect(self.hdc, self.ps.rcPaint, brush);
    }
    
    pub fn drawText(self: *WindowsGraphicsContext, text: []const u8, x: i32, y: i32, color: Color) void {
        _ = win32.SetTextColor(self.hdc, color.toU32());
        _ = win32.SetBkMode(self.hdc, win32.TRANSPARENT);
        win32.textOutA(self.hdc, x, y, text);
    }
    
    pub fn drawRect(self: *WindowsGraphicsContext, x: i32, y: i32, width: i32, height: i32, color: Color) void {
        const brush = win32.createSolidBrush(color.toU32());
        defer win32.deleteObject(brush);
        
        const rect = win32.RECT{
            .left = x,
            .top = y,
            .right = x + width,
            .bottom = y + height,
        };
        
        _ = win32.FillRect(self.hdc, &rect, brush);
    }
    
    pub fn drawLine(self: *WindowsGraphicsContext, x1: i32, y1: i32, x2: i32, y2: i32, color: Color) void {
        const pen = win32.CreatePen(win32.PS_SOLID, 1, color.toU32()) orelse return;
        defer win32.deleteObject(pen);
        
        if (win32.SelectObject(self.hdc, pen)) |old_pen| {
            defer _ = win32.SelectObject(self.hdc, old_pen);
            
            _ = win32.MoveToEx(self.hdc, x1, y1, null);
            _ = win32.LineTo(self.hdc, x2, y2);
        }
    }
    
    pub fn setClipRect(self: *WindowsGraphicsContext, x: i32, y: i32, width: i32, height: i32) void {
        const rect = win32.RECT{
            .left = x,
            .top = y,
            .right = x + width,
            .bottom = y + height,
        };
        _ = win32.SelectClipRgn(self.hdc, win32.CreateRectRgnIndirect(&rect));
    }
    
    pub fn resetClipRect(self: *WindowsGraphicsContext) void {
        _ = win32.SelectClipRgn(self.hdc, null);
    }
    
    pub fn deinit(self: *WindowsGraphicsContext) void {
        _ = win32.EndPaint(self.hwnd, &self.ps);
        std.heap.c_allocator.destroy(self);
    }
    
    pub fn toInterface(self: *WindowsGraphicsContext) GraphicsContext {
        return GraphicsContext{
            .ptr = self,
            .vtable = &.{
                .clear = clearImpl,
                .drawText = drawTextImpl,
                .drawRect = drawRectImpl,
                .drawLine = drawLineImpl,
                .setClipRect = setClipRectImpl,
                .resetClipRect = resetClipRectImpl,
                .deinit = deinitImpl,
            },
        };
    }
    
    // VTable implementations
    fn clearImpl(ctx_ptr: *anyopaque, color: Color) void {
        const ctx = @as(*WindowsGraphicsContext, @alignCast(@ptrCast(ctx_ptr)));
        ctx.clear(color);
    }
    
    fn drawTextImpl(ctx_ptr: *anyopaque, text: []const u8, x: i32, y: i32, color: Color) void {
        const ctx = @as(*WindowsGraphicsContext, @alignCast(@ptrCast(ctx_ptr)));
        ctx.drawText(text, x, y, color);
    }
    
    fn drawRectImpl(ctx_ptr: *anyopaque, x: i32, y: i32, width: i32, height: i32, color: Color) void {
        const ctx = @as(*WindowsGraphicsContext, @alignCast(@ptrCast(ctx_ptr)));
        ctx.drawRect(x, y, width, height, color);
    }
    
    fn drawLineImpl(ctx_ptr: *anyopaque, x1: i32, y1: i32, x2: i32, y2: i32, color: Color) void {
        const ctx = @as(*WindowsGraphicsContext, @alignCast(@ptrCast(ctx_ptr)));
        ctx.drawLine(x1, y1, x2, y2, color);
    }
    
    fn setClipRectImpl(ctx_ptr: *anyopaque, x: i32, y: i32, width: i32, height: i32) void {
        const ctx = @as(*WindowsGraphicsContext, @alignCast(@ptrCast(ctx_ptr)));
        ctx.setClipRect(x, y, width, height);
    }
    
    fn resetClipRectImpl(ctx_ptr: *anyopaque) void {
        const ctx = @as(*WindowsGraphicsContext, @alignCast(@ptrCast(ctx_ptr)));
        ctx.resetClipRect();
    }
    
    fn deinitImpl(ctx_ptr: *anyopaque) void {
        const ctx = @as(*WindowsGraphicsContext, @alignCast(@ptrCast(ctx_ptr)));
        ctx.deinit();
    }
};

fn translateWin32Event(uMsg: u32, wParam: win32.WPARAM, lParam: win32.LPARAM) ?Event {
    switch (uMsg) {
        win32.WM_CLOSE => return Event.close,
        win32.WM_DESTROY => return Event{ .close = {} },
        win32.WM_PAINT => {
            // We don't know the size here, will be filled by beginPaint
            return Event{ .paint = .{ .width = 0, .height = 0 } };
        },
        win32.WM_SIZE => {
            const width = win32.loword(@as(u32, @intCast(lParam)));
            const height = win32.hiword(@as(u32, @intCast(lParam)));
            return Event{ .resize = .{ .width = @intCast(width), .height = @intCast(height) } };
        },
        win32.WM_KEYDOWN => {
            const key = @as(u32, @intCast(wParam));
            return Event{ .key_down = .{ .key = @enumFromInt(key) } };
        },
        win32.WM_KEYUP => {
            const key = @as(u32, @intCast(wParam));
            return Event{ .key_up = .{ .key = @enumFromInt(key) } };
        },
        win32.WM_LBUTTONDOWN => {
            const x = win32.loword(@as(u32, @intCast(lParam)));
            const y = win32.hiword(@as(u32, @intCast(lParam)));
            return Event{ .mouse_down = .{ .button = .left, .x = @intCast(x), .y = @intCast(y) } };
        },
        win32.WM_LBUTTONUP => {
            const x = win32.loword(@as(u32, @intCast(lParam)));
            const y = win32.hiword(@as(u32, @intCast(lParam)));
            return Event{ .mouse_up = .{ .button = .left, .x = @intCast(x), .y = @intCast(y) } };
        },
        win32.WM_MOUSEMOVE => {
            const x = win32.loword(@as(u32, @intCast(lParam)));
            const y = win32.hiword(@as(u32, @intCast(lParam)));
            return Event{ .mouse_move = .{ .x = @intCast(x), .y = @intCast(y) } };
        },
        win32.WM_DPICHANGED => {
            // TODO: Get actual DPI from hwnd
            return Event{ .dpi_changed = .{ .dpi = 96 } };
        },
        else => return null,
    }
}

pub fn createApp(allocator: std.mem.Allocator) !App {
    const app = try WindowsApp.create(allocator);
    return app.toInterface();
}