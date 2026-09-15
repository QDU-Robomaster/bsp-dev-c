# Local static-assembly candidate

This BSP uses the exported local Module sources under Modules and the generated
User/xrobot_main.hpp. The matching LibXR source lives in ../../libxr relative to
this BSP. Configure with the BSP's normal CMake toolchain and pass
`-DLIBXR_SOURCE_DIR=<absolute path to that checkout>`.

Do not run an online module update against unpublished feature branches and
assume it reproduces these uncommitted sources. The checked-in package requests
specify the planned matching branch; only a real publication can make those
branches remotely fetchable. No lockfile falsely representing these dirty
sources by an older commit has been created. Exact local inputs and generated
firmware are recorded in the task's evidence and build/firmware directories.

The original CodeGenerator user blocks are preserved except for the explicit
old entry/container calls that were migrated. The current generated static
entry requires the matching candidate XRobot tools, not the old installed pip
release. Build/test remain native; no new command frontend is required.

No firmware has been flashed or certified on hardware by this task.
