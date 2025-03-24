const std = @import("std");
const zant = @import("zant");
const pkgAllocator = zant.utils.allocator;
const allocator = pkgAllocator.allocator;

const onnx = zant.onnx;
const codeGen = @import("codegen");

pub fn main() !void {
    {
        // Trim whitespace from the line.
        const trimmed_line = std.mem.trim(u8, raw_line, " \t\r\n");
        if (trimmed_line.len > 0) {
            std.debug.print("Operation: {s}\n", .{trimmed_line});
        }

        // Construct the model file path: "Phython-ONNX/{op}_0.onnx"
        const model_path = "/Users/curtisdas/Progetto di ingegneria informatica/Z-Ant-GUI/datasets/models/debug_model";
        std.debug.print("model_path : {s}", .{model_path});

        // Load the model.
        var model = try onnx.parseFromFile(allocator, model_path);

        //Printing the model:
        //DEBUG
        model.print();

        std.debug.print("\n CODEGENERATING {s} ...", .{model_path});

        // Create the generated model directory if not present
        const generated_path = try std.fmt.allocPrint(allocator, "generated/oneOpModels/{s}/", .{trimmed_line});
        defer allocator.free(generated_path);
        try std.fs.cwd().makePath(generated_path);

        // CORE PART -------------------------------------------------------
        // ONNX model parsing
        try codeGen.globals.setGlobalAttributes(model);

        // Create the code for the model
        try codeGen.skeleton.writeZigFile(trimmed_line, generated_path, model, false);

        // Create relative tests
        try codeGen.tests.writeSlimTestFile(trimmed_line, generated_path);

        // Copy user test file into the generated test file
        const dataset_test_model_path = try std.fmt.allocPrint(allocator, "datasets/oneOpModels/{s}_0_user_tests.json", .{trimmed_line});
        defer allocator.free(dataset_test_model_path);

        const generated_test_model_path = try std.fmt.allocPrint(allocator, "generated/oneOpModels/{s}/user_tests.json", .{trimmed_line});
        defer allocator.free(generated_test_model_path);

        try codeGen.utils.copyFile(dataset_test_model_path, generated_test_model_path);
        std.debug.print("Written user test for {s}", .{trimmed_line});

        // Add relative one op test to global tests file
        try test_oneop_writer.print("\t _ = @import(\"{s}/test_{s}.zig\"); \n", .{ trimmed_line, trimmed_line });

        //try codeGen.globals.setGlobalAttributes(model);
        model.deinit(allocator);
    }

    // Adding last global test line
    try test_oneop_writer.writeAll("} \n\n");
}
