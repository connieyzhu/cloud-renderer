'use strict'

import { Object3D } from './object3d.js'

class Volume extends Object3D {
    /**
     * Creates a 3D box from 8 vertices and draws it as a line mesh
     * @param {WebGL2RenderingContext} gl The webgl2 rendering context
     * @param {Shader} shader The shader to be used to draw the object
     */
    constructor(gl, shader, box_scale = [1, 1, 1]) {
        const vertices = [
            // Front face
            -1.0, -1.0,  1.0, // Bottom-left
             1.0, -1.0,  1.0, // Bottom-right
             1.0,  1.0,  1.0, // Top-right
            -1.0,  1.0,  1.0, // Top-left
        
            // Back face
            -1.0, -1.0, -1.0, // Bottom-left
            -1.0,  1.0, -1.0, // Top-left
             1.0,  1.0, -1.0, // Top-right
             1.0, -1.0, -1.0, // Bottom-right
        
            // Top face
            -1.0,  1.0, -1.0, // Top-left (back)
            -1.0,  1.0,  1.0, // Top-left (front)
             1.0,  1.0,  1.0, // Top-right (front)
             1.0,  1.0, -1.0, // Top-right (back)
        
            // Bottom face
            -1.0, -1.0, -1.0, // Bottom-left (back)
             1.0, -1.0, -1.0, // Bottom-right (back)
             1.0, -1.0,  1.0, // Bottom-right (front)
            -1.0, -1.0,  1.0, // Bottom-left (front)
        
            // Right face
             1.0, -1.0, -1.0, // Bottom-left
             1.0,  1.0, -1.0, // Top-left
             1.0,  1.0,  1.0, // Top-right
             1.0, -1.0,  1.0, // Bottom-right
        
            // Left face
            -1.0, -1.0, -1.0, // Bottom-left
            -1.0, -1.0,  1.0, // Bottom-right
            -1.0,  1.0,  1.0, // Top-right
            -1.0,  1.0, -1.0, // Top-left
        ];        

        for (let i = 0; i < vertices.length; i++) {
            vertices[i] = vertices[i] * box_scale[i % 3];
        }

        const indices = [
            // Front face
            0,  1,  2,
            0,  2,  3,
        
            // Back face
            4,  5,  6,
            4,  6,  7,
        
            // Top face
            8,  9, 10,
            8, 10, 11,
        
            // Bottom face
            12, 13, 14,
            12, 14, 15,
        
            // Right face
            16, 17, 18,
            16, 18, 19,
        
            // Left face
            20, 21, 22,
            20, 22, 23
        ];

        super(gl, shader, vertices, indices, gl.TRIANGLES);
    }

    renderVolume(gl) {
        gl.disable(gl.DEPTH_TEST);
        gl.enable(gl.BLEND);
        gl.blendFunc(gl.SRC_ALPHA, gl.ONE_MINUS_SRC_ALPHA);

        this.render(gl);

        gl.enable(gl.DEPTH_TEST);
        gl.disable(gl.BLEND);
    }
    
    update() {
        // update volume uniforms
        return;
    }
}

export default Volume
