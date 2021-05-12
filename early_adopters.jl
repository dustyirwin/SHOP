
using DataFramesMeta
using ProgressMeter
using Statistics
using CSV


# loading ReCurve project slugs (GNN_IDs)
SHOP_ledger_df = CSV.File("data/input/SHOP_Ledger_Inputs-2021-03.csv", normalizenames=true) |> DataFrame
GNNs = SHOP_ledger_df[!,:project_slug]

# loading input data
mcl_df = CSV.File("data/input/mcl_2020.csv", normalizenames=true) |> DataFrame
mcl_GNNs = mcl_df[!,:GNN_ID] |> unique
mcl_df |> names |> print

old_df = CSV.File("data/input/Old_MCL.csv") |> DataFrame
old_GNNs = old_df[!,:GNN_ID] |> unique

new_df = CSV.File("data/input/ICF_MCL_MAY2021.csv") |> DataFrame
new_GNNs = new_df[!,:GNN_ID] |> unique
new_df |> names |> print

i, j, k = 0, 0, 0
mcl_matches, old_matches, new_matches = [], [], []

for id in GNNs
    if id in mcl_GNNs 
        i+=1
        push!(mcl_matches, id)
    elseif id in old_GNNs 
        j+=1
        push!(old_matches, id)
    elseif id in new_GNNs 
        k+=1
        push!(new_matches, id)
    end    
end

begin
    println("found $i in mcl_GNNs!")
    println("found $j in old_GNNs!")
    println("found $k in new_GNNs!")
end

mcl_matches
old_matches
new_matches

mcl_matches_df = DataFrame(GNN_ID=mcl_matches)
old_matches_df = DataFrame(GNN_ID=old_matches)

ea_df = leftjoin(gnn_df, mcl_df, on=:GNN_ID)
ea_df |> names |> print

CSV.write("data/output/MCL_201912-202101_early_adopters.csv", ea_df)

#=
old_df[!,:GNN_ID] = coalesce.(old_df[!,:GNN_ID],0)

eao_df = leftjoin(gnn_df, old_df, on=:GNN_ID)
eao_df |> names |> print
=#