# Function for estimating a problem's time step
function update_a2a3adot(surf::TwoDSurf,dt)
    for ia = 2:3
        surf.aterm[ia] = simpleTrapz(surf.downwash.*cos.(ia*surf.theta),surf.theta)
        surf.aterm[ia] = 2. *surf.aterm[ia]/(surf.uref*pi)
    end
    surf.a0dot[1] = (surf.a0[1] - surf.a0prev[1])/dt
    for ia = 1:3
        surf.adot[ia] = (surf.aterm[ia]-surf.aprev[ia])/dt
    end
    return surf
end

function update_atermdot(surf::TwoDSurf,dt)
    for ia = 2:surf.naterm
        surf.aterm[ia] = simpleTrapz(surf.downwash.*cos.(ia*surf.theta),surf.theta)
        surf.aterm[ia] = 2. *surf.aterm[ia]/(surf.uref*pi)
    end
    surf.a0dot[1] = (surf.a0[1] - surf.a0prev[1])/dt
    for ia = 1:surf.naterm
        surf.adot[ia] = (surf.aterm[ia]-surf.aprev[ia])/dt
    end
    return surf
end

function update_adot(surf::TwoDSurf,dt)
    surf.a0dot[1] = (surf.a0[1] - surf.a0prev[1])/dt
    for ia = 1:3
        surf.adot[ia] = (surf.aterm[ia]-surf.aprev[ia])/dt
    end
    return surf
end

# Function for updating the induced velocities
function update_indbound(surf::TwoDSurf, curfield::TwoDFlowField)
    surf.uind[1:surf.ndiv], surf.wind[1:surf.ndiv] = ind_vel([curfield.tev; curfield.lev; curfield.extv], surf.bnd_x, surf.bnd_z)
    return surf
end

function update_indbound(surf::TwoDSurf, curfield::TwoDVFlowField)
    surf.uind[1:surf.ndiv], surf.wind[1:surf.ndiv] = ind_vel([curfield.tev; curfield.lev; curfield.extv], surf.bnd_x, surf.bnd_z)
    return surf
end


function add_indbound_b(surf::TwoDSurf, surfj::TwoDSurf)
    uind, wind = ind_vel(surfj.bv, surf.bnd_x, surf.bnd_z)
    surf.uind[:] += uind
    surf.wind[:] += wind
    return surf
    
end

# Function for updating the downwash
function update_downwash(surf::TwoDSurf, vels::Vector{Float64})
    for ib = 1:surf.ndiv
        surf.downwash[ib] = -(surf.kinem.u + vels[1])*sin(surf.kinem.alpha) - surf.uind[ib]*sin(surf.kinem.alpha) + (surf.kinem.hdot - vels[2])*cos(surf.kinem.alpha) - surf.wind[ib]*cos(surf.kinem.alpha) - surf.kinem.alphadot*(surf.x[ib] - surf.pvt*surf.c) + surf.cam_slope[ib]*(surf.uind[ib]*cos(surf.kinem.alpha) + (surf.kinem.u + vels[1])*cos(surf.kinem.alpha) + (surf.kinem.hdot - vels[2])*sin(surf.kinem.alpha) - surf.wind[ib]*sin(surf.kinem.alpha))
    end
    return surf
end

# Function for a_0 and a_1 fourier coefficients
function update_a0anda1(surf::TwoDSurf)
    surf.a0[1] = simpleTrapz(surf.downwash,surf.theta)
    surf.aterm[1] = simpleTrapz(surf.downwash.*cos.(surf.theta),surf.theta)
    surf.a0[1] = -surf.a0[1]/(surf.uref*pi)
    surf.aterm[1] = 2. *surf.aterm[1]/(surf.uref*pi)
    return surf
end

# Function for calculating the fourier coefficients a_2 upwards to a_n
function update_a2toan(surf::TwoDSurf)
    for ia = 2:surf.naterm
        surf.aterm[ia] = simpleTrapz(surf.downwash.*cos.(ia*surf.theta),surf.theta)
        surf.aterm[ia] = 2. *surf.aterm[ia]/(surf.uref*pi)
    end
    return surf
end

# Function to update the external flowfield
function update_externalvel(curfield::TwoDFlowField, t)
    if (typeof(curfield.velX) == CosDef)
        curfield.u[1] = curfield.velX(t)
        curfield.w[1] = curfield.velZ(t)
    elseif (typeof(curfield.velX) == SinDef)
        curfield.u[1] = curfield.velX(t)
        curfield.w[1] = curfield.velZ(t)
    elseif (typeof(curfield.velX) == ConstDef)
        curfield.u[1] = curfield.velX(t)
        curfield.w[1] = curfield.velZ(t)
    end
    if (typeof(curfield.velX) == StepGustDef)
        curfield.u[1] = curfield.velX(t)
    end
    if (typeof(curfield.velZ) == StepGustDef)
        curfield.w[1] = curfield.velZ(t)
    end
end

function update_externalvel(curfield::TwoDVFlowField, t)
    if (typeof(curfield.velX) == CosDef)
        curfield.u[1] = curfield.velX(t)
        curfield.w[1] = curfield.velZ(t)
    elseif (typeof(curfield.velX) == SinDef)
        curfield.u[1] = curfield.velX(t)
        curfield.w[1] = curfield.velZ(t)
    elseif (typeof(curfield.velX) == ConstDef)
        curfield.u[1] = curfield.velX(t)
        curfield.w[1] = curfield.velZ(t)
    end
    if (typeof(curfield.velX) == StepGustDef)
        curfield.u[1] = curfield.velX(t)
    end
    if (typeof(curfield.velZ) == StepGustDef)
        curfield.w[1] = curfield.velZ(t)
    end
end



