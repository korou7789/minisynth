const std = @import("std");
const ma = @import("ma");

fn sineSample(n: usize, sample_rate: f64, frequency: f64, amplitude: f64) f64 {
    const sample_index: f64 = @floatFromInt(n);
    const elapsed_seconds = sample_index / sample_rate;
    return std.math.sin(std.math.tau * elapsed_seconds * frequency) * amplitude;
}

const Playback = struct {
    next_sample: usize = 0,
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

    for (samples[0..frame_count]) |*sample| {
        sample.* = @floatCast(sineSample(state.next_sample, sample_rate, 440.0, 0.05));
        state.next_sample += 1;
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
