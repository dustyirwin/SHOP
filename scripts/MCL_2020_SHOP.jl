
include("SHOPBase.jl")
using Main.SHOPBase


# loading input data
csv_df = CSV.File("data/input/mcl_2020.csv", normalizenames=true) |> DataFrame
csv_df |> names |> print

old_df = CSV.File("data/input/Old_MCL.csv") |> DataFrame
old_df = @select(old_df, :CUST_EMAIL_ADDR, :CUST_ID)  # selecting emails
old_df = coalesce.(old_df, "NA")
old_df = @where(old_df, :CUST_EMAIL_ADDR .!= "NA")

# writing input data description
#csv_desc = describe(csv_df, :all, sum=>:sum)
#write("data/input/mcl_2020-description.txt", csv_desc |> string)

# constants 
prob_f = 0.005
savings_reduction = 0.5  # applying 50% reduction on Tstat Therms Saved per McGee  Y.

# removing under 300 winter therms users
df = @where(csv_df, :WINTER_2020_THMS .> 300)

# building cols
@time begin

    df[!,"Heating Therms"] .= df[!,"_2020_ANNUAL"] .- 12 .* mean(
        [ df[!,"_202006"], df[!,"_202007"], df[!,"_202008"], df[!,"_202009"] ])

    df[!,"Baseload Therms"] .= df[!,"_2020_ANNUAL"] .- df[!,"Heating Therms"]
    
    df[!,"% Baseload"] .= df[!,"Baseload Therms"] ./ df[!,"_2020_ANNUAL"]
    
    df[!,"T-stat/heating"] .= (df[!,"wop"] .+ df[!,"tstat"]) ./ df[!,"Heating Therms"]
    
    df[!,"Tstat Therms Saved"] .= df[!,"T-stat/heating"] .* df[!,"Heating Therms"] * savings_reduction
    
    df[!,"HW/baseload"] .= df[!,"swh"] ./ df[!,"Baseload Therms"]
    
    df[!,"WH Therms Saved"] .= df[!,"HW/baseload"] .* df[!,"Baseload Therms"]
    
    df[!,"Comb Savings as % of Annual"] .= (df[!,"Tstat Therms Saved"] .+ df[!,"WH Therms Saved"]) ./ df[!,"_2020_ANNUAL"]
    
    df[!,"HW/baseload"] .= df[!,"swh"] ./ df[!,"Baseload Therms"]
    
    df[!,"WH Therms Saved"] .= df[!,"HW/baseload"] .* df[!,"Baseload Therms"] * savings_reduction
    
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


# Tier I customer groups
@where(df, :Group .== "AB" ) # 353738
@where(df, :Group .== "A" ) # 334151
@where(df, :Group .== "B" ) # 421059
@where(df, :Group .== "C" ) # 146069


# finding zeros in variables / possible NaN source
sum(df[!,"_2020_ANNUAL"] .== 0)
sum(df[!,"Baseload Therms"] .== 0)
sum(df[!,"Heating Therms"] .== 0)  # 134 @300


# excluding group C and slimming
slim_df = @where(df, :Group .!= "C" ) # 1108948
slim_df = coalesce.(df, "NA")

# leftjoining old on slim using :CUST_ID
both_emails_df = leftjoin(slim_df, old_df, on=:CUST_ID, makeunique=true)
both_emails_df = coalesce.(both_emails_df, "NA")

# matching emails to old_df
@showprogress for i in 1:length(both_emails_df[!,:GNN_ID])
    if both_emails_df[i,:CUST_EMAIL_ADDR] == "NA"
        both_emails_df[i,:CUST_EMAIL_ADDR] = both_emails_df[i,:CUST_EMAIL_ADDR_1]
    end
end

both_emails_df = @where(both_emails_df, :CUST_EMAIL_ADDR .!= "NA")

both_emails_df[!,:CUST_EMAIL_ADDR] |> unique

slim_email_df = select(both_emails_df, intersect(both_emails_df |> names, SHOPBase.column_names))

slim_email_df[!,:CUST_EMAIL_ADDR] |> unique  # 337102  392365 now?

slim_email_df |> names |> print

# writing and describing output data
write("data/output/MCL_2020_SHOP-300-therms-slim-T1-desc.txt", describe(slim_email_df, :all, sum=>:sum) |> string)
CSV.write("data/output/MCL_2020_SHOP-300-therms-slim-T1.csv", slim_email_df)
