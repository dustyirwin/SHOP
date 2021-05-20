module SHOPBase

using Reexport

@reexport using DataDrivenDiffEq
@reexport using ModelingToolkit
@reexport using OrdinaryDiffEq
@reexport using DataFramesMeta
@reexport using LinearAlgebra
@reexport using ProgressMeter
@reexport using Transformers
@reexport using Statistics
@reexport using StatsPlots
@reexport using PlutoUI
#@reexport using AMDGPU  # no Windows support :(
@reexport using Plots
@reexport using Flux
#@reexport using CUDA
@reexport using CSV

@reexport using DarkMode


# column names to retain for slim version

#column_names_df = CSV.File("data/input/MCL_Fields.csv", normalizenames=true) |> DataFrame
#column_names = [ row["Fieldname"] for row in eachrow(column_names_df) if row["Keep"] == "Y" ]

end

