FROM ubuntu:22.04 as builder

RUN DEBIAN_FRONTEND=noninteractive apt-get update -y

RUN DEBIAN_FRONTEND=noninteractive apt-get install -y git cmake pip

# https://tlittenberg.github.io/ldasoft/html/md_gbmcmc_README.html#autotoc_md8
RUN DEBIAN_FRONTEND=noninteractive apt-get install -y libgslcblas0  gsl-bin libgsl-dev libomp-dev mpi mpi-default-dev libhdf5-dev

RUN git clone https://github.com/tlittenberg/ldasoft

# set prefix for install directories
ARG LDASOFT_PREFIX
ENV LDASOFT_PREFIX=${LDASOFT_PREFIX:-/usr/local/lib/ldasoft}
ARG MBH_HOME
ENV MBH_HOME=${MBH_HOME:-/usr/local/lib/mbh}

# build codes
# add location of binaries to PATH 
RUN cd ldasoft \
  && ./install.sh ${LDASOFT_PREFIX}

RUN for binFile in ${LDASOFT_PREFIX}/bin/* ; do ln -s "${binFile}" /usr/bin/ ; done

RUN git clone https://github.com/eXtremeGravityInstitute/LISA-Massive-Black-Hole.git -b global-fit

RUN cd LISA-Massive-Black-Hole \
  && bash -x ./install.sh ${MBH_HOME}

FROM ubuntu:22.04

# set prefix for install directories
ARG LDASOFT_PREFIX
ENV LDASOFT_PREFIX=${LDASOFT_PREFIX:-/usr/local/lib/ldasoft}
ARG MBH_HOME
ENV MBH_HOME=${MBH_HOME:-/usr/local/lib/mbh}

COPY --from=builder ${LDASOFT_PREFIX} ${LDASOFT_PREFIX}
COPY --from=builder ${MBH_HOME} ${MBH_HOME}

RUN DEBIAN_FRONTEND=noninteractive apt-get update -y

RUN DEBIAN_FRONTEND=noninteractive apt-get install -y tree

# Runtime lib
# https://tlittenberg.github.io/ldasoft/html/md_gbmcmc_README.html#autotoc_md8
# Somehow, we also need hdf5 dev package or else pip install of lisacattools will fails asking HDF5_DIR directory.
RUN DEBIAN_FRONTEND=noninteractive apt-get install -y libgslcblas0 gsl-bin libomp5 mpi libhdf5-dev

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

