# 1.2.3 / 2015-10-07
* [BUGFIX] Fix exception when calculating similarity on empty resources

# 1.2.2 / 2015-04-24
* [BUGFIX] Fixed trailing "\n" in load commands

# 1.2.0 / 2015-04-01
* [FEATURE] Add ability to remove select tags for a resource

# 1.1.0 / 2015-04-01
* [FEATURE] Add ability to remove a resource from a group and recalculate similarity

# 1.0.0 / 2014-04-22
* [FEATURE] Add limits to similarity requests and bump to production release 1.0.0 :)

# 0.0.9 / 2014-04-09
* [BUGFIX] Fix similarity calculation for resources in many sets

# 0.0.8 / 2014-04-09
* [FEATURE] Allow degree of set membership to be included when adding data and incrementally increase scores when adding new data

# 0.0.7 / 2014-04-01
* [BUGFIX] Cope with sets of empty tags being set in TagSet

# 0.0.6 / 2014-04-01
* [FEATURE] Weighted groups now accept array of resources and return combined similarity scores

# 0.0.5 / 2014-03-31
* [FEATURE] Can now accept array of resources and return combined similarity scores

# 0.0.4 / 2014-03-31
* [FEATURE] Similarity score pushed down into redis using two different approaches depending on size of set

# 0.0.3 / 2014-03-31
* [FEATURE] Filtering of recommendations based on tags

# 0.0.2 / 2014-03-31
* [FEATURE] Weighted groups. Incremental additions. Deletions.

# 0.0.1 / 2014-03-28
* [FEATURE] Initial Release
