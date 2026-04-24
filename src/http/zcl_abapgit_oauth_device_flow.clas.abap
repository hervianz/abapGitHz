CLASS zcl_abapgit_oauth_device_flow DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.

    TYPES:
      BEGIN OF ty_provider_config,
        name            TYPE string,
        device_code_url TYPE string,
        token_url       TYPE string,
        client_id       TYPE string,
        scope           TYPE string,
      END OF ty_provider_config.

    TYPES:
      BEGIN OF ty_device_response,
        device_code      TYPE string,
        user_code        TYPE string,
        verification_uri TYPE string,
        expires_in       TYPE i,
        interval         TYPE i,
      END OF ty_device_response.

    TYPES:
      BEGIN OF ty_poll_result,
        access_token TYPE string,
        status       TYPE string,
      END OF ty_poll_result.

    CONSTANTS:
      BEGIN OF c_status,
        ok                    TYPE string VALUE 'ok',
        authorization_pending TYPE string VALUE 'authorization_pending',
        slow_down             TYPE string VALUE 'slow_down',
        expired_token         TYPE string VALUE 'expired_token',
        access_denied         TYPE string VALUE 'access_denied',
      END OF c_status.

    CLASS-METHODS get_provider_config
      IMPORTING
        !iv_url                   TYPE string
        !iv_client_id             TYPE string OPTIONAL
      RETURNING
        VALUE(rs_provider_config) TYPE ty_provider_config.

    CLASS-METHODS is_supported
      IMPORTING
        !iv_url        TYPE string
      RETURNING
        VALUE(rv_bool) TYPE abap_bool.

    CLASS-METHODS initiate
      IMPORTING
        !is_config                TYPE ty_provider_config
      RETURNING
        VALUE(rs_device_response) TYPE ty_device_response
      RAISING
        zcx_abapgit_exception.

    CLASS-METHODS poll_once
      IMPORTING
        !is_config       TYPE ty_provider_config
        !iv_device_code  TYPE string
      RETURNING
        VALUE(rs_result) TYPE ty_poll_result
      RAISING
        zcx_abapgit_exception.

  PRIVATE SECTION.

    CLASS-METHODS post_form
      IMPORTING
        !iv_url        TYPE string
        !io_params     TYPE REF TO zcl_abapgit_string_map
      RETURNING
        VALUE(rv_body) TYPE string
      RAISING
        zcx_abapgit_exception.

ENDCLASS.



