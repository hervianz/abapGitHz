CLASS zcl_abapgit_repo_rfc DEFINITION
  PUBLIC
  INHERITING FROM zcl_abapgit_repo
  CREATE PUBLIC .

* Skeleton for the new "RFC remote" repo backend.
*
* Models a remote SAP system (PRD/QA/another DEV) as the source
* of truth for object content, while still using the local DEV
* system to commit/push the result back to git.
*
* PR #1 scope (this file):
*   - Persists nothing extra; the RFC destination and remote
*     package are held in-memory and provided by callers.
*     Schema changes are intentionally deferred to PR #2 to keep
*     this PR non-breaking and reviewable.
*   - Exposes pin-points (refresh_from_remote, ping_remote) that
*     delegate to the injectable zif_abapgit_rfc_client. With the
*     default null client these will surface a clear "agent not
*     installed" error instead of silently doing nothing.
*
* Why inherit from zcl_abapgit_repo (not zcl_abapgit_repo_offline):
*   The remote side is fetched ad-hoc over RFC, not from a git
*   server. We need offline-style "remote is preserved on reset"
*   behavior, but zcl_abapgit_repo_offline is declared FINAL and
*   cannot be subclassed, so we inherit directly from the base
*   class and re-implement the small reset_remote override.
*   The "remote" file table is the right place to stash the
*   RFC-fetched files so the existing diff/stage flow can
*   consume them unchanged.

  PUBLIC SECTION.

    METHODS set_rfc_destination
      IMPORTING
        !iv_destination TYPE rfcdest .

    METHODS get_rfc_destination
      RETURNING
        VALUE(rv_destination) TYPE rfcdest .

    METHODS set_remote_package
      IMPORTING
        !iv_package TYPE devclass .

    METHODS get_remote_package
      RETURNING
        VALUE(rv_package) TYPE devclass .

    METHODS ping_remote
      RETURNING
        VALUE(rs_result) TYPE zif_abapgit_rfc_client=>ty_ping_result
      RAISING
        zcx_abapgit_exception .

    METHODS refresh_from_remote
      RAISING
        zcx_abapgit_exception .

  PROTECTED SECTION.

    METHODS reset_remote
        REDEFINITION .

  PRIVATE SECTION.

    DATA mv_rfc_destination TYPE rfcdest .
    DATA mv_remote_package  TYPE devclass .

ENDCLASS.



CLASS zcl_abapgit_repo_rfc IMPLEMENTATION.


  METHOD set_rfc_destination.
    mv_rfc_destination = iv_destination.
  ENDMETHOD.


  METHOD reset_remote.

    DATA lt_backup LIKE mt_remote.

    " Preserve the last RFC-fetched remote across base resets,
    " same idea as zcl_abapgit_repo_offline: there's no upstream
    " source we can re-fetch from automatically (the user must
    " trigger refresh_from_remote explicitly).
    lt_backup = mt_remote.
    super->reset_remote( ).
    set_files_remote( lt_backup ).

  ENDMETHOD.


  METHOD get_rfc_destination.
    rv_destination = mv_rfc_destination.
  ENDMETHOD.


  METHOD set_remote_package.
    mv_remote_package = iv_package.
  ENDMETHOD.


  METHOD get_remote_package.
    rv_package = mv_remote_package.
  ENDMETHOD.


  METHOD ping_remote.

    DATA li_client TYPE REF TO zif_abapgit_rfc_client.

    IF mv_rfc_destination IS INITIAL.
      zcx_abapgit_exception=>raise( 'RFC destination not set on repo' ).
    ENDIF.

    li_client = zcl_abapgit_factory=>get_rfc_client( ).
    rs_result = li_client->ping( mv_rfc_destination ).

  ENDMETHOD.


  METHOD refresh_from_remote.

    DATA li_client    TYPE REF TO zif_abapgit_rfc_client.
    DATA lt_tadir     TYPE zif_abapgit_rfc_client=>ty_remote_tadir_tt.
    DATA lt_objects   TYPE zif_abapgit_rfc_client=>ty_remote_objects_tt.
    DATA lt_files     TYPE zif_abapgit_git_definitions=>ty_files_tt.
    DATA ls_file      TYPE zif_abapgit_git_definitions=>ty_file.

    FIELD-SYMBOLS <ls_object> TYPE zif_abapgit_rfc_client=>ty_remote_object.

    IF mv_rfc_destination IS INITIAL.
      zcx_abapgit_exception=>raise( 'RFC destination not set on repo' ).
    ENDIF.
    IF mv_remote_package IS INITIAL.
      zcx_abapgit_exception=>raise( 'Remote package not set on repo' ).
    ENDIF.

    li_client = zcl_abapgit_factory=>get_rfc_client( ).

    lt_tadir = li_client->list_package(
      iv_destination = mv_rfc_destination
      iv_package     = mv_remote_package
      iv_recursive   = abap_true ).

    IF lt_tadir IS INITIAL.
      set_files_remote( lt_files ).
      RETURN.
    ENDIF.

    lt_objects = li_client->bulk_serialize(
      iv_destination = mv_rfc_destination
      it_tadir       = lt_tadir ).

    LOOP AT lt_objects ASSIGNING <ls_object>.
      LOOP AT <ls_object>-files INTO ls_file.
        APPEND ls_file TO lt_files.
      ENDLOOP.
    ENDLOOP.

    set_files_remote( lt_files ).

  ENDMETHOD.


ENDCLASS.
