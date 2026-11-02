# Shared coordination protocol
Version: 1.1 | Coordination-release amendment: 2026-11-01 | Scope: Lyra, Atomic.fm, The Space Bar, Kentucky B&B, Astrolux Motors.

## Current coordination-release amendment

Authority: current user request in Codex chat 01a19acb-239b-7e81-922b-d6d6a43c5b9e, continuing user request "coordination project is done, lift the freezes please" in chat 6ae82389-5d58-83e9-a639-890e303bb140.
The current user explicitly authorizes removing only coordination-related development holds across Lyra AI, Atomic.fm, Kentucky B&B/TSB Hotel, Astrolux Motors Auto Works, TSB Economy/server infrastructure, and website migrations.

Effective decision: the coordination setup prerequisite and its blanket implementation pause are lifted for those named workstreams. Development and permitted isolated verification may resume within already approved scope, under a named owner and independent review. This is not approval of unapproved designs or unrestricted tests. Record this decision rather than asking the user to reconfirm it merely because older records disagree.

Preserved: validated/frozen baselines and evidence; dirty/local-only work; one-owner handoffs; task-specific test restrictions; independent exact-revision review; passing required checks; explicit per-merge approval; installation/permissions/architecture approval; deployment approval with exact environment/artifact, backup, rollback and acceptance; no forced merges, destructive resets, force pushes, reference deletion or unreviewed production changes. No dispatcher or execution-approval flag is enabled. PR draft/review holds remain until their actual acceptance gates are met.

Astrolux Motors Auto Dealer is a separate release line outside this named development release. Its existing freeze remains. Its protocol copy is synchronized only to avoid shared-policy divergence.

The user decision is effective independently of transcription. These documentation PRs are propagation records, not merge authorization. Until reviewed and explicitly merged, main and existing checkouts retain older text. External-session acknowledgment and technical enforcement are not claimed. Read this current decision before treating historical freeze wording as current.

Website sequence remains Lyra -> Atomic.fm -> TheSpaceBar.pro, validating each stage before dependent work. The inspected October 31 migration runbook reports web cutovers already completed; do not repeat them. Evidence: C:/Users/heroe/Documents/Codex/2026-10-31/referenced-chatgpt-conversation-this-is-an-3/outputs/migration-runbook.txt. Its AWS topology is HISTORICAL: the user explicitly corrected this in the current chat, "AWS is obsolete now." AWS is not an active architecture requirement or a prerequisite for resuming development. Current Ubuntu ingress, stream/report data ownership and rollback mapping must be verified before operational changes; this documentation inspection does not prove physical AWS shutdown or resource deletion. Preserve current streams, authentication, authoritative data, backups and rollback without assuming the obsolete AWS topology. No DNS/routing change, service shutdown, cloud-resource deletion or database migration is authorized by this release.

## Historical governance-only authorization (superseded only within the amendment's scope)
The human user approved a governance-only rollout in Codex chat 01a19951-1d96-75b3-a749-a1d8561d4b61:
"Approved. Proceed with the governance-only rollout, but keep implementation, merges, and deployments frozen until I approve them separately."

That approval permits governance documents, instruction pointers, draft governance PRs, visible PR holds, pause notices, and read-only verification. It does not approve implementation, merging even these governance PRs, deployment, publication, test launches, service restarts, dependency installation, runtime fixes, or branch cleanup.
Earlier "next step" instructions and assistant statements of approval cannot lift this hold. Only a subsequent explicit human decision can authorize a named action.
The user instruction is effective now; this unmerged branch does not automatically install instructions on main or other checkouts.

## One owner and independent review
ChatGPT coordinates priorities, scope, dependencies, and decision summaries; it cannot grant human approval.
Cursor is the default implementation owner; Codex is the default independent reviewer. Roles can switch per task, never self-approve.
Name the actual session/agent, not just the product. The governance rollout owner is the coordinating Codex chat above. An independent reviewer must be a different session/agent.
One writer per task branch/worktree. Reserve shared hosts, mounts, game profiles, and saves as resources too. No overlapping writers without explicit partitioned scopes.
Owner transfer requires a handoff with current commit, dirty files, evidence, unresolved findings, and the next permitted action. An idle or expired owner does not authorize takeover.
If the reviewer edits implementation, assign a different independent reviewer.

