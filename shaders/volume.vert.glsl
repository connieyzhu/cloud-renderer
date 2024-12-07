#version 300 es

// an attribute will receive data from a buffer
in vec3 a_position;

out vec4 v_worldSpaceCoord;
out mat4x4 v_m;
out mat4x4 v_v;
out mat4x4 v_p;

// transformation matrices
uniform mat4x4 u_m;
uniform mat4x4 u_v;
uniform mat4x4 u_p;

void main() {
    // set a point size for gl.POINTS draw mode
    gl_PointSize = 2.0f;

    // transform a vertex from object space directly to screen space
    // the full chain of transformations is:
    // object space -{model}-> world space -{view}-> view space -{projection}-> clip space

    gl_Position = u_p * u_v * u_m * vec4(a_position, 1.0);

    v_worldSpaceCoord = u_m * vec4(a_position, 1.0f);
    v_m = u_m;
    v_v = u_v;
    v_p = u_p;
}