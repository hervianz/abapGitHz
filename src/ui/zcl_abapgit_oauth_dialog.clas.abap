CLASS zcl_abapgit_oauth_dialog DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.

    CLASS-METHODS popup
      IMPORTING
        !iv_url          TYPE string
      EXPORTING
        !ev_use_basic    TYPE abap_bool
      RETURNING
        VALUE(rv_token)  TYPE string
      RAISING
        zcx_abapgit_exception.

  PROTECTED SECTION.
  PRIVATE SECTION.

ENDCLASS.



CLASS zcl_abapgit_oauth_dialog IMPLEMENTATION.


  METHOD popup.

    DATA lx_error TYPE REF TO cx_sy_dyn_call_illegal_form.

    ev_use_basic = abap_false.

    TRY.
        PERFORM oauth_device_popup
          IN PROGRAM (sy-cprog)
          USING iv_url
          CHANGING rv_token ev_use_basic.
      CATCH cx_sy_dyn_call_illegal_form INTO lx_error.
        zcx_abapgit_exception=>raise_with_text( lx_error ).
    ENDTRY.

  ENDMETHOD.

ENDCLASS.
