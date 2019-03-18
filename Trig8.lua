-- GLOBALS: app, connect
local Class = require "Base.Class"
local Unit = require "Unit"
local Pitch = require "Unit.ViewControl.Pitch"
local GainBias = require "Unit.ViewControl.GainBias"
local Gate = require "Unit.ViewControl.Gate"
local Fader = require "Unit.ViewControl.Fader"
local Encoder = require "Encoder"
local ply = app.SECTION_PLY

local Trig8 = Class{}
Trig8:include(Unit)

function Trig8:init(args)
  args.title = "Trig 8"
  args.mnemonic = "T8"
  args.version = 1
  Unit.init(self, args)
end

function Trig8:onLoadGraph(channelCount)
  -- input, vca, sine osc

  -- create sine osc
  local modulator = self:createObject("SineOscillator", "modulator")

  -- create multipliers
  local mult1 = self:createObject("Multiply", "mult1")
  local mult2 = self:createObject("Multiply", "mult2")

  -- create f0 gainbias & minmax
  local f0 = self:createObject("GainBias", "f0")
  local f0Range = self:createObject("MinMax", "f0Range")

  -- connect unit input to vca/multipler
  connect(self, "In1", mult1, "Left")
  if channelCount > 1 then
    connect(self, "In2", mult2, "Left")
  end

  -- connect vca/multiplier to unit output
  connect(mult1, "Out", self, "Out1")
  if channelCount > 1 then
    connect(mult2, "Out", self, "Out2")
  end

  -- connect sine osc to right Inlet of vca/multiplier
  connect(modulator, "Out", mult1, "Right")
  if channelCount > 1 then
    connect(modulator, "Out", mult2, "Right")
  end

  connect(f0, "Out", modulator, "Fundamental")
  connect(f0, "Out", f0Range, "In")

  self:createMonoBranch("f0", f0, "In", f0, "Out")
end

local views = {
  expanded = {"freq"},
  collapsed = {},
}

function Trig8:onLoadViews(objects, branches)
  local controls = {}

  controls.freq = GainBias {
    button = "f0",
    description = "Fundamental",
    branch = branches.f0,
    gainbias = objects.f0,
    range = objects.f0Range,
    biasMap = Encoder.getMap("oscFreq"),
    biasUnits = app.unitHertz,
    initialBias = 200.0,
    gainMap = Encoder.getMap("freqGain"),
    scaling = app.octaveScaling
  }
  return controls, views
end

return Trig8