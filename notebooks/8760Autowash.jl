### A Pluto.jl notebook ###
# v0.14.5

using Markdown
using InteractiveUtils

# This Pluto notebook uses @bind for interactivity. When running this notebook outside of Pluto, the following 'mock version' of @bind gives bound variables a default value (instead of an error).
macro bind(def, element)
    quote
        local el = $(esc(element))
        global $(esc(def)) = Core.applicable(Base.get, el) ? Base.get(el) : missing
        el
    end
end

# ╔═╡ 04296da0-b815-11eb-2c22-f185f61022a1
begin
	import Pkg
	Pkg.activate("8760Autowash")
	
	using CSV
	using Flux
	using BSON
	using Plots
	using PlutoUI
	using DataFramesMeta
	
	import DarkMode
	
	plotly()
	
	md"""
	# 🧼 8760 Autowash 🧽
	"""
end

# ╔═╡ e2d17e73-c395-4bca-979d-12a2eeff4532
md"""
## Download TMY data: 

$(@bind TMY3 Select(["station1", "station2"]))
"""

# ╔═╡ d70c5cf0-a4cf-45c3-92ae-336305f6d750
begin
	#Pkg.add(["CSV", "DataFramesMeta", "Plots", "Flux", "PlutoUI"])
	#Pkg.add(url="https://github.com/Pocket-titan/DarkMode")
end

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

# ╔═╡ f341f296-113c-4a1b-9f17-bddc32217831
tempF = 63.14

# ╔═╡ 22abff5a-2707-41eb-bba6-b367aa9285ff
rel_humidity = 0.243

# ╔═╡ 4bdb11d9-beb4-493d-be92-b88cfd1a2869
wind_spd_MPH = 6.314

# ╔═╡ 2fba71e3-ad36-4053-a9de-fa8973eadf4c
# using lat, lng for Selfrige Air National Guard base

# ╔═╡ b0baead8-c023-43fd-a6a0-592032e16e40
lng = 42.611721716115355

# ╔═╡ c45f92bd-4fb9-4f32-b305-447d17430ce5
lat = 82.83188992618686

# ╔═╡ c0113dc6-1899-45de-8c94-dda4910530f6
year = 2019

# ╔═╡ eca90237-ae18-4998-b749-99cd2009bb23
month = 1

# ╔═╡ af72fc9a-4eec-439f-b82a-504409826310
day = 1

# ╔═╡ 2d156af7-67e1-42c2-81ed-7a8a58fd00ff
hour = 0

# ╔═╡ 11e6a398-c0df-4439-9061-0fcb92407b23
elev = 656

# ╔═╡ 38fd7dfe-27b4-4b39-84b5-9139ab820997
xvec = Float32[tempF,rel_humidity,wind_spd_MPH,lng,lat,elev,year,month,day,hour]

# ╔═╡ 6cace2fe-a434-4430-9ca0-d2592da74801
usage_value = 4.521

# ╔═╡ a58a98a0-5736-414e-9f9f-34b559341b00
yvec = [usage_value] # MW for that hour

# ╔═╡ 65b121b6-f67f-453a-a906-ee9c2ac5fb3f
x_length = xvec |> length

# ╔═╡ 171a5828-4405-4ac3-928e-ac8ea837a655
x = rand(Float32, 2)

# ╔═╡ e54b2e58-c990-4787-a1be-7475459f5062
m = Chain(LSTM(x_length, x_length*2), Dense(x_length*2, 1), x -> reshape(x, :))

# ╔═╡ 437aac89-6a02-4354-bbb3-428e0035f08b
m(xvec)

# ╔═╡ 840af0c5-1b67-471f-95af-7c11d411ea71
xs = [xvec, xvec]

# ╔═╡ 39106fdd-c691-46b4-a0df-d6d10d938014
ys = [ [4.51],[4.51] ]

