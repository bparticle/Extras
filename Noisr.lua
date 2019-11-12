local app = app
local Class = require "Base.Class"
local Unit = require "Unit"
local GainBias = require "Unit.ViewControl.GainBias"
local Gate = require "Unit.ViewControl.Gate"
local Encoder = require "Encoder"
local ply = app.SECTION_PLY

local Noisr = Class{}
Noisr:include(Unit)

function Noisr:init(args)
    args.title = "Noisr"
    args.mnemonic = "Ns"
    Unit.init(self, args)
end

function Noisr:onLoadGraph(channelCount)
    local noise1 = self:createObject("WhiteNoise", "noise1")
    local trig = self:createObject("Comparator", "trig")
    trig:setTriggerMode()
    local adsr = self:createObject("ADSR", "adsr")
    local attack = self:createObject("GainBias", "attack")
    local decay = self:createObject("GainBias", "decay")
    local attackRange = self:createObject("MinMax","attackRange")
    local decayRange = self:createObject("MinMax","decayRange")
    local vca = self:createObject("Multiply", "vca")

    connect(trig, "out", adsr, "Gate")

    connect(attack, "Out", adsr, "Attack")
    connect(decay, "Out", adsr, "Decay")
    connect(attack,"Out",attackRange,"In")
    connect(decay,"Out",decayRange,"In")
    adsr:hardSet("Sustain", 0)
    adsr:hardSet("Release", 0)

    connect(noise1, "Out", vca, "Left")
    connect(adsr, "Out", vca, "Right")
    connect(vca, "Out", self, "Out1")

    self:createMonoBranch("trig", trig, "In", trig, "Out")
    self:createMonoBranch("attack", attack, "In", attack, "Out")
    self:createMonoBranch("decay", decay, "In", decay, "Out")

end

function Noisr:onLoadViews(objects, branches)
    local controls = {}

    controls.attack = GainBias{
        button = "A",
        branch = branches.attack,
        description = "Attack",
        gainbias = objects.attack,
        range = objects.attackRange,
        biasMap = Encoder.getMap("ADSR"),
        biasUnits = app.unitSecs,
        initialBias = 0.010
    }

    controls.decay = GainBias{
        button = "D",
        branch = branches.decay,
        description = "Decay",
        gainbias = objects.decay,
        range = objects.decayRange,
        biasMap = Encoder.getMap("ADSR"),
        biasUnits = app.unitSecs,
        initialBias = 0.050
    }

    controls.trig = Gate{
        button = 1,
        branch = branches.trig,
        description = "trig",
        comparator = trig
    }

    return controls, views

end

return Noisr
