#----------------------------------------------------------------
# Generated CMake target import file for configuration "Release".
#----------------------------------------------------------------

# Commands may need to know the format version.
set(CMAKE_IMPORT_FILE_VERSION 1)

# Import target "depthai::core" for configuration "Release"
set_property(TARGET depthai::core APPEND PROPERTY IMPORTED_CONFIGURATIONS RELEASE)
set_target_properties(depthai::core PROPERTIES
  IMPORTED_LOCATION_RELEASE "${_IMPORT_PREFIX}/lib/libdepthai-core.so"
  IMPORTED_SONAME_RELEASE "libdepthai-core.so"
  )

list(APPEND _IMPORT_CHECK_TARGETS depthai::core )
list(APPEND _IMPORT_CHECK_FILES_FOR_depthai::core "${_IMPORT_PREFIX}/lib/libdepthai-core.so" )

# Commands beyond this point should not need to know the version.
set(CMAKE_IMPORT_FILE_VERSION)
