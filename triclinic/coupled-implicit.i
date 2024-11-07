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
    model = 'model_with_stress'
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
  [euler_rodrigues]
    type = RotationMatrix
    from = 'state/orientation'
    to = 'state/orientation_matrix'
  []
  [elasticity]
    type = GeneralElasticity
    elastic_stiffness_tensor = 'C'
    strain = 'state/elastic_strain'
    stress = 'state/internal/cauchy_stress'
  []
  [resolved_shear]
    type = ResolvedShear
  []
  [elastic_stretch]
    type = ElasticStrainRate
  []
  [plastic_spin]
    type = PlasticVorticity
  []
  [plastic_deformation_rate]
    type = PlasticDeformationRate
  []
  [orientation_rate]
    type = OrientationRate
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
  [integrate_orientation]
    type = WR2ImplicitExponentialTimeIntegration
    variable = 'state/orientation'
  []

  [implicit_rate]
    type = ComposedModel
    models = "euler_rodrigues elasticity orientation_rate resolved_shear
              elastic_stretch plastic_deformation_rate plastic_spin
              sum_slip_rates slip_rule slip_strength voce_hardening
              integrate_slip_hardening integrate_elastic_strain integrate_orientation"
  []
  [model]
    type = ImplicitUpdate
    implicit_model = 'implicit_rate'
    solver = 'newton'
  []
  [model_with_stress]
    type = ComposedModel
    models = 'model elasticity'
    additional_outputs = 'state/elastic_strain state/orientation'
  []
[]
