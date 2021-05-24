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
		Pkg.add(["PlutoUI", "StatsPlots", "CSV", "Statistics", "DataFramesMeta","HypertextLiteral"])
	end
	
	using DataFramesMeta
	using Statistics
	using StatsPlots
	using PlutoUI
	using Random
	using CSV
	
	import DarkMode
	
	md"""
	# 📜 Napkin Calcs 
	
	Hi McGee! This is an experimental tool use with caution ⚠️ 
	"""
end

# ╔═╡ 60dd45e8-3c31-4575-8739-a8d664aa58f3
md"""
## Upload SCG MCL data

Latest MCL: 

Column header names will be normalized. Descriptions will be provided below.
- MCL (SoCalGas) data input: $(@bind SCG_csv FilePicker())
"""

# ╔═╡ 11c11ff9-5a14-4fe3-ab53-a65111060115
MCL_desc = if !isempty(SCG_csv["data"])
	MCL_csv = CSV.File(UInt8.(SCG_csv["data"]) |> IOBuffer, normalizenames=true) 
	MCL_df = MCL_csv |> DataFrame	
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

# ╔═╡ a4cda47d-907b-4510-b68e-63b87d78ae02
if !isempty(SCG_csv["data"])
	md"""
	## Measure Savings Calculation
	
	The savings table supplied by Ahmed: [compiled_savings.csv](https://icfonline-my.sharepoint.com/:x:/g/personal/33648_icf_com/EVO2S2yDc8JElpRUqoEjr-IBiRDIAKo4cnivWPOKjYazjw?e=z62pu5) 
	
	Upload a measure savings table below to calculate measure savings using the measure table
	- Savings table: $(@bind savings_table_csv FilePicker())
	"""
end

# ╔═╡ aa5bffb1-f412-4d52-b132-379b0a014c4b
savings_table_df = if (@isdefined savings_table_csv) && (!isempty(savings_table_csv["data"]))
	CSV.File(UInt8.(savings_table_csv["data"]) |> IOBuffer, normalizenames=true) |> DataFrame
end

# ╔═╡ a71665f4-0951-44f7-969e-d933bed20f62
md"""
__Joining `MCL_targets` and `savings_table_df` on `:CEC_ZONE` and generating `swh`, `wop`, and `tstat` columns__

## Measure Savings Results
"""

# ╔═╡ 0fad5851-fe23-4895-9194-dd1625c9abe5
md"""

# ⚠️ Measure Savings ReCalc

1. Retargetting customers with 2020 `Heating_Therms` usage between $(@bind heat_therms_lower NumberField(1:1000, default=300)) and $(@bind heat_therms_upper NumberField(1:1000, default=9999)) therms.
- __Should we take an avg of all available years?__
1. Recalculating estimated savings based on 7% of heating load for Smart Thermostats and 4% for Aquanta WH Controllers
1. Discounting savings by 50%.

New savings estimate parameters:
- Using June-Sept total usage as `Baseload_Therms`
- Smart thermostat savings = $(@bind therm_pct NumberField(0:100,default=7)) % of `Heating_therms` * `savings_reduction`
- Aquanta savings = $(@bind aquanta_pct NumberField(0:100,default=4)) % of `Baseload_Therms` * `savings_reduction`
- Savings reduction factor = $(@bind savings_reduction NumberField(0:100,default=50)) %
- Propensity score = $(@bind propensity NumberField(0:100,default=1.5)) %


Group qualifications:
- Group A: Estimated Aquanta Savings is at least $(@bind aqsav_lower NumberField(1:999, default=20.)) therms and less than $(@bind aqsav_upper NumberField(1:999, default=100.)) therms
- Group B: Estimated Smart Thermostat Savings is at least $(@bind tssav_lower NumberField(1:999, default=20.)) therms and less than $(@bind tssav_upper NumberField(1:999, default=100.)) therms
- Group AB: Meets both group requirements.
- Group C: Meets neither group requirements.


**Targetting and savings calculation details may be found in the [Targeting for SHOP program](https://icfonline-my.sharepoint.com/:w:/g/personal/33648_icf_com/EUiH4sP72QNKuGLEADCFb5EB0rd-NmRyTSzf7cRKorFNHg?e=pa4Puu) document**
"""

