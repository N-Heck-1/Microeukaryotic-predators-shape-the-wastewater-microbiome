# Microeukaryotic Predators Shape the Wastewater Microbiome.

This repository contains data and scripts of the paper [Heck _et al._, 2023](). Making use of the scripts in the manner outlined in this description and the data files in [Original Data](https://github.com/N-Heck-1/Microeukaryotic-predators-shape-the-wastewater-microbiome/tree/main/original_data), the results and figures of said paper, as wel as the intermediary steps, can be recreated.
## Data access
[Prefetch](https://github.com/N-Heck-1/Microeukaryotic-predators-shape-the-wastewater-microbiome/tree/main/bash/prefetcher.sh) transcriptomic read data from the SRA.
A [script](https://github.com/N-Heck-1/Microeukaryotic-predators-shape-the-wastewater-microbiome/tree/main/bash/sra_getter.sh) to keep the working directory empty by moving not currently used sra files to a different drive.
Assessing read quality [using fastqc](https://github.com/N-Heck-1/Microeukaryotic-predators-shape-the-wastewater-microbiome/tree/main/bash/quality_controller.sh).
## Quality assessment and filter determination
