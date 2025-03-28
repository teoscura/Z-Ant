const std = @import("std");

pub const math_handler = @import("math_handler.zig");
pub const shape_handler = @import("shape_handler.zig");
pub const parameters = @import("parameters.zig");
pub const predict = @import("predict.zig");
pub const skeleton = @import("skeleton.zig");
pub const globals = @import("globals.zig");
pub const tests = @import("tests.zig");
pub const utils = @import("utils.zig");

// import di zant
const zant = @import("zant");
const onnx = zant.onnx;
const Tensor = zant.core.tensor.Tensor;
const tensorMath = zant.core.tensor.math_standard;
const allocator = zant.utils.allocator.allocator;

pub const CodeGenOptions = struct {
    model_name: [:0]const u8,
    model_path: [:0]const u8,
    user_tests: [:0]const u8,
    log: bool,
    comm: bool,
    shape: [:0]const u8,
    type: [:0]const u8,
};

pub fn main() !void {
    const test_options = CodeGenOptions{
        .model_name = "mnist-8",
        .model_path = "datasets/models/debug_model/debug_model.onnx",
        .user_tests = "",
        .log = false,
        .comm = false,
        .shape = "",
        .type = "f32",
    };
    try run(test_options);
}

pub fn run(options: CodeGenOptions) !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const gpa_allocator = gpa.allocator();

    var model = try onnx.parseFromFile(gpa_allocator, options.model_path);
    defer model.deinit(gpa_allocator);

    //onnx.printStructure(&model);

    // Create the generated model directory if not present
    const generated_path = try std.fmt.allocPrint(gpa_allocator, "generated/{s}/", .{options.model_name});
    defer gpa_allocator.free(generated_path);
    //const generated_path = "src/codeGen/";
    try std.fs.cwd().makePath(generated_path);

    // ONNX model parsing
    try globals.setGlobalAttributes(model, options);

    model.print();

    //DEBUG
    //utils.printTensorHashMap(tensorHashMap);

    //DEBUG
    //try utils.printOperations(model.graph.?);

    //DEBUG
    //try utils.printNodeList(readyGraph);

    //////////////////////////////////////////

    // Create the code for the model
    try skeleton.writeZigFile(options.model_name, generated_path, model, true, options);

    // Test the generated code
    try tests.writeTestFile(options.model_name, generated_path, options);
}
