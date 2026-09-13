Kalau gue yang merancang dari posisi principal software engineer, gue akan **menggeser framing-nya sedikit**: jangan bikin “script hub” sebagai kumpulan script random. Bikin sebagai **automation + observability platform untuk Roblox experience milik sendiri / test place**.

Dengan begitu semua yang kita bahas—detector, asset scanner, event recorder, movement recorder, interaction recorder, replay, adapter per game/place, UI, config, target selector, navigator, state machine, workflow inference—masuk ke satu sistem yang punya batas domain yang jelas.

Master architecture-nya gue bikin seperti ini.

```text
                    ┌───────────────────────────┐
                    │        Bootstrap          │
                    └─────────────┬─────────────┘
                                  │
                                  ▼
                    ┌───────────────────────────┐
                    │       Application         │
                    │       Runtime/Core        │
                    └─────────────┬─────────────┘
                                  │
        ┌─────────────────────────┼─────────────────────────┐
        ▼                         ▼                         ▼
 Environment                  Experience                Lifecycle
 Detection                    Detection                 Manager
        │                         │                         │
        └──────────────┬──────────┴──────────┬─────────────┘
                       ▼                     ▼
                Runtime Context        Adapter Registry
                                             │
                                             ▼
                                      Experience Adapter
                                             │
                 ┌───────────────────────────┼──────────────────────────┐
                 ▼                           ▼                          ▼
             Sensors                     Automation                  Debug UI
                 │                           │                          │
      ┌──────────┼──────────┐        ┌───────┼─────────┐       ┌──────┼─────┐
      ▼          ▼          ▼        ▼       ▼         ▼       ▼      ▼     ▼
 movement   interaction   world   target   planner  navigator overlay logs inspector
 recorder     recorder    scanner selector
      │          │          │        │       │         │
      └──────────┴──────────┴────────┴───────┴─────────┘
                              │
                              ▼
                       Event / State Bus
                              │
                              ▼
                    Timeline + State Store
                              │
              ┌───────────────┼─────────────────┐
              ▼               ▼                 ▼
           Replay          Analytics       Workflow Engine
                                                │
                                                ▼
                                         Behavior Graph
```

Ini bukan cuma rapi. Boundary-nya juga jelas.

---

# 1. Prinsip arsitektur

Ada beberapa aturan yang gue jadikan non-negotiable.

**Core tidak boleh tahu detail game.** Core cuma tahu interface seperti `Adapter`, `Sensor`, `Feature`, `Navigator`, `Recorder`.

**UI tidak boleh memiliki business logic.** UI hanya mengubah state atau mengirim command.

**Sensor hanya mengobservasi.** Sensor tidak boleh mengubah world.

**Automation tidak boleh melakukan discovery sendiri.** Dia meminta data dari world model/scanner.

**Semua side effect lewat service yang jelas.** Misalnya navigation lewat `Navigator`, interaction lewat `InteractionService`, config lewat `ConfigStore`.

**Game-specific knowledge tinggal di adapter.**

**Recorder memakai event schema yang stabil.** Jangan simpan data sesuka hati dari tiap module.

**Jangan pakai global mutable state.**

**Jangan ada giant `while true do` yang mengerjakan semuanya.**

Kalau satu rule ini dilanggar, project akan berubah jadi spaghetti dalam beberapa bulan.

---

# 2. Struktur repository

Gue akan pilih struktur seperti:

