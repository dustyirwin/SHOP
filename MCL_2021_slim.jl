using DataFramesMeta
using ProgressMeter
using Statistics
using CSV


keepcols = Symbol.([
"GNN_ID",
"CUST_ID",
"IC_FST_NM",
"IC_LST_NM",
"DA_NBR",
"SVC_ADDR1",
"SVC_ADDR2",
"SVC_CITY",
"SVC_STATE",
"SVC_ZIP",
"CUST_HOME_PHONE",
"CUST_CELL_PHONE",
"CUST_EMAIL_ADDR",
"_202001",
"_202002",
"_202003",
"_202004",
"_202005",
"_202006",
"_202007",
"_202008",
"_202009",
"_202010",
"_202011",
"_202012",
"_202101",
#"_202102",
"_2020_ANNUAL",
])

# loading input data
csv_df = CSV.File("data/input/ICF_MCL_MAY2021.csv", normalizenames=true) |> DataFrame
csv_df |> names |> println

slim_df = csv_df[!,keepcols]
slim_df

CSV.write("data/output/ICF_MCL_MAY2021-slim.csv", slim_df)