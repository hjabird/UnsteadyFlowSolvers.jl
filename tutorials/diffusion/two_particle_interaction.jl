
let
    using UnsteadyFlowSolvers

    # Set up a single vortex
    start_vc = 0.02 # Core radius
    start_vort = 1.
    re = 1e3
    nu = start_vort / re
    field = TwoDVFlowField(nu)
    vort = TwoDVVort(0., 0., start_vort, start_vc, 0., 0., 0.)
    push!(field.tev, vort)
    vort = TwoDVVort(0., 0.01, start_vort, start_vc, 0., 0., 0.)
    push!(field.tev, vort)

    # Solver settings
    dt = 0.015
    t0 = 0.
    tmax = 1.5
    t = t0
    nsteps = Int(ceil((tmax-t)/dt)) + 1

    for i = 1:nsteps
        t += dt
        UnsteadyFlowSolvers.wakeroll(field, dt)
        println("Step\t",i,":\tCore 1\t",field.tev[1].vc, "\tCore 2\t", field.tev[2].vc)
        println("\t\t", "VelX 1\t",field.tev[1].vx, "\tVelX 2\t", field.tev[2].vx)
        println("\t\t", "VelZ 1\t",field.tev[1].vz, "\tVelZ 2\t", field.tev[2].vz)
    end
end