```text
roblox-automation-platform/
│
├── src/
│   ├── bootstrap/
│   │   └── main.lua
│   │
│   ├── core/
│   │   ├── Application.lua
│   │   ├── Context.lua
│   │   ├── Lifecycle.lua
│   │   ├── EventBus.lua
│   │   ├── CommandBus.lua
│   │   ├── Scheduler.lua
│   │   └── Errors.lua
│   │
│   ├── runtime/
│   │   ├── EnvironmentDetector.lua
│   │   ├── ExperienceDetector.lua
│   │   ├── CapabilityDetector.lua
│   │   └── RuntimeInfo.lua
│   │
│   ├── registry/
│   │   ├── AdapterRegistry.lua
│   │   ├── FeatureRegistry.lua
│   │   ├── SensorRegistry.lua
│   │   └── SerializerRegistry.lua
│   │
│   ├── world/
│   │   ├── WorldModel.lua
│   │   ├── Entity.lua
│   │   ├── EntityIndex.lua
│   │   ├── SpatialIndex.lua
│   │   ├── AssetResolver.lua
│   │   └── TagResolver.lua
│   │
│   ├── sensors/
│   │   ├── Sensor.lua
│   │   ├── MovementSensor.lua
│   │   ├── InteractionSensor.lua
│   │   ├── WorldSensor.lua
│   │   ├── InventorySensor.lua
│   │   ├── CameraSensor.lua
│   │   └── StateSensor.lua
│   │
│   ├── recorder/
│   │   ├── SessionRecorder.lua
│   │   ├── Timeline.lua
│   │   ├── EventSchema.lua
│   │   ├── SnapshotManager.lua
│   │   └── exporters/
│   │       ├── ConsoleExporter.lua
│   │       ├── JsonExporter.lua
│   │       └── MemoryExporter.lua
│   │
│   ├── serializers/
│   │   ├── InstanceSerializer.lua
│   │   ├── AssetSerializer.lua
│   │   ├── VectorSerializer.lua
│   │   ├── CFrameSerializer.lua
│   │   └── AttributeSerializer.lua
│   │
│   ├── automation/
│   │   ├── AutomationEngine.lua
│   │   ├── StateMachine.lua
│   │   ├── BehaviorTree.lua
│   │   ├── Workflow.lua
│   │   ├── WorkflowRunner.lua
│   │   ├── TargetSelector.lua
│   │   ├── Planner.lua
│   │   ├── Navigator.lua
│   │   ├── InteractionController.lua
│   │   └── Validator.lua
│   │
│   ├── replay/
│   │   ├── ReplayEngine.lua
│   │   ├── ReplayClock.lua
│   │   └── ReplaySession.lua
│   │
│   ├── adapters/
│   │   ├── Adapter.lua
│   │   ├── UniversalAdapter.lua
│   │   └── examples/
│   │       └── simple_tycoon/
│   │           ├── Adapter.lua
│   │           ├── Metadata.lua
│   │           ├── EntityRules.lua
│   │           ├── WorkflowRules.lua
│   │           └── Features.lua
│   │
│   ├── features/
│   │   ├── Feature.lua
│   │   ├── WorldInspector.lua
│   │   ├── AssetInspector.lua
│   │   ├── RecorderFeature.lua
│   │   ├── ReplayFeature.lua
│   │   └── AutomationFeature.lua
│   │
│   ├── ui/
│   │   ├── AppUI.lua
│   │   ├── UIState.lua
│   │   ├── components/
│   │   ├── pages/
│   │   │   ├── DashboardPage.lua
│   │   │   ├── InspectorPage.lua
│   │   │   ├── RecorderPage.lua
│   │   │   ├── WorkflowPage.lua
│   │   │   ├── AutomationPage.lua
│   │   │   └── SettingsPage.lua
│   │   └── overlays/
│   │       ├── EntityOverlay.lua
│   │       ├── AssetOverlay.lua
│   │       └── PathOverlay.lua
│   │
│   ├── config/
│   │   ├── Config.lua
│   │   ├── ConfigStore.lua
│   │   ├── Defaults.lua
│   │   └── Migrations.lua
│   │
│   ├── telemetry/
│   │   ├── Logger.lua
│   │   ├── Metrics.lua
│   │   ├── Trace.lua
│   │   └── Diagnostics.lua
│   │
│   └── utils/
│       ├── Maid.lua
│       ├── Signal.lua
│       ├── Table.lua
│       ├── Time.lua
│       └── Id.lua
│
├── tests/
│   ├── unit/
│   ├── integration/
│   └── fixtures/
│
├── docs/
│   ├── architecture.md
│   ├── event-schema.md
│   ├── adapter-guide.md
│   └── workflow-guide.md
│
├── examples/
└── README.md
```

Ini kelihatan besar, tapi separation-nya worth it.

---

# 3. Bootstrap layer

Bootstrap harus seminimal mungkin.

```lua
local Application = require(...)
local Config = require(...)

local app = Application.new(Config.load())

app:init()
app:start()
```

Jangan taruh:

```lua
if game.PlaceId == ...
```

di bootstrap.

Jangan create UI di bootstrap.

Jangan scan Workspace di bootstrap.

Bootstrap cuma composition root.

---

# 4. Runtime Context

Semua module akan membutuhkan context.

Jangan passing 15 dependency satu per satu.

Bikin:

```lua
local Context = {
    runtime = {},
    experience = {},
    capabilities = {},
    services = {},
    config = {},
    logger = {},
    eventBus = {},
    world = {},
}
```

Contoh hasil detection:

```lua
{
    runtime = {
        platform = "desktop",
        environment = "studio",
    },

    experience = {
        gameId = 12345,
        placeId = 67890,
        placeType = "match",
        name = "SimpleTycoon",
    },

    capabilities = {
        pathfinding = true,
        recording = true,
        persistence = true,
    }
}
```

