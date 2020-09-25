# ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
# CREATE THE WORLD
# ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

setwd("...")

# import street segments/subsegments
# df_v = read.csv('hamilton_edges_3402_prj_split_by_100m.csv')
df_v = read.csv('edges_in_uptown_neig_buff_4miles.csv')
df_v = with(df_v, data.frame(osmid = osmid, to = to, from = from, uid = uid))
df_v = aggregate(cbind(to = to) ~ uid, data = df_v, function(x) 1)
df_v = within(df_v, rm(to))


# import intersections
df_e = read.csv('hamilton_edges_new.csv')
df_e = df_e[df_e$uid %in% df_v$uid | df_e$uid_2 %in% df_v$uid, ]
names(df_e) = c('u', 'v')

# get land use types and add them to the points data
land_use_c = read.csv('Land Use Codes - Hamilton County Auditor Dusty Rhodes.csv')
land_use_c = land_use_c[which(land_use_c$LAND_USE_C %!in% c(100, 110, 300, 400, 500, 501, 502, 503, 504, 505)), ]

# import land use data
df_l = read.csv('split_by_100_prj_points.csv')
df_l = merge(df_l, land_use_c)
df_l = df_l[which(df_l$CATEGORY != 'ABATED' & df_l$uid != 0), ]
df_l = aggregate(cbind(n = LAND_USE_C) ~ uid + CATEGORY, data = df_l, function(x) {NROW(x)})

# this file has numbers of different land use types on uid's
df_l = reshape(df_l, idvar = 'uid', timevar = 'CATEGORY', direction = 'wide')
names(df_l) = unlist(lapply(names(df_l), function(x) {
  if (substr(x, 1, 2) == 'n.') {
    x = tolower(substr(x, 3, nchar(x)))
    x = gsub(' ', '_', x)
  } else {
    x
  }
}))

# add land use data to vertices
df_v = merge(df_v, df_l, all = T)
df_v[is.na(df_v)] = 0

# create the graph
G = graph_from_data_frame(df_e)
G = as.undirected(G, mode = c("collapse"), 'ignore')
G = G - V(G)[which(degree(G) == 0)]
G = simplify(G, edge.attr.comb = list('ignore'))
G = decompose(G)
tmp = unlist(lapply(G, function(x) length(V(x))))
G = G[[which(tmp == max(tmp))]]

# remove vertices that are not in the G
df_v = df_v[df_v$uid %in% V(G)$name, ]

# initiate the world
rnodes = init.r.nodes()
anodes = init.a.nodes()

# some cleanup
rm(df_l, df_e, df_v, land_use_c, tmp)

agent.learning.rate = 10

tic(); agents = init.agents(1000, .05); toc()

citizens.on.nodes = update.c.on.nodes()
offenders.on.nodes = update.o.on.nodes()
victim.nodes = c()

uptown.nodes = read.csv('uptown_neig_edges_3402_prj_split_by_100m.csv')
uptown.nodes = uptown.nodes$uid

# ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
# END CREATE THE WORLD
# ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
