# YoungLion Calendar
# SPDX-License-Identifier: GPL-3.0-only

cmake_minimum_required(VERSION 3.21.1)
project(CalendarApp VERSION 0.2.0 LANGUAGES CXX)

option(BUILD_QDS_COMPONENTS "Build the bundled Qt Design Studio components" OFF)
option(LINK_INSIGHT "Link the optional Qt Insight Tracker library" OFF)

find_package(Qt6 6.8 REQUIRED COMPONENTS Core Gui Widgets Qml Quick QuickControls2 Sql)
qt_standard_project_setup(REQUIRES 6.8)
set(QT_QML_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/qml")
set(QML_IMPORT_PATH "${QT_QML_OUTPUT_DIRECTORY}" CACHE PATH "QML import path for Qt Creator" FORCE)

qt_add_executable(${PROJECT_NAME})
target_link_libraries(${PROJECT_NAME} PRIVATE Qt6::QuickControls2)
qt_add_resources(${PROJECT_NAME} configuration
    PREFIX "/"
    FILES qtquickcontrols2.conf
)

include(qds.cmake)

if(LINK_INSIGHT)
    include(cmake/insight.cmake)
endif()

include(GNUInstallDirs)
if(NOT ANDROID)
    install(TARGETS ${PROJECT_NAME}
        BUNDLE DESTINATION .
        RUNTIME DESTINATION "${CMAKE_INSTALL_BINDIR}"
    )
endif()

include(CTest)
if(BUILD_TESTING)
    find_package(Qt6 REQUIRED COMPONENTS Test)
    qt_add_executable(calendar_sql_tests tests/tst_sql.cpp)
    target_link_libraries(calendar_sql_tests PRIVATE CalendarStorage Qt6::Test)
    add_test(NAME calendar_sql COMMAND calendar_sql_tests)
endif()

if(CMAKE_SYSTEM_NAME STREQUAL "Linux" AND NOT ANDROID)
    install(FILES packaging/linux/xyz.younglion.Calendar.desktop
            DESTINATION "${CMAKE_INSTALL_DATADIR}/applications")
    install(FILES packaging/linux/xyz.younglion.Calendar.metainfo.xml
            DESTINATION "${CMAKE_INSTALL_DATADIR}/metainfo")
    install(FILES assets/younglion.svg
            DESTINATION "${CMAKE_INSTALL_DATADIR}/icons/hicolor/scalable/apps"
            RENAME xyz.younglion.Calendar.svg)
endif()

if(ANDROID)
    set_target_properties(${PROJECT_NAME} PROPERTIES
        QT_ANDROID_PACKAGE_SOURCE_DIR "${CMAKE_CURRENT_SOURCE_DIR}/packaging/android"
        QT_ANDROID_PACKAGE_NAME "xyz.younglion.calendar"
        QT_ANDROID_APP_NAME "YoungLion Calendar"
        QT_ANDROID_MIN_SDK_VERSION 28
        QT_ANDROID_VERSION_NAME "${PROJECT_VERSION}"
        QT_ANDROID_VERSION_CODE 2
    )
endif()