Semua module menerima context ini.

---

# 5. Experience detector

Jangan giant if-chain.

Gunakan metadata.

```lua
return {
    id = "simple-tycoon",

    gameIds = {
        123456
    },

    places = {
        [111] = "lobby",
        [222] = "factory",
        [333] = "market"
    }
}
```

Registry:

```lua
AdapterRegistry:Register(SimpleTycoonAdapter)
```

Resolver:

```lua
local adapter = AdapterRegistry:resolve(
    context.experience.gameId,
    context.experience.placeId
)
```

Kalau tidak ada:

```text
UniversalAdapter
```

Ini penting supaya system selalu bisa boot.

---

# 6. Adapter contract

Adapter adalah tempat semua knowledge spesifik experience.

Interface:

```lua
export type Adapter = {
    id: string,

    supports: (self, context) -> boolean,
    init: (self, context) -> (),
    start: (self) -> (),
    stop: (self) -> (),

    getEntityRules: (self) -> {},
    getWorkflows: (self) -> {},
    getFeatures: (self) -> {},
}
```

SimpleTycoon:

```lua
local Adapter = {}

Adapter.id = "simple-tycoon"

function Adapter:supports(ctx)
    return ctx.experience.gameId == 123456
end

function Adapter:init(ctx)
    self.ctx = ctx
end

function Adapter:getEntityRules()
    return require(script.EntityRules)
end

function Adapter:getWorkflows()
    return require(script.WorkflowRules)
end

return Adapter
```

---

# 7. World Model

Ini salah satu bagian paling penting.

Jangan feature scan Workspace sendiri-sendiri.

Bad:

```text
AssetInspector -> GetDescendants()
Autofarm -> GetDescendants()
Recorder -> GetDescendants()
Overlay -> GetDescendants()
```

Empat scan.

Waste.

Better:

```text
Workspace
    ↓
WorldScanner
    ↓
WorldModel
    ↓
shared consumers
```

`WorldModel` menyimpan normalized representation:

```lua
{
    id = "entity_42",

    instance = instance,

    name = "Apple",

    class = "Model",

    path = "Workspace.Items.Apple",

    position = Vector3.new(...),

    tags = {
        "Collectible"
    },

    attributes = {
        Value = 10
    },

    assets = {
        mesh = "...",
        texture = "..."
    }
}
```

Jadi seluruh sistem bicara soal **Entity**, bukan raw Roblox Instance.

---

# 8. Entity classification

Ini layer yang menentukan:

> benda ini apa?

Contoh rule engine:

```lua
{
    id = "collectible",

    match = function(entity)
        return entity.tags.Collectible
            or entity.path:find("Items")
    end
}
```

Seller:

```lua
{
    id = "seller",

    match = function(entity)
        return entity.tags.Seller
    end
}
```

Output:

```text
Workspace.Items.Apple
→ collectible

Workspace.Seller.Counter
→ seller
```

Ini jauh lebih baik daripada hard-code:

```lua
workspace.Items.Apple
```

---

# 9. Asset resolver

Asset metadata adalah augmentation.

```text
Entity
├── identity
├── position
├── tags
├── attributes
└── assets
```

AssetResolver membaca:

```text
MeshPart.MeshId
MeshPart.TextureID
Decal.Texture
Sound.SoundId
Animation.AnimationId
```

Output normalized:

```lua
{
    {
        kind = "mesh",
        id = "123456"
    },

    {
        kind = "texture",
        id = "654321"
    }
}
```

Jangan biarkan tiap feature parse:

```text
rbxassetid://
```

sendiri.

---

# 10. Spatial Index

Kalau item banyak, jangan tiap frame:

```lua
for _, item in items do
    distance(...)
end
```

Untuk sedikit item masih oke.

Tapi framework proper sebaiknya punya:

```text
SpatialIndex
```

API:

```lua
world.spatial:nearest(position, {
    type = "collectible"
})
```

atau:

```lua
world.spatial:withinRadius(
    position,
    50,
    "collectible"
)
```

Implementation awal boleh linear search.

Nanti bisa upgrade ke:

```text
grid partitioning
quadtree
octree
```

tanpa mengubah consumer.

Ini contoh abstraction yang bagus.

---

# 11. Sensor architecture

Sensor hanya mengamati.

Base contract:

```lua
Sensor = {
    init(),
    start(),
    stop(),
}
```

Movement sensor:

```text
player position
velocity
direction
humanoid state
```

Interaction sensor:

```text
ProximityPrompt
ClickDetector
Tool activation
domain interaction events
```

World sensor:

