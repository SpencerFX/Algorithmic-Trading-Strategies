----------------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------------
--**LIST OF VARIABLES**
-- 1 -  BID Price, ASK Price

-- 2 - EMA MOVING AVERAGE
--------- In particular 20 period moving average

-- 3 - "m0m0 Signal" {MMS)
--------- Calculation = Absolute Value(period2 - period1)*1000
---------^^note -  Ideally should be above .3

-- 4 "greenlight Signal" {GLS}
--------- Calculation = (MMSper 1 + MMSper-1 + MMSper-2 + MMSper-3 + MMSper-4) / 4
---------^^note - Ideally should be above .30

-- 5 "lens Filter" {LF}
--------- Calculation = GLSper1 - GLSper4
---------^^note - If this figure is negative, trade will not open

--------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------
--** CONDITIONS**
-- 1 - BUY
	--1 - MoMo Signal must be = .40 or greater
	--2 - Ask Close must be > EMA.Close.20
	--3 - Greenlight Signal must be > .20
	--4 - Lens Filter must be a positive integer
	
-- 2 - SELL 
	--1 - MoMo Signal must be .40 or greater
	--2 - Bid Close must be < EMA.Close.20
	--3 - Greenlight Signal must be > .20
	--4 - Lens Filter must be a positive integer
	
-- 3 - EXIT POSITION
	--1 - Trader species a number of hours for the trade to be open for. 
	--2 - In essence they will choose number of hours to keep the trade open in total
	--3 - They have to close a portion of the trades every hour or every two hours, or every 3hrs, etc
	   
	   --  ALTERNATIVE -- There is no section for this currently
	--1 - If RSI drops following next our close position
	
	
	--NOTE
	-- 1 - What is the risk parameter to stop excessive trades from being placed ???
	-- 2 - Will this parameter work to close losing trades or to prevent additional losing trades to be closed

--------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------
-- ***REQUIRED FUNCTION***
-- The Init function is the first thing thats ran as soon as a strategy is selected...
-- This allows you to select the parameters for your strategy...
-- i.e. lotsize, stop/limit levels, indicator settings, anything you want to change

