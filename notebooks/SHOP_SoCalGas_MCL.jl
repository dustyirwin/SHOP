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

])

# ╔═╡ 4e1fb60a-85dc-4831-9132-02d3eba6ea95
if @isdefined MCL_df
	select!(MCL_df, MCL_keepcols)
end

# ╔═╡ cf876449-ae50-4583-8152-79c8239054e1
if @isdefined MCL_df
	MCL_df[!,:_2020_Heating_Therms] .= MCL_df[!,"_2020_ANNUAL"] .- 12 .* mean([ MCL_df[!,"_202006"], MCL_df[!,"_202007"], MCL_df[!,"_202008"], MCL_df[!,"_202009"] ])
	MCL_df[!,:_2020_Baseload_Therms] .= MCL_df[!,"_2020_ANNUAL"] .- MCL_df[!,:_2020_Heating_Therms]
	
	select(MCL_df, :_2020_Heating_Therms, :_2020_Baseload_Therms)
end

# ╔═╡ c00c8c6e-a1a3-4fdf-9dc5-bbd3bcc20aa2
md"""
## Customer Targeting
Selecting a subset of the data:
- Quantile Range: $(@bind low_q NumberField(0:100,default=50))% - $(@bind high_q NumberField(0:100,default=70))%
"""

# ╔═╡ 92877da7-6f6d-4ba0-ba18-4763214564b8
if @isdefined MCL_df
	heat_lowq, heat_highq = quantile(MCL_df[!,"_2020_Heating_Therms"], [low_q/100, high_q/100])
	base_lowq, base_highq = quantile(MCL_df[!,"_2020_Baseload_Therms"], [low_q/100, high_q/100])
		
	md"""
	Selecting projects with:
	- `_2020_Heating_Therms` between __$heat_lowq__ and __$heat_highq__ 
	and 
	- `_2020_Baseload_Therms` between __$base_lowq__ and __$base_highq__
	"""
end

# ╔═╡ ed0d5d8b-345e-49bf-bcba-e6f4b19b8896
MCL_targets_desc = if @isdefined MCL_df
	MCL_targets = @where(MCL_df, 
		:_2020_Heating_Therms .> heat_lowq,
		:_2020_Heating_Therms .< heat_highq,
		:_2020_Baseload_Therms .> base_lowq,
		:_2020_Baseload_Therms .< base_highq
	)
	describe(MCL_targets, :all, sum=>:sum)
end

# ╔═╡ a4cda47d-907b-4510-b68e-63b87d78ae02
if !isempty(SCG_csv["data"])
	md"""
	## Measure savings estimation
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
Joining `MCL_targets` and `savings_table_df` into `MCL_savings` and generating `swh`, `wop`, and `tstat` columns...
"""

# ╔═╡ db159774-fe16-45ed-8f34-afbd68150f54
MCL_savings_desc = if @isdefined MCL_targets
	MCL_savings = leftjoin(MCL_targets, @where(savings_table_df, :type .== "sh"), on=:CEC_ZONE)
	
	@transform!(MCL_savings,
		swh = :swh_ .* :_2020_Baseload_Therms .* 2,
		wop = :wop_ .* (:_2020_Heating_Therms .- :_2020_Baseload_Therms),
		tstat = :tstat_ .* :_2020_Heating_Therms .- :_2020_Baseload_Therms,
		)
	
	MCL_savings[!,:savings] = @with MCL_savings begin
		:swh .+ :wop .+ :tstat .+ :tcv .+ :spout
	end
	
	describe(MCL_savings, :all, sum=>:sum)
end

# ╔═╡ 0fad5851-fe23-4895-9194-dd1625c9abe5
md"""
__Overriding savings with 7% for thermostat and 4% for Aquanta, and then discounted by 50%.__
 - smart thermostat savings $(@bind therm_pct NumberField(0:100,default=7)) %
 - Aquanta savings $(@bind aquanta_pct NumberField(0:100,default=4)) %
 - savings reduction $(@bind savings_reduction NumberField(0:100,default=50)) %
 - propensity score $(@bind propensity NumberField(0:100,default=1.5)) %
"""

# ╔═╡ 6c53ca70-b96f-4e0d-862f-45b335092556
begin
	MCL_savings[!,"Tstat Therms Saved"] .= MCL_savings[!,:_2020_Heating_Therms] * therm_pct/100 * savings_reduction/100
    MCL_savings[!,"WH Therms Saved"] .= MCL_savings[!,:_2020_Baseload_Therms] * aquanta_pct/100 * savings_reduction/100
	MCL_savings[!,"Combined Therms Savings"] = MCL_savings[!,"Tstat Therms Saved"] .+ MCL_savings[!,"WH Therms Saved"]
end;

# ╔═╡ bc9a3e3a-1bf7-460d-b3b1-a30228e2e7fa
if @isdefined MCL_savings
	histogram(MCL_savings[!,"Combined Therms Savings"], size=(900,400), title="Estimated Therms Savings Histogram")
end

# ╔═╡ 029834b6-9d7f-4b0a-a941-07e305ad63e1
md"""
## Customer Grouping 
Collecting customers into AB, A, and B cohorts
"""

