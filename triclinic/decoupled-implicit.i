[Tensors]
  [end_time]
    type = FullScalar
    batch_shape = '(${nbatch})'
    value = 1000.0
  []
  [times]
    type = LinspaceScalar
    start = 0
    end = end_time
    nstep = ${nstep}
  []
  [dxx]
    type = FullScalar
    batch_shape = '(${nbatch})'
    value = 0.0
  []
  [dyy]
    type = FullScalar
    batch_shape = '(${nbatch})'
    value = 0.001
  []
  [dzz]
    type = FullScalar
    batch_shape = '(${nbatch})'
    value = -0.001
  []
  [deformation_rate_single]
    type = FillSR2
    values = 'dxx dyy dzz'
  []
  [deformation_rate]
    type = LinspaceSR2
    start = deformation_rate_single
    end = deformation_rate_single
    nstep = ${nstep}
  []

  [w1]
    type = FullScalar
    batch_shape = '(${nbatch})'
    value = 0.0
  []
  [w2]
    type = FullScalar
    batch_shape = '(${nbatch})'
    value = 0.0
  []
  [w3]
    type = FullScalar
    batch_shape = '(${nbatch})'
    value = 0.0
  []
  [vorticity_single]
    type = FillWR2
    values = 'w1 w2 w3'
  []
  [vorticity]
    type = LinspaceWR2
    start = vorticity_single
    end = vorticity_single
    nstep = ${nstep}
  []

  [sdirs]
    type = FillMillerIndex
    values = '0 0 1 
              0 0 1
              0 1 0
              0 1 0
              1 0 0
              1 0 0'
  []
  [splanes]
    type = FillMillerIndex
    values = '0 1 0
              1 0 0
              1 0 0
              0 0 1
              0 1 0
              0 0 1'
  []

  [initial_orientation]
    type = Orientation
    input_type = 'random'
    random_seed = 42
    quantity = ${nbatch}
    normalize = true
  []

  [C]
    type = SSR4
    values = "120000.0 30000.0 26000.0 6000 -3000 -1000
             30000.0 320000.0 5000.0 -5000 -10000.0 -8000
             26000.0 5000.0 320000.0 -11000 10000.0 -10000
             6000.0 -5000 -11000 90000.0 -4000 -12000.0
             -3000 -10000.0 10000.0 -4000 95000.0 1000.0
             -1000 -8000 -10000 -12000 1000.0 120000.0"
  []
  [lvecs]
    type = Vec
    batch_shape = '(3)'
    values = "8.1 0.0 0.0
              -0.5 12.7 0.0
              3.2 -0.41 6.4"
  []
  [class_1]
    type = SymmetryFromOrbifold
    orbifold = "1"
  [] 
[]

[Drivers]
  [driver]
    type = LargeDeformationIncrementalSolidMechanicsDriver
    model = 'model'
    times = 'times'
    prescribed_deformation_rate = 'deformation_rate'
    prescribed_vorticity = 'vorticity'
    ic_rot_names = 'state/orientation'
    ic_rot_values = 'initial_orientation'
    predictor = 'CP_PREVIOUS_STATE'
    save_as = 'result-triclinic.pt'
    cp_elastic_scale = 0.01
    device = ${device}
  []
[]


[Solvers]
  [newton]
    type = NewtonWithLineSearch
    max_linesearch_iterations = 5
  []
[]

[Data]
  [crystal_geometry]
    type = CrystalGeometry
    lattice_vectors = 'lvecs'
    crystal_class = 'class_1'
    slip_directions = "sdirs"
    slip_planes = "splanes"
  []
[]

