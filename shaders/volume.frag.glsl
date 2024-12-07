#version 300 es

// Fragment shaders don't have a default precision so we need
// to pick one. mediump is a good default. It means "medium precision".
precision mediump float;
precision mediump sampler3D;

#define EPSILON 0.001

in vec4 v_worldSpaceCoord;
in mat4x4 v_m;
in mat4x4 v_v;
in mat4x4 v_p;

// with webgl 2, we now have to define an out that will be the color of the fragment
out vec4 o_fragColor;

uniform vec3 u_eye;
uniform vec3 u_lightPos;
uniform uint u_frame;
uniform float u_near;
uniform float u_far;

uniform sampler2D u_colorTexture;
uniform sampler3D u_noiseTexture;

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

float easeOutExpo(in float x) {
    return clamp(1.0f - pow(2.0f, -30.0f * x), 0.0f, 1.0f);
}

float densityremap(in float d) {
    return easeOutExpo(d) * 2.0f;
}

// temporary density sdf
float density(in vec3 p, in vec3 offset) {
    if (outofbounds(p)) {
        return 0.0;
    }
    return densityremap(perlin3d(p + offset, 1.0, 1, 6, 0.5, 2.0));
}

// temporary density sdf
float density(in vec3 p) {
    return density(p, vec3(0));
}

// transfer function density -> color rgb
vec3 transfer(in float x) {
    x = easeOutExpo(x);
    return mix(vec3(0), vec3(1), x);
}

vec3 march(in vec3 ro, in vec3 rd, in vec3 l, in vec3 offset, in int stepCount, in float stepSize, in float maxDepth, in vec3 maxColor) {
    float depth = 0.0;
    float cumTransmittance = 1.0f;
    vec3 cumColor = vec3(0.0f);
    for (int i = 0; i < stepCount; ++i) {
        bool terminate = false;

        vec3 p = ro + rd * depth;
        float d = density(p, offset);

        float attenuation = exp(-d * stepSize);
        vec3 color = transfer(d);
        if (-(v_v * vec4(p, 1.0f)).z >= maxDepth) {
            attenuation = 1.0f;
            color = maxColor;
            terminate = true;
        }

        const float lStepSize = 0.1f;
        const int lStepCount = 5;
        float ldepth = 0.0f;
        float lCumTransmittance = 1.0f;
        for (int i = 0; i < lStepCount; ++i) {
            vec3 lp = p + l * ldepth;
            float ld = density(lp, offset);

            float lAttenuation = exp(-ld * lStepSize);
            if (outofbounds(lp)) lAttenuation = 1.0f;

            lCumTransmittance *= lAttenuation;
            ldepth += lStepSize;
        }

        cumColor += cumTransmittance * color * (1.0f - attenuation) * lCumTransmittance;
        cumTransmittance *= attenuation;
        depth += stepSize;

        if (outofbounds(p)) terminate = true;
        if (cumTransmittance <= 0.01f) terminate = true;

        if (terminate) break;
    }
    return vec3(cumColor + cumTransmittance * maxColor);
}

void main() {
    vec3 rd = normalize(v_worldSpaceCoord.xyz - u_eye);
    vec3 ro = v_worldSpaceCoord.xyz;

    vec4 sscoord4 = v_p * v_v * v_m * v_worldSpaceCoord;
    vec2 sscoord = (sscoord4.xy / sscoord4.w) * 0.5f + 0.5f;
    vec4 background = texture(u_colorTexture, sscoord);
    float viewDepth = background.a * (u_far - u_near) + u_near;
    
    vec3 marchColor = march(ro, rd, normalize(vec3(1.0f, 1.0f, 0.0f)), vec3(0.005f, 0.001f, 0.0f) * float(u_frame), 200, 0.01, viewDepth, background.rgb);

    o_fragColor = vec4(marchColor, 1.0f);
}