function Init ()
	strategy:name("m0m0 strat"); -- Name of the strategy
	strategy:description("This strat is initialized when a key Momentum guage is reached. Momentum is calculated by looking at force of moving averages change") -- A description of the strategy
	
	-- Time Frame paramters
	strategy.parameters:addString("TF", "Time Frame", "Time frame ('m1', 'm5', etc the strategy is optimized on H1 due to previous mathmatical calculations");
		strategy.paramters:setFlag("TG", core.FLAG_BARPERIODS); -- core.FLAG_BARPERIODS will create drop list of available time frames for this parameters
	
	--PRICE CONDITIONS--
	-- ***MA parameter
	strategy.parameters:addGroup("Momentum Moving Average Settings");
	strategy.parameters:addInteger("MA_Periods", "MA_Periods, "Specify the number of periods used when calculating the exponential moving average indicator value.", 5);
	-- Used to decide which moving average to cross over
	
	-- ***MMS parameter
	strategy.parameters:addGroup("M0M0 Signal Settings");
	strategy.parameters:addInteger("MMS_Value", "MMS_Value," "Specify the threshold value for which to look to start a trade." .01);
	-- Used as a threshold value for which trades to be started on
	
	--*** GLS parameter
	strategy.parameters:addGroup("Green Light Settings");
	strategy.paramers:addInteger("GLS_Value", "GLS_Value," "Specify the necessary value needed for the strategy to continue checking other parameters.", .01);
	-- Used to confirm and guage the strength of the momentum
	
	-- ***LF parameter
	strategy.parameters:addGroup("Lens Filter Settings");
	strategy.parameter:addInteger(LF_Value", "LF_Value, "Specify what value will shut off the trade from being opened",);
	-- If this figure = -.01, then no trade will be placed for this period
	
	-- ***Money Management Parameters
	strategy.parameters:addGroup("Money Management");
	strategy.parameters:addInteger("LotSize", "LotSize" "Set the trade size; an input of 1 refers to the minimum contract size available on the account", 1);
	strategy.parameters:addDouble("StopLoss", "StopLoss", "Set the distance, in pips, from entry price to place a stoploss on trades", 0.0);
	strategy.parameters:addDouble("Limit", "Limit", "Set the distance, in pips, from entry price to place a limit on trades");
	
	strategy.parameters:addGroup("Time")
	strategy.parameters:addInteger("Duration", "Duration" "Choose the duration for which the trades would be open for");
	strategy.parameters:addInteger("CloseT1", "CloseT1", "Set the trade size to be closed during the 1st stage", "20");
	strategy.parameters:addDouble("CloseT1", "CloseT", "Set the time to close the 1st trade in X-hours", "1");
	strategy.parameters:addInteger("CloseT2", "CloseT2", "Set the trade size to be closed during the 2nd stage", "20");
	strategy.parameters:addDouble("CloseT2", "CloseT2", "Set the time to close the 2nd trade in X-hours", "1");
	strategy.parameters:addInteger("CloseT3", "CloseT3", "Set the trade size to be closed during the 3rd stage", "20");
	strategy.parameters:addDouble("CloseT3", "CloseT3", "Set the time to close the 3rd trade in X-hours", "1");
	strategy.parameters:addInteger("CloseT4", "CloseT4", "Set the trade size to be closed during the 4th stage", "20");
	strategy.parameters:addDouble("CloseT4", "CloseT4", "Set the time to close the 4th trade in X-hours", "1");
	strategy.parameters:addInteger("CloseT5", "CloseT5", "Set the trade size to be closed during the 5th stage", "20");
	strategy.parameters:addDouble("CloseT5", "CloseT5", "Set the time to close the 5th trade in X-hours", "1");
	
	--***Magic Number and Account parameters
	strategy.parameters:addGroup("Misc");
	strategy.parameters:addString("MagicNumber", "MagicNumber", "This will allow the strategy to more easily see what tredes are being placed on the account");
	strategy.parameters:addString("Account," "Account to trade on," "", "", "");
		strategy.paramters:setFlag("Account", core.FLAG_ACCOUNT); -- core.FLAG_ACCOUNT will create a convenient drop down list of all avaiable accounts
	
end
-------------------------------------------------------------------------------------------------------------------------
-- *** REQUIRED AREA***
-- list of global variables to be referenced in any function

local MA_Periods;
local EMA;
local GLS = nil;
local MMS = nil;
local LF = nil;
local Duration
local LotSize;
local StopLoss;
local Limit;
local MagicNumber;
local Account;

local Source = nil; -- will be the source stream

local Counter = 0; -- used as counter for closing candles/closing trade

local BaseSize, Offer, CanClose; -- will store account information

local iEMA; -- will indicator data streams

local first; -- will be the index of the olderst period we can use
------------------------------------------------------------------------------------------------------------------------
-- ** CREATE OUTPUT STREAMS**--
function Update(period, mode)
EMA1:update(mode)
EMA2:update(mode)
EMA3:update(mode)
EMA4:update(mode)

function Update(period, mode)
MMS:update(mode)

function Update(period, mode)
GLS:update(mode)

function Update(period, mode)
LF:update(period, mode)

------------------------------------------------------------------------------------------------------------------------
-- ** REQUIRED AREA**
-- List of time based global variables

local len;
local out;
local L;
local T;
local tid;

function Prepare(onlyName)
	source = instance.source;
	assert(source:isAlive(), resources:get("assert_liveprice"));
	assert(source:barSize() ~="t1", resources:get("assert_bar"));
	local name = profil:id() . . "(" . . source:name() . . ")"
	
	instance:name(name);
	
	if onlyName then
		return;
	end
	
	T=tonumber(instance.parameters.T);
	L = instance.parameters.L;
	
	local s, e;
	
	-- calculate length of the bar in seconds
	s, e = core.getcandle(source:barSize(), 0, 0, 0);
	len=math.floor((e-s)*86400+0.5);
	out=instance:
	tid=core.host:excute("setTimer", 1, 1);
end

function Update(period, mode)
	return;
end

function AsyncOperationFinished(cookie, success, message)
	if cookie == 1 and source:size() > 1 then
		local period = source:size()-1;
		
		-- calculate offset b/w the current and the server time
		
		-- get current date/time
		local now = core.host:execute("getServerTime", 1);
		--core.host:trace(core.formatDate(now));
		
		--calculate how much seconds past from the beginning of the candle
		local past;
		past=math.floor((now-source:date(period))*86400+0.5);
		local percents;
		percents=math.floor(past/len*100);
		
		--calculate how much seconds remains:
		past=len-past;
		if past > 0 then
			local h, m, s, t, p, n;
			s=math.floor(past%60);
			m=math.floor((past/60))%60;
			h=math.floor(past/3600);
????????????????????????????????????????????????????????????????
------------------------------------------------------------------------------------------------------------------------
-- ***REQUIRED FUNCTION***
-- The Prepare function is run one time when the strategy is turned on.
-- This is where we store our parameters as variables.
-- We create our Strategy's chart "Legend"
-- We store our account's settings(FIFO/Non-FIFO, Base trade size)
-- We define what our price source(s) will be.
-- We create any indicator streams we will need to be reference.

function Prepare(nameOnly)
	-- stores the parameters we selected using simpler variable names
	EMA_Periods = instance.parameters.MA_Periods;
	
	LotSize = instance.parameters.LotSize;
	StopLoss = instance.parameters.StopLoss;
	Limit = instance.parameters.Limit;
	MagicNumber = instance.parameters.MagicNumber;
	Account = instance.parameters.Account;
	
	-- creates the "Legend" displayed in the top left corner of the chart
	local name = profile:id() . . "(" . . instance.bid:instrument() . . ", " . . tostring(instance.parameters.TF) / / ", " . . tostring(EMA_Periods) . . ", " . . tostring(MMS) . . ", " . . tostring(GLS) . . ", " . . tostring(LF) . . " . . tostring(LotSize) . . ", " . . tostring(StopLoss) . . ", " . . tostring(Limit) . . ", " . . tostring(MagicNumber) . . ")";
	instance:name(name);
	if nameOnly then
		return ;
	end
	
	-- stores the account's settings
	BaseSize = core.host:execute("getTradingProperty", "baseUnitSize", instance.bid:instrument(), Account); -- base trade size
	Offer = core.host:findTable("offers"):find("Instrument", instance.bid:instrument()).OfferID; -- the instrument the strategy is applied to in this instance
	CanClose = core.host:execute("getTradingProperty", "canCreateMarketClose", instance.bid:instrument(), Account); -- whether account is FIFO or Non-FIFO 
	
	-- creates our price source based on the TF (time frame) we selected in parameters.
	Source = ExtSubscribe(1, nil, instance.parameters.TF, true, "bar");
	
	--  creates indicator streams based on the parameters we selected 
	iEMA = core.indicators:create("EMA", Source.close, MA_Periods);
	
	-- stores the oldest index, or in other words, the first bar that the strategy can pull data from
	first = math.max(iEMA.DATA:first(), iMMS.MMS:first(), iGLS.GLS:first(), iLF());
	
