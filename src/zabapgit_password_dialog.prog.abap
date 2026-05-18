*&---------------------------------------------------------------------*
*&  Include           ZABAPGIT_PASSWORD_DIALOG
*&---------------------------------------------------------------------*

SELECTION-SCREEN BEGIN OF SCREEN 1002 TITLE sc_title.
SELECTION-SCREEN SKIP.
SELECTION-SCREEN BEGIN OF LINE.
SELECTION-SCREEN COMMENT 1(18) sc_url FOR FIELD p_url.
PARAMETERS: p_url TYPE string LOWER CASE VISIBLE LENGTH 60 ##SEL_WRONG.
SELECTION-SCREEN END OF LINE.
SELECTION-SCREEN SKIP.
SELECTION-SCREEN BEGIN OF LINE.
SELECTION-SCREEN COMMENT 1(18) sc_user FOR FIELD p_user.
PARAMETERS: p_user TYPE string LOWER CASE VISIBLE LENGTH 60 ##SEL_WRONG.
SELECTION-SCREEN END OF LINE.
SELECTION-SCREEN BEGIN OF LINE.
SELECTION-SCREEN COMMENT 1(18) sc_pass FOR FIELD p_pass.
PARAMETERS: p_pass TYPE c LENGTH 255 LOWER CASE VISIBLE LENGTH 60 ##SEL_WRONG.
SELECTION-SCREEN END OF LINE.
SELECTION-SCREEN SKIP.
SELECTION-SCREEN BEGIN OF LINE.
SELECTION-SCREEN COMMENT 1(18) sc_cmnt FOR FIELD p_cmnt.
PARAMETERS: p_cmnt TYPE c LENGTH 255 LOWER CASE VISIBLE LENGTH 60 ##SEL_WRONG.
SELECTION-SCREEN END OF LINE.
SELECTION-SCREEN END OF SCREEN 1002.

*-----------------------------------------------------------------------
* SCREEN 1003 - OAuth Device Code Dialog
*-----------------------------------------------------------------------
SELECTION-SCREEN BEGIN OF SCREEN 1003 TITLE sc_otit.
SELECTION-SCREEN SKIP.
SELECTION-SCREEN BEGIN OF LINE.
SELECTION-SCREEN COMMENT 1(22) sc_ourl FOR FIELD p_ourl.
PARAMETERS: p_ourl TYPE string LOWER CASE VISIBLE LENGTH 65 ##SEL_WRONG.
SELECTION-SCREEN END OF LINE.
SELECTION-SCREEN SKIP.
SELECTION-SCREEN BEGIN OF LINE.
SELECTION-SCREEN COMMENT 1(22) sc_ocod FOR FIELD p_ocode.
PARAMETERS: p_ocode TYPE c LENGTH 30 LOWER CASE VISIBLE LENGTH 30 ##SEL_WRONG.
SELECTION-SCREEN END OF LINE.
SELECTION-SCREEN SKIP.
SELECTION-SCREEN BEGIN OF LINE.
SELECTION-SCREEN COMMENT 1(22) sc_osta FOR FIELD p_ostat.
PARAMETERS: p_ostat TYPE c LENGTH 80 LOWER CASE VISIBLE LENGTH 65 ##SEL_WRONG.
SELECTION-SCREEN END OF LINE.
SELECTION-SCREEN SKIP.
SELECTION-SCREEN BEGIN OF LINE.
SELECTION-SCREEN PUSHBUTTON 1(20) pb_obr USER-COMMAND obr.
SELECTION-SCREEN PUSHBUTTON 23(25) pb_ochk USER-COMMAND ochk.
SELECTION-SCREEN END OF LINE.
SELECTION-SCREEN END OF SCREEN 1003.

