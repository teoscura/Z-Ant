const std = @import("std");
const dvui = @import("dvui");
const WebBackend = dvui.backend;
const entypo = dvui.entypo;

const orange = dvui.Color{ .r = 255, .g = 165, .b = 0, .a = 255 };
const darkorange = dvui.Color{ .r = 172, .g = 99, .b = 22, .a = 255 };
const hoverorange = dvui.Color{ .r = 235, .g = 227, .b = 213, .a = 255 };
const lightorange = dvui.Color{ .r = 255, .g = 246, .b = 229, .a = 255 };

const zant_icon = @embedFile("zant-icon.png");

const Page = enum {
    home,
    select_model,
    generating_code,
    deploy_options,
    generating_library,
};
var page: Page = .home;

var filepath: ?[:0]const u8 = null;
var filename: ?[:0]const u8 = null;

const ModelOptions = enum(u8) { default, debug_model, mnist_1, mnist_8, sentiment, wake_word, custom };
var model_options: ModelOptions = @enumFromInt(0);
const model_length = @typeInfo(ModelOptions).@"enum".fields.len;

fn pathToFileName(fp: ?[:0]const u8) [:0]const u8 {
    if (fp == null or fp.?.len == 0) return "";
    const path = fp.?;
    var last_slash: usize = 0;
    for (path, 0..) |c, i| {
        if (c == '/' or c == '\\') {
            last_slash = i + 1;
        }
    }
    return path[last_slash..];
}

fn isOnnx(fp: ?[:0]const u8) bool {
    if (fp) |path| {
        const extension: []const u8 = ".onnx";
        if (path.len >= extension.len) {
            return std.mem.endsWith(u8, path, extension);
        }
    }
    return false;
}

fn getModelString(value: ModelOptions) []const u8 {
    return switch (value) {
        .default => "",
        .debug_model => "Debug Model",
        .mnist_1 => "MNIST-1",
        .mnist_8 => "MNIST-8",
        .sentiment => "Sentiment",
        .wake_word => "Wake Word",
        .custom => {
            if (filename) |name| {
                return name;
            } else {
                return "Not Selected";
            }
        },
    };
}

fn getModelPath(value: ModelOptions) []const u8 {
    return switch (value) {
        .default => "",
        .debug_model => "datasets/models/debug_model/debug_model.onnx",
        .mnist_1 => "datasets/models/mnist-1/mnist-1.onnx",
        .mnist_8 => "datasets/models/mnist-8/mnist-8.onnx",
        .sentiment => "datasets/models/Sentiment/sentiment_analysis_it.onnx",
        .wake_word => "datasets/models/wakeWord/wakeWord.onnx",
        .custom => {
            if (filepath) |fp| {
                return fp;
            } else {
                return "";
            }
        },
    };
}

pub fn pageHome() !void {
    {
        var vbox0 = try dvui.box(@src(), .vertical, .{ .gravity_x = 0.5, .gravity_y = 0.4 });
        defer vbox0.deinit();

        var heading = try dvui.textLayout(@src(), .{}, .{
            .background = false,
            .margin = .{ .h = 20.0 },
        });
        try heading.addText("Z-Ant Simplifies the Deployment\nand Optimization of Neural Networks\non Microprocessors", .{ .font_style = .title });
        heading.deinit();

        if (try (dvui.button(@src(), "Get Started", .{}, .{ .gravity_x = 0.5, .padding = dvui.Rect.all(15) }))) {
            page = .select_model;
        }
    }

    var footer = try dvui.textLayout(@src(), .{}, .{ .background = false, .gravity_x = 0.5, .gravity_y = 0.8 });
    try footer.addText("Z-Ant is an open-source project powered by Zig\nFor help visit our ", .{});
    footer.deinit();
    if (try footer.addTextClick("GitHub", .{ .color_text = .{ .color = orange } })) {
        try dvui.openURL("https://github.com/ZantFoundation/Z-Ant");
    }
}

pub fn pageSelectModel() !void {
    if (try dvui.buttonIcon(@src(), "back", entypo.chevron_left, .{}, .{ .margin = dvui.Rect.all(15) })) {
        page = .home;
    }

    {
        var vbox = try dvui.box(@src(), .vertical, .{ .gravity_x = 0.5, .gravity_y = 0.3 });
        defer vbox.deinit();

        try dvui.label(@src(), "Select a Model", .{}, .{ .font_style = .title, .margin = .{ .h = 20.0 }, .gravity_x = 0.5 });

        {
            var vbox1 = try dvui.box(@src(), .vertical, .{ .gravity_x = 0.5 });
            defer vbox1.deinit();

            try dvui.label(@src(), "Built in Models", .{}, .{ .font_style = .heading });

            inline for (@typeInfo(ModelOptions).@"enum".fields[1 .. model_length - 1], 0..) |field, i| {
                const enum_value = @as(ModelOptions, @enumFromInt(field.value));
                const display_name = getModelString(enum_value);
                if (try dvui.radio(@src(), model_options == enum_value, display_name, .{ .id_extra = i })) {
                    model_options = enum_value;
                }
            }

            try dvui.label(@src(), "Custom Model", .{}, .{ .font_style = .heading, .margin = .{ .y = 10.0 } });

            if (try dvui.button(@src(), "Open ONNX File", .{}, .{})) {}

            const enum_value = @as(ModelOptions, @enumFromInt(model_length - 1));
            const display_name = getModelString(enum_value);
            if (try dvui.radio(@src(), model_options == enum_value, display_name, .{ .id_extra = model_length - 1 })) {
                model_options = enum_value;
            }

            if (try dvui.button(@src(), "Generate Zig Code", .{}, .{ .gravity_x = 0.5, .margin = .{ .y = 20.0 }, .padding = dvui.Rect.all(15) })) {
                if (std.mem.eql(u8, getModelPath(model_options), "")) {
                    try dvui.dialog(@src(), .{ .modal = true, .title = "Error", .message = "You must select a model" });
                } else {}
            }
        }
    }
}

