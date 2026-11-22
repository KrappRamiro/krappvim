-- drop.nvim: cosas que caen sobre el dashboard (hojas, nieve, según la
-- fecha con theme = "auto"). Solo está en el build si
-- settings.dashboard.overlay.drop.enable es true (nix/dashboard/deps.nix);
-- si no, auto_enable hace que lze ignore esta spec.
return {
   "drop",
   auto_enable = true,
   -- Carga cuando snacks ya dibujó el dashboard: drop busca los buffers con
   -- su filetype al hacer setup.
   event = "User SnacksDashboardOpened",
   after = function(_)
      local d = nixInfo({}, "settings", "dashboard", "overlay", "drop")
      require("drop").setup(require("dashboard.extras").drop_opts(d))
   end,
}