# ╔═╡ 6c53ca70-b96f-4e0d-862f-45b335092556
MCL_new_savings = if @isdefined MCL_csv
	df = MCL_csv |> DataFrame
	
	df[!,:Heating_Therms] .= df[!,"_2020_ANNUAL"] .- 12 .* mean([ df[!,"_202006"], df[!,"_202007"], df[!,"_202008"], df[!,"_202009"] ])
	
	df[!,:Baseload_Therms] .= df[!,"_2020_ANNUAL"] .- df[!,:Heating_Therms]
	
	df = @where(df, :Heating_Therms .> heat_therms_lower, :Heating_Therms .< heat_therms_upper)
	
	df[!,:Tstat_Therms_Saved] = df[!,:Heating_Therms] * (therm_pct / 100) * (savings_reduction / 100)
    
	df[!,:WH_Therms_Saved] = df[!,:Baseload_Therms] * (aquanta_pct / 100) * (savings_reduction / 100)
	
	df[!,:Combined_Therms_Savings] = df[!,:Tstat_Therms_Saved] .+ df[!,:WH_Therms_Saved]
	
	df = @where(df, :Tstat_Therms_Saved .> tssav_lower)
	
	df = @where(df, :Tstat_Therms_Saved .< tssav_upper)  # setting upper limit.. keep?
	
	df = @where(df, :WH_Therms_Saved .> aqsav_lower)
		
	df = @where(df, :WH_Therms_Saved .< aqsav_upper)  # setting upper limit.. keep?
end;

# ╔═╡ 7397ca3a-7a1e-425a-ac09-8f30e49bd1ec
begin
	MCL_new_savings[!,:Group] = [
		
	if MCL_new_savings[i,:Tstat_Therms_Saved] > 20 && MCL_new_savings[i,:WH_Therms_Saved] > 20
	"AB"
	elseif MCL_new_savings[i,:Tstat_Therms_Saved] > 20
		"A"
	elseif MCL_new_savings[i,:WH_Therms_Saved] > 20
		"B"
	else
		"C"
	end for i in 1:length(MCL_new_savings[!,:GNN_ID])
				
	]
	
	md"""
	## Customer Grouping 
	Collecting customers into AB, A, and B groupings
	"""
end

# ╔═╡ bc9a3e3a-1bf7-460d-b3b1-a30228e2e7fa
if (@isdefined MCL_new_savings) && ("Combined_Therms_Savings" in MCL_new_savings |> names)
	histogram(
		select(MCL_new_savings, :Tstat_Therms_Saved, :WH_Therms_Saved, :Combined_Therms_Savings) |> Matrix,
		title="New Estimated Therms Savings Histogram",
		labels=[:Tstat_Therms_Saved :WH_Therms_Saved :Combined_Therms_Savings],
		size=(800,400),
	)
end

# ╔═╡ b7461faf-dc28-4f62-a43a-08870c0d83a1
MCL_new_savings_desc = if @isdefined MCL_new_savings 
	describe(MCL_new_savings,
		[ :mean, :min, :median, :max, :nmissing, :eltype ]...,
		sum => :sum,	
		cols=[:Tstat_Therms_Saved, :WH_Therms_Saved, :Combined_Therms_Savings, :Group
	])
end

# ╔═╡ d52bcf99-f303-4755-9f31-0238d504b3bc
g = groupby(MCL_new_savings, :Group)

# ╔═╡ b7f8b1b2-aed0-4c8d-9a88-4a8c948c734c
with_terminal() do
	combine(describe, g, ungroup = false) |> (t -> show(t, allrows = true, allgroups = true))
end

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
md"""
# MCL Data Export
Download the new MCL as a CSV!
"""

