#!/bin/bash
set -x

echo "Extracting project names from misp and magenta repositories: "
#for i in {1..10}
#do
#  echo "Getting repos for misp in group halo at page: ${i}"
#  curl -H "Content-Type: application/json"  --header "PRIVATE-TOKEN:" "https://misp.t-systems.com/tools/gitlab/api/v4/groups/halo/projects?page=$i&page_limit=100" | jq ' .[] | (.id | tostring)+ " "+.path' >> misp-inf.txt
#  echo "Getting repos for magenta in group halo at page : ${i}"
#  curl -H "Content-Type: application/json"  --header "PRIVATE-TOKEN: " "https://gitlab.devops.telekom.de/api/v4/groups/halo/projects?page=$i&page_limit=100" | jq '.[] | (.id | tostring)+ " "+.path' >> magenta-inf.txt
#done

while read line; do
  # reading each line and removing quotes
  magenta_l=$(echo ${line} | sed 's/^.//;s/.$//')
  # getting magenta_repo name from magenta_l
  magenta_get_repo=$(echo $magenta_l  | sed 's/.*[[:blank:]]//')
  echo "get repo : ${magenta_get_repo}"
  # getting magenta_repo id from magenta_l
  magenta_get_id=$(echo $magenta_l | sed 's/ .*//')
  # grep magenta_get_repo name in misp-inf.txt
  misp_search=$(cat misp-inf.txt | grep -E "${magenta_get_repo}\"")
  echo "misp_search value : $misp_search"
  # remove quotes in misp_search
  misp_remove_quotes=$(echo $misp_search | sed 's/^.//;s/.$//')
  # get misp repo id
  misp_get_id=$(echo $misp_remove_quotes | sed 's/ .*//')
  echo "get id : $misp_get_id"
  # get misp_repo name
  misp_repo=$(echo $misp_remove_quotes  | sed 's/.*[[:blank:]]//')
  # Check for repo name or if empty
  if [[  $magenta_get_repo != $misp_repo ]] || [[ $misp_repo == ""  ]]
  then
    echo "magenta repo : $magenta_get_repo" >> missing.txt
    echo "misp repo : $misp_repo" >> missing.txt
    continue
  fi

  # get protected_branches for a particular misp project
  get_branches=$(curl -H "Content-Type: application/json"  --header "PRIVATE-TOKEN: " "https://misp.t-systems.com/tools/gitlab/api/v4/projects/${misp_get_id}/protected_branches" | jq -r ' .[] .name')
  # loop over branch names
  for b in $get_branches
  do
    # check if branch has / in it's name 	  
    if [[ "$b" == *"/"* ]]
    then
      # Add %2F in place of /    
      b=$(echo $b | sed 's/\//%2F/')
    fi
    # fresh register, for which delete target magenta repo protected_branch 
    echo "Delete branch ${b}, if already present on magenta"
    curl --request DELETE --header "PRIVATE-TOKEN: " "https://gitlab.devops.telekom.de/api/v4/projects/"${magenta_get_id}"/protected_branches/${b}" 
    echo "Get push count"
    # Get push count on misp_repo
    push=$(curl -H "Content-Type: application/json"  --header "PRIVATE-TOKEN: " "https://misp.t-systems.com/tools/gitlab/api/v4/projects/"$misp_get_id"/protected_branches/$b" | jq -r '.push_access_levels[].access_level')
    echo "Get Merge count"
    # Get merge_count on misp_repo
    merge=$(curl -H "Content-Type: application/json"  --header "PRIVATE-TOKEN: " "https://misp.t-systems.com/tools/gitlab/api/v4/projects/"${misp_get_id}"/protected_branches/"${b}"" | jq -r '.merge_access_levels[].access_level')
    # Register protected_branch in magenta_repo
    curl --request POST --header "PRIVATE-TOKEN: " "https://gitlab.devops.telekom.de/api/v4/projects/"${magenta_get_id}"/protected_branches?name=${b}&push_access_level=${push}&merge_access_level=${merge}"
    sleep 10
  done
  # Add magenta_repo names in conpleted_migration.txt file
  echo "Completed for $magenta_get_repo" >> completed_migration.txt
# Done reading file
done < magenta-inf.txt

# Get projects in group jdp
# curl -H "Content-Type: application/json"  --header "PRIVATE-TOKEN: " "https://misp.t-systems.com/tools/gitlab/api/v4/groups/jdp/projects" | jq ' .[] | (.id | tostring)+ " "+.path' >> misp-jdp-inf.txt

#while read line; do
#  misp_l=$(echo ${line} | sed 's/^.//;s/.$//')
#  misp_get_repo=$(echo $misp_l  | sed 's/.*[[:blank:]]//')
#  echo "get repo : ${misp_get_repo}"
#  misp_get_id=$(echo $misp_l | sed 's/ .*//')
#  magenta_search=$(cat magenta-inf.txt | grep -E "${misp_get_repo}\"")
#  echo "magenta_search value : $magenta_search"
#  magenta_remove_quotes=$(echo $magenta_search | sed 's/^.//;s/.$//')
#  magenta_get_id=$(echo $magenta_remove_quotes | sed 's/ .*//')
#  echo "get id : $magenta_get_id"
#  magenta_repo=$(echo $magenta_remove_quotes  | sed 's/.*[[:blank:]]//')
#  if [[  $misp_get_repo != $magenta_repo ]] || [[ $magenta_repo == ""  ]]
#  then
#    echo "magenta repo : $magenta_repo" >> missing-jdp.txt
#    echo "misp repo : $misp_get_repo" >> missing-jdp.txt
#    continue
#  fi
#  get_branches=$(curl -H "Content-Type: application/json"  --header "PRIVATE-TOKEN: " "https://misp.t-systems.com/tools/gitlab/api/v4/projects/${misp_get_id}/protected_branches" | jq -r ' .[] .name')
#  for b in $get_branches
#  do
#    if [[ "$b" == *"/"* ]]
#    then
#      b=$(echo $b | sed 's/\//%2F/')
#    fi
#    echo "Delete branch ${b}, if already present on magenta"
#    curl --request DELETE --header "PRIVATE-TOKEN: " "https://gitlab.devops.telekom.de/api/v4/projects/"${magenta_get_id}"/protected_branches/${b}"
#    echo "Get push count"
#    push=$(curl -H "Content-Type: application/json"  --header "PRIVATE-TOKEN: " "https://misp.t-systems.com/tools/gitlab/api/v4/projects/"$misp_get_id"/protected_branches/$b" | jq -r '.push_access_levels[].access_level')
#    echo "Get Merge count"
#    merge=$(curl -H "Content-Type: application/json"  --header "PRIVATE-TOKEN: " "https://misp.t-systems.com/tools/gitlab/api/v4/projects/"${misp_get_id}"/protected_branches/"${b}"" | jq -r '.merge_access_levels[].access_level')
#   curl -s --request POST --header "PRIVATE-TOKEN: " "https://gitlab.devops.telekom.de/api/v4/projects/"${magenta_get_id}"/protected_branches?name=${b}&push_access_level=${push}&merge_access_level=${merge}"
#    sleep 5
#  done
#  echo "Completed for $magenta_repo" >> completed_migration_jdp.txt
#done < misp-jdp-inf.txt	
