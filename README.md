# abm-using-igraph
This project will be a replication of Birks, Daniel, and Davies, Toby (2017). "Street network structure and crime risk: An agent-based investigation of the encounter and enclosure hypotheses," Criminology, 55(4): 900-937. 

Birks and Davies (2017) use NetLogo software to create their virtual world. I will use R, igraph, and data from Geoff Boeing's repository, here: https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/F5UNSK. Weblinks occasionally disappear. Thus, here is the article's full reference where Boeing describes his dataset: Boeing, G. (2019). Street Network Models and Measures for Every U.S. City, County, Urbanized Area, Census Tract, and Zillow-Defined Neighborhood. Urban Science, 3(1). http://dx.doi.org/10.3390/urbansci3010028.

*edges_in_uptown_neig_buff_4miles.csv* has the street segments (and subsegments) in the target neighborhoods and the neighborhoods within a four-mile buffer zone.

*uptown_neig_edges_3402_prj_split_by_100m.csv* has the street segments (and subsegments) in the target neighborhoods.

*Land Use Codes - Hamilton County Auditor Dusty Rhodes* is a list of all (I assume) land-use types in Hamilton County.

*split_by_100_prj_points.csv* has all land-uses in Hamilton County, OH.
