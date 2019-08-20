using UnsteadyFlowSolvers

#alphadef = SinDef(deg2rad(3), deg2rad(10), 1, 0)
alphadef = ConstDef(deg2rad(1))
hdef = ConstDef(0.)
udef = ConstDef(1.)
full_kinem = KinemDef(alphadef, hdef, udef)

pvt = 0.25
geometry = "FlatPlate"
surf = TwoDSurf(geometry, pvt, full_kinem, rho = 0.02)

Re = 10000
nu = udef.amp  * surf.c / Re
curfield = TwoDVFlowField(nu)
#curfield = TwoDFlowField()
dtstar = find_tstep(alphadef)
t_tot = 3 * dtstar
nsteps = Int(round(t_tot/dtstar))+1
startflag = 0
writeflag = 1
writeInterval = t_tot/10.
delvort = delNone()

mat, surf, curfield = lautat(surf, curfield, nsteps, dtstar,startflag, writeflag, writeInterval, delvort, wakerollup=1)

#makeForcePlots2D()
makeVortPlots2D()

return
