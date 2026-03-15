const std = @import("std");

const CHESS_TEST_TARGETS: []const []const u8 = &.{
    "src/chess/tests/board_tests.zig",
};

const ENGINE_TEST_TARGETS: []const []const u8 = &.{};

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const chess_mod = b.createModule(.{
        .root_source_file = b.path("src/chess/root.zig"),
        .target = target,
        .optimize = optimize,
    });

    const engine_mod = b.createModule(.{
        .root_source_file = b.path("src/engine/root.zig"),
        .target = target,
        .optimize = optimize,
        .imports = &.{.{ .name = "chess", .module = chess_mod }},
    });

    const root_mod = b.createModule(.{
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
        .imports = &.{
            .{ .name = "engine", .module = engine_mod },
            .{ .name = "chess", .module = chess_mod },
        },
    });

    const exe = b.addExecutable(.{ .name = "fear", .root_module = root_mod });
    b.installArtifact(exe);

    const run_exe = b.addRunArtifact(exe);
    const run_step = b.step("run", "Run the application");
    run_step.dependOn(&run_exe.step);

    const test_step = b.step("test", "Run unit tests");

    for (CHESS_TEST_TARGETS) |test_tg| {
        const unit_tests = b.addTest(.{
            .root_module = b.createModule(.{
                .root_source_file = b.path(test_tg),
                .imports = &.{.{ .name = "chess", .module = chess_mod }},
                .target = target,
            }),
        });

        const run_unit_tests = b.addRunArtifact(unit_tests);
        test_step.dependOn(&run_unit_tests.step);
    }

    for (ENGINE_TEST_TARGETS) |test_tg| {
        const unit_tests = b.addTest(.{
            .root_module = b.createModule(.{
                .root_source_file = b.path(test_tg),
                .imports = &.{.{ .name = "engine", .module = engine_mod }},
                .target = target,
            }),
        });

        const run_unit_tests = b.addRunArtifact(unit_tests);
        test_step.dependOn(&run_unit_tests.step);
    }
}
