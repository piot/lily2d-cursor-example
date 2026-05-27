struct SimulationInput {
    requested_absolute_position: (Int, Int)
    fired: Bool,
}

struct ExampleSimulation {
    time: Int
    accepted_position: (Int, Int)
    fire_count: Int,
}


impl ExampleSimulation {
    fn new() -> ExampleSimulation {
        ExampleSimulation {..}
    }

    #[host_call]
    fn tick(mut self, input: SimulationInput) {
        .time += 1
        .accepted_position = input.requested_absolute_position
        if input.fired {
            .fire_count += 1
        }
    }
}
