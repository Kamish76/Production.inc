# 🎨 Production.INC — Icon Asset Design Roadmap & Batch Production Guide (`ICON_DESIGN_ROADMAP.md`)

> **Document Purpose**: A prioritized, batch-by-batch asset production guide for creating custom iconography for **Production.INC**.
> 
> 🎯 **Design Strategy**: Instead of tackling 80+ icons at once, this guide breaks all game assets into **8 manageable, bite-sized batches (8–11 icons per batch)** strictly ordered by gameplay priority. You can work on one batch at a time without feeling overwhelmed, test them immediately in-game, and steadily progress through factory expansion tiers.

---

## 📊 Master Production Dashboard

Track your overall asset completion progress across all batches:

| Batch | Theme / Domain | Icons | Game Progression Phase | Status | Progress |
| :---: | :--- | :---: | :--- | :---: | :---: |
| **Batch 1** | **Core Foundation: Raw Materials & Starter Parts** | **10** | Tier 1: Garage Workshop | ✅ Complete | `10 / 10` |
| **Batch 2** | **Factory Machinery & Logistics Fleet** | **11** | Core Automation & Shipping | 📋 Ready | `0 / 11` |
| **Batch 3** | **Tier 2 Intermediates & Early Retail** | **10** | Tier 2: Light Assembly Facility | 📋 Ready | `0 / 10` |
| **Batch 4** | **Specialized Branches: Robotics & Clean Energy** | **10** | Branch Specialization | 📋 Ready | `0 / 10` |
| **Batch 5** | **Complex Parts, Flagships & Factory Tiers** | **11** | Tier 3–4: Precision & Megafactory | 📋 Ready | `0 / 11` |
| **Batch 6** | **R&D Tech Tree, Lab Systems & Corporate Clients** | **10** | Phase 4: R&D & B2B Contracts | 📋 Ready | `0 / 10` |
| **Batch 7** | **Prestige IPO & Quantum Prototypes** | **8** | Phase 5: Wall Street Prestige | 📋 Ready | `0 / 8` |
| **Batch 8** | **UI HUD, Navigation & Action Badges** | **10** | System Polish & Navigation | 📋 Ready | `0 / 10` |
| **TOTAL** | **Complete Game Asset Suite** | **80** | **All Game Phases** | 🎨 **In Progress** | **`10 / 80` (12.5%)** |

---

## 🛠️ Technical Asset Specifications & Guidelines

To ensure your icons look uniform, crisp, and high-quality across all screen sizes and resolutions:

