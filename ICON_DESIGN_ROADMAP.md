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
| **Batch 2** | **Factory Machinery & Logistics Fleet** | **11** | Core Automation & Shipping | ✅ Complete | `11 / 11` |
| **Batch 3** | **Tier 2 Intermediates & Early Retail** | **10** | Tier 2: Light Assembly Facility | ✅ Complete | `10 / 10` |
| **Batch 4** | **Advanced Consumer Electronics & Optics** | **10** | Tier 3: High-Tech Retail & Optics | ✅ Complete | `10 / 10` |
| **Batch 5** | **Heavy Mobility, Robotics & Infrastructure** | **10** | Tier 4: Heavy Industry & Megastructures | ✅ Complete | `10 / 10` |
| **Batch 6** | **Advanced & Quantum Infrastructure** | **9** | Advanced Infrastructure & Megastructures | ✅ Complete | `9 / 9` |
| **Batch 7** | **Upgrades & Tech Tree Modules** | **10** | Phase 4 & 5: Tech Tree & Prestige | ✅ Complete | `10 / 10` |
| **Batch 8** | **Game UI, Controls & Achievement Badges** | **10** | System Polish & Achievements | ✅ Complete | `10 / 10` |
| **TOTAL** | **Complete Game Asset Suite** | **80** | **All Game Phases** | 🏆 **Complete** | **`80 / 80` (100.0%)** |

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
| [x] | `icons/machines/mach_auto_buy.svg` | **Auto-Buy Machine**<br>`buyer` | 🤖 | Automation Machine | Automated warehouse robotic procurement drone holding a barcode scanner and cargo pallet. | Supply Amber & Teal (`#FFB300`) |
| [x] | `icons/machines/mach_build_basic.svg` | **Basic Assembler**<br>`basic_assembler` | 🏭 | Automation Machine | Compact industrial assembly bench with hydraulic press arm and green cycle status LED. | Factory Blue (`#2196F3`) |
| [x] | `icons/machines/mach_build_intermediate.svg` | **Intermediate Assembler** | 🏭 | Automation Machine | Twin robotic arm workcell soldering precision circuit boards under an overhead clean light. | Precision Violet (`#7C4DFF`) |
| [x] | `icons/machines/mach_build_complex.svg` | **Complex Assembler** | 🔬 | Automation Machine | High-grade cleanroom chamber with vacuum suction manipulator and laser alignment beam. | Cleanroom Cyan (`#00E5FF`) |
| [x] | `icons/machines/mach_build_retail.svg` | **Retail Assembler**<br>`retail_assembler` | 🛍️ | Automation Machine | Automated retail storefront gantry with packaging arms, conveyor, and laser barcode scanner. | Retail Emerald & Cyan (`#00E676`) |
| [x] | `icons/machines/mach_auto_sell.svg` | **Auto-Sell Dispatcher**<br>`basic_seller` | 🛒 | Automation Machine | Automated storefront fulfillment conveyor with checkout barcode laser and currency badge. | Commercial Emerald (`#00E676`) |
| [x] | `icons/machines/tool_maintenance.svg` | **Maintenance Checkup** | 🔧 | Tool / Diagnostics | High-tech adjustable torque wrench crossed with electronic oscilloscope diagnostic probe. | Warning Amber (`#FFA000`) |
| [x] | `icons/machines/tool_salvage.svg` | **Machine Salvage** | ♻️ | Tool / Decommission | Circular recycling arrows enclosing a disassembled gear and reclaim cash coin. | Eco Green & Silver (`#66BB6A`) |
| [x] | `icons/fleet/fleet_courier_bike.svg` | **Courier Bike (Tier 1)** | 🚲 | Logistics Fleet | Modern fixed-gear cargo bicycle with oversized insulated front rack and courier parcel bag. | Vibrant Orange (`#FF6E40`) |
| [x] | `icons/fleet/fleet_delivery_van.svg` | **Delivery Van (Tier 2)** | 🚐 | Logistics Fleet | Sleek electric commercial delivery van with side sliding door and corporate livery stripe. | Fleet Cobalt (`#1E88E5`) |
| [x] | `icons/fleet/fleet_freight_truck.svg` | **Freight Truck (Tier 3)** | 🚚 | Logistics Fleet | Heavy-duty 18-wheeler semi-truck cab with aerodynamic wind fairings and cargo container. | Heavy Industrial Crimson (`#E53935`) |
| [x] | `icons/fleet/fleet_cargo_plane.svg` | **Cargo Plane (Tier 4)** | ✈️ | Logistics Fleet | Twin-engine commercial airfreight cargo jet with nose cargo loading ramp open. | Aero Sky & Gold (`#00B0FF`) |

