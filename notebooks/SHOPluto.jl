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

# ╔═╡ 868cd960-ba5b-11eb-2c92-255e7e10725e
begin
	import Pkg
	Pkg.activate("SHOPluto")
	
	try
		using HypertextLiteral
	catch
		Pkg.add(url="https://github.com/Pocket-titan/DarkMode#master")
		Pkg.add(["PlutoUI", "StatsPlots", "CSV", "Statistics", "Flux", "DataFramesMeta","HypertextLiteral"])
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
	# SHOP Napkin Calcs📜 
	
	Hi McGee! This is an experimental tool use with caution ⚠️ 
	"""
end

# ╔═╡ 60dd45e8-3c31-4575-8739-a8d664aa58f3
md"""
## Upload MCL data below 
Column header names will be normalized. Descriptions will be provided below.
- MCL (SoCalGas) data input: $(@bind SCG_csv FilePicker())
"""

# ╔═╡ 11c11ff9-5a14-4fe3-ab53-a65111060115
MCL_desc = if !isempty(SCG_csv["data"])
	MCL_df = CSV.File(UInt8.(SCG_csv["data"]) |> IOBuffer, normalizenames=true) |> DataFrame	
	describe(MCL_df, :all, sum=>:sum)
end

# ╔═╡ 8764c5aa-3472-4a7e-9212-9af62d3f902e
md"""
__To speed up processing, let's slim down this dataset. Select which MCL columns to keep:__
"""

# ╔═╡ d7598973-beb7-44b1-835b-3527fdc70668
MCL_keepcols = Symbol.([

"GNN_ID"
"CUST_ID"
"IC_FST_NM"
"IC_LST_NM"
"DA_NBR"
"SVC_ADDR1"
"SVC_ADDR2"
"SVC_CITY"
"SVC_STATE"
"SVC_ZIP"
"CUST_HOME_PHONE"
"CUST_CELL_PHONE"
"CUST_EMAIL_ADDR"
"CEC_ZONE"
"_202001"
"_202002"
"_202003"
"_202004"
"_202005"
"_202006"
"_202007"
"_202008"
"_202009"
"_202010"
"_202011"
"_202012"
"_202101"
"_202102"
"_2020_ANNUAL"
"_2020_BASELOAD_THMS"
"WINTER_2020_THMS"
])

# ╔═╡ 4e1fb60a-85dc-4831-9132-02d3eba6ea95
if @isdefined MCL_df
	select!(MCL_df, MCL_keepcols)
end

# ╔═╡ c00c8c6e-a1a3-4fdf-9dc5-bbd3bcc20aa2
md"""
## Customer Targeting
Selecting a subset of the data:
- Quantile Range: $(@bind low_q NumberField(0:100,default=50))% - $(@bind high_q NumberField(0:100,default=70))%
"""

# ╔═╡ 92877da7-6f6d-4ba0-ba18-4763214564b8
if @isdefined MCL_df
	heat_lowq, heat_highq = quantile(MCL_df[!,"WINTER_2020_THMS"], [low_q/100, high_q/100])
	base_lowq, base_highq = quantile(MCL_df[!,"_2020_BASELOAD_THMS"], [low_q/100, high_q/100])
		
	md"""
	Selecting projects with:
	- `WINTER_2020_THMS` between __$heat_lowq__ and __$heat_highq__ 
	and 
	- `_2020_BASELOAD_THMS` between __$base_lowq__ and __$base_highq__
	"""
end

# ╔═╡ ed0d5d8b-345e-49bf-bcba-e6f4b19b8896
MCL_targets_desc = if @isdefined MCL_df
	MCL_targets = @where(MCL_df, 
		:WINTER_2020_THMS .> heat_lowq,
		:WINTER_2020_THMS .< heat_highq,
		:_2020_BASELOAD_THMS .> base_lowq,
		:_2020_BASELOAD_THMS .< base_highq
	)
	describe(MCL_targets, :all, sum=>:sum)
end

# ╔═╡ a4cda47d-907b-4510-b68e-63b87d78ae02
if !isempty(SCG_csv["data"])
	md"""
	## Measure Savings Calculation
	Upload a measure savings table below to calculate savings on the uploaded MCL
	- Savings table: $(@bind savings_table_csv FilePicker())
	"""
end

# ╔═╡ aa5bffb1-f412-4d52-b132-379b0a014c4b
savings_table_df = if (@isdefined savings_table_csv) && (!isempty(savings_table_csv["data"]))
	CSV.File(UInt8.(savings_table_csv["data"]) |> IOBuffer, normalizenames=true) |> DataFrame
end

# ╔═╡ 5fc68bf5-4fd6-4aab-ac8d-8d5e163558df
md"""
__Joining `MCL_targets` and `savings_table_df` on `:CEC_ZONE` and generating `swh`, `wop`, and `tstat` columns__
"""

# ╔═╡ db159774-fe16-45ed-8f34-afbd68150f54
MCL_savings_desc = if (@isdefined MCL_targets) && !isempty(savings_table_csv["data"])
	MCL_savings = leftjoin(MCL_targets, @where(savings_table_df, :type .== "sh"), on=:CEC_ZONE)
	
	@transform!(MCL_savings,
		swh = :swh_ .* :_2020_BASELOAD_THMS .* 2,
		wop = :wop_ .* (:WINTER_2020_THMS .- :_2020_BASELOAD_THMS),
		tstat = :tstat_ .* :WINTER_2020_THMS .- :_2020_BASELOAD_THMS,
		)
	
	MCL_savings[!,:savings] = @with MCL_savings begin
		:swh .+ :wop .+ :tstat .+ :tcv .+ :spout
	end
	
	describe(MCL_savings, :all, sum=>:sum)
end

# ╔═╡ a71665f4-0951-44f7-969e-d933bed20f62
md"## Measure Savings Results"

# ╔═╡ ed36453a-fda8-45d5-93f8-7828be779317
if (@isdefined MCL_savings) && ("savings" in MCL_savings |> names)
	histogram(
		MCL_savings[!,"savings"], 
		title="Old Estimated Therms Savings Histogram",
		size=(750,400), 
	)
end

# ╔═╡ f44c29c7-c23b-40ee-8099-e65e1223d57c
# total savings
MCL_savings[!,:savings] |> sum

# ╔═╡ 0fad5851-fe23-4895-9194-dd1625c9abe5
md"""
__⚠️ Overriding estimated savings calculation with 7% for Smart Thermostats and 4% for Aquanta WH Controllers, and then discounted by 50%.__
 - smart thermostat savings $(@bind therm_pct NumberField(0:100,default=7)) %
 - Aquanta savings $(@bind aquanta_pct NumberField(0:100,default=4)) %
 - savings reduction $(@bind savings_reduction NumberField(0:100,default=50)) %
 - propensity score $(@bind propensity NumberField(0:100,default=1.5)) %
