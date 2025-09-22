//+------------------------------------------------------------------+
//|                                            SMC_Unified_EA_v2.mq5 |
//| Smart Money Concepts: Order Blocks + FVG + BOS with Filters      |
//+------------------------------------------------------------------+
#property copyright "Vignesh Kumaravel, SkyBlueFS 2025"
#property version   "2.01"
#property strict

#include <Trade/Trade.mqh>
#include <Trade/PositionInfo.mqh>

CTrade         trade;
CPositionInfo  pos;

//=========================== ENUMS ===========================//
enum ENUM_STRATEGY { STRAT_OB=0, STRAT_FVG=1, STRAT_BOS=2, STRAT_AUTO=3 };
enum ENUM_REGIME   { REGIME_ADX=0, REGIME_EFFICIENCY=1 };

//========================== INPUTS ===========================//
// Core Strategy
input ENUM_STRATEGY Strategy           = STRAT_AUTO;
input long          MagicNumber        = 76543;
input long          HedgeMagic         = 76544;      // for future hedging
input bool          OneTradePerBar     = true;

// Risk & Money Management  
input double        LotPerK            = 0.02;       // lots per $1000 balance
input double        BagProfitPercent   = 8.0;        // close all at +x% equity
input double        BagLossPercent     = 4.0;        // close all at -y% equity

// Market Context Filters
input bool          UseSessionFilter   = true;       // skip Asian session
input bool          UseATRFilters      = true;       // displacement + gap sizing
input bool          UseRegimeFilter    = true;       // trend filter for BOS
input ENUM_REGIME   RegimeMethod       = REGIME_ADX; // ADX or Efficiency Ratio

// Core Parameters (others auto-calculated)
input int           ATR_Period         = 14;
input int           SwingBars          = 5;          // swing confirmation period
input double        FibRetraceLevel    = 61.8;       // OB entry level

// Advanced (auto-adapted if 0)
input double        DisplacementMin    = 0.0;        // auto = adaptive
input int           MaxSpreadPoints    = 120;

//========================= CONSTANTS ==========================//
// Sessions (UTC hours)
const int ASIA_START = 1, ASIA_END = 7;
const int LONDON_START = 7, LONDON_END = 16;  
const int NY_START = 12, NY_END = 21;

// Colors
const color BULL_OB = clrLimeGreen;
const color BEAR_OB = clrCrimson;
const color BULL_FVG = clrLightBlue;
const color BEAR_FVG = clrMistyRose;
const color BOS_BULL = clrDodgerBlue;
const color BOS_BEAR = clrTomato;

//========================== GLOBALS ===========================//
double   PointValue, currentBalance, profitThreshold, lossThreshold;
int      DigitsCount;                     // <-- renamed from 'Digits'
datetime lastBarTime = 0, lastTradeBar = 0;

// runtime feature flags (mirror inputs; safe to change at runtime)
bool     gUseATRFilters = true;
bool     gUseRegimeFilter = true;

// Indicators
int      atr_handle = INVALID_HANDLE;
int      adx_handle = INVALID_HANDLE;

// Order Block State
datetime lastOBTime = 0;
double   obHigh = 0, obLow = 0;
int      obDirection = 0;

// Arrays for bagging system
ulong    pairs[];
ulong    hedges[];

//======================= INITIALIZATION =======================//
int OnInit()
{
   PointValue = SymbolInfoDouble(_Symbol, SYMBOL_POINT);
   DigitsCount = (int)SymbolInfoInteger(_Symbol, SYMBOL_DIGITS);
   lastBarTime = iTime(_Symbol, _Period, 0);

   // mirror inputs into runtime flags
   gUseATRFilters   = UseATRFilters;
   gUseRegimeFilter = UseRegimeFilter;
   
   // Initialize indicators
   atr_handle = iATR(_Symbol, _Period, ATR_Period);
   if(gUseATRFilters && atr_handle == INVALID_HANDLE) {
      Print("ATR initialization failed - disabling ATR filters");
      gUseATRFilters = false;                 // <-- never modify 'input'
   }
   
   if(gUseRegimeFilter && RegimeMethod == REGIME_ADX) {
      adx_handle = iADX(_Symbol, _Period, 14);
      if(adx_handle == INVALID_HANDLE) {
         Print("ADX initialization failed - disabling regime filter");
         gUseRegimeFilter = false;           // <-- never modify 'input'
      }
   }
   
   // Initialize bagging thresholds
   ChangeBaggingThresholds();
   
   return INIT_SUCCEEDED;
}

