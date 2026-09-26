{
  config,
  lib,
  pkgs,
  ...
}:
let
  makiCfg = config.modules.home.terminal.maki;

  usageLib = import ../../../lib/usage-fetch.nix { inherit pkgs; };

  shimScript = pkgs.writeShellApplication {
    name = "maki-statusline-shim";
    runtimeInputs = with pkgs; [
      bash
      curl
      jq
      coreutils
    ];
    text = ''
      # shellcheck source=/dev/null
      . ${usageLib.script}
      cache_json="''${MAKI_QUOTA_CACHE_JSON:-/tmp/maki-quota-cache.json}"
      cache_ts="''${MAKI_QUOTA_CACHE_TS:-/tmp/maki-quota-cache.ts}"

      lim5h=""
      lim7d=""
      if [ -n "''${ZHIPU_API_KEY:-}" ]; then
        fetch_zclaude_usage "" "$cache_json" "$cache_ts" || true
      elif [ -n "''${OPENCODE_API_KEY:-}" ]; then
        fetch_oclaude_usage "" "$cache_json" "$cache_ts" || true
      fi

      if [ -n "$lim5h" ]; then printf '5h=%s\n' "$lim5h"; fi
      if [ -n "$lim7d" ]; then printf '7d=%s\n' "$lim7d"; fi
    '';
  };

  pluginLua = ''
    local M = {}

    local state = {
      ctx_size = 0,
      ctx_window = 0,
      cost = 0,
      lim_5h = nil,
      lim_7d = nil,
    }

    local buf = nil

    local function pct_color(pct)
      if pct >= 80 then
        return { fg = "#ff5555", bold = true }
      elseif pct >= 50 then
        return { fg = "#ffff55" }
      else
        return { fg = "#55ff55" }
      end
    end

    local function build_bar(pct)
      local filled = math.min(math.floor(pct / 10), 10)
      local empty = 10 - filled
      return string.rep("█", filled) .. string.rep("░", empty)
    end

    local function render()
      if not buf then return end
      local model = maki.model.get()
      local model_id = (model and model.id) or "unknown"

      local ctx_pct = 0
      if state.ctx_window > 0 then
        ctx_pct = math.floor(state.ctx_size * 100 / state.ctx_window)
      end

      local line = {
        { "🤖 ", { fg = "#00ffff", bold = true } },
        { model_id, { fg = "#00ffff", bold = true } },
        { "  ctx " },
        { build_bar(ctx_pct), pct_color(ctx_pct) },
        { string.format(" %d%%", ctx_pct) },
      }

      if state.cost and state.cost > 0 then
        table.insert(line, { "  " })
        table.insert(line, {
          string.format("$%.2f", state.cost),
          { fg = "#55ff55", bold = true },
        })
      end

      if state.lim_5h then
        table.insert(line, {
          string.format("  5h %d%%", state.lim_5h),
          pct_color(state.lim_5h),
        })
      end

      if state.lim_7d then
        table.insert(line, {
          string.format("  7d %d%%", state.lim_7d),
          pct_color(state.lim_7d),
        })
      end

      buf:set_lines({ line })
    end

    local function fetch_quota()
      local shim = (os.getenv("HOME") or "") .. "/.config/maki/lib/usage-fetch.sh"
      local ok, job_id = pcall(maki.fn.jobstart, { shim }, {
        scope = "plugin",
        name = "maki-statusline-quota",
      })
      if not ok or not job_id then return end

      maki.async.run(function()
        local result = maki.fn.jobwait(job_id, 5000)
        if not result then return end
        for line in string.gmatch(result.stdout or "", "[^\n]+") do
          local k, v = string.match(line, "^(%w+)=(%d+)$")
          if k == "5h" then state.lim_5h = tonumber(v)
          elseif k == "7d" then state.lim_7d = tonumber(v)
          end
        end
        render()
      end)
    end

    function M.setup()
      buf = maki.ui.buf({ scratch = true })
      maki.ui.open_win(buf, {
        split = "below",
        height = 3,
        focus = false,
        keys = {},
      })

      maki.api.create_autocmd("ModelChanged", {
        callback = function(_ev) render() end,
      })

      maki.api.create_autocmd("TurnEnd", {
        callback = function(ev)
          state.ctx_size = (ev.data and ev.data.context_size) or 0
          state.ctx_window = (ev.data and ev.data.context_window) or 0
          state.cost = (ev.data and ev.data.cost) or 0
          render()
        end,
      })

      maki.api.create_autocmd("SessionStatusChanged", {
        callback = function(ev)
          if ev.data and ev.data.status == "idle" then
            fetch_quota()
          end
        end,
      })

      render()
      fetch_quota()
    end

    return M
  '';

  initLua = ''
    require("statusline").setup()
  '';

  pluginToml = ''
    min_maki_version = "0.5.6"

    [permissions]
    run = true
    fs_read = true
  '';
in
{
  config = lib.mkIf makiCfg.enable {
    home.file.".config/maki/init.lua".text = initLua;
    home.file.".config/maki/lua/statusline.lua".text = pluginLua;
    home.file.".config/maki/plugin.toml".text = pluginToml;
    home.file.".config/maki/lib/usage-fetch.sh" = {
      source = "${shimScript}/bin/maki-statusline-shim";
      executable = true;
    };
  };
}
