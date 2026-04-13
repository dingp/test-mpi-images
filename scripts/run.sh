#!/bin/bash
# Wrapper: resolves mode-specific Slurm resource flags and submits the job via sbatch.

set -euo pipefail

usage() {
  cat <<'USAGE'
Usage:
  scripts/run.sh <cpu|gpu> [image]

Examples:
  scripts/run.sh cpu
  scripts/run.sh cpu ghcr.io/dingp/test-mpi-images:ubuntu-24.04
  scripts/run.sh gpu ghcr.io/dingp/test-mpi-images:ubuntu-24.04-cuda-12.8.1
  scripts/run.sh gpu ghcr.io/dingp/test-mpi-images:ubuntu-24.04-cuda-13.2.0-cudnn
USAGE
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
    SBATCH_EXTRA=(--nodes=2 --ntasks-per-node=16 --qos=debug --constraint=cpu)
    SRUN_EXTRA=(--mpi=pmi2 --ntasks-per-node=16)
    CONTAINER_EXTRA=(-v /dev/cxi0:/dev/cxi0)
    ;;
  gpu)
    DEFAULT_IMAGE="ghcr.io/dingp/test-mpi-images:ubuntu-24.04-cuda-12.8.1"
    SBATCH_EXTRA=(--nodes=2 --ntasks=8 --gpus-per-task=1 --qos=debug --constraint=gpu)
    SRUN_EXTRA=(--mpi=pmi2 -n 8 -N 2 --gpus-per-task=1)
    CONTAINER_EXTRA=(
      -v /dev/cxi0:/dev/cxi0
      -v /dev/cxi1:/dev/cxi1
      -v /dev/cxi2:/dev/cxi2
      -v /dev/cxi3:/dev/cxi3
      -e MPICH_GPU_SUPPORT_ENABLED=1
    )
    ;;
  *)
    echo "Unsupported mode: ${MODE}" >&2
    usage >&2
    exit 1
    ;;
esac

IMAGE="${IMAGE:-$DEFAULT_IMAGE}"
WORKDIR="$PWD"

echo "Submitting ${MODE} job with image: ${IMAGE}"

# Common container options shared between cpu and gpu modes
CONTAINER_COMMON=(
  -e SLURM_* -e PALS_* -e PMI_*
  --ipc=host --network=host --pid=host
  --privileged
  -v /dev/shm:/dev/shm
  -v /dev/xpmem:/dev/xpmem
  -v /var/spool/slurmd:/var/spool/slurmd
  -v /run/munge:/run/munge
  -v /run/nscd:/run/nscd
  -v "${WORKDIR}:/scratch"
)

# Build the full srun command and serialize it for safe embedding in the job script
SRUN_CMD=(
  srun "${SRUN_EXTRA[@]}"
  podman-hpc shared-run --rm
  "${CONTAINER_COMMON[@]}"
  "${CONTAINER_EXTRA[@]}"
  "${IMAGE}" python3 /scratch/tests/test_mpi4py.py
)
SRUN_CMD_STR=$(printf '%q ' "${SRUN_CMD[@]}")

sbatch \
  --job-name=podman_mpi_test \
  --time=00:05:00 \
  --account=nstaff \
  --output=log_%j.out \
  --mail-type=end,fail \
  "${SBATCH_EXTRA[@]}" - <<EOF
#!/bin/bash
set -euo pipefail
${SRUN_CMD_STR}
EOF
