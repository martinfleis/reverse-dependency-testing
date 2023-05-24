#!/bin/bash

# fail on undefined variables
set -u
# Prevent pipe errors to be silenced
set -o pipefail
# Exit if any command exit as non-zero
# set -e
# enable trace mode (print what it does)
# set -x

cd /tmp

micromamba repoquery whoneeds $INPUT_PACKAGE_NAME -c conda-forge > whoneeds.txt

python get_yml.py

micromamba install -y -n base -f reverse.yaml

cd $GITHUB_WORKSPACE

eval $INPUT_INSTALLATION_COMMAND

cd /tmp

# Read packages from packages.txt file
packages=$(cat packages.txt)

counter=0
# Get the total number of packages
total=${#packages[@]}

# Declare variables for each category
passed=""
failed=""
no_tests=""

# Loop through each package and run pytest with pyargs option
for package in $packages
do
    ((counter++))
    echo -e "\n$counter/$total: Running pytest for $package\n"

    pytest --color yes --tb=no --disable-warnings -n auto --pyargs $package

    # Get the exit code
    exit_code=$?

    if [ $exit_code -eq 0 ]; then
        passed+="$package "
    elif [ $exit_code -eq 1 ]; then
        failed+="$package "
    elif [ $exit_code -eq 5 ]; then
        no_tests+="$package "
    fi

done

# Print the summary
echo -e "\n\e[35m======================= reverse dependency tests summary =======================\n"
echo -e "\e[32mPASSED: $passed"
echo -e "\e[31mFAILED: $failed"
echo -e "\e[33mNO TESTS COLLECTED: $no_tests"