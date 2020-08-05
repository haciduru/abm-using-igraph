
    
  # init the world
  G = init.w('...', 50)
  
  plot(G, layout = layout_with_fr,  
       vertex.label = '',
       # vertex.label = substr(V(G)$name, nchar(V(G)$name) - 3, nchar(V(G)$name)),
       vertex.label.cex = 1,
       vertex.size = 1,
       edge.arrow.size = .1, 
       edge.color = 'black', 
       edge.width = .5)
  
    
  #init nodes
  nodes = data.frame(name = row.names(as.matrix(V(G))), n_offender = 0, n_civilian = 0)
  
  # init agents
  agents = init.agents(G, 10, .5, nodes)
