
include("SHOPBase.jl")
using Main.SHOPBase
using Base.Threads

Threads.nthreads()

#=

Process:

1. identify Tier I Cust w/ email (using mcl_2020.csv and script)
2. identify Tier II Cust w/ email (using ICF_MCL_MAY2021.csv)
3. gather required columns.
4. upload to sharepoint

=#


# import and process cleaned mcl_df
mcl_df = CSV.File("data/output/MCL_2020_SHOP-300-therms-slim-T1.csv") |> DataFrame
#mcl_df = unique(mcl_df, :CUST_EMAIL_ADDR) # retaining rows with unique cust email records
mcl_df[!,:CUST_EMAIL_ADDR]

# adding Tier I label
mcl_df[!,"Tier"] .= "T1"


# import and process cleaned may_df
may_df = CSV.File("data/output/ICF_MCL_2021_SHOP-300-therms-slim-T2.csv") |> DataFrame
#may_df = unique(may_df, :CUST_EMAIL_ADDR) # retaining rows with unique cust email records
may_df[!,:CUST_EMAIL_ADDR]

# adding Tier I label
may_df[!,"Tier"] .= "T2"


may_df = coalesce.(may_df, 0)
mcl_df = coalesce.(mcl_df, 0)

combo_df = outerjoin(mcl_df, may_df, on = intersect(names(mcl_df), names(may_df)))
combo_df = @where(combo_df, :Group .!= "C")

t1_cust_ids = @where(combo_df, :Tier .== "T1")[!,:CUST_ID]
t2_cust_ids = @where(combo_df, :Tier .== "T2")[!,:CUST_ID]

overlapping_customers = intersect(t1_cust_ids, t2_cust_ids)

Threads.@threads for row in eachrow(combo_df)
    if row[:CUST_ID] in overlapping_customers
        row[:Tier] = "T2"
    end
end

combo_df = unique(combo_df, :CUST_EMAIL_ADDR)

@where(combo_df, :Tier .== "T1")
@where(combo_df, :Tier .== "T2")


# writing and describing output data
write("data/output/MCL_2021_300_therms_Tiered-desc.txt", describe(combo_df, :all, sum=>:sum) |> string)
CSV.write("data/output/MCL_2021_300_therms_Tiered.csv", combo_df)


groupby(combo_df, "Group")