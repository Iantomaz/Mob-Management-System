# Mob-Management-System

Some functions, such as Billboard, Animations, Sounds, and Particles, are left empty because they need to be implemented according to your current system. I’m not sure if you’re using any kind of controller for animations, sounds, particles, etc.

The only feature that might still be missing is the logic for removing items the player is carrying when taking damage, or for damaging/killing the mob (you can remove this function if you don’t want to use it). However, with the way I structured the system, integrating this into your combat system should be straightforward.

I also created a small framework to run and test the systems in a familiar way, but it’s very easy to decouple and adapt it to how your game’s system works. I can handle that adjustment as well. I implemented it this way because I’m not yet familiar with your architecture.

I’ve tried to describe as clearly as possible in this README how the system works and how to use it.

## Architecture

The system is divided into several key components:

### Server-Side Components
- `MobsService.luau`: Central service for managing mob lifecycle
- `Mob.luau`: Core mob class defining mob behavior
- `SpawnZone.luau`: Manages spawn zones and mob generation

### Client-Side Components
- `MobsController.luau`: Handles client-side mob interactions
- `MobClient.luau`: Client-side representation of mobs

### Shared Components
- `MobTypes.luau`: Type definitions
- `MobConfigs.luau`: Mob configuration management

### Mob Spawning
1. Define spawn zones with specific parameters
2. Mobs are randomly generated within these zones
3. Supports configurable mob types, spawn intervals, and max mob counts

### Mob Interactions
- Players can carry mobs
- Mobs have configurable states (Wandering, BeingCarried, Returning, Dead)
- Supports damage and mutation systems

## Configuration Example

```lua
MobsService:CreateSpawnZone({
    Name = "TestArea",
    Center = Vector3.new(0, 50, 0),
    Size = Vector3.new(100, 0, 100),
    MaxMobs = 10,
    SpawnInterval = 5,
    MobTypes = { "Generic" },
    Seed = 12345,
})
```

### Mob Configuration

```lua
MobConfigs["Generic"] = {
    TypeId = "Generic",
    BaseHealth = 100,
    BaseSpeed = 8,
    BaseSize = 1.0,
    WanderRadius = 20,
    DefaultLifetime = 300,
    Model = "Rig",
    CanBeMutated = true,
    MutationChance = 0.15,
    PossibleMutations = { "Size", "Color", "Speed", "Glow" },
    CarrySlowdown = 0.6,
    DropOnDamage = true,
}
```

## Customization

You can easily extend the system by:
- Adding new mob types in `MobConfigs.luau`
- Creating custom mutation types
- Modifying spawn zone behaviors
