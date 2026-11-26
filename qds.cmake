# YoungLion Calendar
# SPDX-License-Identifier: GPL-3.0-only

add_subdirectory(Calendar)
add_subdirectory(CalendarContent)
add_subdirectory(App)

target_link_libraries(${PROJECT_NAME} PRIVATE Calendarplugin CalendarContentplugin)

if(BUILD_QDS_COMPONENTS)
    find_package(Qt6 6.8 REQUIRED COMPONENTS QuickTimeline ShaderTools)
    add_subdirectory(Dependencies)
    target_compile_definitions(${PROJECT_NAME} PRIVATE BUILD_QDS_COMPONENTS)
    target_link_libraries(${PROJECT_NAME} PRIVATE QtQuickDesignerComponents)
endif()

# Keep the same relative asset URLs in source previews and in the executable.
file(GLOB_RECURSE calendar_images CONFIGURE_DEPENDS
    RELATIVE "${CMAKE_CURRENT_SOURCE_DIR}"
    "assets/*.png" "assets/*.svg"
)
qt_add_resources(${PROJECT_NAME} calendar_images
    PREFIX "/qt/qml"
    FILES ${calendar_images}
)
