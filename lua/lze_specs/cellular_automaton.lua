-- cellular-automaton.nvim: tecla de broma que "derrite" el buffer
-- (make_it_rain). Solo está en el build si
-- settings.dashboard.extras.cellularAutomaton.enable es true; la tecla
-- también sale de ahí.
local key = nixInfo("<leader>ur", "settings", "dashboard", "extras", "cellularAutomaton", "keymap")

return {
   "cellular-automaton.nvim",
   auto_enable = true,
   keys = {
      {
         key,
         function()
            require("cellular-automaton").start_animation("make_it_rain")
         end,
         desc = "Make it rain (cellular-automaton)",
      },
   },
}