void OnDeinit(const int reason)
{
   if(atr_handle != INVALID_HANDLE) IndicatorRelease(atr_handle);
   if(adx_handle != INVALID_HANDLE) IndicatorRelease(adx_handle);
}

//====================== UTILITY FUNCTIONS ======================//
bool IsNewBar()
{
   datetime current = iTime(_Symbol, _Period, 0);
   if(current != lastBarTime) {
      lastBarTime = current;
      return true;
   }
   return false;
}

double GetATR(int shift = 1)
{
   if(atr_handle == INVALID_HANDLE) return 0;
   double buffer[1];
   return (CopyBuffer(atr_handle, 0, shift, 1, buffer) == 1) ? buffer[0] : 0;
}

double CalculateAdaptiveThreshold(string type)
{
   if(!gUseATRFilters) return (type == "displacement") ? 1.5 : 0.15;
   
   double atr = GetATR(1);
   if(atr <= 0) return (type == "displacement") ? 1.5 : 0.15;
   
   // Adapt thresholds based on recent volatility
   double bid=SymbolInfoDouble(_Symbol, SYMBOL_BID);
   if(bid<=0) bid=1.0;
   double volatility = atr / bid;
   
   if(type == "displacement") {
      return MathMax(1.2, 1.8 - volatility * 100); // Lower threshold in high vol
   }
   else if(type == "fvg_gap") {
      return MathMax(0.10, 0.20 - volatility * 50); // Smaller gaps OK in high vol
   }
   
   return 1.5; // default
}

//====================== SESSION FILTER ======================//
bool IsValidSession()
{
   if(!UseSessionFilter) return true;
   
   MqlDateTime dt;
   TimeToStruct(TimeGMT(), dt);
   int hour = dt.hour;
   
   // Block Asian session
   if(hour >= ASIA_START && hour < ASIA_END) return false;
   
   // Allow London and NY sessions
   return ((hour >= LONDON_START && hour < LONDON_END) || 
           (hour >= NY_START && hour < NY_END));
}

//===================== DISPLACEMENT LOGIC ====================//
bool HasDisplacement(int bar)
{
   if(!gUseATRFilters) return true;
   
   double atr = GetATR(bar);
   if(atr <= 0) return true;
   
   double high = iHigh(_Symbol, _Period, bar);
   double low  = iLow (_Symbol, _Period, bar);
   double open = iOpen(_Symbol, _Period, bar);
   double close= iClose(_Symbol, _Period, bar);
   
   double range = high - low;
   double body  = MathAbs(close - open);
   
   double displacementThreshold = (DisplacementMin > 0.0) ? DisplacementMin
                                                          : CalculateAdaptiveThreshold("displacement");
   
   // 2-of-3 score: (range vs ATR), (body strength), (mild continuation)
   int score = 0;
   if(range >= displacementThreshold * atr) score++;
   if(range>0 && (body >= 0.6 * range))     score++;
   if(bar > 0 && MathAbs(iClose(_Symbol, _Period, bar-1) - iOpen(_Symbol, _Period, bar-1)) >= 0.4 * atr) score++;
   
   return score >= 2;
}