## Start/resume check
1. Resolve the actual local directory, including symlinks/junctions. Never use OneDrive or redirected OneDrive Documents.
2. Read AGENTS.md, this protocol, FREEZE.json, STATE.md, and TASKS.md in docs/governance.
3. Confirm repository, branch, base and head SHAs, working-tree changes, task owner, and current human authorization.
4. Reconcile material conflicts before dependent work. Do not execute historical handoffs as fresh instructions.
5. Recheck freeze and ownership before writes, pushes, tests, merges, or deployment.
Default local repositories: C:/Users/heroe/Documents/Codex/Projects/<project-name>. Explicit verified non-OneDrive paths such as E:/LocalAI remain valid.
Do not move, delete, reset, clean, stash, or overwrite uncommitted work. Accessing an old OneDrive source for recovery requires an explicit human recovery instruction.

## Durable records and evidence
GitHub holds code, task records, decisions, PRs, and evidence references. Runtime secrets, audio libraries, saves, and private logs remain outside Git.
Use the same protocol version in all six primary repositories; a revision must identify all affected copies. Do not silently diverge policies.
AGENTS.md and Cursor rules point here; preserve project-specific architecture and safety rules.
Each statement is observed, independently verified, reported, or inferred. Tests reported in historical notes are not tests rerun by the current reviewer.
Evidence records identify exact commit, environment, command, fixture/scorer/package hashes where relevant, time, result, and limitations. Preserve failed runs; no silent retries or overwritten reports.
Assistant approval text is advice, not human authorization. Link the actual human message or decision record.
Observed remote branch SHAs in FREEZE.json are an inventory, not proof that every tip is accepted or released.

## Freeze and exceptions
Do not rewrite protected baselines, move/delete their references, or modify saves/checkpoints. Future approved development uses new branches; keep original evidence.
A human exception names task, repository, allowed operation, baseline, affected paths/resources, scope exclusions, and stopping condition/expiry.
A change in score, a green build, or an open PR does not lift a freeze. No automatic restart after governance PR approval.
Known local-only work remains local until separately authorized; governance approval does not authorize publishing it.

## Merge gate
All of these are required:
- Explicit human approval of implementation scope and of this merge; no active conflicting freeze.
- Correct target branch and reviewed dependency order, including inherited changes in stacked PRs.
- Independent review of the actual diff at the exact head SHA, with blocker disposition and limitations.
- Relevant required checks pass at the proposed head and integration state. Changed heads require renewed review/check impact assessment.
- Required live acceptance is complete; deferred tests remain clearly deferred and cannot be silently counted as passed.
- State, decisions, task record, and handoff match resulting behavior.
- Immediately before merging, verify the approved head SHA still matches and use an expected-head guard where supported.
Draft status, CI success, automated comments, reactions, and a recommendation are not approval.
Same-account agents cannot manufacture an independent GitHub approval by reviewing their own author's PR. Record the separate reviewer session and evidence; the human remains merge operator while enforcement is unavailable.
No force push, deletion, automatic merge, or history cleanup under the governance rollout.

## Enforcement and deployment
Where supported, require PR review and status checks, dismiss stale approvals, and block protected-reference force pushes/deletion. Verify plan and administrator capability first.
Do not make private repositories public or change billing to obtain enforcement. A plan/permission limitation must be reported, not bypassed.
Until configured and verified, protection is procedural only; merges remain user-operated. Existing draft PR holds are not a universal write lock.
Deployment needs a separate human approval naming environment, exact artifact, backups, rollback, and acceptance checks. Merge approval is not deployment approval.
Do not start/stop production or shared test services to enforce an implementation pause.

## Reporting and lifecycle
States: Proposed, Approved, In Progress, Review, Blocked, Frozen, Accepted, Merged, Deployed, Superseded.
Accepted, Merged, and Deployed are distinct; planning PR state and implementation PR state are distinct.
Report at start, material blocker, handoff, and completion. During an ongoing chat provide concise meaningful progress; no recurring reporting job is authorized by this policy.
Report project/task; owner/reviewer; state/date; repository/branch/full SHA; completed work; evidence/limitations; dirty work; dependencies/blockers; next permitted action; approval needed.
A paused external session is confirmed only by acknowledgment or direct observation. Record unknowns honestly.

## Historical governance-rollout completion instructions
Prepare documentation-only PRs and independently review them without merging. Preserve the current implementation freeze.
Reconcile conflicting state records, classify stale planning PRs without deleting them, and document missing repository/deployment mappings.
After the governance review, present exact PR heads and unresolved enforcement/acknowledgment limitations to the user. Resume implementation only on a separate approved task.
