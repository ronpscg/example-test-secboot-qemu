# example-test-secboot-qemu
A repo with clear instructions how to reproduce and test some things from other projects, providing the OVMF code to make things easy.
In fact, this repository was opened just to keep the OVMF_CODE and OVMF_VARS somewhere, and to "protect you" against the notrious swtpm path length limitations.

This repo is not a standalone. It is used assuming you have the other repos.
If you were refereed to this repo **READ THIS README file!**

### Why this repo exists
**swtpm** has a limitation of 107 (or 108) characters of its real path, which is both annoying, and will waste time if you work with repositories with long name (in other words, if you took almost anything from the writer of these lines...).

So when you run the TPM testing script, if you run it, please clone it to some place with a short name.

### Components
- OVMF_CODE.md and OVMF_VARS.md are used for secure boot
- Scripts for running QEMU and TPM - but careful - I don't guarantee that I will update it. You would better see the other repo (TODO maybe link to it if it is kept open-sourced)

## Required packages
We tested on Ubuntu 24.04 and 25.04. It should work on 22.04 as well.
We assume you have the `swtpm` and `qemu-system` packages installed.

## Starting point
For the sake of this exmaple, we will assume that the following variables are exported or set in the same line before you run the scripts:
- `IMAGE_BASENAME` - the name of your Yocto Project build target
- `MACHINE` - the name of the Yocto Machine
- `YOCTO_BUILD_DIR` - the path to the *build* directory where your Yocto Project was built (where `oe-init-build-env` was referred to).

For example, you would be at the starting point after (replace the variables with your relevant ones)
```
# replace the following values with whatever is relevant for you
export IMAGE_BASENAME=signing-wip
export MACHINE=intel-corei7-64
export YOCTO_BUILD_DIR=$HOME/yocto/my-build

# assume oe-init-build-env was already setup, or alternatively that you are in a kas shell, so that the command would be identical...
# use kas alternatively... e.g. kas build $KAS_CONFIG_FILE_YAML
cd $YOCTO_BUILD_DIR
bitbake $IMAGE_BASENAME
```

This will give you the images.
Then, you have already repackaged the images, e.g. (using the same exported variables as before)
```
cd scripts/yocto
./yocto-copy-artifacts.sh
```

So now you have the relevant artifacts under *$YOCTO_BUILD_DIR/tmp/deploy/images/$MACHINE/secure-boot-work/artifacts*
It is a link to a folder with the respective build DATETIME, and we will use it as is, so if you build again, be careful about it.

## Running the emulator
Let's assume for the sake of discussion that you cloned this repository into *$HOME/example-test-secboot-qemu*, and exported the environment variables as listed before.
You will run with:
``` 
cd $HOME/example-test-secboot-qemu
./scripts/yocto/tests/qemu-tpm-bitbake.sh  disk --serial mon:stdio 
```

You can remove the `--serial mon:stdio` argument or replace it with `-nographic` to account for no serial, or no display, respectively.

**Basic troubleshooting:** If you run into resource taken errors, just `pkill tpm` 

**Files changing under source control:** Don't worry about *OVMF_VARS* and *tpm-state*. These are state values. You are not supposed to commit the changes, but you may if you want to, for your own purposes. *OVMF_VARS* was included to have you started without any challenge. *tpm-state* is created in the first time you run swtpm
