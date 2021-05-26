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
	
	plotly()
	
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
if !isempty(SCG_csv["data"])
	csv = CSV.File(UInt8.(SCG_csv["data"]) |> IOBuffer, normalizenames=true) 
	df = csv |> DataFrame	
	
	md"""
	!!! csv "CSV Loaded"
	"""
end

# ╔═╡ e03549e4-ce54-4850-bffd-735fcd7fd637
if @isdefined df
	describe(df, :all, sum=>:sum)
end

# ╔═╡ 70bf7cd4-4f22-4757-88ee-56b9ae90be04
md"""
!!! note
	Targetting and savings calculation details may be found in the [Targeting for SHOP program](https://icfonline-my.sharepoint.com/:w:/g/personal/33648_icf_com/EUiH4sP72QNKuGLEADCFb5EB0rd-NmRyTSzf7cRKorFNHg?e=pa4Puu) document
	
	`Baseload Therms` is now defined as the average monthly therms usage of June, July, Aug and Sept.
	
	This [U. C. Irvine paper](https://www.physics.uci.edu/~silverma/actions/HouseholdEnergy.html#:~:text=With%20an%20average%20of%20400,8%2C000%20kWh%20equivalent%20for%20gas.) cites 400 therms as the average annual gas consumption per household in Southern California
"""

# ╔═╡ 0fad5851-fe23-4895-9194-dd1625c9abe5
md"""
## Customer Targeting
Retargetting customers with: 
- 2020 `Heating_Therms` above $(@bind heat_therms_lower NumberField(1:1000, default=200))

!!! warning
	Is this step necessary? If we're capping the therms savings at 50 and ignoring under 20 therms projects (except to set to 0), we may not need this restriction. 
"""

# ╔═╡ cc369e9c-0af1-455c-aa20-b3d7927e0e18
md"""
## Measure Savings Calc
New estimate parameters:
- Savings estimates are capped at a default of 50 therms.
- Savings estimates below 20 therms are set to 0. ICF will not attempt to install this measure.
- Using June-Sept 2020 mean usage as `Baseload_Therms`
- Smart thermostat savings = $(@bind therm_pct NumberField(0:100,default=7)) % of `Heating_therms` capped @ $(@bind tstat_cap NumberField(0:999, default=50)) therms
- Aquanta savings = $(@bind aquanta_pct NumberField(0:100,default=4)) % of `Baseload_Therms` capped @ $(@bind aquanta_cap NumberField(0:999, default=50)) therms
- Propensity score = $(@bind propensity NumberField(0:100,default=1.5)) %
"""

# ╔═╡ 6c53ca70-b96f-4e0d-862f-45b335092556
if @isdefined df
	df[!,:Heating_Therms] .= df[!,"_2020_ANNUAL"] .- 12 .* mean(
		[ df[!,"_202006"], df[!,"_202007"], df[!,"_202008"], df[!,"_202009"] ] )
	df[!,:Baseload_Therms] .= df[!,"_2020_ANNUAL"] .- df[!,:Heating_Therms]
	df[!,:Tstat_Therms_Saved] = df[!,:Heating_Therms] * (therm_pct / 100)	
	df[!,:WH_Therms_Saved] = df[!,:Baseload_Therms] * (aquanta_pct / 100)
	df[!,:Combined_Therms_Savings] = df[!,:Tstat_Therms_Saved] .+ df[!,:WH_Therms_Saved]
	
	md"""
	!!! calc "Measure Savings Calculation Complete"
	"""
end

