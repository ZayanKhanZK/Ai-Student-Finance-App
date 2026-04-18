cmake_minimum_required(VERSION 3.16)

project(AiStudentFinanceApp VERSION 0.1 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD_REQUIRED ON)

find_package(Qt6 REQUIRED COMPONENTS Quick Network)

qt_standard_project_setup(REQUIRES 6.10)

qt_add_executable(appAiStudentFinanceApp
    main.cpp
    sf.cpp
    sf.h
)

qt_add_qml_module(appAiStudentFinanceApp
    URI AiStudentFinanceApp
    QML_FILES
        Main.qml
)

set_target_properties(appAiStudentFinanceApp PROPERTIES
    MACOSX_BUNDLE_BUNDLE_VERSION ${PROJECT_VERSION}
    MACOSX_BUNDLE_SHORT_VERSION_STRING ${PROJECT_VERSION_MAJOR}.${PROJECT_VERSION_MINOR}
    MACOSX_BUNDLE TRUE
    WIN32_EXECUTABLE TRUE
)

target_link_libraries(appAiStudentFinanceApp
    PRIVATE Qt6::Quick
    PRIVATE Qt6::Network
)

install(TARGETS appAiStudentFinanceApp
    BUNDLE DESTINATION .
    LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
    RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
)