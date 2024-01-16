# DQ - Cluster Analysis #

## Description ##
The Cluster Analysis step enables you can compare pairs of rows within a single match cluster to determine whether each pair is really a match. This step helps you to score each record in a cluster to determine if a record in a cluster is a potential false positive or not.

* You can either run rules and set an individual score for each rule condition or
* You can use the rules to determine if a cluster rule was triggered for a record to match a cluster.

## User interface ##

* # Cluster Analysis tab #
   | Standalone mode | Flow mode |
   | --- | --- |                  
   | ![](img/CA-ClusterAnalisis.jpg) | ![](img/CA-ClusterAnalisis-FL.jpg) |
1. **Cluster ID column** - Set the cluster id for the cluster to analyse.
2. **Number of rules** - Set to the number of rules for the cluster analysis. Max number of rules is 5.
3. **Number of rule conditions** - Set to the number of condition for the rule. Max number of conditions is 8.
4. **Record 1 Field** - Set the column of the first record.
5. **Record 2 Field** - Set the column of the second record.
6. **Camparison** - Chose from the drop down list how to compare the two record fields.
7. **Score** - Set the score to be assigned if the condition is true. Default score is 10.

* # Options tab #
   | Use rules for cluster analysis |
   | --- |                  
   | ![](img/CA-Options.jpg) |
  
When using **Use rules for cluster analysis** the rules are used to analyse the clusters. Each record in a cluster will be compared with each other based on the rules.
A sore will be set for each rule condition that is true.
1. **Show condition score** - A score column for each rule condition will be added to the output table.
2. **Show rule score** - A score column for each rule will be added to the output table. The rule sore is the aggregated condition score for rule.
3. **Show total score** - A total score column will be added to the output table. The total score is the the aggregated rule score.

**Note:** The step is going to build a cartesian product for each cluster. All records in a cluster will be compared with each other. If clusters are big the cartesian product will be big and may result in a long run time.  

Use rules as cluster rules