# ╔═╡ afe35483-ca48-4235-9854-8361acb468b9
if @isdefined df
	df[!,:WH_Therms_Saved] = coalesce.(df[!,:WH_Therms_Saved], 0)
	df[!,:Tstat_Therms_Saved] = coalesce.(df[!,:WH_Therms_Saved], 0)
	
	df[!,:WH_Therms_Saved] = [ 
		
		if savings > tstat_cap
			tstat_cap 
		elseif savings > 20
			savings
		else
			0
		end 
			for savings in df[!,:WH_Therms_Saved] ]
	
	df[!,:Tstat_Therms_Saved] = [ 
		
		if savings > aquanta_cap
			aquanta_cap 
		elseif savings > 20
			savings
		else
			0
		end 
			for savings in df[!,:Tstat_Therms_Saved] ]
	
	md"""
	!!! capcut "Measure Savings Capped and Cut"
	"""
end

# ╔═╡ 77dba1dd-c22a-48c7-a1cc-0d95c62b249f
begin
	Tiers = [1, 2]
	Groups = ["AB", "A", "B"]

	md"""
	## Tier and Group Quals
	- Tier I threshold: above $(@bind T1_thresh NumberField(1:99999, default=20)) therms savings for either measure
	- Tier II threshold: above the savings cap for either measure


	- Group A: Estimated Aquanta Savings meets Tier I threshold
	- Group B: Estimated Smart Thermostat Savings meets Tier I threshold
	- Group AB: Meets both group requirements
	- Group C: Meets neither group requirements
	"""
end

# ╔═╡ 7397ca3a-7a1e-425a-ac09-8f30e49bd1ec
if (@isdefined df) && (df isa DataFrame)
	
	df[!,:Group] = [
		
	if df[i,:Tstat_Therms_Saved] > T1_thresh && df[i,:WH_Therms_Saved] > T1_thresh
		"AB"
	elseif df[i,:Tstat_Therms_Saved] > T1_thresh
		"A"
	elseif df[i,:WH_Therms_Saved] > T1_thresh
		"B"
	else
		"C"
	end for i in 1:length(df[!,:GNN_ID])
				
	]
	
	# Setting all customers to Tier 1
	df[!,:Tier] = ones(length(df[!,:GNN_ID]))
	
	# finding Tier 2 customers
	df[!,:Tier] = [ savings == tstat_cap ? 2 : 1 for savings in df[!,:Tstat_Therms_Saved] ]
	df[!,:Tier] = [ savings == aquanta_cap ? 2 : 1 for savings in df[!,:WH_Therms_Saved] ]
	
	md"""
	!!! group "Grouping Complete"
	"""
end

# ╔═╡ b7461faf-dc28-4f62-a43a-08870c0d83a1
if @isdefined df
	describe(
		df,
		[ :mean, :min, :median, :max, :nmissing, :eltype ]...,
		sum => :sum,
		cols=[:Tstat_Therms_Saved, :WH_Therms_Saved, :Combined_Therms_Savings, :Group, :Tier]
	)
end

# ╔═╡ bc9a3e3a-1bf7-460d-b3b1-a30228e2e7fa
if (@isdefined df) #&& (df isa DataFrame) && ("Combined_Therms_Savings" in df |> names)
	StatsPlots.histogram(
		select(df, :Tstat_Therms_Saved, :WH_Therms_Saved) |> Matrix,
		title="New Therms Savings Histogram",
		labels=string.([:Tstat_Therms_Saved :WH_Therms_Saved]),
		size=(800,400),
	)
end

# ╔═╡ 5d5c58b6-1a57-4111-b1cf-d1c9e50e9e89
if @isdefined df
	df[!,:SVC_ADDR_FULL] = df[!,:SVC_ADDR1] .* df[!,:SVC_ADDR2] .* df[!,:SVC_CITY] .* string.(df[!,:SVC_ZIP]) .* df[!,:SVC_ZIP9] 
	
	md"""
	!!! note
		Created `SVC_ADDR_FULL` column in `MCL_grouped_savings` dataframe
	"""
end

