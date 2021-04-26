
using CSV
using Statistics
using DataFrames
using DataFramesMeta
using ProgressMeter
using Plots


#loading csv data
mcl_df = CSV.File("data/ICF_MCL_MAR2021.csv") |> DataFrame


# creating index col
mcl_df[!,"INDEX"] .= 1:length(mcl_df[!,"GNN_ID"])


# renaming cols into strings
colnames = mcl_df_desc[!,:variable] .|> string


# generating description
mcl_df_desc = mcl_df |> describe
mcl_df_desc


# constants 
type = "sh"
spout = 7.83
swh_ = 0.1664
wop_ = 0.07
tcv = 2.276015857
tstat_ = 0.075
prob_f = 0.005


# apply 50% reduction on Tstat Therms Saved...
savings_reduction = 0.5


# needs func/val
mcl_df[!,"rank"] .= 1  # can define
mcl_df[!,"tstat"] .= 1
mcl_df[!,"swh"] .= 1 
mcl_df[!,"wop"] .= 1
mcl_df[!,"savings"] .= 1


# building cols
mcl_df[!,"Heating Therms"] = @showprogress [ 
    mcl_df[i,"2020_ANNUAL"] - 12 * mean([ 
        mcl_df[i,"202006"], mcl_df[i,"202007"], mcl_df[i,"202008"], mcl_df[i,"202009"] ]
            ) for i in mcl_df[!,"INDEX"] ];
mcl_df[!,"Baseload Therms"] .= mcl_df[!,"2020_ANNUAL"] .- mcl_df[!,"Heating Therms"]
mcl_df[!,"% Baseload"] .= mcl_df[!,"Baseload Therms"] ./ mcl_df[!,"2020_ANNUAL"]
mcl_df[!,"type"] .= type
mcl_df[!,"spout"] .= spout
mcl_df[!,"swh_"] .= swh_
mcl_df[!,"wop_"] .= wop_
mcl_df[!,"tcv"] .= tcv
mcl_df[!,"tstat_"] .= tstat_
mcl_df[!,"HW/baseload"] .= mcl_df[!,"swh"] ./ mcl_df[!,"Baseload Therms"]
mcl_df[!,"WH Therms Saved"] .= mcl_df[!,"HW/baseload"] .* mcl_df[!,"Baseload Therms"]
mcl_df[!,"T-stat/heating"] .= (mcl_df[!,"wop"] .+ mcl_df[!,"tstat"]) ./ mcl_df[!,"Heating Therms"]
mcl_df[!,"Tstat Therms Saved"] .= mcl_df[!,"T-stat/heating"] .* mcl_df[!,"Heating Therms"] .* savings_reduction
mcl_df[!,"Comb Savings as % of Annual"] .= (mcl_df[!,"Tstat Therms Saved"]) ./ mcl_df[!,"2020_ANNUAL"]
mcl_df[!,"HW/baseload"] .= mcl_df[!,"swh"] ./ mcl_df[!,"Baseload Therms"]
mcl_df[!,"WH Therms Saved"] .= mcl_df[!,"HW/baseload"] .* mcl_df[!,"Baseload Therms"]
mcl_df[!,"Combined Therms Savings"] .= mcl_df[!,"Tstat Therms Saved"] .+ mcl_df[!,"WH Therms Saved"]
mcl_df[!,"Combined % Savings"] .= mcl_df[!,"Combined Therms Savings"] ./ mcl_df[!,"2020_ANNUAL"]
mcl_df[!,"Probability Function of Savings"] .= mcl_df[!,"Combined Therms Savings"] .* prob_f