//==================== REGIME DETECTION ====================//
double CalculateEfficiencyRatio(int periods)
{
   if(Bars(_Symbol, _Period) < periods + 2) return 0.0;
   
   double start = iClose(_Symbol, _Period, periods);
   double end   = iClose(_Symbol, _Period, 1);
   double netMove = MathAbs(end - start);
   
   double totalMove = 0;
   for(int i = periods; i > 1; i--) {
      totalMove += MathAbs(iClose(_Symbol, _Period, i-1) - iClose(_Symbol, _Period, i));
   }
   
   return (totalMove > 0) ? netMove / totalMove : 0.0;
}

bool IsTrendingMarket()
{
   if(!gUseRegimeFilter) return true;
   
   if(RegimeMethod == REGIME_ADX) {
      if(adx_handle == INVALID_HANDLE) return true;
      double buffer[1];
      if(CopyBuffer(adx_handle, 0, 1, 1, buffer) != 1) return true;
      return buffer[0] >= 18.0;
   } else {
      return CalculateEfficiencyRatio(30) >= 0.30;
   }
}

//===================== SWING DETECTION =====================//
void FindSwingLevels(double &swingHigh, datetime &highTime, double &swingLow, datetime &lowTime)
{
   swingHigh = 0; highTime = 0; swingLow = 0; lowTime = 0;
   int lookback = MathMin(20, Bars(_Symbol, _Period) - SwingBars * 2);
   if(lookback < SwingBars+1) return;
   
   for(int i = SwingBars; i <= lookback; i++) {
      bool isSwingHigh = true, isSwingLow = true;
      double h = iHigh(_Symbol, _Period, i);
      double l = iLow (_Symbol, _Period, i);
      
      for(int j = 1; j <= SwingBars; j++) {
         if(h <= iHigh(_Symbol, _Period, i-j) || h <= iHigh(_Symbol, _Period, i+j)) isSwingHigh = false;
         if(l >= iLow (_Symbol, _Period, i-j) || l >= iLow (_Symbol, _Period, i+j)) isSwingLow  = false;
         if(!isSwingHigh && !isSwingLow) break;
      }
      
      if(isSwingHigh && (highTime == 0 || iTime(_Symbol, _Period, i) > highTime)) {
         swingHigh = h;
         highTime  = iTime(_Symbol, _Period, i);
      }
      if(isSwingLow && (lowTime == 0 || iTime(_Symbol, _Period, i) > lowTime)) {
         swingLow = l;  
         lowTime  = iTime(_Symbol, _Period, i);
      }
   }
}

//==================== POSITION MANAGEMENT ===================//
double CalculateLotSize()
{
   double balance = AccountInfoDouble(ACCOUNT_BALANCE);
   double lots = LotPerK * (balance / 1000.0);
   
   double minLot = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
   double maxLot = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MAX);
   double lotStep= SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);
   
   lots = MathFloor(lots / lotStep) * lotStep;
   if(lots < minLot) lots = minLot;
   if(lots > maxLot) lots = maxLot;
   return lots;
}

void CalculateStopLoss(ENUM_ORDER_TYPE orderType, double entry, double &sl, double &tp)
{
   double atr = GetATR(0);
   double slDistance, tpDistance;
   
   if(gUseATRFilters && atr > 0) {
      slDistance = 1.5 * atr;
      tpDistance = 2.5 * atr;
   } else {
      slDistance = 3500 * PointValue;
      tpDistance = 7500 * PointValue;
   }
   
   if(orderType == ORDER_TYPE_BUY) { sl = entry - slDistance; tp = entry + tpDistance; }
   else                            { sl = entry + slDistance; tp = entry - tpDistance; }
   
   sl = NormalizeDouble(sl, DigitsCount);
   tp = NormalizeDouble(tp, DigitsCount);
   
   int stopLevel = (int)SymbolInfoInteger(_Symbol, SYMBOL_TRADE_STOPS_LEVEL);
   double minDist = stopLevel * PointValue;
   
   if(orderType == ORDER_TYPE_BUY) {
      if((entry - sl) < minDist) sl = NormalizeDouble(entry - minDist, DigitsCount);
      if((tp - entry) < minDist) tp = NormalizeDouble(entry + minDist, DigitsCount);
   } else {
      if((sl - entry) < minDist) sl = NormalizeDouble(entry + minDist, DigitsCount);
      if((entry - tp) < minDist) tp = NormalizeDouble(entry - minDist, DigitsCount);
   }
}

