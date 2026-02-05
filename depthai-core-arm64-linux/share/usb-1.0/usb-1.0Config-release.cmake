#----------------------------------------------------------------
# Generated CMake target import file for configuration "Release".
#----------------------------------------------------------------

# Commands may need to know the format version.
set(CMAKE_IMPORT_FILE_VERSION 1)

# Import target "usb-1.0" for configuration "Release"
set_property(TARGET usb-1.0 APPEND PROPERTY IMPORTED_CONFIGURATIONS RELEASE)
set_target_properties(usb-1.0 PROPERTIES
  IMPORTED_LOCATION_RELEASE "${_IMPORT_PREFIX}/lib/libusb-1.0.so"
  IMPORTED_SONAME_RELEASE "libusb-1.0.so"
  )

list(APPEND _cmake_import_check_targets usb-1.0 )
list(APPEND _cmake_import_check_files_for_usb-1.0 "${_IMPORT_PREFIX}/lib/libusb-1.0.so" )

# Commands beyond this point should not need to know the version.
set(CMAKE_IMPORT_FILE_VERSION)
