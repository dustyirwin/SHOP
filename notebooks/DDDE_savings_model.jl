### A Pluto.jl notebook ###
# v0.14.5

using Markdown
using InteractiveUtils

# ╔═╡ e8ba56fb-0444-404c-aa72-c97ce55ace1f
import Pkg

# ╔═╡ 6d7ab689-a21b-4589-9330-0b915c063ac5
begin
	using Flux
	
	
end

# ╔═╡ 7d012b27-dddf-4c21-850c-f3d9326e4549


# ╔═╡ b2ecfa5b-030d-4a15-864a-391089c261bd


# ╔═╡ d013495a-81dc-476c-b8e6-b53b4e247b6a
md"""
### Example 1
"""

# ╔═╡ e0f35fbd-8bde-4b18-bc85-ebadb93b374d
function linear!(du, u, p, t)
  du[1] = u[2]
  du[2] = -u[1] - 0.1*u[2]
end

# ╔═╡ e0a94e3d-f7d5-4bf5-9d3b-9c17a4003db6
md"""
### Example 2: Generate some data by solving a differential equation
"""

# ╔═╡ f5a14162-41ef-4beb-9352-3d5995ee4288
# Create a test problem
function lorenz(u,p,t)
	x, y, z = u
	ẋ = 10.0*(y - x)
	ẏ = x*(28.0-z) - y
	ż = x*y - (8/3)*z
	return [ẋ, ẏ, ż]
end

# ╔═╡ 2bac05a0-b751-11eb-137d-335fd0a4ddc3
begin
	u0 = [-8.0; 7.0; 27.0]
	p = [10.0; -10.0; 28.0; -1.0; -1.0; 1.0; -8/3]
	tspan = (0.0,100.0)
	dt = 0.001
	problem = ODEProblem(lorenz,u0,tspan)
	solution = solve(problem, Tsit5(), saveat = dt, atol = 1e-7, rtol = 1e-8)

	X = Array(solution)
	DX = similar(X)
	for (i, xi) in enumerate(eachcol(X))
		DX[:,i] = lorenz(xi, [], 0.0)
	end
end

# ╔═╡ eeb18ed4-c832-49c6-a8fa-fa92112b7c4f
begin
	u01 = Float64[0.99π; -0.3]
	tspan1 = (0.0, 40.0)

	problem1 = ODEProblem(linear!, u0, tspan)
	solution1 = solve(problem1, Tsit5(), saveat = 1.0)

	plot(solution1)
end

# ╔═╡ 5a5e4c68-05fe-46c8-b15e-88991d09177c
md"""
#### Now automatically discover the system that generated the data
"""

# ╔═╡ 4b649624-5318-4123-a312-aaf937659243
begin
	@variables x y z
	
	u = [x; y; z]
	polys = Any[]
	
	for i ∈ 0:4
		for j ∈ 0:i
			for k ∈ 0:j
				push!(polys, u[1]^i*u[2]^j*u[3]^k)
				push!(polys, u[2]^i*u[3]^j*u[1]^k)
				push!(polys, u[3]^i*u[1]^j*u[2]^k)
			end
		end
	end

	basis = Basis(polys, u)
	opt = STRRidge(0.1)
	Ψ = SINDy(X, DX, basis, opt, maxiter = 100, normalize = true)
end

# ╔═╡ b8b46904-c75e-43de-9950-6d39b01b35e3
with_terminal() do
	print_equations(Ψ)
end

# ╔═╡ f34efd04-ad47-4b65-a655-ab0c9d936030
error = if @isdefined Ψ
	get_error(Ψ)
end

# ╔═╡ 5d646491-ec92-48f6-87ac-8c94c81ca9ac
DarkMode.ToolBox()

# ╔═╡ de6e8673-b1a1-4e8f-9827-0f991e032a4a
DarkMode.enable()

# ╔═╡ Cell order:
# ╠═e8ba56fb-0444-404c-aa72-c97ce55ace1f
# ╠═6d7ab689-a21b-4589-9330-0b915c063ac5
# ╠═7d012b27-dddf-4c21-850c-f3d9326e4549
# ╠═b2ecfa5b-030d-4a15-864a-391089c261bd
# ╟─d013495a-81dc-476c-b8e6-b53b4e247b6a
# ╠═e0f35fbd-8bde-4b18-bc85-ebadb93b374d
# ╠═eeb18ed4-c832-49c6-a8fa-fa92112b7c4f
# ╟─e0a94e3d-f7d5-4bf5-9d3b-9c17a4003db6
# ╠═f5a14162-41ef-4beb-9352-3d5995ee4288
# ╠═2bac05a0-b751-11eb-137d-335fd0a4ddc3
# ╟─5a5e4c68-05fe-46c8-b15e-88991d09177c
# ╠═4b649624-5318-4123-a312-aaf937659243
# ╟─b8b46904-c75e-43de-9950-6d39b01b35e3
# ╟─f34efd04-ad47-4b65-a655-ab0c9d936030
# ╠═5d646491-ec92-48f6-87ac-8c94c81ca9ac
# ╠═de6e8673-b1a1-4e8f-9827-0f991e032a4a