# Function updating the dimensional kinematic parameters
function update_kinem(surf::TwoDSurf, t)

    # Pitch kinematics
    if (typeof(surf.kindef.alpha) == EldUpDef)
        surf.kinem.alpha = surf.kindef.alpha(t)
        surf.kinem.alphadot = ForwardDiff.derivative(surf.kindef.alpha,t)*surf.uref/surf.c
    elseif (typeof(surf.kindef.alpha) == EldUptstartDef)
        surf.kinem.alpha = surf.kindef.alpha(t)
        surf.kinem.alphadot = ForwardDiff.derivative(surf.kindef.alpha,t)*surf.uref/surf.c
    elseif (typeof(surf.kindef.alpha) == EldRampReturnDef)
        surf.kinem.alpha = surf.kindef.alpha(t)
        surf.kinem.alphadot = ForwardDiff.derivative(surf.kindef.alpha,t)*surf.uref/surf.c
    elseif (typeof(surf.kindef.alpha) == ConstDef)
        surf.kinem.alpha = surf.kindef.alpha(t)
        surf.kinem.alphadot = 0.
    elseif (typeof(surf.kindef.alpha) == SinDef)
        surf.kinem.alpha = surf.kindef.alpha(t)
        surf.kinem.alphadot = ForwardDiff.derivative(surf.kindef.alpha,t)*surf.uref/surf.c
    elseif (typeof(surf.kindef.alpha) == CosDef)
        surf.kinem.alpha = surf.kindef.alpha(t)
        surf.kinem.alphadot = ForwardDiff.derivative(surf.kindef.alpha,t)*surf.uref/surf.c
    elseif (typeof(surf.kindef.alpha) == VAWTalphaDef)
        surf.kinem.alpha = surf.kindef.alpha(t)
        surf.kinem.alphadot = ForwardDiff.derivative(surf.kindef.alpha,t)*surf.uref/surf.c
    end
    # ---------------------------------------------------------------------------------------------

    # Plunge kinematics
    if (typeof(surf.kindef.h) == EldUpDef)
        surf.kinem.h = surf.kindef.h(t)*surf.c
        surf.kinem.hdot = ForwardDiff.derivative(surf.kindef.h,t)*surf.uref
    elseif (typeof(surf.kindef.h) == EldUptstartDef)
        surf.kinem.h = surf.kindef.h(t)*surf.c
        surf.kinem.hdot = ForwardDiff.derivative(surf.kindef.h,t)*surf.uref
    elseif (typeof(surf.kindef.h) == EldUpIntDef)
        surf.kinem.h = surf.kindef.h(t)*surf.c
        surf.kinem.hdot = ForwardDiff.derivative(surf.kindef.h,t)*surf.uref
    elseif (typeof(surf.kindef.h) == EldUpInttstartDef)
        surf.kinem.h = surf.kindef.h(t)*surf.c
        surf.kinem.hdot = ForwardDiff.derivative(surf.kindef.h,t)*surf.uref
    elseif (typeof(surf.kindef.h) == EldRampReturnDef)
        surf.kinem.h = surf.kindef.h(t)*surf.c
        surf.kinem.hdot = ForwardDiff.derivative(surf.kindef.h,t)*surf.uref
    elseif (typeof(surf.kindef.h) == ConstDef)
        surf.kinem.h = surf.kindef.h(t)*surf.c
        surf.kinem.hdot = 0.
    elseif (typeof(surf.kindef.h) == SinDef)
        surf.kinem.h = surf.kindef.h(t)*surf.c
        surf.kinem.hdot = ForwardDiff.derivative(surf.kindef.h,t)*surf.uref
    elseif (typeof(surf.kindef.h) == CosDef)
        surf.kinem.h = surf.kindef.h(t)*surf.c
        surf.kinem.hdot = ForwardDiff.derivative(surf.kindef.h,t)*surf.uref
    elseif (typeof(surf.kindef.h) == VAWThDef)
        surf.kinem.h = surf.kindef.h(t)*surf.c
        surf.kinem.hdot = ForwardDiff.derivative(surf.kindef.h,t)*surf.uref
    end
    # ---------------------------------------------------------------------------------------------

    # Forward velocity
    if (typeof(surf.kindef.u) == EldUpDef)
        surf.kinem.u = surf.kindef.u(t)*surf.uref
        surf.kinem.udot = ForwardDiff.derivative(surf.kindef.u,t)*surf.uref*surf.uref/surf.c
    elseif (typeof(surf.kindef.u) == EldRampReturnDef)
        surf.kinem.u = surf.kindef.u(t)*surf.uref
        surf.kinem.udot = ForwardDiff.derivative(surf.kindef.u,t)*surf.uref*surf.uref/surf.c
    elseif (typeof(surf.kindef.u) == ConstDef)
        surf.kinem.u = surf.kindef.u(t)*surf.uref
        surf.kinem.udot = 0.
    elseif (typeof(surf.kindef.u) == SinDef)
        surf.kinem.u = surf.kindef.u(t)*surf.uref
        surf.kinem.udot = ForwardDiff.derivative(surf.kindef.u,t)*surf.uref*surf.uref/surf.c
    elseif (typeof(surf.kindef.u) == CosDef)
        surf.kinem.u = surf.kindef.u(t)*surf.uref
        surf.kinem.udot = ForwardDiff.derivative(surf.kindef.u,t)*surf.uref*surf.uref/surf.c
    elseif (typeof(surf.kindef.u) == LinearDef)
        surf.kinem.u = surf.kindef.u(t)*surf.uref
        surf.kinem.udot = ForwardDiff.derivative(surf.kindef.u,t)*surf.uref*surf.uref/surf.c
    elseif (typeof(surf.kindef.u) == VAWTuDef)
        surf.kinem.u = surf.kindef.u(t)*surf.uref
        surf.kinem.udot = ForwardDiff.derivative(surf.kindef.u,t)*surf.uref*surf.uref/surf.c
    end
    # ---------------------------------------------------------------------------------------------
    return surf
end

# ---------------------------------------------------------------------------------------------
# Updates the bound vorticity distribution: eqn (2.1) in Ramesh et al. (2013)
# determines the strength of bound vortices
# determines the x, z components of the bound vortices
function update_bv(surf::TwoDSurf)
    gamma = zeros(surf.ndiv)
    for ib = 1:surf.ndiv
        gamma[ib] = (surf.a0[1]*(1 + cos(surf.theta[ib])))
        for ia = 1:surf.naterm
            gamma[ib] = gamma[ib] + surf.aterm[ia]*sin(ia*surf.theta[ib])*sin(surf.theta[ib])
        end
        gamma[ib] = gamma[ib]*surf.uref*surf.c
    end

    for ib = 2:surf.ndiv
        surf.bv[ib-1].s = (gamma[ib]+gamma[ib-1])*(surf.theta[2]-surf.theta[1])/2.
        surf.bv[ib-1].x = (surf.bnd_x[ib] + surf.bnd_x[ib-1])/2.
        surf.bv[ib-1].z = (surf.bnd_z[ib] + surf.bnd_z[ib-1])/2.
    end
