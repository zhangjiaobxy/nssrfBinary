#!/bin/bash

###############################################################################
# usage info:
if [ "$1" == "-h" ] ; then
    echo "Usage:           ./nssrf [SUBGRAPH_SIZE] [LABEL] [TOP_K_PERCENT] [DB_START] [DB_END] [QUERY_START] [QUERY_END]"
    echo "Example:         ./nssrf -2 m1 10 1 100 101 110"
    echo "[-h]:            help info"
    echo "[SUBGRAPH_SIZE]: 2, 3, 4 or 234 (234 indicates that feature is the combination of subgraph size 2, 3 and 4)"
    echo "[LABEL]:         m1, m2, m3 or m4 (m1: NETAL EC, m2: NETAL LCCS, m3: HubAlign EC, m4: HubAlign LCCS)"
    echo "[TOP_K_PERCENT]: top k percent similar networks"
    echo "[DB_START]:      integer number, it should be the smallest file name in the database"
    echo "[DB_END]:        integer number, it should be the largest file name in the database"
    echo "[QUERY_START]:   integer number, it should be the smallest file name in the query network set"
    echo "[QUERY_END]:     integer number, it should be the largest file name in the query network set"    
    exit 0
fi
     
###############################################################################
# step 1: run mfinder to get subgraph feature OUT files
# input:
#            ./data/rawData/
# output: 
#            ./data/mfinderFeature/*_subgraphSize_OUT.txt (mfinder output file)
# parameter: 
#            $1: subgraphSize (subgraphSize = 2, 3, 4 or 234)

cd ./sourceCode/  # go to sourceCode folder
python runMfinder.py $1  # generate mfinder OUT files for raw feature

###############################################################################
# step 2: featureExtract() function will extract subgraph features
# input: 
#            ./../data/mfinderFeature/*_OUT.txt
# output: 
#            ./../data/mfinderFeature/querySubgraphSize2.txt (querySubgraphSize3.txt, querySubgraphSize4.txt)
#            ./../data/mfinderFeature/dbSubgraphSize2.txt (dbSubgraphSize3.txt, dbSubgraphSize4.txt)
#            ./../data/mfinderFeature/querySubgraphSize2Feature.txt (querySubgraphSize3Feature.txt, querySubgraphSize4Feature.txt)
#            ./../data/mfinderFeature/dbSubgraphSize2Feature.txt (dbSubgraphSize3Feature.txt, dbSubgraphSize4Feature.txt)
#            ./../data/mfinderFeature/featureSize2.txt  (featureSize3.txt, featureSize4.txt)
# parameter:
#            $1: subgraphSize (subgraphSize = 2, 3, 4 or 234)
#            $5: dbEnd: the end range of database, it is the dividing line of the database and query set 

python featureExtract.py $1 $5 # generate subgraph feature, subgraph size can be 2, 3, 4 or 234

###############################################################################
# step 3: run labelExtract to get label files
# input: 
#            ./data/rawData/
# output: 
#            ./data/netalLabel (netal output file: *.eval files, netal_ec_label.txt, netal_lccs_label.txt)
#            ./data/hubLabel (hubalign output file: *.eval files, hubalign_ec_label.txt, hubalign_lccs_label.txt)
# parameter: 
#            $2: label (label = m1, m2, m3, m4;
#                     (note: m1: NETAL EC, m2: NETAL LCCS, m3: HubAlign EC, m4: HubAlign LCCS)
#            $4: dbStart: the start range of database
#            $5: dbEnd: the end range of database
#            $6: queryStart: the start range of query networks
#            $7: queryEnd: the end range of query networks

netal_ec="m1"
netal_lccs="m2"
hub_ec="m3"
hub_lccs="m4"
if [ "$2" == "$netal_ec" ] || [ "$2" == "$netal_lccs" ]; then
    bash runNetal.sh $4 $5 $6 $7
elif [ "$2" == "$hub_ec" ] || [ "$2" == "$hub_lccs" ]; then
	bash runHubalign.sh $4 $5 $6 $7
else
	echo "*********************************************************************"
	echo
	echo "Invalid label, system exit!"
	echo
	echo "*********************************************************************"
	exit
fi

###############################################################################
# step 4: get feature_lable csv file, it is the input csv file for random forest regression model
# input: 
#            ./../data/mfinderFeature/featureSize2.txt  (featureSize3.txt, featureSize2=4.txt)
#            ./../data/netalLabel/netal_ec_label.txt  (netal_lccs_label.txt, hubalign_ec_label.txt, hubalign_lccs_label.txt)
# output: 
#            ./../data/csvFeatureLabel/featureSize2_netal_ec_label.csv (...)
# parameter: 
#            $1: subgraphSize (subgraphSize = 2, 3, 4 or 234)
#            $2: label (label = m1, m2, m3, m4)
#                      (m1: NETAL EC, m2: NETAL LCCS, m3: HubAlign EC, m4: HubAlign LCCS)

python csvFeatureLabel.py $1 $2  # generate final csvfile

###############################################################################
# step 5: run random forest regression
# input: 
#            ./../data/csvFeatureLabel/featureSize2_netal_ec_label.csv (...)
# output: 
#            ./../data/output/topkNetwork.csv
# parameter: 
#            $1: subgraphSize (subgraphSize = 2, 3, 4 or 234)
#            $2: label (label = m1, m2, m3, m4)
#                      (m1: NETAL EC, m2: NETAL LCCS, m3: HubAlign EC, m4: HubAlign LCCS)
#            $3: topk (output top k percent similar networks)

python rfRegression.py $1 $2 $3  # train random forest model and perform query

###############################################################################

