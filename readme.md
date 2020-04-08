# Boost
[Vcpkg][vcpkg] [boost][boost] ports [overlay][overlay] that respects custom
[toolchains][toolchains] and installs CMake configuration files.

## Advantages
Advantages over the default vcpkg boost port are:

- Builds much faster.
- Installs working CMake configuration files.
- Uses the system layout (no more cryptic library names).
- Downloads all of boost at once instead of downloading single components.
- Uses compiler and compiler options set by the vcpkg toolchain.
- Generates `b2` configs that support MSVC, GCC and Clang.
- Respects the global `CMAKE_CXX_STANDARD` setting.

## Disadvantages
Disadvantages over the default vcpkg boost port are (patches welcome):

- Disables the `mpi` and `graph_parallel` components to reduce build times.
- Disables the `log` and `wave` components because they cannot be built using a C++20 toolchain.
- Disables the `python` component beacuse it is unclear which version to support.
- Only supports 64-bit triplets for Windows and Linux.
- Components cannot be built separately.

## How it Works
- [create.cmake](create.cmake) generates empty ports for all boost components.
- [boost/CMakeLists.txt](boost/CMakeLists.txt) configures boost and builds all supported components.
- [boost/portfile.cmake](boost/portfile.cmake) installs boost and patches generated CMake configuration files.

## Usage
Install [vcpkg](https://github.com/microsoft/vcpkg).

```cmd
cd C:\Workspace
git clone git@github.com:qis/boost ports
cmake -P ports/create.cmake
vcpkg install --overlay-ports=C:/Workspace/ports boost
```

[boost]: https://www.boost.org/
[vcpkg]: https://github.com/microsoft/vcpkg
[overlay]: https://github.com/microsoft/vcpkg/blob/master/docs/specifications/ports-overlay.md
[toolchains]: https://github.com/qis/toolchains
