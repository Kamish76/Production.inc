# 🎨 Production.INC — Icon Asset Design Roadmap & Batch Production Guide (`ICON_DESIGN_ROADMAP.md`)

> **Document Purpose**: A prioritized, batch-by-batch asset production guide for creating custom iconography for **Production.INC**.
> 
> 🎯 **Design Strategy**: Instead of tackling 80+ icons at once, this guide breaks all game assets into **8 manageable, bite-sized batches (8–11 icons per batch)** strictly ordered by gameplay priority. You can work on one batch at a time without feeling overwhelmed, test them immediately in-game, and steadily progress through factory expansion tiers.

---

## 📊 Master Production Dashboard

Track your overall asset completion progress across all batches:

| Batch | Theme / Domain | Icons | Game Progression Phase | Status | Progress |
| :---: | :--- | :---: | :--- | :---: | :---: |
| **Batch 1** | **Core Foundation: Raw Materials & Starter Parts** | **10** | Tier 1: Garage Workshop | 📋 Ready | `0 / 10` |
| **Batch 2** | **Factory Machinery & Logistics Fleet** | **11** | Core Automation & Shipping | 📋 Ready | `0 / 11` |
| **Batch 3** | **Tier 2 Intermediates & Early Retail** | **10** | Tier 2: Light Assembly Facility | 📋 Ready | `0 / 10` |
| **Batch 4** | **Specialized Branches: Robotics & Clean Energy** | **10** | Branch Specialization | 📋 Ready | `0 / 10` |
| **Batch 5** | **Complex Parts, Flagships & Factory Tiers** | **11** | Tier 3–4: Precision & Megafactory | 📋 Ready | `0 / 11` |
| **Batch 6** | **R&D Tech Tree, Lab Systems & Corporate Clients** | **10** | Phase 4: R&D & B2B Contracts | 📋 Ready | `0 / 10` |
| **Batch 7** | **Prestige IPO & Quantum Prototypes** | **8** | Phase 5: Wall Street Prestige | 📋 Ready | `0 / 8` |
| **Batch 8** | **UI HUD, Navigation & Action Badges** | **10** | System Polish & Navigation | 📋 Ready | `0 / 10` |
| **TOTAL** | **Complete Game Asset Suite** | **80** | **All Game Phases** | 🎨 **Backlog** | **`0 / 80`** |

---

## 🛠️ Technical Asset Specifications & Guidelines

To ensure your icons look uniform, crisp, and high-quality across all screen sizes and resolutions:

