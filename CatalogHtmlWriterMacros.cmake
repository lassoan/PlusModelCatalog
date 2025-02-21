MACRO(MODEL_TABLE_START MODEL_TABLE_NAME MODEL_TABLE_DESCRIPTION MODEL_DIRECTORY)
  SET(PAGE_BODY "${PAGE_BODY}
    <h2>${MODEL_TABLE_NAME}</h2>
    <p>${MODEL_TABLE_DESCRIPTION}</p>
    <p>
    <table>
      <thead>
        <tr>
          <th>Image</th>
          <th>ID</td>
          <th>Description</th>
          <th>Printable model</th>
        </tr>
      </thead>
      <tbody>")
  SET(MODEL_DIRECTORY "${MODEL_DIRECTORY}")
ENDMACRO(MODEL_TABLE_START)

MACRO(MODEL_TABLE_ROW)
  set(options "" )
  set(oneValueArgs ID IMAGE_FILE IMAGE_PRINTABLE_FILE DESCRIPTION EDIT_LINK)
  set(multiValueArgs PRINTABLE_FILES)
  cmake_parse_arguments(MODEL "${options}" "${oneValueArgs}" "${multiValueArgs}" ${ARGN} )

  # Get MODEL_PRINTABLE_FILES
  IF(NOT MODEL_PRINTABLE_FILES)
    SET(MODEL_PRINTABLE_FILES "${MODEL_DIRECTORY}/${MODEL_ID}.stl")
  ENDIF()
  SET(MODEL_PRINTABLE_FILES_LIST "${MODEL_PRINTABLE_FILES};")
  FOREACH(MODEL_PRINTABLE_FILE ${MODEL_PRINTABLE_FILES})
    FILE(COPY ${CMAKE_CURRENT_SOURCE_DIR}/${MODEL_PRINTABLE_FILE} DESTINATION "${HTML_OUTPUT_DIR}/printable")
  ENDFOREACH()

  # Get MODEL_IMAGE_PRINTABLE_FILE
  IF (NOT MODEL_IMAGE_PRINTABLE_FILE)
    LIST(GET MODEL_PRINTABLE_FILES_LIST 0 MODEL_IMAGE_PRINTABLE_FILE)
  ELSE()
    FILE(COPY ${CMAKE_CURRENT_SOURCE_DIR}/${MODEL_IMAGE_PRINTABLE_FILE} DESTINATION "${HTML_OUTPUT_DIR}/printable")
  ENDIF()
  
  # Get MODEL_IMAGE_FILE
  IF(NOT MODEL_IMAGE_FILE)
    SET(MODEL_IMAGE_FILE "${MODEL_ID}.png")
    CREATE_MODEL_IMAGE("${CMAKE_CURRENT_SOURCE_DIR}/${MODEL_IMAGE_PRINTABLE_FILE}" "${HTML_OUTPUT_DIR}/rendered/${MODEL_IMAGE_FILE}")
  ELSE()
    FILE(COPY ${CMAKE_CURRENT_SOURCE_DIR}/${MODEL_IMAGE_FILE} DESTINATION "${HTML_OUTPUT_DIR}/rendered")
  ENDIF()
  
  # Get MODEL_EDIT_LINK
  IF(NOT MODEL_EDIT_LINK)
    SET(MODEL_EDIT_LINK "${CATALOG_URL}/${MODEL_DIRECTORY}")
  ENDIF()
  
  # Write to HTML page
  GET_FILENAME_COMPONENT(MODEL_IMAGE_FILE_NAME ${MODEL_IMAGE_FILE} NAME)
  GET_FILENAME_COMPONENT(MODEL_IMAGE_PRINTABLE_FILE_NAME ${MODEL_IMAGE_PRINTABLE_FILE} NAME)
  SET(PAGE_BODY "${PAGE_BODY}
          <tr>
          <td><a href=\"printable/${MODEL_IMAGE_PRINTABLE_FILE_NAME}\"><img class=\"model\" src=\"rendered/${MODEL_IMAGE_FILE_NAME}\"></a></td>
          <td>${MODEL_ID}</td>
          <td>${MODEL_DESCRIPTION}</td>  
          <td>")
  FOREACH(MODEL_PRINTABLE_FILE ${MODEL_PRINTABLE_FILES})
    GET_FILENAME_COMPONENT(MODEL_PRINTABLE_FILE_NAME ${MODEL_PRINTABLE_FILE} NAME)
    GIT_LAST_CHANGED_TAG("${MODEL_PRINTABLE_FILE}" PrintableModelFileLastChangedTag)
    SET(PRINTABLE_MODEL_REV "${PrintableModelFileLastChangedTag}")
    SET(PAGE_BODY "${PAGE_BODY} <a href=\"printable/${MODEL_PRINTABLE_FILE_NAME}\">${MODEL_PRINTABLE_FILE_NAME}</a><br><font size=\"-1\">(${PRINTABLE_MODEL_REV})</font><br><br>")
  ENDFOREACH()
  SET(PAGE_BODY "${PAGE_BODY} <a href=\"${MODEL_EDIT_LINK}\">Source file(s)</a>")
  SET(PAGE_BODY "${PAGE_BODY} </td>
        </tr>")
        
ENDMACRO(MODEL_TABLE_ROW)

MACRO(MODEL_TABLE_END)
  SET(PAGE_BODY "${PAGE_BODY}
      </tbody>
    </table>")
ENDMACRO(MODEL_TABLE_END)

MACRO(PARAGRAPH TEXT)
  SET(PAGE_BODY
    "${PAGE_BODY} <p>${TEXT}</p>")
ENDMACRO(PARAGRAPH)

MACRO (TODAY RESULT)
    IF (WIN32)
        EXECUTE_PROCESS(COMMAND "cmd" " /C date /T" OUTPUT_VARIABLE ${RESULT})
        string(REGEX REPLACE ".* (..)/(..)/(....).*" "\\1/\\2/\\3" ${RESULT} ${${RESULT}})
    ELSEIF(UNIX)
        EXECUTE_PROCESS(COMMAND "date" "+%d/%m/%Y" OUTPUT_VARIABLE ${RESULT})
        string(REGEX REPLACE "(..)/(..)/(....).*" "\\1/\\2/\\3" ${RESULT} ${${RESULT}})
    ELSE (WIN32)
        MESSAGE(WARNING "date not implemented")
        SET(${RESULT} "unknown")
    ENDIF (WIN32)
ENDMACRO (TODAY)

MACRO(MODEL_CATALOG_START)
  SET(PAGE_BODY "" )
ENDMACRO(MODEL_CATALOG_START)

MACRO(MODEL_CATALOG_END)
  GIT_LAST_CHANGED_TAG("." CATALOG_REV)
  TODAY(CURRENT_DATETIME)
  PARAGRAPH("<br>Version: ${CATALOG_REV}<br>Generated: ${CURRENT_DATETIME}")
  CONFIGURE_FILE(
    ${CMAKE_CURRENT_SOURCE_DIR}/CatalogTemplate.html.in
    ${HTML_OUTPUT_DIR}/index.html
    )
  FILE(COPY ${CMAKE_CURRENT_SOURCE_DIR}/link.png DESTINATION "${HTML_OUTPUT_DIR}")
ENDMACRO(MODEL_CATALOG_END)

MACRO (CREATE_MODEL_IMAGE INPUT_STL_FILE OUTPUT_PNG_FILE)
  SET(MODEL_RENDERER_EXE "${PLUS_EXECUTABLE_OUTPUT_PATH}/Release/ModelRenderer")
  GET_FILENAME_COMPONENT(BASE_FILENAME ${INPUT_STL_FILE} NAME)
  add_custom_command(
    DEPENDS ${INPUT_STL_FILE} ModelRenderer
    COMMAND ${MODEL_RENDERER_EXE} --model-file=${INPUT_STL_FILE} --output-image-file=${OUTPUT_PNG_FILE} --camera-orientation 0 -20 -20
    OUTPUT ${OUTPUT_PNG_FILE}
    )
  add_custom_target(ModelRenderer-${BASE_FILENAME} DEPENDS ${OUTPUT_PNG_FILE})
  set_target_properties(ModelRenderer-${BASE_FILENAME} PROPERTIES LABELS ModelRenderer)
  set_target_properties(ModelRenderer-${BASE_FILENAME} PROPERTIES EXCLUDE_FROM_ALL FALSE)
ENDMACRO (CREATE_MODEL_IMAGE)
