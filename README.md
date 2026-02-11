# SafeNavTwin

Digital Twin simulation for assistive navigation systems.

## Goal
Reproduce and extend:
Katzschmann et al. (2018) – Safe Local Navigation for Visually Impaired Users

## System Architecture

Unity Digital Twin:
- Corridor environment
- Agent with CharacterController
- ToF sensor (raycast-based)
- Experiment Logger (raw + summary CSV)

## Current Features
- Forward navigation agent
- Real-time ToF distance measurement
- Event logging to CSV
- Trial-based metadata (Participant / Condition / Trial)

## Next Milestones
- Event-driven feedback logic
- Collision risk modeling
- Asymmetric cost implementation
- Haptic signal abstraction layer
