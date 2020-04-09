# Parse boost version.
file(READ ${CMAKE_CURRENT_LIST_DIR}/CONTROL CONTROL)
string(REGEX MATCH "Version: ([0-9\.]+)" _ ${CONTROL})
set(BOOST_VERSION ${CMAKE_MATCH_1})

string(REPLACE "." "_" BOOST_VERSION_NAME ${BOOST_VERSION})

vcpkg_download_distfile(ARCHIVE
  URLS "https://dl.bintray.com/boostorg/release/${BOOST_VERSION}/source/boost_${BOOST_VERSION_NAME}.7z"
  FILENAME "boost_${BOOST_VERSION_NAME}.7z"
  SHA512 96ce928d490a84d76ef54b0f90780d23eeff4b1d79d7a00e4bee51e791b0f8e65eecc5578c86f49c2f791fb670826c114304d40ce097537431bf23ba587c2cae
)

vcpkg_extract_source_archive_ex(
  OUT_SOURCE_PATH SOURCE_PATH
  ARCHIVE ${ARCHIVE}
  REF "${BOOST_VERSION}")

set(WITH_BZIP2 OFF)
if(bzip2 IN_LIST FEATURES)
  set(WITH_BZIP2 ON)
endif()

set(WITH_LZMA OFF)
if(lzma IN_LIST FEATURES)
  set(WITH_LZMA ON)
endif()

set(WITH_ZLIB OFF)
if(zlib IN_LIST FEATURES)
  set(WITH_ZLIB ON)
endif()

set(WITH_ZSTD OFF)
if(zstd IN_LIST FEATURES)
  set(WITH_ZSTD ON)
endif()

file(COPY ${CMAKE_CURRENT_LIST_DIR}/CMakeLists.txt DESTINATION ${SOURCE_PATH})

vcpkg_execute_required_process(
  COMMAND ${CMAKE_COMMAND} -E copy_directory boost ${CURRENT_PACKAGES_DIR}/include/boost
  WORKING_DIRECTORY ${SOURCE_PATH}
  LOGNAME install-headers-${TARGET_TRIPLET})

if(NOT VCPKG_CMAKE_SYSTEM_NAME)
  set(B2 ${SOURCE_PATH}/b2.exe)
  set(BOOTSTRAP ${SOURCE_PATH}/bootstrap.bat)
else()
  set(B2 ${SOURCE_PATH}/b2)
  set(BOOTSTRAP ${SOURCE_PATH}/bootstrap.sh)
endif()

if(NOT EXISTS ${B2})
  message(STATUS "Building b2...")
  vcpkg_execute_required_process(
    COMMAND ${BOOTSTRAP}
    WORKING_DIRECTORY ${SOURCE_PATH}
    LOGNAME b2-${TARGET_TRIPLET})
endif()

vcpkg_configure_cmake(
  SOURCE_PATH ${SOURCE_PATH}
  PREFER_NINJA
  OPTIONS
    -DB2=${B2}
    -DCRT_LINKAGE=${VCPKG_CRT_LINKAGE}
    -DINCLUDE_DIRECTORY=${CURRENT_PACKAGES_DIR}/include
    -DWITH_BZIP2=${WITH_BZIP2}
    -DWITH_LZMA=${WITH_LZMA}
    -DWITH_ZLIB=${WITH_ZLIB}
    -DWITH_ZSTD=${WITH_ZSTD})

vcpkg_install_cmake()

