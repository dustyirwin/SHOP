### A Pluto.jl notebook ###
# v0.14.6

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
		using PlotlyBase
	catch
		Pkg.rm("HypertextLiteral")
		Pkg.add(url="https://github.com/Pocket-titan/DarkMode#master")
		Pkg.add(["PlutoUI", "StatsPlots", "CSV", "Statistics", "DataFramesMeta", "PlotlyBase"])
	end
	
	using DataFramesMeta
	using Statistics
	using StatsPlots
	using PlutoUI
	using Random
	using CSV
	
	import DarkMode
	
	gr()
	
	md"""
	# 📜 SHOP Napkin :: SCG MCL
	
	Hi McGee! This is an experimental tool use with caution ⚠️ 
	"""
end

# ╔═╡ 60dd45e8-3c31-4575-8739-a8d664aa58f3
md"""
## Upload SCG MCL data 
**(pre-intervention data?)**

- [Old_MCL.csv](https://icfonline-my.sharepoint.com/:x:/g/personal/33648_icf_com/EW2KFBNs449MmM_yfWI3BjcBYtJndy1mp7LTnqBhVqMGMw?e=36UXuh) has data back to 2018, no monthly data
 - [mcl_2020.csv](https://icfonline-my.sharepoint.com/:x:/g/personal/33648_icf_com/EecHDcsSvkpLjDyo4aS3B6sBwnTNylXMFsgqfNXSBkc_yg?e=LTucR7) file has monthly data from 2019/12 - 2021/01
 - [ICF\_MCL\_MAY2021.csv](https://icfonline-my.sharepoint.com/:x:/g/personal/33648_icf_com/EQEmFBJuiB9DikSXEGR-1BEBHLySqZYwuoCd1amrFrZQZw?e=Sbh6ol) file has monthly data from 2020/01 - 2021/02
- [MCL\_Combined\_201912-202102-slim](https://icfonline-my.sharepoint.com/:x:/g/personal/33648_icf_com/EQsqOS5uWS9Ft1oIZAsMaWwBtEAigsOndoLAeO7IZCig8w?e=DTaAsU) contains all available monthly data

Column header names will be normalized. A dataset description will be generated below.
- SCG MCL data input: $(@bind SCG_csv FilePicker())
"""

# ╔═╡ 11c11ff9-5a14-4fe3-ab53-a65111060115
MCL_desc = if !isempty(SCG_csv["data"])
	MCL_csv = CSV.File(UInt8.(SCG_csv["data"]) |> IOBuffer, normalizenames=true) 
	MCL_df = MCL_csv |> DataFrame	
	describe(MCL_df, :all, sum=>:sum)
end

