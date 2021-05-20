
using CSV
using Statistics
using DataFramesMeta


# list of GNN_IDs to match against
list = include("data/input/GNN_list.jl") |> sort

# Tiered MCL csv
MCL_df = "data/output/MCL_2021_300_therms_Tiered.csv" |> CSV.File |> DataFrame
sort!(MCL_df, by=x->:GNN_ID)

# matching on both datasets
GNN_matches_MCL = @where(MCL_df, in.(:GNN_ID, [ list ]))

# generating descriptions
MCL_desc = describe(GNN_matches_MCL, :all, sum=>:sum)

# writing files
CSV.write("data/output/GNN_matches_MCL.csv", GNN_matches_MCL)
write("data/output/GNN-matching/GNN_matches_MCL-description.txt", MCL_desc |> string)

CSV.write("ReCurve_GNN_IDs.csv", DataFrame(GNN_ID = list))
