const std = @import("std");
const ma = @import("ma");

fn sineSample(phase: f64, amplitude: f64) f64 {
    return std.math.sin(std.math.tau * phase) * amplitude;
}

const Playback = struct {
    phase: f64 = 0.0,
};

fn fillAudio(
    device: [*c]ma.ma_device,
    output: ?*anyopaque,
    _: ?*const anyopaque,
    frame_count: ma.ma_uint32,
) callconv(.c) void {
    const samples: [*]f32 = @ptrCast(@alignCast(output orelse return));
    const state: *Playback = @ptrCast(@alignCast(device[0].pUserData.?));
    const sample_rate: f64 = @floatFromInt(device[0].sampleRate);
    const phase_step: f64 = 440.0 / sample_rate;

    for (samples[0..frame_count]) |*sample| {
        sample.* = @floatCast(sineSample(state.phase, 0.05));

        const next_phase = state.phase + phase_step;
        state.phase = if (next_phase >= 1.0) next_phase - 1.0 else next_phase;
    }
}

pub fn main(init: std.process.Init) !void {
    var state: Playback = .{};
    var config = ma.ma_device_config_init(ma.ma_device_type_playback);
    config.playback.format = ma.ma_format_f32;
    config.playback.channels = 1;
    config.sampleRate = 48_000;
    config.dataCallback = fillAudio;
    config.pUserData = &state;

    var device: ma.ma_device = undefined;
    const init_result = ma.ma_device_init(null, &config, &device);
    if (init_result != ma.MA_SUCCESS) {
        std.debug.print("ma_device_init: {d}\n", .{init_result});
        return error.AudioDeviceInitFailed;
    }
    defer ma.ma_device_uninit(&device);

    const start_result = ma.ma_device_start(&device);
    if (start_result != ma.MA_SUCCESS) {
        std.debug.print("ma_device_start: {d}\n", .{start_result});
        return error.AudioDeviceStartFailed;
    }

    try std.Io.sleep(init.io, .fromSeconds(10), .awake);
}