# ╔═╡ db38b61c-0d85-485a-83d2-b0c23fcdea41
data = zip(xs, ys)

# ╔═╡ d64007c6-d9b5-4305-81db-c629ad01f3d5
loss(x, y) = Flux.Losses.mse(m(x), y)

# ╔═╡ fed7cbfb-163f-497c-868d-4380d0d30a54
opt = AdaBelief(0.001, (0.9, 0.8))

# ╔═╡ da23479f-ee1e-45b8-937b-3d9316b47c22
ps = Flux.params(m)

# ╔═╡ 8c4b160e-8a44-4dda-b9fb-9a4068ccbc55
cb = function ()
  accuracy() > 0.9 && Flux.stop()
end

# ╔═╡ c9f24c69-fa7e-4356-9314-0b57296e7d0f
evalcb() = @show(loss(test_x, test_y))

# ╔═╡ 59bd3838-894b-4ef1-8854-332b16aa0bdb
throttled_cb = Flux.throttle(evalcb, 5)

# ╔═╡ 536505e7-697e-47ea-858f-4531c0b8a0a7
Flux.@epochs 20 Flux.train!(loss, ps, data, opt, cb = throttled_cb)

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
# ╟─e2d17e73-c395-4bca-979d-12a2eeff4532
# ╠═d70c5cf0-a4cf-45c3-92ae-336305f6d750
# ╟─5e48440d-b68e-4577-88df-c37d03347f2f
# ╟─4f07c818-e24f-48c2-8b7d-8df3a5ccc608
# ╠═37acd673-da27-4cf6-a048-26e20f61ffb1
# ╠═71596dfe-1643-4305-8a3d-fa41c84c65fa
# ╠═0a552467-030c-45ab-b371-d436dd429c77
# ╠═f341f296-113c-4a1b-9f17-bddc32217831
# ╠═22abff5a-2707-41eb-bba6-b367aa9285ff
# ╠═4bdb11d9-beb4-493d-be92-b88cfd1a2869
# ╠═2fba71e3-ad36-4053-a9de-fa8973eadf4c
# ╠═b0baead8-c023-43fd-a6a0-592032e16e40
# ╠═c45f92bd-4fb9-4f32-b305-447d17430ce5
# ╠═c0113dc6-1899-45de-8c94-dda4910530f6
# ╠═eca90237-ae18-4998-b749-99cd2009bb23
# ╠═af72fc9a-4eec-439f-b82a-504409826310
# ╠═2d156af7-67e1-42c2-81ed-7a8a58fd00ff
# ╠═11e6a398-c0df-4439-9061-0fcb92407b23
# ╠═38fd7dfe-27b4-4b39-84b5-9139ab820997
# ╠═6cace2fe-a434-4430-9ca0-d2592da74801
# ╠═a58a98a0-5736-414e-9f9f-34b559341b00
# ╠═65b121b6-f67f-453a-a906-ee9c2ac5fb3f
# ╠═171a5828-4405-4ac3-928e-ac8ea837a655
# ╠═e54b2e58-c990-4787-a1be-7475459f5062
# ╠═437aac89-6a02-4354-bbb3-428e0035f08b
# ╠═840af0c5-1b67-471f-95af-7c11d411ea71
# ╠═39106fdd-c691-46b4-a0df-d6d10d938014
# ╠═db38b61c-0d85-485a-83d2-b0c23fcdea41
# ╠═d64007c6-d9b5-4305-81db-c629ad01f3d5
# ╠═fed7cbfb-163f-497c-868d-4380d0d30a54
# ╠═da23479f-ee1e-45b8-937b-3d9316b47c22
# ╠═8c4b160e-8a44-4dda-b9fb-9a4068ccbc55
# ╠═c9f24c69-fa7e-4356-9314-0b57296e7d0f
# ╠═59bd3838-894b-4ef1-8854-332b16aa0bdb
# ╠═536505e7-697e-47ea-858f-4531c0b8a0a7
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