end
????????????????????????????????????????????????????????????????????????????????????????
-----------------------------------------------------------------------------------------------------------------------
-- ***REQUIRED FUNCTION***
-- The ExtUdate function is run everytime our price source updates based on our time frame we selected
-- 	... (m5 = runs every 5 minute close, H1 = runs every hourly close, and so fourth)
-- We need to update our indicators' values
-- We need to make sure our indicators have data available before we reference them
-- We need to add our 'decision' logic 
-- This function is the brain of the strategy that causes the body to move

function ExtUpdate (id, source, period)
	-- Updates EMA, MMS, GLS, TF indicators
	EMA = iEMA.DATA; 
	MMS = iMMS.MMS; 
	GLS = iGLS.GLS; 
	LF = iLF.LF;
	
	MMS = ????? (Removed due to Confidentiality)
	GLS = ????? (Removed due to Confidentiality)
	LF = ????? (Removed due to Confidentiality)
	
	-- if the period is before the first bar we can work with, return (do nothing)
	if (period < first) then
		return; -- stop and do nothing this bar
	end
	
	-- check to make sure indicators have data for the latest closed
	if not EMA:hasData(period) or not MMS:hasData(period) or not GLS:hasData(period) or not LF:hasData(period)
		core.host:trace("Data on the loose. Inertia is 0");
		return;
	end
	
	-- Updates MA and MACD indicators
    iEMA:update(core.UpdateLast);
    iMMS:update(core.UpdateLast);
    iGLS:update(core.UpdateLast);
    iLF:update(core.UpdateLast);
	