bool ExecuteTrade(ENUM_ORDER_TYPE orderType, string comment)
{
   if(!IsValidSession()) return false;
   if(OneTradePerBar && lastTradeBar == lastBarTime) return false;
   if(SymbolInfoInteger(_Symbol, SYMBOL_SPREAD) > MaxSpreadPoints) return false;
   
   // Check for existing positions
   for(int i = PositionsTotal()-1; i >= 0; --i) {
      ulong ticket = PositionGetTicket(i);
      if(!ticket) continue;
      if(!PositionSelectByTicket(ticket)) continue;
      if(PositionGetString(POSITION_SYMBOL) != _Symbol) continue;
      if((long)PositionGetInteger(POSITION_MAGIC) != MagicNumber) continue;
      return false; // Position already exists
   }
   
   MqlTick tick;
   if(!SymbolInfoTick(_Symbol, tick)) return false;
   
   double entry = (orderType == ORDER_TYPE_BUY) ? tick.ask : tick.bid;
   double sl, tp;
   CalculateStopLoss(orderType, entry, sl, tp);
   
   double lots = CalculateLotSize();
   
   trade.SetExpertMagicNumber(MagicNumber);
   trade.SetDeviationInPoints(20);
   
   bool result = trade.PositionOpen(_Symbol, orderType, lots, entry, sl, tp, comment);
   if(result && OneTradePerBar) lastTradeBar = lastBarTime;
   return result;
}

//======================= ORDER BLOCKS =======================//
void DetectOrderBlock()
{
   obDirection = 0; obHigh = 0; obLow = 0; lastOBTime = 0;
   int total = Bars(_Symbol, _Period);
   if(total < 10) return;
   
   int scanBars = MathMin(120, total - 4);
   for(int i = 1; i < scanBars; i++) {
      double open_i   = iOpen (_Symbol, _Period, i);
      double close_i  = iClose(_Symbol, _Period, i);
      double open_p   = iOpen (_Symbol, _Period, i-1);
      double close_p  = iClose(_Symbol, _Period, i-1);
      
      bool bullishOB = (open_i > close_i) && (close_p > open_p) && HasDisplacement(i-1);
      bool bearishOB = (open_i < close_i) && (close_p < open_p) && HasDisplacement(i-1);
      
      if(bullishOB) {
         obDirection = 1;
         obHigh = iHigh(_Symbol, _Period, i);
         obLow  = iLow (_Symbol, _Period, i);
         lastOBTime = iTime(_Symbol, _Period, i);
         break;
      }
      if(bearishOB) {
         obDirection = -1;
         obHigh = iHigh(_Symbol, _Period, i);
         obLow  = iLow (_Symbol, _Period, i);
         lastOBTime = iTime(_Symbol, _Period, i);
         break;
      }
   }
}

void TradeOrderBlock()
{
   if(obDirection == 0) return;
   
   MqlTick tick; if(!SymbolInfoTick(_Symbol, tick)) return;
   bool inZone = (obDirection > 0) ? (tick.ask >= obLow && tick.ask <= obHigh)
                                   : (tick.bid >= obLow && tick.bid <= obHigh);
   if(!inZone) return;
   
   // Fib from most recent swings
   double swingHigh, swingLow; datetime highTime, lowTime;
   FindSwingLevels(swingHigh, highTime, swingLow, lowTime);
   if(swingHigh <= 0 || swingLow <= 0) return;
   
   if(obDirection > 0) {
      double entryLevel = swingHigh - (swingHigh - swingLow) * (FibRetraceLevel / 100.0);
      if(tick.ask <= entryLevel) ExecuteTrade(ORDER_TYPE_BUY, "SMC_OB_BUY");
   } else {
      double entryLevel = swingLow + (swingHigh - swingLow) * (FibRetraceLevel / 100.0);
      if(tick.bid >= entryLevel) ExecuteTrade(ORDER_TYPE_SELL, "SMC_OB_SELL");
   }
}