"""

# ╔═╡ 6c53ca70-b96f-4e0d-862f-45b335092556
if @isdefined MCL_savings
	MCL_savings[!,"Tstat Therms Saved"] .= MCL_savings[!,:WINTER_2020_THMS] * therm_pct/100 * savings_reduction/100
    MCL_savings[!,"WH Therms Saved"] .= MCL_savings[!,:_2020_BASELOAD_THMS] * aquanta_pct/100 * savings_reduction/100
	MCL_savings[!,"Combined Therms Savings"] = MCL_savings[!,"Tstat Therms Saved"] .+ MCL_savings[!,"WH Therms Saved"]
end

# ╔═╡ bc9a3e3a-1bf7-460d-b3b1-a30228e2e7fa
if (@isdefined MCL_savings) && ("Combined Therms Savings" in MCL_savings |> names)
	histogram(
		MCL_savings[!,"Combined Therms Savings"], 
		title="New Estimated Therms Savings Histogram",
		size=(750,400), 
	)
end

# ╔═╡ 029834b6-9d7f-4b0a-a941-07e305ad63e1
md"""
## Customer Grouping 
Collecting customers into AB, A, and B groupings
"""

# ╔═╡ 7397ca3a-7a1e-425a-ac09-8f30e49bd1ec
MCL_savings[!,"Group"] = [ 
    if MCL_savings[i,"Tstat Therms Saved"] > 20 && MCL_savings[i,"WH Therms Saved"] > 20
        "AB"
    elseif MCL_savings[i,"Tstat Therms Saved"] > 20
        "A"
    elseif MCL_savings[i,"WH Therms Saved"] > 20
        "B"
    else
        "C"
    end for i in 1:length(MCL_savings[!,:GNN_ID]) ]

# ╔═╡ d52bcf99-f303-4755-9f31-0238d504b3bc
g = groupby(MCL_savings, :Group)

# ╔═╡ 6c0b7453-8de9-4f40-939f-cc68c9e90484
combine(describe, groupby(MCL_savings, :Group), ungroup = false) |> (t -> show(t, allrows = true, allgroups = true))

# ╔═╡ d42fabef-dd60-4056-af92-c4daacf79177
# MCL Tier Counts (requires a Tiered and Grouped MCL)
Tier_Group_counts = if (@isdefined MCL_df) && ("Tier" in names(MCL_df)) && ("Group" in names(MCL_df))
	cts = Dict()
	
	# Tier I counts
	cts[:T1_tot_ct] = @where(MCL_df, :Tier .== "T1") |> eachrow |> length  # 313142
	cts[:T1_AB_ct] = @where(MCL_df, :Tier .== "T1", :Group .== "AB") |> eachrow |> length  # 88059
	cts[:T1_A_ct] = @where(MCL_df, :Tier .== "T1", :Group .== "A") |> eachrow |> length  # 88501
	cts[:T1_B_ct] = @where(MCL_df, :Tier .== "T1", :Group .== "B") |> eachrow |> length  # 136582
	
	@assert cts[:T1_tot_ct] == cts[:T1_AB_ct] + cts[:T1_A_ct] + cts[:T1_B_ct]
	
	# Tier II counts
	cts[:T2_tot_ct] = @where(MCL_df, :Tier .== "T2") |> eachrow |> length  # 88758
	cts[:T2_AB_ct] = @where(MCL_df, :Tier .== "T2", :Group .== "AB") |> eachrow |> length  # 19035
	cts[:T2_A_ct] = @where(MCL_df, :Tier .== "T2", :Group .== "A") |> eachrow |> length  # 424467
	cts[:T2_B_ct] = @where(MCL_df, :Tier .== "T2", :Group .== "B") |> eachrow |> length  # 27277
	
	@assert cts[:T2_tot_ct] == cts[:T2_AB_ct] + cts[:T2_A_ct] + cts[:T2_B_ct]
	
	cts |> DataFrame
end

# ╔═╡ 3d2b922c-33d2-46e9-9729-6087cd0d3bcb
md"# Data Export"

# ╔═╡ acadb603-af96-4ec9-8359-d207b893d0a8


# ╔═╡ 33e60c2d-3b1b-4ed8-9ec4-a0b574aff867
"""<br><br><br><br><br><br><br><br><br><br><br><br><br><br><br><br><br><br><br><br><br><br><br><br>""" |> HTML

# ╔═╡ bde8d1eb-9c04-47e9-aa2b-12a3c844e19c
md"""
# Notebook Settings
"""

# ╔═╡ e9f7cd20-149e-42c4-83cf-d9b74dd4cd08
DarkMode.Toolbox()

# ╔═╡ fcd2727a-1dfe-426b-9318-297ac7c98d2d
DarkMode.enable()

# ╔═╡ 00c24ce5-62f0-4503-8204-b97eba3c1aa7
PlutoUI.TableOfContents()

# ╔═╡ a0ac9f42-72b6-449f-891e-dedaadb19939
"""
<style>
  main {
	max-width: 950px;
	align-self: flex-start;
	margin-left: 50px;
  }