# ╔═╡ 7397ca3a-7a1e-425a-ac09-8f30e49bd1ec
MCL_savings[!,"Group"] = [ 
    if MCL_savings[i,"Tstat Therms Saved"] > 20 && df[i,"WH Therms Saved"] > 20
        "AB"
    elseif MCL_savings[i,"Tstat Therms Saved"] > 20
        "A"
    elseif MCL_savings[i,"WH Therms Saved"] > 20
        "B"
    else
        "C"  # zero cases
    end for i in 1:length(MCL_savings[!,:GNN_ID]) 
	]

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

# ╔═╡ 9159a7dc-a80a-4b0b-8582-3d7069854f93
# AB groups without emails
begin
	T1AB_noemails = @where
end

# ╔═╡ 79f106b2-ed29-4286-b7c5-c46aa2780329
md"""
ReCurve data analysis and visualization

- SHOP ledger (ReCurve) data input: $(@bind ReCurve_csv FilePicker())
"""

# ╔═╡ ae5ae1ea-40f6-4e47-99b7-1fa9b9dee4ad
ReCurve_desc = if !isempty(ReCurve_csv["data"])
	ReCurve_df = UInt8.(ReCurve_csv["data"]) |> IOBuffer |> CSV.File |> DataFrame
	describe(ReCurve_df, :all, sum=>:sum)
end

# ╔═╡ 83e72e6e-608c-4b4b-b860-a0e9875ecf2b
md"""
## I heard you like plots!
"""

# ╔═╡ 6baba9b3-7eb5-494c-91d2-8ee5501ec76c
md"""
ReCurve columns: $(@bind ReCurve_cols MultiSelect(ReCurve_df |> names))
"""

# ╔═╡ 2e7f45b7-3486-4995-8514-74c5298ffba1
cumsum = zeros(225)

# ╔═╡ 1af1e39e-c2c1-4039-9575-68629de926d1
sum(coalesce.(ReCurve_df[!,:reporting_total_metered_savings], 0))

# ╔═╡ 38187e73-6c38-4c4a-b7ba-0afd13160c12
1:length(ReCurve_df[!,:reporting_total_metered_savings])

# ╔═╡ f1112b4e-0e1d-4800-b88d-b7d916184e94
program_cumsum = [ ReCurve_df[i,:reporting_total_metered_savings] + (i > 1 ? cumsum[i-1] : 0) for i in 1:225 ] 

# ╔═╡ aee6dda0-f832-4db0-8ff0-b15d98014f6d
program_cumsum |> plot

# ╔═╡ 8b2906b4-6ee4-4cad-8e67-4913f0e9e830
program_cumsum[end]

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

# ╔═╡ Cell order:
# ╟─868cd960-ba5b-11eb-2c92-255e7e10725e
# ╟─60dd45e8-3c31-4575-8739-a8d664aa58f3
# ╟─11c11ff9-5a14-4fe3-ab53-a65111060115
# ╟─8764c5aa-3472-4a7e-9212-9af62d3f902e
# ╟─d7598973-beb7-44b1-835b-3527fdc70668
# ╟─4e1fb60a-85dc-4831-9132-02d3eba6ea95
# ╟─cf876449-ae50-4583-8152-79c8239054e1
# ╟─c00c8c6e-a1a3-4fdf-9dc5-bbd3bcc20aa2
# ╟─92877da7-6f6d-4ba0-ba18-4763214564b8
# ╟─ed0d5d8b-345e-49bf-bcba-e6f4b19b8896
# ╟─a4cda47d-907b-4510-b68e-63b87d78ae02
# ╟─aa5bffb1-f412-4d52-b132-379b0a014c4b
# ╟─5fc68bf5-4fd6-4aab-ac8d-8d5e163558df
# ╟─db159774-fe16-45ed-8f34-afbd68150f54
# ╟─0fad5851-fe23-4895-9194-dd1625c9abe5
# ╠═6c53ca70-b96f-4e0d-862f-45b335092556
# ╟─bc9a3e3a-1bf7-460d-b3b1-a30228e2e7fa
# ╟─029834b6-9d7f-4b0a-a941-07e305ad63e1
# ╟─7397ca3a-7a1e-425a-ac09-8f30e49bd1ec
# ╠═d42fabef-dd60-4056-af92-c4daacf79177
# ╠═9159a7dc-a80a-4b0b-8582-3d7069854f93
# ╟─79f106b2-ed29-4286-b7c5-c46aa2780329
# ╟─ae5ae1ea-40f6-4e47-99b7-1fa9b9dee4ad
# ╟─83e72e6e-608c-4b4b-b860-a0e9875ecf2b
# ╟─6baba9b3-7eb5-494c-91d2-8ee5501ec76c
# ╠═2e7f45b7-3486-4995-8514-74c5298ffba1
# ╠═1af1e39e-c2c1-4039-9575-68629de926d1
# ╠═38187e73-6c38-4c4a-b7ba-0afd13160c12
# ╠═f1112b4e-0e1d-4800-b88d-b7d916184e94
# ╠═aee6dda0-f832-4db0-8ff0-b15d98014f6d
# ╠═8b2906b4-6ee4-4cad-8e67-4913f0e9e830
# ╟─bde8d1eb-9c04-47e9-aa2b-12a3c844e19c
# ╠═e9f7cd20-149e-42c4-83cf-d9b74dd4cd08
# ╠═fcd2727a-1dfe-426b-9318-297ac7c98d2d
# ╠═00c24ce5-62f0-4503-8204-b97eba3c1aa7
