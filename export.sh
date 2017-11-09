#!/bin/bash
set -e
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

EXPORT="$DIR/export"
echo "Exporting to $EXPORT"

namespaces=$(kubectl get namespaces -o=jsonpath='{.items[*].metadata.name}')

for N in $namespaces; do
    mkdir -p "$EXPORT/$N"
    
    all=$(kubectl --namespace=$N get all -o=name)
    echo "### namespace $N: $(echo "$all" | wc -l) resources"
    for R in $all; do
        type=$(echo $R | awk -F '/' '{ print $1 }')
        name=$(echo $R | awk -F '/' '{ print $2 }')
        mkdir -p "$EXPORT/$N/$type"
        echo -n "# ($type) $name, lines of yaml: "
        kubectl --namespace=$N get $R --export -o=yaml | tee "$EXPORT/$N/$type/$name.yml" | wc -l
    done

done
echo "Export completed to $EXPORT"