pub fn pageGeneratingCode() !void {
    if (try dvui.buttonIcon(@src(), "back", entypo.chevron_left, .{}, .{ .margin = dvui.Rect.all(15) })) {
        page = .select_model;
    }
    {
        var vbox = try dvui.box(@src(), .vertical, .{ .gravity_x = 0.5, .gravity_y = 0.4 });
        defer vbox.deinit();

        try dvui.label(@src(), "Generating Zig Code ...", .{}, .{ .font_style = .heading, .margin = .{ .h = 2.0 } });
        try dvui.label(@src(), "Once completed, the code will be avaialbe in ~/generated", .{}, .{ .margin = .{ .h = 10.0 } });

        if (try dvui.button(@src(), "Continue", .{}, .{ .gravity_x = 0.5, .padding = dvui.Rect.all(15) })) {
            page = .deploy_options;
        }
    }
}

var target_cpu_val: usize = 0;
var target_os_val: usize = 0;

pub fn pageDeployOptions() !void {
    if (try dvui.buttonIcon(@src(), "back", entypo.chevron_left, .{}, .{ .margin = dvui.Rect.all(15) })) {
        page = .select_model;
    }
    {
        var vbox = try dvui.box(@src(), .vertical, .{ .gravity_x = 0.5, .gravity_y = 0.3 });
        defer vbox.deinit();

        try dvui.label(@src(), "Deploy Options", .{}, .{ .font_style = .title, .margin = .{ .h = 20.0 }, .gravity_x = 0.5 });

        {
            var vbox1 = try dvui.box(@src(), .vertical, .{ .gravity_x = 0.5 });
            defer vbox1.deinit();

            const target_cpu = [_][]const u8{ "x86_64", "x86", "arm", "aarch64", "riscv32", "riscv64", "powerpc", "powerpc64", "mips32", "mips64", "wasm32", "wasm64", "sparc", "sparc64" };
            const target_os = [_][]const u8{ "Linux", "Windows", "macOS", "Android", "FreeBSD" };

            try dvui.label(@src(), "Target CPU", .{}, .{ .font_style = .heading, .margin = .{ .h = 5.0 } });
            _ = try dvui.dropdown(@src(), &target_cpu, &target_cpu_val, .{ .min_size_content = .{ .w = 150 }, .margin = .{ .h = 15.0 } });

            try dvui.label(@src(), "Target OS", .{}, .{ .font_style = .heading, .margin = .{ .h = 5.0 } });
            _ = try dvui.dropdown(@src(), &target_os, &target_os_val, .{ .min_size_content = .{ .w = 150 }, .margin = .{ .h = 30.0 } });
        }

        if (try dvui.button(@src(), "Generate Static Library", .{}, .{ .gravity_x = 0.5, .padding = dvui.Rect.all(15) })) {
            page = .generating_library;
        }
    }
}

pub fn pageGeneratingLibrary() !void {
    if (try dvui.buttonIcon(@src(), "back", entypo.chevron_left, .{}, .{ .margin = dvui.Rect.all(15) })) {
        page = .deploy_options;
    }
    {
        var vbox = try dvui.box(@src(), .vertical, .{ .gravity_x = 0.5, .gravity_y = 0.4 });
        defer vbox.deinit();

        try dvui.label(@src(), "Generating Static Library ...", .{}, .{ .font_style = .heading, .margin = .{ .h = 2.0 } });
        try dvui.label(@src(), "Once completed, the library will be avaialbe in ~/zig-out", .{}, .{ .margin = .{ .h = 10.0 } });

        if (try dvui.button(@src(), "Conclude", .{}, .{ .gravity_x = 0.5, .padding = dvui.Rect.all(15) })) {
            page = .home;
        }
    }
}

comptime {
    std.debug.assert(@hasDecl(WebBackend, "WebBackend"));
}
usingnamespace WebBackend.wasm;

const WriteError = error{};
const LogWriter = std.io.Writer(void, WriteError, writeLog);

fn writeLog(_: void, msg: []const u8) WriteError!usize {
    WebBackend.wasm.wasm_log_write(msg.ptr, msg.len);
    return msg.len;
}