---

## 📺 Batch 3: Tier 2 Intermediates & Early Retail (Priority: ★★★★☆)

> **Goal**: Support the mid-game transition when the player unlocks the Light Assembly Facility and starts shipping high-margin consumer products like Speakers and Power Banks.

| Done | File Target | Item Name (`id`) | Current | Category | Visual Concept & Art Description | Dominant Color |
| :---: | :--- | :--- | :---: | :---: | :--- | :--- |
| [x] | `icons/products/prod_sound_driver.svg` | **Sound Driver**<br>`sound_driver` | 🔊 | Basic Part | Speaker cone transducer with concentric rubber surround, copper voice coil, and rear magnet. | Magnet Chrome & Copper (`#FF7043`) |
| [x] | `icons/products/prod_lens.svg` | **Lens**<br>`lens` | 🔍 | Basic Part | High-precision polished optical glass lens element in a threaded black aperture collar. | Optical Refraction Cyan (`#4DD0E1`) |
| [x] | `icons/products/prod_battery.svg` | **Battery**<br>`battery` | 🔋 | Basic Part | Rechargeable lithium-ion cylindrical cell with terminal caps and holographic safety badge. | Energy Green (`#76FF03`) |
| [x] | `icons/products/prod_gears.svg` | **Gears**<br>`gears` | ⚙️ | Basic Part | Pair of interlocking precision brass and steel spur gears with beveled teeth. | Brass Gold & Steel (`#FFD54F`) |
| [x] | `icons/products/prod_solar_cells.svg` | **Solar Cells**<br>`solar_cells` | ☀️ | Basic Part | Photovoltaic textured blue silicon wafer tile with silver grid busbars. | Solar Cobalt (`#1565C0`) |
| [x] | `icons/products/prod_display_screen.svg` | **Display Screen**<br>`display_screen` | 📺 | Intermediate Part | Ultra-thin bezel mobile OLED display panel showing glowing blue diagnostic test bars. | OLED Vibrant Cyan (`#00E5FF`) |
| [x] | `icons/products/prod_processor.svg` | **Processor**<br>`processor` | 🖥️ | Intermediate Part | Ceramic microprocessor chip package with nickel heat spreader, gold contact pins, and etched die logo. | Golden Silicon (`#FFC107`) |
| [x] | `icons/products/prod_gear_mechanism.svg` | **Gear Mechanism**<br>`gear_mechanism` | 🕰️ | Intermediate Part | Complex mechanical clockwork assembly with escapement wheel, coiled tension spring, and pinions. | Horology Bronze (`#D7CCC8`) |
| [x] | `icons/products/prod_speaker.svg` | **Speaker**<br>`speaker` | 🔈 | Retail Product | Compact portable Bluetooth bookshelf speaker with acoustic fabric grille and volume dial. | Audio Charcoal & Blue (`#37474F`) |
| [x] | `icons/products/prod_power_bank.svg` | **Power Bank**<br>`power_bank` | 🔌 | Retail Product | Slim pocket power bank with dual USB-C ports and illuminated 4-dot battery LED fuel gauge. | Matte Midnight (`#263238`) |

---

## 📱 Batch 4: Advanced Consumer Electronics & Optics (Priority: ★★★★☆)

> **Goal**: High-tier consumer electronics, personal mobility, gaming, and precision optical instruments.

