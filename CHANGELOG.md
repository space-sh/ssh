# Space Module change log - ssh

## [2.0.1 - 2021-03-24]

* Fix bug when loading jump hosts via HOSTFILEs

* Fix os, file and string dependency versions


## [2.0.0 - 2021-01-19]

+ Add `HOSTFILE` argument to load jump host info from a .env file

+ Add documentation for `HOSTFILE`

* Inject `hostfile` argument before shell argument

* Make `host` an optional parameter, when using `hostfile`

* Change output to debug level


## [1.4.1 - 2020-02-24]

* Update documentation


## [1.4.0 - 2020-02-18]

+ Add `SSHTUNNEL` default value


## [1.3.1 - 2018-01-02]

* Change `BUILD_COMMAND` to use cross-platform `FILE_STAT`


## [1.3.0 - 2017-10-19]

+ Add `bits` parameter to `KEYGEN` function

* Update `BUILD_COMMAND` to print warning when stat is not available

- Remove default module behavior to avoid endless looping


## [1.2.0 - 2017-09-28]

+ Add `/tunnel/wrap_reverse`

+ Add a check to `SSH` function to verify all key file permissions before running


## [1.1.3 - 2017-06-11]

* Update documentation

* Change Arch Linux image for CI tests


## [1.1.2 - 2017-05-20]

* Rename expected local OUT variables

- Remove old `SUDO` behavior


## [1.1.1 - 2017-05-09]

* Update authorized key operations to create .ssh dir when adding and resetting


## [1.1.0 - 2017-04-26]

+ Add sshfs and tunneling

* Update auto completion

* Change `SPACE_SIGNATURE` to consider parameter constraints

* Update node descriptions

* Update include and clone statements


## [1.0.0 - 2017-04-12]

+ Initial version
