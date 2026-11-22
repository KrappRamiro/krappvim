-- Splash mínimo con el formato de `milli export -t lua`, para el test de
-- header.milli.splashFile (scripts/dashboard-test.lua).
local M = { cols = 9, rows = 2, delays = { 200, 200 } }

M.frames = {}
M.frames[1] = { "  kvim   ", " fixture " }
M.frames[2] = { "  KVIM   ", " FIXTURE " }

return M
