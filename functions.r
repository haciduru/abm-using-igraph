
  library(igraph)

  '%!in%' = function(x,y)!('%in%'(x,y))
  
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
    G = simplify(G, edge.attr.comb = list(length = 'min', 'ignore'))
    
    return(decompose(G)[[1]])
    
  }

  agent.path = function(agent) return(row.names(as.matrix(unlist(shortest_paths(G, agent$loc, agent$enroute)$vpath))))
  
  init.agents = function(G, n_agents, p_offenders, nodes) {
    
   	agents = vector('list', n_agents)
    for (i in 1:n_agents) {
      agent = list(type = 'citizen', 
                   residence = sample(nodes[which(nodes$type == 'residence'), 'name'], 1),
                   activity.nodes = sample(nodes[which(nodes$type != 'intersection'), 'name'], 5),
                   location = '', enroute = '', motivation = 0, path = c())
      agent$activity.nodes = agent$activity.nodes[agent$activity.nodes %!in% agent$residence][1:4]
      agent$location = agent$residence
      agent$enroute = sample(agent$activity.nodes, 1)
      agent$path = agent.path(agent)[-1]
      agents[[i]] = agent
    }
    n_offenders = round(n_agents * p_offenders)
    for (i in 1:n_offenders) {
      agents[[i]]$type = 'offender'
      agents[[i]]$motivation = runif(1, 0, .05)
    }
    
    return(agents)
  }  
  
  move.agent = function(agent, nodes) {
    
    if (agent$location == agent$enroute) {
      agent = set.next.node(agent)
    } else {
      agent$location = agent$path[1]
      agent$path = agent$path[-1]
    }
    return(agent)
    
  }
  
  set.next.node = function(agent) {
    
    if (agent$location != agent$residence) {
      if (runif(1) < .8) {
        agent$enroute = agent$residence
      } else {
        agent$enroute = sample(agent$activity.nodes[agent$activity.nodes %!in% agent$location], 1)
      }
    } else {
      agent$enroute = sample(agent$activity.nodes[agent$activity.nodes %!in% agent$location], 1)
    }
    agent$path = agent.path(agent)[-1]
    return(agent)
    
  }
  
  update.nodes = function(agents, nodes) {

    nodes$n_offender = 0
    nodes$n_civilian = 0
    l = unlist(lapply(agents, function(x) x[x$type == 'offender']$location))
    for (i in 1:length(l)) nodes[which(nodes$name == l[[i]]), ]$n_offender = nodes[which(nodes$name == l[[i]]), ]$n_offender + 1
    l = unlist(lapply(agents, function(x) x[x$type == 'citizen']$location))
    for (i in 1:length(l)) nodes[which(nodes$name == l[[i]]), ]$n_civilian = nodes[which(nodes$name == l[[i]]), ]$n_civilian + 1
    return(nodes)

  }
  
  init.nodes = function(G) {
    
    nodes = data.frame(name = row.names(as.matrix(V(G))), 
                       type = ifelse(as.matrix(V(G)$residential), 'residence', 'non-residence'),
                       n_offender = 0, n_civilian = 0, n_victim = 0)
    nodes[which(substr(nodes$name, 1, 1) != 'r'), ]$type = 'intersection'
    return(nodes)
    
  }

  agent.attack = function(agent, nodes) {
    
    if (agent$type == 'offender' 
        & agent$location %!in% c(agent$activity.nodes, agent$residence) 
        & nodes[which(nodes$name == agent$location), 'type'] == 'residence') {
      neig = c(agent$location, row.names(as.matrix(neighbors(G, V(G)[agent$location]))))
      guardianship = sum(nodes[which(nodes$name %in% neig), 'n_civilian'])
      if (guardianship == 0) {
        if (runif(1) < agent$motivation) {
          # attack
          nodes[which(nodes$name == agent$location), 'n_victim'] = nodes[which(nodes$name == agent$location), 'n_victim'] + 1
        }
      }
    }
    return(nodes)
    
  }
