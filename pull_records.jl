
using CSV
using Statistics
using DataFramesMeta


# list of GNN_IDs to match against
list = include("data/input/GNN_list.jl") |> sort

# SHOP csv
SHOP_df = "data/output/MCL_2020_SHOP.csv" |> CSV.File |> DataFrame
sort!(SHOP_df, by=x->:GNN_ID)

# Full MCL csv
MCL_df = "data/input/mcl_2020.csv" |> CSV.File |> DataFrame
sort!(MCL_df, by=x->:GNN_ID)

# matching on both datasets
GNN_matches_SHOP = @where(SHOP_df, in.(:GNN_ID, [ list ]))

GNN_matches_MCL = @where(MCL_df, in.(:GNN_ID, [ list ]))

# generating descriptions
SHOP_desc = describe(GNN_matches_SHOP, :all, sum=>:sum)

MCL_desc = describe(GNN_matches_MCL, :all, sum=>:sum)

# writing files
CSV.write("data/output/GNN_matches_SHOP.csv", GNN_matches_SHOP)
write("data/output/GNN-matching/GNN_matches_MCL-description.txt", SHOP_desc |> string)

CSV.write("data/output/GNN_matches_MCL.csv", GNN_matches_MCL)
write("data/output/GNN-matching/GNN_matches_SHOP-description.txt", MCL_desc |> string)
