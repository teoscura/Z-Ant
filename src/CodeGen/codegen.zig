const std = @import("std");

pub const math_handler = @import("math_handler.zig");
pub const shape_handler = @import("shape_handler.zig");
pub const parameters = @import("parameters.zig");
pub const predict = @import("predict.zig");
pub const skeleton = @import("skeleton.zig");
pub const globals = @import("globals.zig");
pub const tests = @import("tests.zig");
pub const utils = @import("utils.zig");
//pub const zant_codegen = @import("main.zig").zant_codegen;

// import di zant dal main
const zant = @import("zant");
const onnx = zant.onnx;
const Tensor = zant.core.tensor.Tensor;
const tensorMath = zant.core.tensor.math_standard;
const allocator = zant.utils.allocator.allocator;

pub const ModelOptions = struct {
    name: ?[:0]const u8,
    path: ?[:0]const u8,
    user_tests: ?[:0]const u8,
    log: ?bool,
    comm: ?bool,
    shape: ?[:0]const u8,
    type: ?[:0]const u8,
};

pub fn main() !void {
    // lancia run
}

pub fn run(model_options: ModelOptions) !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const gpa_allocator = gpa.allocator();

    var model = try onnx.parseFromFile(gpa_allocator, model_options.path);
    defer model.deinit(gpa_allocator);

    //onnx.printStructure(&model);

    // Create the generated model directory if not present
    const generated_path = try std.mem.concat(gpa, u8, &.{ "generated/", model_options.name, "/" });
    //const generated_path = "src/codeGen/";
    try std.fs.cwd().makePath(generated_path);

    // ONNX model parsing
    try globals.setGlobalAttributes(model);

    model.print();

    //DEBUG
    //utils.printTensorHashMap(tensorHashMap);

    //DEBUG
    //try utils.printOperations(model.graph.?);

    //DEBUG
    //try utils.printNodeList(readyGraph);

    //////////////////////////////////////////

    // Create the code for the model
    try skeleton.writeZigFile(model_options.name, model_options.path, model, true);

    // Test the generated code
    try tests.writeTestFile(model_options.name, generated_path);
}
