cmake_minimum_required(VERSION 3.16)

project(QuickEdits VERSION 0.1 LANGUAGES CXX)

set(CMAKE_INSTALL_PREFIX "${CMAKE_BINARY_DIR}/install" CACHE PATH "Installation directory" FORCE)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

find_package(Qt6 REQUIRED COMPONENTS
    Quick
)

qt_standard_project_setup(REQUIRES 6.8)

set(SOURCES
    src/main.cpp
    src/imageexporter.cpp
)

set(HEADERS
    include/imageexporter.h
)

set(QML_FILES
    qml/Main.qml
    qml/ColorPicker.qml
)

qt_add_executable(${CMAKE_PROJECT_NAME}
    ${SOURCES}
    ${HEADERS}
)

target_include_directories(${CMAKE_PROJECT_NAME} PRIVATE
    ${CMAKE_CURRENT_SOURCE_DIR}/include
)

qt_add_qml_module(${CMAKE_PROJECT_NAME}
    URI Odizinne.QuickEdits
    VERSION 1.0
    QML_FILES ${QML_FILES}
)

set_target_properties(${CMAKE_PROJECT_NAME} PROPERTIES
    WIN32_EXECUTABLE TRUE
)

target_link_libraries(${CMAKE_PROJECT_NAME}
    PRIVATE
    Qt6::Quick
)

include(GNUInstallDirs)

install(TARGETS ${CMAKE_PROJECT_NAME}
    BUNDLE DESTINATION .
    RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
)

qt_generate_deploy_qml_app_script(
    TARGET ${CMAKE_PROJECT_NAME}
    OUTPUT_SCRIPT deploy_script
    NO_TRANSLATIONS
    DEPLOY_TOOL_OPTIONS --no-compiler-runtime --no-opengl-sw --no-system-dxc-compiler --no-system-d3d-compiler --skip-plugin-types designer,iconengines,qmllint,generic,networkinformation,help,qmltooling,sqldrivers,qmlls
)

install(SCRIPT ${deploy_script})
