#!/bin/bash
#SBATCH --job-name=podman_mpi_test
#SBATCH --time=00:05:00
#SBATCH --nodes=2
#SBATCH --ntasks-per-node=16
#SBATCH --qos=debug
#SBATCH --constraint=cpu
#SBATCH --account=nstaff
#SBATCH --output=log_cpu_%j.out
#SBATCH --mail-type=end,fail

srun --mpi=pmi2 podman-hpc shared-run --rm -e SLURM_* -e PALS_* -e PMI_* --ipc=host --network=host --pid=host --privileged -v /dev/shm:/dev/shm -v /dev/cxi0:/dev/cxi0 -v /dev/xpmem:/dev/xpmem -v /var/spool/slurmd:/var/spool/slurmd -v /run/munge:/run/munge -v /run/nscd:/run/nscd  -v $PWD:/scratch ghcr.io/dingp/ubuntu:mpi4py-pmi2-v0 python3 /scratch/test_mpi4py.py