```text
DescendantAdded
DescendantRemoving
attribute changed
tag changed
```

Inventory sensor:

```text
inventory count
item added
item removed
capacity
```

Semua sensor emit event ke EventBus.

---

# 12. EventBus

Jangan module saling reference langsung berlebihan.

Bad:

```text
MovementSensor
 → Recorder
 → UI
 → Analytics
 → WorkflowAnalyzer
```

Better:

```text
MovementSensor
       ↓
    EventBus
       ↓
 ┌─────┼───────────┐
 ▼     ▼           ▼
Recorder UI     Analytics
```

API:

```lua
eventBus:emit("movement.sample", data)

eventBus:on("movement.sample", function(event)
end)
```

Gunakan naming convention.

```text
movement.sample
interaction.started
interaction.completed
world.entity_added
world.entity_removed
inventory.changed
navigation.started
navigation.completed
workflow.state_changed
```

---

# 13. Event schema

Jangan event arbitrary.

Setiap event punya envelope.

```lua
{
    id = "evt_123",

    timestamp = 14.882,

    type = "interaction.completed",

    source = "InteractionSensor",

    sessionId = "session_abc",

    entityId = "entity_42",

    data = {
        action = "Pickup"
    }
}
```

Ini membuat timeline, analytics, replay, debug jauh lebih gampang.

---

# 14. Session Recorder

Recorder bukan sensor.

Recorder adalah subscriber.

```text
Sensors
   ↓
EventBus
   ↓
Recorder
```

Recorder:

```lua
Recorder:startSession()

Recorder:pause()

Recorder:resume()

Recorder:stopSession()
```

Timeline:

```lua
Session {
    metadata,
    startedAt,
    events,
    snapshots
}
```

---

# 15. Snapshot vs event

Ini penting.

Jangan simpan semuanya sebagai event.

Gunakan:

```text
events
+
periodic snapshots
```

Contoh:

```text
t=0 snapshot
t=1 events
t=2 events
t=5 snapshot
t=6 events
```

Supaya replay tidak perlu reconstruct state dari t=0 terus.

Ini pattern event sourcing.

---

# 16. Recorder timeline

Contoh:

```text
00.000 SESSION_START

01.203 MOVEMENT_SAMPLE
       pos=(10,5,2)

02.022 TARGET_ENTER_RANGE
       Apple#42

02.614 INTERACTION_STARTED
       Pickup Apple#42

02.731 INTERACTION_COMPLETED

02.744 ENTITY_REMOVED
       Apple#42

02.751 INVENTORY_CHANGED
       0 → 1
```

Timeline ini menjadi sumber data universal.

---

# 17. Workflow inference

Ini layer menarik.

Input:

```text
interaction
world delta
inventory delta
movement
```

Analyzer mencoba mengenali pattern.

Misalnya:

```text
interaction Apple
↓
Apple removed
↓
inventory +1
```

Infer:

```text
pickup action
```

Kemudian:

```text
interaction Seller
↓
inventory -1
↓
currency +10
```

Infer:

```text
sell action
```

Maka session:

```text
pickup
pickup
pickup
sell
```

bisa disimpulkan:

```text
CollectUntilFull
→ Sell
```

---

# 18. Workflow model

Jangan hard-code behavior jadi kode dulu.

Represent sebagai data.

```lua
{
    id = "collect-and-sell",

    states = {
        "find_item",
        "move_to_item",
        "pickup",
        "check_inventory",
        "move_to_seller",
        "sell"
    }
}
```

Transitions:

```lua
{
    from = "check_inventory",
    condition = "inventory_full",
    to = "move_to_seller"
}
```

atau:

```lua
{
    from = "check_inventory",
    condition = "inventory_not_full",
    to = "find_item"
}
```

Ini jauh lebih flexible.

---

# 19. State machine vs behavior tree

Dua-duanya berguna.

Untuk simple tycoon:

```text
Finite State Machine
```

cukup.

```text
SEARCH
→ MOVE
→ PICKUP
→ CHECK
→ SELL
```

Kalau behavior kompleks:

```text
Behavior Tree
```

lebih bagus.

Contoh:

```text
Selector
├── If inventory full
│   └── SellSequence
│
└── CollectSequence
    ├── FindItem
    ├── Navigate
    └── Pickup
```

Rule gue:

```text
simple linear workflow
→ FSM

nested conditional behavior
→ Behavior Tree
```

Jangan langsung pakai Behavior Tree kalau cuma lima state.

---

# 20. Target selector

Navigation tidak boleh memilih target.

Itu concern berbeda.

TargetSelector:

```lua
TargetSelector:findBest({
    type = "collectible",

    strategy = "highest_value_per_distance"
})
```