# ╔═╡ 2a739049-a2d1-47e1-b52b-0911e352a05f
if !(MCL_new_savings isa Nothing)
	out_df = select(MCL_new_savings, MCL_keepcols)
	filename = tempdir() * randstring(10) * ".csv"
	CSV.write(filename, out_df)
	DownloadButton(read(filename), basename(filename))
end

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

# ╔═╡ cdf4f394-da81-4bfa-ba55-be6a8bb6e3ca
#gr()

# ╔═╡ a0ac9f42-72b6-449f-891e-dedaadb19939
# cell width control
"""
<style>
  main {
	max-width: 950px;
	align-self: flex-start;
	margin-left: 50px;
  }
""" |> HTML

# ╔═╡ 5be23715-c5a9-47e6-8301-ebefab7d6724
plotly()

# ╔═╡ cb45d403-ecb0-4929-bab2-915d3d6498a4
leftright(a, b; width=600) = """
<style>
	table.nohover tr:hover td {
   		background-color: white !important;
	}
</style>
<table width=$(width)px class="nohover" style="border:none">
	<tr>
		<td>$(html(a))</td>
		<td>$(html(b))</td>
	</tr>
</table>
""" |> HTML

# ╔═╡ 2945046d-0107-4c6a-b65a-1a2a804d79b9
md"""
## Customer Targeting
Targeting and savings estimation methods used based on Ahmed's [savings_calculations.R](https://icfonline-my.sharepoint.com/:u:/g/personal/33648_icf_com/EYXit2vgTO9HjXsu6ShU4MgBF4SUhPkqU16NRtKQS8eQCg?e=cnH78I) script

$(leftright(
	md"Use Quantiles? $(@bind use_quantiles CheckBox(default=true))",
	md"Quantile Range $(@bind low_q NumberField(0:100,default=50))% - $(@bind high_q NumberField(0:100,default=70))%"
	))
"""

# ╔═╡ 92877da7-6f6d-4ba0-ba18-4763214564b8
if @isdefined MCL_df
	heat_lowq, heat_highq = quantile(MCL_df[!,"WINTER_2020_THMS"], [low_q/100, high_q/100])
	base_lowq, base_highq = quantile(MCL_df[!,"_2020_BASELOAD_THMS"], [low_q/100, high_q/100])
		
	md"""
	Selecting projects with `WINTER_2020_THMS` between __$heat_lowq__ and __$heat_highq__ and `_2020_BASELOAD_THMS` between __$base_lowq__ and __$base_highq__
	"""
end

# ╔═╡ ed0d5d8b-345e-49bf-bcba-e6f4b19b8896
MCL_targets_desc = if @isdefined MCL_df
	MCL_targets = if use_quantiles
		@where(MCL_df, 
			:WINTER_2020_THMS .> heat_lowq,
			:WINTER_2020_THMS .< heat_highq,
			:_2020_BASELOAD_THMS .> base_lowq,
			:_2020_BASELOAD_THMS .< base_highq
		)
	else
		MCL_df
	end
	
	describe(MCL_targets, :all, sum=>:sum)
end

# ╔═╡ db159774-fe16-45ed-8f34-afbd68150f54
if (@isdefined MCL_targets) && !isempty(savings_table_csv["data"])
	MCL_savings = leftjoin(MCL_targets, @where(savings_table_df, :type .== "sh"), on=:CEC_ZONE)
	
	@transform!(MCL_savings,
		swh = :swh_ .* :_2020_BASELOAD_THMS .* 2,
		wop = :wop_ .* (:WINTER_2020_THMS .- :_2020_BASELOAD_THMS),
		tstat = :tstat_ .* :WINTER_2020_THMS .- :_2020_BASELOAD_THMS,
		)
	
	MCL_savings[!,:savings] = @with MCL_savings begin
		:swh .+ :wop .+ :tstat .+ :tcv .+ :spout
	end
end