end

# Function for calculating the wake rollup
function wakeroll(surf::TwoDSurf, curfield::TwoDFlowField, dt)

    nlev = length(curfield.lev)
    ntev = length(curfield.tev)
    nextv = length(curfield.extv)

    #Clean induced velocities
    for i = 1:ntev
        curfield.tev[i].vx = 0
        curfield.tev[i].vz = 0
    end

    for i = 1:nlev
        curfield.lev[i].vx = 0
        curfield.lev[i].vz = 0
    end

    for i = 1:nextv
        curfield.extv[i].vx = 0
        curfield.extv[i].vz = 0
    end

    #Velocities induced by free vortices on each other
    mutual_ind([curfield.tev; curfield.lev; curfield.extv])

    #Add the influence of velocities induced by bound vortices
    utemp = zeros(ntev + nlev + nextv)
    wtemp = zeros(ntev + nlev + nextv)
    utemp, wtemp = ind_vel(surf.bv, [map(q -> q.x, curfield.tev); map(q -> q.x, curfield.lev); map(q -> q.x, curfield.extv)], [map(q -> q.z, curfield.tev); map(q -> q.z, curfield.lev); map(q -> q.z, curfield.extv) ])

    for i = 1:ntev
        curfield.tev[i].vx += utemp[i]
        curfield.tev[i].vz += wtemp[i]
    end
    for i = ntev+1:ntev+nlev
        curfield.lev[i-ntev].vx += utemp[i]
        curfield.lev[i-ntev].vz += wtemp[i]
    end
    for i = ntev+nlev+1:ntev+nlev+nextv
        curfield.extv[i-ntev-nlev].vx += utemp[i]
        curfield.extv[i-ntev-nlev].vz += wtemp[i]
    end

    #Add the influence of freestream velocities
    for i = 1:ntev
        curfield.tev[i].vx += curfield.u[1]
        curfield.tev[i].vz += curfield.w[1]
    end
    for i = 1:nlev
        curfield.lev[i].vx += curfield.u[1]
        curfield.lev[i].vz += curfield.w[1]
    end
    for i = 1:nextv
        curfield.extv[i].vx += curfield.u[1]
        curfield.extv[i].vz += curfield.w[1]
    end

    #Convect free vortices with their induced velocities
    for i = 1:ntev
        curfield.tev[i].x += dt*curfield.tev[i].vx
        curfield.tev[i].z += dt*curfield.tev[i].vz
    end
    for i = 1:nlev
        curfield.lev[i].x += dt*curfield.lev[i].vx
        curfield.lev[i].z += dt*curfield.lev[i].vz
    end
    for i = 1:nextv
        curfield.extv[i].x += dt*curfield.extv[i].vx
        curfield.extv[i].z += dt*curfield.extv[i].vz
    end

    return curfield
end


# Function for calculating the wake rollup
function wakeroll(surf::TwoDSurf, curfield::TwoDVFlowField, dt)

    nu = curfield.kinematic_visc
    nlev = length(curfield.lev)
    ntev = length(curfield.tev)
    nextv = length(curfield.extv)

    #Clean induced velocities
    for i = 1:ntev
        curfield.tev[i].vx = 0
        curfield.tev[i].vz = 0
        curfield.tev[i].dvc = 0
    end

    for i = 1:nlev
        curfield.lev[i].vx = 0
        curfield.lev[i].vz = 0
        curfield.lev[i].dvc = 0
    end

    for i = 1:nextv
        curfield.extv[i].vx = 0
        curfield.extv[i].vz = 0
        curfield.extv[i].dvc = 0
    end

    #Velocities induced by free vortices on each other
    mutual_ind_v_gaussian([curfield.tev; curfield.lev; curfield.extv; surf.bv], nu)

    # #Add the influence of velocities induced by bound vortices
    # utemp = zeros(ntev + nlev + nextv)
    # wtemp = zeros(ntev + nlev + nextv)
    # utemp, wtemp = ind_vel(surf.bv, [map(q -> q.x, curfield.tev); map(q -> q.x, curfield.lev); map(q -> q.x, curfield.extv)], [map(q -> q.z, curfield.tev); map(q -> q.z, curfield.lev); map(q -> q.z, curfield.extv) ])

    # for i = 1:ntev
    #     curfield.tev[i].vx += utemp[i]
    #     curfield.tev[i].vz += wtemp[i]
    # end
    # for i = ntev+1:ntev+nlev
    #     curfield.lev[i-ntev].vx += utemp[i]
    #     curfield.lev[i-ntev].vz += wtemp[i]
    # end
    # for i = ntev+nlev+1:ntev+nlev+nextv
    #     curfield.extv[i-ntev-nlev].vx += utemp[i]
    #     curfield.extv[i-ntev-nlev].vz += wtemp[i]
    # end

    #Add the influence of freestream velocities
    for i = 1:ntev
        curfield.tev[i].vx += curfield.u[1]
        curfield.tev[i].vz += curfield.w[1]
    end
    for i = 1:nlev
        curfield.lev[i].vx += curfield.u[1]
        curfield.lev[i].vz += curfield.w[1]
    end
    for i = 1:nextv
        curfield.extv[i].vx += curfield.u[1]
        curfield.extv[i].vz += curfield.w[1]
    end

    #Convect free vortices with their induced velocities and perform core expansion
    for i = 1:ntev
        curfield.tev[i].x += dt*curfield.tev[i].vx
        curfield.tev[i].z += dt*curfield.tev[i].vz
        curfield.tev[i].vc = sqrt(curfield.tev[i].vc^2 + dt*curfield.tev[i].dvc)
    end
    for i = 1:nlev
        curfield.lev[i].x += dt*curfield.lev[i].vx
        curfield.lev[i].z += dt*curfield.lev[i].vz
        curfield.lev[i].vc = sqrt(curfield.lev[i].vc^2 + dt*curfield.lev[i].dvc)
    end
    for i = 1:nextv
        curfield.extv[i].x += dt*curfield.extv[i].vx
        curfield.extv[i].z += dt*curfield.extv[i].vz
        curfield.extv[i].vc = sqrt(curfield.extv[i].vc^2 + dt*curfield.extv[i].dvc)
    end
    return