[Models]
  ############################################################################
  # Sub-system #1 for updating elastic strain and internal variables
  ############################################################################
  [euler_rodrigues_1]
    type = RotationMatrix
    from = 'forces/tmp/orientation'
    to = 'state/orientation_matrix'
  []
  [elasticity_1]
    type = GeneralElasticity
    elastic_stiffness_tensor = 'C'
    strain = 'state/elastic_strain'
    stress = 'state/internal/cauchy_stress'
    orientation = 'forces/tmp/orientation'
  []
  [resolved_shear]
    type = ResolvedShear
  []
  [elastic_stretch]
    type = ElasticStrainRate
  []
  [plastic_deformation_rate]
    type = PlasticDeformationRate
  []
  [sum_slip_rates]
    type = SumSlipRates
  []
  [slip_rule]
    type = PowerLawSlipRule
    n = 8.0
    gamma0 = 2.0e-1
  []
  [slip_strength]
    type = SingleSlipStrengthMap
    constant_strength = 50.0
  []
  [voce_hardening]
    type = VoceSingleSlipHardeningRule
    initial_slope = 500.0
    saturated_hardening = 50.0
  []
  [integrate_slip_hardening]
    type = ScalarBackwardEulerTimeIntegration
    variable = 'state/internal/slip_hardening'
  []
  [integrate_elastic_strain]
    type = SR2BackwardEulerTimeIntegration
    variable = 'state/elastic_strain'
  []
  [implicit_rate_1]
    type = ComposedModel
    models = "euler_rodrigues_1 elasticity_1 resolved_shear
              elastic_stretch plastic_deformation_rate
              sum_slip_rates slip_rule slip_strength voce_hardening
              integrate_slip_hardening integrate_elastic_strain"
  []
  [subsystem1]
    type = ImplicitUpdate
    implicit_model = 'implicit_rate_1'
    solver = 'newton'
  []

  ############################################################################
  # Sub-system #2 for updating orientation
  ############################################################################
  [euler_rodrigues_2]
    type = RotationMatrix
    from = 'state/orientation'
    to = 'state/orientation_matrix'
  []
  [elasticity_2]
    type = GeneralElasticity
    elastic_stiffness_tensor = 'C'
    strain = 'forces/tmp/elastic_strain'
    stress = 'state/internal/cauchy_stress'
  []
  [orientation_rate]
    type = OrientationRate
    elastic_strain = 'forces/tmp/elastic_strain'
  []
  [plastic_spin]
    type = PlasticVorticity
  []
  [slip_strength_2]
    type = SingleSlipStrengthMap
    constant_strength = 50.0
    slip_hardening = 'forces/tmp/internal/slip_hardening'
  []
  [integrate_orientation]
    type = WR2ImplicitExponentialTimeIntegration
    variable = 'state/orientation'
  []
  [implicit_rate_2]
    type = ComposedModel
    models = "euler_rodrigues_2 elasticity_2 resolved_shear
              plastic_deformation_rate plastic_spin
              slip_rule slip_strength_2 orientation_rate
              integrate_orientation"
  []
  [subsystem2]
    type = ImplicitUpdate
    implicit_model = 'implicit_rate_2'
    solver = 'newton'
  []

  ############################################################################
  # Cache information from sub-system #1
  ############################################################################
  [cache_elastic_strain]
    type = CopySR2
    from = 'state/elastic_strain'
    to = 'forces/tmp/elastic_strain'
  []
  [cache_slip_hardening]
    type = CopyScalar
    from = 'state/internal/slip_hardening'
    to = 'forces/tmp/internal/slip_hardening'
  []
  [cache1]
    type = ComposedModel
    models = 'cache_elastic_strain cache_slip_hardening'
  []

  ############################################################################
  # Cache information from sub-system #2
  ############################################################################
  [cache2]
    type = CopyWR2
    from = 'state/orientation'
    to = 'forces/tmp/orientation'
  []

  ############################################################################
  # Sequentially update sub-system #1 and sub-system #2
  ############################################################################
  [model]
    type = ComposedModel
    models = 'cache2 subsystem1 cache1 subsystem2'
    priority = 'cache2 subsystem1 cache1 subsystem2'
    additional_outputs = 'state/elastic_strain state/internal/slip_hardening state/orientation'
  []
[]