Strategies:

```text
nearest
highest_value
value_per_distance
least_congested
oldest_spawn
custom
```

Score:

```text
score =
valueWeight * value
-
distanceWeight * distance
```

Ini pluggable strategy pattern.

---

# 21. Planner

Planner memutuskan **apa yang harus dilakukan**.

Navigator cuma menjawab:

> gimana menuju target?

Planner:

```text
inventory not full
→ acquire collectible

inventory full
→ seller
```

Jangan Navigator tahu inventory.

Itu anti-pattern.

---

# 22. Navigator

Interface:

```lua
Navigator:goTo(target, options)
```

Result:

```lua
{
    success = true,
    duration = 2.34,
    pathLength = 18.2
}
```

Failure:

```lua
{
    success = false,
    reason = "unreachable"
}
```

Navigator sendiri menangani:

```text
path calculation
waypoints
stuck detection
timeout
repath
cancel
```

---

# 23. Navigation state

Jangan blocking:

```lua
MoveToFinished:Wait()
```

di seluruh app.

Bikin task abstraction.

```lua
local task = navigator:goTo(target)

task:onProgress(...)
task:onComplete(...)
task:cancel()
```

Karena target bisa hilang.

---

# 24. Replanning

Target hilang?

```text
MOVE_TO_TARGET
      │
      ▼
target invalid
      │
      ▼
cancel current navigation
      │
      ▼
Planner.plan()
```

Jangan crash.

Ini penting banget untuk bot-world interaction.

---

# 25. Interaction Controller

Semua interaction lewat satu service.

```lua
InteractionController:interact(entity, action)
```

Dalam own-game integration ideal:

```text
InteractionController
↓
domain service
```

bukan fake keyboard.

Misalnya:

```lua
PickupService:Pickup(player, entity.instance)
```

Dengan begitu manusia dan automation memakai logic authoritative yang sama.

---

# 26. Validator

Setelah action jangan langsung assume success.

```text
interact
↓
Validator
```

Untuk pickup:

```text
object disappeared?
inventory increased?
state changed?
```

Untuk sell:

```text
inventory decreased?
currency increased?
```

Result:

```lua
{
    success = true,
    evidence = {
        inventoryDelta = 1,
        entityRemoved = true
    }
}
```

Itu observability yang bagus.

---

# 27. Retry policy

Jangan:

```lua
while not success do
```

Selamanya.

Buat policy:

```lua
{
    maxAttempts = 3,
    backoff = 0.25,
    timeout = 3,
}
```

Kalau gagal:

```text
fail
↓
retry?
↓
yes → action again
no  → replanning
```

---

# 28. Feature architecture

Feature bukan core.

Contoh feature:

```text
World Inspector
Recorder
Replay
Automation
Asset Inspector
Path Visualizer
```

Interface:

```lua
Feature = {
    id,
    init(),
    enable(),
    disable(),
    destroy()
}
```

Feature Manager:

```lua
FeatureManager:setEnabled("world-inspector", true)
```

UI cuma call itu.

---

# 29. UI architecture

UI gunakan:

```text
UI
↓
ViewModel / UIState
↓
Commands
↓
Application services
```

Jangan:

```text
Button.OnClick
↓
langsung scan Workspace
```

Page structure:

```text
Dashboard
Inspector
Recorder
Workflow
Automation
Settings
Diagnostics
```

---

# 30. Dashboard

Dashboard sebaiknya memperlihatkan:

```text
Experience
Adapter
Place
Recorder status
Automation status
Current workflow
Current state
Current target
Current position
Inventory
Events/sec
Errors
```

Jadi user tahu sistem sedang ngapain.

---

# 31. Inspector

Ini tool recon utama untuk own/test experience.

Klik entity:

```text
Name
Class
Path
Position
Distance
Attributes
Tags
Children
Assets
Interaction metadata
```

Misalnya:

```text
Apple
Model

Path:
Workspace.Items.Apple

Position:
12.3, 5.0, -18.2

Distance:
21.4 studs

Tags:
Collectible

Attributes:
Value = 10

Assets:
Mesh 123456
Texture 654321
```

---

# 32. Overlay system

Overlay juga jangan tied ke scanner.

```text
WorldModel
↓
OverlayRenderer
```

Modes:

```text
entity type
distance
asset IDs
path
state
target score
```

Contoh:

```text
Apple
Collectible
14.2 studs
score: 3.41
```

---

# 33. Path visualization

Navigator bisa emit:

```text
navigation.path_computed
```

UI menggambar:

```text
Player
 ○
  \
   ○
    \
     ○ Target
```

