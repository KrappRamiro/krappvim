-- Commits, issues, PRs y diff del repo actual. Solo aparece dentro de un
-- repo de git: afuera, gh y git solo escribirían errores.
local terminal = require("dashboard.terminal")

local function in_repo()
   return Snacks.git.get_root() ~= nil
end

return function(p)
   local n = p.limit
   local all = {
      commits = {
         icon = "\239\144\151 ", -- U+F417 (commit)
         title = "Commits recientes",
         cmd = "git -c color.ui=always log --oneline -6",
         height = 7,
      },
      issues = {
         icon = "\239\144\155 ", -- U+F41B (issue)
         title = "Open Issues",
         cmd = "gh issue list -L " .. n,
         height = n + 2,
         -- gh va a la red: cinco minutos de caché alcanzan
         ttl = 5 * 60,
      },
      prs = {
         icon = "\239\144\135 ", -- U+F407 (pull request)
         title = "Open PRs",
         cmd = "gh pr list -L " .. n,
         height = n + 2,
         ttl = 5 * 60,
      },
      diff = {
         icon = "\238\156\165 ", -- U+E725 (rama)
         title = "Cambios recientes",
         cmd = "git --no-pager diff --stat -B -M -C HEAD~3",
         height = 8,
      },
   }
   local sections = {}
   for _, name in ipairs(p.sections) do
      local s = all[name]
      s.indent, s.enabled = 3, in_repo
      sections[#sections + 1] = terminal(s)
   end
   return { sections = sections }
end