# ╔═╡ 13fd7bbd-d78b-4b08-ad5d-2425fb0c4ecd
if @isdefined df
	s = Dict{Symbol,Any}(
		Symbol("T$tier$group") => Dict{Symbol,Any}(	
			:df=>@where(
				df, 
				:Tier .== tier, 
				:Group .== group)
			) for tier in Tiers, group in Groups 
		)
	
	for k in keys(s)
		s[k][:savings_mean] = round( s[k][:df][!,:Combined_Therms_Savings] |> mean, sigdigits=4)
		s[k][:savings_total] = round( s[k][:df][!,:Combined_Therms_Savings] |> sum, sigdigits=4)
		s[k][:customer_count] = round( s[k][:df][!,:CUST_ID] |> unique |> length, sigdigits=4)
		s[k][:email_count] = round( s[k][:df][!,:CUST_EMAIL_ADDR] |> unique |> length, sigdigits=4)
		s[k][:address_count] = round( s[k][:df][!,:SVC_ADDR_FULL] |> unique |> length, sigdigits=4)
	end

		if !(:program_savings in keys(s))
		s[:mean_therm_savings_per_home] = round( df[!,:Combined_Therms_Savings] |> mean, sigdigits=4)
		s[:total_therm_savings] = round( df[!,:Combined_Therms_Savings] |> sum, sigdigits=4)
		s[:program_savings] = round( df[!,:Combined_Therms_Savings] * propensity / 100 |> sum, sigdigits=4)
	end
	
	md"""
	!!! stats "Program Statistics Generated"
	"""
end

# ╔═╡ 658132e8-9cb1-4e02-a4d0-3970d8180bad
if (@isdefined df) 
	total_measure_savings = round( s[:total_therm_savings], sigdigits=4)
	mean_therm_savings_per_home = round( s[:mean_therm_savings_per_home], sigdigits=4)
	program_savings = round( s[:total_therm_savings] * propensity / 100, sigdigits=4)
	
	md"""

	## Program Savings Stats

	- Program savings (propensity of 1.5%) = $program_savings therms
	- Total measure savings = $total_measure_savings therms
	- Mean therms saved per home per year = $mean_therm_savings_per_home
	- Total AB emails
	
	- ICF revenue ?= \$$(round( program_savings * 11, sigdigits=4))
	"""
end

# ╔═╡ 81dbea14-5d99-48c1-aafc-d8ef91e1d705
df[!,:CUST_EMAIL_ADDR] |> unique |> length

# ╔═╡ a1291c48-8efa-4a0b-b181-3fd8bff08bce
@where(df, :CUST_EMAIL_ADDR .!= "NA", :Group .== "C") |> eachrow |> length

# ╔═╡ 43e98583-ff75-4ac2-a99e-4b58f95cfb4e
@where(df, :CUST_EMAIL_ADDR .!= "NA", :Group .== "B") |> eachrow |> length

# ╔═╡ 588d94bd-300b-4fde-bb35-cbf57690c8bb
@where(df, :CUST_EMAIL_ADDR .!= "NA", :Group .== "A") |> eachrow |> length

# ╔═╡ 42483ec9-a79b-48ee-85f3-53bd7eb46552
@where(df, :CUST_EMAIL_ADDR .!= "NA", :Group .== "AB") |> eachrow |> length

# ╔═╡ 947d8047-0b67-4e35-9780-c0945ddb8e48
# ~$11 per therm to ICF from SoCalGas
# 3500 participants ~ 65 therms each
# 350K potential customers with email and/or address

# ╔═╡ 3d2b922c-33d2-46e9-9729-6087cd0d3bcb
md"""
## Data Export
Download MCL\_grouped\_savings dataframe as a CSV? $(@bind download_csv CheckBox(default=false))
"""

# ╔═╡ 69959e4e-83fe-47b2-8c6e-1d75da91b19d
md"""
## Outstanding issues
!!! danger
	Check to make sure emails aren't being tossed out with duplicate customer records
"""

