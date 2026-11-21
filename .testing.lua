-- .testing.lua -- configuration of testing.nvim for this project.
-- Written by `testing migrate`; edit freely (it is never overwritten). Every key is optional; the
-- keys are documented in testing.nvim's docs/CONFIG.md. Loading this file executes it (same trust
-- as running the specs).
return {
  -- Lua module root of the project.
  plugin = "cmdlog",
  -- How the spec files are run: "auto" = sniffed per file, "h" = on the project's own TESTS/harness.lua,
  -- "script" = a self-running script in its own process.
  dialect = "auto",
  -- Dependencies (directory names) put on the runtimepath: $<NAME>_DIR, .deps/<name>, ../<name>,
  -- stdpath('data')/lazy/<name>.
  deps = { "lib.nvim", "telescope.nvim", "plenary.nvim" },
  -- "none" = all specs in one nvim, "file" = one nvim per spec file
  -- (nothing leaks from one file into the next).
  isolated = "none",
  -- "c" = child started from a -c command (v:vim_did_enter is 0, <cword> works),
  -- "l" = `nvim -l`.
  host = "l",
  -- Environment variables the specs read; a child editor inherits an allowlist only (never secrets).
  env_allow = { "LIB_NVIM_PATH", "REPOS_DIR" },
  -- Guards (docs/GUARDS.md). Strict, so that a new finding turns the run red.
  -- sheets_spec.lua runs every test sheet in a child editor of its own: far more than the default 10 s and 60 s
  -- on a machine under load.
  timeouts = { case_ms = 30000, file_ms = 300000 },
  guards = {
    fs = "error",
    state = "error",
    scheduled_error = "error",
    prompt = "error",
    deprecation = "error",
    process_net = "error",
  },
  -- What the specs may start on purpose, and nothing else.
  guard_allow = {
    fs = {},
    spawn = {
      -- smoke_spec.lua really runs the headless Neovim of the :help preview; sheets_spec.lua runs
      -- every test sheet (TESTS/sheets/) in a child editor.
      "nvim",
      -- smoke_spec.lua runs the fzf-lua previewer's shell one-liners as fzf-lua does (not on Windows).
      "sh",
    },
    network = {},
  },
  -- gated: a failed conformance check makes `scripts/test.sh conformance` exit 1 (docs/CONFORMANCE.md of testing.nvim)
  conformance = { gate = true },
  ci = {
    -- The GitHub workflow, generated: `testing init --workflow=public --force` writes .github/workflows/ci.yml from
    -- this (testing.nvim docs/WORKFLOW-CI.md); the step workflow-in-sync keeps the two together.
    workflow = {
      name = "cmdlog.nvim",
      layout = "hosted",
      -- the steps that depend on the platform: the windows and macOS legs run only these
      platform = { "suite", "conformance" },
      -- `testing ci land`: a check branch ci/** runs the hosted legs, main moves to a commit only once it is green there
      land = true,
      -- telescope.nvim and plenary.nvim are in `deps` (on the runtimepath of the specs); naming them here makes the
      -- generator check them out from these pinned commits instead of a WKDSteve repository at ci-verified.
      checkouts = {
        {
          repo = "nvim-telescope/telescope.nvim",
          ref = "40aedd8a68c78a656a10a8d62d80c54af59420fb",
          why = "the default picker: the telescope modules get real require() coverage instead of being skipped",
        },
        {
          repo = "nvim-lua/plenary.nvim",
          ref = "74b06c6c75e4eeb3108ec01852001636d85a932b",
          why = "telescope.nvim does not load without it",
        },
      },
    },
    steps = {
      ["workflow-in-sync"] = { preset = "workflow-in-sync" },
    },
  },
}
