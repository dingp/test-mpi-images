#!/bin/bash
#SBATCH --job-name=podman_mpi_test_gpu
#SBATCH --time=00:05:00
#SBATCH --nodes=2
#SBATCH --qos=debug
#SBATCH --constraint=gpu
#SBATCH --account=nstaff
#SBATCH --output=log_gpu_%j.out


srun -n 8 -N 2 --gpus-per-task 1 --mpi=pmi2 podman-hpc shared-run --rm -e SLURM_* -e PALS_* -e PMI_* --ipc=host --network=host --pid=host --privileged -v /dev/shm:/dev/shm -v /dev/cxi0:/dev/cxi0 -v /dev/xpmem:/dev/xpmem -v /var/spool/slurmd:/var/spool/slurmd -v /run/munge:/run/munge -v /dev/cxi1:/dev/cxi1 -v /dev/cxi2:/dev/cxi2 -v /dev/cxi3:/dev/cxi3  -v /run/nscd:/run/nscd  -e MPICH_GPU_SUPPORT_ENABLED=1 -v $PWD:/scratch ghcr.io/dingp/ubuntu-nvidia:mpi4py-pmi2-v0 python3 /scratch/test_mpi4py.py

