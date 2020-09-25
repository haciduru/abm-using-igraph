
  # init the world
  G = init.w('/Users/haciduru/Downloads/dataverse_files/36-NY-cities-street_networks-node_edge_lists/3645073_Mannsville', 50)
  
  #init nodes; nodes should be initialized before agents
  nodes = init.nodes(G)

  # init agents
  agents = init.agents(G, 10, .2, nodes)
  nodes = update.nodes(agents, nodes)
    
  for (j in 1:10) for (i in 1:length(agents)) { agents[[i]] = move.agent(agents[[i]], nodes); nodes = agent.attack(agents[[i]], nodes) }; nodes = update.nodes(agents, nodes); nodes[,3]; nodes[,4]; nodes[,5]; plot(G, layout = layout_with_fr, vertex.label = '', vertex.size = (nodes$n_victim + .1), edge.arrow.size = .1, edge.color = 'black', edge.width = .5)
