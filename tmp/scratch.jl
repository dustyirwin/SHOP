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


with_terminal() do
	if (@isdefined MCL_grouped_savings) && (MCL_grouped_savings isa DataFrame)
		t = groupby(MCL_grouped_savings, :Tier)
		combine(describe, t, ungroup = false) |> (t -> show(t, allrows = true, allgroups = true))
	end
end