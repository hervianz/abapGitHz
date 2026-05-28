CLASS zcl_abapgit_rfc_client_null DEFINITION
  PUBLIC
  CREATE PUBLIC .

* Default no-op implementation of zif_abapgit_rfc_client.
*
* Returned by zcl_abapgit_factory=>get_rfc_client when no real
* RFC agent client has been injected. Allows the rest of the
* codebase to depend on the interface without requiring the
* remote agent to be installed.
*
* All methods raise zcx_abapgit_exception with a clear message
* explaining that the RFC agent is not configured, except ping
* which returns reachable = abap_false so callers can render a
* friendly status without exception handling.

  PUBLIC SECTION.
    INTERFACES zif_abapgit_rfc_client .

    CONSTANTS c_not_configured_msg TYPE string
      VALUE 'RFC remote client not configured. Install the abapGit RFC agent and inject zif_abapgit_rfc_client.' ##NO_TEXT.

  PROTECTED SECTION.
  PRIVATE SECTION.
ENDCLASS.



CLASS zcl_abapgit_rfc_client_null IMPLEMENTATION.


  METHOD zif_abapgit_rfc_client~ping.

    rs_result-destination = iv_destination.
    rs_result-reachable   = abap_false.
    rs_result-message     = c_not_configured_msg.

  ENDMETHOD.


  METHOD zif_abapgit_rfc_client~list_package.

    zcx_abapgit_exception=>raise( c_not_configured_msg ).

  ENDMETHOD.


  METHOD zif_abapgit_rfc_client~serialize_object.

    zcx_abapgit_exception=>raise( c_not_configured_msg ).

  ENDMETHOD.


  METHOD zif_abapgit_rfc_client~bulk_serialize.

    zcx_abapgit_exception=>raise( c_not_configured_msg ).

  ENDMETHOD.
ENDCLASS.
