const std = @import("std");
const zant = @import("zant");

const Tensor = zant.core.tensor.Tensor;
const tensorMath = zant.core.tensor.math_standard;
const onnx = zant.onnx;
const ModelOnnx = onnx.ModelProto;
const DataType = onnx.DataType;
const TensorProto = onnx.TensorProto;
const allocator = zant.utils.allocator.allocator;
const codegen = @import("codegen.zig");
const codeGenInitializers = codegen.parameters;
const coddeGenPredict = codegen.predict;
const CodeGenOptions = codegen.CodeGenOptions;

/// Writes a Zig source file containing the generated code for an ONNX model.
///
/// This function generates the necessary Zig code to initialize tensors and
/// define the prediction logic based on the given ONNX model.
///
/// # Parameters
/// - `file`: The file where the generated Zig code will be written.
/// - `model`: The ONNX model from which to generate the Zig code.
///
/// # Errors
/// This function may return an error if writing to the file fails.
pub fn writeZigFile(model_name: []const u8, model_path: []const u8, model: ModelOnnx, do_export: bool, options: CodeGenOptions) !void {

    //initializing writer for lib_operation file
    const lib_file_path = try std.fmt.allocPrint(allocator, "{s}lib_{s}.zig", .{ model_path, model_name });
    defer allocator.free(lib_file_path);
    var lib_file = try std.fs.cwd().createFile(lib_file_path, .{});
    std.debug.print("\n .......... file created, path:{s}", .{lib_file_path});
    defer lib_file.close();

    const lib_writer = lib_file.writer();

    //initializing writer for static_parameters file
    const params_file_path = try std.fmt.allocPrint(allocator, "{s}static_parameters.zig", .{model_path});
    defer allocator.free(params_file_path);
    var param_file = try std.fs.cwd().createFile(params_file_path, .{});
    std.debug.print("\n .......... file created, path:{s}", .{params_file_path});
    defer param_file.close();

    const param_writer = param_file.writer();

    // Write the necessary library imports to the generated Zig file
    try write_libraries(lib_writer);

    if (options.log) {
        //log function setting
        try write_logFunction(lib_writer);
    }

    //Fixed Buffer Allocator
    try write_FBA(lib_writer);

    try write_type_T(lib_writer);

    // Generate tensor initialization code in the static_parameters.zig file
    try codeGenInitializers.write_parameters(param_writer, model);

    // Generate prediction function code
    try coddeGenPredict.writePredict(lib_writer, do_export, options);
}

/// Writes the required library imports to the generated Zig file for predict function.
///
/// This function ensures that the necessary standard and package libraries are
/// imported into the generated Zig source file.
///
/// # Parameters
/// - `writer`: A file writer used to write the import statements.
///
/// # Errors
/// This function may return an error if writing to the file fails.
fn write_libraries(writer: std.fs.File.Writer) !void {
    _ = try writer.print(
        \\
        \\ const std = @import("std");
        \\ const zant = @import("zant");
        \\ const Tensor = zant.core.tensor.Tensor;
        \\ const tensMath = zant.core.tensor.math_standard;
        \\ const pkgAllocator = zant.utils.allocator;
        \\ const allocator = pkgAllocator.allocator;
        \\ const codegen = @import("codegen");
        \\ const utils = codegen.utils;
        \\ const param_lib = @import("static_parameters.zig");
        \\
    , .{});
}

fn write_logFunction(writer: std.fs.File.Writer) !void {
    _ = try writer.print(
        \\
        \\var log_function: ?*const fn ([*c]u8) callconv(.C) void = null;
        \\
        \\pub export fn setLogFunction(func: ?*const fn ([*c]u8) callconv(.C) void) void {{
        \\    log_function = func;
        \\}}
        \\
    , .{});
}

fn write_FBA(writer: std.fs.File.Writer) !void {
    _ = try writer.print(
        \\
        \\
        \\ var buf: [4096 * 10]u8 = undefined;
        \\ var fba_state = @import("std").heap.FixedBufferAllocator.init(&buf);
        \\ const fba = fba_state.allocator();
    , .{});
}

fn write_type_T(writer: std.fs.File.Writer) !void {
    _ = try writer.print( //TODO: get the type form the onnx model
        \\
        \\ const T = f32;
    , .{});
}