""" |> HTML

# ╔═╡ Cell order:
# ╟─868cd960-ba5b-11eb-2c92-255e7e10725e
# ╟─60dd45e8-3c31-4575-8739-a8d664aa58f3
# ╟─11c11ff9-5a14-4fe3-ab53-a65111060115
# ╟─8764c5aa-3472-4a7e-9212-9af62d3f902e
# ╟─d7598973-beb7-44b1-835b-3527fdc70668
# ╟─4e1fb60a-85dc-4831-9132-02d3eba6ea95
# ╟─c00c8c6e-a1a3-4fdf-9dc5-bbd3bcc20aa2
# ╟─92877da7-6f6d-4ba0-ba18-4763214564b8
# ╟─ed0d5d8b-345e-49bf-bcba-e6f4b19b8896
# ╟─a4cda47d-907b-4510-b68e-63b87d78ae02
# ╟─aa5bffb1-f412-4d52-b132-379b0a014c4b
# ╟─5fc68bf5-4fd6-4aab-ac8d-8d5e163558df
# ╟─db159774-fe16-45ed-8f34-afbd68150f54
# ╟─a71665f4-0951-44f7-969e-d933bed20f62
# ╟─ed36453a-fda8-45d5-93f8-7828be779317
# ╠═f44c29c7-c23b-40ee-8099-e65e1223d57c
# ╟─0fad5851-fe23-4895-9194-dd1625c9abe5
# ╟─6c53ca70-b96f-4e0d-862f-45b335092556
# ╟─bc9a3e3a-1bf7-460d-b3b1-a30228e2e7fa
# ╟─029834b6-9d7f-4b0a-a941-07e305ad63e1
# ╟─7397ca3a-7a1e-425a-ac09-8f30e49bd1ec
# ╠═d52bcf99-f303-4755-9f31-0238d504b3bc
# ╠═6c0b7453-8de9-4f40-939f-cc68c9e90484
# ╠═d42fabef-dd60-4056-af92-c4daacf79177
# ╟─3d2b922c-33d2-46e9-9729-6087cd0d3bcb
# ╠═acadb603-af96-4ec9-8359-d207b893d0a8
# ╟─33e60c2d-3b1b-4ed8-9ec4-a0b574aff867
# ╟─bde8d1eb-9c04-47e9-aa2b-12a3c844e19c
# ╠═e9f7cd20-149e-42c4-83cf-d9b74dd4cd08
# ╠═fcd2727a-1dfe-426b-9318-297ac7c98d2d
# ╠═00c24ce5-62f0-4503-8204-b97eba3c1aa7
# ╠═a0ac9f42-72b6-449f-891e-dedaadb19939