end


function wakeroll(surf::Vector{TwoDSurf}, curfield::TwoDFlowField, dt)

    nlev = length(curfield.lev)
    ntev = length(curfield.tev)
    nextv = length(curfield.extv)
    nsurf = length(surf)

    #Clean induced velocities
    for i = 1:ntev
        curfield.tev[i].vx = 0
        curfield.tev[i].vz = 0
    end

    for i = 1:nlev
        curfield.lev[i].vx = 0
        curfield.lev[i].vz = 0
    end

    for i = 1:nextv
        curfield.extv[i].vx = 0
        curfield.extv[i].vz = 0
    end

    #Velocities induced by free vortices on each other
    mutual_ind([curfield.tev; curfield.lev; curfield.extv])

    #Add the influence of velocities induced by bound vortices
    utemp = zeros(ntev + nlev + nextv)
    wtemp = zeros(ntev + nlev + nextv)
    for is = 1:nsurf
        ut, wt = ind_vel(surf[is].bv, [map(q -> q.x, curfield.tev); map(q -> q.x, curfield.lev); map(q -> q.x, curfield.extv)], [map(q -> q.z, curfield.tev); map(q -> q.z, curfield.lev); map(q -> q.z, curfield.extv) ])
        utemp += ut
        wtemp += wt
    end
    for i = 1:ntev
        curfield.tev[i].vx += utemp[i]
        curfield.tev[i].vz += wtemp[i]
    end
    for i = ntev+1:ntev+nlev
        curfield.lev[i-ntev].vx += utemp[i]
        curfield.lev[i-ntev].vz += wtemp[i]
    end
    for i = ntev+nlev+1:ntev+nlev+nextv
        curfield.extv[i-ntev-nlev].vx += utemp[i]
        curfield.extv[i-ntev-nlev].vz += wtemp[i]
    end

    #Add the influence of freestream velocities
    for i = 1:ntev
        curfield.tev[i].vx += curfield.u[1]
        curfield.tev[i].vz += curfield.w[1]
    end
    for i = 1:nlev
        curfield.lev[i].vx += curfield.u[1]
        curfield.lev[i].vz += curfield.w[1]
    end
    for i = 1:nextv
        curfield.extv[i].vx += curfield.u[1]
        curfield.extv[i].vz += curfield.w[1]
    end

    #Convect free vortices with their induced velocities
    for i = 1:ntev
        curfield.tev[i].x += dt*curfield.tev[i].vx
        curfield.tev[i].z += dt*curfield.tev[i].vz
    end
    for i = 1:nlev
        curfield.lev[i].x += dt*curfield.lev[i].vx
        curfield.lev[i].z += dt*curfield.lev[i].vz
    end
    for i = 1:nextv
        curfield.extv[i].x += dt*curfield.extv[i].vx
        curfield.extv[i].z += dt*curfield.extv[i].vz
    end

    return curfield
end

function wakeroll(curfield::TwoDVFlowField, dt)
    # How to calculate nu based on a Reynolds number? Assume Re=Gamma/nu
    nu = curfield.kinematic_visc
    nlev = length(curfield.lev)
    ntev = length(curfield.tev)
    nextv = length(curfield.extv)

    #Clean induced velocities
    for i = 1:ntev
        curfield.tev[i].vx = 0
        curfield.tev[i].vz = 0
        curfield.tev[i].dvc = 0
    end

    for i = 1:nlev
        curfield.lev[i].vx = 0
        curfield.lev[i].vz = 0
        curfield.lev[i].dvc = 0
    end

    for i = 1:nextv
        curfield.extv[i].vx = 0
        curfield.extv[i].vz = 0
        curfield.extv[i].dvc = 0
    end

    #Velocities induced by free vortices on each other
    mutual_ind_v_gaussian([curfield.tev; curfield.lev; curfield.extv], nu)

    #Convect free vortices with their induced velocities
    #Update core size of vortices
    for i = 1:ntev
        curfield.tev[i].x += dt*curfield.tev[i].vx
        curfield.tev[i].z += dt*curfield.tev[i].vz
        curfield.tev[i].vc = sqrt(dt*curfield.tev[i].dvc + curfield.tev[i].vc^2)
    end

    for i = 1:nlev
        curfield.lev[i].x += dt*curfield.lev[i].vx
        curfield.lev[i].z += dt*curfield.lev[i].vz
        curfield.lev[i].vc = sqrt(dt*curfield.lev[i].dvc + curfield.lev[i].vc^2)
    end
    for i = 1:nextv
        curfield.extv[i].x += dt*curfield.extv[i].vx
        curfield.extv[i].z += dt*curfield.extv[i].vz
        curfield.extv[i].vc = sqrt(dt*curfield.extv[i].dvc + curfield.extv[i].vc^2)
    end

    return curfield
end


# Places a trailing edge vortex
function place_tev(surf::TwoDSurf,field::TwoDFlowFieldAbstract,dt)
    ntev = length(field.tev)

    if ntev == 0
        xloc = surf.bnd_x[surf.ndiv] + 0.5*surf.kinem.u*dt
        zloc = surf.bnd_z[surf.ndiv]
    else
        xloc = surf.bnd_x[surf.ndiv]+(1. /3.)*(field.tev[ntev].x - surf.bnd_x[surf.ndiv])

        zloc = surf.bnd_z[surf.ndiv]+(1. /3.)*(field.tev[ntev].z - surf.bnd_z[surf.ndiv])
    end
    push!(field.tev, vortex_type(field)(xloc,zloc,0.,0.02*surf.c,0.,0.))
    return field
end

function place_tev(surf::Vector{TwoDSurf},field::TwoDFlowFieldAbstract,dt)
    nsurf = length(surf)
    ntev = length(field.tev)

    if ntev < nsurf
        for i = 1:nsurf
            xloc = surf[i].bnd_x[end] + 0.5*surf[i].kinem.u*dt
            zloc = surf[i].bnd_z[end]
            push!(field.tev, vortex_type(field)(xloc,zloc,0.,0.02*surf[i].c))
        end
    else
        for i = 1:nsurf
            xloc = surf[i].bnd_x[end]+(1. /3.)*(field.tev[ntev-nsurf+i].x - surf[i].bnd_x[end])
            zloc = surf[i].bnd_z[end]+(1. /3.)*(field.tev[ntev-nsurf+i].z - surf[i].bnd_z[end])
            push!(field.tev, vortex_type(field)(xloc,zloc,0.,0.02*surf[i].c))
        end
    end
    return field