# ╔═╡ ed36453a-fda8-45d5-93f8-7828be779317
if (@isdefined MCL_savings) && ("savings" in MCL_savings |> names)
	histogram(
		MCL_savings[!,"savings"], 
		title="Old Estimated Therms Savings Histogram",
		labels=permutedims(select(MCL_savings, "savings") |> names),
		size=(800,400), 
	)
end

# ╔═╡ df2dddb0-1638-46aa-a193-50cbae6ebab4
updown(a, b; width=nothing) = """
<table class="nohover" style="border:none" $(width === nothing ? "" : "width=$widthpx")>
	<tr>
		<td>$(html(a))</td>
	</tr>
	<tr>
		<td>$(html(b))</td>
	</tr>
</table>
""" |> HTML

# ╔═╡ d2a6550a-a9aa-45fc-9435-92b4d9e016ab
if (@isdefined MCL_savings) && ("savings" in MCL_savings |> names)
	savings = MCL_savings[!,:savings] |> sum 
	
	updown(
		describe(MCL_savings,
			[ :mean, :min, :median, :max, :nmissing, :eltype ]...,
			sum => :sum,
			cols=["savings"]),
		Resource("https://mashable-evaporation-wordpress.s3.amazonaws.com/2013/07/Dr.-Who.gif")
	)
end

# ╔═╡ Cell order:
# ╟─868cd960-ba5b-11eb-2c92-255e7e10725e
# ╟─60dd45e8-3c31-4575-8739-a8d664aa58f3
# ╟─11c11ff9-5a14-4fe3-ab53-a65111060115
# ╟─8764c5aa-3472-4a7e-9212-9af62d3f902e
# ╟─d7598973-beb7-44b1-835b-3527fdc70668
# ╟─4e1fb60a-85dc-4831-9132-02d3eba6ea95
# ╟─2945046d-0107-4c6a-b65a-1a2a804d79b9
# ╟─92877da7-6f6d-4ba0-ba18-4763214564b8
# ╟─ed0d5d8b-345e-49bf-bcba-e6f4b19b8896
# ╟─a4cda47d-907b-4510-b68e-63b87d78ae02
# ╟─aa5bffb1-f412-4d52-b132-379b0a014c4b
# ╟─a71665f4-0951-44f7-969e-d933bed20f62
# ╟─db159774-fe16-45ed-8f34-afbd68150f54
# ╟─ed36453a-fda8-45d5-93f8-7828be779317
# ╟─d2a6550a-a9aa-45fc-9435-92b4d9e016ab
# ╟─0fad5851-fe23-4895-9194-dd1625c9abe5
# ╟─6c53ca70-b96f-4e0d-862f-45b335092556
# ╟─7397ca3a-7a1e-425a-ac09-8f30e49bd1ec
# ╟─bc9a3e3a-1bf7-460d-b3b1-a30228e2e7fa
# ╟─b7461faf-dc28-4f62-a43a-08870c0d83a1
# ╟─d52bcf99-f303-4755-9f31-0238d504b3bc
# ╟─b7f8b1b2-aed0-4c8d-9a88-4a8c948c734c
# ╟─d42fabef-dd60-4056-af92-c4daacf79177
# ╟─3d2b922c-33d2-46e9-9729-6087cd0d3bcb
# ╟─2a739049-a2d1-47e1-b52b-0911e352a05f
# ╟─33e60c2d-3b1b-4ed8-9ec4-a0b574aff867
# ╟─bde8d1eb-9c04-47e9-aa2b-12a3c844e19c
# ╟─e9f7cd20-149e-42c4-83cf-d9b74dd4cd08
# ╠═fcd2727a-1dfe-426b-9318-297ac7c98d2d
# ╠═00c24ce5-62f0-4503-8204-b97eba3c1aa7
# ╠═cdf4f394-da81-4bfa-ba55-be6a8bb6e3ca
# ╠═a0ac9f42-72b6-449f-891e-dedaadb19939
# ╟─5be23715-c5a9-47e6-8301-ebefab7d6724
# ╟─cb45d403-ecb0-4929-bab2-915d3d6498a4
# ╟─df2dddb0-1638-46aa-a193-50cbae6ebab4