| Done | File Target | Item Name (`id`) | Current | Category | Visual Concept & Art Description | Dominant Color |
| :---: | :--- | :--- | :---: | :---: | :--- | :--- |
| [x] | `icons/products/prod_camera.svg` | **Digital Camera**<br>`camera` | 📹 | Retail Product | Compact mirrorless digital camera body with knurled exposure dial, LCD preview, and prime lens. | Magnesium Black (`#263238`) |
| [x] | `icons/products/prod_e_reader.svg` | **E-Reader**<br>`e_reader` | 📖 | Retail Product | Slim e-ink paper-display tablet with leatherette case and crisp typography preview. | Paper White & Slate (`#ECEFF1`) |
| [x] | `icons/products/prod_electric_scooter.svg` | **Electric Scooter**<br>`electric_scooter` | 🛴 | Retail Product | Aerodynamic urban commuter electric scooter with LED stem headlight and digital speedometer. | Cyber Yellow & Dark Grey (`#FFD54F`) |
| [x] | `icons/products/prod_gaming_console.svg` | **Gaming Console**<br>`gaming_console` | 🎮 | Retail Product | Next-gen ergonomic gaming console with glowing LED cooling intake and wireless controller. | Polar White & Neon Blue (`#2979FF`) |
| [x] | `icons/products/prod_laptop.svg` | **Laptop Computer**<br>`laptop` | 💻 | Retail Product | Ultra-thin aluminum unibody clamshell laptop with illuminated keyboard and bezel-less display. | Space Grey Aluminum (`#78909C`) |
| [x] | `icons/products/prod_smartphone.svg` | **Smartphone**<br>`smartphone` | 📱 | Retail Product | Bezel-less flagship glass-slab smartphone with holographic edge screen and triple camera bump. | Sleek Sapphire (`#1A237E`) |
| [x] | `icons/products/prod_smartwatch.svg` | **Smartwatch**<br>`smartwatch` | ⌚ | Retail Product | High-end biometric smartwatch with curved OLED face, silicone sport band, and pulse monitor. | Midnight Sport (`#212121`) |
| [x] | `icons/products/prod_solar_panel.svg` | **Solar Panel**<br>`solar_panel` | 🌞 | Retail (Clean Energy) | Rigid aluminum-framed photovoltaic solar module angled on rooftop mounting brackets. | Deep Space Blue (`#0D47A1`) |
| [x] | `icons/products/prod_telescope.svg` | **Optical Telescope**<br>`telescope` | 🔭 | Retail Product | Professional astronomical refractor telescope on equatorial tripod mount with brass focus knob. | Celestial Brass & Midnight (`#1A237E`) |
| [x] | `icons/products/prod_vr_headset.svg` | **VR Headset**<br>`vr_headset` | 🥽 | Retail Product | Ergonomic standalone spatial computing VR headset with perimeter tracking cameras and halo strap. | Matte Carbon & Cyan Glow (`#00E5FF`) |

---

## 🤖 Batch 5: Heavy Mobility, Robotics & Infrastructure (Priority: ★★★☆☆)

> **Goal**: Heavy industrial machines, autonomous robotics, clean grid infrastructure, and space exploration.

| Done | File Target | Item Name (`id`) | Current | Category | Visual Concept & Art Description | Dominant Color |
| :---: | :--- | :--- | :---: | :---: | :--- | :--- |
| [x] | `icons/products/prod_drone.svg` | **Autonomous Drone**<br>`drone` / `cleaning_drone` | 🛸 | Retail / Robotics | Aerodynamic 4-rotor carbon-fiber quadcopter with gimbal camera and glowing LED navigation beacons. | Aero Cyan & Carbon (`#00E5FF`) |
| [x] | `icons/products/prod_electric_car.svg` | **Electric Sports Sedan**<br>`electric_car` | 🚗 | Retail / Flagship | High-performance electric vehicle on a pedestal base with illuminated light-bar and glass roof. | Metallic Electric Blue (`#1E88E5`) |
| [x] | `icons/products/prod_fusion_reactor.svg` | **Fusion Reactor Core**<br>`fusion_reactor` / `quantum_core` | ⚛️ | Endgame / Energy | Toroidal magnetic confinement reactor vessel trapping a swirling zero-point fusion plasma singularity. | High-Energy Magenta & Cyan (`#E040FB`) |
| [x] | `icons/products/prod_high_speed_train.svg` | **High-Speed Maglev Train**<br>`high_speed_train` | 🚄 | Heavy Mobility | Aerodynamic high-speed bullet train locomotive with streamlined nose and wrap-around windshield. | Bullet Silver & Cobalt (`#1976D2`) |
| [x] | `icons/products/prod_industrial_robot.svg` | **Industrial Robot Arm**<br>`industrial_robot` / `robotic_arm` | 🤖 | Heavy Automation | 6-axis heavy industrial articulated manufacturing robot arm holding an active automated welding head. | Industrial Safety Yellow (`#FDD835`) |
| [x] | `icons/products/prod_mining_drill.svg` | **Heavy Mining Drill**<br>`mining_drill` | ⛏️ | Heavy Industry | Diamond-tipped tungsten carbide rotary boring excavator head with hydraulic stabilizer pistons. | Heavy Carbide Grey & Amber (`#FF8F00`) |
| [x] | `icons/products/prod_robot_dog.svg` | **Quadruped Robot Dog**<br>`robot_dog` / `toy_robot` | 🐕 | Robotics / Retail | Agile four-legged mechatronic robotic quadruped with lidar sensor dome and carbon articulated limbs. | Tech Slate & Industrial Gold (`#FFC107`) |
| [x] | `icons/products/prod_space_satellite.svg` | **Orbital Space Satellite**<br>`space_satellite` / `orbital_satellite` | 🛰️ | Aerospace / Flagship | Cube-sat communication satellite with dual deployed photovoltaic solar wings and antenna dish. | Aerospace Gold & Solar Blue (`#0288D1`) |
| [x] | `icons/products/prod_supercomputer.svg` | **Supercomputer Server Rack**<br>`supercomputer` | 🖥️ | High Performance | High-density liquid-cooled enterprise compute server rack with pulsing optical interconnect matrix LEDs. | Deep Obsidian & Quantum Cyan (`#00E5FF`) |
| [x] | `icons/products/prod_wind_turbine.svg` | **Wind Turbine Generator**<br>`wind_turbine` / `wind_turbine_generator` | 💨 | Clean Energy | Three-bladed commercial clean wind turbine nacelle with tapered composite aerofoil blades on a tall mast. | Clean Aero Sky White (`#ECEFF1`) |