end

# Places a leading edge vortex
function place_lev(surf::TwoDSurf,field::TwoDFlowField,dt)
    nlev = length(field.lev)

    le_vel_x = surf.kinem.u - surf.kinem.alphadot*sin(surf.kinem.alpha)*surf.pvt*surf.c + surf.uind[1]
    le_vel_z = -surf.kinem.alphadot*cos(surf.kinem.alpha)*surf.pvt*surf.c- surf.kinem.hdot + surf.wind[1]

    if (surf.levflag[1] == 0)
        xloc = surf.bnd_x[1] + 0.5*le_vel_x*dt
        zloc = surf.bnd_z[1] + 0.5*le_vel_z*dt
    else
        xloc = surf.bnd_x[1]+(1. /3.)*(field.lev[nlev].x - surf.bnd_x[1])
        zloc = surf.bnd_z[1]+(1. /3.)*(field.lev[nlev].z - surf.bnd_z[1])
    end

    push!(field.lev,TwoDVort(xloc,zloc,0.,0.02*surf.c,0.,0.))

    return field
end

function place_lev(surf::Vector{TwoDSurf},field::TwoDFlowField,dt,shed_ind::Vector{Int})
    nsurf = length(surf) 
    nlev = length(field.lev)

    for i = 1:nsurf
        if i in shed_ind
            if (surf[i].levflag[1] == 0)
                le_vel_x = surf[i].kinem.u - surf[i].kinem.alphadot*sin(surf[i].kinem.alpha)*surf[i].pvt*surf[i].c + surf[i].uind[1]
                le_vel_z = -surf[i].kinem.alphadot*cos(surf[i].kinem.alpha)*surf[i].pvt*surf[i].c- surf[i].kinem.hdot + surf[i].wind[1]
                xloc = surf[i].bnd_x[1] + 0.5*le_vel_x*dt
                zloc = surf[i].bnd_z[1] + 0.5*le_vel_z*dt
                push!(field.lev,TwoDVort(xloc,zloc,0.,0.02*surf[i].c,0.,0.))
            else
                xloc = surf[i].bnd_x[1]+(1. /3.)*(field.lev[nlev-nsurf+i].x - surf[i].bnd_x[1])
                zloc = surf[i].bnd_z[1]+(1. /3.)*(field.lev[nlev-nsurf+i].z - surf[i].bnd_z[1])
                push!(field.lev,TwoDVort(xloc,zloc,0.,0.02*surf[i].c,0.,0.))            
            end
        else
            push!(field.lev, TwoDVort(0., 0., 0., 0., 0., 0.))
        end
    end
    return field
end

# Function for updating the positions of the bound vortices
function update_boundpos(surf::TwoDSurf, dt::Float64)
    for i = 1:surf.ndiv
        surf.bnd_x[i] = surf.bnd_x[i] + dt*((surf.pvt*surf.c - surf.x[i])*sin(surf.kinem.alpha)*surf.kinem.alphadot - surf.kinem.u + surf.cam[i]*cos(surf.kinem.alpha)*surf.kinem.alphadot)
        surf.bnd_z[i] = surf.bnd_z[i] + dt*(surf.kinem.hdot + (surf.pvt*surf.c - surf.x[i])*cos(surf.kinem.alpha)*surf.kinem.alphadot - surf.cam[i]*sin(surf.kinem.alpha)*surf.kinem.alphadot)
    end
    return surf
end

# Function to calculate induced velocities by a set of vortices at a target location
function ind_vel(src::Vector{TwoDVort},t_x,t_z)
    #'s' stands for source and 't' for target
    uind = zeros(length(t_x))
    wind = zeros(length(t_x))

    for itr = 1:length(t_x)
        for isr = 1:length(src)
            xdist = src[isr].x - t_x[itr]
            zdist = src[isr].z - t_z[itr]
            distsq = xdist*xdist + zdist*zdist
            uind[itr] = uind[itr] - src[isr].s*zdist/(2*pi*sqrt(src[isr].vc*src[isr].vc*src[isr].vc*src[isr].vc + distsq*distsq))
            wind[itr] = wind[itr] + src[isr].s*xdist/(2*pi*sqrt(src[isr].vc*src[isr].vc*src[isr].vc*src[isr].vc + distsq*distsq))
        end
    end
    return uind, wind
end

function ind_vel(src::Vector{TwoDVVort},t_x,t_z)
    #'s' stands for source and 't' for target
    uind = zeros(length(t_x))
    wind = zeros(length(t_x))

    for itr = 1:length(t_x)
        for isr = 1:length(src)
            xdist = src[isr].x - t_x[itr]
            zdist = src[isr].z - t_z[itr]
            distsq = xdist*xdist + zdist*zdist
            uind[itr] = uind[itr] - src[isr].s*zdist/(2*pi*sqrt(src[isr].vc*src[isr].vc*src[isr].vc*src[isr].vc + distsq*distsq))
            wind[itr] = wind[itr] + src[isr].s*xdist/(2*pi*sqrt(src[isr].vc*src[isr].vc*src[isr].vc*src[isr].vc + distsq*distsq))
        end
    end
    return uind, wind
end


# Function determining the effects of interacting vortices - velocities induced on each other - classical n-body problem
function mutual_ind(vorts::Vector{TwoDVort})
    for i = 1:length(vorts)
        for j = i+1:length(vorts)
            dx = vorts[i].x - vorts[j].x
            dz = vorts[i].z - vorts[j].z
            #source- tar
            dsq = dx*dx + dz*dz

            magitr = 1. /(2*pi*sqrt(vorts[j].vc*vorts[j].vc*vorts[j].vc*vorts[j].vc + dsq*dsq))
            magjtr = 1. /(2*pi*sqrt(vorts[i].vc*vorts[i].vc*vorts[i].vc*vorts[i].vc + dsq*dsq))

            vorts[j].vx -= dz * vorts[i].s * magjtr
            vorts[j].vz += dx * vorts[i].s * magjtr

            vorts[i].vx += dz * vorts[j].s * magitr
            vorts[i].vz -= dx * vorts[j].s * magitr
        end
    end
    return vorts
