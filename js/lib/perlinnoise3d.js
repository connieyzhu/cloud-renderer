class PerlinNoise3D {
    constructor() {
      this.permutation = [];
      this.grad3 = [
        [1, 1, 0], [-1, 1, 0], [1, -1, 0], [-1, -1, 0],
        [1, 0, 1], [-1, 0, 1], [1, 0, -1], [-1, 0, -1],
        [0, 1, 1], [0, -1, 1], [0, 1, -1], [0, -1, -1]
      ];
  
      // Initialize permutation and duplicate it
      for (let i = 0; i < 256; i++) {
        this.permutation.push(i);
      }
  
      this.permutation.sort(() => Math.random() - 0.5);
      this.permutation = this.permutation.concat(this.permutation);
    }
  
    dot(g, x, y, z) {
      return g[0] * x + g[1] * y + g[2] * z;
    }
  
    fade(t) {
      return t * t * t * (t * (t * 6 - 15) + 10);
    }
  
    lerp(t, a, b) {
      return a + t * (b - a);
    }
  
    noise(x, y, z) {
      // Find unit cube containing point
      const X = Math.floor(x) & 255;
      const Y = Math.floor(y) & 255;
      const Z = Math.floor(z) & 255;
  
      // Relative coordinates of point within cube
      x -= Math.floor(x);
      y -= Math.floor(y);
      z -= Math.floor(z);
  
      // Compute fade curves for each coordinate
      const u = this.fade(x);
      const v = this.fade(y);
      const w = this.fade(z);
  
      // Hash coordinates of the cube corners
      const A = this.permutation[X] + Y;
      const AA = this.permutation[A] + Z;
      const AB = this.permutation[A + 1] + Z;
      const B = this.permutation[X + 1] + Y;
      const BA = this.permutation[B] + Z;
      const BB = this.permutation[B + 1] + Z;
  
      // Add blended results from the corners
      const gradAA = this.grad3[this.permutation[AA] % 12];
      const gradBA = this.grad3[this.permutation[BA] % 12];
      const gradAB = this.grad3[this.permutation[AB] % 12];
      const gradBB = this.grad3[this.permutation[BB] % 12];
  
      const gradAA1 = this.grad3[this.permutation[AA + 1] % 12];
      const gradBA1 = this.grad3[this.permutation[BA + 1] % 12];
      const gradAB1 = this.grad3[this.permutation[AB + 1] % 12];
      const gradBB1 = this.grad3[this.permutation[BB + 1] % 12];
  
      const x1 = this.lerp(u,
        this.dot(gradAA, x, y, z),
        this.dot(gradBA, x - 1, y, z)
      );
      const x2 = this.lerp(u,
        this.dot(gradAB, x, y - 1, z),
        this.dot(gradBB, x - 1, y - 1, z)
      );
  
      const y1 = this.lerp(v, x1, x2);
  
      const x3 = this.lerp(u,
        this.dot(gradAA1, x, y, z - 1),
        this.dot(gradBA1, x - 1, y, z - 1)
      );
      const x4 = this.lerp(u,
        this.dot(gradAB1, x, y - 1, z - 1),
        this.dot(gradBB1, x - 1, y - 1, z - 1)
      );
  
      const y2 = this.lerp(v, x3, x4);
  
      return this.lerp(w, y1, y2);
    }
}
  
  export default PerlinNoise3D