### 1. Canvas & Export Specs
- **Canvas Size**: `256 × 256 px` master canvas (downsamples cleanly to `48px`, `32px`, and `24px` in Flutter).
- **Format**: Transparent 32-bit PNG (`.png`) with clean alpha channel edges (no jagged white halos).
- **Safe Area / Padding**: Keep glyph artwork within an inner `216 × 216 px` bounding box (leaving `20px` perimeter padding so glowing borders or drop shadows aren't clipped).
- **Style Language**: Isometric or subtle 2.5D front-angle presentation, semi-stylized modern industrial aesthetic. Crisp outlines, subtle ambient occlusion, and vibrant neon accents that pop against dark backgrounds (`#1A1A2E`, `#263238`).

### 2. Suggested Directory Structure
Store your exported PNGs inside `assets/images/icons/` partitioned by category:
```text
assets/
└── images/
    ├── AppIcon.png
    └── icons/
        ├── materials/      # Raw materials (cardboard, metals, glass...)
        ├── products/       # Manufactured parts & retail products
        ├── machines/       # Auto-buy, auto-build, auto-sell, tools
        ├── fleet/          # Courier bikes, vans, trucks, cargo planes
        ├── tiers/          # Factory tier emblems
        ├── research/       # Tech tree nodes, RP, deconstruction bay
        ├── clients/        # Corporate client emblems
        ├── prestige/       # Golden share, IPO bell, prototype emblems
        └── ui/             # Navigation tabs, manifest cart, HUD badges
```

### 3. Industry Branch Color Coding Guide
Use these standard accent highlights so players intuitively identify product families:
- 📱 **Consumer Electronics / Foundation**: Electric Cyan (`#00E5FF`) & Tech Blue (`#2196F3`)
- 🤖 **Robotics & Automation**: High-Torque Violet (`#B388FF`) & Cyber Silver (`#ECEFF1`)
- ⚡ **Renewable Energy & Storage**: Solar Gold (`#FFB300`) & Neon Emerald (`#00E676`)
- 🏭 **Industrial Machinery**: Construction Amber (`#FF9800`) & Steel Grey (`#78909C`)
- 💎 **Prestige & Prototypes**: Radiant Qubit Teal (`#1DE9B6`) & Golden Ratio (`#FFD700`)

---

## 📦 Batch 1: Core Foundation — Raw Materials & Starter Parts (Priority: ★★★★★)

> **Goal**: Replace the very first things every player sees in the first 5 minutes of gameplay: the 5 buyable materials and the initial 5 starter parts crafted in the Garage Workshop.

| Done | File Target | Item Name (`id`) | Current | Category | Visual Concept & Art Description | Dominant Color |
| :---: | :--- | :--- | :---: | :---: | :--- | :--- |
| [ ] | `icons/materials/mat_cardboard.png` | **Cardboard**<br>`cardboard` | 📄 | Raw Material | Stack of corrugated craft cardboard sheets with visible fluted edge ridges and a paper roll. | Warm Kraft Brown (`#C49A45`) |
| [ ] | `icons/materials/mat_basic_metals.png` | **Basic Metals**<br>`basic_metals` | 🔩 | Raw Material | Steel ingots stacked beside industrial hex bolts and copper wire strands. | Steel Slate & Copper (`#90A4AE`) |
| [ ] | `icons/materials/mat_plastic.png` | **Plastic**<br>`plastic` | 🧱 | Raw Material | Vibrant molded polymer pellets or injection-molding thermoplastic resin blocks. | Clean Polymer White/Cyan (`#80DEEA`) |
| [ ] | `icons/materials/mat_glass.png` | **Glass**<br>`glass` | 🪟 | Raw Material | Transparent pane of tempered architectural glass with specular blue light glints. | Ice Cyan Specular (`#E0F7FA`) |
| [ ] | `icons/materials/mat_advanced_metals.png` | **Advanced Metals**<br>`advanced_metals` | ⚡ | Raw Material | Titanium/aerospace alloy bar with laser-etched lattice lines and neodymium magnet sheen. | Electric Titanium (`#7C4DFF`) |
| [ ] | `icons/products/prod_box.png` | **Box**<br>`box` | 📦 | Basic Part | Sturdy taped corrugated packing box with packaging label and shipping stamps. | Classic Box Tan (`#D7A86E`) |
| [ ] | `icons/products/prod_wires.png` | **Wires**<br>`wires` | 🔌 | Basic Part | Bundle of flexible copper cables with color-coded red/blue/yellow rubber insulation sleeves. | Copper & Insulator Red (`#FF5252`) |
| [ ] | `icons/products/prod_circuits.png` | **Circuits**<br>`circuits` | 💾 | Basic Part | High-contrast green PCB board with gold solder traces, micro-resistors, and solder pads. | PCB Emerald & Gold (`#00C853`) |
| [ ] | `icons/products/prod_enclosure_plastic.png` | **Plastic Enclosure**<br>`enclosure_plastic` | 📱 | Basic Part | Molded matte plastic casing halves with screw bosses and snap-fit clips. | Matte Charcoal & Sky (`#455A64`) |
| [ ] | `icons/products/prod_metal_enclosure.png` | **Metal Enclosure**<br>`metal_enclosure` | 🏠 | Basic Part | Anodized extruded aluminum electronic chassis with ventilation heat dissipation grilles. | Brushed Aluminum (`#B0BEC5`) |

---

## ⚙️ Batch 2: Factory Machinery & Logistics Fleet (Priority: ★★★★★)

> **Goal**: Give tactile personality to the automation machines on the Control Screen and the shipping carriers on the Logistics Fleet screen.

| Done | File Target | Asset Name (`id`) | Current | Category | Visual Concept & Art Description | Dominant Color |
| :---: | :--- | :--- | :---: | :---: | :--- | :--- |
| [ ] | `icons/machines/mach_auto_buy.png` | **Auto-Buy Machine**<br>`buyer` | 🤖 | Automation Machine | Automated warehouse robotic procurement drone holding a barcode scanner and cargo pallet. | Supply Amber & Teal (`#FFB300`) |
| [ ] | `icons/machines/mach_build_basic.png` | **Basic Assembler**<br>`basic_assembler` | 🏭 | Automation Machine | Compact industrial assembly bench with hydraulic press arm and green cycle status LED. | Factory Blue (`#2196F3`) |
| [ ] | `icons/machines/mach_build_intermediate.png` | **Intermediate Assembler** | 🏭 | Automation Machine | Twin robotic arm workcell soldering precision circuit boards under an overhead clean light. | Precision Violet (`#7C4DFF`) |
| [ ] | `icons/machines/mach_build_complex.png` | **Complex Assembler** | 🔬 | Automation Machine | High-grade cleanroom chamber with vacuum suction manipulator and laser alignment beam. | Cleanroom Cyan (`#00E5FF`) |
| [ ] | `icons/machines/mach_auto_sell.png` | **Auto-Sell Dispatcher**<br>`basic_seller` | 🛒 | Automation Machine | Automated storefront fulfillment conveyor with checkout barcode laser and currency badge. | Commercial Emerald (`#00E676`) |
| [ ] | `icons/machines/tool_maintenance.png` | **Maintenance Checkup** | 🔧 | Tool / Diagnostics | High-tech adjustable torque wrench crossed with electronic oscilloscope diagnostic probe. | Warning Amber (`#FFA000`) |
| [ ] | `icons/machines/tool_salvage.png` | **Machine Salvage** | ♻️ | Tool / Decommission | Circular recycling arrows enclosing a disassembled gear and reclaim cash coin. | Eco Green & Silver (`#66BB6A`) |
| [ ] | `icons/fleet/fleet_courier_bike.png` | **Courier Bike (Tier 1)** | 🚲 | Logistics Fleet | Modern fixed-gear cargo bicycle with oversized insulated front rack and courier parcel bag. | Vibrant Orange (`#FF6E40`) |
| [ ] | `icons/fleet/fleet_delivery_van.png` | **Delivery Van (Tier 2)** | 🚐 | Logistics Fleet | Sleek electric commercial delivery van with side sliding door and corporate livery stripe. | Fleet Cobalt (`#1E88E5`) |
| [ ] | `icons/fleet/fleet_freight_truck.png` | **Freight Truck (Tier 3)** | 🚚 | Logistics Fleet | Heavy-duty 18-wheeler semi-truck cab with aerodynamic wind fairings and cargo container. | Heavy Industrial Crimson (`#E53935`) |
| [ ] | `icons/fleet/fleet_cargo_plane.png` | **Cargo Plane (Tier 4)** | ✈️ | Logistics Fleet | Twin-engine commercial airfreight cargo jet with nose cargo loading ramp open. | Aero Sky & Gold (`#00B0FF`) |

---

## 📺 Batch 3: Tier 2 Intermediates & Early Retail (Priority: ★★★★☆)

> **Goal**: Support the mid-game transition when the player unlocks the Light Assembly Facility and starts shipping high-margin consumer products like Speakers and Power Banks.

| Done | File Target | Item Name (`id`) | Current | Category | Visual Concept & Art Description | Dominant Color |
| :---: | :--- | :--- | :---: | :---: | :--- | :--- |
| [ ] | `icons/products/prod_sound_driver.png` | **Sound Driver**<br>`sound_driver` | 🔊 | Basic Part | Speaker cone transducer with concentric rubber surround, copper voice coil, and rear magnet. | Magnet Chrome & Copper (`#FF7043`) |
| [ ] | `icons/products/prod_lens.png` | **Lens**<br>`lens` | 🔍 | Basic Part | High-precision polished optical glass lens element in a threaded black aperture collar. | Optical Refraction Cyan (`#4DD0E1`) |
| [ ] | `icons/products/prod_battery.png` | **Battery**<br>`battery` | 🔋 | Basic Part | Rechargeable lithium-ion cylindrical cell with terminal caps and holographic safety badge. | Energy Green (`#76FF03`) |
| [ ] | `icons/products/prod_gears.png` | **Gears**<br>`gears` | ⚙️ | Basic Part | Pair of interlocking precision brass and steel spur gears with beveled teeth. | Brass Gold & Steel (`#FFD54F`) |
| [ ] | `icons/products/prod_solar_cells.png` | **Solar Cells**<br>`solar_cells` | ☀️ | Basic Part | Photovoltaic textured blue silicon wafer tile with silver grid busbars. | Solar Cobalt (`#1565C0`) |
| [ ] | `icons/products/prod_display_screen.png` | **Display Screen**<br>`display_screen` | 📺 | Intermediate Part | Ultra-thin bezel mobile OLED display panel showing glowing blue diagnostic test bars. | OLED Vibrant Cyan (`#00E5FF`) |
| [ ] | `icons/products/prod_processor.png` | **Processor**<br>`processor` | 🖥️ | Intermediate Part | Ceramic microprocessor chip package with nickel heat spreader, gold contact pins, and etched die logo. | Golden Silicon (`#FFC107`) |
| [ ] | `icons/products/prod_gear_mechanism.png` | **Gear Mechanism**<br>`gear_mechanism` | 🕰️ | Intermediate Part | Complex mechanical clockwork assembly with escapement wheel, coiled tension spring, and pinions. | Horology Bronze (`#D7CCC8`) |
| [ ] | `icons/products/prod_speaker.png` | **Speaker**<br>`speaker` | 🔈 | Retail Product | Compact portable Bluetooth bookshelf speaker with acoustic fabric grille and volume dial. | Audio Charcoal & Blue (`#37474F`) |
| [ ] | `icons/products/prod_power_bank.png` | **Power Bank**<br>`power_bank` | 🔌 | Retail Product | Slim pocket power bank with dual USB-C ports and illuminated 4-dot battery LED fuel gauge. | Matte Midnight (`#263238`) |

---

## 🤖 Batch 4: Specialized Branches — Robotics & Clean Energy (Priority: ★★★★☆)

> **Goal**: Support the Phase 3 industry branch choice (Robotics & Mechatronics vs. Renewable Energy & Storage).

| Done | File Target | Item Name (`id`) | Current | Category | Visual Concept & Art Description | Dominant Color |
| :---: | :--- | :--- | :---: | :---: | :--- | :--- |
| [ ] | `icons/products/prod_silicon_wafer.png` | **Silicon Wafer**<br>`silicon_wafer` | 💿 | Basic (Robotics) | Mirror-polished circular silicon ingot disc with iridescent rainbow diffraction pattern. | Rainbow Holographic (`#B388FF`) |
| [ ] | `icons/products/prod_copper_coils.png` | **Copper Coils**<br>`copper_coils` | 🧲 | Basic (Robotics) | Tightly wound electromagnetic copper magnet wire spool with exposed enameled terminals. | Polished Copper (`#D84315`) |
| [ ] | `icons/products/prod_servo_motor.png` | **Servo Motor**<br>`servo_motor` | 🦾 | Intermediate (Robotics) | High-torque micro metal-gear servo actuator with three-wire harness and spline output horn. | Mechatronics Blue & Silver (`#0288D1`) |
| [ ] | `icons/products/prod_microcontroller.png` | **Microcontroller**<br>`microcontroller` | 🔲 | Intermediate (Robotics) | Quad-flat package (QFP) IC chip mounted on breakout board with blinking status LED. | Microchip Violet (`#651FFF`) |
| [ ] | `icons/products/prod_chassis_alloy.png` | **Chassis Alloy**<br>`chassis_alloy` | 🛡️ | Intermediate (Robotics) | Hydroformed structural carbon-titanium skeletal beam with hexagonal weight-saving cutouts. | Aerospace Titanium (`#78909C`) |
| [ ] | `icons/products/prod_inverter_unit.png` | **Inverter Unit**<br>`inverter_unit` | ⚡ | Intermediate (Clean Energy) | Pure sine wave DC-to-AC power converter unit with aluminum cooling fins and LED voltage display. | High-Voltage Amber (`#FF9100`) |
| [ ] | `icons/products/prod_storage_cell.png` | **Storage Cell**<br>`storage_cell` | 🪫 | Intermediate (Clean Energy) | Prismatic heavy-duty solid-state battery block with laser-welded busbar terminals. | Emerald Storage (`#00C853`) |
| [ ] | `icons/products/prod_wall_clock.png` | **Analog Wall Clock**<br>`wall_clock` | 🕰️ | Retail Product | Minimalist Bauhaus wall clock with visible skeleton gear movement and sweep second hand. | Clockmaker Brass (`#A1887F`) |
| [ ] | `icons/products/prod_toy_robot.png` | **Toy Robot**<br>`toy_robot` | 🤖 | Retail (Robotics) | Retro-futuristic walking wind-up tin/plastic robot with illuminated dome head and gripper arms. | Cyber Turquoise (`#00BCD4`) |
| [ ] | `icons/products/prod_cleaning_drone.png` | **Cleaning Drone**<br>`cleaning_drone` | 🛸 | Retail (Robotics) | Sleek circular robotic vacuum and lidar mapping drone with glowing laser sensor turret. | Pearl White & Gloss Black (`#ECEFF1`) |

---

## 📱 Batch 5: Complex Parts, Flagships & Factory Tiers (Priority: ★★★☆☆)

> **Goal**: High-tier endgame products (Smartphones, Turbines, Robotic Arms) and the 4 Factory Tier progression emblems.

| Done | File Target | Item Name (`id`) | Current | Category | Visual Concept & Art Description | Dominant Color |
| :---: | :--- | :--- | :---: | :---: | :--- | :--- |
| [ ] | `icons/products/prod_image_sensor.png` | **Image Sensor**<br>`image_sensor` | 📸 | Intermediate Part | CMOS digital camera sensor chip with iridescent gold wire bonds and microscopic pixel grid. | Iridescent Purple & Gold (`#7B1FA2`) |
| [ ] | `icons/products/prod_camera_module.png` | **Camera Module**<br>`camera_module` | 📷 | Complex Part | Multi-element smartphone camera assembly with optical image stabilization (OIS) coils and flex cable. | Optical Jet Black (`#212121`) |
| [ ] | `icons/products/prod_solar_panel.png` | **Solar Panel**<br>`solar_panel` | 🌞 | Retail (Clean Energy) | Rigid aluminum-framed photovoltaic solar module angled on rooftop mounting brackets. | Deep Space Blue (`#0D47A1`) |
| [ ] | `icons/products/prod_camera.png` | **Digital Camera**<br>`camera` | 📹 | Retail Product | Compact mirrorless digital camera body with knurled exposure dial, LCD preview, and prime lens. | Magnesium Black (`#263238`) |
| [ ] | `icons/products/prod_smartphone.png` | **Smartphone**<br>`smartphone` | 📱 | Retail Product | Bezel-less flagship glass-slab smartphone with holographic edge screen and triple camera bump. | Sleek Sapphire (`#1A237E`) |
| [ ] | `icons/products/prod_robotic_arm.png` | **Robotic Arm**<br>`robotic_arm` | 🤖 | Retail (Robotics) | 6-axis industrial articulated manufacturing robot arm holding an automated welding head. | Industrial Safety Yellow (`#FDD835`) |
| [ ] | `icons/products/prod_home_powerwall.png` | **Home Powerwall**<br>`home_powerwall` | 🔋 | Retail (Clean Energy) | Wall-mounted residential smart battery storage cabinet with vertical pulsing LED pulse stripe. | Minimalist Matte White (`#ECEFF1`) |
| [ ] | `icons/products/prod_wind_turbine.png` | **Wind Turbine Generator**<br>`wind_turbine_generator` | 💨 | Retail (Clean Energy) | Three-bladed commercial wind turbine nacelle with aerodynamic tapered composite blades. | Clean Aero Cyan (`#80DEEA`) |
| [ ] | `icons/tiers/tier_1_garage.png` | **Tier 1: Garage Workshop** | 🏚️ | Factory Tier | Modest brick garage workshop with roller shutter, overhead bulb, and wooden workbench. | Rustic Brick Tan (`#8D6E63`) |
| [ ] | `icons/tiers/tier_2_assembly.png` | **Tier 2: Light Assembly** | 🏭 | Factory Tier | Steel pre-fab commercial light manufacturing building with exhaust vents and delivery bay. | Industrial Steel Blue (`#546E7A`) |
| [ ] | `icons/tiers/tier_3_precision.png` | **Tier 3: Precision Tech Plant** | 🔬 | Factory Tier | Futuristic corporate high-tech plant with glass atrium, cleanroom airlocks, and solar roof. | Cleanroom Aqua (`#00838F`) |
| [ ] | `icons/tiers/tier_4_megafactory.png` | **Tier 4: Megafactory** | 🚀 | Factory Tier | Massive sprawling gigafactory complex with automated monorails, drone docks, and glowing logo. | Hyper-Industrial Purple (`#311B92`) |

---

## 🔬 Batch 6: R&D Tech Tree, Lab Systems & Corporate Clients (Priority: ★★★☆☆)

> **Goal**: Visual identity for the R&D Research screen, research points, and the 3 B2B Corporate Clients who award contracts.

| Done | File Target | Item Name (`id`) | Current | Category | Visual Concept & Art Description | Dominant Color |
| :---: | :--- | :--- | :---: | :---: | :--- | :--- |
| [ ] | `icons/research/tech_material_science.png` | **Material Science Tech**<br>`material_science` | 🧬 | Tech Branch | Double-helix DNA strand fusing with crystal lattice nodes and replicating atoms. | Bio-Synthetic Green (`#00E676`) |
| [ ] | `icons/research/tech_factory_overclock.png` | **Factory Overclocking Tech**<br>`factory_overclocking` | ⚡ | Tech Branch | Mechanical cog surrounded by intense electrical plasma arcs and tachometer rev needle. | Overclock Neon Orange (`#FF3D00`) |
| [ ] | `icons/research/tech_logistics_opt.png` | **Logistics Optimization Tech**<br>`logistics_optimization` | 🚀 | Tech Branch | Supersonic cargo container rocket blasting through a quantum hyperlane transport ring. | Hyperlane Cyan (`#00E5FF`) |
| [ ] | `icons/research/res_points_rp.png` | **Research Points (RP)** | 🧪 | Game Currency | Glowing spherical energy orb suspended inside a magnetic containment beaker with orbiting electrons. | Plasma Cyan Glow (`#18FFFF`) |
| [ ] | `icons/research/lab_deconstruction.png` | **Deconstruction Bay** | 🔬 | Lab Facility | Laser disassembly chamber breaking down a circuit board into glowing constituent atoms. | Laser Ruby Red (`#FF1744`) |
| [ ] | `icons/research/lab_overclock_toggle.png` | **Overclock Gauge / Switch** | 🔥 | Telemetry | Dual-needle boost pressure gauge entering redline zone with flame particle effects. | Thermal Crimson (`#D50000`) |
| [ ] | `icons/research/lab_thermal_wear.png` | **Machine Wear / Health** | 🌡️ | Telemetry | Heartbeat/vital waveform integrated into a gear silhouette indicating machinery health. | Diagnostics Amber (`#FFC400`) |
| [ ] | `icons/clients/client_apex_telecom.png` | **Apex Telecom**<br>`apex_telecom` | 📡 | Corporate Client | Satellite communications dish emitting orbital signal waves over a stylized global wireframe. | Cyber Cyan (`#00E5FF`) |
| [ ] | `icons/clients/client_solaria_energy.png` | **Solaria Energy**<br>`solaria_energy` | ☀️ | Corporate Client | Geometric radiant solar corona crest with photovoltaic sunbeam vectors. | Solar Gold (`#FFB300`) |
| [ ] | `icons/clients/client_nova_robotics.png` | **Nova Robotics**<br>`nova_robotics` | 🤖 | Corporate Client | Stylized geometric android head silhouette with glowing hexagonal optics visor. | Android Violet (`#B388FF`) |

---

## 💎 Batch 7: Prestige IPO & Quantum Prototypes (Priority: ★★☆☆☆)

> **Goal**: Late-game prestige assets for taking Production.INC public on Wall Street, earning Golden Shares, and crafting high-margin Prototype Blueprints.

| Done | File Target | Item Name (`id`) | Current | Category | Visual Concept & Art Description | Dominant Color |
| :---: | :--- | :--- | :---: | :---: | :--- | :--- |
| [ ] | `icons/prestige/curr_golden_share.png` | **Golden Share** | 📜 | Prestige Currency | Holographic gold stock certificate embossed with an illuminated factory emblem and diamond watermark. | Brilliant Gold (`#FFD700`) |
| [ ] | `icons/prestige/ipo_wall_st_bell.png` | **IPO Wall Street Bell** | 🔔 | Prestige Milestone | Polished brass exchange opening bell on an oak mount surrounded by ticker tape confetti. | Polished Brass (`#FFA000`) |
| [ ] | `icons/products/prod_quantum_processor.png` | **Quantum Processor**<br>`quantum_processor` | 💠 | Prototype Intermediate | Gold dilution refrigerator cold-finger chip packaging quantum qubit waveguides with blue zero-point glow. | Cryogenic Cyan (`#00E5FF`) |
| [ ] | `icons/products/prod_quantum_core.png` | **Quantum Core**<br>`quantum_core` | ⚛️ | Prototype Complex | Toroidal magnetic confinement reactor vessel trapping a swirling zero-point fusion singularity. | Singularity Violet (`#D500F9`) |
| [ ] | `icons/products/prod_orbital_satellite.png` | **Orbital Satellite**<br>`orbital_satellite` | 🛰️ | Prototype Retail | Golden foil-wrapped cube-sat payload deploying dual solar wings and quantum communication dish in orbit. | Orbital Gold & Void (`#FFEA00`) |
| [ ] | `icons/prestige/perk_instant_machines.png` | **Instant Machine Licensing** | ⚙️ | Prestige Perk | Golden gear fitted with a lightning bolt key bypassing a padlock. | Gilded Amber (`#FFC107`) |
| [ ] | `icons/prestige/perk_angel_capital.png` | **Angel Seed Capital** | 💼 | Prestige Perk | Gilded leather investor briefcase overflowing with stacks of cash and gold bullion. | Venture Emerald (`#00E676`) |
| [ ] | `icons/prestige/perk_quantum_warp.png` | **Quantum Warp Logistics** | 🌌 | Prestige Perk | Spiral galactic hyperspace wormhole gateway bending transit light vectors. | Cosmic Indigo (`#3D5AFE`) |

---

## 🧭 Batch 8: UI HUD, Navigation & Action Badges (Priority: ★★☆☆☆)

> **Goal**: Custom branded navigation and telemetry badges that replace default Flutter Material icons for a truly premium, bespoke app feel.

| Done | File Target | Badge Name | Current | Category | Visual Concept & Art Description | Dominant Color |
| :---: | :--- | :--- | :---: | :---: | :--- | :--- |
| [ ] | `icons/ui/nav_buy.png` | **Buy Materials Tab** | 🛒 | Bottom Nav | Sleek industrial procurement crate with an inward-pointing download arrow. | Emerald Green (`#4CAF50`) |
| [ ] | `icons/ui/nav_build.png` | **Build Products Tab** | 🔨 | Bottom Nav | Crossed pneumatic riveting gun and precision calipers. | Electric Blue (`#2196F3`) |
| [ ] | `icons/ui/nav_sell.png` | **Sell Commercial Tab** | 💰 | Bottom Nav | Outgoing shipping crate embossed with an upward profit trend arrow. | Regal Purple (`#AB47BC`) |
| [ ] | `icons/ui/nav_shipping.png` | **Shipping Logistics Tab** | 🚚 | Bottom Nav | Aerodynamic courier delivery carrier vehicle in swift forward motion. | Fleet Orange (`#FF9800`) |
| [ ] | `icons/ui/nav_control.png` | **Control Center Tab** | 🎛️ | Bottom Nav | Industrial master control console with slider dials and digital telemetry gauges. | Control Cyan (`#00BCD4`) |
| [ ] | `icons/ui/hud_cash.png` | **Cash Currency Emblem** | 💵 | HUD Currency | Glossy embossed dollar emblem coin with high-tech minting bevels. | Money Green (`#43A047`) |
| [ ] | `icons/ui/hud_reputation.png` | **Corporate Rep Star** | ⭐ | HUD Metric | Five-pointed faceted military/corporate star medal with laurel leaf wreath. | Prestige Amber (`#FFB300`) |
| [ ] | `icons/ui/hud_manifest_cart.png` | **Bulk Manifest Staging Tray** | 📦 | HUD Staging | Staged cargo pallet crate with a dynamic inventory item count badge. | Manifest Cobalt (`#2979FF`) |
| [ ] | `icons/ui/hud_transit_timer.png` | **Transit Speed Timer** | ⏱️ | Telemetry | Stopwatch dial surrounded by motion speed streaks indicating active carrier transit. | Speed Yellow (`#FFD600`) |
| [ ] | `icons/ui/hud_tier_lock.png` | **Tier Requirement Lock** | 🔒 | UI State | High-tech electronic biometric padlock with red/green access status LED. | Secure Slate & Red (`#EF5350`) |

---

## 💻 Flutter Code Implementation Architecture

Once you begin creating icon assets, here is how the codebase can cleanly and safely consume them with zero regressions:

### 1. `pubspec.yaml` Asset Registration
Ensure your assets directory is declared:
```yaml
flutter:
  assets:
    - assets/images/
    - assets/images/icons/materials/
    - assets/images/icons/products/
    - assets/images/icons/machines/
    - assets/images/icons/fleet/
    - assets/images/icons/tiers/
    - assets/images/icons/research/
    - assets/images/icons/clients/
    - assets/images/icons/prestige/
    - assets/images/icons/ui/
```

### 2. Backward-Compatible `GameIcon` Widget
Create a centralized helper widget `lib/widgets/game_icon.dart` that automatically displays the custom PNG asset if available, and gracefully falls back to the existing Unicode emoji if you haven't drawn that icon yet:

```dart
import 'package:flutter/material.dart';

class GameIcon extends StatelessWidget {
  final String? assetPath;
  final String fallbackEmoji;
  final double size;

  const GameIcon({
    super.key,
    this.assetPath,
    required this.fallbackEmoji,
    this.size = 24.0,
  });

  @override
  Widget build(BuildContext context) {
    if (assetPath != null && assetPath!.isNotEmpty) {
      return Image.asset(
        assetPath!,
        width: size,
        height: size,
        errorBuilder: (context, error, stackTrace) {
          // Graceful fallback to emoji if PNG is missing or misnamed
          return Text(
            fallbackEmoji,
            style: TextStyle(fontSize: size * 0.85),
          );
        },
      );
    }
    return Text(
      fallbackEmoji,
      style: TextStyle(fontSize: size * 0.85),
    );
  }
}
```

This guarantees:
1. **Zero Broken Builds**: You can draw and drop in 1 icon, 10 icons, or an entire batch at your own pace.
2. **Instant Visual Testing**: The moment you save `assets/images/icons/...` and trigger hot reload, your drawn icon appears immediately in-game without touching complex screen logic!

---

## 🎯 Recommended Next Step
Start with **Batch 1 (10 icons)**:
1. `mat_cardboard.png`
2. `mat_basic_metals.png`
3. `mat_plastic.png`
4. `mat_glass.png`
5. `mat_advanced_metals.png`
6. `prod_box.png`
7. `prod_wires.png`
8. `prod_circuits.png`
9. `prod_enclosure_plastic.png`
10. `prod_metal_enclosure.png`

Completing Batch 1 will instantly transform the first screen (`Buy Materials`) and starter crafting cards (`Build Products`) into polished, custom art!
