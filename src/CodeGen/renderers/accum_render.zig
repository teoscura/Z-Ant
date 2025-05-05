const std = @import("std");
const zant = @import("zant");
const UOp = zant.uops.UOp;
const DTypeInfo = zant.uops.DTypeInfo;

pub fn render(
    allocator: std.mem.Allocator,
    writer: anytype,
    uop: UOp,
    ptr_map: *const std.AutoHashMap(usize, []const u8),
) !void {
    _ = allocator;
    if (uop.op != .DEFINE_ACC and uop.op != .MULACC){
        return error.InvalidOperation;
    }

    const type_str = DTypeInfo.asString(uop.dtype);

    switch (uop.op) {
        .DEFINE_ACC => {
            const acc_name = ptr_map.get(uop.id) orelse return error.VariableNotFound;
            try writer.print("var {s}: {s} = 0;\n", .{ acc_name, type_str });
        },
        .MULACC => {
            if(uop.src.len != 3) return error.InvalidOperandCount;
            const acc_name = ptr_map.get(uop.src[0]) orelse return error.VariableNotFound;
            const a_name = ptr_map.get(uop.src[1]) orelse return error.VariableNotFound;
            const b_name = ptr_map.get(uop.src[2]) orelse return error.VariableNotFound;
            try writer.print("{s}[0] += {s}[0]*{s}[0]\n", .{ acc_name, a_name, b_name});
        },
        else => unreachable,
    }
}
