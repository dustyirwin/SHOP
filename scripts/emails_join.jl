
using CSV
using DataFramesMeta
using Statistics

# loading input data
df = CSV.File("data/input/mcl_2020.csv") |> DataFrame
df_old = CSV.File("data/input/Old_MCL.csv") |> DataFrame


new = @select(df, :GNN_ID, :CUST_EMAIL_ADDR)
new = dropmissing(new, :CUST_EMAIL_ADDR)

old = @select(df_old, :GNN_ID, :CUST_EMAIL_ADDR)
old = dropmissing(old, :CUST_EMAIL_ADDR)

combo_df = rightjoin(new, old, on=:GNN_ID, makeunique=true)

combo_df[!,:CUST_EMAIL_ADDR] |> unique
combo_df[!,:CUST_EMAIL_ADDR_1] |> unique
combo_df[!,:GNN_ID] |> unique


write("data/output/mcl_emails_description.txt",  describe(combo_df, :all, sum=>:sum) |> string)
CSV.write("data/output/mcl_emails.csv", combo_df )
