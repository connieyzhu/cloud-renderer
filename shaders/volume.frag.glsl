#version 300 es

// Fragment shaders don't have a default precision so we need
// to pick one. mediump is a good default. It means "medium precision".
precision mediump float;

#define STEP_SIZE 0.08
#define STEP_COUNT 100
#define EPSILON 0.001

in vec4 v_worldSpaceCoord;

// with webgl 2, we now have to define an out that will be the color of the fragment
out vec4 o_fragColor;

uniform vec3 u_eye;
uniform vec3 u_lightPos;
uniform uint u_frame;

// https://www.shadertoy.com/view/4djSRW
vec4 hash44(in vec4 p4) {
	p4 = fract(p4  * vec4(.1031, .1030, .0973, .1099));
    p4 += dot(p4, p4.wzxy + 33.33);
    return fract((p4.xxyz+p4.yzzw)*p4.zywx);
}

// perlin noise
float perlin3d(in vec3 p, in float scale) {
    p *= scale;
    vec3 floorp = floor(p);
    vec3 fractp = fract(p);

    vec3 t = fractp * fractp * fractp * (fractp * (fractp * 6.0 - 15.0) + 10.0);
    float v000 = dot(normalize(hash44(vec4(floorp.xyz, 1.0) + vec4(0.0, 0.0, 0.0, 0.0)).xyz * 2.0 - 1.0), fractp - vec3(0.0, 0.0, 0.0));
    float v001 = dot(normalize(hash44(vec4(floorp.xyz, 1.0) + vec4(0.0, 0.0, 1.0, 0.0)).xyz * 2.0 - 1.0), fractp - vec3(0.0, 0.0, 1.0));
    float v010 = dot(normalize(hash44(vec4(floorp.xyz, 1.0) + vec4(0.0, 1.0, 0.0, 0.0)).xyz * 2.0 - 1.0), fractp - vec3(0.0, 1.0, 0.0));
    float v011 = dot(normalize(hash44(vec4(floorp.xyz, 1.0) + vec4(0.0, 1.0, 1.0, 0.0)).xyz * 2.0 - 1.0), fractp - vec3(0.0, 1.0, 1.0));
    float v100 = dot(normalize(hash44(vec4(floorp.xyz, 1.0) + vec4(1.0, 0.0, 0.0, 0.0)).xyz * 2.0 - 1.0), fractp - vec3(1.0, 0.0, 0.0));
    float v101 = dot(normalize(hash44(vec4(floorp.xyz, 1.0) + vec4(1.0, 0.0, 1.0, 0.0)).xyz * 2.0 - 1.0), fractp - vec3(1.0, 0.0, 1.0));
    float v110 = dot(normalize(hash44(vec4(floorp.xyz, 1.0) + vec4(1.0, 1.0, 0.0, 0.0)).xyz * 2.0 - 1.0), fractp - vec3(1.0, 1.0, 0.0));
    float v111 = dot(normalize(hash44(vec4(floorp.xyz, 1.0) + vec4(1.0, 1.0, 1.0, 0.0)).xyz * 2.0 - 1.0), fractp - vec3(1.0, 1.0, 1.0));
    return mix(
               mix(mix(v000, v100, t.x), mix(v010, v110, t.x), t.y), 
               mix(mix(v001, v101, t.x), mix(v011, v111, t.x), t.y), 
               t.z);
}

// fractal brownian motion
float perlin3d(in vec3 p, in float scale, in int frequency, in int octaves, in float persistence, in float lacunarity) {
    float v = 0.0;
    float a = 1.0;
    float f = float(frequency);
    for (int i = 0; i < octaves; ++i) {
        v += perlin3d(p * f, scale) * a;
        a *= persistence;
        f *= lacunarity;
    }
    return v;
}

bool outofbounds(in vec3 p) {
    return p.x < -1.0 || p.x > 1.0 || p.y < -1.0 || p.y > 1.0 || p.z < -1.0 || p.z > 1.0;
}

// temporary density sdf
float density(in vec3 p, in vec3 offset) {
    if (outofbounds(p)) {
        return 0.0;
    }
    return perlin3d(p + offset, 1.0, 1, 6, 0.5, 2.0);
}

// temporary density sdf
float density(in vec3 p) {
    return density(p, vec3(0));
}

// transfer function density -> color rgb
vec3 transfer(in float d) {
    return mix(vec3(0), vec3(1), d);
}

vec3 march(in vec3 ro, in vec3 rd, in vec3 l, in vec3 offset) {
    float depth = 0.0;
    vec4 color = vec4(0.0);
    for (int i = 0; i < STEP_COUNT; ++i) {
        vec3 p = ro + rd * depth;
        float d = density(p, offset);
        float ld = density(p + normalize(p - l) * EPSILON, offset);
        if (d > 0.0) {
            float dif = clamp((ld - d) / EPSILON, 0.0, 1.0);
            vec4 c = vec4(transfer(d), d);
            c.rgb *= dif;
            c += vec4(0.2f, 0.2f, 0.2f, 0.0);
            c.rgb *= c.a; // treat density as alpha
            color += c * (1.0 - color.a);

            // bounding box
            if (outofbounds(p)) {
                break;
            }
        }
        depth += STEP_SIZE;
    }
    return clamp(color, 0.0, 1.0).rgb;
}

vec3 march(in vec3 ro, in vec3 rd, in vec3 l) {
    return march(ro, rd, l, vec3(0.0));
}

void main() {
    // fract(gl_FragCoord.w / STEP_SIZE - length(v_worldSpaceCoord.xyz - u_eye)) * STEP_SIZE;

    vec3 vd = normalize(-u_eye);
    vec3 rd = normalize(v_worldSpaceCoord.xyz - u_eye);
    vec3 ro = v_worldSpaceCoord.xyz;
    rd *= 1.0 / dot(rd, vd); // align samples with view
    o_fragColor = vec4(march(ro, rd, u_lightPos, vec3(0.005, 0.001, 0) * float(u_frame)), 1.0);
    // o_fragColor = vec4(1.0f, 0.0f, 0.0f, 0.1f);
}