CLASS ltcl_rfc_client_null DEFINITION FOR TESTING RISK LEVEL HARMLESS DURATION SHORT FINAL.

  PRIVATE SECTION.
    DATA mi_cut TYPE REF TO zif_abapgit_rfc_client.

    METHODS:
      setup,
      ping_returns_unreachable    FOR TESTING RAISING cx_static_check,
      list_package_raises         FOR TESTING RAISING cx_static_check,
      serialize_object_raises     FOR TESTING RAISING cx_static_check,
      bulk_serialize_raises       FOR TESTING RAISING cx_static_check.

ENDCLASS.


CLASS ltcl_rfc_client_null IMPLEMENTATION.

  METHOD setup.
    CREATE OBJECT mi_cut TYPE zcl_abapgit_rfc_client_null.
  ENDMETHOD.

  METHOD ping_returns_unreachable.

    DATA ls_result TYPE zif_abapgit_rfc_client=>ty_ping_result.

    ls_result = mi_cut->ping( 'NONE' ).

    cl_abap_unit_assert=>assert_equals(
      act = ls_result-reachable
      exp = abap_false ).
    cl_abap_unit_assert=>assert_equals(
      act = ls_result-destination
      exp = 'NONE' ).
    cl_abap_unit_assert=>assert_not_initial( act = ls_result-message ).

  ENDMETHOD.

  METHOD list_package_raises.

    TRY.
        mi_cut->list_package(
          iv_destination = 'NONE'
          iv_package     = '$TMP' ).
        cl_abap_unit_assert=>fail( msg = 'expected exception not raised' ).
      CATCH zcx_abapgit_exception ##NO_HANDLER.
        " expected
    ENDTRY.

  ENDMETHOD.

  METHOD serialize_object_raises.

    TRY.
        mi_cut->serialize_object(
          iv_destination = 'NONE'
          iv_object      = 'CLAS'
          iv_obj_name    = 'ZCL_DUMMY' ).
        cl_abap_unit_assert=>fail( msg = 'expected exception not raised' ).
      CATCH zcx_abapgit_exception ##NO_HANDLER.
        " expected
    ENDTRY.

  ENDMETHOD.

  METHOD bulk_serialize_raises.

    DATA lt_tadir TYPE zif_abapgit_rfc_client=>ty_remote_tadir_tt.

    TRY.
        mi_cut->bulk_serialize(
          iv_destination = 'NONE'
          it_tadir       = lt_tadir ).
        cl_abap_unit_assert=>fail( msg = 'expected exception not raised' ).
      CATCH zcx_abapgit_exception ##NO_HANDLER.
        " expected
    ENDTRY.

  ENDMETHOD.

ENDCLASS.
