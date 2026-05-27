use lily::wgpu_types::{Vec4f, Vec2f, Mat4f}
use lily::wgpu
use lily::bmf
use lily::gm
mod simulation::{ExampleSimulation}


struct ExampleRender {
    debug_quad_pipeline: wgpu::RenderPipelineHandle
    debug_quad_pipeline_layout: wgpu::PipelineLayoutHandle
    debug_quad_bind_group_layout: wgpu::BindGroupLayoutHandle
    debug_quad_bind_group: wgpu::BindGroupHandle
    debug_quad_instance_buffer: wgpu::BufferHandle
    debug_quad_uniform_buffer: wgpu::BufferHandle
}

#[repr(uniform)]
struct DebugQuadUniform {
    view_proj: Mat4f
}

struct DebugQuadInstance {
    pos: Vec2f
    size: Vec2f
    color: Vec4f
}

// Sweetie 16 — https://lospec.com/palette-list/sweetie-16
const SWEET_COLORS: [Vec4f; 16] = [
    [26.0/255.0, 28.0/255.0, 44.0/255.0, 1.0]// #1a1c2c
    [93.0/255.0, 39.0/255.0, 93.0/255.0, 1.0]// #5d275d
    [177.0/255.0, 62.0/255.0, 83.0/255.0, 1.0]  // #b13e53
    [239.0/255.0, 125.0/255.0, 87.0/255.0, 1.0] // #ef7d57
    [255.0/255.0, 205.0/255.0, 117.0/255.0, 1.0] // #ffcd75
    [167.0/255.0, 240.0/255.0, 112.0/255.0, 1.0] // #a7f070
    [56.0/255.0, 183.0/255.0, 100.0/255.0, 1.0] // #38b764
    [37.0/255.0, 113.0/255.0, 121.0/255.0, 1.0] // #257179
    [41.0/255.0, 54.0/255.0, 111.0/255.0, 1.0] // #29366f
    [59.0/255.0, 93.0/255.0, 201.0/255.0, 1.0] // #3b5dc9
    [65.0/255.0, 166.0/255.0, 246.0/255.0, 1.0] // #41a6f6
    [115.0/255.0, 239.0/255.0, 247.0/255.0, 1.0] // #73eff7
    [244.0/255.0, 244.0/255.0, 244.0/255.0, 1.0] // #f4f4f4
    [148.0/255.0, 176.0/255.0, 194.0/255.0, 1.0] // #94b0c2
    [86.0/255.0, 108.0/255.0, 134.0/255.0, 1.0] // #566c86
    [51.0/255.0, 60.0/255.0, 87.0/255.0, 1.0]   // #333c57
]

impl ExampleRender {
    fn new() -> ExampleRender {

        // Background layout and pipeline
        debug_quad_bind_group_layout := wgpu::create_bind_group_layout([
            { binding: 0, ty: Buffer(Uniform) },
        ], 'background bind group layout')

        debug_quad_pipeline_layout := wgpu::create_pipeline_layout([debug_quad_bind_group_layout], 'debug quad pipeline layout')

        debug_instance_buffer_layout := wgpu::VertexBufferLayout {
            array_stride: size_of::<DebugQuadInstance>
            vertex_attribute: [
                wgpu::VertexAttribute { offset: offset_of::<DebugQuadInstance::pos>, location: 0, format: Float32x2 }
                wgpu::VertexAttribute { offset: offset_of::<DebugQuadInstance::size>, location: 1, format: Float32x2 }
                wgpu::VertexAttribute { offset: offset_of::<DebugQuadInstance::color>, location: 2, format: Float32x4 }
            ],
            vertex_attribute_count: 3
            step_mode: Instance
        }

        debug_quad_pipeline := wgpu::create_render_pipeline(
            debug_quad_pipeline_layout,
             [debug_instance_buffer_layout],
              @shaders/debug_quad.wgsl, Alpha, Back, false, 'debug quad pipeline')


        sprite_view_proj := gm::Mat4::ortho_2d_int(256, 256, 1.0).to_mat4f()
        debug_uniform := DebugQuadUniform {
            view_proj: sprite_view_proj
        }
        debug_quad_uniform_buffer := wgpu::create_uniform_buffer(debug_uniform, 'debug quad uniform')


        debug_quad_instances: Block<DebugQuadInstance; 64>
        debug_quad_instance_buffer := wgpu::create_vertex_buffer(debug_quad_instances, 'debug quad instances')
      

        debug_quad_bind_group := wgpu::create_bind_group(debug_quad_bind_group_layout, [
            Buffer(debug_quad_uniform_buffer)], 'bind group') 

        // Background texture, sampler and bind group

        {

            debug_quad_pipeline: debug_quad_pipeline
            debug_quad_pipeline_layout: debug_quad_pipeline_layout
            debug_quad_bind_group_layout: debug_quad_bind_group_layout
            debug_quad_bind_group: debug_quad_bind_group
            debug_quad_instance_buffer: debug_quad_instance_buffer
            debug_quad_uniform_buffer: debug_quad_uniform_buffer
        }
    }


    #[host_call]
    fn render(mut self, sim: ExampleSimulation) {
        normalized_int_time := sim.time % 62800
        normalized_float_time := (normalized_int_time.float() * 0.1)

        screen_width, screen_height = wgpu::surface_extent()


        sprite_view_proj := gm::Mat4::ortho_2d_pixel_near_far_int(screen_width, screen_height, 0, 100).to_mat4f()
        debug_uniform := DebugQuadUniform {
            view_proj: sprite_view_proj
        }
        .debug_quad_uniform_buffer.write(debug_uniform)

        mut sprite_instances: Block<DebugQuadInstance; 8>

        x_int, y_int = sim.accepted_position

        quad_color := SWEET_COLORS[sim.fire_count % 16]
        quad_size := 16 + (sim.fire_count % 8) * 20

        sprite_instances[0] = DebugQuadInstance {
            pos: [x_int.float(), y_int.float()]
            size: [quad_size.float(), quad_size.float()]
            color: quad_color
        }

        .debug_quad_instance_buffer.write(sprite_instances)
        // PASS: Render
        {
            mut render_pass: wgpu::RenderPass
            render_pass.depth_attachment = -1

            // Render debug quads
            render_pass.set_pipeline(.debug_quad_pipeline)
            render_pass.set_bind_group( group_index: 0, bind_group: .debug_quad_bind_group )
            render_pass.set_vertex_buffer( slot: 0, vertex_buffer: .debug_quad_instance_buffer)
            render_pass.draw( [0, 6], [0, 1] )

            wgpu::add_pass(render_pass, 'render stuff to screen')
        }
    }

    #[host_call]
    fn resize(mut self) {
        
    }
}