---

## 🔬 Batch 6: Advanced & Quantum Infrastructure (Priority: ★★★☆☆)

> **Goal**: High-fidelity 3D diorama icons for late-game mega-structures, quantum computing hardware, deep-space telemetry, and B2B corporate contracts.

| Done | File Target | Item Name (`id`) | Current | Category | Visual Concept & Art Description | Dominant Color |
| :---: | :--- | :--- | :---: | :--- | :--- | :--- |
| [x] | `icons/products/prod_ai_core.svg` | **AI Neural Core**<br>`ai_core` / `nova_robotics` | 🤖 | Endgame / Computing | Self-contained AI neural compute orb with concentric rotating magnetic rings and pulsing azure photon pathways on a diorama tech plinth. | Neural Cyan & Cobalt (`#00E5FF`) |
| [x] | `icons/products/prod_dyson_receiver.svg` | **Dyson Swarm Receiver**<br>`dyson_receiver` / `solaria_energy` | ☀️ | Endgame / Megastructure | Parabolic solar collector dish array harvesting focused microwave energy beams from orbit on an insulated hexagonal base. | Solar Gold & Amber (`#FFB300`) |
| [x] | `icons/products/prod_orbital_station.svg` | **Orbital Space Station**<br>`orbital_station` / `orbital_satellite` | 🛰️ | Aerospace / Flagship | Toroidal rotating ring modular space habitat with docking berths, communications mast, and solar radiator arrays. | Aerospace White & Void (`#ECEFF1`) |
| [x] | `icons/products/prod_particle_accelerator.svg` | **Particle Accelerator Ring**<br>`particle_accelerator` / `material_science` | 🔬 | Research / Physics | Circular magnetic beamline collider tunnel with cryogenic cooling manifolds and collision detection chamber on a laboratory platform. | Cryo Azure & Steel (`#2979FF`) |
| [x] | `icons/products/prod_quantum_computer.svg` | **Quantum Computer Chandelier**<br>`quantum_computer` | 💠 | Endgame / Hardware | Golden cryostat dilution refrigerator chandelier housing superconducting qubits, microwave coaxial coils, and shielded thermal stages. | Polished Brass & Gold (`#FFD700`) |
| [x] | `icons/products/prod_quantum_processor.svg` | **Quantum Qubit Processor**<br>`quantum_processor` | 💾 | High-Tech Component | Cryogenic quantum chip socket with microscopic gold qubit waveguides, laser alignment channels, and quantum bus interconnects. | Quantum Violet & Gold (`#7C4DFF`) |
| [x] | `icons/products/prod_space_probe.svg` | **Deep Space Exploration Probe**<br>`space_probe` / `logistics_optimization` | 🚀 | Aerospace / Telemetry | Autonomous interplanetary space probe equipped with RTG power unit, high-gain dish, and ion propulsion drive nozzle. | Deep Space Gold & White (`#FFD54F`) |
| [x] | `icons/products/prod_space_telescope.svg` | **Space Observatory Telescope**<br>`space_telescope` | 🔭 | Science / Optics | Orbital space telescope with gold-coated beryllium primary mirror segments, deployable sunshield, and star tracker assembly. | Hex Gold & Dark Obsidian (`#FFA000`) |
| [x] | `icons/products/prod_telecom_tower.svg` | **5G Telecom Relay Tower**<br>`telecom_tower` / `apex_telecom` | 📡 | Infrastructure / Comms | Lattice steel telecommunications transmission tower fitted with cellular array panels, microwave drum antennas, and warning beacons. | Telecom Cyan & Signal Red (`#00BCD4`) |