end

# Uses Gaussian regularisiation
function mutual_ind_v_gaussian(vorts::Vector{<:TwoDVortAbstract}, nu::Real)

	@assert(nu >= 0, "Kinematic viscosity must be >= 0.")
	@assert(sum(map(v->typeof(v)==TwoDVVort ? abs(v.dvc) : 0, vorts))==0,
		"Not all of the viscous vortex particles started with zero rate"*
		" of change of vorticity.")
	@assert(all(map(v->v.vc>=0, vorts)), "Expected vortex cores to have 0 "*
		"or positive radius")
	@assert(all(isfinite.(map(v->v.x, vorts))), 
		"1 or more vortex particles had a bad x coord.")
	@assert(all(isfinite.(map(v->v.z, vorts))), 
		"1 or more vortex particles had a bad z coord.")
	@assert(all(isfinite.(map(v->v.s, vorts))), 
		"1 or more vortex particles had a bad vorticity.")
	@assert(all(isfinite.(map(v->v.vx, vorts))), 
		"1 or more vortex particles had a bad x velocity.")
	@assert(all(isfinite.(map(v->v.vz, vorts))), 
        "1 or more vortex particles had a bad z velocity.")
	
	n = length(vorts)
    w = zeros(n)	# Local vorticity density
    wx = zeros(n)	# x derivative of vorticity density
    wz = zeros(n)	# z derivative of vorticity density
    w_lap = zeros(n)# Laplacian of vorticity density.
    
    # Pairwise interactions
    for i = 1:n
        for j = i+1:n
            # source - tar: Equations are +ve for i, and j must be corrected for -dx & -dz.
            dx = vorts[i].x - vorts[j].x
            dz = vorts[i].z - vorts[j].z
            dsq = dx*dx + dz*dz

			# Fluid velocity (exc. diffusion velocity)
            magitr = (1 - exp(-dsq / vorts[j].vc^2)) /(2*pi*dsq)
            magjtr = (1 - exp(-dsq / vorts[i].vc^2)) /(2*pi*dsq)
            vorts[i].vx +=  dz * vorts[j].s * magitr
            vorts[i].vz -=  dx * vorts[j].s * magitr
            vorts[j].vx += -dz * vorts[i].s * magjtr
            vorts[j].vz -= -dx * vorts[i].s * magjtr
			# Vorticity
            w[i] += vorts[j].s * exp(-dsq/vorts[j].vc^2) / (pi * vorts[j].vc^2)
            w[j] += vorts[i].s * exp(-dsq/vorts[i].vc^2) / (pi * vorts[i].vc^2)
			# Vorticity derivatives
            wx[i] += -2 * vorts[j].s *  dx * exp(-dsq / vorts[j].vc^2) / (pi * vorts[j].vc^4)
            wz[i] += -2 * vorts[j].s *  dz * exp(-dsq / vorts[j].vc^2) / (pi * vorts[j].vc^4)
            wx[j] += -2 * vorts[i].s * -dx * exp(-dsq / vorts[i].vc^2) / (pi * vorts[i].vc^4)
            wz[j] += -2 * vorts[i].s * -dz * exp(-dsq / vorts[i].vc^2) / (pi * vorts[i].vc^4)
            # Vorticity Laplacians
            w_lap[i] += -4 * vorts[j].s * (vorts[j].vc^2 - dsq) * exp(-dsq / vorts[j].vc^2) / (pi * vorts[j].vc^6)  
            w_lap[j] += -4 * vorts[i].s * (vorts[i].vc^2 - dsq) * exp(-dsq / vorts[i].vc^2) / (pi * vorts[i].vc^6)  
            # We'd like to know about errors sooner rather than later.
            @assert(isfinite(w_lap[i]))
            @assert(isfinite(w_lap[j]))
            @assert(isfinite(w[i]))
            @assert(isfinite(w[j]))
        end
    end

	# Self effect
    for i = 1:n
        if typeof(vorts[i]) == TwoDVVort
            w[i]        += wself        = vorts[i].s / (pi * vorts[i].vc^2)
            # First derivative influences are 0
            w_lap[i]    += wself_lap    = -4 * vorts[i].s / (pi * vorts[i].vc^4)
            @assert(vorts[i].s == 0 ? true : wself_lap / wself < 0, 
                "Self incluence should have correct"*
                " sign such that core expands if isolated. "*
                string(-vorts[i].vc^2 * wself_lap/wself)*" should be about 4.")
        end
	end
	
    for i = 1:n
        if typeof(vorts[i]) == TwoDVVort
            # Diffusion velocity 
            vorts[i].vx += -nu*wx[i]/w[i]
            vorts[i].vz += -nu*wz[i]/w[i]
			# Rate of core expansion
            vorts[i].dvc = vorts[i].vc^2 * nu * ((wx[i]^2 + wz[i]^2)/w[i]^2 - w_lap[i]/w[i])   
            @assert(isfinite(vorts[i].dvc), "NaN or Inf vortex core radius derivative.")
            @assert(vorts[i].dvc >= 0, "Vortex cores should not shrink!\n"*
                "Vortex particle "*string(i)*" of "*string(n)*"\n"*
                "( wx[i]^2 + wz[i]^2 ) / w[i]^2 \t= "*string((wx[i]^2 + wz[i]^2)/w[i]^2)*  
                "\n-w_lap[i] / w[i] \t\t= "*string(-w_lap[i]/w[i])*"\nCore radius = "*
                string(vorts[i].vc)*".")
        end
    end
    return vorts
end

function regularised_functions

end

# function mutual_ind(vorts::Vector{TwoDVVort}, nu::Float64)

#     for i = 1:length(vorts)
#         for j = i+1:length(vorts)
#             dx = vorts[i].x - vorts[j].x
#             dz = vorts[i].z - vorts[j].z
#             #source- tar
#             dsq = dx*dx + dz*dz