-----------------------------------------------------------------------------------------------------------------------------
-- EXIT TRADES FUNCTION--
function exit(BuySell)
	if not(AllowTrade) then
			return true;
	end
	local valuemap, succes, msg;
		if tradesCount(BuySell) > 0 then
			valuemap = core.valuemap();
		-- switch the direction since the order must be in opposite direction
		if BuySell == "B" then
				BuySell = "S";
		else
				BuySell = "B";
		end
		value.map.OrderType = "CM";
		valuemap.OfferID = Offer;
		valuemap.AcctID = Account;
		valuemap.NetQtyFlag = "Y";
		valuemap.BuySell = BuySell;
		valuemap.CustomID = "FXCM CONTEST" . . " . . profile:id() . . " " . . instance.parameters.MagicNumber;
		succes, msg = terminal:execute(101, valuemap);
		if not (success) then
			terminal:alertMessage(instance.bid:instrument(), instance.bid[instance.bid:size() - 1] "Open order failed" . . msg, instance.bid:date(instance.bid() - 1));
			return false;
		end
		return true;
	end
	return false;
end
	
	---*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*---
	---                   LOGIC       ---            
	---*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*---
	
	-- only check logic if there are no open strategy trades
	if not haveTrades() then
	-- core.host
	
		-- BUY Logic
		-- English: if Momentum Signal (MMS) is greater than the specified  MMS value, 
		-- and the Greenlight Signal (GLS) is greater than the specified GLS, and the current price is above the 20-period EMA 
		-- However if the Lens Filter (LF) is negative, no trade will be placed.
		if iMMS > iMMS[period] and iGLS > iGLS[period]and LF > 0 then
			enter("B"); -- place a Buy Trade 
			
		-- SELL Logic
		-- English: if  Momentum signal (MMS) is greater than the specified MMS value, and 
		-- the Greenlight Signal (GLS) is greater than the the specified GLS, and the current price is below the 20-period EMA
		-- However if the Lens Filter (LF) is negative, no trade will be placed
		if MMS > iMMS[period] and GLS>iGLS[period] and LF > 0 then
			enter("S"); -- place a Sell Trade
		
		--EXIT Logic
		-- English: The user may decide the time period to which they would like to keep the positions open for. 
		-- Potentially speaking, the longer they hold the trades open for the greater the risk, the greater the return.
		--Observation: The longer the momentum trade is open for the greater the profits through 42 tests.
		--Logic - The user will specify how many hours the trade will
		if haveTrades("B") and Counter == 1 then
		exit("B", Close1); 
		else
		if haveTrades("S") and Counter == 1 then
		exit("S", Close1);
		end
		
		if haveTrades("B") and Counter == 2 then
		exit("B", Close2);
		else
		if haveTrades("S") and Counter == 2 then
		exit("S", Close2);
		end
		
		if haveTrades("B") and Counter == 3 then
		exit("B", Close3);
		else
		if haveTrades("S") and Counter == 3 then
		Exit("S", Close3)
		end
		
		if haveTrades("B") and Counter == 4 then
		exit("B", Close4);
		else
		if haveTrades("S") and Counter == 4 then
		exit("S", Close4)
		end
		
		if haveTrades("B") and Counter == 5 then
		exit("B", Close4);
		else
		if haveTrades("S") and Counter == 5 then
		exit("S", Close5);
		end

	end