//===================== FAIR VALUE GAPS ====================//
void DrawFVG(string name, datetime startTime, double bottom, double top, color clr)
{
   if(ObjectFind(0, name) != -1) ObjectDelete(0, name);
   ObjectCreate(0, name, OBJ_RECTANGLE, 0, startTime, bottom, lastBarTime, top);
   ObjectSetInteger(0, name, OBJPROP_FILL, true);
   ObjectSetInteger(0, name, OBJPROP_BACK, true);
   ObjectSetInteger(0, name, OBJPROP_COLOR, clr);
}

void TradeFVGTouch()
{
   MqlTick tick; if(!SymbolInfoTick(_Symbol, tick)) return;
   int totalObjects = ObjectsTotal(0, 0, -1);
   for(int i = 0; i < totalObjects; i++) {
      string objName = ObjectName(0, i);
      bool isBullFVG = StringFind(objName, "FVG_BULL_") == 0;
      bool isBearFVG = StringFind(objName, "FVG_BEAR_") == 0;
      if(!isBullFVG && !isBearFVG) continue;
      
      double top    = ObjectGetDouble(0, objName, OBJPROP_PRICE, 1);
      double bottom = ObjectGetDouble(0, objName, OBJPROP_PRICE, 0);
      
      if(isBullFVG && tick.ask >= bottom && tick.ask <= top) {
         if(ExecuteTrade(ORDER_TYPE_BUY, "SMC_FVG_BUY")) break;
      }
      if(isBearFVG && tick.bid >= bottom && tick.bid <= top) {
         if(ExecuteTrade(ORDER_TYPE_SELL, "SMC_FVG_SELL")) break;
      }
   }
}

void DetectAndTradeFVG()
{
   int total = Bars(_Symbol, _Period);
   if(total < 5) return;

   int scanBars = MathMin(50, total - 3);
   double minGapThreshold = CalculateAdaptiveThreshold("fvg_gap");
   double atr = GetATR(1);
   
   for(int i = 0; i < scanBars; i++) {
      if(i + 2 >= total) break;
      
      double high_A = iHigh(_Symbol, _Period, i + 2);
      double low_A  = iLow (_Symbol, _Period, i + 2);
      double high_C = iHigh(_Symbol, _Period, i);
      double low_C  = iLow (_Symbol, _Period, i);
      
      // Bullish FVG: Low[A] > High[C]
      if(low_A > high_C) {
         double gapSize = (low_A - high_C) / PointValue;
         double minGap  = (gUseATRFilters && atr > 0) ? (minGapThreshold * atr / PointValue) : 3.0;
         if(gapSize >= minGap) {
            string objName = "FVG_BULL_" + TimeToString(iTime(_Symbol, _Period, i+2), TIME_DATE|TIME_MINUTES);
            DrawFVG(objName, iTime(_Symbol, _Period, i+2), high_C, low_A, BULL_FVG);
         }
      }
      // Bearish FVG: High[A] < Low[C]  
      if(high_A < low_C) {
         double gapSize = (low_C - high_A) / PointValue;
         double minGap  = (gUseATRFilters && atr > 0) ? (minGapThreshold * atr / PointValue) : 3.0;
         if(gapSize >= minGap) {
            string objName = "FVG_BEAR_" + TimeToString(iTime(_Symbol, _Period, i+2), TIME_DATE|TIME_MINUTES);
            DrawFVG(objName, iTime(_Symbol, _Period, i+2), high_A, low_C, BEAR_FVG);
         }
      }
   }
   // touch-to-trade
   TradeFVGTouch();
}