Navigator tidak menggambar UI sendiri.

Separation.

---

# 34. Config

Config harus versioned.

```lua
{
    schemaVersion = 3,

    recorder = {
        movementSampleRate = 5,
    },

    automation = {
        retryCount = 3,
    },

    ui = {
        overlayEnabled = true,
    }
}
```

Kalau schema berubah:

```text
v1 → v2 → v3
```

pakai migration.

Jangan assume config selamanya sama.

---

# 35. Logging

Jangan pakai `print()` random.

Logger:

```lua
logger:debug(...)
logger:info(...)
logger:warn(...)
logger:error(...)
```

Context:

```text
[15:44:12.143]
[Navigator]
[WARN]

Target unreachable
entity=Apple#42
attempt=2
```

---

# 36. Metrics

Tambahkan metrics.

```text
items_collected
items_sold
navigation_failures
interaction_failures
workflow_cycles
average_cycle_time
average_path_length
profit_per_minute
```

Itu bikin debugging dan optimization jauh lebih mudah.

---

# 37. Tracing

Untuk workflow execution, trace satu cycle.

```text
traceId = cycle_129

SEARCH
  12 ms

TARGET_SELECT
  4 ms

PATH_COMPUTE
  31 ms

NAVIGATE
  2.8 sec

PICKUP
  120 ms
```

Ini principal-level observability.

---

# 38. Error taxonomy

Jangan semua error string.

Bikin categories:

```text
NavigationError
InteractionError
ValidationError
AdapterError
ConfigurationError
SerializationError
TimeoutError
```

Contoh:

```lua
return {
    code = "NAV_TARGET_UNREACHABLE",
    retryable = true
}
```

---

# 39. Cleanup management

Roblox project sering memory leak dari Connections.

Pakai pattern semacam Maid/Janitor.

```lua
self.maid:GiveTask(
    event:Connect(...)
)
```

Saat module stop:

```lua
self.maid:Cleanup()
```

Non-negotiable.

---

# 40. Lifecycle

Setiap module:

```text
new
↓
init
↓
start
↓
stop
↓
destroy
```

`init()` tidak boleh mulai event listeners.

`start()` baru side effects.

Ini bikin dependency initialization deterministic.

---

# 41. Dependency graph

Jangan module bebas require satu sama lain.

Arah dependency:

```text
UI
↓
application

automation
↓
world/core

recorder
↓
core

adapters
↓
interfaces/core
```

Core tidak boleh require:

```text
UI
automation
adapter implementation
```

Ini clean architecture.

---

# 42. Ports and adapters

Secara formal, gue akan pakai pendekatan Hexagonal-ish.

Domain core:

```text
Workflow
TargetSelector
Planner
StateMachine
```

Ports:

```text
WorldReader
Navigator
Interactor
Recorder
Logger
```

Adapters:

```text
RobloxWorldAdapter
PathfindingNavigator
DomainInteractionAdapter
```

Itu bikin logic gampang dites tanpa Roblox runtime.

---

# 43. Unit testing

TargetSelector bisa dites dengan fake world:

```lua
items = {
    {distance = 10, value = 20},
    {distance = 15, value = 100}
}
```

Assert:

```text
value/distance strategy
→ item kedua
```

Tidak perlu spawn Roblox objects.

---

# 44. Integration tests

Untuk Adapter:

```text
spawn fake collectible
↓
WorldModel detects
↓
classification = collectible
↓
TargetSelector sees it
```

Workflow:

```text
inventory = 0
→ expects Collect

inventory = full
→ expects Sell
```

---

# 45. Replay testing

Ini keren banget.

Recorded session:

```text
session_fixture_001.json
```

Feed ke analyzer:

```text
ReplaySession
↓
WorkflowInference
```

Expected:

```text
pickup
pickup
sell
```

Jadi behavior inference bisa regression-tested.

---

# 46. Adapter anti-pattern

Jangan adapter jadi:

```text
SimpleTycoonAdapter.lua
8000 lines
```

Adapter hanya composition:

```lua
Adapter
├── Metadata
├── EntityRules
├── WorkflowRules
├── Features
└── optional services
```

---

# 47. Giant universal module = anti-pattern

Jangan bikin:

```text
Universal.lua
15000 lines
```

Universal harus composed:

```text
UniversalAdapter
├── inspector
├── recorder
├── movement telemetry
└── asset scanner
```

---

# 48. No magic strings

Bad:

```lua
if type == "pickup" then
```

Better:

```lua
EventTypes.INTERACTION_PICKUP
```

atau typed union kalau tooling mendukung.

---

# 49. No raw table soup

Kalau project besar, define types.