*-----------------------------------------------------------------------
* SCREEN 1004 - Authentication Method Choice Dialog
*-----------------------------------------------------------------------
SELECTION-SCREEN BEGIN OF SCREEN 1004 TITLE sc_mtit.
SELECTION-SCREEN SKIP.
SELECTION-SCREEN BEGIN OF LINE.
PARAMETERS p_mbasic TYPE c RADIOBUTTON GROUP meth DEFAULT 'X'.
SELECTION-SCREEN COMMENT 3(55) sc_mbas FOR FIELD p_mbasic.
SELECTION-SCREEN END OF LINE.
SELECTION-SCREEN BEGIN OF LINE.
PARAMETERS p_moauth TYPE c RADIOBUTTON GROUP meth.
SELECTION-SCREEN COMMENT 3(55) sc_moas FOR FIELD p_moauth.
SELECTION-SCREEN END OF LINE.
SELECTION-SCREEN SKIP.
SELECTION-SCREEN BEGIN OF LINE.
SELECTION-SCREEN COMMENT 1(22) sc_mcid FOR FIELD p_mcid.
PARAMETERS: p_mcid TYPE string LOWER CASE VISIBLE LENGTH 60 ##SEL_WRONG.
SELECTION-SCREEN END OF LINE.
SELECTION-SCREEN BEGIN OF LINE.
SELECTION-SCREEN COMMENT 1(22) sc_msec FOR FIELD p_msec.
PARAMETERS: p_msec TYPE string LOWER CASE VISIBLE LENGTH 60 ##SEL_WRONG.
SELECTION-SCREEN END OF LINE.
SELECTION-SCREEN BEGIN OF LINE.
SELECTION-SCREEN COMMENT 1(22) sc_mprv FOR FIELD p_mprv.
PARAMETERS: p_mprv TYPE string LOWER CASE VISIBLE LENGTH 60 ##SEL_WRONG.
SELECTION-SCREEN END OF LINE.
SELECTION-SCREEN BEGIN OF LINE.
SELECTION-SCREEN COMMENT 1(80) sc_mhlp.
SELECTION-SCREEN END OF LINE.
SELECTION-SCREEN END OF SCREEN 1004.

*-----------------------------------------------------------------------
* LCL_PASSWORD_DIALOG
*-----------------------------------------------------------------------
CLASS lcl_password_dialog DEFINITION FINAL.

**************
* This class will remain local in the report
**************

  PUBLIC SECTION.

    CONSTANTS c_dynnr TYPE c LENGTH 4 VALUE '1002'.

    CLASS-METHODS popup
      IMPORTING
        iv_repo_url TYPE string
      CHANGING
        cv_user     TYPE string
        cv_pass     TYPE string.

    CLASS-METHODS on_screen_init.
    CLASS-METHODS on_screen_output.
    CLASS-METHODS on_screen_event
      IMPORTING
        iv_ucomm TYPE sy-ucomm.

  PRIVATE SECTION.

    CLASS-DATA gv_confirm TYPE abap_bool.
    CLASS-METHODS enrich_title_by_hostname
      IMPORTING
        iv_repo_url TYPE string.

ENDCLASS.

CLASS lcl_password_dialog IMPLEMENTATION.

  METHOD popup.

    DATA ls_position TYPE zif_abapgit_popups=>ty_popup_position.

    CLEAR p_pass.
    p_url      = iv_repo_url.
    p_user     = cv_user.
    gv_confirm = abap_false.

    p_cmnt = 'Press F1 for Help'.

    enrich_title_by_hostname( iv_repo_url ).

    ls_position = zcl_abapgit_popups=>center(
      iv_width  = 65
      iv_height = 7 ).

    CALL SELECTION-SCREEN c_dynnr
      STARTING AT ls_position-start_column ls_position-start_row
      ENDING AT ls_position-end_column ls_position-end_row.

    IF gv_confirm = abap_true.
      cv_user = p_user.
      cv_pass = p_pass.
    ELSE.
      CLEAR: cv_user, cv_pass.
    ENDIF.

    CLEAR: p_url, p_user, p_pass.

  ENDMETHOD.

  METHOD on_screen_init.
    sc_title = 'Login'.
    sc_url   = 'Repo URL'.
    sc_user  = 'User'.
    sc_pass  = 'Password or Token'.
    sc_cmnt  = 'Note'.
  ENDMETHOD.

  METHOD on_screen_output.

    DATA lt_ucomm TYPE TABLE OF sy-ucomm.

    CHECK sy-dynnr = c_dynnr.

    LOOP AT SCREEN.
      IF screen-name = 'P_URL' OR screen-name = 'P_CMNT'.
        screen-input       = '0'.
        screen-intensified = '1'.
        screen-display_3d  = '0'.
        MODIFY SCREEN.
      ENDIF.
      IF screen-name = 'P_CMNT' OR screen-name = 'SC_CMNT'.
        screen-active    = '1'.
        screen-invisible = '0'.
        MODIFY SCREEN.
      ENDIF.
      IF screen-name = 'P_PASS'.
        screen-invisible = '1'.
        MODIFY SCREEN.
      ENDIF.
    ENDLOOP.

    APPEND 'PICK' TO lt_ucomm.

    CALL FUNCTION 'RS_SET_SELSCREEN_STATUS'
      EXPORTING
        p_status  = 'DETL'
        p_program = 'RSPFPAR'
      TABLES
        p_exclude = lt_ucomm.

    IF p_user IS NOT INITIAL.
      SET CURSOR FIELD 'P_PASS'.
    ENDIF.

  ENDMETHOD.

  METHOD on_screen_event.

    CHECK sy-dynnr = c_dynnr.

    CASE iv_ucomm.
      WHEN 'OK'. " Enter
        gv_confirm = abap_true.
        LEAVE TO SCREEN 0.
      WHEN 'HELP'. " F1
        TRY.
            zcl_abapgit_services_abapgit=>open_abapgit_wikipage( 'guide-authentication.html' ).
          CATCH zcx_abapgit_exception ##NO_HANDLER.
        ENDTRY.
      WHEN OTHERS. " Escape
        gv_confirm = abap_false.
        LEAVE TO SCREEN 0.
    ENDCASE.

  ENDMETHOD.


  METHOD enrich_title_by_hostname.

    DATA lv_host TYPE string.

    FIND REGEX 'https?://([^/^:]*)' IN iv_repo_url SUBMATCHES lv_host ##REGEX_POSIX.
    IF lv_host IS NOT INITIAL AND lv_host <> space.
      CLEAR sc_title.
      CONCATENATE 'Login:' lv_host INTO sc_title IN CHARACTER MODE SEPARATED BY space.
    ENDIF.

  ENDMETHOD.