end
---------------------------------------------------------------------------------------------------------------------
--STOPS AND LIMITS (CLOSE TRADE)
-- This is a custom function that will enter a market order stop/limit (if specified)
-- This will only run when it is called (typically from your strategy's trading logic)
-- calling enter ("B") will execute a market order to buy with a stop/limit (if specified)
-- calling enter ("S") will execute a market order to sell with a stop/limit (if specified)
function enter(BuySell)
	local valuemap, succes, msg;
		
	valuemap = core.valuemap();
		
	valuemap.OrderTyppe = "OM";
	valuemap.OfferID = Offer;
	value.map.AcctID = Account;
	valuemap.Quantity = LotSize * BaseSize;
	valuemap.BuySell = BuySell;
	valuemap.GTC = "GTC";
	valuemap.CustomID = "FXCM_Contest";
		
	-- set limit order if its greater than 
	if Limit > 0 then
		valuemap.PegTypeLimit = "0";
		if BuySell == "B" then
			valuemap.PegPriceOffsetPipsLimit = Limit;
		else
			valuemap.PegPriceOffsetPipsLimit = -Limit;
		end
	end
	
	-- set stoploss order if its greater than 0
	if StopLoss > 0 then
		valuemap.PegTypeStop = "0";
		if BuySell == "B" then
			valuemap.PegPriceOffsetPipsStop = -StopLoss;
		else
			valuemap.PegPriceOffsetPipsStop = StopLoss;
		end
	end
		
	-- sets correct stop/limit based on FIFO vs Non-FIFO accounts
	if (not CanClose) and (StopLoss > 0 or Limit > 0) then
		valuemap.EntryLimitStop = 'Y'
	end
		
	success, msg = terminal:execute(100, valuemap);
		
	if not (success) then
		terminal:alertMessage(instance.bid:instrument(), instance.bid[instance.bid:seize() - 1], "alert_OpenOrderFailed:" ". . msg, instance.bid:date(instance.bid:size() - 1));
		return false;
	end
		
	return true;
end
----------------------------------------------------------------------------------------------------------------
-- STOP OVERRIDE
-- Should losses exceed a certain amount close the trade immediately
function enter(BuySell)
	local valuemap, success, msg;
	
	valuemap = core.valuemap();
	
	valuemap.OrderType = "OM";
	valuemap.OfferID = Offer;
	valuemap.AcctID = Account;
	valuemap.Quantity = LotSize * BaseSize;
	valuemap.BuySell = BuySell;
	valuemap.GTC = "GTC";
	valuemap.CustomID = "FXCM_Contest";
	
	-- Have set stop should losses exceed certain amount, immediately have the trade closed
	if 
	
	-- Have limit should profit exceed certain amount, immediately have the trade closed
	if
	
	
----------------------------------------------------------------------------------------------------------------
-- This is a custom function that will tell us if there is a strategy trade already open or not
-- This will only run when it is called (typically called from your strategy's trading logic)
-- calling haveTrades ("B") will return 'true' if there is a strategy Buy position currently open
-- calling haveTrades("S") will return 'true' if there is a strategy Sell position currently open
-- calling haveTrades() will return 'true' if there is any strategy position currently open (buy or sell)
function haveTrades(BuySell)
	local enum, row;
	local found = false;
	enum = core.host:findTable("trades"):enumerater();
	row = enum:next();
	while (not found) and (row ~= nil) do
		if row.AccountID == Account and
		   row.OfferID == Offer and
		   (row.BS == BuySell or BuySell == nil)
		   row.QTXT == "FXCM_Contest" then
		   found = true;
		end
		row = enum:next();
	end
	
	return found;
end

---------------------------------------------------------------------------------------------------------------------
--*** REQUIRED FILE ***
-- This allows you to more easily code strategies in Marketscope the way this strategy is coded
dofile(core.app_path() . . "\\strategies\\standard\\include\\helper.lua");

function Init(_
	strategy:name(resouces:get("R_Name"));
	strategy:description(resources:get("R_Description"));
	strategy:setTag("group", Oscillators");
	strategy:setTag("NonOptimizableParameters","Email, SendEmail, SoundFile, RecurrentSound,PlaySound, ShowAlert");
	strategy:type(core.Signal);
	
	strategy.parameters:addGroup(resources:get("R_ParamGroup"));
	strategy.parameters:addInteger("RSIN", resources:get("R_RSIN"), ""14, 2, 200);