### 1. Canvas & Export Specs
- **Canvas Size**: `256 × 256 px` or `512 × 512 px` master canvas (scales infinitely in Flutter via vector math).
- **Format**: Scalable Vector Graphics (`.svg`) rendered natively via [`flutter_svg`](https://pub.dev/packages/flutter_svg).
- **Alpha Transparency**: 100% transparent backgrounds (`alpha = 0`) around glyphs—zero solid background rectangles, cards, or borders, allowing the art to float seamlessly on dark game cards (`#1A1A2E`, `#263238`).
- **Canva 3D & Vector Integration**: For complex 3D renders created in Canva or Blender (specular glass, metallic bevels, glowing neon veins), background removal is applied (via Apple Vision foreground segmentation or color flood fill) and the crisp transparent artwork is packaged into standard SVG containers (`<svg viewBox="0 0 512 512"><image href="data:image/png;base64,..."/>`). This combines photorealistic 3D lighting with universal `.svg` format consistency across the app.
- **Safe Area / Padding**: Keep glyph artwork within an inner safe bounding box (leaving ~10% perimeter padding so glowing borders or drop shadows aren't clipped).
- **Style Language**: Isometric or subtle 2.5D front-angle presentation, semi-stylized modern industrial aesthetic. Crisp outlines, subtle ambient occlusion, and vibrant neon accents that pop against dark backgrounds (`#1A1A2E`, `#263238`).

### 2. Suggested Directory Structure
Store your exported SVGs inside `assets/images/icons/` partitioned by category:
```text
assets/
└── images/
    ├── AppIcon.png
    └── icons/
        ├── materials/      # Raw materials (mat_cardboard.svg, mat_glass.svg...)
        ├── products/       # Manufactured parts & retail products (prod_box.svg...)
        ├── machines/       # Auto-buy, auto-build, auto-sell, tools (mach_*.svg)
        ├── fleet/          # Courier bikes, vans, trucks, cargo planes (fleet_*.svg)
        ├── tiers/          # Factory tier emblems (tier_*.svg)
        ├── research/       # Tech tree nodes, RP, deconstruction bay (tech_*.svg)
        ├── clients/        # Corporate client emblems (client_*.svg)
        ├── prestige/       # Golden share, IPO bell, prototype emblems (perk_*.svg)
        └── ui/             # Navigation tabs, manifest cart, HUD badges (nav_*.svg)
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
| [x] | `icons/materials/mat_cardboard.svg` | **Cardboard**<br>`cardboard` | 📄 | Raw Material | Stack of corrugated craft cardboard sheets with visible fluted edge ridges and a paper roll. | Warm Kraft Brown (`#C49A45`) |
| [x] | `icons/materials/mat_basic_metals.svg` | **Basic Metals**<br>`basic_metals` | 🔩 | Raw Material | Steel ingots stacked beside industrial hex bolts and copper wire strands. | Steel Slate & Copper (`#90A4AE`) |
| [x] | `icons/materials/mat_plastic.svg` | **Plastic**<br>`plastic` | 🧱 | Raw Material | Vibrant molded polymer pellets or injection-molding thermoplastic resin blocks. | Clean Polymer White/Cyan (`#80DEEA`) |
| [x] | `icons/materials/mat_glass.svg` | **Glass**<br>`glass` | 🪟 | Raw Material | Transparent pane of tempered architectural glass with specular blue light glints. | Ice Cyan Specular (`#E0F7FA`) |
| [x] | `icons/materials/mat_advanced_metals.svg` | **Advanced Metals**<br>`advanced_metals` | ⚡ | Raw Material | Titanium/aerospace alloy bar with laser-etched lattice lines and neodymium magnet sheen. | Electric Titanium (`#7C4DFF`) |
| [x] | `icons/products/prod_box.svg` | **Box**<br>`box` | 📦 | Basic Part | Sturdy taped corrugated packing box with packaging label and shipping stamps. | Classic Box Tan (`#D7A86E`) |
| [x] | `icons/products/prod_wires.svg` | **Wires**<br>`wires` | 🔌 | Basic Part | Bundle of flexible copper cables with color-coded red/blue/yellow rubber insulation sleeves. | Copper & Insulator Red (`#FF5252`) |
| [x] | `icons/products/prod_circuits.svg` | **Circuits**<br>`circuits` | 💾 | Basic Part | High-contrast green PCB board with gold solder traces, micro-resistors, and solder pads. | PCB Emerald & Gold (`#00C853`) |
| [x] | `icons/products/prod_enclosure_plastic.svg` | **Plastic Enclosure**<br>`enclosure_plastic` | 📱 | Basic Part | Molded matte plastic casing halves with screw bosses and snap-fit clips. | Matte Charcoal & Sky (`#455A64`) |
| [x] | `icons/products/prod_metal_enclosure.svg` | **Metal Enclosure**<br>`metal_enclosure` | 🏠 | Basic Part | Anodized extruded aluminum electronic chassis with ventilation heat dissipation grilles. | Brushed Aluminum (`#B0BEC5`) |

---

## ⚙️ Batch 2: Factory Machinery & Logistics Fleet (Priority: ★★★★★)

> **Goal**: Give tactile personality to the automation machines on the Control Screen and the shipping carriers on the Logistics Fleet screen.

| Done | File Target | Asset Name (`id`) | Current | Category | Visual Concept & Art Description | Dominant Color |
| :---: | :--- | :--- | :---: | :---: | :--- | :--- |
| [ ] | `icons/machines/mach_auto_buy.svg` | **Auto-Buy Machine**<br>`buyer` | 🤖 | Automation Machine | Automated warehouse robotic procurement drone holding a barcode scanner and cargo pallet. | Supply Amber & Teal (`#FFB300`) |
| [ ] | `icons/machines/mach_build_basic.svg` | **Basic Assembler**<br>`basic_assembler` | 🏭 | Automation Machine | Compact industrial assembly bench with hydraulic press arm and green cycle status LED. | Factory Blue (`#2196F3`) |
| [ ] | `icons/machines/mach_build_intermediate.svg` | **Intermediate Assembler** | 🏭 | Automation Machine | Twin robotic arm workcell soldering precision circuit boards under an overhead clean light. | Precision Violet (`#7C4DFF`) |
| [ ] | `icons/machines/mach_build_complex.svg` | **Complex Assembler** | 🔬 | Automation Machine | High-grade cleanroom chamber with vacuum suction manipulator and laser alignment beam. | Cleanroom Cyan (`#00E5FF`) |
| [ ] | `icons/machines/mach_auto_sell.svg` | **Auto-Sell Dispatcher**<br>`basic_seller` | 🛒 | Automation Machine | Automated storefront fulfillment conveyor with checkout barcode laser and currency badge. | Commercial Emerald (`#00E676`) |
| [ ] | `icons/machines/tool_maintenance.svg` | **Maintenance Checkup** | 🔧 | Tool / Diagnostics | High-tech adjustable torque wrench crossed with electronic oscilloscope diagnostic probe. | Warning Amber (`#FFA000`) |
| [ ] | `icons/machines/tool_salvage.svg` | **Machine Salvage** | ♻️ | Tool / Decommission | Circular recycling arrows enclosing a disassembled gear and reclaim cash coin. | Eco Green & Silver (`#66BB6A`) |
| [ ] | `icons/fleet/fleet_courier_bike.svg` | **Courier Bike (Tier 1)** | 🚲 | Logistics Fleet | Modern fixed-gear cargo bicycle with oversized insulated front rack and courier parcel bag. | Vibrant Orange (`#FF6E40`) |
| [ ] | `icons/fleet/fleet_delivery_van.svg` | **Delivery Van (Tier 2)** | 🚐 | Logistics Fleet | Sleek electric commercial delivery van with side sliding door and corporate livery stripe. | Fleet Cobalt (`#1E88E5`) |
| [ ] | `icons/fleet/fleet_freight_truck.svg` | **Freight Truck (Tier 3)** | 🚚 | Logistics Fleet | Heavy-duty 18-wheeler semi-truck cab with aerodynamic wind fairings and cargo container. | Heavy Industrial Crimson (`#E53935`) |
| [ ] | `icons/fleet/fleet_cargo_plane.svg` | **Cargo Plane (Tier 4)** | ✈️ | Logistics Fleet | Twin-engine commercial airfreight cargo jet with nose cargo loading ramp open. | Aero Sky & Gold (`#00B0FF`) |

---

## 📺 Batch 3: Tier 2 Intermediates & Early Retail (Priority: ★★★★☆)

> **Goal**: Support the mid-game transition when the player unlocks the Light Assembly Facility and starts shipping high-margin consumer products like Speakers and Power Banks.

| Done | File Target | Item Name (`id`) | Current | Category | Visual Concept & Art Description | Dominant Color |
| :---: | :--- | :--- | :---: | :---: | :--- | :--- |
| [ ] | `icons/products/prod_sound_driver.svg` | **Sound Driver**<br>`sound_driver` | 🔊 | Basic Part | Speaker cone transducer with concentric rubber surround, copper voice coil, and rear magnet. | Magnet Chrome & Copper (`#FF7043`) |
| [ ] | `icons/products/prod_lens.svg` | **Lens**<br>`lens` | 🔍 | Basic Part | High-precision polished optical glass lens element in a threaded black aperture collar. | Optical Refraction Cyan (`#4DD0E1`) |
| [ ] | `icons/products/prod_battery.svg` | **Battery**<br>`battery` | 🔋 | Basic Part | Rechargeable lithium-ion cylindrical cell with terminal caps and holographic safety badge. | Energy Green (`#76FF03`) |
| [ ] | `icons/products/prod_gears.svg` | **Gears**<br>`gears` | ⚙️ | Basic Part | Pair of interlocking precision brass and steel spur gears with beveled teeth. | Brass Gold & Steel (`#FFD54F`) |
| [ ] | `icons/products/prod_solar_cells.svg` | **Solar Cells**<br>`solar_cells` | ☀️ | Basic Part | Photovoltaic textured blue silicon wafer tile with silver grid busbars. | Solar Cobalt (`#1565C0`) |
| [ ] | `icons/products/prod_display_screen.svg` | **Display Screen**<br>`display_screen` | 📺 | Intermediate Part | Ultra-thin bezel mobile OLED display panel showing glowing blue diagnostic test bars. | OLED Vibrant Cyan (`#00E5FF`) |
| [ ] | `icons/products/prod_processor.svg` | **Processor**<br>`processor` | 🖥️ | Intermediate Part | Ceramic microprocessor chip package with nickel heat spreader, gold contact pins, and etched die logo. | Golden Silicon (`#FFC107`) |
| [ ] | `icons/products/prod_gear_mechanism.svg` | **Gear Mechanism**<br>`gear_mechanism` | 🕰️ | Intermediate Part | Complex mechanical clockwork assembly with escapement wheel, coiled tension spring, and pinions. | Horology Bronze (`#D7CCC8`) |
| [ ] | `icons/products/prod_speaker.svg` | **Speaker**<br>`speaker` | 🔈 | Retail Product | Compact portable Bluetooth bookshelf speaker with acoustic fabric grille and volume dial. | Audio Charcoal & Blue (`#37474F`) |
| [ ] | `icons/products/prod_power_bank.svg` | **Power Bank**<br>`power_bank` | 🔌 | Retail Product | Slim pocket power bank with dual USB-C ports and illuminated 4-dot battery LED fuel gauge. | Matte Midnight (`#263238`) |

---

## 🤖 Batch 4: Specialized Branches — Robotics & Clean Energy (Priority: ★★★★☆)

> **Goal**: Support the Phase 3 industry branch choice (Robotics & Mechatronics vs. Renewable Energy & Storage).

| Done | File Target | Item Name (`id`) | Current | Category | Visual Concept & Art Description | Dominant Color |
| :---: | :--- | :--- | :---: | :---: | :--- | :--- |
| [ ] | `icons/products/prod_silicon_wafer.svg` | **Silicon Wafer**<br>`silicon_wafer` | 💿 | Basic (Robotics) | Mirror-polished circular silicon ingot disc with iridescent rainbow diffraction pattern. | Rainbow Holographic (`#B388FF`) |
| [ ] | `icons/products/prod_copper_coils.svg` | **Copper Coils**<br>`copper_coils` | 🧲 | Basic (Robotics) | Tightly wound electromagnetic copper magnet wire spool with exposed enameled terminals. | Polished Copper (`#D84315`) |
| [ ] | `icons/products/prod_servo_motor.svg` | **Servo Motor**<br>`servo_motor` | 🦾 | Intermediate (Robotics) | High-torque micro metal-gear servo actuator with three-wire harness and spline output horn. | Mechatronics Blue & Silver (`#0288D1`) |
| [ ] | `icons/products/prod_microcontroller.svg` | **Microcontroller**<br>`microcontroller` | 🔲 | Intermediate (Robotics) | Quad-flat package (QFP) IC chip mounted on breakout board with blinking status LED. | Microchip Violet (`#651FFF`) |
| [ ] | `icons/products/prod_chassis_alloy.svg` | **Chassis Alloy**<br>`chassis_alloy` | 🛡️ | Intermediate (Robotics) | Hydroformed structural carbon-titanium skeletal beam with hexagonal weight-saving cutouts. | Aerospace Titanium (`#78909C`) |
| [ ] | `icons/products/prod_inverter_unit.svg` | **Inverter Unit**<br>`inverter_unit` | ⚡ | Intermediate (Clean Energy) | Pure sine wave DC-to-AC power converter unit with aluminum cooling fins and LED voltage display. | High-Voltage Amber (`#FF9100`) |
| [ ] | `icons/products/prod_storage_cell.svg` | **Storage Cell**<br>`storage_cell` | 🪫 | Intermediate (Clean Energy) | Prismatic heavy-duty solid-state battery block with laser-welded busbar terminals. | Emerald Storage (`#00C853`) |
| [ ] | `icons/products/prod_wall_clock.svg` | **Analog Wall Clock**<br>`wall_clock` | 🕰️ | Retail Product | Minimalist Bauhaus wall clock with visible skeleton gear movement and sweep second hand. | Clockmaker Brass (`#A1887F`) |
| [ ] | `icons/products/prod_toy_robot.svg` | **Toy Robot**<br>`toy_robot` | 🤖 | Retail (Robotics) | Retro-futuristic walking wind-up tin/plastic robot with illuminated dome head and gripper arms. | Cyber Turquoise (`#00BCD4`) |
| [ ] | `icons/products/prod_cleaning_drone.svg` | **Cleaning Drone**<br>`cleaning_drone` | 🛸 | Retail (Robotics) | Sleek circular robotic vacuum and lidar mapping drone with glowing laser sensor turret. | Pearl White & Gloss Black (`#ECEFF1`) |

---

## 📱 Batch 5: Complex Parts, Flagships & Factory Tiers (Priority: ★★★☆☆)

> **Goal**: High-tier endgame products (Smartphones, Turbines, Robotic Arms) and the 4 Factory Tier progression emblems.

| Done | File Target | Item Name (`id`) | Current | Category | Visual Concept & Art Description | Dominant Color |
| :---: | :--- | :--- | :---: | :---: | :--- | :--- |
| [ ] | `icons/products/prod_image_sensor.svg` | **Image Sensor**<br>`image_sensor` | 📸 | Intermediate Part | CMOS digital camera sensor chip with iridescent gold wire bonds and microscopic pixel grid. | Iridescent Purple & Gold (`#7B1FA2`) |
| [ ] | `icons/products/prod_camera_module.svg` | **Camera Module**<br>`camera_module` | 📷 | Complex Part | Multi-element smartphone camera assembly with optical image stabilization (OIS) coils and flex cable. | Optical Jet Black (`#212121`) |
| [ ] | `icons/products/prod_solar_panel.svg` | **Solar Panel**<br>`solar_panel` | 🌞 | Retail (Clean Energy) | Rigid aluminum-framed photovoltaic solar module angled on rooftop mounting brackets. | Deep Space Blue (`#0D47A1`) |
| [ ] | `icons/products/prod_camera.svg` | **Digital Camera**<br>`camera` | 📹 | Retail Product | Compact mirrorless digital camera body with knurled exposure dial, LCD preview, and prime lens. | Magnesium Black (`#263238`) |
| [ ] | `icons/products/prod_smartphone.svg` | **Smartphone**<br>`smartphone` | 📱 | Retail Product | Bezel-less flagship glass-slab smartphone with holographic edge screen and triple camera bump. | Sleek Sapphire (`#1A237E`) |
| [ ] | `icons/products/prod_robotic_arm.svg` | **Robotic Arm**<br>`robotic_arm` | 🤖 | Retail (Robotics) | 6-axis industrial articulated manufacturing robot arm holding an automated welding head. | Industrial Safety Yellow (`#FDD835`) |
| [ ] | `icons/products/prod_home_powerwall.svg` | **Home Powerwall**<br>`home_powerwall` | 🔋 | Retail (Clean Energy) | Wall-mounted residential smart battery storage cabinet with vertical pulsing LED pulse stripe. | Minimalist Matte White (`#ECEFF1`) |
| [ ] | `icons/products/prod_wind_turbine.svg` | **Wind Turbine Generator**<br>`wind_turbine_generator` | 💨 | Retail (Clean Energy) | Three-bladed commercial wind turbine nacelle with aerodynamic tapered composite blades. | Clean Aero Cyan (`#80DEEA`) |
| [ ] | `icons/tiers/tier_1_garage.svg` | **Tier 1: Garage Workshop** | 🏚️ | Factory Tier | Modest brick garage workshop with roller shutter, overhead bulb, and wooden workbench. | Rustic Brick Tan (`#8D6E63`) |
| [ ] | `icons/tiers/tier_2_assembly.svg` | **Tier 2: Light Assembly** | 🏭 | Factory Tier | Steel pre-fab commercial light manufacturing building with exhaust vents and delivery bay. | Industrial Steel Blue (`#546E7A`) |
| [ ] | `icons/tiers/tier_3_precision.svg` | **Tier 3: Precision Tech Plant** | 🔬 | Factory Tier | Futuristic corporate high-tech plant with glass atrium, cleanroom airlocks, and solar roof. | Cleanroom Aqua (`#00838F`) |
| [ ] | `icons/tiers/tier_4_megafactory.svg` | **Tier 4: Megafactory** | 🚀 | Factory Tier | Massive sprawling gigafactory complex with automated monorails, drone docks, and glowing logo. | Hyper-Industrial Purple (`#311B92`) |

---

## 🔬 Batch 6: R&D Tech Tree, Lab Systems & Corporate Clients (Priority: ★★★☆☆)

> **Goal**: Visual identity for the R&D Research screen, research points, and the 3 B2B Corporate Clients who award contracts.

| Done | File Target | Item Name (`id`) | Current | Category | Visual Concept & Art Description | Dominant Color |
| :---: | :--- | :--- | :---: | :---: | :--- | :--- |
| [ ] | `icons/research/tech_material_science.svg` | **Material Science Tech**<br>`material_science` | 🧬 | Tech Branch | Double-helix DNA strand fusing with crystal lattice nodes and replicating atoms. | Bio-Synthetic Green (`#00E676`) |
| [ ] | `icons/research/tech_factory_overclock.svg` | **Factory Overclocking Tech**<br>`factory_overclocking` | ⚡ | Tech Branch | Mechanical cog surrounded by intense electrical plasma arcs and tachometer rev needle. | Overclock Neon Orange (`#FF3D00`) |
| [ ] | `icons/research/tech_logistics_opt.svg` | **Logistics Optimization Tech**<br>`logistics_optimization` | 🚀 | Tech Branch | Supersonic cargo container rocket blasting through a quantum hyperlane transport ring. | Hyperlane Cyan (`#00E5FF`) |
| [ ] | `icons/research/res_points_rp.svg` | **Research Points (RP)** | 🧪 | Game Currency | Glowing spherical energy orb suspended inside a magnetic containment beaker with orbiting electrons. | Plasma Cyan Glow (`#18FFFF`) |
| [ ] | `icons/research/lab_deconstruction.svg` | **Deconstruction Bay** | 🔬 | Lab Facility | Laser disassembly chamber breaking down a circuit board into glowing constituent atoms. | Laser Ruby Red (`#FF1744`) |
| [ ] | `icons/research/lab_overclock_toggle.svg` | **Overclock Gauge / Switch** | 🔥 | Telemetry | Dual-needle boost pressure gauge entering redline zone with flame particle effects. | Thermal Crimson (`#D50000`) |
| [ ] | `icons/research/lab_thermal_wear.svg` | **Machine Wear / Health** | 🌡️ | Telemetry | Heartbeat/vital waveform integrated into a gear silhouette indicating machinery health. | Diagnostics Amber (`#FFC400`) |
| [ ] | `icons/clients/client_apex_telecom.svg` | **Apex Telecom**<br>`apex_telecom` | 📡 | Corporate Client | Satellite communications dish emitting orbital signal waves over a stylized global wireframe. | Cyber Cyan (`#00E5FF`) |
| [ ] | `icons/clients/client_solaria_energy.svg` | **Solaria Energy**<br>`solaria_energy` | ☀️ | Corporate Client | Geometric radiant solar corona crest with photovoltaic sunbeam vectors. | Solar Gold (`#FFB300`) |
| [ ] | `icons/clients/client_nova_robotics.svg` | **Nova Robotics**<br>`nova_robotics` | 🤖 | Corporate Client | Stylized geometric android head silhouette with glowing hexagonal optics visor. | Android Violet (`#B388FF`) |

---

## 💎 Batch 7: Prestige IPO & Quantum Prototypes (Priority: ★★☆☆☆)

> **Goal**: Late-game prestige assets for taking Production.INC public on Wall Street, earning Golden Shares, and crafting high-margin Prototype Blueprints.

| Done | File Target | Item Name (`id`) | Current | Category | Visual Concept & Art Description | Dominant Color |
| :---: | :--- | :--- | :---: | :---: | :--- | :--- |
| [ ] | `icons/prestige/curr_golden_share.svg` | **Golden Share** | 📜 | Prestige Currency | Holographic gold stock certificate embossed with an illuminated factory emblem and diamond watermark. | Brilliant Gold (`#FFD700`) |
| [ ] | `icons/prestige/ipo_wall_st_bell.svg` | **IPO Wall Street Bell** | 🔔 | Prestige Milestone | Polished brass exchange opening bell on an oak mount surrounded by ticker tape confetti. | Polished Brass (`#FFA000`) |
| [ ] | `icons/products/prod_quantum_processor.svg` | **Quantum Processor**<br>`quantum_processor` | 💠 | Prototype Intermediate | Gold dilution refrigerator cold-finger chip packaging quantum qubit waveguides with blue zero-point glow. | Cryogenic Cyan (`#00E5FF`) |
| [ ] | `icons/products/prod_quantum_core.svg` | **Quantum Core**<br>`quantum_core` | ⚛️ | Prototype Complex | Toroidal magnetic confinement reactor vessel trapping a swirling zero-point fusion singularity. | Singularity Violet (`#D500F9`) |
| [ ] | `icons/products/prod_orbital_satellite.svg` | **Orbital Satellite**<br>`orbital_satellite` | 🛰️ | Prototype Retail | Golden foil-wrapped cube-sat payload deploying dual solar wings and quantum communication dish in orbit. | Orbital Gold & Void (`#FFEA00`) |
| [ ] | `icons/prestige/perk_instant_machines.svg` | **Instant Machine Licensing** | ⚙️ | Prestige Perk | Golden gear fitted with a lightning bolt key bypassing a padlock. | Gilded Amber (`#FFC107`) |
| [ ] | `icons/prestige/perk_angel_capital.svg` | **Angel Seed Capital** | 💼 | Prestige Perk | Gilded leather investor briefcase overflowing with stacks of cash and gold bullion. | Venture Emerald (`#00E676`) |
| [ ] | `icons/prestige/perk_quantum_warp.svg` | **Quantum Warp Logistics** | 🌌 | Prestige Perk | Spiral galactic hyperspace wormhole gateway bending transit light vectors. | Cosmic Indigo (`#3D5AFE`) |

---

## 🧭 Batch 8: UI HUD, Navigation & Action Badges (Priority: ★★☆☆☆)

> **Goal**: Custom branded navigation and telemetry badges that replace default Flutter Material icons for a truly premium, bespoke app feel.

| Done | File Target | Badge Name | Current | Category | Visual Concept & Art Description | Dominant Color |
| :---: | :--- | :--- | :---: | :---: | :--- | :--- |
| [ ] | `icons/ui/nav_buy.svg` | **Buy Materials Tab** | 🛒 | Bottom Nav | Sleek industrial procurement crate with an inward-pointing download arrow. | Emerald Green (`#4CAF50`) |
| [ ] | `icons/ui/nav_build.svg` | **Build Products Tab** | 🔨 | Bottom Nav | Crossed pneumatic riveting gun and precision calipers. | Electric Blue (`#2196F3`) |
| [ ] | `icons/ui/nav_sell.svg` | **Sell Commercial Tab** | 💰 | Bottom Nav | Outgoing shipping crate embossed with an upward profit trend arrow. | Regal Purple (`#AB47BC`) |
| [ ] | `icons/ui/nav_shipping.svg` | **Shipping Logistics Tab** | 🚚 | Bottom Nav | Aerodynamic courier delivery carrier vehicle in swift forward motion. | Fleet Orange (`#FF9800`) |
| [ ] | `icons/ui/nav_control.svg` | **Control Center Tab** | 🎛️ | Bottom Nav | Industrial master control console with slider dials and digital telemetry gauges. | Control Cyan (`#00BCD4`) |
| [ ] | `icons/ui/hud_cash.svg` | **Cash Currency Emblem** | 💵 | HUD Currency | Glossy embossed dollar emblem coin with high-tech minting bevels. | Money Green (`#43A047`) |
| [ ] | `icons/ui/hud_reputation.svg` | **Corporate Rep Star** | ⭐ | HUD Metric | Five-pointed faceted military/corporate star medal with laurel leaf wreath. | Prestige Amber (`#FFB300`) |
| [ ] | `icons/ui/hud_manifest_cart.svg` | **Bulk Manifest Staging Tray** | 📦 | HUD Staging | Staged cargo pallet crate with a dynamic inventory item count badge. | Manifest Cobalt (`#2979FF`) |
| [ ] | `icons/ui/hud_transit_timer.svg` | **Transit Speed Timer** | ⏱️ | Telemetry | Stopwatch dial surrounded by motion speed streaks indicating active carrier transit. | Speed Yellow (`#FFD600`) |
| [ ] | `icons/ui/hud_tier_lock.svg` | **Tier Requirement Lock** | 🔒 | UI State | High-tech electronic biometric padlock with red/green access status LED. | Secure Slate & Red (`#EF5350`) |

---

## 💻 Flutter Code Implementation Architecture

Once you begin creating icon assets, here is how the codebase cleanly and safely consumes them with zero regressions:

### 1. `pubspec.yaml` Asset Registration & `flutter_svg`
Ensure your assets directory and `flutter_svg` dependency are declared:
```yaml
dependencies:
  flutter:
    sdk: flutter
  flutter_svg: ^2.3.0

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
The centralized widget [`lib/widgets/game_icon.dart`](file:///Users/Kamish/Desktop/JEBZ%20DEVVV/Main%20Projects/Game1/lib/widgets/game_icon.dart) automatically resolves custom SVG assets when available, and gracefully falls back to the existing Unicode emoji if an icon is missing or not yet drawn:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class GameIcon extends StatelessWidget {
  final String? assetPath;
  final String? itemId;
  final String fallbackEmoji;
  final double size;
  final BoxFit fit;

  const GameIcon({
    super.key,
    this.assetPath,
    this.itemId,
    required this.fallbackEmoji,
    this.size = 24.0,
    this.fit = BoxFit.contain,
  });

  @override
  Widget build(BuildContext context) {
    final resolvedPath = assetPath ?? (itemId != null ? resolveAssetPath(itemId!) : null);

    if (resolvedPath != null && resolvedPath.isNotEmpty) {
      if (resolvedPath.endsWith('.svg')) {
        return SvgPicture.asset(
          resolvedPath,
          width: size,
          height: size,
          fit: fit,
          placeholderBuilder: (context) => _buildFallbackEmoji(),
          errorBuilder: (context, error, stackTrace) => _buildFallbackEmoji(),
        );
      }

      return Image.asset(
        resolvedPath,
        width: size,
        height: size,
        fit: fit,
        errorBuilder: (context, error, stackTrace) => _buildFallbackEmoji(),
      );
    }

    return _buildFallbackEmoji();
  }

  Widget _buildFallbackEmoji() {
    return Text(
      fallbackEmoji,
      style: TextStyle(fontSize: size * 0.85, height: 1.0),
      textAlign: TextAlign.center,
    );
  }
}
```

This guarantees:
1. **Zero Broken Builds**: You can draw and drop in 1 icon, 10 icons, or an entire batch at your own pace.
2. **Instant Visual Testing**: The moment you save `assets/images/icons/...` and trigger hot reload, your drawn icon appears immediately in-game without touching complex screen logic!

---

## 🎯 Recommended Next Step
Batch 1 is **100% complete, vectorized, and integrated**! Next focus is **Batch 2: Factory Machinery & Logistics Fleet (11 icons)**:
1. `mach_auto_buy.svg` (Auto-Buy Machine / Procurement Drone)
2. `mach_build_basic.svg` (Basic Assembler)
3. `mach_build_intermediate.svg` (Intermediate Assembler)
4. `mach_build_complex.svg` (Complex Assembler)
5. `mach_auto_sell.svg` (Auto-Sell Dispatcher)
6. `tool_maintenance.svg` (Maintenance Checkup)
7. `tool_salvage.svg` (Machine Salvage)
8. `fleet_courier_bike.svg` (Courier Bike - Tier 1)
9. `fleet_delivery_van.svg` (Delivery Van - Tier 2)
10. `fleet_freight_truck.svg` (Freight Truck - Tier 3)
11. `fleet_cargo_plane.svg` (Cargo Plane - Tier 4)

Completing Batch 2 will transform the Control Screen (Machines tab) and Logistics Fleet screen with bespoke custom machinery and vehicle artwork!
