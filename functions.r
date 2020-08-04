  library(igraph)
  library(tictoc)

  '%!in%' = function(x,y)!('%in%'(x,y))

  create.residential.units = function(G, rwidth, p_res) {
  
    G = as.undirected(G, mode = c("collapse"), 
                        edge.attr.comb = list(highway = 'max', 
                                              length = 'mean',
                                              lanes = 'max',
                                              width = 'mean',
                                              maxspeed = 'max',
                                              access = 'max',
                                              service = 'max',
                                              bridge = 'max',
                                              tunnel = 'max',
                                              area = 'mean',
                                              junction = 'max',
                                              osmid = 'max',
                                              'ignore'))
    V(G)$size = 3
    V(G)$res = F
    initial.n = length(E(G))

    ridx = 1
    i = 0
    while (i < initial.n) {
    
      i = i + 1
      if (E(G)[i]$length > rwidth) {
        
        res = ifelse(E(G)[i]$highway %in% c('residential', 'secondary', 'tetriary', NA)
                     & E(G)[i]$bridge %in% c('', 'no', NA) 
                     & E(G)[i]$tunnel %in% c('', 'no', NA) 
                     & E(G)[i]$junction %in% c('', NA)
                     & runif(1) < p_res, T, F)

        nres = round(E(G)[i]$length / rwidth)
        lres = E(G)[i]$length / (nres + 1)
        h = head_of(G, E(G)[i])$name
        t = tail_of(G, E(G)[i])$name
        
        v = paste('r', ridx, sep=".")
        ridx = ridx + 1
        
        if (res == T) {
          G = G + vertex(v, size = .5, res = T)
        } else {
          G = G + vertex(v, size = .5, res = F)
        }
        G = G + edge(h, v, length = lres)
        v.p = v
        
        if (nres > 1) {
          for (j in 2:nres) {
            v = paste('r', ridx, sep=".")
            ridx = ridx + 1
            
            if (res == T) {
              G = G + vertex(v, size = .5, res = T)
            } else {
              G = G + vertex(v, size = .5, res = F)
            }
            G = G + edge(v.p, v, length = lres)
            v.p = v
          }
        }
        
        G = G + edge(v, t)
      }
      
    }
  
    j = 1
    i = 0
    while (i < initial.n) {
      i = i + 1
      if (E(G)[j]$length > rwidth) {
        G = G - E(G)[j]
      } else {
        j = j + 1
      }
    }
    G = G - V(G)[which(degree(G) == 0)]
    
    return(decompose(G)[[1]])
  
  }  

  init.agents = function(G, n_agents, p_offenders) {
    
    residences = row.names(as.matrix(V(G)[res == T]))
    allnodes = unlist(lapply(row.names(as.matrix(V(G))), function(x) ifelse(substr(x, 1, 1) == 'r', x, NA)))
    allnodes = allnodes[!is.na(allnodes)]
    agents = vector('list', n_agents)
    for (i in 1:n_agents) {
      agent = list(type = 'citizen', res = sample(residences, 1), nodes = list(), loc = '', enroute = '')
      nodes = sample(allnodes, 5)
      agent$nodes = nodes[nodes %!in% agent$res][1:4]
      agent$loc = agent$res
      agent$enroute = sample(agent$nodes, 1)
      agents[[i]] = agent
    }
    n_offenders = round(n_agents * p_offenders)
    for (i in 1:n_offenders) agents[[i]]$type = 'offender'
    
    return(agents)
  }
