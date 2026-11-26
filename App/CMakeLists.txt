
target_sources(${CMAKE_PROJECT_NAME} PUBLIC
    "main.cpp"
)

target_link_libraries(${CMAKE_PROJECT_NAME} PRIVATE
    Qt${QT_VERSION_MAJOR}::Core
    Qt${QT_VERSION_MAJOR}::Gui
    Qt${QT_VERSION_MAJOR}::Widgets
    Qt${QT_VERSION_MAJOR}::Quick
    Qt${QT_VERSION_MAJOR}::Qml)

find_package(LibIcal REQUIRED)
add_library(CalendarStorage STATIC EventDatabase.cpp EventDatabase.h CalendarFiles.cpp)
target_include_directories(CalendarStorage PUBLIC "${CMAKE_CURRENT_SOURCE_DIR}")
target_link_libraries(CalendarStorage PUBLIC Qt6::Core Qt6::Sql PRIVATE ical)
target_link_libraries(${PROJECT_NAME} PRIVATE CalendarStorage)

target_sources(${PROJECT_NAME} PRIVATE DesktopSession.cpp DesktopSession.h)
target_sources(${PROJECT_NAME} PRIVATE CalendarWorker.cpp CalendarWorker.h)
if(CMAKE_SYSTEM_NAME STREQUAL "Linux" AND NOT ANDROID)
    find_package(Qt6 REQUIRED COMPONENTS DBus)
    target_link_libraries(${PROJECT_NAME} PRIVATE Qt6::DBus)
    target_compile_definitions(${PROJECT_NAME} PRIVATE YOUNGLION_DESKTOP_DBUS)
endif()