CLASS zcl_abapgit_oauth_device_flow IMPLEMENTATION.


  METHOD get_provider_config.

    DATA lv_url_lower TYPE string.

    lv_url_lower = to_lower( iv_url ).

    IF lv_url_lower CS 'github.com'.
      rs_provider_config-name            = 'GitHub'.
      rs_provider_config-device_code_url = 'https://github.com/login/device/code'.
      rs_provider_config-token_url       = 'https://github.com/login/oauth/access_token'.
      rs_provider_config-scope           = 'repo'.
    ELSEIF lv_url_lower CS 'gitlab.com'.
      rs_provider_config-name            = 'GitLab'.
      rs_provider_config-device_code_url = 'https://gitlab.com/oauth/authorize_device'.
      rs_provider_config-token_url       = 'https://gitlab.com/oauth/token'.
      rs_provider_config-scope           = 'api read_user'.
    ENDIF.

    IF iv_client_id IS NOT INITIAL.
      rs_provider_config-client_id = iv_client_id.
    ENDIF.

  ENDMETHOD.


  METHOD is_supported.

    DATA lv_url_lower TYPE string.

    lv_url_lower = to_lower( iv_url ).
    rv_bool = boolc( lv_url_lower CS 'github.com' OR lv_url_lower CS 'gitlab.com' ).

  ENDMETHOD.


  METHOD initiate.

    DATA lo_params TYPE REF TO zcl_abapgit_string_map.
    DATA lv_body   TYPE string.
    DATA li_json   TYPE REF TO zif_abapgit_ajson.
    DATA lx_ajson  TYPE REF TO zcx_abapgit_ajson_error.
    DATA lv_str    TYPE string.

    IF is_config-client_id IS INITIAL.
      zcx_abapgit_exception=>raise(
        'OAuth Client ID not configured.' &&
        ' Register an OAuth App at your Git provider and enter the Client ID.' ).
    ENDIF.

    CREATE OBJECT lo_params.
    lo_params->set( iv_key = 'client_id' iv_val = is_config-client_id ).
    lo_params->set( iv_key = 'scope'     iv_val = is_config-scope ).

    lv_body = post_form(
      iv_url    = is_config-device_code_url
      io_params = lo_params ).

    TRY.
        li_json = zcl_abapgit_ajson=>parse( lv_body ).

        rs_device_response-device_code      = li_json->get( '/device_code' ).
        rs_device_response-user_code        = li_json->get( '/user_code' ).
        rs_device_response-verification_uri = li_json->get( '/verification_uri' ).

        lv_str = li_json->get( '/expires_in' ).
        rs_device_response-expires_in = lv_str.

        lv_str = li_json->get( '/interval' ).
        rs_device_response-interval = lv_str.

      CATCH zcx_abapgit_ajson_error INTO lx_ajson.
        zcx_abapgit_exception=>raise_with_text( lx_ajson ).
    ENDTRY.

    IF rs_device_response-device_code IS INITIAL.
      zcx_abapgit_exception=>raise(
        |OAuth device flow initiation failed. Response: { lv_body }| ).
    ENDIF.

    IF rs_device_response-interval = 0.
      rs_device_response-interval = 5.
    ENDIF.

  ENDMETHOD.


  METHOD poll_once.

    DATA lo_params TYPE REF TO zcl_abapgit_string_map.
    DATA lv_body   TYPE string.
    DATA li_json   TYPE REF TO zif_abapgit_ajson.
    DATA lx_ajson  TYPE REF TO zcx_abapgit_ajson_error.
    DATA lv_error  TYPE string.

    CREATE OBJECT lo_params.
    lo_params->set( iv_key = 'client_id'   iv_val = is_config-client_id ).
    lo_params->set( iv_key = 'device_code' iv_val = iv_device_code ).
    lo_params->set( iv_key = 'grant_type'
                    iv_val = 'urn:ietf:params:oauth:grant-type:device_code' ).

    lv_body = post_form(
      iv_url    = is_config-token_url
      io_params = lo_params ).

    TRY.
        li_json = zcl_abapgit_ajson=>parse( lv_body ).
        rs_result-access_token = li_json->get( '/access_token' ).
        lv_error               = li_json->get( '/error' ).
      CATCH zcx_abapgit_ajson_error INTO lx_ajson.
        zcx_abapgit_exception=>raise_with_text( lx_ajson ).
    ENDTRY.

    IF rs_result-access_token IS NOT INITIAL.
      rs_result-status = c_status-ok.
    ELSEIF lv_error IS NOT INITIAL.
      rs_result-status = lv_error.
    ELSE.
      rs_result-status = c_status-authorization_pending.
    ENDIF.

  ENDMETHOD.


  METHOD post_form.

    DATA li_client  TYPE REF TO if_http_client.
    DATA lv_code    TYPE i.
    DATA lv_message TYPE string.
    FIELD-SYMBOLS <ls_entry> LIKE LINE OF io_params->mt_entries.

    li_client = zcl_abapgit_exit=>get_instance( )->create_http_client( iv_url ).

    IF li_client IS INITIAL.
      cl_http_client=>create_by_url(
        EXPORTING
          url    = iv_url
          ssl_id = zcl_abapgit_exit=>get_instance( )->get_ssl_id( )
        IMPORTING
          client             = li_client
        EXCEPTIONS
          argument_not_found = 1
          plugin_not_active  = 2
          internal_error     = 3
          OTHERS             = 4 ).
      IF sy-subrc <> 0.
        zcx_abapgit_exception=>raise( 'Error creating HTTP client for OAuth' ).
      ENDIF.
    ENDIF.

    li_client->request->set_version( if_http_request=>co_protocol_version_1_1 ).
    li_client->request->set_method( 'POST' ).
    li_client->request->set_header_field(
      name  = 'Accept'
      value = 'application/json' ).

    LOOP AT io_params->mt_entries ASSIGNING <ls_entry>.
      li_client->request->set_form_field(
        name  = <ls_entry>-k
        value = <ls_entry>-v ).
    ENDLOOP.

    li_client->send(
      EXCEPTIONS
        http_communication_failure = 1
        http_invalid_state         = 2
        http_processing_failed     = 3
        http_invalid_timeout       = 4
        OTHERS                     = 5 ).

    IF sy-subrc = 0.
      li_client->receive(
        EXCEPTIONS
          http_communication_failure = 1
          http_invalid_state         = 2
          http_processing_failed     = 3
          OTHERS                     = 4 ).
    ENDIF.

    IF sy-subrc <> 0.
      li_client->get_last_error(
        IMPORTING
          code    = lv_code
          message = lv_message ).
      zcx_abapgit_exception=>raise( |OAuth HTTP error { lv_code }: { lv_message }| ).
    ENDIF.

    rv_body = li_client->response->get_cdata( ).
    li_client->close( ).

  ENDMETHOD.

ENDCLASS.
