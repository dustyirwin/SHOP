### A Pluto.jl notebook ###
# v0.14.5

using Markdown
using InteractiveUtils

# ╔═╡ d70c5cf0-a4cf-45c3-92ae-336305f6d750
begin
	import Pkg
	Pkg.activate("8760Autowash")
	
	#Pkg.add(["Transformers", "CUDA", "AMDGPU", "CSV", "DataFramesMeta", "Plots", "Reexport", "Flux"])
	#Pkg.add(url="https://github.com/Pocket-titan/DarkMode")
end

# ╔═╡ 10d74a06-04d7-4b50-98a6-2ad301106f87
begin
	using CSV
	using Flux
	using CUDA
	using Plots
	using AMDGPU
	using Transformers
	using DataFramesMeta
	
	import DarkMode
	
	#plotly()  # nicer
	gr()  # less memory
end

# ╔═╡ 04296da0-b815-11eb-2c22-f185f61022a1
md"""
# 🧼 8760 Autowash 🧽
"""

# ╔═╡ dfa18b45-747c-432f-9563-4d1118401721
Pkg.build("AMDGPU")

# ╔═╡ 5ae5edc6-8e37-49f7-abce-1262f4169169
enable_gpu(true)

# ╔═╡ 5e48440d-b68e-4577-88df-c37d03347f2f
input_dir = "C:/Users/33648/OneDrive - ICF/Documents/Projects/nwa-dte/data/input"

# ╔═╡ 4f07c818-e24f-48c2-8b7d-8df3a5ccc608
SCADA_df = CSV.File("$input_dir/OMEGA_SCADA_2018-2021.csv") |> DataFrame

# ╔═╡ 37acd673-da27-4cf6-a048-26e20f61ffb1
plot(select(SCADA_df, :MW) |> Matrix, labels=permutedims(SCADA_df |> names))

# ╔═╡ 71596dfe-1643-4305-8a3d-fa41c84c65fa
# restricting y range to 0:15
SCADA_df[!,:MW] = [ val > 15 ? 15 : val for val in SCADA_df[!,:MW] ] 

# ╔═╡ 0a552467-030c-45ab-b371-d436dd429c77
plot(select(SCADA_df, :MW) |> Matrix, labels=permutedims(SCADA_df |> names))

# ╔═╡ a03bd487-54d1-4148-9f92-27d788a19b48


# ╔═╡ 748c0e8d-fed0-4371-b901-9aa743147a4e


# ╔═╡ e93f161a-b735-4349-8162-70ccddc3c7fb
DarkMode.Toolbox()

# ╔═╡ 628cf529-0993-4931-b2eb-c721917a3a46
DarkMode.enable()

# ╔═╡ 0a382c57-786e-4b16-9cc0-481b8d642887
#m = Chain(
#	Dense(8760, 8760*2),
#	Dense(8760*2, 8760, swish)
#	)	

# ╔═╡ d0c35a30-87b5-48bf-adc3-1e27df6b5929
#opt = Flux.Optimise.ADAGrad()

# ╔═╡ 7259e244-6462-48c6-8885-b7d8d74ecae0
#evalcb() = @show(loss(test_x, test_y))

# ╔═╡ b86c16c6-2e2d-41e2-aeb6-3fc8c00ed337
#ps = Flux.params(m)

# ╔═╡ 8af724b6-d643-41e5-a7d4-7d03ea59e1a5
#loss(x, y) = Flux.Losses.mse(m(x), y)

# ╔═╡ a70d57b9-8170-4f72-9399-ec624cd1aeab
#Flux.train!(loss, ps, data, opt; cb=throttled_cb)

# ╔═╡ 5ab7069e-1f60-4265-bfef-18c226126a32
#throttled_cb = Flux.throttle(evalcb, 5)

# ╔═╡ 7fb7138c-e631-43e4-8a1a-f928a19bd836


# ╔═╡ Cell order:
# ╟─04296da0-b815-11eb-2c22-f185f61022a1
# ╠═d70c5cf0-a4cf-45c3-92ae-336305f6d750
# ╟─10d74a06-04d7-4b50-98a6-2ad301106f87
# ╠═dfa18b45-747c-432f-9563-4d1118401721
# ╠═5ae5edc6-8e37-49f7-abce-1262f4169169
# ╟─5e48440d-b68e-4577-88df-c37d03347f2f
# ╠═4f07c818-e24f-48c2-8b7d-8df3a5ccc608
# ╠═37acd673-da27-4cf6-a048-26e20f61ffb1
# ╠═71596dfe-1643-4305-8a3d-fa41c84c65fa
# ╠═0a552467-030c-45ab-b371-d436dd429c77
# ╠═a03bd487-54d1-4148-9f92-27d788a19b48
# ╠═748c0e8d-fed0-4371-b901-9aa743147a4e
# ╠═e93f161a-b735-4349-8162-70ccddc3c7fb
# ╠═628cf529-0993-4931-b2eb-c721917a3a46
# ╠═0a382c57-786e-4b16-9cc0-481b8d642887
# ╠═d0c35a30-87b5-48bf-adc3-1e27df6b5929
# ╠═7259e244-6462-48c6-8885-b7d8d74ecae0
# ╠═b86c16c6-2e2d-41e2-aeb6-3fc8c00ed337
# ╠═8af724b6-d643-41e5-a7d4-7d03ea59e1a5
# ╠═a70d57b9-8170-4f72-9399-ec624cd1aeab
# ╠═5ab7069e-1f60-4265-bfef-18c226126a32
# ╠═7fb7138c-e631-43e4-8a1a-f928a19bd836