---

## 💎 Batch 7: Upgrades & Tech Tree Modules (Priority: ★★☆☆☆)

> **Goal**: High-tech upgrade modules, research nodes, and prestige perks for R&D lab advancements, factory overclocking, and venture perks.

| Done | File Target | Item Name (`id`) | Current | Category | Visual Concept & Art Description | Dominant Color |
| :---: | :--- | :--- | :---: | :---: | :--- | :--- |
| [x] | `icons/research/upg_automation_chip.svg` | **Automation Chip**<br>`automation_chip`, `instant_machines` | ⚙️ | Tech / Perk | Cybernetic processor wafer glowing with micro-circuits and neon logic pathways on a polished rounded pedestal. | Cybernetic Cyan (`#00E5FF`) |
| [x] | `icons/research/upg_eco_efficiency.svg` | **Eco Efficiency**<br>`eco_efficiency` | 🍃 | Tech Upgrade | Biomechanical leaf turbine synthesis node infused with green solar energy ribbons. | Emerald Green (`#00E676`) |
| [x] | `icons/research/upg_logistics_optimizer.svg` | **Logistics Optimizer**<br>`logistics_optimizer`, `quantum_warp_dispatch` | 🚀 | Tech / Perk | Holographic routing navigational orb computing real-time quantum hyperspace vector coordinates. | Quantum Cobalt (`#2979FF`) |
| [x] | `icons/research/upg_market_algorithm.svg` | **Market Algorithm**<br>`market_algorithm`, `angel_seed_capital` | 📈 | Tech / Perk | Dynamic financial holographic matrix displaying surging candlestick projections and gold tokens. | Venture Gold (`#FFD700`) |
| [x] | `icons/research/upg_nanotech_infusion.svg` | **Nanotech Infusion**<br>`nanotech_infusion`, `prototype_blueprints` | 🔬 | Tech / Perk | Glowing nanite swarm chamber constructing crystalline molecular lattices in zero gravity. | Singularity Violet (`#D500F9`) |
| [x] | `icons/research/upg_neural_accelerator.svg` | **Neural Accelerator**<br>`neural_accelerator` | 🧠 | Tech Upgrade | Synthetic crystalline neocortex node with synapse pulse arcs and optoelectronic conduits. | Synapse Magenta (`#FF4081`) |
| [x] | `icons/research/upg_overclock_boost.svg` | **Overclock Boost**<br>`overclock_boost`, `factory_overclocking` | ⚡ | Tech Upgrade | Heavy-duty plasma actuator manifold firing twin blue lightning surges through cooling fins. | Electric Amber (`#FFAB00`) |
| [x] | `icons/research/upg_power_grid_overload.svg` | **Power Grid Overload**<br>`power_grid_overload` | 🔋 | Tech Upgrade | High-voltage substation capacitor array radiating plasma discharge arcs on an insulated base. | Arc Violet (`#7C4DFF`) |
| [x] | `icons/research/upg_quality_control.svg` | **Quality Control**<br>`quality_control` | 🔍 | Tech Upgrade | Precision optical diagnostic scanner projecting green holographic calibration reticles over parts. | Laser Teal (`#00BFA5`) |
| [x] | `icons/research/upg_thermal_cooling.svg` | **Thermal Cooling**<br>`thermal_cooling` | ❄️ | Tech Upgrade | Cryogenic vapor dispersion heat sink venting sub-zero frost vapors with glowing coolant coils. | Cryo Cyan (`#18FFFF`) |

---

## 🧭 Batch 8: Game UI, Controls & Achievement Badges (Priority: ★★☆☆☆)

> **Goal**: Custom branded UI system controls, audio toggles, cloud saves, settings console, analytics telemetry, and trophy achievement badges.

