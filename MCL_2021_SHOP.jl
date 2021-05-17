
include("SHOPBase.jl")
using Main.SHOPBase

# loading input data
csv_df = CSV.File("data/input/ICF_MCL_MAY2021.csv", normalizenames=true) |> DataFrame
csv_df |> names |> print

# writing input data description
#csv_desc = describe(csv_df, :all, sum=>:sum)
#write("data/input/ICF_MCL_MAY2021-description.txt", csv_desc |> string)

# constants 
prob_f = 0.005
savings_reduction = 0.5  # applying 50% reduction on Tstat Therms Saved per McGee  Y.

# removing under 300 winter therms users
df = @where(csv_df, :WINTER_2020_THMS .> 300)
df = coalesce.(df, "NA")

# building cols
begin

    df[!,"Heating Therms"] .= df[!,"_2020_ANNUAL"] .- 12 .* mean(
        [ df[!,"_202006"], df[!,"_202007"], df[!,"_202008"], df[!,"_202009"] ])

    df[!,"Baseload Therms"] .= df[!,"_2020_ANNUAL"] .- df[!,"Heating Therms"]

    df[!,"% Baseload"] .= df[!,"Baseload Therms"] ./ df[!,"_2020_ANNUAL"]

    df[!,"Tstat Therms Saved"] .= df[!,"Heating Therms"] * 0.07 * savings_reduction

    df[!,"WH Therms Saved"] .= df[!,"Baseload Therms"] * 0.04 * savings_reduction

    df[!,"Comb Savings as % of Annual"] .= (df[!,"Tstat Therms Saved"] .+ df[!,"WH Therms Saved"]) ./ df[!,"_2020_ANNUAL"]

    df[!,"Combined Therms Savings"] .= df[!,"Tstat Therms Saved"] .+ df[!,"WH Therms Saved"]

    df[!,"Combined % Savings"] .= df[!,"Combined Therms Savings"] ./ df[!,"_2020_ANNUAL"]

    df[!,"Probability Function of Savings"] .= df[!,"Combined Therms Savings"] * prob_f

end

# grouping
df[!,"Group"] = [ 
    if df[i,"Tstat Therms Saved"] > 20 && df[i,"WH Therms Saved"] > 20
        "AB"
    elseif df[i,"Tstat Therms Saved"] > 20
        "A"
    elseif df[i,"WH Therms Saved"] > 20
        "B"
    else
        "C"  # zero cases
    end for i in 1:length(df[!,:GNN_ID]) 
    ]


# Tier II customer groups
@where(df, :Group .== "AB" ) # 11678
@where(df, :Group .== "A" ) # 96855
@where(df, :Group .== "B" ) # 44067
@where(df, :Group .== "C" ) # 1102417


# finding zeros in variables / possible NaN source
sum(df[!,"_2020_ANNUAL"] .== 0)
sum(df[!,"Baseload Therms"] .== 0)
sum(df[!,"Heating Therms"] .== 0)  # 134


# excluding group C, slimming datset
df = @where(df, :Group .!= "C" ) # 152600
df = @where(df, :CUST_EMAIL_ADDR .!= "NA") # 89752

slim_df = select(df, intersect(df |> names, SHOPBase.column_names))
slim_df[!,:CUST_EMAIL_ADDR] |> unique

missing_email_percent = 89752 / 152600

# !!!  59% of emails are missing... cross reference other datsets? !!!

# TODO: Create Master MCL file with all relevant, cleaned, data

# writing and describing output data
write("data/output/ICF_MCL_2021_SHOP-300-therms-slim-desc.txt", 
    describe(slim_df, :all, sum=>:sum) |> string)
outfile = CSV.write("data/output/ICF_MCL_2021_SHOP-300-therms-slim.csv", 
    slim_df)
