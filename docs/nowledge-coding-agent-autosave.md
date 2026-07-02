# Nowledge autosave for external coding-agent runners

## Problem

Hermes Studio can run external coding agents, including Codex and Claude Code,
through the `coding-agent-run` wrapper. The wrapper starts a tool-specific CLI
(`codex exec`, `claude print`), flushes the response back into the Hermes Studio
chat database, and then marks the external run complete.

Observed log shape:

```text
[coding-agent-run] print runner started
[coding-agent-run] recorded Codex native session id
[coding-agent-run] codex exec exited
[chat-run-socket] flushResponseRunToDb
[chat-run-socket] external run completed
```

```text
[coding-agent-run] print runner started
[chat-run-socket] flushResponseRunToDb
[coding-agent-run] claude print exited
[chat-run-socket] external run completed
```

The external agents may have their own Nowledge Mem Stop hooks, but those hooks
are not reliable in this wrapper flow. In verified Hermes Studio sessions, the
agent transcripts were written locally and Hermes Studio DB flush succeeded, but
no remote Nowledge thread was created until `nmem threads save` was run manually.

## Verified examples

### Codex

Hermes Studio session id:

```text
mr3eiohc924sn8
```

Codex native session id recorded by Hermes Studio:

```text
019f2284-4f34-7cd0-b1db-c5bc58c4271e
```

Manual recovery command:

```bash
CODEX_HOME=/home/agent/.hermes-web-ui/coding-agent/model/default/custom_axonhub.nasw.heiyu.space/codex \
  nmem threads save --from codex --truncate \
  --session-id 019f2284-4f34-7cd0-b1db-c5bc58c4271e
```

Created thread:

```text
codex-019f2284-4f34-7cd0-b1db-c5bc58c4271e
```

### Claude Code

Hermes Studio session id:

```text
mr3eoys1vax19g
```

Claude Code native transcript id:

```text
1a7b6ed3-9c6a-47ee-bf7d-e42891992af2
```

Manual recovery command:

```bash
nmem threads save --from claude-code --truncate \
  --session-id 1a7b6ed3-9c6a-47ee-bf7d-e42891992af2
```

Created thread:

```text
claude-code-1a7b6ed3-9c6a-47ee-bf7d-e42891992af2
```

## Proposed fix

Hermes Studio should perform runner-level autosave after an external coding-agent
run completes and the response has been flushed to the Hermes Studio DB.

Recommended flow:

```text
external coding-agent run completes
        ↓
flushResponseRunToDb succeeds
        ↓
if Nowledge autosave is enabled and nmem is available
        ↓
call nmem threads save for the matching agent/native session
```

The save should be best-effort: failures must be logged but must not fail the
user-visible chat run.

## Suggested implementation contract

Add a helper around the external runner completion path:

```ts
async function saveCodingAgentThreadToNowledge(args: {
  agentId: string
  sessionId: string              // Hermes Studio session id
  nativeSessionId?: string       // Codex/Claude native transcript id when known
  cwd: string
  profile: string
  codexHome?: string
})
```

Source mapping:

```ts
const nowledgeSourceByAgentId: Record<string, string> = {
  'codex': 'codex',
  'claude-code': 'claude-code',
}
```

Codex command:

```bash
CODEX_HOME=<Hermes-managed Codex runtime> \
  nmem threads save --from codex --truncate --session-id <nativeSessionId>
```

Claude Code command:

```bash
nmem threads save --from claude-code --truncate --session-id <nativeSessionId>
```

If Claude Code native session id is not available, prefer recording it from the
Claude CLI invocation. A temporary fallback can call `nmem threads save --from
claude-code --truncate`, but passing the native id is safer for concurrent or
recent sessions.

## Logging

Success:

```text
[coding-agent-run] Nowledge autosave completed
```

Failure:

```text
[coding-agent-run] Nowledge autosave failed
```

The warning should include `agentId`, Hermes `sessionId`, `nativeSessionId` when
available, and the non-secret command shape.

## Acceptance criteria

1. A new Hermes Studio Codex chat creates a remote Nowledge thread with
   `source=codex` and id `codex-<nativeSessionId>` after the runner completes.
2. A new Hermes Studio Claude Code chat creates a remote Nowledge thread with
   `source=claude-code` and id `claude-code-<nativeSessionId>` after the runner
   completes.
3. The save works even when the external CLI's own Stop hook does not fire.
4. Nowledge save failure does not break the chat response.
5. Logs include enough IDs to map Hermes Studio sessions to saved Nowledge
   threads.

## Complementary Nowledge change

Nowledge community can provide a recovery helper for historical/backfill cases,
for example mapping a Hermes Studio session id to a Codex/Claude Code transcript
and running the same `nmem threads save` command. That fallback does not replace
this runner-level fix, because Hermes Studio is the component that knows exactly
when a run has completed and which native session id was produced.