# ╔═╡ 92603658-e437-49ef-8136-3c76b064ca67
md"""
## Outstanding questions
!!! warning
	MANSIONS! What do do about extrema homes? Ahmed mentioned 5 in 5000? Is that in the top 1% of consumers?
	
	Should we take an avg of all available years for baseline / heating therms values?
"""

# ╔═╡ 2a739049-a2d1-47e1-b52b-0911e352a05f
if (@isdefined df) && download_csv
	filename = "tmp/" * "MCL_grouped_savings_slim-" * randstring(10) * ".csv"
	CSV.write(filename, df)
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
if @isdefined df
	unique_customers = df[!,:CUST_ID] |> unique |> length
	unique_emails = df[!,:CUST_EMAIL_ADDR] |> unique |> length
	
	leftright(
		md"unique customer ids: $unique_customers",
		md"unique emails: $unique_emails"
	)
end

# ╔═╡ 617e2561-9794-4a59-abd6-ec9bf44144fb
if @isdefined s
	leftright(md"""
		### Tier II
		- AB customer count = $(s[:T2AB][:customer_count])
		- AB email count = $(s[:T2AB][:email_count])
		- AB address count = $(s[:T2AB][:address_count])
		- AB mean savings = $(s[:T2AB][:savings_mean])
		- AB total savings = $(s[:T2AB][:savings_total])
		""",
		md"""
		### Tier I
		- AB customer count = $(s[:T1AB][:customer_count])
		- AB email count = $(s[:T1AB][:email_count])
		- AB address count = $(s[:T1AB][:address_count])
		- AB mean savings = $(s[:T1AB][:savings_mean])
		- AB total savings = $(s[:T1AB][:savings_total])
		"""
	)
end

# ╔═╡ cdc7e754-a102-495a-b49a-7bc43851b8c2
if @isdefined s
leftright(md"""
	- A customer count = $(s[:T2A][:customer_count])
	- A email count = $(s[:T2A][:email_count])
	- A address count = $(s[:T2A][:address_count])
	- A mean savings = $(s[:T2A][:savings_mean])
	- A total savings = $(s[:T2A][:savings_total])
	""",
	md"""
	- A customer count = $(s[:T1A][:customer_count])
	- A email count = $(s[:T1A][:email_count])
	- A address count = $(s[:T1A][:address_count])
	- A mean savings = $(s[:T1A][:savings_mean])
	- A total savings = $(s[:T1A][:savings_total])
	"""
	)
end

# ╔═╡ 22fd3bda-f4d8-410a-8cd0-062577e526c3
if @isdefined s
leftright(
	md"""
	- B customer count = $(s[:T2B][:customer_count])
	- B email count = $(s[:T2B][:email_count])
	- B address count = $(s[:T2B][:address_count])
	- B mean savings = $(s[:T2B][:savings_mean])
	- B total savings = $(s[:T2B][:savings_total])
	""",
	md"""
	- B customer count = $(s[:T1B][:customer_count])
	- B email count = $(s[:T1B][:email_count])
	- B address count = $(s[:T1B][:address_count])
	- B mean savings = $(s[:T1B][:savings_mean])
	- B total savings = $(s[:T1B][:savings_total])
	"""
	)
end

