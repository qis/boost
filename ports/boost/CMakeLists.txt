cmake_minimum_required(VERSION 3.16)
project(boost LANGUAGES C CXX ASM_MASM)

# Create a b2 project config based on CMake toolchain settings.
set(config "${CMAKE_CURRENT_BINARY_DIR}/config.jam")
if(WIN32)
  if(CMAKE_CXX_COMPILER_ID STREQUAL Clang)
    file(WRITE ${config} "using clang-win : ${CMAKE_CXX_COMPILER_VERSION} : ")
  else()
    string(REGEX REPLACE "^([0-9]*)([0-9])$" "\\1.\\2" toolset_version "${MSVC_TOOLSET_VERSION}")
    file(WRITE ${config} "using msvc : ${toolset_version} : ")
  endif()
else()
  if(CMAKE_CXX_COMPILER_ID STREQUAL Clang)
    file(WRITE ${config} "using clang-linux : ${CMAKE_CXX_COMPILER_VERSION} : ")
  else()
    file(WRITE ${config} "using gcc : ${CMAKE_CXX_COMPILER_VERSION} : ")
  endif()
endif()

file(APPEND ${config} "\"${CMAKE_CXX_COMPILER}\" :\n")
file(APPEND ${config} "\n")

function(append name value)
  string(REPLACE "\"" "\\\"" quoted_value "${value}")
  file(APPEND ${config} "${name}\"${quoted_value}\"\n")
endfunction()

if(WIN32 AND DEFINED CMAKE_LINKER)
  append("<linker>" "\"${CMAKE_LINKER}\"")
  file(APPEND ${config} "\n")
endif()

append("<cflags>" "${CMAKE_C_FLAGS}")
append("<variant>debug:<cflags>" "${CMAKE_C_FLAGS_DEBUG}")
append("<variant>release:<cflags>" "${CMAKE_C_FLAGS_RELEASE}")
file(APPEND ${config} "\n")

if(CMAKE_CXX_STANDARD)
  if(CMAKE_CXX_STANDARD STREQUAL 98)
    append("<cxxstd>" "98")
  elseif(CMAKE_CXX_STANDARD STREQUAL 11)
    append("<cxxstd>" "11")
  elseif(CMAKE_CXX_STANDARD STREQUAL 14)
    append("<cxxstd>" "14")
  elseif(CMAKE_CXX_STANDARD STREQUAL 17)
    append("<cxxstd>" "17")
  elseif(CMAKE_CXX_STANDARD STREQUAL 20)
    append("<cxxstd>" "20")
  else()
    append("<cxxstd>" "latest")
  endif()
  if(NOT CMAKE_CXX_EXTENSIONS)
    append("<cxxstd-dialect>" "iso")
  endif()
endif()
append("<cxxflags>" "${CMAKE_CXX_FLAGS}")
append("<variant>debug:<cxxflags>" "${CMAKE_CXX_FLAGS_DEBUG}")
append("<variant>release:<cxxflags>" "${CMAKE_CXX_FLAGS_RELEASE}")
file(APPEND ${config} "\n")

if(BUILD_SHARED_LIBS)
  append("<linkflags>" "${CMAKE_CXX_FLAGS} ${CMAKE_SHARED_LINKER_FLAGS}")
  append("<variant>debug:<linkflags>" "${CMAKE_CXX_FLAGS_DEBUG} ${CMAKE_SHARED_LINKER_FLAGS_DEBUG}")
  append("<variant>release:<linkflags>" "${CMAKE_CXX_FLAGS_RELEASE} ${CMAKE_SHARED_LINKER_FLAGS_RELEASE}")
else()
  append("<linkflags>" "${CMAKE_CXX_FLAGS} ${CMAKE_STATIC_LINKER_FLAGS}")
  append("<variant>debug:<linkflags>" "${CMAKE_CXX_FLAGS_DEBUG} ${CMAKE_STATIC_LINKER_FLAGS_DEBUG}")
  append("<variant>release:<linkflags>" "${CMAKE_CXX_FLAGS_RELEASE} ${CMAKE_STATIC_LINKER_FLAGS_RELEASE}")
endif()
file(APPEND ${config} "\n;\n")

# Enable bzip2 support.
if(WITH_BZIP2)
  find_path(BZIP2_INCLUDE bzlib.h)
  if(NOT BZIP2_INCLUDE)
    message(FATAL_ERROR "Could not find bzip2 header: bzlib.h")
  endif()
  find_library(BZIP2_LIBRARY NAMES bz2 bz2d NAMES_PER_DIR)
  if(NOT BZIP2_LIBRARY)
    message(FATAL_ERROR "Could not find library: BZIP2")
  endif()
  get_filename_component(BZIP2_SEARCH ${BZIP2_LIBRARY} DIRECTORY)
  get_filename_component(BZIP2_NAME ${BZIP2_LIBRARY} NAME_WE)
  set(BZIP2_INCLUDE ${BZIP2_INCLUDE_DIR})
  file(APPEND ${config} "\nusing bzip2 : :\n")
  file(APPEND ${config} "<include>\"${BZIP2_INCLUDE}\"\n")
  file(APPEND ${config} "<search>\"${BZIP2_SEARCH}\"\n")
  file(APPEND ${config} "<name>\"${BZIP2_NAME}\"\n;\n")
endif()