| Done | File Target | Item / Badge Name (`id`) | Current | Category | Visual Concept & Art Description | Dominant Color |
| :---: | :--- | :--- | :---: | :---: | :--- | :--- |
| [x] | `icons/ui/badge_interplanetary_reach.svg` | **Interplanetary Reach Badge**<br>`badge_interplanetary_reach` | ⭐ | Achievement | Faceted gold star framed by glowing neon orbital warp rings encircling Earth on a pedestal. | Stellar Gold & Cyan (`#00E5FF`) |
| [x] | `icons/ui/badge_master_automation.svg` | **Master of Automation Crown**<br>`badge_master_automation` | 👑 | Achievement | Royal cybernetic gear crown studded with sapphires, rubies, and glowing circuit traces on an isometric plinth. | Regal Gold (`#FFD700`) |
| [x] | `icons/ui/badge_tycoon_trophy.svg` | **Industrial Tycoon Trophy**<br>`badge_tycoon_trophy` | 🏆 | Achievement | First-place winged golden cup mounted on a black marble pedestal with engraved brass placard. | Championship Gold (`#FFA000`) |
| [x] | `icons/ui/badge_zero_carbon.svg` | **Zero-Carbon Ecology Medal**<br>`badge_zero_carbon` | 🎖️ | Achievement | Polished gold laurel medal featuring wind turbines across the globe on a striped green ribbon. | Ecology Emerald (`#00E676`) |
| [x] | `icons/ui/ui_audio_off.svg` | **Mute / Audio Off**<br>`ui_audio_off` | 🔇 | UI Control | Heavy-duty acoustic driver silenced by a glossy red 3D diagonal strike-through bar on a plinth. | Crimson & Slate (`#FF1744`) |
| [x] | `icons/ui/ui_audio_on.svg` | **Audio / Sound On**<br>`ui_audio_on` | 🔊 | UI Control | Golden-rimmed subwoofer radiating pulsating translucent cyan acoustic soundwaves and music notes. | Soundwave Cyan (`#00E5FF`) |
| [x] | `icons/ui/ui_quest_target.svg` | **Quest & Production Target**<br>`ui_quest_target` | 🎯 | UI Telemetry | Bullseye archery target board on an industrial truss stand with a gold arrow struck dead-center. | Bullseye Crimson (`#D50000`) |
| [x] | `icons/ui/ui_save_cloud.svg` | **Cloud Save & Sync**<br>`ui_save_cloud` | 💾 | UI System | Volumetric white cloud downloading glowing green telemetry data into an open platter SSD hard drive. | Cloud Mint (`#00E676`) |
| [x] | `icons/ui/ui_settings.svg` | **Master Settings Console**<br>`ui_settings` | ⚙️ | UI System | Precision steel and brass interlocking gears mounted on an aluminum telemetry deck with dual slider dials. | Machined Steel (`#78909C`) |
| [x] | `icons/ui/ui_stats_analytics.svg` | **Factory Analytics Dashboard**<br>`ui_stats_analytics` | 📊 | UI Telemetry | High-tech tablet computing platform displaying ascending 3D bar graphs linked by a glowing growth spline. | Analytics Emerald (`#00E676`) |

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

## 🏆 Master Icon Suite: 100% Complete!
🎉 **All 8 Batches are 100% vectorized, tested, and integrated (80 / 80 icons, 100.0%)!**

Every single custom asset category across Production.INC is now completely powered by bespoke 3D vector-packaged SVGs:
1. **Batch 1**: Raw Materials & Starter Parts (`10 / 10`)
2. **Batch 2**: Factory Machinery & Logistics Fleet (`11 / 11`)
3. **Batch 3**: Tier 2 Intermediates & Early Retail (`10 / 10`)
4. **Batch 4**: Advanced Consumer Electronics & Optics (`10 / 10`)
5. **Batch 5**: Heavy Mobility, Robotics & Infrastructure (`10 / 10`)
6. **Batch 6**: Advanced & Quantum Infrastructure (`9 / 9`)
7. **Batch 7**: Upgrades & Tech Tree Modules (`10 / 10`)
8. **Batch 8**: Game UI, Controls & Achievement Badges (`10 / 10`)

**Next Milestone**: Proceed to **Phase C: Google Play Console Release Prep** (signing keys, production bundle build, and store submission)!

