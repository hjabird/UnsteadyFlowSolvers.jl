
let
    using UnsteadyFlowSolvers

    # Set up a single vortex
    start_vc = 0.05 # Core radius
    start_vort = -1.
    re = 1e3
    n_particles = 100
    radius = 1
    nu = start_vort / re
    field = TwoDVFlowField(re)
    for i = 1 : n_particles
        theta = i * 2 * pi / n_particles
        vort = TwoDVVort(radius * sin(theta), radius * cos(theta), 
            start_vort/n_particles, start_vc, 0., 0., 0.)
        push!(field.tev, vort)
    end
    # Solver settings
    dt = 0.015
    t0 = 0.
    tmax = 1.5
    t = t0
    nsteps = Int(ceil((tmax-t)/dt)) + 1

    for i = 1:nsteps
        t += dt
        UnsteadyFlowSolvers.wakeroll(field, dt)
        ave = mapreduce(x->x.vc, +, field.tev) / (n_particles)
        stddev = sqrt(mapreduce(x->(x.vc-ave)^2, +, field.tev) / (n_particles-1))
        println("Average core readius: ", ave, " std deviation = ", stddev)
    end
end