# ╔═╡ 9616d97c-9da4-4190-910b-c9585f967cdc
md"!!! note
	Using [MCL_Fields.csv](https://icfonline-my.sharepoint.com/:x:/g/personal/33648_icf_com/EQx_wySet5ZInGTVwD42Q6UBXQn7kOsvcPNpVKaoUbySqQ?e=eGbvX7) to keep columns required for PBI dashboard."

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
!!! info
	Joining `MCL_targets` and `savings_table_df` on `:CEC_ZONE` and generating `swh`, `wop`, and `tstat` columns

## Measure Savings Results
"""

# ╔═╡ 22ce9c38-2a4a-49cf-8f8c-5dfcfee8788f
html"""<br><br><br><br><br><br><br>"""

# ╔═╡ 70bf7cd4-4f22-4757-88ee-56b9ae90be04
md"""
!!! note
	Targetting and savings calculation details may be found in the [Targeting for SHOP program](https://icfonline-my.sharepoint.com/:w:/g/personal/33648_icf_com/EUiH4sP72QNKuGLEADCFb5EB0rd-NmRyTSzf7cRKorFNHg?e=pa4Puu) document
	
	`Baseload Therms` is now defined as the average monthly therms usage of June, July, Aug and Sept.
	
	This [U. C. Irvine paper](https://www.physics.uci.edu/~silverma/actions/HouseholdEnergy.html#:~:text=With%20an%20average%20of%20400,8%2C000%20kWh%20equivalent%20for%20gas.) cites 400 therms as the average annual gas consumption per household in Southern California
"""

# ╔═╡ 0fad5851-fe23-4895-9194-dd1625c9abe5
md"""
## ⚠️ Customer ReTargeting
Retargetting customers with: 
- 2020 `Heating_Therms` above $(@bind heat_therms_lower NumberField(1:1000, default=200))
"""

# ╔═╡ cc369e9c-0af1-455c-aa20-b3d7927e0e18
md"""
## ⚠️ Measure Savings ReCalc
New estimate parameters:
- Using June-Sept 2020 total usage as `Baseload_Therms`
- Smart thermostat savings = $(@bind therm_pct NumberField(0:100,default=7)) % of `Heating_therms` capped @ $(@bind tstat_cap NumberField(0:999, default=50)) therms
- Aquanta savings = $(@bind aquanta_pct NumberField(0:100,default=4)) % of `Baseload_Therms` capped @ $(@bind aquanta_cap NumberField(0:999, default=50)) therms
- Propensity score = $(@bind propensity NumberField(0:100,default=1.5)) %
"""

# ╔═╡ 77dba1dd-c22a-48c7-a1cc-0d95c62b249f
begin
	Tiers = [1, 2]
	Groups = ["AB", "A", "B"]

	md"""
	Tier and Grouping qualifications:
	- Tier I threshold: above $(@bind T1_thresh NumberField(1:99999, default=20)) therms savings for either measure
	- Tier II threshold: above the savings cap for either measure


	- Group A: Estimated Aquanta Savings meets Tier I threshold
	- Group B: Estimated Smart Thermostat Savings meets Tier I threshold
	- Group AB: Meets both group requirements
	- Group C: Meets neither group requirements
	"""
end

# ╔═╡ 6c53ca70-b96f-4e0d-862f-45b335092556
if @isdefined MCL_df
	df = MCL_df
	
	df[!,:Heating_Therms] .= df[!,"_2020_ANNUAL"] .- 12 .* mean([ df[!,"_202006"], df[!,"_202007"], df[!,"_202008"], df[!,"_202009"] ])
	
	df[!,:Baseload_Therms] .= df[!,"_2020_ANNUAL"] .- df[!,:Heating_Therms]
	
	df = @where(df, :Heating_Therms .> heat_therms_lower)
	
	df[!,:Tstat_Therms_Saved] = df[!,:Heating_Therms] * (therm_pct / 100) 
    df[!,:Tstat_Therms_Saved] = [ 
		if savings > tstat_cap
			tstat_cap 
		elseif savings > 20
			savings
		else
			0 
		end for savings in df[!,:Tstat_Therms_Saved] ]
	
	df[!,:WH_Therms_Saved] = df[!,:Baseload_Therms] * (aquanta_pct / 100)
	df[!,:WH_Therms_Saved] = [ 
		if savings > aquanta_cap
			aquanta_cap 
		elseif savings > 20
			savings
		else
			0 
		end for savings in df[!,:WH_Therms_Saved] ]
	
	df[!,:Combined_Therms_Savings] = df[!,:Tstat_Therms_Saved] .+ df[!,:WH_Therms_Saved]
	
	MCL_new_savings = unique(df, :CUST_EMAIL_ADDR)
	
	md"""
	!!! calc "Calculation Completed"
		Removed records with duplicate CUST_IDs
	
		Enforced savings caps
	"""
end

# ╔═╡ 7397ca3a-7a1e-425a-ac09-8f30e49bd1ec
if (@isdefined MCL_new_savings) && (MCL_new_savings isa DataFrame)
	MCL_new_savings[!,:Group] = [
		
	if MCL_new_savings[i,:Tstat_Therms_Saved] > T1_thresh && MCL_new_savings[i,:WH_Therms_Saved] > T1_thresh
		"AB"
	elseif MCL_new_savings[i,:Tstat_Therms_Saved] > T1_thresh
		"A"
	elseif MCL_new_savings[i,:WH_Therms_Saved] > T1_thresh
		"B"
	else
		"C"
	end for i in 1:length(MCL_new_savings[!,:GNN_ID])
				
	]
	
	# finding Tier 1 customers
	MCL_new_savings[!,:Tier] = [ savings .> T1_thresh ? 1 : 0 for savings in MCL_new_savings[!,:Tstat_Therms_Saved] ]
	MCL_new_savings[!,:Tier] = [ savings .> T1_thresh ? 1 : 0 for savings in MCL_new_savings[!,:WH_Therms_Saved] ]
	
	# finding Tier 2 customers
	MCL_new_savings[!,:Tier] = [ savings .> tstat_cap ? 1 : 0 for savings in MCL_new_savings[!,:Tstat_Therms_Saved] ]
	MCL_new_savings[!,:Tier] = [ savings .> aquanta_cap ? 1 : 0 for savings in MCL_new_savings[!,:WH_Therms_Saved] ]
	
	md"""
	!!! group "Grouping Completed"
	"""
end

# ╔═╡ 0be5ddfc-079b-47d4-82de-439ad9c4ec39


# ╔═╡ b7461faf-dc28-4f62-a43a-08870c0d83a1
MCL_new_savings_desc = if (@isdefined MCL_new_savings) && (MCL_new_savings isa DataFrame)	
	describe(
		MCL_new_savings,
		[ :mean, :min, :median, :max, :nmissing, :eltype ]...,
		sum => :sum,
		cols=[:Tstat_Therms_Saved, :WH_Therms_Saved, :Combined_Therms_Savings, :Group]
	)
end

# ╔═╡ bc9a3e3a-1bf7-460d-b3b1-a30228e2e7fa
if (@isdefined MCL_new_savings) && (MCL_new_savings isa DataFrame) && ("Combined_Therms_Savings" in MCL_new_savings |> names)
	StatsPlots.histogram(
		select(MCL_new_savings, :Tstat_Therms_Saved, :WH_Therms_Saved) |> Matrix,
		title="New Therms Savings Histogram",
		labels=string.([:Tstat_Therms_Saved :WH_Therms_Saved]),
		size=(800,400),
	)
end;

# ╔═╡ 5d5c58b6-1a57-4111-b1cf-d1c9e50e9e89
if @isdefined MCL_new_savings
	MCL_new_savings[!,:SVC_ADDR_FULL] = MCL_new_savings[!,:SVC_ADDR1] .* MCL_new_savings[!,:SVC_ADDR2] .* MCL_new_savings[!,:SVC_CITY] .* string.(MCL_new_savings[!,:SVC_ZIP]) .* MCL_new_savings[!,:SVC_ZIP9] 
	
	md"""
	!!! note
		Created `SVC_ADDR_FULL` column in `MCL_grouped_savings` dataframe
	"""
end

# ╔═╡ 13fd7bbd-d78b-4b08-ad5d-2425fb0c4ecd
if @isdefined MCL_new_savings
	s = Dict{Symbol,Any}(
		Symbol("T$tier$group") => Dict{Symbol,Any}(	
			:df=>@where(
				MCL_new_savings, 
				:Tier .== tier, 
				:Group .== group)
			) for tier in Tiers, group in Groups 
		)
	
	for k in keys(s)
		s[k][:savings_mean] = round( s[k][:df][!,:Combined_Therms_Savings] |> mean, digits=2)
		s[k][:savings_total] = round( s[k][:df][!,:Combined_Therms_Savings] |> sum, digits=2)
		s[k][:customer_count] = round( s[k][:df][!,:CUST_ID] |> unique |> length, digits=2)
		s[k][:email_count] = round( s[k][:df][!,:CUST_EMAIL_ADDR] |> unique |> length, digits=2)
		s[k][:address_count] = round( s[k][:df][!,:SVC_ADDR_FULL] |> unique |> length, digits=2)
	end

		if !(:program_savings in keys(s))
		s[:mean_therm_savings_per_home] = round( MCL_new_savings[!,:Combined_Therms_Savings] |> mean, digits=2)
		s[:total_therm_savings] = round( MCL_new_savings[!,:Combined_Therms_Savings] |> sum, digits=2)
		s[:program_savings] = round( MCL_new_savings[!,:Combined_Therms_Savings] * propensity / 100 |> sum, digits=2)
	end
	
	md"""
	!!! stats "Program Statistics Generated"
		Results are broken out by Tier and Group
	"""
end

# ╔═╡ 658132e8-9cb1-4e02-a4d0-3970d8180bad
if (@isdefined MCL_new_savings) 
md"""

## Program Savings Stats

- Program therms savings (propensity of 1.5%) = $(s[:total_therm_savings] * propensity / 100)
- Total therms savings = $(s[:total_therm_savings])
- Mean therms saved per home (are these only single-family residential homes?) per year = $(s[:mean_therm_savings_per_home])
"""
end

# ╔═╡ 947d8047-0b67-4e35-9780-c0945ddb8e48
# ~$11 per therm to ICF from SoCalGas
# 3500 participants ~ 65 therms each
# 350K potential customers with email and/or address

# ╔═╡ 3d2b922c-33d2-46e9-9729-6087cd0d3bcb
md"""
## Data Export
Download MCL\_grouped\_savings dataframe as a CSV? $(@bind download_csv CheckBox(default=false))
"""

# ╔═╡ 92603658-e437-49ef-8136-3c76b064ca67
md"""
## Outstanding questions
!!! warning
	Why are some homes using so much gas? MANSIONS!
	
	Should we take an avg of all available years for baseline / heating therms values?
	
	Should the Tier II metric be cost-driven?
"""

# ╔═╡ 69959e4e-83fe-47b2-8c6e-1d75da91b19d
md"""
## Outstanding issues
!!! warning
	Check to make sure emails aren't being tossed out with duplicate customer records
"""

# ╔═╡ 2a739049-a2d1-47e1-b52b-0911e352a05f
if MCL_new_savings isa DataFrame && download_csv
	filename = "tmp/" * "MCL_grouped_savings_slim-" * randstring(10) * ".csv"
	CSV.write(filename, MCL_grouped_savings)
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

# ╔═╡ cdf4f394-da81-4bfa-ba55-be6a8bb6e3ca
#gr()

# ╔═╡ 9b0570eb-e752-4e46-b709-9f50a20b7912


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

# ╔═╡ 11fd20c1-a9c8-4467-a65f-990015da018e
if @isdefined MCL_df
	
	unique_projects = MCL_df[!,:GNN_ID] |> unique |> length
	unique_customers = MCL_df[!,:CUST_ID] |> unique |> length
	unique_emails = MCL_df[!,:CUST_EMAIL_ADDR] |> unique |> length
	
	leftright(
		md"unique customer ids: $unique_customers",
		md"unique emails: $unique_emails"
	)
end

# ╔═╡ 2945046d-0107-4c6a-b65a-1a2a804d79b9
md"""
## Customer Targeting
$(leftright(
md"Use Quantiles? $(@bind use_quantiles CheckBox(default=false))",
md"Quantile Range $(@bind low_q NumberField(0:100,default=50))% - $(@bind high_q NumberField(0:100,default=70))%"
))
!!! note
	Targeting and savings estimation methods used based on Ahmed's [savings_calculations.R](https://icfonline-my.sharepoint.com/:u:/g/personal/33648_icf_com/EYXit2vgTO9HjXsu6ShU4MgBF4SUhPkqU16NRtKQS8eQCg?e=cnH78I) script

"""

# ╔═╡ 92877da7-6f6d-4ba0-ba18-4763214564b8
if @isdefined MCL_df
	heat_lowq, heat_highq = quantile(MCL_df[!,"WINTER_2020_THMS"] |> skipmissing |> collect, [low_q/100, high_q/100])
	base_lowq, base_highq = quantile(MCL_df[!,"_2020_BASELOAD_THMS"] |> skipmissing |> collect, [low_q/100, high_q/100])
		
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
	
	MCL_savings[!,:savings] = MCL_savings[!,:savings]
end

# ╔═╡ ed36453a-fda8-45d5-93f8-7828be779317
if (@isdefined MCL_savings) && ("savings" in MCL_savings |> names)
	
	StatsPlots.histogram(
		coalesce.(MCL_savings[!,:savings], 0),
		title="Estimated Therms Savings Histogram",
		labels="savings",
		size=(800,400), 
	)
end

# ╔═╡ d2a6550a-a9aa-45fc-9435-92b4d9e016ab
if (@isdefined MCL_savings) && ("savings" in MCL_savings |> names)
	savings = MCL_savings[!,:savings] |> sum 
	
	describe(MCL_savings,
		[ :mean, :min, :median, :max, :nmissing, :eltype ]...,
		sum => :sum,
		cols=["savings"]
	)
end

# ╔═╡ a1291c48-8efa-4a0b-b181-3fd8bff08bce
if @isdefined MCL_new_savings
	@where(MCL_new_savings, :Tier .== 1, :Group .== "AB") |> eachrow |> length
	
	leftright(md"""
		### Tier I
		- AB customer count = $(s[:T2AB][:customer_count])
		- AB address count = $(s[:T2AB][:address_count])
		- AB email count = $(s[:T2AB][:email_count])
		- AB mean savings = $(s[:T2AB][:savings_mean])
		- AB total savings = $(s[:T2AB][:savings_total])

		
		- A customer count = $(s[:T2A][:customer_count])
		- A address count = $(s[:T2A][:address_count])
		- A email count = $(s[:T2A][:email_count])
		- A mean savings = $(s[:T2A][:savings_mean])
		- A total savings = $(s[:T2A][:savings_total])


		- B customer count = $(s[:T2B][:customer_count])
		- B address count = $(s[:T2B][:address_count])
		- B email count = $(s[:T2B][:email_count])
		- B mean savings = $(s[:T2B][:savings_mean])
		- B total savings = $(s[:T2B][:savings_total])
		""",
		
		md"""
		### Tier II
		- AB customer count = $(s[:T1AB][:customer_count])
		- AB address count = $(s[:T1AB][:address_count])
		- AB email count = $(s[:T1AB][:email_count])
		- AB mean savings = $(s[:T1AB][:savings_mean])
		- AB total savings = $(s[:T1AB][:savings_total])

		
		- A customer count = $(s[:T1A][:customer_count])
		- A address count = $(s[:T1A][:address_count])
		- A email count = $(s[:T1A][:email_count])
		- A mean savings = $(s[:T1A][:savings_mean])
		- A total savings = $(s[:T1A][:savings_total])


		- B customer count = $(s[:T1B][:customer_count])
		- B address count = $(s[:T1B][:address_count])
		- B email count = $(s[:T1B][:email_count])
		- B mean savings = $(s[:T1B][:savings_mean])
		- B total savings = $(s[:T1B][:savings_total])
		""",
	)
end

# ╔═╡ 601127cb-6a0e-448c-9a6e-7284234f449b


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

# ╔═╡ 8764c5aa-3472-4a7e-9212-9af62d3f902e
updown(
	md"Choose a csv file with column names to keep: $(@bind keep_cols_csv FilePicker())",
	md"Slim down this dataset using :Fieldname values? $(@bind slim_df CheckBox(default=false))", 
)

# ╔═╡ d7598973-beb7-44b1-835b-3527fdc70668
MCL_keepcols = if !isempty(keep_cols_csv["data"]) && slim_df
	kc_df = CSV.File(UInt8.(keep_cols_csv["data"]) |> IOBuffer, normalizenames=true) |> DataFrame
	kc_df[!,:Fieldname]
end

# ╔═╡ 4e1fb60a-85dc-4831-9132-02d3eba6ea95
if (@isdefined MCL_df) && slim_df
	select!(MCL_df, intersect(MCL_keepcols, MCL_df |> names))
end

# ╔═╡ 5066ed9a-32ae-4b25-b065-c50a81df59f6
if @isdefined MCL_new_savings
	updown(md"""
	!!! note
		This looks like a [Pareto distribution](https://en.wikipedia.org/wiki/Pareto_distribution)
	""",
	Resource("https://upload.wikimedia.org/wikipedia/commons/thumb/1/11/Probability_density_function_of_Pareto_distribution.svg/1920px-Probability_density_function_of_Pareto_distribution.svg.png", :width => 500))
end;

# ╔═╡ Cell order:
# ╟─868cd960-ba5b-11eb-2c92-255e7e10725e
# ╟─60dd45e8-3c31-4575-8739-a8d664aa58f3
# ╟─11c11ff9-5a14-4fe3-ab53-a65111060115
# ╟─11fd20c1-a9c8-4467-a65f-990015da018e
# ╟─9616d97c-9da4-4190-910b-c9585f967cdc
# ╟─8764c5aa-3472-4a7e-9212-9af62d3f902e
# ╟─d7598973-beb7-44b1-835b-3527fdc70668
# ╟─4e1fb60a-85dc-4831-9132-02d3eba6ea95
# ╟─2945046d-0107-4c6a-b65a-1a2a804d79b9
# ╟─92877da7-6f6d-4ba0-ba18-4763214564b8
# ╟─ed0d5d8b-345e-49bf-bcba-e6f4b19b8896
# ╟─a4cda47d-907b-4510-b68e-63b87d78ae02
# ╟─aa5bffb1-f412-4d52-b132-379b0a014c4b
# ╟─a71665f4-0951-44f7-969e-d933bed20f62
# ╠═db159774-fe16-45ed-8f34-afbd68150f54
# ╟─ed36453a-fda8-45d5-93f8-7828be779317
# ╟─d2a6550a-a9aa-45fc-9435-92b4d9e016ab
# ╟─22ce9c38-2a4a-49cf-8f8c-5dfcfee8788f
# ╟─70bf7cd4-4f22-4757-88ee-56b9ae90be04
# ╠═0fad5851-fe23-4895-9194-dd1625c9abe5
# ╠═cc369e9c-0af1-455c-aa20-b3d7927e0e18
# ╠═77dba1dd-c22a-48c7-a1cc-0d95c62b249f
# ╠═6c53ca70-b96f-4e0d-862f-45b335092556
# ╠═7397ca3a-7a1e-425a-ac09-8f30e49bd1ec
# ╠═0be5ddfc-079b-47d4-82de-439ad9c4ec39
# ╟─b7461faf-dc28-4f62-a43a-08870c0d83a1
# ╟─bc9a3e3a-1bf7-460d-b3b1-a30228e2e7fa
# ╟─5066ed9a-32ae-4b25-b065-c50a81df59f6
# ╟─5d5c58b6-1a57-4111-b1cf-d1c9e50e9e89
# ╟─13fd7bbd-d78b-4b08-ad5d-2425fb0c4ecd
# ╟─658132e8-9cb1-4e02-a4d0-3970d8180bad
# ╟─a1291c48-8efa-4a0b-b181-3fd8bff08bce
# ╠═947d8047-0b67-4e35-9780-c0945ddb8e48
# ╟─3d2b922c-33d2-46e9-9729-6087cd0d3bcb
# ╟─92603658-e437-49ef-8136-3c76b064ca67
# ╟─69959e4e-83fe-47b2-8c6e-1d75da91b19d
# ╟─2a739049-a2d1-47e1-b52b-0911e352a05f
# ╟─33e60c2d-3b1b-4ed8-9ec4-a0b574aff867
# ╟─bde8d1eb-9c04-47e9-aa2b-12a3c844e19c
# ╠═e9f7cd20-149e-42c4-83cf-d9b74dd4cd08
# ╠═fcd2727a-1dfe-426b-9318-297ac7c98d2d
# ╠═00c24ce5-62f0-4503-8204-b97eba3c1aa7
# ╠═a0ac9f42-72b6-449f-891e-dedaadb19939
# ╠═cdf4f394-da81-4bfa-ba55-be6a8bb6e3ca
# ╠═9b0570eb-e752-4e46-b709-9f50a20b7912
# ╟─cb45d403-ecb0-4929-bab2-915d3d6498a4
# ╠═601127cb-6a0e-448c-9a6e-7284234f449b
# ╟─df2dddb0-1638-46aa-a193-50cbae6ebab4