#             magitr = 1. /(2*pi*sqrt(vorts[j].vc*vorts[j].vc*vorts[j].vc*vorts[j].vc + dsq*dsq))
#             magjtr = 1. /(2*pi*sqrt(vorts[i].vc*vorts[i].vc*vorts[i].vc*vorts[i].vc + dsq*dsq))

#             #Convectiom
#             vorts[j].vx -= dz * vorts[i].s * magjtr
#             vorts[j].vz += dx * vorts[i].s * magjtr

#             vorts[i].vx += dz * vorts[j].s * magitr
#             vorts[i].vz -= dx * vorts[j].s * magitr

#             #Diffusion velocity
#             wi = vorts[i].s*vorts[i].vc^4/(pi*(dsq^2 + vorts.vc[i]^4)^(3/2))
#             wj = vorts[j].s*vorts[j].vc^4/(pi*(dsq^2 + vorts.vc[j]^4)^(3/2))

#             magitr = 6. *nu*dsq*vorts[j].vc^4*vorts[j].s/(pi*wj*(dsq^2 + vorts[j].vc^4)^(5/2))
#             magjtr = 6. *nu*dsq*vorts[i].vc^4*vorts[i].s/(pi*wi*(dsq^2 + vorts[i].vc^4)^(5/2))

#             vorts[i].vx -= dx * magitr
#             vorts[i].vz -= dz * magitr

#             vorts[j].vx += dx * magjtr
#             vorts[j].vz += dz * magjtr

#             #Diffusion vortex core expansion
#             vorts[i].dvc += 6*nu*vorts[i].vc^2*dsq*(3*vorts[j].vc^4 - dsq^2)/(vorts[j].vc^4 + dsq^2)^2
#             vorts[j].dvc += 6*nu*vorts[j].vc^2*dsq*(3*vorts[i].vc^4 - dsq^2)/(vorts[i].vc^4 + dsq^2)^2
#         end
#     end
#     return vorts
# end

"""
    controlVortCount(delvort, surf, curfield)

Performs merging or deletion operation on free vortices in order to
control computational cost according to algorithm specified.

Algorithms for parameter delvort

 - delNone

    Does nothing, no vortex count control.

 - delSpalart(limit=500, dist=10, tol=1e-6)

    Merges vortices according to algorithm given in Spalart,
    P. R. (1988). Vortex methods for separated flows.

     - limit: min number of vortices present for merging to occur

     - dist: small values encourage mergin near airfoil, large values in
         wake (see paper)

     - tol: tolerance for merging, merging is less likely to occur for low
        values (see paper)

There is no universal set of parameters that work for all problem. If
using vortex control, test and calibrate choice of parameters

"""
function controlVortCount(delvort :: delVortDef, surf_locx :: Float64, surf_locz :: Float64, curfield :: TwoDFlowField)

    if typeof(delvort) == delNone

    elseif typeof(delvort) == delSpalart
        D0 = delvort.dist
        V0 = delvort.tol
        if length(curfield.tev) > delvort.limit
            #Check possibility of merging the last vortex with the closest 20 vortices
            gamma_j = curfield.tev[1].s
            d_j = sqrt((curfield.tev[1].x- surf_locx)^2 + (curfield.tev[1].z - surf_locz)^2)
            z_j = sqrt(curfield.tev[1].x^2 + curfield.tev[1].z^2)


            for i = 2:20
                gamma_k = curfield.tev[i].s
                d_k = sqrt((curfield.tev[i].x - surf_locx)^2 + (curfield.tev[i].z - surf_locz)^2)
                z_k = sqrt(curfield.tev[i].x^2 + curfield.tev[i].z^2)

                fact = abs(gamma_j*gamma_k)*abs(z_j - z_k)/(abs(gamma_j + gamma_k)*(D0 + d_j)^1.5*(D0 + d_k)^1.5)

                if fact < V0
                    #Merge the 2 vortices into the one at k
                    curfield.tev[i].x = (abs(gamma_j)*curfield.tev[1].x + abs(gamma_k)*curfield.tev[i].x)/(abs(gamma_j + gamma_k))
                    curfield.tev[i].z = (abs(gamma_j)*curfield.tev[1].z + abs(gamma_k)*curfield.tev[i].z)/(abs(gamma_j + gamma_k))
                    curfield.tev[i].s += curfield.tev[1].s

                    popfirst!(curfield.tev)

                    break
                end
            end

            if length(curfield.lev) > delvort.limit
                #Check possibility of merging the last vortex with the closest 20 vortices

                gamma_j = curfield.lev[1].s
                d_j = sqrt((curfield.lev[1].x - surf_locx)^2 + (curfield.lev[1].z - surf_locz)^2)
                z_j = sqrt(curfield.lev[1].x^2 + curfield.lev[1].z^2)

                for i = 2:20
                    gamma_k = curfield.lev[i].s
                    d_k = sqrt((curfield.lev[i].x - surf_locx)^2 + (curfield.lev[i].z - surf_locz)^2)
                    z_k = sqrt(curfield.lev[i].x^2 + curfield.lev[i].z^2)

                    fact = abs(gamma_j*gamma_k)*abs(z_j - z_k)/(abs(gamma_j + gamma_k)*(D0 + d_j)^1.5*(D0 + d_k)^1.5)

                    if fact < V0
                        #Merge the 2 vortices into the one at k
                        curfield.lev[i].x = (abs(gamma_j)*curfield.lev[1].x + abs(gamma_k)*curfield.lev[i].x)/(abs(gamma_j + gamma_k))
                        curfield.lev[i].z = (abs(gamma_j)*curfield.lev[1].z + abs(gamma_k)*curfield.lev[i].z)/(abs(gamma_j + gamma_k))
                        curfield.lev[i].s += curfield.lev[1].s

                        popfirst!(curfield.lev)

                        break
                    end
                end
            end
        end
    end
end