ENDCLASS.


FORM password_popup
      USING
        pv_repo_url TYPE string
      CHANGING
        cv_user     TYPE string
        cv_pass     TYPE string ##CALLED.

  lcl_password_dialog=>popup(
    EXPORTING
      iv_repo_url     = pv_repo_url
    CHANGING
      cv_user         = cv_user
      cv_pass         = cv_pass ).

ENDFORM.

*-----------------------------------------------------------------------
* LCL_OAUTH_DEVICE_DIALOG
*-----------------------------------------------------------------------
CLASS lcl_oauth_device_dialog DEFINITION FINAL.

**************
* This class will remain local in the report
**************

  PUBLIC SECTION.

    CONSTANTS c_dynnr        TYPE c LENGTH 4 VALUE '1003'.
    CONSTANTS c_dynnr_choice TYPE c LENGTH 4 VALUE '1004'.

    CLASS-METHODS popup
      IMPORTING
        !iv_url          TYPE string
      EXPORTING
        !ev_use_basic    TYPE abap_bool
      RETURNING
        VALUE(rv_token)  TYPE string
      RAISING
        zcx_abapgit_exception.

    CLASS-METHODS on_screen_init.
    CLASS-METHODS on_screen_output_device.
    CLASS-METHODS on_screen_event_device
      IMPORTING
        iv_ucomm TYPE sy-ucomm.
    CLASS-METHODS on_screen_output_choice.
    CLASS-METHODS on_screen_event_choice
      IMPORTING
        iv_ucomm TYPE sy-ucomm.

  PRIVATE SECTION.

    CLASS-DATA: gv_token       TYPE string,
                gv_device_code TYPE string,
                gv_status      TYPE string,
                gv_confirmed   TYPE abap_bool,
                gv_cancelled   TYPE abap_bool,
                gv_use_basic   TYPE abap_bool,
                gs_provider    TYPE zcl_abapgit_oauth_device_flow=>ty_provider_config.

    CLASS-METHODS enrich_title_by_hostname
      IMPORTING
        iv_url TYPE string.

    CLASS-METHODS open_browser
      IMPORTING
        iv_url TYPE string.

ENDCLASS.

