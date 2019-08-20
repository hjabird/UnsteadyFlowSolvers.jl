
let
    using UnsteadyFlowSolvers

    # Set up a single vortex
    start_vc = 0.02 # Core radius
    start_vort = 1.
    re = 1e3
    ref_len = 1
    nu = start_vort / re
    vort = TwoDVVort(0., 0., start_vort, start_vc, 0., 0., 0.)
    field = TwoDVFlowField(nu)
    push!(field.tev, vort)

    # Solver settings
    dt = 0.015
    t0 = 0.
    tmax = 1.5
    t = t0
    nsteps = Int(ceil((tmax-t)/dt)) + 1

    # Comparison to the (Gaussian) Lamb-Oseen vortex
    rc = t->sqrt(4 * nu * (t-t0) + start_vc^2)

    for i = 1:nsteps
        t += dt
        UnsteadyFlowSolvers.wakeroll(field, dt)
        println("Step\t",i,":\tCore radius is \t",field.tev[1].vc, "\tLamb-Oseen radius is\t", rc(t))
    end
end
