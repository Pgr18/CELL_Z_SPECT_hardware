#!/bin/bash

set -e -x

# Check for required arguments
if [ "$#" -ne 2 ]; then
    echo "Usage: $0 directory project_name"
    exit 1
fi

# Assign arguments to variables
project_dir=`realpath $1`
project_name=$2

# Construct the file paths
kicad_pcb="${project_dir}/${project_name}.kicad_pcb"
kicad_sch="${project_dir}/${project_name}.kicad_sch"

kibot_path=`realpath $(dirname $0)`/kibot.yaml

# Retrieve the latest Git tag or commit hash
GITTAG=$(git describe --always)

# Function to process the project
process_project() {
    mkdir -p ./${project_name}
    cd ./${project_name}
    
    mkdir -p solder
    mkdir -p gerber
    
    # Run electrical rule check with KiCad CLI
    kicad-cli sch erc "$kicad_sch" --exit-code-violations --severity-error
    kicad-cli pcb drc "$kicad_pcb" --exit-code-violations --severity-error
    
    # Export Bill of Materials
    kicad-cli sch export bom "$kicad_sch" --preset prod --format-preset CSV --exclude-dnp --output "solder/bom.csv"
    kicad-cli pcb export pos "$kicad_pcb" --format csv --units in --use-drill-file-origin --exclude-dnp --output "solder/${project_name}.pos"

    kibot -c $kibot_path -b "$kicad_pcb" -e "$kicad_sch"

    mv gerber.zip ../${project_name}-${GITTAG}-gerber.zip
    mv solder.zip ../${project_name}-${GITTAG}-solder.zip

    cd ..
}

# Call the process_project function
process_project

echo "Processing of ${project_name} complete."
