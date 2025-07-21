cmake_minimum_required(VERSION 3.16)

project(QuickEdits VERSION 0.1.1 LANGUAGES CXX)

set(CMAKE_INSTALL_PREFIX "${CMAKE_BINARY_DIR}/install" CACHE PATH "Installation directory" FORCE)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_AUTORCC ON)

find_package(Qt6 REQUIRED COMPONENTS
    Quick
)

qt_standard_project_setup(REQUIRES 6.8)

set(SOURCES
    src/main.cpp
    src/imageexporter.cpp
    src/filehandler.cpp
)

set(HEADERS
    include/imageexporter.h
    include/filehandler.h
)

set(QML_FILES
    qml/Main.qml
    qml/ColorPicker.qml
    qml/CustomColorDialog.qml
    qml/MaterialButton.qml
    qml/SaveNamingDialog.qml
    qml/DonatePopup.qml
    qml/DownloadPopup.qml
)

set(QML_SINGLETONS
    qml/Singletons/UserSettings.qml
    qml/Singletons/Constants.qml
    qml/Singletons/Colors.qml
)

set_source_files_properties(${QML_SINGLETONS}
    PROPERTIES QT_QML_SINGLETON_TYPE TRUE
)

qt_add_executable(${CMAKE_PROJECT_NAME}
    ${SOURCES}
    ${HEADERS}
    resources/fonts/fonts.qrc
    resources/icons/icons.qrc
)

target_include_directories(${CMAKE_PROJECT_NAME} PRIVATE
    ${CMAKE_CURRENT_SOURCE_DIR}/include
)

qt_add_qml_module(${CMAKE_PROJECT_NAME}
    URI Odizinne.QuickEdits
    VERSION 1.0
    QML_FILES ${QML_FILES} ${QML_SINGLETONS}
)

# WebAssembly specific settings
if(CMAKE_SYSTEM_NAME STREQUAL "Emscripten")
    set_target_properties(${CMAKE_PROJECT_NAME} PROPERTIES
        QT_WASM_PTHREAD_POOL_SIZE 4
        QT_WASM_INITIAL_MEMORY 50MB
        QT_WASM_MAXIMUM_MEMORY 1GB
    )

    # Enable file system access for file dialogs and export functions
    target_link_options(${CMAKE_PROJECT_NAME} PRIVATE
        "-sALLOW_MEMORY_GROWTH=1"
        "-sFILESYSTEM=1"
        "-sEXPORTED_RUNTIME_METHODS=['FS','stringToUTF8','lengthBytesUTF8']"
        "-sEXPORTED_FUNCTIONS=['_main','_fileSelectedCallback','_layerImageSelectedCallback','_saveFileSelectedCallback','_malloc','_free']"
    )
else()
    # Native platforms only
    set_target_properties(${CMAKE_PROJECT_NAME} PROPERTIES
        WIN32_EXECUTABLE TRUE
    )
endif()

target_link_libraries(${CMAKE_PROJECT_NAME}
    PRIVATE
    Qt6::Quick
)

# Only do installation stuff for non-WebAssembly builds
if(NOT CMAKE_SYSTEM_NAME STREQUAL "Emscripten")
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
endif()
