CLASS ltcl_rfc_mock DEFINITION FOR TESTING.

  PUBLIC SECTION.
    INTERFACES zif_abapgit_rfc_client.

    DATA mv_ping_called    TYPE abap_bool.
    DATA mv_list_called    TYPE abap_bool.
    DATA mv_bulk_called    TYPE abap_bool.
    DATA mv_last_package   TYPE devclass.
    DATA mt_tadir_to_return  TYPE zif_abapgit_rfc_client=>ty_remote_tadir_tt.
    DATA mt_objects_to_return TYPE zif_abapgit_rfc_client=>ty_remote_objects_tt.

ENDCLASS.


CLASS ltcl_rfc_mock IMPLEMENTATION.

  METHOD zif_abapgit_rfc_client~ping.
    mv_ping_called = abap_true.
    rs_result-destination = iv_destination.
    rs_result-reachable   = abap_true.
    rs_result-agent_version = '1.0.0'.
  ENDMETHOD.

  METHOD zif_abapgit_rfc_client~list_package.
    mv_list_called  = abap_true.
    mv_last_package = iv_package.
    rt_tadir = mt_tadir_to_return.
  ENDMETHOD.

  METHOD zif_abapgit_rfc_client~serialize_object.
    " not used here
  ENDMETHOD.

  METHOD zif_abapgit_rfc_client~bulk_serialize.
    mv_bulk_called = abap_true.
    rt_objects = mt_objects_to_return.
  ENDMETHOD.

ENDCLASS.


CLASS ltcl_repo_rfc DEFINITION FOR TESTING RISK LEVEL HARMLESS DURATION SHORT FINAL.

  PRIVATE SECTION.
    DATA mo_cut  TYPE REF TO zcl_abapgit_repo_rfc.
    DATA mo_mock TYPE REF TO ltcl_rfc_mock.

    METHODS:
      setup,
      teardown,
      destination_roundtrip       FOR TESTING RAISING cx_static_check,
      package_roundtrip           FOR TESTING RAISING cx_static_check,
      ping_without_dest_raises    FOR TESTING RAISING cx_static_check,
      ping_delegates_to_client    FOR TESTING RAISING cx_static_check,
      refresh_without_dest_raises FOR TESTING RAISING cx_static_check,
      refresh_without_pack_raises FOR TESTING RAISING cx_static_check,
      refresh_populates_remote    FOR TESTING RAISING cx_static_check.

    METHODS make_cut.

ENDCLASS.


