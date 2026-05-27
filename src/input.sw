use lily::input

mod simulation::{SimulationInput}

struct SpaceCraft {
    cursor_pos: (Int, Int)
    fire: Bool,
}

struct InputLogic {
    previous_fire: Bool
}

impl InputLogic {
    #[host_call] // is needed to tell Swamp that this will be called by a host (Lily2D)
    fn tick(mut self) -> SimulationInput {
        active_devices: Vec<Int; 8> = input::get_active_devices()

        mut pos := (0, 0)
        mut fire := false

        for device_id in active_devices {
            input::set_active_action_set::<SpaceCraft>(device_id)
            space_craft_input: SpaceCraft = input::get(device_id)

            pos = space_craft_input.cursor_pos
            if space_craft_input.fire {
                fire = space_craft_input.fire
            }

           // found_type := input::get_device_type(device_id)
       }

        fired := !.previous_fire && fire
        .previous_fire = fire

        SimulationInput {
            requested_absolute_position: pos
            fired: fired
        }
    }
}
