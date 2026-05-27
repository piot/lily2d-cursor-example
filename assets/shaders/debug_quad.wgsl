//! Debug Quad Shader
//!
//! Minimal 2D quad renderer:
//! - uniform: view_proj matrix
//! - instance buffer: pos, size, color

struct DebugQuadUniform {
 view_proj: mat4x4f,
};

@group(0) @binding(0) var<uniform> debug_quad: DebugQuadUniform;

struct VSOut {
  @builtin(position) position: vec4f,
  @location(0) tint: vec4f,
};

@vertex
fn vs_main(
     // Per-vertex
    @builtin(vertex_index) vertex_index : u32,

    // Per-instance
    @location(0) pos: vec2f,
    @location(1) size: vec2f,
    @location(2) color: vec4f 
  ) -> VSOut {

  // "centered" quad (two triangles)
  // CCW vertices, assumes RH projection.
  const POSITIONS = array(
      vec2f(-0.5, -0.5),
      vec2f( 0.5, -0.5),
      vec2f(-0.5,  0.5),

      vec2f(-0.5,  0.5),
      vec2f( 0.5, -0.5),
      vec2f( 0.5,  0.5),
  );

  let world_pos = pos + POSITIONS[vertex_index] * size;

  var out : VSOut;
  out.position = debug_quad.view_proj * vec4f(world_pos, 0.0, 1.0);
  out.tint = color;

  return out;
}

@fragment
fn fs_main(in: VSOut) -> @location(0) vec4f {
  return in.tint;
}
