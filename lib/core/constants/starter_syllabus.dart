import '../../data/models/syllabus_model.dart';

/// Predefined Starter ECE Syllabus with 14 foundational subjects.
/// Clearly marked as a starter syllabus, fully customizable by the user.
final List<SyllabusSubject> starterEceSyllabus = [
  SyllabusSubject(
    id: 'subj_math',
    name: 'Engineering Mathematics',
    order: 0,
    topics: [
      SyllabusTopic(
        id: 'topic_math_linear_algebra',
        name: 'Linear Algebra',
        subjectId: 'subj_math',
        subtopics: [
          SyllabusSubtopic(id: 'sub_la_matrices', name: 'Matrices & Determinants', topicId: 'topic_math_linear_algebra'),
          SyllabusSubtopic(id: 'sub_la_eigen', name: 'Eigenvalues & Eigenvectors', topicId: 'topic_math_linear_algebra'),
          SyllabusSubtopic(id: 'sub_la_systems', name: 'Systems of Linear Equations', topicId: 'topic_math_linear_algebra'),
        ],
      ),
      SyllabusTopic(
        id: 'topic_math_calculus',
        name: 'Calculus',
        subjectId: 'subj_math',
        subtopics: [
          SyllabusSubtopic(id: 'sub_calc_mv', name: 'Mean Value Theorems & Partial Derivatives', topicId: 'topic_math_calculus'),
          SyllabusSubtopic(id: 'sub_calc_integrals', name: 'Multiple Integrals & Vector Calculus', topicId: 'topic_math_calculus'),
          SyllabusSubtopic(id: 'sub_calc_theorems', name: 'Stokes, Gauss, & Green Theorems', topicId: 'topic_math_calculus'),
        ],
      ),
      SyllabusTopic(
        id: 'topic_math_differential_eq',
        name: 'Differential Equations',
        subjectId: 'subj_math',
        subtopics: [
          SyllabusSubtopic(id: 'sub_de_first_order', name: 'First Order Linear Equations', topicId: 'topic_math_differential_eq'),
          SyllabusSubtopic(id: 'sub_de_higher_order', name: 'Higher Order Linear Equations', topicId: 'topic_math_differential_eq'),
        ],
      ),
      SyllabusTopic(
        id: 'topic_math_probability',
        name: 'Probability and Statistics',
        subjectId: 'subj_math',
        subtopics: [
          SyllabusSubtopic(id: 'sub_prob_rv', name: 'Random Variables & Probability Distributions', topicId: 'topic_math_probability'),
          SyllabusSubtopic(id: 'sub_prob_stats', name: 'Mean, Median, Mode & Standard Deviation', topicId: 'topic_math_probability'),
        ],
      ),
    ],
  ),
  SyllabusSubject(
    id: 'subj_network_theory',
    name: 'Network Theory',
    order: 1,
    topics: [
      SyllabusTopic(
        id: 'topic_nt_analysis',
        name: 'Network Analysis',
        subjectId: 'subj_network_theory',
        subtopics: [
          SyllabusSubtopic(id: 'sub_nt_kcl_kvl', name: 'KCL, KVL & Node/Mesh Analysis', topicId: 'topic_nt_analysis'),
          SyllabusSubtopic(id: 'sub_nt_theorems', name: 'Thevenin, Norton, Superposition & Max Power', topicId: 'topic_nt_analysis'),
        ],
      ),
      SyllabusTopic(
        id: 'topic_nt_transients',
        name: 'Transient Analysis',
        subjectId: 'subj_network_theory',
        subtopics: [
          SyllabusSubtopic(id: 'sub_nt_first_order', name: 'RC and RL First Order Circuits', topicId: 'topic_nt_transients'),
          SyllabusSubtopic(id: 'sub_nt_second_order', name: 'RLC Second Order Transient Response', topicId: 'topic_nt_transients'),
        ],
      ),
      SyllabusTopic(
        id: 'topic_nt_two_port',
        name: 'Two-Port Networks & Resonance',
        subjectId: 'subj_network_theory',
        subtopics: [
          SyllabusSubtopic(id: 'sub_nt_params', name: 'Z, Y, ABCD and h-parameters', topicId: 'topic_nt_two_port'),
          SyllabusSubtopic(id: 'sub_nt_resonance', name: 'Series and Parallel Resonance (Q-factor)', topicId: 'topic_nt_two_port'),
        ],
      ),
    ],
  ),
  SyllabusSubject(
    id: 'subj_signals_systems',
    name: 'Signals and Systems',
    order: 2,
    topics: [
      SyllabusTopic(
        id: 'topic_ss_classification',
        name: 'Continuous & Discrete Signals',
        subjectId: 'subj_signals_systems',
        subtopics: [
          SyllabusSubtopic(id: 'sub_ss_properties', name: 'Linearity, Causality, Time-Invariance & Stability', topicId: 'topic_ss_classification'),
          SyllabusSubtopic(id: 'sub_ss_convolution', name: 'Convolution Integral and Sum', topicId: 'topic_ss_classification'),
        ],
      ),
      SyllabusTopic(
        id: 'topic_ss_fourier',
        name: 'Fourier Analysis & Laplace Transform',
        subjectId: 'subj_signals_systems',
        subtopics: [
          SyllabusSubtopic(id: 'sub_ss_fourier_series', name: 'Continuous & Discrete Fourier Series/Transform', topicId: 'topic_ss_fourier'),
          SyllabusSubtopic(id: 'sub_ss_laplace', name: 'Laplace Transform & Region of Convergence (ROC)', topicId: 'topic_ss_fourier'),
        ],
      ),
      SyllabusTopic(
        id: 'topic_ss_z_transform',
        name: 'Z-Transform & Sampling',
        subjectId: 'subj_signals_systems',
        subtopics: [
          SyllabusSubtopic(id: 'sub_ss_z_transform', name: 'Z-Transform Properties and Inverse Z-Transform', topicId: 'topic_ss_z_transform'),
          SyllabusSubtopic(id: 'sub_ss_sampling', name: 'Nyquist Sampling Theorem & Aliasing', topicId: 'topic_ss_z_transform'),
        ],
      ),
    ],
  ),
  SyllabusSubject(
    id: 'subj_electronic_devices',
    name: 'Electronic Devices',
    order: 3,
    topics: [
      SyllabusTopic(
        id: 'topic_ed_semiconductors',
        name: 'Semiconductor Physics',
        subjectId: 'subj_electronic_devices',
        subtopics: [
          SyllabusSubtopic(id: 'sub_ed_carrier', name: 'Carrier Transport, Diffusion, Drift & Mobility', topicId: 'topic_ed_semiconductors'),
          SyllabusSubtopic(id: 'sub_ed_generation', name: 'Generation-Recombination & Continuity Equation', topicId: 'topic_ed_semiconductors'),
        ],
      ),
      SyllabusTopic(
        id: 'topic_ed_junctions',
        name: 'PN Junction & Diodes',
        subjectId: 'subj_electronic_devices',
        subtopics: [
          SyllabusSubtopic(id: 'sub_ed_pn_junction', name: 'Depletion Width, Built-in Potential & Capacitance', topicId: 'topic_ed_junctions'),
          SyllabusSubtopic(id: 'sub_ed_special_diodes', name: 'Zener, Tunnel & Schottky Diodes', topicId: 'topic_ed_junctions'),
        ],
      ),
      SyllabusTopic(
        id: 'topic_ed_transistors',
        name: 'BJT and MOSFET Physics',
        subjectId: 'subj_electronic_devices',
        subtopics: [
          SyllabusSubtopic(id: 'sub_ed_bjt_physics', name: 'BJT Current Components & Ebers-Moll Model', topicId: 'topic_ed_transistors'),
          SyllabusSubtopic(id: 'sub_ed_mosfet_physics', name: 'MOS Capacitor, Inversion & Threshold Voltage', topicId: 'topic_ed_transistors'),
        ],
      ),
    ],
  ),
  SyllabusSubject(
    id: 'subj_analog_electronics',
    name: 'Analog Electronics',
    order: 4,
    topics: [
      SyllabusTopic(
        id: 'topic_ae_diode_circuits',
        name: 'Diode Circuits & Biasing',
        subjectId: 'subj_analog_electronics',
        subtopics: [
          SyllabusSubtopic(id: 'sub_ae_clippers', name: 'Rectifiers, Clippers, Clampers & Voltage Multipliers', topicId: 'topic_ae_diode_circuits'),
          SyllabusSubtopic(id: 'sub_ae_bjt_bias', name: 'BJT & MOSFET Biasing and Thermal Stability', topicId: 'topic_ae_diode_circuits'),
        ],
      ),
      SyllabusTopic(
        id: 'topic_ae_amplifiers',
        name: 'Small Signal Amplifiers & Feedback',
        subjectId: 'subj_analog_electronics',
        subtopics: [
          SyllabusSubtopic(id: 'sub_ae_small_signal', name: 'CE, CB, CC and CS, CD Amplifiers', topicId: 'topic_ae_amplifiers'),
          SyllabusSubtopic(id: 'sub_ae_feedback', name: 'Negative Feedback Topologies and Stability', topicId: 'topic_ae_amplifiers'),
        ],
      ),
      SyllabusTopic(
        id: 'topic_ae_opamps',
        name: 'Operational Amplifiers & Oscillators',
        subjectId: 'subj_analog_electronics',
        subtopics: [
          SyllabusSubtopic(id: 'sub_ae_opamp_apps', name: 'Inverting, Non-inverting, Integrator & Differentiator', topicId: 'topic_ae_opamps'),
          SyllabusSubtopic(id: 'sub_ae_oscillators', name: 'Barkhausen Criterion, RC Phase Shift & LC Oscillators', topicId: 'topic_ae_opamps'),
        ],
      ),
    ],
  ),
  SyllabusSubject(
    id: 'subj_digital_electronics',
    name: 'Digital Electronics',
    order: 5,
    topics: [
      SyllabusTopic(
        id: 'topic_de_combinational',
        name: 'Boolean Algebra & Combinational Circuits',
        subjectId: 'subj_digital_electronics',
        subtopics: [
          SyllabusSubtopic(id: 'sub_de_kmap', name: 'K-Maps & Logic Gate Minimization', topicId: 'topic_de_combinational'),
          SyllabusSubtopic(id: 'sub_de_mux_demux', name: 'Multiplexers, Decoders, Encoders & Adders', topicId: 'topic_de_combinational'),
        ],
      ),
      SyllabusTopic(
        id: 'topic_de_sequential',
        name: 'Sequential Circuits & Finite State Machines',
        subjectId: 'subj_digital_electronics',
        subtopics: [
          SyllabusSubtopic(id: 'sub_de_latches_ff', name: 'SR, JK, D, and T Flip-Flops', topicId: 'topic_de_sequential'),
          SyllabusSubtopic(id: 'sub_de_counters', name: 'Synchronous, Asynchronous Counters & Shift Registers', topicId: 'topic_de_sequential'),
        ],
      ),
      SyllabusTopic(
        id: 'topic_de_data_converters',
        name: 'Data Converters & Semiconductor Memories',
        subjectId: 'subj_digital_electronics',
        subtopics: [
          SyllabusSubtopic(id: 'sub_de_adc_dac', name: 'ADC (Flash, SAR, Dual Slope) & DAC (R-2R ladder)', topicId: 'topic_de_data_converters'),
          SyllabusSubtopic(id: 'sub_de_memory', name: 'ROM, SRAM, DRAM & PLA/PAL', topicId: 'topic_de_data_converters'),
        ],
      ),
    ],
  ),
  SyllabusSubject(
    id: 'subj_comm_systems',
    name: 'Communication Systems',
    order: 6,
    topics: [
      SyllabusTopic(
        id: 'topic_cs_analog_comm',
        name: 'Analog Communications',
        subjectId: 'subj_comm_systems',
        subtopics: [
          SyllabusSubtopic(id: 'sub_cs_am', name: 'AM, DSB-SC, SSB, VSB Modulation & Demodulation', topicId: 'topic_cs_analog_comm'),
          SyllabusSubtopic(id: 'sub_cs_fm_pm', name: 'FM, PM, Narrowband & Wideband FM, Carson Rule', topicId: 'topic_cs_analog_comm'),
        ],
      ),
      SyllabusTopic(
        id: 'topic_cs_digital_comm',
        name: 'Digital Communications',
        subjectId: 'subj_comm_systems',
        subtopics: [
          SyllabusSubtopic(id: 'sub_cs_pcm_dpcm', name: 'PCM, DPCM, DM, ADM and Quantization Noise', topicId: 'topic_cs_digital_comm'),
          SyllabusSubtopic(id: 'sub_cs_ask_fsk_psk', name: 'BPSK, QPSK, QAM, Constellation Diagrams & BER', topicId: 'topic_cs_digital_comm'),
        ],
      ),
      SyllabusTopic(
        id: 'topic_cs_information_theory',
        name: 'Information Theory & Noise Analysis',
        subjectId: 'subj_comm_systems',
        subtopics: [
          SyllabusSubtopic(id: 'sub_cs_entropy', name: 'Entropy, Mutual Information & Shannon Channel Capacity', topicId: 'topic_cs_information_theory'),
          SyllabusSubtopic(id: 'sub_cs_snr', name: 'SNR & Figure of Merit in AM and FM Receivers', topicId: 'topic_cs_information_theory'),
        ],
      ),
    ],
  ),
  SyllabusSubject(
    id: 'subj_em_theory',
    name: 'Electromagnetic Theory',
    order: 7,
    topics: [
      SyllabusTopic(
        id: 'topic_em_maxwell',
        name: 'Maxwell Equations & Electrostatics',
        subjectId: 'subj_em_theory',
        subtopics: [
          SyllabusSubtopic(id: 'sub_em_gauss_ampere', name: 'Coulomb, Gauss, Biot-Savart & Ampere Laws', topicId: 'topic_em_maxwell'),
          SyllabusSubtopic(id: 'sub_em_maxwell_eq', name: 'Maxwell Equations in Differential & Integral Forms', topicId: 'topic_em_maxwell'),
        ],
      ),
      SyllabusTopic(
        id: 'topic_em_waves',
        name: 'Plane Waves & Transmission Lines',
        subjectId: 'subj_em_theory',
        subtopics: [
          SyllabusSubtopic(id: 'sub_em_poynting', name: 'Wave Propagation, Skin Depth & Poynting Vector', topicId: 'topic_em_waves'),
          SyllabusSubtopic(id: 'sub_em_tlines', name: 'Characteristic Impedance, VSWR, Reflection & Smith Chart', topicId: 'topic_em_waves'),
        ],
      ),
      SyllabusTopic(
        id: 'topic_em_waveguides_antennas',
        name: 'Waveguides & Antennas',
        subjectId: 'subj_em_theory',
        subtopics: [
          SyllabusSubtopic(id: 'sub_em_rectangular_wg', name: 'Rectangular Waveguides, Cutoff Frequencies & TE/TM Modes', topicId: 'topic_em_waveguides_antennas'),
          SyllabusSubtopic(id: 'sub_em_antenna_radiation', name: 'Dipole Radiation, Directivity, Gain & Antenna Arrays', topicId: 'topic_em_waveguides_antennas'),
        ],
      ),
    ],
  ),
  SyllabusSubject(
    id: 'subj_control_systems',
    name: 'Control Systems',
    order: 8,
    topics: [
      SyllabusTopic(
        id: 'topic_cs_transfer_fn',
        name: 'Time Response Analysis',
        subjectId: 'subj_control_systems',
        subtopics: [
          SyllabusSubtopic(id: 'sub_cs_block_diagrams', name: 'Block Diagrams & Signal Flow Graphs (Mason Gain)', topicId: 'topic_cs_transfer_fn'),
          SyllabusSubtopic(id: 'sub_cs_transient_specs', name: 'Damping Ratio, Natural Frequency, Rise Time & Settling Time', topicId: 'topic_cs_transfer_fn'),
        ],
      ),
      SyllabusTopic(
        id: 'topic_cs_stability',
        name: 'Stability & Frequency Response',
        subjectId: 'subj_control_systems',
        subtopics: [
          SyllabusSubtopic(id: 'sub_cs_routh_rl', name: 'Routh-Hurwitz Criterion & Root Locus Techniques', topicId: 'topic_cs_stability'),
          SyllabusSubtopic(id: 'sub_cs_bode_nyquist', name: 'Bode Plots, Nyquist Stability Criterion & Gain/Phase Margins', topicId: 'topic_cs_stability'),
        ],
      ),
      SyllabusTopic(
        id: 'topic_cs_state_space',
        name: 'State Variable Analysis & Compensators',
        subjectId: 'subj_control_systems',
        subtopics: [
          SyllabusSubtopic(id: 'sub_cs_state_models', name: 'State Space Representation, Controllability & Observability', topicId: 'topic_cs_state_space'),
          SyllabusSubtopic(id: 'sub_cs_controllers', name: 'Lead, Lag Compensators & P, PI, PID Controllers', topicId: 'topic_cs_state_space'),
        ],
      ),
    ],
  ),
  SyllabusSubject(
    id: 'subj_microprocessors',
    name: 'Microprocessors & Microcontrollers',
    order: 9,
    topics: [
      SyllabusTopic(
        id: 'topic_up_8085_8086',
        name: '8085 and 8086 Architecture',
        subjectId: 'subj_microprocessors',
        subtopics: [
          SyllabusSubtopic(id: 'sub_up_registers', name: 'Pinout, Registers, Bus Architecture & Interrupts', topicId: 'topic_up_8085_8086'),
          SyllabusSubtopic(id: 'sub_up_instructions', name: 'Instruction Sets, Addressing Modes & Timing Diagrams', topicId: 'topic_up_8085_8086'),
        ],
      ),
      SyllabusTopic(
        id: 'topic_up_interfacing',
        name: 'Peripheral Interfacing & 8051 Microcontroller',
        subjectId: 'subj_microprocessors',
        subtopics: [
          SyllabusSubtopic(id: 'sub_up_ppi', name: '8255 PPI, 8254 Timer & 8259 Interrupt Controller', topicId: 'topic_up_interfacing'),
          SyllabusSubtopic(id: 'sub_up_8051_arch', name: '8051 Architecture, Timers, Serial Port & Embedded C', topicId: 'topic_up_interfacing'),
        ],
      ),
    ],
  ),
  SyllabusSubject(
    id: 'subj_computer_org',
    name: 'Computer Organization',
    order: 10,
    topics: [
      SyllabusTopic(
        id: 'topic_co_cpu',
        name: 'CPU, ALU & Datapath',
        subjectId: 'subj_computer_org',
        subtopics: [
          SyllabusSubtopic(id: 'sub_co_alu_ops', name: 'Fixed and Floating Point Arithmetic, Booth Multiplier', topicId: 'topic_co_cpu'),
          SyllabusSubtopic(id: 'sub_co_pipelining', name: 'Instruction Pipelining, Hazards & Branch Prediction', topicId: 'topic_co_cpu'),
        ],
      ),
      SyllabusTopic(
        id: 'topic_co_memory_io',
        name: 'Memory Hierarchy & I/O Organization',
        subjectId: 'subj_computer_org',
        subtopics: [
          SyllabusSubtopic(id: 'sub_co_cache', name: 'Direct, Associative, Set-Associative Cache Mapping', topicId: 'topic_co_memory_io'),
          SyllabusSubtopic(id: 'sub_co_dma', name: 'Interrupts, Programmed I/O & DMA Controllers', topicId: 'topic_co_memory_io'),
        ],
      ),
    ],
  ),
  SyllabusSubject(
    id: 'subj_vlsi',
    name: 'VLSI Design',
    order: 11,
    topics: [
      SyllabusTopic(
        id: 'topic_vlsi_cmos',
        name: 'CMOS Inverter & Logic Design',
        subjectId: 'subj_vlsi',
        subtopics: [
          SyllabusSubtopic(id: 'sub_vlsi_inverter_char', name: 'DC Characteristics, Noise Margins & Propagation Delay', topicId: 'topic_vlsi_cmos'),
          SyllabusSubtopic(id: 'sub_vlsi_complex_gates', name: 'Static CMOS, Pass Transistor & Transmission Gates', topicId: 'topic_vlsi_cmos'),
        ],
      ),
      SyllabusTopic(
        id: 'topic_vlsi_fabrication',
        name: 'Fabrication & Layout Rules',
        subjectId: 'subj_vlsi',
        subtopics: [
          SyllabusSubtopic(id: 'sub_vlsi_nwell_pwell', name: 'Photolithography, Oxidation, Diffusion & Ion Implantation', topicId: 'topic_vlsi_fabrication'),
          SyllabusSubtopic(id: 'sub_vlsi_design_rules', name: 'Lambda Design Rules, Stick Diagrams & Layout', topicId: 'topic_vlsi_fabrication'),
        ],
      ),
    ],
  ),
  SyllabusSubject(
    id: 'subj_power_electronics',
    name: 'Power Electronics',
    order: 12,
    topics: [
      SyllabusTopic(
        id: 'topic_pe_devices',
        name: 'Power Semiconductor Devices',
        subjectId: 'subj_power_electronics',
        subtopics: [
          SyllabusSubtopic(id: 'sub_pe_scr_triac', name: 'SCR Characteristics, Turn-on, Turn-off & Commutation', topicId: 'topic_pe_devices'),
          SyllabusSubtopic(id: 'sub_pe_power_mosfet', name: 'Power MOSFET, IGBT & GTO Operation', topicId: 'topic_pe_devices'),
        ],
      ),
      SyllabusTopic(
        id: 'topic_pe_converters',
        name: 'Converters, Inverters & Choppers',
        subjectId: 'subj_power_electronics',
        subtopics: [
          SyllabusSubtopic(id: 'sub_pe_controlled_rectifiers', name: 'Single & Three Phase Controlled Rectifiers', topicId: 'topic_pe_converters'),
          SyllabusSubtopic(id: 'sub_pe_choppers', name: 'Step-down, Step-up Choppers & PWM Inverters', topicId: 'topic_pe_converters'),
        ],
      ),
    ],
  ),
  SyllabusSubject(
    id: 'subj_measurements',
    name: 'Electronic Measurements',
    order: 13,
    topics: [
      SyllabusTopic(
        id: 'topic_em_instruments',
        name: 'Meters & Bridges',
        subjectId: 'subj_measurements',
        subtopics: [
          SyllabusSubtopic(id: 'sub_em_pmmc_mi', name: 'PMMC, Moving Iron & Electrodynamometer Instruments', topicId: 'topic_em_instruments'),
          SyllabusSubtopic(id: 'sub_em_ac_bridges', name: 'Wheatstone, Maxwell, Hay, Schering & Wien Bridges', topicId: 'topic_em_instruments'),
        ],
      ),
      SyllabusTopic(
        id: 'topic_em_cro_sensors',
        name: 'CRO, DSO & Transducers',
        subjectId: 'subj_measurements',
        subtopics: [
          SyllabusSubtopic(id: 'sub_em_cro', name: 'Cathode Ray Oscilloscope, Time Base, Lissajous Figures', topicId: 'topic_em_cro_sensors'),
          SyllabusSubtopic(id: 'sub_em_transducers', name: 'LVDT, Strain Gauges, Thermocouples & Piezoelectric Sensors', topicId: 'topic_em_cro_sensors'),
        ],
      ),
    ],
  ),
];

