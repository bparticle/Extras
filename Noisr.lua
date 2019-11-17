local app = app
local Class = require "Base.Class"
local Unit = require "Unit"
local Fader = require "Unit.ViewControl.Fader"
local GainBias = require "Unit.ViewControl.GainBias"
local Gate = require "Unit.ViewControl.Gate"
local OutputScope = require "Unit.ViewControl.OutputScope"
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
    if channelCount == 2 then
        self:loadStereoGraph()
    else
        self:loadMonoGraph()
    end
end

function Noisr:loadMonoGraph()
    local noise1 = self:createObject("WhiteNoise", "noise1")
    local trig = self:createObject("Comparator", "trig")
    trig:setGateMode()
    local vca = self:createObject("Multiply", "vca")

    local adsr = self:createObject("ADSR", "adsr")
    local attack = self:createObject("GainBias", "attack")
    local decay = self:createObject("GainBias", "decay")
    local sustain = self:createObject("GainBias", "sustain")
    local release = self:createObject("GainBias", "release")
    local attackRange = self:createObject("MinMax", "attackRange")
    local decayRange = self:createObject("MinMax", "decayRange")
    local sustainRange = self:createObject("MinMax", "sustainRange")
    local releaseRange = self:createObject("MinMax", "releaseRange")

    
    connect(attack, "Out", adsr, "Attack")
    connect(decay, "Out", adsr, "Decay")
    connect(sustain, "Out", adsr, "Sustain")
    connect(release, "Out", adsr, "Release")
    
    connect(attack, "Out", attackRange, "In")
    connect(decay, "Out", decayRange, "In")
    connect(sustain, "Out", sustainRange, "In")
    connect(release, "Out", releaseRange, "In")
    
    -- adsr:hardSet("Decay", 0)
    -- adsr:hardSet("Sustain", 0)
    
    connect(trig, "out", adsr, "Gate")
    connect(noise1, "Out", vca, "Left")
    connect(adsr, "Out", vca, "Right")
    connect(vca, "Out", self, "Out1")

    self:createMonoBranch("attack", attack, "In", attack, "Out")
    self:createMonoBranch("decay", decay, "In", decay, "Out")
    self:createMonoBranch("sustain", sustain, "In", sustain, "Out")
    self:createMonoBranch("release", release, "In", release, "Out")
    self:createMonoBranch("trig", trig, "In", trig, "Out")
    self:createMonoBranch("attack", attack, "In", attack, "Out")
    self:createMonoBranch("decay", decay, "In", decay, "Out")

end

function Noisr:loadStereoGraph()
    self:loadMonoGraph()
    connect(self.objects.vca, "Out", self, "Out2")
end

local views = {
    expanded = {"trig", "attack", "release"},
    collapsed = {},
    trig = {"scope","trig"},
    attack = {"scope", "attack"},
    release = {"scope", "release"}
}

function Noisr:onLoadViews(objects, branches)
    local controls = {}

    controls.scope = OutputScope{monitor = self, width = 4 * ply}

    controls.attack = GainBias{
        button = "A",
        branch = branches.attack,
        description = "Attack",
        gainbias = objects.attack,
        range = objects.attackRange,
        biasMap = Encoder.getMap("ADSR"),
        biasUnits = app.unitSecs,
        initialBias = 0.050
    }
    
    controls.release = GainBias{
        button = "R",
        branch = branches.release,
        description = "Release",
        gainbias = objects.release,
        range = objects.releaseRange,
        biasMap = Encoder.getMap("ADSR"),
        biasUnits = app.unitSecs,
        initialBias = 0.100
    }

    controls.trig = Gate{
        button = 1,
        branch = branches.trig,
        description = "trig",
        comparator = objects.trig
    }

    return controls, views

end

return Noisr
