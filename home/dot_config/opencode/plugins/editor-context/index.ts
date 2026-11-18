import { Plugin } from "@opencode/plugin"
import { execFileSync } from "node:child_process"
import { readdirSync } from "node:fs"
import path from "node:path"

/**
 * Neovim editor context plugin — ported to the OpenCode V2 plugin API.
 *
 * V1 (opencode-nvim-editor-context) returned a `tool` map; V2 default-exports
 * Plugin.define({ id, setup }) and registers tools through ctx.tool.transform.
 * Command execution uses node:child_process instead of the Bun shell helper.
 */

const luaString = (value: string): string =>
  `"${value.replace(/\\/g, "\\\\").replace(/"/g, '\\"').replace(/\n/g, "\\n")}"`

const luaEval = (code: string): string => `luaeval('${code.replace(/'/g, "''")}')`

const runNvim = (socket: string, expr: string): string => {
  return execFileSync(
    "nvim",
    ["--headless", "--server", socket, "--remote-expr", expr],
    { encoding: "utf8", timeout: 15000 },
  )
}

const formatRpcError = (e: any, socket: string, expr: string): string => {
  const stdout = e?.stdout ? String(e.stdout).trim() || "<empty>" : "<empty>"
  const stderr = e?.stderr ? String(e.stderr).trim() || "<empty>" : "<empty>"
  const code = e?.status ?? "?"
  return (
    "Neovim RPC command failed.\n\n" +
    `Socket: ${socket}\n` +
    `Expression: ${expr}\n` +
    `Exit code: ${code}\n\n` +
    `stdout:\n${stdout}\n\n` +
    `stderr:\n${stderr}`
  )
}

const noSocketMessage = (): string =>
  "Could not find a running Neovim instance.\n\n" +
  "Set NVIM_SOCKET where OpenCode runs, or start Neovim with --listen:\n" +
  "  export NVIM_SOCKET=/tmp/nvim.sock\n" +
  "  nvim --listen $NVIM_SOCKET"

const listSockets = (dir: string): string[] => {
  try {
    return readdirSync(dir)
      .filter((name) => name.startsWith("nvim"))
      .map((name) => path.join(dir, name))
  } catch {
    return []
  }
}

const isLive = (socket: string): boolean => {
  try {
    runNvim(socket, "1+1")
    return true
  } catch {
    return false
  }
}

const discoverNvimSocket = (): string | null => {
  if (process.env.NVIM_SOCKET) return process.env.NVIM_SOCKET
  if (process.platform === "win32") return null

  const candidates = [
    ...listSockets(path.join(process.env.TMPDIR || "/tmp", `nvim.${process.env.USER || "unknown"}`)),
    ...listSockets("/tmp"),
  ]

  let fallback: string | null = null
  for (const socket of candidates) {
    if (!isLive(socket)) continue
    try {
      const cwd = runNvim(socket, luaEval("vim.fn.getcwd()")).trim()
      if (cwd === process.cwd()) return socket
    } catch {}
    if (!fallback) fallback = socket
  }
  return fallback
}

export default Plugin.define({
  id: "editor-context",
  async setup(ctx) {
    const directory = ctx.location.directory

    await ctx.tool.transform((editor) => {
      editor.add({
        name: "editor_context",
        description:
          "Get the user's current Neovim editor state: open file, cursor position, " +
          "visual selection, and diagnostics. Use this when the user refers to " +
          "'this', 'here', 'the current file', 'my selection', 'what I'm looking at', " +
          "or similar. The selection text is included in the response — you do not " +
          "need to read the file separately unless you need more surrounding context.",
        input: {
          type: "object",
          properties: {},
          additionalProperties: false,
        },
        async execute() {
          const socket = discoverNvimSocket()
          if (!socket) return { content: noSocketMessage() }
          const expr = luaEval("EditorContext()")
          try {
            return { content: runNvim(socket, expr).trim() }
          } catch (e: any) {
            return { content: formatRpcError(e, socket, expr) }
          }
        },
      })

      editor.add({
        name: "editor_view",
        description:
          "Open a file or highlight code in the user's Neovim editor. Use this when " +
          "the user asks to 'show me', 'open this', 'take me there', 'highlight that code', " +
          "or when you want to point the user at exact code you are discussing. This changes " +
          "the visible Neovim editor state but does not modify files or visual selection. " +
          "Do not use this to read file contents; use read/search tools for analysis.",
        input: {
          type: "object",
          properties: {
            filePath: {
              type: "string",
              description:
                "Absolute path or path relative to the current project to open in Neovim.",
            },
            line: { type: "number", description: "1-indexed line to move the cursor to." },
            column: {
              type: "number",
              description:
                "1-indexed column to move the cursor to or start a highlighted range.",
            },
            endLine: {
              type: "number",
              description:
                "1-indexed end line for a highlighted range. Multi-line ranges without columns highlight full lines.",
            },
            endColumn: { type: "number", description: "1-indexed end column for a highlighted range." },
            highlight: {
              type: "boolean",
              description:
                "Whether to highlight the range. Defaults to true when endLine or endColumn is provided.",
            },
          },
          required: ["filePath"],
          additionalProperties: false,
        },
        async execute(input) {
          const args = input as {
            filePath: string
            line?: number
            column?: number
            endLine?: number
            endColumn?: number
            highlight?: boolean
          }
          const socket = discoverNvimSocket()
          if (!socket) return { content: noSocketMessage() }

          const filePath = path.isAbsolute(args.filePath)
            ? args.filePath
            : path.join(directory, args.filePath)
          const payload = JSON.stringify({ ...args, filePath })
          const expr = luaEval(`EditorView(${luaString(payload)})`)

          try {
            const parsed = JSON.parse(runNvim(socket, expr).trim())
            if (parsed.error) {
              return { content: `Failed to update Neovim view: ${parsed.error}` }
            }
            const location = parsed.line
              ? ` at line ${parsed.line}${parsed.column ? `, column ${parsed.column}` : ""}`
              : ""
            const highlighted = parsed.highlighted ? " and highlighted the requested range" : ""
            return { content: `Opened ${parsed.file}${location}${highlighted}.` }
          } catch (e: any) {
            return { content: formatRpcError(e, socket, expr) }
          }
        },
      })
    })
  },
})
