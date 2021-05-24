
using CSV
using DataFramesMeta

keep_cols = DataFrame(CSV.File("data/input/MCL_Fields.csv"))[!,:Fieldname]

MCL_old = CSV.File("data/input/Old_MCL.csv", normalizenames=true) |> DataFrame;
MCL_old |> names |> print
MCL_old = select(MCL_old, intersect(keep_cols, MCL_old |> names))

MCL_2020 = CSV.File("data/input/mcl_2020.csv", normalizenames=true) |> DataFrame;
MCL_2020 |> names |> print
MCL_2020 = select(MCL_2020, intersect(keep_cols, MCL_2020 |> names))


MCL_2021 = CSV.File("data/input/ICF_MCL_MAY2021.csv", normalizenames=true) |> DataFrame;
MCL_2021 |> names |> print
MCL_2021 = select(MCL_2021, intersect(keep_cols, MCL_2021 |> names))


combo_df = outerjoin(
    MCL_2020 |> dropmissing, 
    MCL_2021 |> dropmissing,
    on = intersect(names(MCL_2020), names(MCL_2021))
    )

out_df = outerjoin(
    combo_df, 
    MCL_old |> dropmissing, 
    on = intersect(names(combo_df), names(MCL_old))
    )

out_df = unique(out_df, :GNN_ID)

write("data/output/MCL_Combined_201912-202102-slim-description.txt", describe(out_df, :all, sum=>:sum) |> string)
CSV.write("data/output/MCL_Combined_201912-202102-slim.csv", out_df)


GC.gc()