//================== BREAK OF STRUCTURE ===================//
void DrawBOS(string name, datetime startTime, double level, datetime endTime, double endLevel, color clr)
{
   if(ObjectFind(0, name) != -1) return;
   ObjectCreate(0, name, OBJ_TREND, 0, startTime, level, endTime, endLevel);
   ObjectSetInteger(0, name, OBJPROP_COLOR, clr);
   ObjectSetInteger(0, name, OBJPROP_WIDTH, 2);
   string labelName = name + "_LBL";
   ObjectCreate(0, labelName, OBJ_TEXT, 0, endTime, endLevel);
   ObjectSetString(0, labelName, OBJPROP_TEXT, "BOS");
   ObjectSetInteger(0, labelName, OBJPROP_COLOR, clr);
}

void DetectAndTradeBOS()
{
   if(!IsTrendingMarket()) return; // Only trade BOS in trending markets
   
   double swingHigh, swingLow; datetime highTime, lowTime;
   FindSwingLevels(swingHigh, highTime, swingLow, lowTime);
   if(swingHigh <= 0 && swingLow <= 0) return;
   
   MqlTick tick; if(!SymbolInfoTick(_Symbol, tick)) return;
   
   // Bullish BOS: Break above swing high with displacement
   if(swingHigh > 0 && tick.ask > swingHigh && HasDisplacement(1)) {
      string objName = "BOS_BULL_" + TimeToString(highTime, TIME_DATE|TIME_MINUTES);
      DrawBOS(objName, highTime, swingHigh, lastBarTime, swingHigh, BOS_BULL);
      ExecuteTrade(ORDER_TYPE_BUY, "SMC_BOS_BUY");
      return;
   }
   // Bearish BOS: Break below swing low with displacement
   if(swingLow > 0 && tick.bid < swingLow && HasDisplacement(1)) {
      string objName = "BOS_BEAR_" + TimeToString(lowTime, TIME_DATE|TIME_MINUTES);
      DrawBOS(objName, lowTime, swingLow, lastBarTime, swingLow, BOS_BEAR);
      ExecuteTrade(ORDER_TYPE_SELL, "SMC_BOS_SELL");
      return;
   }
}

//==================== BAGGING SYSTEM ====================//
void ChangeBaggingThresholds()
{
   currentBalance = AccountInfoDouble(ACCOUNT_BALANCE);
   profitThreshold = currentBalance * (1.0 + BagProfitPercent/100.0);
   lossThreshold   = currentBalance * (1.0 - BagLossPercent/100.0);
   PrintFormat("Bagging Targets: Loss=%.2f, Profit=%.2f", lossThreshold, profitThreshold);
}

void CloseAllTrades()
{
   for(int i = PositionsTotal()-1; i >= 0; --i) {
      ulong ticket = PositionGetTicket(i);
      if(!ticket) continue;
      if(!PositionSelectByTicket(ticket)) continue;
      string sym = PositionGetString(POSITION_SYMBOL);
      long   mgc = (long)PositionGetInteger(POSITION_MAGIC);
      if(sym==_Symbol && (mgc==MagicNumber || mgc==HedgeMagic)) {
         trade.PositionClose(ticket);
      }
   }
   ArrayResize(pairs, 0);
   ArrayResize(hedges, 0);
}

void CheckBagging()
{
   double equity = AccountInfoDouble(ACCOUNT_EQUITY);
   if(equity >= profitThreshold || equity <= lossThreshold) {
      PrintFormat("Bagging triggered - Equity: %.2f, Targets: %.2f/%.2f", 
                  equity, lossThreshold, profitThreshold);
      CloseAllTrades();
      ChangeBaggingThresholds();
   }
}

//======================== MAIN EVENTS ========================//
void OnTick()
{
   CheckBagging(); // Always check bagging first
   if(!IsNewBar()) return;
   
   if(Strategy == STRAT_OB  || Strategy == STRAT_AUTO){ DetectOrderBlock(); TradeOrderBlock(); }
   if(Strategy == STRAT_FVG || Strategy == STRAT_AUTO){ DetectAndTradeFVG(); }
   if(Strategy == STRAT_BOS || Strategy == STRAT_AUTO){ DetectAndTradeBOS(); }
}
