"""
Function to pre-allocate arrays contening the result.
"""
function allocate_arrays(ti	,xc0, xd0, n_max; rejection = false, ind_save_c=-1:1, ind_save_d=-1:1)
	if ind_save_c[1] == -1
		ind_save_c = 1:length(xc0)
	end

	if ind_save_d[1] == -1
		ind_save_d = 1:length(xd0)
	end

	if rejection
		X0  = copy(xc0)
		Xc  = copy(xc0)
	else
		# for the CVH method, needs to enlarge the state space
		X0 = copy(xc0); push!(X0,ti)
		Xc = copy(xc0)
	end
	Xd	 = copy(xd0)

	# arrays for storing history, pre-allocate storage
	t_hist  = zeros(n_max)
	xc_hist = zeros(eltype(xc0), length(ind_save_c), n_max)
	xd_hist = zeros(eltype(xd0), length(ind_save_d), n_max)
	res_ode = zeros(2, length(X0))


	# initialise arrays
	t_hist[1] = ti
	xc_hist[:,1] .= xc0[ind_save_c]
	xd_hist[:,1] .= Xd[ind_save_d]
	return X0, Xc, Xd, t_hist, xc_hist, xd_hist, res_ode, ind_save_d, ind_save_c
end


"""
Function copied from Gillespie.jl and StatsBase

This function is a substitute for `StatsBase.sample(wv::WeightVec)`, which avoids recomputing the sum and size of the weight vector, as well as a type conversion of the propensity vector. It takes the following arguments:
- **w** : an `Array{Float64,1}`, representing propensity function weights.
- **s** : the sum of `w`.
- **n** : the length of `w`.
"""
function pfsample(w::vec, s::Tc, n::Int64) where {Tc, vec <: AbstractVector{Tc}}
	t = rand() * s
	i = 1
	cw = w[1]
	while cw < t && i < n
		i += 1
		@inbounds cw += w[i]
	end
	return i
end

"""
This type stores the output composed of:
- **time** : a `Vector` of `Float64`, containing the times of simulated events.
- **xc** : containing the simulated states for the continuous variable.
- **xd** : containing the simulated states for the continuous variable.
- **rates** : containing the rates used during the simulation
"""
struct PDMPResult{Tc <: Real, vectype_xc, vectype_xd}
	time::Vector{Tc}
	xc::vectype_xc
	xd::vectype_xd
	rates::Vector{Tc}
	save_positions::Tuple{Bool, Bool}
	njumps::Int64
	nrejected::Int64
end

PDMPResult(time, xchist, xdhist)  = PDMPResult(time, xchist, xdhist, eltype(xchist)[], (false,false), length(time), 0)
PDMPResult(time, xchist, xdhist, rates, sp)  = PDMPResult(time, xchist, xdhist, rates, sp, length(time), 0)
