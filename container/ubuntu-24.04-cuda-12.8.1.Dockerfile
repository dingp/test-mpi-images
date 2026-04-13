FROM docker.io/nvidia/cuda:12.8.1-devel-ubuntu24.04

RUN apt-get update \
    && DEBIAN_FRONTEND=noninteractive \
       apt-get install -y \
        build-essential \
        ca-certificates \
        pkg-config \
        automake \
        autoconf \
        libtool \
        cmake \
        gdb \
        strace \
        wget \
        git \
        bzip2 \
        python3 \
        python3-pip \
        python3-venv \
        python3-dev \
        gfortran \
        rdma-core \
        numactl \
        libconfig-dev \
        libuv1-dev \
        libfuse-dev \
        libfuse3-dev \
        libyaml-dev \
        libnl-3-dev \
        libnuma-dev \
        libsensors-dev \
        libcurl4-openssl-dev \
        libjson-c-dev \
        libibverbs-dev \
        --no-install-recommends \
    && rm -rf /var/lib/apt/lists/*

# Install XPMEM
# Use commit according to Spack package versioning rule:
# https://github.com/spack/spack/blob/develop/var/spack/repos/spack_repo/builtin/packages/xpmem/package.py#L28
ARG xpmem_ref=0d0bad4e1d07b38d53ecc8f20786bb1328c446da
RUN git clone https://github.com/hpc/xpmem.git \
    && cd xpmem \
    && git checkout ${xpmem_ref} \
    && ./autogen.sh \
    && ./configure --prefix=/usr --with-default-prefix=/usr --disable-kernel-module \
    && make -j$(nproc) \
    && make install \
    && cd .. \
    && rm -r xpmem

ARG GDRCOPY_VER=2.5
RUN git clone --depth 1 --branch v${GDRCOPY_VER} https://github.com/NVIDIA/gdrcopy.git \
    && cd gdrcopy \
    && export CUDA_PATH=${CUDA_HOME:-$(echo $(which nvcc) | grep -o '.*cuda')} \
    && make CC=gcc CUDA=$CUDA_PATH lib \
    && make lib_install \
    && cd ../ && rm -rf gdrcopy

ARG cassini_headers_version=release/shs-12.0.1
RUN git clone --branch ${cassini_headers_version} --depth 1 https://github.com/HewlettPackard/shs-cassini-headers.git \
    && cd shs-cassini-headers \
    && cp -r include/* /usr/include/ \
    && cp -r share/* /usr/share/ \
    && cd .. \
    && rm -r shs-cassini-headers

ARG cxi_driver_version=release/shs-12.0.1
RUN git clone --branch ${cxi_driver_version} --depth 1 https://github.com/HewlettPackard/shs-cxi-driver.git \
    && cd shs-cxi-driver \
    && cp -r include/* /usr/include/ \
    && cd .. \
    && rm -r shs-cxi-driver

ARG libcxi_version=release/shs-12.0.1
RUN git clone --branch ${libcxi_version} --depth 1 https://github.com/HewlettPackard/shs-libcxi.git \
    && cd shs-libcxi \
    && ./autogen.sh \
    && ./configure --prefix=/usr --with-cuda=/usr/local/cuda \
    && make -j$(nproc) \
    && make install \
    && ldconfig \
    && cd .. \
    && rm -r shs-libcxi

# Install libfabric
ARG libfabric_version=2.1.0
RUN git clone --branch v${libfabric_version} --depth 1 https://github.com/ofiwg/libfabric.git \
    && cd libfabric \
    && ./autogen.sh \
    && ./configure --prefix=/usr --with-cuda=/usr/local/cuda --enable-cuda-dlopen --enable-gdrcopy-dlopen --enable-xpmem=/usr --enable-cxi --enable-lnx --enable-efa \
    && make -j$(nproc) \
    && make install \
    && ldconfig \
    && cd .. \
    && rm -rf libfabric

# Install UCX
ARG UCX_VERSION=1.18.1
RUN wget -q https://github.com/openucx/ucx/releases/download/v${UCX_VERSION}/ucx-${UCX_VERSION}.tar.gz \
    && tar xzf ucx-${UCX_VERSION}.tar.gz \
    && cd ucx-${UCX_VERSION} \
    && mkdir build \
    && cd build \
    && ../configure --prefix=/usr --with-cuda=/usr/local/cuda --with-gdrcopy=/usr/local --enable-mt --enable-devel-headers \
    && make -j$(nproc) \
    && make install \
    && cd ../.. \
    && rm -rf ucx-${UCX_VERSION}.tar.gz ucx-${UCX_VERSION}

# Install mpich
ARG MPI_VER=4.3.1
RUN wget -q https://www.mpich.org/static/downloads/${MPI_VER}/mpich-${MPI_VER}.tar.gz \
    && tar xf mpich-${MPI_VER}.tar.gz \
    && cd mpich-${MPI_VER} \
    && ./autogen.sh \
    && ./configure --prefix=/usr --enable-fast=O3,ndebug \
       --disable-fortran --disable-cxx \
       --with-device=ch4:ofi --with-libfabric=/usr \
       --with-cuda=/usr/local/cuda \
       CFLAGS="-L/usr/local/cuda/targets/sbsa-linux/lib/stubs/ -lcuda" \
       CXXFLAGS="-L/usr/local/cuda/targets/sbsa-linux/lib/stubs/ -lcuda" \
    && make -j$(nproc) \
    && make install \
    && ldconfig \
    && cd .. \
    && rm -rf mpich-${MPI_VER}.tar.gz mpich-${MPI_VER}

ARG mpi4py=4.1.0
ENV LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/usr/local/cuda-12.8/compat/:/usr/local/cuda-12.8/targets/x86_64-linux/lib/stubs
RUN MPICC="mpicc -shared" pip install --force --no-cache-dir --break-system-packages --no-binary=mpi4py mpi4py==$mpi4py