pub fn logFn(
    comptime message_level: std.log.Level,
    comptime scope: @Type(.enum_literal),
    comptime format: []const u8,
    args: anytype,
) void {
    const level_txt = switch (message_level) {
        .err => "error",
        .warn => "warning",
        .info => "info",
        .debug => "debug",
    };
    const prefix2 = if (scope == .default) ": " else "(" ++ @tagName(scope) ++ "): ";
    const msg = level_txt ++ prefix2 ++ format ++ "\n";

    (LogWriter{ .context = {} }).print(msg, args) catch return;
    WebBackend.wasm.wasm_log_flush();
}

pub const std_options: std.Options = .{
    // Overwrite default log handler
    .logFn = logFn,
};

var gpa_instance = std.heap.GeneralPurposeAllocator(.{}){};
const gpa = gpa_instance.allocator();

var win: dvui.Window = undefined;
var backend: WebBackend = undefined;
var touchPoints: [2]?dvui.Point = [_]?dvui.Point{null} ** 2;
var orig_content_scale: f32 = 1.0;

//const zig_favicon = @embedFile("src/zig-favicon.png");

export fn app_init(platform_ptr: [*]const u8, platform_len: usize) i32 {
    const platform = platform_ptr[0..platform_len];
    dvui.log.debug("platform: {s}", .{platform});
    const mac = if (std.mem.indexOf(u8, platform, "Mac") != null) true else false;

    backend = WebBackend.init() catch {
        return 1;
    };
    win = dvui.Window.init(@src(), gpa, backend.backend(), .{ .keybinds = if (mac) .mac else .windows }) catch {
        return 2;
    };

    WebBackend.win = &win;

    orig_content_scale = win.content_scale;

    return 0;
}

export fn app_deinit() void {
    win.deinit();
    backend.deinit();
}

// return number of micros to wait (interrupted by events) for next frame
// return -1 to quit
export fn app_update() i32 {
    return update() catch |err| {
        std.log.err("{!}", .{err});
        const msg = std.fmt.allocPrint(gpa, "{!}", .{err}) catch "allocPrint OOM";
        WebBackend.wasm.wasm_panic(msg.ptr, msg.len);
        return -1;
    };
}

fn update() !i32 {
    const nstime = win.beginWait(backend.hasEvent());

    try win.begin(nstime);

    // Instead of the backend saving the events and then calling this, the web
    // backend is directly sending the events to dvui
    //try backend.addAllEvents(&win);

    try dvui_frame();
    //try dvui.label(@src(), "test", .{}, .{ .color_text = .{ .color = dvui.Color.white } });

    //var indices: []const u32 = &[_]u32{ 0, 1, 2, 0, 2, 3 };
    //var vtx: []const dvui.Vertex = &[_]dvui.Vertex{
    //    .{ .pos = .{ .x = 100, .y = 150 }, .uv = .{ 0.0, 0.0 }, .col = .{} },
    //    .{ .pos = .{ .x = 200, .y = 150 }, .uv = .{ 1.0, 0.0 }, .col = .{ .g = 0, .b = 0, .a = 200 } },
    //    .{ .pos = .{ .x = 200, .y = 250 }, .uv = .{ 1.0, 1.0 }, .col = .{ .r = 0, .b = 0, .a = 100 } },
    //    .{ .pos = .{ .x = 100, .y = 250 }, .uv = .{ 0.0, 1.0 }, .col = .{ .r = 0, .g = 0 } },
    //};
    //backend.drawClippedTriangles(null, vtx, indices);

    const end_micros = try win.end(.{});

    backend.setCursor(win.cursorRequested());
    backend.textInputRect(win.textInputRequested());

    const wait_event_micros = win.waitTime(end_micros, null);
    return @intCast(@divTrunc(wait_event_micros, 1000));
}

fn dvui_frame() !void {
    {
        var m = try dvui.menu(@src(), .horizontal, .{ .background = true, .color_fill = .{ .color = lightorange }, .expand = .horizontal });
        defer m.deinit();

        const imgsize = try dvui.imageSize("Z-Ant icon", zant_icon);
        try dvui.image(@src(), "Z-Ant icon", zant_icon, .{
            .gravity_y = 0.5,
            .min_size_content = .{ .w = imgsize.w * 0.12, .h = imgsize.h * 0.12 },
            .margin = .{ .x = 20, .y = 10, .h = 10.0, .w = 3.0 },
        });
        try dvui.label(@src(), "Z-Ant", .{}, .{ .gravity_y = 0.5, .font_style = .heading });

        if (try dvui.buttonIcon(@src(), "back", entypo.moon, .{}, .{ .background = false, .gravity_y = 0.5, .gravity_x = 1.0, .margin = .{ .w = 20.0 } })) {
            page = .home;
        }
    }

    var scroll = try dvui.scrollArea(@src(), .{}, .{ .expand = .both, .color_fill = .{ .color = dvui.Color.white } });
    defer scroll.deinit();
    switch (page) {
        .home => try pageHome(),
        .select_model => try pageSelectModel(),
        .generating_code => try pageGeneratingCode(),
        .deploy_options => try pageDeployOptions(),
        .generating_library => try pageGeneratingLibrary(),
    }
}
