
rm(list = ls())
library(igraph)
library(tictoc)

setwd("...")

'%!in%' = function(x,y)!('%in%'(x,y))

agent.learning.rate = 10

agent.path = function(agent) return(row.names(as.matrix(unlist(shortest_paths(G, agent$loc, agent$enroute)$vpath))))

# create a named list of all residential nodes
init.r.nodes = function() {
  
  nodes = as.data.frame(get.vertex.attribute(G))
  nodes[is.na(nodes)] = 0
  rnodes = nodes[nodes$residential > 0, ]
  rnodes$utility = 1 / rnodes$residential * runif(nrow(rnodes)) + 1
  rnodes = data.frame(name = rnodes$name, val = rnodes$utility)
  rnodes = setNames(rnodes$val, rnodes$name)
  return(rnodes)

}

# create a named list of all activity nodes
init.a.nodes = function() {
  
  nodes = as.data.frame(get.vertex.attribute(G))
  nodes[is.na(nodes)] = 0
  nodes$anodes = nodes$commercial + nodes$industrial + nodes$publicly_owned + nodes$residential
  anodes = nodes[nodes$anodes > 0, ]
  anodes = data.frame(name = anodes$name, val = anodes$anodes)
  anodes = setNames(anodes$val, anodes$name)
  return(anodes)
  
}

init.agents = function(n_agents, p_offenders) {
  
  agents = vector('list', n_agents)
  for (i in 1:n_agents) {
    agent = list(type = 'citizen', 
                 residence = sample(names(rnodes), 1),
                 activity.nodes = sample(names(anodes), 5),
                 location = '', enroute = '', motivation = 0,
                 path = c(), memory = c())
    agent$activity.nodes = agent$activity.nodes[agent$activity.nodes %!in% agent$residence][1:4]
    agent$location = agent$residence
    agent$enroute = sample(agent$activity.nodes, 1)
    agent$path = agent.path(agent)[-1]
    agents[[i]] = agent
  }
  n_offenders = round(n_agents * p_offenders)
  for (i in 1:n_offenders) {
    agents[[i]]$type = 'offender'
    agents[[i]]$motivation = runif(1, 0, .01)
  }
  return(agents)
  
}  

move.agent = function(agent) {
  
  if (agent$location == agent$enroute) {
    agent = set.next.node(agent)
  } else {
    if (substr(agent$path[1], 1, 1) != 'r') agent$path = agent$path[-1]
    agent$location = agent$path[1]
    agent$path = agent$path[-1]
    if (agent$location %in% names(agent$memory)) {
      agent$memory[agent$location] <- agent$memory[agent$location] + 1
    } else {
      agent$memory[agent$location] <- 1 
    }
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

# create a named list of all nodes with citizen agents
update.c.on.nodes = function() table(unlist(lapply(agents, function(x) { if (x$type == 'citizen') x$location })))

# create a named list of all nodes with offender agents
update.o.on.nodes = function() table(unlist(lapply(agents, function(x) { if (x$type == 'offender') x$location })))

agent.attack = function(agent) {
  
  if (agent$type == 'offender' 
      & agent$location %!in% c(agent$activity.nodes, agent$residence) 
      & agent$location %in% names(rnodes)) {
    neig = c(agent$location, row.names(as.matrix(neighbors(G, V(G)[agent$location]))))
    guardianship = sum(names(citizens.on.nodes) %in% neig)
    if (guardianship == 0) {
      awareness = 1 / (1 + exp(-(agent$memory[agent$location] / agent.learning.rate)))
      p_attack = agent$motivation * (rnodes[agent$location] + 1) * awareness
      if (runif(1) < p_attack) {
        # attack
        if (agent$location %in% names(victim.nodes)) {
          victim.nodes[agent$location] <<- victim.nodes[agent$location] + 1
        } else {
          victim.nodes[agent$location] <<- 1
        }
        # and go home
        agent$enroute = agent$residence
        agent$path = agent.path(agent)
      }
    }
  }
  return(agent)

}

G = read.graph('hamilton_abm.graphml', format = 'graphml')
G = delete_graph_attr(G, 'rdix')
G = delete_vertex_attr(G, 'id')

# plot(G, layout = layout.kamada.kawai(G), vertex.label = '', vertex.label.size = 1, vertex.size = .5, edge.arrow.size = .1, edge.color = 'black', edge.width = .5)

# initiate the world
rnodes = init.r.nodes()
anodes = init.a.nodes()

tic(); agents = init.agents(1000, .05); toc()

citizens.on.nodes = update.c.on.nodes()
offenders.on.nodes = update.o.on.nodes()
victim.nodes = c()

for (i in 1:1000) {
  tic(i)
  agents = lapply(agents, function(x) move.agent(x))
  agents = lapply(agents, function(x) agent.attack(x))
  citizens.on.nodes = update.c.on.nodes()
  offenders.on.nodes = update.o.on.nodes()
  toc()
}
table(victim.nodes)
table(citizens.on.nodes)
table(offenders.on.nodes)

# get uid's of nodes with victimized residences
vuid = data.frame(uid = V(G)[names(victim.nodes)]$uid, dum = 1)
write.csv(vuid, 'victim.txt', row.names = F)

# get uid's of nodes where offenders live
ouid = data.frame(uid = V(G)[unlist(lapply(agents, function(x) if (x$type == 'offender') x$residence))]$uid, dum = 1)
write.csv(ouid, 'offenders.txt', row.names = F)

# get uid's of nodes where citizens live
cuid = data.frame(uid = V(G)[unlist(lapply(agents, function(x) if (x$type == 'citizen') x$residence))]$uid, dum = 1)
write.csv(cuid, 'citizens.txt', row.names = F)




