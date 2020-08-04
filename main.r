
  setwd("...")
  
  edges = read.csv("edge_list.csv")
  nodes = read.csv("node_list.csv")
  nodes = with(nodes, data.frame(osmid = osmid))
  
  G = graph_from_data_frame(d = edges, vertices = nodes)
  
  tic()
  G = create.residential.units(G, 50, .3)
  toc()

  plot(G, layout = layout_with_fr,  
       vertex.label = '', 
       edge.arrow.size = .1, 
       # vertex.size = 3, 
       edge.color = 'black', 
       edge.width = .5)

  agents = init.agents(G, 10, .2)
