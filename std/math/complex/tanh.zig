const std = @import("../../index.zig");
const debug = std.debug;
const math = std.math;
const cmath = math.complex;
const Complex = cmath.Complex;

pub fn tanh(z: var) Complex(@typeOf(z.re)) {
    const T = @typeOf(z.re);
    return switch (T) {
        f32 => tanh32(z),
        f64 => tanh64(z),
        else => @compileError("tan not implemented for " ++ @typeName(z)),
    };
}

fn tanh32(z: *const Complex(f32)) Complex(f32) {
    const x = z.re;
    const y = z.im;

    const hx = @bitCast(u32, x);
    const ix = hx & 0x7fffffff;

    if (ix >= 0x7f800000) {
        if (ix & 0x7fffff != 0) {
            const r = if (y == 0) y else x * y;
            return Complex(f32).new(x, r);
        }
        const xx = @bitCast(f32, hx - 0x40000000);
        const r = if (math.isInf(y)) y else math.sin(y) * math.cos(y);
        return Complex(f32).new(xx, math.copysign(f32, 0, r));
    }

    if (!math.isFinite(y)) {
        const r = if (ix != 0) y - y else x;
        return Complex(f32).new(r, y - y);
    }

    // x >= 11
    if (ix >= 0x41300000) {
        const exp_mx = math.exp(-math.fabs(x));
        return Complex(f32).new(math.copysign(f32, 1, x), 4 * math.sin(y) * math.cos(y) * exp_mx * exp_mx);
    }

    // Kahan's algorithm
    const t = math.tan(y);
    const beta = 1.0 + t * t;
    const s = math.sinh(x);
    const rho = math.sqrt(1 + s * s);
    const den = 1 + beta * s * s;

    return Complex(f32).new((beta * rho * s) / den, t / den);
}

fn tanh64(z: *const Complex(f64)) Complex(f64) {
    const x = z.re;
    const y = z.im;

    const fx = @bitCast(u64, x);
    const hx = u32(fx >> 32);
    const lx = @truncate(u32, fx);
    const ix = hx & 0x7fffffff;

    if (ix >= 0x7ff00000) {
        if ((ix & 0x7fffff) | lx != 0) {
            const r = if (y == 0) y else x * y;
            return Complex(f64).new(x, r);
        }

        const xx = @bitCast(f64, (u64(hx - 0x40000000) << 32) | lx);
        const r = if (math.isInf(y)) y else math.sin(y) * math.cos(y);
        return Complex(f64).new(xx, math.copysign(f64, 0, r));
    }

    if (!math.isFinite(y)) {
        const r = if (ix != 0) y - y else x;
        return Complex(f64).new(r, y - y);
    }

    // x >= 22
    if (ix >= 0x40360000) {
        const exp_mx = math.exp(-math.fabs(x));
        return Complex(f64).new(math.copysign(f64, 1, x), 4 * math.sin(y) * math.cos(y) * exp_mx * exp_mx);
    }

    // Kahan's algorithm
    const t = math.tan(y);
    const beta = 1.0 + t * t;
    const s = math.sinh(x);
    const rho = math.sqrt(1 + s * s);
    const den = 1 + beta * s * s;

    return Complex(f64).new((beta * rho * s) / den, t / den);
}

const epsilon = 0.0001;

test "complex.ctanh32" {
    const a = Complex(f32).new(5, 3);
    const c = tanh(a);

    debug.assert(math.approxEq(f32, c.re, 0.999913, epsilon));
    debug.assert(math.approxEq(f32, c.im, -0.000025, epsilon));
}

test "complex.ctanh64" {
    const a = Complex(f64).new(5, 3);
    const c = tanh(a);

    debug.assert(math.approxEq(f64, c.re, 0.999913, epsilon));
    debug.assert(math.approxEq(f64, c.im, -0.000025, epsilon));
}