file(GLOB LIB_FILES ${CURRENT_PACKAGES_DIR}/lib/*.dll)
if(LIB_FILES)
  if(NOT EXISTS ${CURRENT_PACKAGES_DIR}/bin)
    file(MAKE_DIRECTORY ${CURRENT_PACKAGES_DIR}/bin)
  endif()
  foreach(name ${LIB_FILES})
    get_filename_component(name ${name} NAME)
    file(RENAME ${CURRENT_PACKAGES_DIR}/lib/${name} ${CURRENT_PACKAGES_DIR}/bin/${name})
  endforeach()
endif()

file(GLOB LIB_DEBUG_FILES ${CURRENT_PACKAGES_DIR}/debug/lib/*.dll)
if(LIB_DEBUG_FILES)
  if(NOT EXISTS ${CURRENT_PACKAGES_DIR}/debug/bin)
    file(MAKE_DIRECTORY ${CURRENT_PACKAGES_DIR}/debug/bin)
  endif()
  foreach(name ${LIB_DEBUG_FILES})
    get_filename_component(name ${name} NAME)
    file(RENAME ${CURRENT_PACKAGES_DIR}/debug/lib/${name} ${CURRENT_PACKAGES_DIR}/debug/bin/${name})
  endforeach()
endif()

# Move config file.
set(BOOST_STATIC_LIBS "ON")
if(VCPKG_LIBRARY_LINKAGE STREQUAL "dynamic")
  set(BOOST_STATIC_LIBS "OFF")
endif()

set(BOOST_STATIC_RUNTIME "ON")
if(VCPKG_CRT_LINKAGE STREQUAL "dynamic")
  set(BOOST_STATIC_RUNTIME "OFF")
endif()

file(READ "${CURRENT_PACKAGES_DIR}/share/boost/Boost-${BOOST_VERSION}/BoostConfig.cmake" BOOST_CONFIG)
string(REPLACE "$\{CMAKE_CURRENT_LIST_DIR}/.." "$\{CMAKE_CURRENT_LIST_DIR}" BOOST_CONFIG "${BOOST_CONFIG}")

set(BOOST_CONFIG_FILE "${CURRENT_PACKAGES_DIR}/share/boost/BoostConfig.cmake")
file(WRITE  "${BOOST_CONFIG_FILE}" "# Configuration\n")
file(APPEND "${BOOST_CONFIG_FILE}" "set(Boost_USE_STATIC_LIBS ${BOOST_STATIC_LIBS})\n")
file(APPEND "${BOOST_CONFIG_FILE}" "set(Boost_USE_STATIC_RUNTIME ${BOOST_STATIC_RUNTIME})\n")
file(APPEND "${BOOST_CONFIG_FILE}" "set(Boost_USE_MULTITHREADED \"\")\n")
file(APPEND "${BOOST_CONFIG_FILE}" "set(Boost_USE_RELEASE_LIBS \"\")\n\n")
file(APPEND "${BOOST_CONFIG_FILE}" "${BOOST_CONFIG}")

# Move version file.
file(RENAME
  "${CURRENT_PACKAGES_DIR}/share/boost/Boost-${BOOST_VERSION}/BoostConfigVersion.cmake"
  "${CURRENT_PACKAGES_DIR}/share/boost/BoostConfigVersion.cmake")

# Remove config directory.
file(REMOVE_RECURSE "${CURRENT_PACKAGES_DIR}/share/boost/Boost-${BOOST_VERSION}")

# Patch debug config files.
file(GLOB DEBUG_CMAKE_FILES ${CURRENT_PACKAGES_DIR}/debug/share/boost/*/*-variant*.cmake)
if(DEBUG_CMAKE_FILES)
  foreach(name ${DEBUG_CMAKE_FILES})
    file(READ "${name}" data)
    string(REPLACE "$\{_BOOST_LIBDIR}" "$\{_BOOST_LIBDIR_DEBUG}" data "${data}")
    string(PREPEND data "get_filename_component(_BOOST_LIBDIR_DEBUG \"$\{_BOOST_LIBDIR}/../debug/lib\" ABSOLUTE)\n\n")
    string(APPEND data "\n\nunset(_BOOST_LIBDIR_DEBUG)")
    get_filename_component(dirname ${name} DIRECTORY)
    get_filename_component(dirname ${dirname} NAME)
    get_filename_component(name ${name} NAME_WLE)
    file(WRITE "${CURRENT_PACKAGES_DIR}/share/boost/${dirname}/${name}-debug.cmake" "${data}")
  endforeach()
else()
  message(FATAL_ERROR "Could not find CMake config files.")
endif()

file(REMOVE_RECURSE ${CURRENT_PACKAGES_DIR}/debug/include)
file(REMOVE_RECURSE ${CURRENT_PACKAGES_DIR}/debug/share)

configure_file(${CMAKE_CURRENT_LIST_DIR}/usage.in ${CURRENT_PACKAGES_DIR}/share/boost/usage LF)