function controlVortCount(delvort :: delVortDef, surf_locx :: Float64, surf_locz :: Float64, curfield :: TwoDVFlowField)

    if typeof(delvort) == delNone

    elseif typeof(delvort) == delSpalart
        D0 = delvort.dist
        V0 = delvort.tol
        if length(curfield.tev) > delvort.limit
            #Check possibility of merging the last vortex with the closest 20 vortices
            gamma_j = curfield.tev[1].s
            d_j = sqrt((curfield.tev[1].x- surf_locx)^2 + (curfield.tev[1].z - surf_locz)^2)
            z_j = sqrt(curfield.tev[1].x^2 + curfield.tev[1].z^2)


            for i = 2:20
                gamma_k = curfield.tev[i].s
                d_k = sqrt((curfield.tev[i].x - surf_locx)^2 + (curfield.tev[i].z - surf_locz)^2)
                z_k = sqrt(curfield.tev[i].x^2 + curfield.tev[i].z^2)

                fact = abs(gamma_j*gamma_k)*abs(z_j - z_k)/(abs(gamma_j + gamma_k)*(D0 + d_j)^1.5*(D0 + d_k)^1.5)

                if fact < V0
                    #Merge the 2 vortices into the one at k
                    curfield.tev[i].x = (abs(gamma_j)*curfield.tev[1].x + abs(gamma_k)*curfield.tev[i].x)/(abs(gamma_j + gamma_k))
                    curfield.tev[i].z = (abs(gamma_j)*curfield.tev[1].z + abs(gamma_k)*curfield.tev[i].z)/(abs(gamma_j + gamma_k))
                    curfield.tev[i].s += curfield.tev[1].s

                    popfirst!(curfield.tev)

                    break
                end
            end

            if length(curfield.lev) > delvort.limit
                #Check possibility of merging the last vortex with the closest 20 vortices

                gamma_j = curfield.lev[1].s
                d_j = sqrt((curfield.lev[1].x - surf_locx)^2 + (curfield.lev[1].z - surf_locz)^2)
                z_j = sqrt(curfield.lev[1].x^2 + curfield.lev[1].z^2)

                for i = 2:20
                    gamma_k = curfield.lev[i].s
                    d_k = sqrt((curfield.lev[i].x - surf_locx)^2 + (curfield.lev[i].z - surf_locz)^2)
                    z_k = sqrt(curfield.lev[i].x^2 + curfield.lev[i].z^2)

                    fact = abs(gamma_j*gamma_k)*abs(z_j - z_k)/(abs(gamma_j + gamma_k)*(D0 + d_j)^1.5*(D0 + d_k)^1.5)

                    if fact < V0
                        #Merge the 2 vortices into the one at k
                        curfield.lev[i].x = (abs(gamma_j)*curfield.lev[1].x + abs(gamma_k)*curfield.lev[i].x)/(abs(gamma_j + gamma_k))
                        curfield.lev[i].z = (abs(gamma_j)*curfield.lev[1].z + abs(gamma_k)*curfield.lev[i].z)/(abs(gamma_j + gamma_k))
                        curfield.lev[i].s += curfield.lev[1].s

                        popfirst!(curfield.lev)

                        break
                    end
                end
            end
        end
    end
end


function update_kinem2DOF(surf::TwoDSurf, strpar :: TwoDOFPar, kinem :: KinemPar2DOF, dt, cl, cm)
    #Update previous terms
    kinem.alpha_pr = kinem.alpha
    kinem.h_pr = kinem.h

    kinem.alphadot_pr3 = kinem.alphadot_pr2
    kinem.alphadot_pr2 = kinem.alphadot_pr
    kinem.alphadot_pr = kinem.alphadot

    kinem.hdot_pr3 = kinem.hdot_pr2
    kinem.hdot_pr2 = kinem.hdot_pr
    kinem.hdot_pr = kinem.hdot

    kinem.alphaddot_pr3 = kinem.alphaddot_pr2
    kinem.alphaddot_pr2 = kinem.alphaddot_pr

    kinem.hddot_pr3 = kinem.hddot_pr2
    kinem.hddot_pr2 = kinem.hddot_pr

    #Calculate hddot and alphaddot from forces based on 2DOF structural system
    m11 = 2. /surf.c
    m12 = -strpar.x_alpha*cos(kinem.alpha)
    m21 = -2. *strpar.x_alpha*cos(kinem.alpha)/surf.c
    m22 = strpar.r_alpha*strpar.r_alpha

    R1 = 4*strpar.kappa*surf.uref*surf.uref*cl/(pi*surf.c*surf.c) - 2*strpar.w_h*strpar.w_h*(strpar.cubic_h_1*kinem.h + strpar.cubic_h_3*kinem.h^3)/surf.c - strpar.x_alpha*sin(kinem.alpha)*kinem.alphadot*kinem.alphadot

    R2 = 8*strpar.kappa*surf.uref*surf.uref*cm/(pi*surf.c*surf.c) - strpar.w_alpha*strpar.w_alpha*strpar.r_alpha*strpar.r_alpha*(strpar.cubic_alpha_1*kinem.alpha + strpar.cubic_alpha_3*kinem.alpha^3)
    
    kinem.hddot_pr = (1/(m11*m22-m21*m12))*(m22*R1-m12*R2)
    kinem.alphaddot_pr = (1/(m11*m22-m21*m12))*(-m21*R1+m11*R2)

    #Kinematics are updated according to the 2DOF response
    kinem.alphadot = kinem.alphadot_pr + (dt/12.)*(23*kinem.alphaddot_pr - 16*kinem.alphaddot_pr2 + 5*kinem.alphaddot_pr3)
    kinem.hdot = kinem.hdot_pr + (dt/12)*(23*kinem.hddot_pr-16*kinem.hddot_pr2 + 5*kinem.hddot_pr3)
    
    kinem.alpha = kinem.alpha_pr + (dt/12)*(23*kinem.alphadot_pr-16*kinem.alphadot_pr2 + 5*kinem.alphadot_pr3)
    kinem.h = kinem.h_pr + (dt/12)*(23*kinem.hdot_pr - 16*kinem.hdot_pr2 + 5*kinem.hdot_pr3)

    #Copy over these values to the TwoDSurf
    surf.kinem.alphadot = kinem.alphadot
    surf.kinem.hdot = kinem.hdot
    surf.kinem.alpha = kinem.alpha
    surf.kinem.h = kinem.h
    
    return surf, kinem
end

function vortex_type(field::TwoDFlowFieldAbstract)
    if typeof(field)==TwoDFlowField
        VortType = TwoDVort
    elseif  typeof(field)==TwoDVFlowField
        VortType = TwoDVVort
    else
        @error("Vortex field type not recognised / implemented. Field"*
            " type was "*string(typeof(field)))
    end
    return VortType
end
    
