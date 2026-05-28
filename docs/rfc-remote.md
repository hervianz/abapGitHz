# RFC remote repositories (skeleton)

> **Status:** PR #1 of a 4-PR series. This PR ships the architecture
> (interfaces, factory wiring, repo skeleton, tests). The real RFC
> agent function group and the diff UI ship in follow-up PRs. See
> "Roadmap" at the bottom.

## What it is

A new abapGit repo backend that treats a **remote SAP system**
(PRD, QA, or another DEV) as the read-only source of object
content, while the local DEV system remains the place where you
commit and push to git.

```
+----------------+        RFC (read-only)        +----------------+
|  Local DEV     |  <--------------------------  |  Remote PRD    |
|  (abapGit UI)  |     pull serialized files     |  (RFC agent)   |
+--------+-------+                                +----------------+
         |
         | git push (existing flow)
         v
   +-----------+
   |   git     |
   +-----------+
```

abapGit's invariant — *git is the source of truth, the local SAP
system is the working copy* — is preserved. The remote system is
only ever read. Deployments to PRD continue to go through the SAP
transport system, not through abapGit. **There is no write-to-PRD
path and there will not be one.**

## Why this design

- Modeled as a new repo class (`zcl_abapgit_repo_rfc`), sibling
  to `zcl_abapgit_repo_online` and `zcl_abapgit_repo_offline`.
- The RFC layer is hidden behind `zif_abapgit_rfc_client`, which
  is injectable via `zcl_abapgit_injector=>set_rfc_client`. The
  default `zcl_abapgit_rfc_client_null` returns an "agent not
  configured" error so the codebase remains buildable on systems
  that have not installed the remote agent.
- The remote agent (PR #2) calls `zcl_abapgit_objects=>serialize`
  on the remote side, so the file format pulled over RFC is
  **byte-for-byte the same** as what local abapGit would produce.
  That is what makes the comparison meaningful.

## Public API (PR #1)

### `zif_abapgit_rfc_client`

| Method             | Purpose                                                  |
|--------------------|----------------------------------------------------------|
| `ping`             | Handshake + return remote agent version, never raises.   |
| `list_package`     | Recursively list TADIR entries below a package.          |
| `serialize_object` | Fetch serialized files for a single TADIR key.           |
| `bulk_serialize`   | Batched variant of `serialize_object` (perf).            |

All methods are read-only. All raise `zcx_abapgit_exception` for
transport / authorization errors.

### `zcl_abapgit_repo_rfc`

Inherits from `zcl_abapgit_repo_offline` and adds:

- `set_rfc_destination` / `get_rfc_destination`
- `set_remote_package`  / `get_remote_package`
- `ping_remote`         — delegates to the injected client.
- `refresh_from_remote` — lists the remote package recursively,
  bulk-serializes all entries, and stores the result as the
  repo's "remote" file set, so the existing diff/stage code path
  (`zcl_abapgit_repo_status`, `zcl_abapgit_gui_page_stage`, etc.)
  is reused unchanged.

## Security model

- **Read-only RFC.** The agent function group (PR #2) will expose
  only `Z_ABAPGIT_RFC_PING`, `Z_ABAPGIT_RFC_LIST_PACKAGE`,
  `Z_ABAPGIT_RFC_SERIALIZE_OBJECT`, `Z_ABAPGIT_RFC_BULK_SERIALIZE`.
  No update / delete / activate FMs ship at any tier.
- **Remote-side `AUTHORITY-CHECK`.** Every FM on the agent side
  checks `S_DEVELOP` with `ACTVT = 03` (display) on the requested
  package / object. Customers should additionally restrict the
  RFC technical user to a display-only role.
- **No passwords on the wire.** Use a trusted RFC destination
  (SM59 → trusted system) or a technical user with display-only
  authorisations. abapGit never transmits credentials over the
  RFC link.
- **Audit log** (PR #4): every pull will be logged to a small
  remote-side log table including caller, destination, package,
  timestamp.

## Limits of CI testing

The PR #1 changes are validated by:

- `npx abaplint --format codeframe` — passes with 0 issues.
- ABAP unit tests for `zcl_abapgit_rfc_client_null` and
  `zcl_abapgit_repo_rfc` against a mock implementation of
  `zif_abapgit_rfc_client` injected via `zcl_abapgit_injector`.

The RFC layer itself (PR #2) can only be meaningfully tested on
a real two-system landscape: install the agent FG on PRD/QA,
create an SM59 destination from DEV, create an RFC repo, run
"Refresh from remote", verify package recursion, diff against
the git branch, commit. This requires a customer or sandbox
landscape; it cannot be reproduced in an abaplint CI sandbox.

## Roadmap

| PR  | Scope                                                                     |
|-----|---------------------------------------------------------------------------|
| #1  | **This PR.** Interface, null client, repo skeleton, factory/injector, tests, docs. |
| #2  | Remote agent function group + real `zcl_abapgit_rfc_client` + persistence for destination/package. |
| #3  | 3-way diff UI page (Remote ↔ Local DEV ↔ Git branch) and router wiring.   |
| #4  | Docs polish, audit log, hardening, customer-installable agent transport.  |
