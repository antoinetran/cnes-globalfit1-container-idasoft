
####
# Build environment
####

#FROM ubuntu:22.04 as builder
FROM centos:7.9.2009 as builder

#RUN DEBIAN_FRONTEND=noninteractive apt-get update -y
RUN yum update -y

#RUN DEBIAN_FRONTEND=noninteractive apt-get install -y git cmake pip wget
# The loop does a second yum install to check that individual rpm that are missing in remote are counted as an error.
# We need latest cmake3 instead of cmake, and latest gcc*, thus devtoolset.
# See https://access.redhat.com/documentation/en-us/red_hat_developer_toolset/11/html/user_guide/chap-red_hat_developer_toolset#sect-Red_Hat_Developer_Toolset-Install
RUN yum install centos-release-scl epel-release -y \
  && rpms="bzip2 cmake3 devtoolset-11-toolchain git python3-pip wget" \
  && yum install ${rpms} -y \
  && for rpm in ${rpms} ; do yum install "${rpm}" -y ; done

RUN ln -s /usr/bin/cmake3 /usr/bin/cmake \
  && sclCreateProxy() { \
  cmd="$1" \
  sclName="$2" \
  && echo '#!/bin/sh' >/usr/bin/"${cmd}" \
  && echo exec scl enable "${sclName}" -- "${cmd}" \"\$@\" >>/usr/bin/"${cmd}" \
  && chmod 775 /usr/bin/"${cmd}" \
  ; } \
  && sclCreateProxy make devtoolset-11 \
  && sclCreateProxy gcc devtoolset-11 \
  && sclCreateProxy g++ devtoolset-11 \
  && sclCreateProxy gfortran devtoolset-11

# https://tlittenberg.github.io/ldasoft/html/md_gbmcmc_README.html#autotoc_md8
# Disable recent openmpi libomp-dev mpi mpi-default-dev because we use openmpi 3.1.4 for cluster compatibility.
# gsl is too old in Redhat/CentOs for ldasoft. 2.7.1 should be enough.
#RUN DEBIAN_FRONTEND=noninteractive apt-get install -y libgslcblas0  gsl-bin libgsl-dev libhdf5-dev
RUN rpms="libgomp hdf5-devel" \
  && yum install ${rpms} -y \
  && for rpm in ${rpms} ; do yum install "${rpm}" -y ; done

# set prefix for install directories
ARG LDASOFT_PREFIX
ENV LDASOFT_PREFIX=${LDASOFT_PREFIX:-/usr/local/lib/ldasoft}
ARG MBH_HOME
ENV MBH_HOME=${MBH_HOME:-/usr/local/lib/mbh}
ARG MPI_DIR
ENV MPI_DIR=${MPI_DIR:-/usr/local/lib/mpi}
ARG MANA_DIR
ENV MANA_DIR=${MANA_DIR:-/usr/local/lib/mana}
# See https://cmake.org/cmake/help/latest/module/FindGSL.html
ARG GSL_ROOT_DIR
ENV GSL_ROOT_DIR=${GSL_ROOT_DIR:-/usr/local/lib/gsl}

####
# MPICH
####

RUN rpms="libxml2-static libxml2-devel zlib-static xz-devel patch yum-utils" \
  && yum install ${rpms} -y \
  && for rpm in ${rpms} ; do yum install "${rpm}" -y ; done

RUN set -x && mkdir /tmp/xz-static && cd /tmp/xz-static \
  && wget http://vault.centos.org/7.9.2009/os/Source/SPackages/xz-5.2.2-1.el7.src.rpm \
  && mkdir liblzma_TEMP && cd liblzma_TEMP \
  && yumdownloader --source xz-devel \
  && rpm2cpio xz-*.src.rpm | cpio -idv \
  && find \
  && tar xf xz-*.tar.gz \
  && cd xz-5.2.2 \
  && patch -Np1 < ../xz-5.2.2-compat-libs.patch \
  && patch -Np1 < ../xz-5.2.2-man-page-day.patch \
  && ./configure --enable-static \
  && make -j install \
  && cp ./src/liblzma/.libs/liblzma.a /usr/lib64/

# To fix this error:
# configure: error: The Fortran compiler gfortran will not compile files that call the same routine with arguments of different types.
# see https://gcc.gnu.org/bugzilla/show_bug.cgi?id=91731
RUN mkdir /tmp/mpich && cd /tmp/mpich && wget https://www.mpich.org/static/downloads/3.3.2/mpich-3.3.2.tar.gz --no-check-certificate \
  && tar xf mpich-3.3.2.tar.gz \
  && cd mpich-3.3.2 \
  && export FFLAGS="-w -fallow-argument-mismatch -O2" \
  && ./configure --prefix=$MPI_DIR \
  && make -j install

#ENV PATH="${PATH}:/usr/lib64/mpich-3.2/bin"

ENV PATH="${PATH}:${MPI_DIR}/bin"


####
# MANA
####

RUN yum install glibc-static mlocate iproute vim -y

# Dirty workaround of Mana needing gzip >= 1.6 for "gzip --keep", but in CentOS7 we have gzip < 1.6.
RUN mv /usr/bin/gzip /usr/bin/gzip.orig \
  && writeGzip() { echo "$@" >>/usr/bin/gzip ; } \
  && writeGzip '#!/bin/sh' \
  && writeGzip 'i=0' \
  && writeGzip 'while test $((i+=1)) -lt "$#" ; do' \
  && writeGzip '  if test "$1" != "--keep" ; then' \
  && writeGzip '    set -- "$@" "$1"' \
  && writeGzip '    shift' \
  && writeGzip '  else' \
  && writeGzip '    set -- "$@"' \
  && writeGzip '    shift' \
  && writeGzip '  fi' \
  && writeGzip 'done' \
  && writeGzip 'exec gzip.orig "$@"' \
  && chmod 775 /usr/bin/gzip

RUN set -x && echo PATH = $PATH && type mpicc  && mpicc -v \
  && mkdir /tmp/mana && cd /tmp/mana && git clone https://github.com/mpickpt/mana.git -b main \
  && cd ./mana && export MANA_ROOT=$PWD \
  && git submodule update --init \
  && sed ./configure-mana -i -e 's,MANA_USE_LH_FIXED_ADDRESS=1$,MANA_USE_LH_FIXED_ADDRESS=1 "$@",g' \
  && sed mpi-proxy-split/lower-half/Makefile -i -e 's,2>&1,,g' -e 's,grep -q,grep,g' -e 's,if ${MPICC},set -x \&\& if ${MPICC},g' \
  && ./configure-mana --prefix="${MANA_DIR}" \
  && make mana \
  && make install

####
# OpenMPI
####
# Old OpenMPI because CNES cluster has old version.

#RUN mkdir /tmp/openmpi && cd /tmp/openmpi \
#  && wget https://download.open-mpi.org/release/open-mpi/v3.1/openmpi-3.1.4.tar.bz2 \
#  && tar xf openmpi-*.tar.bz2 \
#  && cd openmpi-* \
#  && ./configure --prefix=$MPI_DIR \
#  && make -j4 all >/dev/null \
#  && make install >/dev/null \
#  && cd .. && rm /tmp/openmpi -rf

#ENV PATH="${PATH}:${MPI_DIR}/bin"

####
# Gsl 2
####
RUN mkdir /tmp/gsl && cd /tmp/gsl \
  && wget https://mirror.ibcp.fr/pub/gnu/gsl/gsl-2.7.1.tar.gz \
  && tar xf gsl-* \
  && cd gsl-* \
  && mkdir "${GSL_ROOT_DIR}" -p \
  && ./configure --prefix="${GSL_ROOT_DIR}" \
  && make && make check && make install \
  && rm /tmp/gsl -rf

####
# MBH
####
RUN git clone https://github.com/eXtremeGravityInstitute/LISA-Massive-Black-Hole.git -b global-fit

RUN cd LISA-Massive-Black-Hole \
  && bash -x ./install.sh ${MBH_HOME}

####
# Globalfit1
####
RUN git clone https://github.com/tlittenberg/ldasoft \
  && cd ldasoft && git checkout 26e41dc9ab83a53f823869ad2e8da6ec0d96cf18

ADD ./container/ /container/

## Patches.
RUN rsync -a /container/ldasoft/ /ldasoft/

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
#FROM ubuntu:22.04
#FROM registry.access.redhat.com/ubi7/ubi:7.9-829.1665060345
FROM centos:7.9.2009

#RUN DEBIAN_FRONTEND=noninteractive apt-get install -y man-db sudo tmux tree vim
RUN yum update -y && yum install centos-release-scl epel-release -y \
  && rpms="man-db sudo vim" \
  && yum install ${rpms} -y \
  && for rpm in ${rpms} ; do yum install "${rpm}" -y ; done \
  && yum clean all

# Unminimize to get man pages. Image will be bigger!
#RUN DEBIAN_FRONTEND=noninteractive apt-get update -y && yes | unminimize
# See https://hub.docker.com/_/centos/ section "Package documentation"
# or https://superuser.com/questions/784451/centos-on-docker-how-to-install-doc-files
# We override the tsflags=nodocs to tsflags="" below directly in yum install.
RUN sed -i -e 's,tsflags=nodocs,tsflags=,g' /etc/yum.conf

# Epel in Redhat Ubi needs rpm install.
#RUN yum install https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm -y

# set prefix for install directories
ARG LDASOFT_PREFIX
ENV LDASOFT_PREFIX=${LDASOFT_PREFIX:-/usr/local/lib/ldasoft}
ARG MBH_HOME
ENV MBH_HOME=${MBH_HOME:-/usr/local/lib/mbh}
ARG MPI_DIR
ENV MPI_DIR=${MPI_DIR:-/usr/local/lib/mpi}
ARG MANA_DIR
ENV MANA_DIR=${MANA_DIR:-/usr/local/lib/mana}
ARG GSL_ROOT_DIR
ENV GSL_ROOT_DIR=${GSL_ROOT_DIR:-/usr/local/lib/gsl}

COPY --from=builder ${LDASOFT_PREFIX} ${LDASOFT_PREFIX}
COPY --from=builder ${MBH_HOME} ${MBH_HOME}
COPY --from=builder ${MPI_DIR} ${MPI_DIR}
COPY --from=builder /tmp/mana/mana ${MANA_DIR}
COPY --from=builder ${GSL_ROOT_DIR} ${GSL_ROOT_DIR}
COPY --from=builder /container /container

RUN for binFile in ${LDASOFT_PREFIX}/bin/* ${MBH_HOME}/bin/* ${MPI_DIR}/bin/* ${MANA_DIR}/bin/* ; do ln -s "${binFile}" /usr/bin/ ; done

# Adds the build libraries to system libraries path.
RUN echo "/usr/local/lib/gsl/lib" >/etc/ld.so.conf.d/container.conf \
  && ldconfig

# Runtime lib
# https://tlittenberg.github.io/ldasoft/html/md_gbmcmc_README.html#autotoc_md8
# Somehow, we also need hdf5 dev package or else pip install of lisacattools will fails asking HDF5_DIR directory.
# Disabled recent openmpi 4. See beyond. libomp5 openmpi-common openmpi-bin libopenmpi3 
#RUN DEBIAN_FRONTEND=noninteractive apt-get install -y libgslcblas0 gsl-bin libhdf5-dev
# ssh is needed for mpirun or else error: plm_rsh_agent: ssh : rsh
RUN rpms="libgomp hdf5 openssh-clients" \
  && yum install ${rpms} -y \
  && for rpm in ${rpms} ; do yum install "${rpm}" -y ; done \
  && yum install libgfortran5 libnl -y \
  && yum clean all

# https://tlittenberg.github.io/ldasoft/html/md_gbmcmc_README.html#autotoc_md9
#RUN DEBIAN_FRONTEND=noninteractive apt-get install -y python3-numpy python3-pandas python3-astropy python3-matplotlib python3-h5py python3-tables python3-pydot
#RUN DEBIAN_FRONTEND=noninteractive apt-get install -y pip && pip install chainconsumer

# Some python dependencies are already installed as OS package beyond.
# Workaround of https://github.com/tlittenberg/lisacattools/issues/13
# We install manually requirements, without pip version of astropy==4.2, that has the bug.
# See https://github.com/tlittenberg/lisacattools/blob/main/requirements.txt#L1
#RUN writeFile() { echo "$@" >>/tmp/lisacattools-req.txt ; } \
#  && writeFile corner==2.1.0 \
#  && writeFile healpy==1.14.0 \
#  && writeFile ligo.skymap==0.5.0 \
#  && writeFile seaborn==0.11.1
#RUN pip install -r /tmp/lisacattools-req.txt
#RUN pip install --no-deps lisacattools