CLASS ltcl_repo_rfc IMPLEMENTATION.

  METHOD make_cut.

    DATA ls_data TYPE zif_abapgit_persistence=>ty_repo.

    ls_data-key     = 'TESTRFC'.
    ls_data-offline = abap_true.
    ls_data-package = '$TMP'.

    CREATE OBJECT mo_cut
      EXPORTING
        is_data = ls_data.

  ENDMETHOD.

  METHOD setup.
    CREATE OBJECT mo_mock.
    zcl_abapgit_injector=>set_rfc_client( mo_mock ).
    make_cut( ).
  ENDMETHOD.

  METHOD teardown.
    DATA li_null TYPE REF TO zif_abapgit_rfc_client.
    CREATE OBJECT li_null TYPE zcl_abapgit_rfc_client_null.
    zcl_abapgit_injector=>set_rfc_client( li_null ).
  ENDMETHOD.

  METHOD destination_roundtrip.

    mo_cut->set_rfc_destination( 'MY_PRD' ).
    cl_abap_unit_assert=>assert_equals(
      act = mo_cut->get_rfc_destination( )
      exp = 'MY_PRD' ).

  ENDMETHOD.

  METHOD package_roundtrip.

    mo_cut->set_remote_package( 'ZPKG_TEST' ).
    cl_abap_unit_assert=>assert_equals(
      act = mo_cut->get_remote_package( )
      exp = 'ZPKG_TEST' ).

  ENDMETHOD.

  METHOD ping_without_dest_raises.

    TRY.
        mo_cut->ping_remote( ).
        cl_abap_unit_assert=>fail( msg = 'expected exception not raised' ).
      CATCH zcx_abapgit_exception ##NO_HANDLER.
        " expected
    ENDTRY.

  ENDMETHOD.

  METHOD ping_delegates_to_client.

    DATA ls_result TYPE zif_abapgit_rfc_client=>ty_ping_result.

    mo_cut->set_rfc_destination( 'MY_PRD' ).
    ls_result = mo_cut->ping_remote( ).

    cl_abap_unit_assert=>assert_equals(
      act = mo_mock->mv_ping_called
      exp = abap_true ).
    cl_abap_unit_assert=>assert_equals(
      act = ls_result-reachable
      exp = abap_true ).
    cl_abap_unit_assert=>assert_equals(
      act = ls_result-destination
      exp = 'MY_PRD' ).

  ENDMETHOD.

  METHOD refresh_without_dest_raises.

    mo_cut->set_remote_package( 'ZPKG_TEST' ).
    TRY.
        mo_cut->refresh_from_remote( ).
        cl_abap_unit_assert=>fail( msg = 'expected exception not raised' ).
      CATCH zcx_abapgit_exception ##NO_HANDLER.
        " expected
    ENDTRY.

  ENDMETHOD.

  METHOD refresh_without_pack_raises.

    mo_cut->set_rfc_destination( 'MY_PRD' ).
    TRY.
        mo_cut->refresh_from_remote( ).
        cl_abap_unit_assert=>fail( msg = 'expected exception not raised' ).
      CATCH zcx_abapgit_exception ##NO_HANDLER.
        " expected
    ENDTRY.

  ENDMETHOD.

  METHOD refresh_populates_remote.

    DATA ls_tadir   TYPE zif_abapgit_rfc_client=>ty_remote_tadir.
    DATA ls_object  TYPE zif_abapgit_rfc_client=>ty_remote_object.
    DATA ls_file    TYPE zif_abapgit_git_definitions=>ty_file.
    DATA lt_remote  TYPE zif_abapgit_git_definitions=>ty_files_tt.

    ls_tadir-pgmid    = 'R3TR'.
    ls_tadir-object   = 'CLAS'.
    ls_tadir-obj_name = 'ZCL_FOO'.
    ls_tadir-devclass = 'ZPKG_TEST'.
    APPEND ls_tadir TO mo_mock->mt_tadir_to_return.

    ls_file-path     = '/src/'.
    ls_file-filename = 'zcl_foo.clas.abap'.
    ls_file-data     = cl_abap_codepage=>convert_to( 'CLASS zcl_foo DEFINITION PUBLIC. ENDCLASS.' ).
    APPEND ls_file TO ls_object-files.
    ls_object-pgmid    = ls_tadir-pgmid.
    ls_object-object   = ls_tadir-object.
    ls_object-obj_name = ls_tadir-obj_name.
    APPEND ls_object TO mo_mock->mt_objects_to_return.

    mo_cut->set_rfc_destination( 'MY_PRD' ).
    mo_cut->set_remote_package( 'ZPKG_TEST' ).

    mo_cut->refresh_from_remote( ).

    cl_abap_unit_assert=>assert_equals(
      act = mo_mock->mv_list_called
      exp = abap_true ).
    cl_abap_unit_assert=>assert_equals(
      act = mo_mock->mv_bulk_called
      exp = abap_true ).
    cl_abap_unit_assert=>assert_equals(
      act = mo_mock->mv_last_package
      exp = 'ZPKG_TEST' ).

    lt_remote = mo_cut->get_files_remote( ).
    cl_abap_unit_assert=>assert_equals(
      act = lines( lt_remote )
      exp = 1 ).

  ENDMETHOD.

ENDCLASS.
