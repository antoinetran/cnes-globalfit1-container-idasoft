Prerequisite in CNES HPC:
* have ~/set_proxy.sh that set proxy

To build:

```
./build.sh -p ~/set_proxy.sh -o ~/cnes-lisa-globalfit1-idasoft-hpc.sif
```

Warning: do not put output directory to shared file-system. Eg: this command will not work.

```
./build.sh -p ~/set_proxy.sh -o /work/SC/lisa/cnes-lisa-globalfit1-idasoft-hpc.sif
```


