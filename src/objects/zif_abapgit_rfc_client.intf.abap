INTERFACE zif_abapgit_rfc_client
  PUBLIC .

* Read-only RFC client used to fetch serialized abapGit objects
* from a remote SAP system (PRD/QA/another DEV) for comparison
* against the local DEV system and/or the git branch.
*
* This is the DEV-side interface. The actual transport (RFC FMs
* such as Z_ABAPGIT_RFC_PING / Z_ABAPGIT_RFC_LIST_PACKAGE /
* Z_ABAPGIT_RFC_SERIALIZE_OBJECT) is implemented by a concrete
* class in a follow-up PR. The skeleton ships with a null
* implementation so the codebase stays buildable and testable
* on systems without the remote agent installed.
*
* All methods are READ-ONLY. Writing to the remote system over
* RFC is intentionally out of scope; deployments to PRD must go
* through the standard SAP transport system.

  CONSTANTS c_agent_min_version TYPE string VALUE '1.0.0' ##NO_TEXT.

  TYPES:
    BEGIN OF ty_ping_result,
      destination   TYPE rfcdest,
      system_id     TYPE sy-sysid,
      client        TYPE sy-mandt,
      agent_version TYPE string,
      reachable     TYPE abap_bool,
      message       TYPE string,
    END OF ty_ping_result .

  TYPES:
    BEGIN OF ty_remote_tadir,
      pgmid     TYPE tadir-pgmid,
      object    TYPE tadir-object,
      obj_name  TYPE tadir-obj_name,
      devclass  TYPE tadir-devclass,
      srcsystem TYPE tadir-srcsystem,
    END OF ty_remote_tadir .
  TYPES:
    ty_remote_tadir_tt TYPE STANDARD TABLE OF ty_remote_tadir WITH DEFAULT KEY .

  TYPES:
    BEGIN OF ty_remote_object,
      pgmid    TYPE tadir-pgmid,
      object   TYPE tadir-object,
      obj_name TYPE tadir-obj_name,
      devclass TYPE tadir-devclass,
      files    TYPE zif_abapgit_git_definitions=>ty_files_tt,
      sha1     TYPE zif_abapgit_git_definitions=>ty_sha1,
      message  TYPE string,
    END OF ty_remote_object .
  TYPES:
    ty_remote_objects_tt TYPE STANDARD TABLE OF ty_remote_object WITH DEFAULT KEY .

  METHODS ping
    IMPORTING
      !iv_destination  TYPE rfcdest
    RETURNING
      VALUE(rs_result) TYPE ty_ping_result
    RAISING
      zcx_abapgit_exception .

  METHODS list_package
    IMPORTING
      !iv_destination TYPE rfcdest
      !iv_package     TYPE devclass
      !iv_recursive   TYPE abap_bool DEFAULT abap_true
    RETURNING
      VALUE(rt_tadir) TYPE ty_remote_tadir_tt
    RAISING
      zcx_abapgit_exception .

  METHODS serialize_object
    IMPORTING
      !iv_destination  TYPE rfcdest
      !iv_pgmid        TYPE tadir-pgmid DEFAULT 'R3TR'
      !iv_object       TYPE tadir-object
      !iv_obj_name     TYPE tadir-obj_name
    RETURNING
      VALUE(rs_object) TYPE ty_remote_object
    RAISING
      zcx_abapgit_exception .

  METHODS bulk_serialize
    IMPORTING
      !iv_destination   TYPE rfcdest
      !it_tadir         TYPE ty_remote_tadir_tt
    RETURNING
      VALUE(rt_objects) TYPE ty_remote_objects_tt
    RAISING
      zcx_abapgit_exception .

ENDINTERFACE.