```lua
export type Entity = {
    id: string,
    name: string,
    kind: string,
    position: Vector3?,
    tags: {[string]: boolean},
}
```

Luau type annotations bakal sangat membantu.

---

# 50. State ownership

Setiap state harus punya owner.

Contoh:

```text
WorldModel owns world state
Recorder owns session data
WorkflowRunner owns workflow state
UIState owns presentation state
ConfigStore owns persisted configuration
```

Jangan dua subsystem mutate object yang sama.

---

# 51. Command bus

Untuk UI actions:

```lua
commandBus:execute("recorder.start")
commandBus:execute("automation.stop")
commandBus:execute("workflow.select", "collect-sell")
```

Ini lebih bagus daripada UI tahu implementation.

---

# 52. Automation safety controls

Walau untuk test place, kasih guard.

```text
manual stop
timeout
max cycle count
max runtime
stuck detection
emergency reset
```

Contoh:

```lua
automation:start({
    maxCycles = 100,
    maxRuntime = 600
})
```

---

# 53. Session persistence

Session metadata:

```lua
{
    id,
    experienceId,
    placeId,
    adapterId,
    startedAt,
    duration,
    eventCount,
    version
}
```

Untuk compatibility, record juga:

```text
framework version
event schema version
adapter version
```

---

# 54. Workflow versioning

Workflow juga versioned.

```text
collect-sell
v1
v2
```

Kalau entity classification berubah, recording lama tetap reproducible.

---

# 55. Plugin architecture

Nanti framework bisa support plugin.

```text
plugins/
├── EconomyAnalytics
├── RouteOptimizer
├── Heatmap
└── SessionComparator
```

Plugin contract:

```lua
Plugin = {
    init(ctx),
    start(),
    stop()
}
```

Tapi jangan bikin plugin API terlalu awal.

Rule:

> buat setelah minimal dua use case nyata membutuhkan extensibility.

---

# 56. Design system UI

Kalau lu serius mau polished:

```text
tokens/
├── spacing
├── typography
├── radius
├── opacity
└── elevation

components/
├── Button
├── Toggle
├── Slider
├── Table
├── InspectorTree
├── Timeline
├── StatusBadge
└── MetricCard
```

Jangan hard-code:

```lua
UDim2...
Color3...
TextSize...
```

di tiap page.

Gunakan token.

---

# 57. Status model

Gunakan consistent status.

```text
idle
starting
running
paused
stopping
failed
completed
```

Recorder dan automation bisa pakai lifecycle state yang sama.

---

# 58. Timeline UI

Recorder page:

```text
00:00 ─ SESSION START
00:03 ─ MOVEMENT
00:04 ─ PICKUP Apple
00:05 ─ INVENTORY +1
00:08 ─ SELL
```

Filter:

```text
movement
interaction
world
inventory
navigation
workflow
```

---

# 59. Entity inspector tree

Tree view:

```text
Workspace
└── Items
    ├── Apple
    │   ├── Handle
    │   └── MeshPart
    └── Diamond
```

Klik entity → side pane.

Ini jauh lebih usable daripada log text.

---

# 60. Workflow editor

Akhirnya bisa punya visual workflow:

```text
[Find Item]
    ↓
[Move]
    ↓
[Pickup]
    ↓
[Inventory Full?]
   / \
 no   yes
 |     |
 └──   [Move Seller]
          ↓
        [Sell]
```

Workflow engine membaca graph ini.

---

# 61. Master flow end-to-end

Startup:

```text
Bootstrap
↓
Application
↓
detect runtime
↓
detect experience
↓
resolve adapter
↓
initialize WorldModel
↓
initialize Sensors
↓
initialize Recorder
↓
initialize Automation
↓
initialize UI
↓
start
```

Recon:

```text
WorldSensor
↓
WorldModel
↓
EntityClassifier
↓
AssetResolver
↓
SpatialIndex
↓
Inspector/Overlay
```

Recording:

```text
MovementSensor
InteractionSensor
WorldSensor
InventorySensor
       ↓
     EventBus
       ↓
 SessionRecorder
       ↓
    Timeline
```

Workflow inference:

```text
Timeline
↓
Event Correlator
↓
Semantic Actions
↓
Workflow Analyzer
↓
Behavior Graph
```

Automation:

```text
WorkflowRunner
↓
Planner
↓
TargetSelector
↓
Navigator
↓
InteractionController
↓
Validator
↓
State Transition
↓
repeat
```

---

# 62. Satu contoh flow tycoon

Misalnya environment:

```text
Workspace
├── Items
│   ├── Apple
│   ├── Apple
│   └── Diamond
└── Seller
```

