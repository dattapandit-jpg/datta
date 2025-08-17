//+------------------------------------------------------------------+
//|                                              RangeFilter.mq5 |
//|                                  Copyright 2024, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2024, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property version   "1.00"
#property indicator_chart_window
#property indicator_buffers 8
#property indicator_plots   5

//--- plot Range Filter
#property indicator_label1  "Range Filter"
#property indicator_type1   DRAW_LINE
#property indicator_color1  clrWhite
#property indicator_style1  STYLE_SOLID
#property indicator_width1  2

//--- plot High Target
#property indicator_label2  "High Target"
#property indicator_type2   DRAW_LINE
#property indicator_color2  clrLightBlue
#property indicator_style2  STYLE_SOLID
#property indicator_width2  1

//--- plot Low Target
#property indicator_label3  "Low Target"
#property indicator_type3   DRAW_LINE
#property indicator_color3  clrBlue
#property indicator_style3  STYLE_SOLID
#property indicator_width3  1

//--- plot Buy Signal
#property indicator_label4  "Buy Signal"
#property indicator_type4   DRAW_ARROW
#property indicator_color4  clrWhite
#property indicator_width4  2

//--- plot Sell Signal
#property indicator_label5  "Sell Signal"
#property indicator_type5   DRAW_ARROW
#property indicator_color5  clrBlue
#property indicator_width5  2

//--- input parameters
input ENUM_APPLIED_PRICE InpSource = PRICE_CLOSE;     // Source
input int                InpPeriod = 100;             // Sampling Period
input double             InpMultiplier = 3.0;         // Range Multiplier

//--- indicator buffers
double         FilterBuffer[];
double         HighBandBuffer[];
double         LowBandBuffer[];
double         BuySignalBuffer[];
double         SellSignalBuffer[];
double         UpwardBuffer[];
double         DownwardBuffer[];
double         SmoothRangeBuffer[];

//--- handles
int            handle_ema1;
int            handle_ema2;

