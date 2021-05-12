
include("SHOPBase.jl")

using Main.SHOPBase
plotly()

# loading input data
csv_df = CSV.File("data/input/ICF_MCL_MAY2021.csv", normalizenames=true) |> DataFrame
csv_df |> names |> print

months = ["_202001", "_202002", "_202003", "_202004", "_202005", "_202006", "_202007", 
        "_202008", "_202009", "_202010", "_202011", "_202012"]

monthly_usage = [ sum(csv_df[!,months[i]]) for i in 1:12 ]

baseline_usage = mean( sort(monthly_usage)[1:4] )

seasonal_usage = monthly_usage .- baseline_usage

M = DataFrame(seasonal_usage=seasonal_usage, baseline_usage=baseline_usage) |> Matrix

p = groupedbar(M, labels=["seasonal","baseline"], title="2020 Total Consumption", size=(1200,600), bar_position=:stack)