WorldModel:

```text
Apple#1 collectible
Apple#2 collectible
Diamond#1 collectible
Seller#1 seller
```

Automation state:

```text
SEARCH_ITEM
```

TargetSelector:

```text
Apple#1 distance 15 value 10 score .67
Apple#2 distance 30 value 10 score .33
Diamond  distance 25 value 100 score 4
```

Pilih:

```text
Diamond
```

Navigator:

```text
compute path
↓
follow waypoints
```

Interaction:

```text
Pickup
```

Validator:

```text
Diamond removed
inventory 0 → 1
```

Transition:

```text
inventory not full
↓
SEARCH_ITEM
```

Setelah penuh:

```text
MOVE_TO_SELLER
↓
SELL
↓
validate currency delta
↓
SEARCH_ITEM
```

---

# 63. Roadmap implementasi

Gue jangan bikin semuanya sekaligus.

### Phase 1 — Foundation

Bikin:

```text
Application
Context
Lifecycle
EventBus
Logger
Config
```

Target: app bisa boot/shutdown cleanly.

### Phase 2 — World inspection

Bikin:

```text
WorldModel
Entity
EntityIndex
AssetResolver
Inspector
Overlay
```

Target: bisa memahami dunia.

### Phase 3 — Recording

Bikin:

```text
MovementSensor
InteractionSensor
WorldSensor
SessionRecorder
Timeline
JSON exporter
```

Target: satu sesi bermain bisa direkam.

### Phase 4 — Semantic model

Bikin:

```text
EntityClassifier
EventCorrelator
InventorySensor
semantic actions
```

Target:

```text
raw events
→ Pickup
→ Sell
```

### Phase 5 — Automation engine

Bikin:

```text
FSM
TargetSelector
Navigator
InteractionController
Validator
```

Target: workflow tycoon sederhana.

### Phase 6 — Workflow engine

Bikin:

```text
workflow-as-data
workflow runner
visualizer
```

Target: behavior tidak hard-coded.

### Phase 7 — Replay

Bikin:

```text
ReplayClock
ReplaySession
state reconstruction
```

### Phase 8 — Analytics

Bikin:

```text
cycle time
route efficiency
value per minute
failure rate
```

---

# 64. Hal yang jangan dilakukan

Ini anti-pattern paling umum:

```text
❌ satu file 15k lines

❌ semua module scan Workspace sendiri

❌ UI langsung melakukan automation logic

❌ movement + decision + interaction dalam satu loop

❌ giant if game.PlaceId chain

❌ hard-code object path di core

❌ print debugging dimana-mana

❌ semua state global

❌ event connection tidak pernah cleanup

❌ blocking Wait() di banyak tempat

❌ tidak ada timeout

❌ assume action selalu sukses

❌ config tanpa versioning

❌ event schema tidak konsisten

❌ game-specific logic masuk core

❌ premature abstraction di semua tempat
```

Yang terakhir penting juga.

Jangan over-engineer.

Misalnya hanya punya 10 item:

```text
linear nearest search
```

sudah cukup.

Jangan langsung implement octree.

---

# 65. Boundary yang paling penting

Kalau gue harus merangkum arsitektur ini jadi satu prinsip:

```text
OBSERVE
↓
MODEL
↓
DECIDE
↓
ACT
↓
VALIDATE
↓
RECORD
```

Bukan:

```text
scan → do random thing → loop
```

Dan mapping module-nya:

```text
OBSERVE
Sensors

MODEL
WorldModel

DECIDE
Planner + TargetSelector

ACT
Navigator + InteractionController

VALIDATE
Validator

RECORD
EventBus + SessionRecorder
```

Itu menurut gue merupakan fondasi paling sehat.

---

Kalau project ini benar-benar mau dibangun, **MVP yang paling tepat bukan autofarm dulu**. MVP-nya adalah:

```text
1. WorldModel
2. Entity inspector
3. Asset scanner
4. Interaction recorder
5. Movement recorder
6. Timeline
7. Adapter registry
8. Satu SimpleTycoonAdapter
```

Setelah itu baru Automation Engine. Alasannya sederhana: kalau observability-nya bagus, automation jadi gampang. Kalau langsung bikin automation dulu, lu akan habiskan waktu debugging sesuatu yang sistemnya sendiri nggak bisa menjelaskan sedang terjadi apa.

Kalau gue yang lead project ini, milestone pertama yang gue targetkan adalah **“record satu sesi manual dan menghasilkan timeline semantik yang jelas”**. Setelah itu baru `timeline → workflow → replay/automation`. Itu jalur paling scalable dan paling sedikit technical debt.