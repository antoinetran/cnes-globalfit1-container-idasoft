
####
# Build environment
####

FROM ubuntu:22.04 as builder

RUN DEBIAN_FRONTEND=noninteractive apt-get update -y

RUN DEBIAN_FRONTEND=noninteractive apt-get install -y git cmake pip wget

# https://tlittenberg.github.io/ldasoft/html/md_gbmcmc_README.html#autotoc_md8
# Disable recent openmpi libomp-dev mpi mpi-default-dev because we use openmpi 3.1.4 for cluster compatibility.
RUN DEBIAN_FRONTEND=noninteractive apt-get install -y libgslcblas0  gsl-bin libgsl-dev libhdf5-dev

# set prefix for install directories
ARG LDASOFT_PREFIX
ENV LDASOFT_PREFIX=${LDASOFT_PREFIX:-/usr/local/lib/ldasoft}
ARG MBH_HOME
ENV MBH_HOME=${MBH_HOME:-/usr/local/lib/mbh}
ARG MPI_DIR
ENV MPI_DIR=${MPI_DIR:-/usr/local/lib/omp}

####
# OpenMPI
####
# Old OpenMPI because CNES cluster has old version.

ADD https://download.open-mpi.org/release/open-mpi/v3.1/openmpi-3.1.4.tar.bz2 .
RUN tar xf openmpi-3.1.4.tar.bz2 \
    && cd openmpi-3.1.4 \
    && ./configure --prefix=$MPI_DIR \
    && make -j4 all \
    && make install \
    && cd .. && rm -rf \
    openmpi-3.1.4 openmpi-3.1.4.tar.bz2 /tmp/*

ENV PATH="${PATH}:${MPI_DIR}/bin"

####
# MBH
####
RUN git clone https://github.com/eXtremeGravityInstitute/LISA-Massive-Black-Hole.git -b global-fit

RUN cd LISA-Massive-Black-Hole \
  && bash -x ./install.sh ${MBH_HOME}

####
# Globalfit1
####
RUN git clone https://github.com/tlittenberg/ldasoft

ADD ./container/ /container/

## Patches to remove.
#RUN cp /container/GalacticBinaryWrapper.c /ldasoft/globalfit/src/GalacticBinaryWrapper.c -f \
#  && ls -al /ldasoft/globalfit/src/

# build codes
# add location of binaries to PATH
# Warning single quote will make an error. Use double-quote.
RUN cd ldasoft \
  && sed ./globalfit/src/CMakeLists.txt -i -e "s,^#include_directories.*,include_directories(\"${MBH_HOME}/include\"),g" \
  && sed ./globalfit/src/CMakeLists.txt -i -e "s,^#link_directories.*,link_directories(\"${MBH_HOME}/lib\"),g" \
  && cat ./globalfit/src/CMakeLists.txt \
  && find ${MBH_HOME}/lib \
  && MBH_DIR="${MBH_HOME}/lib/cmake/mbh" ./install.sh ${LDASOFT_PREFIX}

# https://docs.sylabs.io/guides/3.3/user-guide/mpi.html
RUN cd /container && mpicc -o mpitest mpitest.c && chmod 775 /container/mpitest
# https://www.open-mpi.org/faq/?category=running#diagnose-multi-host-problems
RUN cd /container && wget https://raw.githubusercontent.com/open-mpi/ompi/main/examples/ring_c.c \
  && mpicc -o ring_c ring_c.c && chmod 775 /container/ring_c

####
# Runtime image
####
FROM ubuntu:22.04

# set prefix for install directories
ARG LDASOFT_PREFIX
ENV LDASOFT_PREFIX=${LDASOFT_PREFIX:-/usr/local/lib/ldasoft}
ARG MBH_HOME
ENV MBH_HOME=${MBH_HOME:-/usr/local/lib/mbh}
ARG MPI_DIR
ENV MPI_DIR=${MPI_DIR:-/usr/local/lib/omp}

COPY --from=builder ${LDASOFT_PREFIX} ${LDASOFT_PREFIX}
COPY --from=builder ${MBH_HOME} ${MBH_HOME}
COPY --from=builder ${MPI_DIR} ${MPI_DIR}
COPY --from=builder /container /container

RUN for binFile in ${LDASOFT_PREFIX}/bin/* ${MBH_HOME}/bin/* ${MPI_DIR}/bin/* ; do ln -s "${binFile}" /usr/bin/ ; done

# Unminimize to get man pages. Image will be bigger!
RUN DEBIAN_FRONTEND=noninteractive apt-get update -y && yes | unminimize

RUN DEBIAN_FRONTEND=noninteractive apt-get install -y man-db sudo tmux tree vim

# Runtime lib
# https://tlittenberg.github.io/ldasoft/html/md_gbmcmc_README.html#autotoc_md8
# Somehow, we also need hdf5 dev package or else pip install of lisacattools will fails asking HDF5_DIR directory.
# Disabled recent openmpi 4. See beyond. libomp5 openmpi-common openmpi-bin libopenmpi3 
RUN DEBIAN_FRONTEND=noninteractive apt-get install -y libgslcblas0 gsl-bin libhdf5-dev

# https://tlittenberg.github.io/ldasoft/html/md_gbmcmc_README.html#autotoc_md9
RUN DEBIAN_FRONTEND=noninteractive apt-get install -y python3-numpy python3-pandas python3-astropy python3-matplotlib python3-h5py python3-tables python3-pydot
RUN DEBIAN_FRONTEND=noninteractive apt-get install -y pip && pip install chainconsumer

# Some python dependencies are already installed as OS package beyond.
# Workaround of https://github.com/tlittenberg/lisacattools/issues/13
# We install manually requirements, without pip version of astropy==4.2, that has the bug.
# See https://github.com/tlittenberg/lisacattools/blob/main/requirements.txt#L1
RUN writeFile() { echo "$@" >>/tmp/lisacattools-req.txt ; } \
  && writeFile corner==2.1.0 \
  && writeFile healpy==1.14.0 \
  && writeFile ligo.skymap==0.5.0 \
  && writeFile seaborn==0.11.1
RUN pip install -r /tmp/lisacattools-req.txt
RUN pip install --no-deps lisacattools