CLASS lcl_oauth_device_dialog IMPLEMENTATION.

  METHOD popup.

    DATA ls_device   TYPE zcl_abapgit_oauth_device_flow=>ty_device_response.
    DATA ls_position TYPE zif_abapgit_popups=>ty_popup_position.

    ev_use_basic = abap_false.
    CLEAR: gv_token, gv_device_code, gv_status,
           gv_confirmed, gv_cancelled, gv_use_basic.

    " Show auth method choice first
    CLEAR: p_mbasic, p_moauth, p_mcid, p_msec, p_mprv.
    p_mbasic = abap_true.

    gs_provider = zcl_abapgit_oauth_device_flow=>get_provider_config( iv_url ).

    " Show auto-detected device code URL so user can verify (display-only)
    p_mprv  = gs_provider-device_code_url.

    sc_mcid  = 'Client ID (OAuth App):'.
    sc_msec  = 'Client Secret (opt):'.
    sc_mprv  = 'Device code URL:'.
    sc_mbas  = 'Username / Password / Personal Access Token'.
    sc_moas  = 'SSO (OAuth 2.0 Device Code Flow)'.
    sc_mhlp  = 'OAuth: register an OAuth App and enter its Client ID (+ Secret if required)'.
    sc_mtit  = 'Authentication Method'.

    ls_position = zcl_abapgit_popups=>center(
      iv_width  = 80
      iv_height = 10 ).

    CALL SELECTION-SCREEN c_dynnr_choice
      STARTING AT ls_position-start_column ls_position-start_row
      ENDING AT ls_position-end_column ls_position-end_row.

    " sy-subrc <> 0 only when user exited via Back/Exit/Cancel
    " (those route through AT SELECTION-SCREEN ON EXIT-COMMAND and unwind here).
    " gv_cancelled is not reliable on screen 1004 because the standard
    " Execute action sends ucomm 'ONLI', not 'OK', so we only trust sy-subrc.
    IF sy-subrc <> 0.
      ev_use_basic = abap_true.
      RETURN.
    ENDIF.

    IF p_mbasic = abap_true.
      ev_use_basic = abap_true.
      RETURN.
    ENDIF.

    " OAuth chosen: accept client_id and client_secret from dialog
    IF p_mcid IS NOT INITIAL.
      gs_provider-client_id = p_mcid.
    ENDIF.

    " Accept optional client_secret
    IF p_msec IS NOT INITIAL.
      gs_provider-client_secret = p_msec.
    ENDIF.

    " Allow user to override the auto-detected device code URL
    IF p_mprv IS NOT INITIAL AND p_mprv <> gs_provider-device_code_url.
      gs_provider-device_code_url = p_mprv.
    ENDIF.

    " Initiate OAuth device flow
    ls_device = zcl_abapgit_oauth_device_flow=>initiate( gs_provider ).

    " Populate screen 1003 fields
    p_ourl  = ls_device-verification_uri.
    p_ocode = ls_device-user_code.
    p_ostat = 'Open browser, log in, enter the code, then click Check'.
    gv_device_code = ls_device-device_code.

    enrich_title_by_hostname( iv_url ).
    sc_ourl  = 'Verification URL:'.
    sc_ocod  = 'Enter this code:'.
    sc_osta  = 'Status:'.
    pb_obr   = 'Open Browser'.
    pb_ochk  = 'Check Authorization'.

    " Try to open browser automatically
    open_browser( ls_device-verification_uri ).

    ls_position = zcl_abapgit_popups=>center(
      iv_width  = 80
      iv_height = 10 ).

    CALL SELECTION-SCREEN c_dynnr
      STARTING AT ls_position-start_column ls_position-start_row
      ENDING AT ls_position-end_column ls_position-end_row.

    IF gv_confirmed = abap_true AND gv_token IS NOT INITIAL.
      rv_token = gv_token.
    ELSE.
      " OAuth cancelled or failed - signal caller to use basic auth
      ev_use_basic = abap_true.
    ENDIF.

  ENDMETHOD.


  METHOD on_screen_init.
    " Initialize screen text variables
    sc_otit  = 'SSO Login'.
  ENDMETHOD.


  METHOD on_screen_output_device.

    CHECK sy-dynnr = c_dynnr.

    LOOP AT SCREEN.
      IF screen-name = 'P_OURL'
      OR screen-name = 'P_OCODE'
      OR screen-name = 'P_OSTAT'.
        screen-input       = '0'.
        screen-intensified = '1'.
        MODIFY SCREEN.
      ENDIF.
    ENDLOOP.

  ENDMETHOD.


  METHOD on_screen_event_device.

    DATA ls_result TYPE zcl_abapgit_oauth_device_flow=>ty_poll_result.
    DATA lx_err    TYPE REF TO zcx_abapgit_exception.

    CHECK sy-dynnr = c_dynnr.

    CASE iv_ucomm.
      WHEN 'OBR'.
        " Open browser
        open_browser( p_ourl ).
      WHEN 'OCHK'.
        " Poll for token
        TRY.
            ls_result = zcl_abapgit_oauth_device_flow=>poll_once(
              is_config      = gs_provider
              iv_device_code = gv_device_code ).
          CATCH zcx_abapgit_exception INTO lx_err.
            p_ostat = lx_err->get_text( ).
            RETURN.
        ENDTRY.

        CASE ls_result-status.
          WHEN zcl_abapgit_oauth_device_flow=>c_status-ok.
            gv_token     = ls_result-access_token.
            gv_confirmed = abap_true.
            p_ostat      = 'Authorization successful!'.
            LEAVE TO SCREEN 0.
          WHEN zcl_abapgit_oauth_device_flow=>c_status-authorization_pending.
            p_ostat = 'Pending: complete authorization in browser, then click Check again'.
          WHEN zcl_abapgit_oauth_device_flow=>c_status-slow_down.
            p_ostat = 'Slow down: please wait a moment before clicking Check again'.
          WHEN zcl_abapgit_oauth_device_flow=>c_status-expired_token.
            p_ostat = 'Code expired. Please cancel and try again.'.
          WHEN zcl_abapgit_oauth_device_flow=>c_status-access_denied.
            p_ostat = 'Access denied. Authorization was rejected.'.
            LEAVE TO SCREEN 0.
          WHEN OTHERS.
            p_ostat = |Unexpected status: { ls_result-status }|.
        ENDCASE.

      WHEN 'OK'.
        " Enter pressed without explicit check - just close
        LEAVE TO SCREEN 0.
      WHEN OTHERS.
        " Cancel / Escape
        gv_cancelled = abap_true.
        LEAVE TO SCREEN 0.
    ENDCASE.

  ENDMETHOD.


  METHOD on_screen_output_choice.

    CHECK sy-dynnr = c_dynnr_choice.

    " Keep Client ID always editable: radio button selection does not
    " re-fire AT SELECTION-SCREEN OUTPUT, so conditional disabling would
    " leave the field permanently grayed-out when Basic is the default.
    " Device code URL is shown read-only (informational); user can edit it
    " if the auto-detected endpoint is wrong (e.g. custom GHE instance).
    LOOP AT SCREEN.
      IF screen-name = 'P_MCID' OR screen-name = 'P_MPRV'.
        screen-input = '1'.
        MODIFY SCREEN.
      ENDIF.
    ENDLOOP.

  ENDMETHOD.


  METHOD on_screen_event_choice.

    CHECK sy-dynnr = c_dynnr_choice.

    " Any ucomm that reaches this handler means the user confirmed the dialog
    " (Execute sends 'ONLI', Enter may send 'CRET'/'OK', etc.). Back/Exit/Cancel
    " are exit-commands and are dispatched via AT SELECTION-SCREEN ON EXIT-COMMAND
    " instead, never reaching this method. Treating WHEN OTHERS as cancel here
    " would incorrectly abort the OAuth flow when the user clicks Execute.
    LEAVE TO SCREEN 0.

  ENDMETHOD.


  METHOD enrich_title_by_hostname.

    DATA lv_host TYPE string.

    FIND REGEX 'https?://([^/:]*)' IN iv_url SUBMATCHES lv_host ##REGEX_POSIX.
    IF lv_host IS NOT INITIAL AND lv_host <> space.
      CONCATENATE 'SSO Login:' lv_host INTO sc_otit
        IN CHARACTER MODE SEPARATED BY space.
    ENDIF.

  ENDMETHOD.


  METHOD open_browser.

    TRY.
        zcl_abapgit_ui_factory=>get_frontend_services( )->execute(
          iv_document = iv_url ).
      CATCH zcx_abapgit_exception ##NO_HANDLER.
    ENDTRY.

  ENDMETHOD.

ENDCLASS.


FORM oauth_device_popup
      USING
        pv_url       TYPE string
      CHANGING
        cv_token     TYPE string
        cv_use_basic TYPE abap_bool ##CALLED.

  " Let zcx_abapgit_exception propagate: acquire_login_details handles it.
  " Only cx_sy_dyn_call_illegal_form (API context) must be caught here.
  lcl_oauth_device_dialog=>popup(
    EXPORTING
      iv_url       = pv_url
    IMPORTING
      ev_use_basic = cv_use_basic
    RECEIVING
      rv_token     = cv_token ).

ENDFORM.

