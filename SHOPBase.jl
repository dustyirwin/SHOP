module SHOPBase

using Reexport

@reexport using DataFramesMeta
@reexport using LinearAlgebra
@reexport using ProgressMeter
@reexport using Statistics
@reexport using StatsPlots
@reexport using PlutoUI
@reexport using Plots
@reexport using CSV

@reexport using DarkMode

# column names to retain for slim version

column_names_df = CSV.File("data/input/MCL_Fields.csv", normalizenames=true) |> DataFrame
column_names = [ row["Fieldname"] for row in eachrow(column_names_df) if row["Keep"] == "Y" ]

end