# Enable lzma support.
if(WITH_LZMA)
  find_path(LZMA_INCLUDE lzma.h)
  if(NOT LZMA_INCLUDE)
    message(FATAL_ERROR "Could not find lzma header: lzma.h")
  endif()
  find_library(LZMA_LIBRARY NAMES lzma lzmad NAMES_PER_DIR)
  if(NOT LZMA_LIBRARY)
    message(FATAL_ERROR "Could not find library: LZMA")
  endif()
  get_filename_component(LZMA_SEARCH ${LZMA_LIBRARY} DIRECTORY)
  get_filename_component(LZMA_NAME ${LZMA_LIBRARY} NAME_WE)
  set(LZMA_INCLUDE ${LZMA_INCLUDE_DIR})
  file(APPEND ${config} "\nusing lzma : :\n")
  file(APPEND ${config} "<include>\"${LZMA_INCLUDE}\"\n")
  file(APPEND ${config} "<search>\"${LZMA_SEARCH}\"\n")
  file(APPEND ${config} "<name>\"${LZMA_NAME}\"\n;\n")
endif()

# Enable zlib support.
if(WITH_ZLIB)
  find_path(ZLIB_INCLUDE zlib.h)
  if(NOT ZLIB_INCLUDE)
    message(FATAL_ERROR "Could not find zlib header: zlib.h")
  endif()
  find_library(ZLIB_LIBRARY NAMES z zlib zlibd NAMES_PER_DIR)
  if(NOT ZLIB_LIBRARY)
    message(FATAL_ERROR "Could not find library: ZLIB")
  endif()
  get_filename_component(ZLIB_SEARCH ${ZLIB_LIBRARY} DIRECTORY)
  get_filename_component(ZLIB_NAME ${ZLIB_LIBRARY} NAME_WE)
  set(ZLIB_INCLUDE ${ZLIB_INCLUDE_DIR})
  file(APPEND ${config} "\nusing zlib : :\n")
  file(APPEND ${config} "<include>\"${ZLIB_INCLUDE}\"\n")
  file(APPEND ${config} "<search>\"${ZLIB_SEARCH}\"\n")
  file(APPEND ${config} "<name>\"${ZLIB_NAME}\"\n;\n")
endif()

# Enable zstd support.
if(WITH_ZSTD)
  find_path(ZSTD_INCLUDE zstd.h)
  if(NOT ZSTD_INCLUDE)
    message(FATAL_ERROR "Could not find zstd header: zstd.h")
  endif()
  find_library(ZSTD_LIBRARY NAMES zstd zstdd NAMES_PER_DIR)
  if(NOT ZSTD_LIBRARY)
    message(FATAL_ERROR "Could not find library: ZSTD")
  endif()
  get_filename_component(ZSTD_SEARCH ${ZSTD_LIBRARY} DIRECTORY)
  get_filename_component(ZSTD_NAME ${ZSTD_LIBRARY} NAME_WE)
  set(ZSTD_INCLUDE ${ZSTD_INCLUDE_DIR})
  file(APPEND ${config} "\nusing zstd : :\n")
  file(APPEND ${config} "<include>\"${ZSTD_INCLUDE}\"\n")
  file(APPEND ${config} "<search>\"${ZSTD_SEARCH}\"\n")
  file(APPEND ${config} "<name>\"${ZSTD_NAME}\"\n;\n")
endif()

# Set variant.
if(CMAKE_BUILD_TYPE STREQUAL Debug)
  set(variant debug)
  set(debug_symbols on)
else()
  set(variant release)
  set(debug_symbols off)
endif()

# Set linkage.
if(BUILD_SHARED_LIBS)
  set(link shared)
else()
  set(link static)
endif()

# Set runtime linkage.
if(CRT_LINKAGE STREQUAL static)
  set(runtime_link static)
else()
  set(runtime_link shared)
endif()

# Build and install boost.
add_custom_target(boost ALL ${B2}
  --layout=system
  --project-config=${config}
  --prefix=${CMAKE_INSTALL_PREFIX}
  --libdir=${CMAKE_INSTALL_PREFIX}/lib
  --exec-prefix=${CMAKE_INSTALL_PREFIX}/bin
  --includedir=${CMAKE_INSTALL_PREFIX}/$<$<CONFIG:Debug>:../>include
  --cmakedir=${CMAKE_INSTALL_PREFIX}/share/boost
  --build-dir=${CMAKE_CURRENT_BINARY_DIR}/build
  --without-graph_parallel
  --without-mpi
  --without-python
  --includedir=${INCLUDE_DIRECTORY}
  architecture=x86 address-model=64
  variant=${variant} threading=multi
  link=${link} runtime-link=${runtime_link}
  debug-symbols=${debug_symbols} install
  WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
  USES_TERMINAL)

# Install PDB files.
install(CODE [[
  file(GLOB_RECURSE PDB_FILES ${CMAKE_CURRENT_BINARY_DIR}/build/boost/bin.v2/libs/*/boost_*.pdb)
  if(PDB_FILES)
    file(INSTALL ${PDB_FILES} DESTINATION ${CMAKE_INSTALL_PREFIX}/bin)
  endif()
]])

# Install license.
install(FILES ${CMAKE_CURRENT_SOURCE_DIR}/LICENSE_1_0.txt DESTINATION share/boost RENAME copyright)