# ╔═╡ 71bfd4ff-866f-4137-842d-0eb7c8eaa537
if @isdefined s
	leftright(md"""
	Tier II Totals:

	- Customer count = $( round( sum([ s[sym][:customer_count] for sym in [:T2AB, :T2A, :T2B] ]), digits=2))
	- Email count = $( round( sum([ s[sym][:email_count] for sym in [:T2AB, :T2A, :T2B] ]), digits=2))
	- Address count = $( round( sum([ s[sym][:address_count] for sym in [:T2AB, :T2A, :T2B] ]), digits=2))
	- Mean savings = $( round( mean([ s[sym][:savings_mean] for sym in [:T2AB, :T2B] ]), digits=2))
	- Total savings = $( round( sum([ s[sym][:savings_total] for sym in [:T2AB, :T2A, :T2B] ]), digits=2))
	""",
	md"""
	Tier I Totals:

	- Customer count = $( round( sum([ s[sym][:customer_count] for sym in [:T1AB, :T1A, :T1B] ]), digits=2))
	- Email count = $( round( sum([ s[sym][:email_count] for sym in [:T1AB, :T1A, :T1B] ]), digits=2))
	- Address count = $( round( sum([ s[sym][:address_count] for sym in [:T1AB, :T1A, :T1B] ]), digits=2))
	- Mean savings = $( round( mean([ s[sym][:savings_mean] for sym in [:T1AB, :T1A, :T1B] ]), digits=2))
	- Total savings = $( round( sum([ s[sym][:savings_total] for sym in [:T1AB, :T1A, :T1B] ]), digits=2))
	"""
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

# ╔═╡ 5066ed9a-32ae-4b25-b065-c50a81df59f6
if @isdefined df
	updown(md"""
	!!! note
		This looks like a [Pareto distribution](https://en.wikipedia.org/wiki/Pareto_distribution)""",
	Resource("https://upload.wikimedia.org/wikipedia/commons/thumb/1/11/Probability_density_function_of_Pareto_distribution.svg/1920px-Probability_density_function_of_Pareto_distribution.svg.png", :width => 500))
end;

# ╔═╡ Cell order:
# ╟─868cd960-ba5b-11eb-2c92-255e7e10725e
# ╟─60dd45e8-3c31-4575-8739-a8d664aa58f3
# ╟─11c11ff9-5a14-4fe3-ab53-a65111060115
# ╟─11fd20c1-a9c8-4467-a65f-990015da018e
# ╟─e03549e4-ce54-4850-bffd-735fcd7fd637
# ╟─70bf7cd4-4f22-4757-88ee-56b9ae90be04
# ╟─0fad5851-fe23-4895-9194-dd1625c9abe5
# ╟─cc369e9c-0af1-455c-aa20-b3d7927e0e18
# ╟─6c53ca70-b96f-4e0d-862f-45b335092556
# ╟─afe35483-ca48-4235-9854-8361acb468b9
# ╟─77dba1dd-c22a-48c7-a1cc-0d95c62b249f
# ╟─7397ca3a-7a1e-425a-ac09-8f30e49bd1ec
# ╟─b7461faf-dc28-4f62-a43a-08870c0d83a1
# ╟─bc9a3e3a-1bf7-460d-b3b1-a30228e2e7fa
# ╟─5066ed9a-32ae-4b25-b065-c50a81df59f6
# ╟─5d5c58b6-1a57-4111-b1cf-d1c9e50e9e89
# ╟─13fd7bbd-d78b-4b08-ad5d-2425fb0c4ecd
# ╟─658132e8-9cb1-4e02-a4d0-3970d8180bad
# ╠═81dbea14-5d99-48c1-aafc-d8ef91e1d705
# ╠═a1291c48-8efa-4a0b-b181-3fd8bff08bce
# ╠═43e98583-ff75-4ac2-a99e-4b58f95cfb4e
# ╠═588d94bd-300b-4fde-bb35-cbf57690c8bb
# ╠═42483ec9-a79b-48ee-85f3-53bd7eb46552
# ╟─617e2561-9794-4a59-abd6-ec9bf44144fb
# ╟─cdc7e754-a102-495a-b49a-7bc43851b8c2
# ╟─22fd3bda-f4d8-410a-8cd0-062577e526c3
# ╟─71bfd4ff-866f-4137-842d-0eb7c8eaa537
# ╠═947d8047-0b67-4e35-9780-c0945ddb8e48
# ╟─3d2b922c-33d2-46e9-9729-6087cd0d3bcb
# ╟─69959e4e-83fe-47b2-8c6e-1d75da91b19d
# ╟─92603658-e437-49ef-8136-3c76b064ca67
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
