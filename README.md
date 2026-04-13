# Test MPI Images

This repository contains container images and helper scripts for testing MPI workloads on systems that use CXI, libfabric, UCX, MPICH, and `mpi4py`.

## Repository Layout

- `container/ubuntu-24.04.Dockerfile`: CPU-focused Ubuntu 24.04 image
- `container/ubuntu-24.04-cuda-12.8.1.Dockerfile`: GPU-enabled Ubuntu 24.04 image based on `nvidia/cuda:12.8.1-devel-ubuntu24.04`
- `container/ubuntu-24.04-cuda-13.2.0-cudnn.Dockerfile`: GPU-enabled Ubuntu 24.04 image based on `nvidia/cuda:13.2.0-cudnn-devel-ubuntu24.04`
- `scripts/run.sh`: Parameterized Slurm launch script for CPU or GPU images
- `tests/test_mpi4py.py`: Multi-rank `mpi4py` test program

## Published Images

The GitHub Actions workflows publish images to GHCR:

- `ghcr.io/dingp/test-mpi-images:ubuntu-24.04`
- `ghcr.io/dingp/test-mpi-images:ubuntu-24.04-cuda-12.8.1`
- `ghcr.io/dingp/test-mpi-images:ubuntu-24.04-cuda-13.2.0-cudnn`

## Local Build Examples

```bash
docker build -f container/ubuntu-24.04.Dockerfile -t test-mpi-images:ubuntu-24.04 .
docker build -f container/ubuntu-24.04-cuda-12.8.1.Dockerfile -t test-mpi-images:ubuntu-24.04-cuda-12.8.1 .
docker build -f container/ubuntu-24.04-cuda-13.2.0-cudnn.Dockerfile -t test-mpi-images:ubuntu-24.04-cuda-13.2.0-cudnn .
```

## Running The Test

The helper script mounts the repository into `/scratch` inside the container and runs `tests/test_mpi4py.py`.

Examples:

```bash
scripts/run.sh cpu
scripts/run.sh cpu ghcr.io/dingp/test-mpi-images:ubuntu-24.04
scripts/run.sh gpu ghcr.io/dingp/test-mpi-images:ubuntu-24.04-cuda-12.8.1
scripts/run.sh gpu ghcr.io/dingp/test-mpi-images:ubuntu-24.04-cuda-13.2.0-cudnn
```
