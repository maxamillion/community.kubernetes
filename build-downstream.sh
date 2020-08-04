#!/bin/bash

# Hacky Proof of Concept to dual-home the upstream and downstream Collection
# in a single repo

# Array of excluded files from downstream build (relative path)
_file_exclude=(
)

# Files to copy downstream
_file_manifest=(
CHANGELOG.rst
galaxy.yml
LICENSE
README.md
)

# Directories to recursively copy downstream
_dir_manifest=(
changelogs
meta
plugins
)

# Temp build dir 
_build_dir=$(mktemp -d)

# Create the Collection
for f_name in ${_file_manifest[@]};
do
    cp ./${f_name} ${_build_dir}/${f_name}
done
for d_name in ${_dir_manifest[@]};
do
    cp -r ./${d_name} ${_build_dir}/${d_name}
done

# Switch FQCN
sed -i "s/name\:.*$/name: openshift/" ${_build_dir}/galaxy.yml
sed -i "s/namespace\:.*$/namespace: redhat/" ${_build_dir}/galaxy.yml
sed -i "s/Kubernetes/OpenShift/g" ${_build_dir}/galaxy.yml
find ${_build_dir} -type f -exec sed -i "s/community\.kubernetes/redhat\.openshift/g" {} \;

# Build the collection
pushd ${_build_dir}
ansible-galaxy collection build
popd

# Copy the Collection build result into original working dir
cp ${_build_dir}/*.tar.gz ./

# Remove the build dir
rm -r ${_build_dir}
