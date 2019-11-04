local app = app
local Class = require "Base.Class"
local Unit = require "Unit"
local GainBias = require "Unit.ViewControl.GainBias"
local Gate = require "Unit.ViewControl.Gate"
local Encoder = require "Encoder"
local ply = app.SECTION_PLY

local Punchcard = Class{}
Punchcard:include(Unit)

function Punchcard:init(args)
  args.title = "Punch card"
  args.mnemonic = "8T"
  Unit.init(self,args)
end

function Punchcard:onLoadGraph(channelCount)

    local numTrigs = 8
    local localVars = {}

    local counter = self:createObject("Counter","counter")
    counter:hardSet("Gain", 1/numTrigs)
    counter:hardSet("Start",0.0)
    counter:hardSet("Finish",7.0)
    counter:hardSet("Step Size",1.0)

    local thresholds = {-0.1, 0.06, 0.2, 0.3, 0.45, 0.55, 0.7, 0.801}

    for i = 1, numTrigs do
        -- These are the actual compare units you inserted, thresholds hardcoded to the values above
        localVars["comparator" .. i] = self:createObject("Comparator","comparator" .. i)
        localVars["comparator" .. i]:hardSet("Threshold",thresholds[i])
        localVars["comparator" .. i]:hardSet("Hysteresis", 0.03)
        -- You used offsets to mix, but in the middle layer we can just use "sum" objects.
        -- Need one fewer than we have comparators
        if i < numTrigs then
            localVars["outputMixer" .. i] = self:createObject("Sum","outputMixer" .. i)
        end
        -- These are the vcas that control whether each comparator output gets through or not
        localVars["vca" .. i] = self:createObject("Multiply","vca" .. i)
        -- Connect counter output directly to each comparator but the first - the counter needs to be inverted
        -- before connecting to the first comparator
        if i > 1 then
            connect(counter,"Out",localVars["comparator"  .. i],"In")
        end
        -- Connect the comparator outputs to the vcas
        connect(localVars["comparator" .. i],"Out",localVars["vca" .. i],"Left")
        -- These 8 comparators are for the 1-8 buttons.  When you create a custom gate control in the UI layer
        -- it automatically creates this but in the middle layer you have to manage it.  Set the modes
        -- to toggle so that they stay latched when you engage them
        localVars["sw" .. i] = self:createObject("Comparator","sw" ..i)
        localVars["sw" .. i]:setToggleMode()
        -- Connect the button comparators to the other side of the VCAs that control whether each trigger output is
        -- allowed through
        connect(localVars["sw" .. i],"Out",localVars["vca" .. i],"Right")
        -- This creates the branches for each of the 1-8 gates that we'll use in the onLoadViews section below
        self:createMonoBranch("t" .. i,localVars["sw" .. i],"In",localVars["sw" .. i],"Out")
    end

    -- The next six lines create an inverting VCA and connect the counter through it and into the first 
    -- comparator
    local negOne = self:createObject("Constant","negOne")
    negOne:hardSet("Value",-1.0)
    local invert = self:createObject("Multiply","invert")
    connect(counter,"Out",invert,"Left")
    connect(negOne,"Out",invert,"Right")
    connect(invert,"Out",localVars["comparator1"],"In")

    -- More comparators for the clock input and reset 
    local clockIn = self:createObject("Comparator","clockIn")
    local reset = self:createObject("Comparator","reset")

    connect(clockIn,"Out",counter,"In")
    connect(reset,"Out",counter,"Reset")

    -- Connect the VCA outputs up to mixers, and then mix the mixers so we end up with only one output that
    -- mixes it all together
    connect(localVars["vca1"],"Out",localVars["outputMixer1"],"Left")
    connect(localVars["vca2"],"Out",localVars["outputMixer1"],"Right")
    connect(localVars["vca3"],"Out",localVars["outputMixer2"],"Left")
    connect(localVars["vca4"],"Out",localVars["outputMixer2"],"Right")
    connect(localVars["vca5"],"Out",localVars["outputMixer3"],"Left")
    connect(localVars["vca6"],"Out",localVars["outputMixer3"],"Right")
    connect(localVars["vca7"],"Out",localVars["outputMixer4"],"Left")
    connect(localVars["vca8"],"Out",localVars["outputMixer4"],"Right")
    connect(localVars["outputMixer1"],"Out",localVars["outputMixer5"],"Left")
    connect(localVars["outputMixer2"],"Out",localVars["outputMixer5"],"Right")
    connect(localVars["outputMixer3"],"Out",localVars["outputMixer6"],"Left")
    connect(localVars["outputMixer4"],"Out",localVars["outputMixer6"],"Right")
    connect(localVars["outputMixer5"],"Out",localVars["outputMixer7"],"Left")
    connect(localVars["outputMixer6"],"Out",localVars["outputMixer7"],"Right")
    connect(localVars["outputMixer7"],"Out",self,"Out1")
    -- connect(counter,"Out",self,"Out1")

    self:createMonoBranch("clock",clockIn,"In",clockIn,"Out")
    self:createMonoBranch("reset",reset,"In",reset,"Out")

end

local views = {
    expanded = {"clock","reset","sw1","sw2","sw3","sw4","sw5","sw6","sw7","sw8"},
    collapsed = {},
  }

function Punchcard:onLoadViews(objects,branches)
    local numTrigs = 8
    local controls = {}

    controls.clock = Gate {
        button = "clock",
        description = "Clock In",
        branch = branches.clock,
        comparator = objects.clockIn,
        }

        controls.reset = Gate {
        button = "reset",
        description = "Reset",
        branch = branches.reset,
        comparator = objects.reset,
        }
  
    for i = 1, numTrigs do
        controls["sw" .. i] = Gate {
        button = i,
        branch = branches["t" .. i],
        description = "on/off",
        comparator = objects["sw" .. i],
        }
    end

    return controls, views
end

return Punchcard