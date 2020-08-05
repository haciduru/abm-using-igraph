
  library(igraph)

  '%!in%' = function(x,y)!('%in%'(x,y))
  
  init.agents = function(G, n_agents, p_offenders) {
    
    residences = row.names(as.matrix(V(G)[res == T]))
    allnodes = unlist(lapply(row.names(as.matrix(V(G))), function(x) ifelse(substr(x, 1, 1) == 'r', x, NA)))
    allnodes = allnodes[!is.na(allnodes)]
    agents = vector('list', n_agents)
    for (i in 1:n_agents) {
      agent = list(type = 'citizen', res = sample(residences, 1), nodes = list(), loc = '', enroute = '', path = c())
      nodes = sample(allnodes, 5)
      agent$nodes = nodes[nodes %!in% agent$res][1:4]
      agent$loc = agent$res
      agent$enroute = sample(agent$nodes, 1)
      agent$path = agent.path(agent)[-1]
      agents[[i]] = agent
    }
    n_offenders = round(n_agents * p_offenders)
    for (i in 1:n_offenders) agents[[i]]$type = 'offender'
    
    return(agents)
  }  
  
  add.r.nodes = function(G, e, residential, minL = 50) {
    if (e$length > minL) {
      h = as.character(e$h)
      t = as.character(e$t)
      nres = floor(e$length / minL)
      lres = e$length / nres
      v.p = h
      for (i in 1:nres) {
        v = paste('r.', G$rdix, sep='')
        G = G + vertex(v, residential = ifelse(runif(1) < .5, F, T))
        G = G + edge(v.p, v, length = lres, directed = T)
        v.p = v
        G$rdix = G$rdix + 1
      }
      G = G + edge(v, t, length = lres, directed = T)
      G = G - E(G)[get.edge.ids(G, c(h, t))]
    }
    return(G)
  }
  
  init.w = function(path, minL = 50) {
    
    epath = paste(path, '/edge_list.csv', sep = '')
    edges = read.csv(epath)
    G = graph_from_data_frame(d = edges)
    G = as.undirected(G, mode = c("collapse"), 
                      edge.attr.comb = list(highway = 'max', 
                                            length = 'mean',
                                            # lanes = 'max',
                                            # width = 'mean',
                                            # maxspeed = 'max',
                                            # access = 'max',
                                            # service = 'max',
                                            bridge = 'max',
                                            tunnel = 'max',
                                            # area = 'mean',
                                            junction = 'max',
                                            # osmid = 'max',
                                            'ignore'))
    V(G)$residential = F
    E(G)$residential = F
    E(G)[highway %in% c('residential', 'secondary', 'tetriary', NA)
         & bridge %in% c('', 'no', NA) 
         & tunnel %in% c('', 'no', NA) 
         & junction %in% c('', NA)]$residential = T

    G$rdix = 1
    Es = data.frame(t = row.names(as.matrix(tail_of(G, E(G)[which(E(G)$length > 50)]))),
                    h = row.names(as.matrix(head_of(G, E(G)[which(E(G)$length > 50)]))),
                    length = E(G)[which(E(G)$length > 50)]$length,
                    residential = E(G)[which(E(G)$length > 50)]$residential
    )
    for (i in 1:nrow(Es)) {
      G = add.r.nodes(G, Es[i,], minL)
    }
    G = G - V(G)[which(degree(G) == 0)]
    return(decompose(G)[[1]])
    
  }

  agent.path = function(agent) {
    
    loc = agent$loc
    enroute = agent$enroute
    return(row.names(as.matrix(unlist(shortest_paths(G, loc, enroute)$vpath))))
    
  }
  
  init.agents = function(G, n_agents, p_offenders, nodes) {
    
    residences = row.names(as.matrix(V(G)[residential == T]))
    allnodes = unlist(lapply(row.names(as.matrix(V(G))), function(x) ifelse(substr(x, 1, 1) == 'r', x, NA)))
    allnodes = allnodes[!is.na(allnodes)]
    agents = vector('list', n_agents)
    for (i in 1:n_agents) {
      agent = list(type = 'citizen', res = sample(residences, 1), anodes = list(), loc = '', enroute = '', path = c())
      anodes = sample(allnodes, 5)
      agent$anodes = anodes[anodes %!in% agent$res][1:4]
      agent$loc = agent$res
      agent$enroute = sample(agent$anodes, 1)
      agent$path = agent.path(agent)[-1]
      agents[[i]] = agent
    }
    n_offenders = round(n_agents * p_offenders)
    for (i in 1:n_offenders) agents[[i]]$type = 'offender'
    for (i in 1:n_agents) update.node(agents[[i]], nodes, '+')

    return(agents)
  }  
  
  move.agent = function(agent, nodes) {
    
    if (agent$loc != agent$enroute) {
      update.node(agent, nodes, '-')
      agent$loc = agent$path[1]
      update.node(agent, nodes, '+')
      agent$path = agent$path[-1]
    } else {
      agent = set.next.node(agent)
    }
    return(agent)
    
  }
  
  set.next.node = function(agent) {
    
    if (agent$loc != agent$res) {
      if (runif(1) < .8) {
        agent$enroute = agent$res
      } else {
        agent$enroute = sample(agent$anodes[agent$anodes %!in% agent$loc], 1)
      }
    } else {
      agent$enroute = sample(agent$anodes[agent$anodes %!in% agent$loc], 1)
    }
    agent$path = agent.path(agent)[-1]
    return(agent)
    
  }
  
  update.node = function(agent, nodes, sign) {
    if (agent$type == 'offender') {
      nodes[which(nodes$name == agent$loc), 'n_offender'] <<- ifelse(sign == '+', 
                                                                     nodes[which(nodes$name == agent$loc), 'n_offender'] + 1,
                                                                     nodes[which(nodes$name == agent$loc), 'n_offender'] - 1
                                                                     )
    } else {
      nodes[which(nodes$name == agent$loc), 'n_civilian'] <<- ifelse(sign == '+', 
                                                                     nodes[which(nodes$name == agent$loc), 'n_civilian'] + 1,
                                                                     nodes[which(nodes$name == agent$loc), 'n_civilian'] - 1
                                                                     )
    }
  }
