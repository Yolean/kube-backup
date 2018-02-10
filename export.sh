#!/bin/bash
set -e
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

EXPORT="$DIR/export"
echo "Exporting to $EXPORT"
[ -d "$EXPORT" ] && PREVIOUS="$EXPORT.backup$(date +%FT%H%M%S)" && mv -v "$EXPORT" "$PREVIOUS"
mkdir "$EXPORT"

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
    kubectl --namespace=$N get $R --export -o=yaml \
      | sed "s/namespace: \"\"/namespace: \"$N\"/" \
      | tee "$dest.yml" \
      | wc -l
    grep -q 'kubernetes.io/created-by:' "$dest.yml" && echo "# ... is a managed resource" && \
        mv "$dest.yml" "$dest.k8s-created.yml"
    [ -f "$dest.yml" ] && grep -q 'deployment.kubernetes.io/desired-replicas:' "$dest.yml" && echo "# ... is a deployment resource" && \
        mv "$dest.yml" "$dest.k8s-created.yml"
    [ -f "$dest.yml" ] && grep -q 'generateName:' "$dest.yml" && echo "# ... is a generated resource" && \
        mv "$dest.yml" "$dest.k8s-created.yml"
    [ -f "$dest.yml" ] && grep -q 'ownerReference:' "$dest.yml" && echo "# ... is an owned resource" && \
        mv "$dest.yml" "$dest.k8s-created.yml"
    : # don't exit on missing created-by
}

crd=$( kubectl get crd -o=name | awk -F/ '{print $2}' )
echo "### CRDs: $(echo "$crd" | wc -l) resources"
for R in $crd; do
    getexport "" "customresourcedefinitions/$R"
done

nonnamespaced=$( \
    kubectl get persistentvolume -o=name; \
)
echo "### non-namespaced: $(echo "$nonnamespaced" | wc -l) resources"
for R in $nonnamespaced; do
    getexport "" "$R"
done

for N in $namespaces; do
    mkdir -p "$EXPORT/$N"
    
    all=$( \
      kubectl --namespace=$N get all -o=name; \
      kubectl --namespace=$N get configmap -o=name; \
      kubectl --namespace=$N get persistentvolumeclaim -o=name; \
    )
    for C in $crd; do
        all="$all $(kubectl --namespace=$N get $C -o=name)";
    done
    echo "### namespace $N: $(echo "$all" | wc -l) resources"
    for R in $all; do
        getexport "$N" "$R"
    done

done

git add -u "$EXPORT"
git add "$EXPORT"

echo "Export completed to $EXPORT"
