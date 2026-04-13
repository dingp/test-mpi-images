#!/bin/bash
#SBATCH --job-name=podman_mpi_test
#SBATCH --time=00:05:00
#SBATCH --nodes=2
#SBATCH --account=nstaff
#SBATCH --output=log_%j.out
#SBATCH --mail-type=end,fail

set -euo pipefail

usage() {
  cat <<'EOF'
Usage:
  sbatch scripts/run.sh <cpu|gpu> [image]

Examples:
  sbatch scripts/run.sh cpu
  sbatch scripts/run.sh cpu ghcr.io/dingp/test-mpi-images:ubuntu-24.04
  sbatch scripts/run.sh gpu ghcr.io/dingp/test-mpi-images:ubuntu-24.04-cuda-12.8.1
  sbatch scripts/run.sh gpu ghcr.io/dingp/test-mpi-images:ubuntu-24.04-cuda-13.2.0-cudnn
EOF
}

MODE="${1:-}"
IMAGE="${2:-}"

if [[ -z "${MODE}" ]]; then
  usage >&2
  exit 1
fi

case "${MODE}" in
  cpu)
    DEFAULT_IMAGE="ghcr.io/dingp/test-mpi-images:ubuntu-24.04"
    SRUN_ARGS=(--ntasks-per-node=16 --qos=debug --constraint=cpu)
    CONTAINER_ARGS=(
      -e SLURM_* -e PALS_* -e PMI_*
      --ipc=host --network=host --pid=host
      --privileged
      -v /dev/shm:/dev/shm
      -v /dev/cxi0:/dev/cxi0
      -v /dev/xpmem:/dev/xpmem
      -v /var/spool/slurmd:/var/spool/slurmd
      -v /run/munge:/run/munge
      -v /run/nscd:/run/nscd
      -v "$PWD:/scratch"
    )
    ;;
  gpu)
    DEFAULT_IMAGE="ghcr.io/dingp/test-mpi-images:ubuntu-24.04-cuda-12.8.1"
    SRUN_ARGS=(-n 8 -N 2 --gpus-per-task=1 --qos=debug --constraint=gpu)
    CONTAINER_ARGS=(
      -e SLURM_* -e PALS_* -e PMI_*
      --ipc=host --network=host --pid=host
      --privileged
      -v /dev/shm:/dev/shm
      -v /dev/cxi0:/dev/cxi0
      -v /dev/cxi1:/dev/cxi1
      -v /dev/cxi2:/dev/cxi2
      -v /dev/cxi3:/dev/cxi3
      -v /dev/xpmem:/dev/xpmem
      -v /var/spool/slurmd:/var/spool/slurmd
      -v /run/munge:/run/munge
      -v /run/nscd:/run/nscd
      -e MPICH_GPU_SUPPORT_ENABLED=1
      -v "$PWD:/scratch"
    )
    ;;
  *)
    echo "Unsupported mode: ${MODE}" >&2
    usage >&2
    exit 1
    ;;
esac

IMAGE="${IMAGE:-$DEFAULT_IMAGE}"

echo "Running mode: ${MODE}"
echo "Using image: ${IMAGE}"

srun --mpi=pmi2 "${SRUN_ARGS[@]}" \
  podman-hpc shared-run --rm \
  "${CONTAINER_ARGS[@]}" \
  "${IMAGE}" python3 /scratch/tests/test_mpi4py.py
