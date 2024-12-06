#version 300 es

// an attribute will receive data from a buffer
in vec3 a_position;
in vec3 a_normal;
in vec3 a_tangent;
in vec2 a_texture_coord;

// transformation matrices
uniform mat4x4 u_m;
uniform mat4x4 u_v;
uniform mat4x4 u_p;

// output to fragment stage
// TODO: Create varyings to pass data to the fragment stage (position, texture coords, and more)
out vec3 v_position;
out vec3 v_normal;
out vec3 v_tangent;
out vec3 v_bitangent;
out vec2 v_tex_coord;
out mat3 v_tbn;

void main() {

    // transform a vertex from object space directly to screen space
    // the full chain of transformations is:
    // object space -{model}-> world space -{view}-> view space -{projection}-> clip space
    vec4 vertex_position_world = u_m * vec4(a_position, 1.0);
    vec3 normal_world = normalize(vec3(u_m * vec4(a_normal, 0.0)));
    vec3 tangent_world = normalize(vec3(u_m * vec4(a_tangent, 0.0)));
    tangent_world = normalize(tangent_world - dot(tangent_world, normal_world) * normal_world);
    vec3 bitangent_world = cross(normal_world, tangent_world);

    // TODO: Construct TBN matrix from normals, tangents and bitangents
    // TODO: Use the Gram-Schmidt process to re-orthogonalize tangents
    // NOTE: Different from the book, try to do all calculations in world space using the TBN to transform normals
    // HINT: Refer to https://learnopengl.com/Advanced-Lighting/Normal-Mapping for all above
    mat3 tbn = mat3(tangent_world, bitangent_world, normal_world);

    // TODO: Forward data to fragment stage
    v_position = vertex_position_world.xyz;
    v_normal = normal_world;
    v_tangent = tangent_world;
    v_bitangent = bitangent_world;
    v_tex_coord = a_texture_coord;
    v_tbn = tbn;

    gl_Position = u_p * u_v * vertex_position_world;

}