//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
{
   //--- indicator buffers mapping
   SetIndexBuffer(0, FilterBuffer, INDICATOR_DATA);
   SetIndexBuffer(1, HighBandBuffer, INDICATOR_DATA);
   SetIndexBuffer(2, LowBandBuffer, INDICATOR_DATA);
   SetIndexBuffer(3, BuySignalBuffer, INDICATOR_DATA);
   SetIndexBuffer(4, SellSignalBuffer, INDICATOR_DATA);
   SetIndexBuffer(5, UpwardBuffer, INDICATOR_CALCULATIONS);
   SetIndexBuffer(6, DownwardBuffer, INDICATOR_CALCULATIONS);
   SetIndexBuffer(7, SmoothRangeBuffer, INDICATOR_CALCULATIONS);
   
   //--- setting accuracy
   IndicatorSetInteger(INDICATOR_DIGITS, _Digits);
   
   //--- setting first bar from what index will be drawn
   PlotIndexSetInteger(0, PLOT_DRAW_BEGIN, InpPeriod);
   PlotIndexSetInteger(1, PLOT_DRAW_BEGIN, InpPeriod);
   PlotIndexSetInteger(2, PLOT_DRAW_BEGIN, InpPeriod);
   
   //--- setting arrow codes
   PlotIndexSetInteger(3, PLOT_ARROW, 233);
   PlotIndexSetInteger(4, PLOT_ARROW, 234);
   
   //--- setting arrow offset
   PlotIndexSetInteger(3, PLOT_ARROW_SHIFT, 10);
   PlotIndexSetInteger(4, PLOT_ARROW_SHIFT, -10);
   
   //--- setting line labels
   PlotIndexSetString(0, PLOT_LABEL, "Range Filter");
   PlotIndexSetString(1, PLOT_LABEL, "High Target");
   PlotIndexSetString(2, PLOT_LABEL, "Low Target");
   PlotIndexSetString(3, PLOT_LABEL, "Buy Signal");
   PlotIndexSetString(4, PLOT_LABEL, "Sell Signal");
   
   //--- create EMA handles
   handle_ema1 = iMA(_Symbol, PERIOD_CURRENT, InpPeriod, 0, MODE_EMA, PRICE_CLOSE);
   handle_ema2 = iMA(_Symbol, PERIOD_CURRENT, InpPeriod * 2 - 1, 0, MODE_EMA, PRICE_CLOSE);
   
   if(handle_ema1 == INVALID_HANDLE || handle_ema2 == INVALID_HANDLE)
   {
      Print("Error creating EMA handles");
      return(INIT_FAILED);
   }
   
   //--- name for DataWindow and indicator subwindow label
   IndicatorSetString(INDICATOR_SHORTNAME, "Range Filter");
   
   return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
//+------------------------------------------------------------------+
int OnCalculate(const int rates_total,
                const int prev_calculated,
                const datetime &time[],
                const double &open[],
                const double &high[],
                const double &low[],
                const double &close[],
                const long &tick_volume[],
                const long &volume[],
                const int &spread[])
{
   //--- check for bars count
   if(rates_total < InpPeriod)
      return(0);
      
   //--- preliminary calculations
   int start = prev_calculated == 0 ? InpPeriod : prev_calculated - 1;
   
   //--- the main loop of calculations
   for(int i = start; i < rates_total; i++)
   {
      //--- get source price
      double src = GetAppliedPrice(InpSource, open[i], high[i], low[i], close[i]);
      
      //--- calculate smooth range
      double smoothRange = CalculateSmoothRange(i, src);
      SmoothRangeBuffer[i] = smoothRange;
      
      //--- calculate range filter
      double filter = CalculateRangeFilter(i, src, smoothRange);
      FilterBuffer[i] = filter;
      
      //--- calculate target bands
      HighBandBuffer[i] = filter + smoothRange;
      LowBandBuffer[i] = filter - smoothRange;
      
      //--- calculate direction
      CalculateDirection(i, filter);
      
      //--- calculate signals
      CalculateSignals(i, src, filter);
   }
   
   //--- return value of prev_calculated for next call
   return(rates_total);
}

//+------------------------------------------------------------------+
//| Calculate smooth range using EMA                                |
//+------------------------------------------------------------------+
double CalculateSmoothRange(int index, double src)
{
   if(index == 0)
      return 0;
      
   double absDiff = MathAbs(src - GetAppliedPrice(InpSource, 
      iOpen(_Symbol, PERIOD_CURRENT, index-1),
      iHigh(_Symbol, PERIOD_CURRENT, index-1),
      iLow(_Symbol, PERIOD_CURRENT, index-1),
      iClose(_Symbol, PERIOD_CURRENT, index-1)));
      
   //--- use EMA for smoothing
   double ema1 = 0, ema2 = 0;
   double ema1Array[1], ema2Array[1];
   
   if(CopyBuffer(handle_ema1, 0, index, 1, ema1Array) > 0)
      ema1 = ema1Array[0];
      
   if(CopyBuffer(handle_ema2, 0, index, 1, ema2Array) > 0)
      ema2 = ema2Array[0];
      
   return ema2 * InpMultiplier;
}

//+------------------------------------------------------------------+
//| Calculate range filter                                          |
//+------------------------------------------------------------------+
double CalculateRangeFilter(int index, double src, double range)
{
   if(index == 0)
      return src;
      
   double prevFilter = FilterBuffer[index-1];
   
   if(src > prevFilter)
   {
      if(src - range < prevFilter)
         return prevFilter;
      else
         return src - range;
   }
   else
   {
      if(src + range > prevFilter)
         return prevFilter;
      else
         return src + range;
   }
}

//+------------------------------------------------------------------+
//| Calculate upward/downward direction                             |
//+------------------------------------------------------------------+
void CalculateDirection(int index, double filter)
{
   if(index == 0)
   {
      UpwardBuffer[index] = 0;
      DownwardBuffer[index] = 0;
      return;
   }
   
   double prevFilter = FilterBuffer[index-1];
   
   if(filter > prevFilter)
   {
      UpwardBuffer[index] = UpwardBuffer[index-1] + 1;
      DownwardBuffer[index] = 0;
   }
   else if(filter < prevFilter)
   {
      UpwardBuffer[index] = 0;
      DownwardBuffer[index] = DownwardBuffer[index-1] + 1;
   }
   else
   {
      UpwardBuffer[index] = UpwardBuffer[index-1];
      DownwardBuffer[index] = DownwardBuffer[index-1];
   }
}

//+------------------------------------------------------------------+
//| Calculate buy/sell signals                                      |
//+------------------------------------------------------------------+
void CalculateSignals(int index, double src, double filter)
{
   if(index == 0)
   {
      BuySignalBuffer[index] = EMPTY_VALUE;
      SellSignalBuffer[index] = EMPTY_VALUE;
      return;
   }
   
   double prevSrc = GetAppliedPrice(InpSource,
      iOpen(_Symbol, PERIOD_CURRENT, index-1),
      iHigh(_Symbol, PERIOD_CURRENT, index-1),
      iLow(_Symbol, PERIOD_CURRENT, index-1),
      iClose(_Symbol, PERIOD_CURRENT, index-1));
   
   bool longCond = (src > filter && src > prevSrc && UpwardBuffer[index] > 0) ||
                   (src > filter && src < prevSrc && UpwardBuffer[index] > 0);
                   
   bool shortCond = (src < filter && src < prevSrc && DownwardBuffer[index] > 0) ||
                    (src < filter && src > prevSrc && DownwardBuffer[index] > 0);
   
   //--- signal conditions
   static int condIni = 0;
   if(index > 0)
   {
      if(longCond)
         condIni = 1;
      else if(shortCond)
         condIni = -1;
      else
         condIni = condIni;
   }
   
   bool longCondition = longCond && (index > 0 ? condIni == -1 : false);
   bool shortCondition = shortCond && (index > 0 ? condIni == 1 : false);
   
   //--- set signals
   BuySignalBuffer[index] = longCondition ? low[index] - 10 * _Point : EMPTY_VALUE;
   SellSignalBuffer[index] = shortCondition ? high[index] + 10 * _Point : EMPTY_VALUE;
}

//+------------------------------------------------------------------+
//| Get applied price based on input parameter                      |
//+------------------------------------------------------------------+
double GetAppliedPrice(ENUM_APPLIED_PRICE applied_price, double open, double high, double low, double close)
{
   switch(applied_price)
   {
      case PRICE_OPEN:   return open;
      case PRICE_HIGH:   return high;
      case PRICE_LOW:    return low;
      case PRICE_CLOSE:  return close;
      case PRICE_MEDIAN: return (high + low) / 2.0;
      case PRICE_TYPICAL: return (high + low + close) / 3.0;
      case PRICE_WEIGHTED: return (high + low + close + close) / 4.0;
      default:           return close;
   }
}

//+------------------------------------------------------------------+
//| Custom indicator deinitialization function                      |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
   //--- release indicator handles
   if(handle_ema1 != INVALID_HANDLE)
      IndicatorRelease(handle_ema1);
   if(handle_ema2 != INVALID_HANDLE)
      IndicatorRelease(handle_ema2);
}