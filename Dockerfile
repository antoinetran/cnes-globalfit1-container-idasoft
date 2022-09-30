
####
# Build environment
####

FROM ubuntu:22.04 as builder

RUN DEBIAN_FRONTEND=noninteractive apt-get update -y

RUN DEBIAN_FRONTEND=noninteractive apt-get install -y git cmake pip

# https://tlittenberg.github.io/ldasoft/html/md_gbmcmc_README.html#autotoc_md8
RUN DEBIAN_FRONTEND=noninteractive apt-get install -y libgslcblas0  gsl-bin libgsl-dev libomp-dev mpi mpi-default-dev libhdf5-dev

# set prefix for install directories
ARG LDASOFT_PREFIX
ENV LDASOFT_PREFIX=${LDASOFT_PREFIX:-/usr/local/lib/ldasoft}
ARG MBH_HOME
ENV MBH_HOME=${MBH_HOME:-/usr/local/lib/mbh}

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

# build codes
# add location of binaries to PATH
# Warning single quote will make an error. Use double-quote.
RUN cd ldasoft \
  && sed ./globalfit/src/CMakeLists.txt -i -e "s,^#include_directories.*,include_directories(\"${MBH_HOME}/include\"),g" \
  && sed ./globalfit/src/CMakeLists.txt -i -e "s,^#link_directories.*,link_directories(\"${MBH_HOME}/lib\"),g" \
  && cat ./globalfit/src/CMakeLists.txt \
  && find ${MBH_HOME}/lib \
  && MBH_DIR="${MBH_HOME}/lib/cmake/mbh" ./install.sh ${LDASOFT_PREFIX}

####
# Runtime image
####
FROM ubuntu:22.04

# set prefix for install directories
ARG LDASOFT_PREFIX
ENV LDASOFT_PREFIX=${LDASOFT_PREFIX:-/usr/local/lib/ldasoft}
ARG MBH_HOME
ENV MBH_HOME=${MBH_HOME:-/usr/local/lib/mbh}

COPY --from=builder ${LDASOFT_PREFIX} ${LDASOFT_PREFIX}
COPY --from=builder ${MBH_HOME} ${MBH_HOME}

RUN for binFile in ${LDASOFT_PREFIX}/bin/* ${MBH_HOME}/bin/* ; do ln -s "${binFile}" /usr/bin/ ; done

# Unminimize to get man pages. Image will be bigger!
RUN DEBIAN_FRONTEND=noninteractive apt-get update -y && yes | unminimize

RUN DEBIAN_FRONTEND=noninteractive apt-get install -y man-db sudo tmux tree vim

# Runtime lib
# https://tlittenberg.github.io/ldasoft/html/md_gbmcmc_README.html#autotoc_md8
# Somehow, we also need hdf5 dev package or else pip install of lisacattools will fails asking HDF5_DIR directory.
RUN DEBIAN_FRONTEND=noninteractive apt-get install -y libgslcblas0 gsl-bin libomp5 openmpi-common openmpi-bin libopenmpi3 libhdf5-dev

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

