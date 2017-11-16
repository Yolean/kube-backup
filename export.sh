#!/bin/bash
set -e
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

EXPORT="$DIR/export"
echo "Exporting to $EXPORT"

namespaces=$(kubectl get namespaces -o=jsonpath='{.items[*].metadata.name}')

getexport() {
    N="$1"
    R="$2"

    type=$(echo $R | awk -F '/' '{ print $1 }')
    name=$(echo $R | awk -F '/' '{ print $2 }')
    [ -z "$N" ] && edir="$EXPORT/_/$type" || edir="$EXPORT/$N/$type"
    mkdir -p "$edir"
    echo -n "# ($type) $name, lines of yaml: "
    dest="$edir/$name"
    kubectl --namespace=$N get $R --export -o=yaml | tee "$dest.yml" | wc -l
    grep -q 'kubernetes.io/created-by:' "$dest.yml" && echo "# ... is a generated resource" && \
        mv "$dest.yml" "$dest.k8s-created.yml"
    : # don't exit on missing created-by
}

for N in $namespaces; do
    mkdir -p "$EXPORT/$N"
    
    all=$( \
      kubectl --namespace=$N get all -o=name; \
      kubectl --namespace=$N get configmap -o=name; \
      kubectl --namespace=$N get persistentvolumeclaim -o=name; \
    )
    echo "### namespace $N: $(echo "$all" | wc -l) resources"
    for R in $all; do
        getexport "$N" "$R"
    done

done

nonnamespaced=$( \
    kubectl --namespace=$N get persistentvolume -o=name; \
)
echo "### non-namespaced: $(echo "$all" | wc -l) resources"
for R in $nonnamespaced; do
    getexport "" "$R"
done

echo "Export completed to $EXPORT"
