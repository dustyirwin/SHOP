
gnnid = 1664757100
ins = @where(mcl_df, :GNN_ID .== gnnid)

for n in names(ins)
    println(n, " | ",ins[1,n][1])
end