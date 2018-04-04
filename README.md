# STM32F4DISC RTE

This is a simple "Makefication" of [RTE](https://github.com/nucleron/RTE) nucleron project focused in [stm32f4-discovery board](http://www.st.com/en/evaluation-tools/stm32f4discovery.html).

# Configuring the environment to build

> This commands was testes just in 16.04.1-Ubuntu

The ficticious variable **${F4DISC_RTE_ROOT}** indicates the current directory where all tools described here is download


* Create the ${F4DISC_RTE_ROOT} directory

```shell
$ mkdir f4disk_rte  
$ cd f4disk_rte  
```

* Clone this project

```
$ git clone https://github.com/libopencm3/libopencm3.git
```

* Download the arm toolchain


```shell
$ wget https://developer.arm.com/-/media/Files/downloads/gnu-rm/7-2017q4/gcc-arm-none-eabi-7-2017-q4-major-linux.tar.bz2
```

* Clone matiec project


```shell
$ hg clone ssh://hg@bitbucket.org/mjsousa/matiec
```

* Clone libopencm3 project

```shell
$ git clone https://github.com/libopencm3/libopencm3.git
```

* Untar the ARM gcc toolchain and export the binaries to PATH

```shell
$ tar -xvf gcc-arm-none-eabi-7-2017-q4-major-linux.tar.bz2  
$ export PATH=$PWD/gcc-arm-none-eabi-7-2017-q4-major/bin/:$PATH  
$ arm-none-eabi-gcc --version  
```

* Build the libopencm3

```shell
$ cd libopencm3/  
$ make  
$ cd ..  
```

* Set some enviromnent variable to build this project

> You need to be in the ${F4DISC_RTE_ROOT}


```shell
$ export LIBOPENCM3_DIR=$PWD/libopencm3  
$ export MATIEC_C_INCLUDE_PATH=$PWD/matiec/lib/C  
``` 

* Build the project

The build will generate the .elf and .hex that can be upload to the f4disc board using dfu-util, stlink, openocd, etc...

```
$ cd f4disk_rte  
$ make
```
