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

# ╔═╡ e434d64e-ba9a-11eb-0615-6bc773a653c1
begin
	import Pkg
	Pkg.activate("SHOPluto")
	
	try
		using StatsPlots
	catch
		Pkg.add(url="https://github.com/Pocket-titan/DarkMode#master")
		Pkg.add(["PlutoUI", "StatsPlots", "CSV", "Statistics", "Flux", "DataFramesMeta"])
	end
	
	using DataFramesMeta
	using Statistics
	using StatsPlots
	using PlutoUI
	using Flux
	using CSV
	
	import DarkMode
	
	plotly()
	
	md"""
	# SHOP Napkin Calcs📜 :: ReCurve Data
	
	Hi McGee! This is an experimental tool use with caution ⚠️
	"""
end

# ╔═╡ fe531276-91a4-4046-b60a-7d227ab5dadf
md"""
## Load ReCurve ledger data

- SHOP ledger (ReCurve) data input: $(@bind ReCurve_csv FilePicker())
"""

# ╔═╡ 9c6785c9-8cea-40af-aa2f-4cfa9a41cad0
ReCurve_desc = if !isempty(ReCurve_csv["data"])
	ReCurve_df = UInt8.(ReCurve_csv["data"]) |> IOBuffer |> CSV.File |> DataFrame
	describe(ReCurve_df, :all, sum=>:sum)
end

# ╔═╡ a0df870e-0782-40bf-91f6-03b26283c240
plot(ReCurve_df)

# ╔═╡ ffaa09de-3d0e-4989-bf54-42d4bf7f1c3e
md"""
ReCurve columns: $(@bind ReCurve_cols MultiSelect(ReCurve_df |> names))
"""

# ╔═╡ 36969ee2-1837-48c3-ace0-1ca4e50fd509
sum(coalesce.(ReCurve_df[!,:reporting_total_metered_savings], 0))

# ╔═╡ fe044ee3-3433-4dac-ae0e-d269b7cb8681
DarkMode.Toolbox()

# ╔═╡ 47101f41-f525-4ac5-a8fb-62b0e6da925b
DarkMode.enable()

# ╔═╡ 9d0ac1a9-c472-4b24-aa77-df84b2465c7c
PlutoUI.TableOfContents()

# ╔═╡ 64cc0f2a-29f4-4c84-b573-ffb6809d012c


# ╔═╡ 4a2c1100-c662-40fd-a993-8979dac7b571
cumsum = zeros(225)

# ╔═╡ 91f449ac-8c6a-4ec9-8041-5bf13a6f0612
sum(coalesce.(ReCurve_df[!,:reporting_total_metered_savings], 0))

# ╔═╡ f19ae56c-b24a-48bc-a89f-bae0e41e4676
1:length(ReCurve_df[!,:reporting_total_metered_savings])

# ╔═╡ 22563e40-5e14-4ae3-90d4-40b0a72a21b2
program_cumsum = [ ReCurve_df[i,:reporting_total_metered_savings] + (i > 1 ? cumsum[i-1] : 0) for i in 1:225 ]

# ╔═╡ bf6acf2a-0d49-4cc9-aee5-c523da270d3e
program_cumsum |> plot

# ╔═╡ 5e01dbab-81f9-4ef1-b8be-893b3839e6b1
program_cumsum[end]

# ╔═╡ Cell order:
# ╠═e434d64e-ba9a-11eb-0615-6bc773a653c1
# ╠═fe531276-91a4-4046-b60a-7d227ab5dadf
# ╠═9c6785c9-8cea-40af-aa2f-4cfa9a41cad0
# ╠═a0df870e-0782-40bf-91f6-03b26283c240
# ╠═ffaa09de-3d0e-4989-bf54-42d4bf7f1c3e
# ╠═36969ee2-1837-48c3-ace0-1ca4e50fd509
# ╠═fe044ee3-3433-4dac-ae0e-d269b7cb8681
# ╠═47101f41-f525-4ac5-a8fb-62b0e6da925b
# ╠═9d0ac1a9-c472-4b24-aa77-df84b2465c7c
# ╠═64cc0f2a-29f4-4c84-b573-ffb6809d012c
# ╠═4a2c1100-c662-40fd-a993-8979dac7b571
# ╠═91f449ac-8c6a-4ec9-8041-5bf13a6f0612
# ╠═f19ae56c-b24a-48bc-a89f-bae0e41e4676
# ╠═22563e40-5e14-4ae3-90d4-40b0a72a21b2
# ╠═bf6acf2a-0d49-4cc9-aee5-c523da270d3e
# ╠═5e01dbab-81f9-4ef1-b8be-893b3839e6b1
