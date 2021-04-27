
using CSV
using DataFramesMeta
using Statistics

# loading input data
df = CSV.File("data/input/mcl_2020.csv") |> DataFrame

# creating index col
df[!,"INDEX"] .= 1:length(df[!,"GNN_ID"])

# generating and writing description
df_desc = df |> describe
write("data/input/mcl_2020-description.txt", df_desc |> string)

# renaming cols into strings from desc
colnames = df_desc[!,:variable] .|> string

# constants 
prob_f = 0.005
savings_reduction = 0.5  # applying 50% reduction on Tstat Therms Saved per McGee Y.

# building cols
@time begin

    df[!,"Heating Therms"] .= df[!,"2020_ANNUAL"] .- 12 .* mean(
        [ df[!,"202006"], df[!,"202007"], df[!,"202008"], df[!,"202009"] ])

    df[!,"Baseload Therms"] .= df[!,"2020_ANNUAL"] .- df[!,"Heating Therms"]
    
    df[!,"% Baseload"] .= df[!,"Baseload Therms"] ./ df[!,"2020_ANNUAL"]
    
    df[!,"T-stat/heating"] .= (df[!,"wop"] .+ df[!,"tstat"]) ./ df[!,"Heating Therms"]
    
    df[!,"Tstat Therms Saved"] .= df[!,"T-stat/heating"] .* df[!,"Heating Therms"] * savings_reduction
    
    df[!,"HW/baseload"] .= df[!,"swh"] ./ df[!,"Baseload Therms"]
    
    df[!,"WH Therms Saved"] .= df[!,"HW/baseload"] .* df[!,"Baseload Therms"]
    
    df[!,"Comb Savings as % of Annual"] .= (df[!,"Tstat Therms Saved"] .+ df[!,"WH Therms Saved"]) ./ df[!,"2020_ANNUAL"]
    
    df[!,"HW/baseload"] .= df[!,"swh"] ./ df[!,"Baseload Therms"]
    
    df[!,"WH Therms Saved"] .= df[!,"HW/baseload"] .* df[!,"Baseload Therms"]
    
    df[!,"Combined Therms Savings"] .= df[!,"Tstat Therms Saved"] .+ df[!,"WH Therms Saved"]
    
    df[!,"Combined % Savings"] .= df[!,"Combined Therms Savings"] ./ df[!,"2020_ANNUAL"]
    
    df[!,"Probability Function of Savings"] .= df[!,"Combined Therms Savings"] .* prob_f
    
end

# writing and describing output data
write("data/output/MCL_2020_SHOP-description.txt", df |> describe |> string)

outfile = CSV.write("data/output/MCL_2020_SHOP.csv", df)

# finding zeros in variables / possible NaN source
sum(df[!,"2020_ANNUAL"] .== 0)
sum(df[!,"Baseload Therms"] .== 0)
sum(df[!,"Heating Therms"] .== 0)  # 2627 found