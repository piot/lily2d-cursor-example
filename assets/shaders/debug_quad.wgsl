//! Debug Quad Shader
//!
//! Minimal 2D quad renderer:
//! - uniform: view_proj matrix
//! - instance buffer: pos, size, color

struct DebugQuadUniform {
 view_proj: mat4x4<f32>,
};

@group(0) @binding(0) var<uniform> debug_quad: DebugQuadUniform;

struct VSOut {
  @builtin(position) position: vec4<f32>,
  @location(0) tint: vec4<f32>,
};

@vertex
fn vs_main(
     // Per-vertex
    @builtin(vertex_index) vertex_index : u32,

    // Per-instance
    @location(0) pos: vec2<f32>,
    @location(1) size: vec2<f32>,
    @location(2) color: vec4<f32> 
  ) -> VSOut {

  // "centered" quad (two triangles)
  // CCW vertices, assumes RH projection.
  var positions = array<vec2<f32>, 6>(
      vec2<f32>(-0.5, -0.5),
      vec2<f32>( 0.5, -0.5),
      vec2<f32>(-0.5,  0.5),

      vec2<f32>(-0.5,  0.5),
      vec2<f32>( 0.5, -0.5),
      vec2<f32>( 0.5,  0.5),
  );

  let world_pos = pos + positions[vertex_index] * size;

  var out : VSOut;
  out.position = debug_quad.view_proj * vec4<f32>(world_pos, 0.0, 1.0);
  out.tint = color;

  return out;
}

@fragment
fn fs_main(in: VSOut) -> @location(0) vec4<f32> {
  return in.tint;
}
