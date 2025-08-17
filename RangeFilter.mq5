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
#property indicator_color2  C'144,191,249'
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
input ENUM_APPLIED_PRICE Source = PRICE_CLOSE;     // Source
input int                 Period = 100;            // Sampling Period
input double             Multiplier = 3.0;         // Range Multiplier

//--- indicator buffers
double         RangeFilterBuffer[];
double         HighTargetBuffer[];
double         LowTargetBuffer[];
double         BuySignalBuffer[];
double         SellSignalBuffer[];
double         UpwardBuffer[];
double         DownwardBuffer[];
double         SmoothRangeBuffer[];

//--- handles
int            ema_handle;
int            ema_abs_handle;

//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
{
   //--- indicator buffers mapping
   SetIndexBuffer(0, RangeFilterBuffer, INDICATOR_DATA);
   SetIndexBuffer(1, HighTargetBuffer, INDICATOR_DATA);
   SetIndexBuffer(2, LowTargetBuffer, INDICATOR_DATA);
   SetIndexBuffer(3, BuySignalBuffer, INDICATOR_DATA);
   SetIndexBuffer(4, SellSignalBuffer, INDICATOR_DATA);
   SetIndexBuffer(5, UpwardBuffer, INDICATOR_CALCULATIONS);
   SetIndexBuffer(6, DownwardBuffer, INDICATOR_CALCULATIONS);
   SetIndexBuffer(7, SmoothRangeBuffer, INDICATOR_CALCULATIONS);
   
   //--- setting accuracy
   IndicatorSetInteger(INDICATOR_DIGITS, _Digits);
   
   //--- setting first bar from what index will be drawn
   IndicatorSetInteger(INDICATOR_FIRST, Period);
   
   //--- name of DataWindow and indicator subwindow label
   IndicatorSetString(INDICATOR_SHORTNAME, "Range Filter");
   
   //--- initialization done
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
                const int &spread[],
                const long &volume[])
{
   //--- check for bars count
   if(rates_total < Period)
      return(0);
   
   //--- preliminary calculations
   int start;
   if(prev_calculated == 0)
   {
      start = Period;
      //--- initialize arrays
      ArrayInitialize(RangeFilterBuffer, 0.0);
      ArrayInitialize(HighTargetBuffer, 0.0);
      ArrayInitialize(LowTargetBuffer, 0.0);
      ArrayInitialize(BuySignalBuffer, 0.0);
      ArrayInitialize(SellSignalBuffer, 0.0);
      ArrayInitialize(UpwardBuffer, 0.0);
      ArrayInitialize(DownwardBuffer, 0.0);
      ArrayInitialize(SmoothRangeBuffer, 0.0);
   }
   else
      start = prev_calculated - 1;
   
   //--- the main loop of calculations
   for(int i = start; i < rates_total; i++)
   {
      //--- get source price
      double src = GetAppliedPrice(Source, open, high, low, close, i);
      double src_prev = GetAppliedPrice(Source, open, high, low, close, i-1);
      
      //--- calculate smooth range
      double abs_diff = MathAbs(src - src_prev);
      double wper = Period * 2.0 - 1.0;
      
      //--- simple EMA calculation for smooth range
      if(i == start)
         SmoothRangeBuffer[i] = abs_diff;
      else
         SmoothRangeBuffer[i] = (abs_diff * 2.0 / (Period + 1.0)) + (SmoothRangeBuffer[i-1] * (Period - 1.0) / (Period + 1.0));
      
      double smrng = SmoothRangeBuffer[i] * Multiplier;
      
      //--- range filter calculation
      if(i == start)
         RangeFilterBuffer[i] = src;
      else
      {
         double prev_filt = RangeFilterBuffer[i-1];
         if(src > prev_filt)
         {
            if(src - smrng < prev_filt)
               RangeFilterBuffer[i] = prev_filt;
            else
               RangeFilterBuffer[i] = src - smrng;
         }
         else
         {
            if(src + smrng > prev_filt)
               RangeFilterBuffer[i] = prev_filt;
            else
               RangeFilterBuffer[i] = src + smrng;
         }
      }
      
      //--- filter direction
      if(i == start)
      {
         UpwardBuffer[i] = 0.0;
         DownwardBuffer[i] = 0.0;
      }
      else
      {
         if(RangeFilterBuffer[i] > RangeFilterBuffer[i-1])
            UpwardBuffer[i] = UpwardBuffer[i-1] + 1.0;
         else if(RangeFilterBuffer[i] < RangeFilterBuffer[i-1])
         {
            UpwardBuffer[i] = 0.0;
            DownwardBuffer[i] = DownwardBuffer[i-1] + 1.0;
         }
         else
         {
            UpwardBuffer[i] = UpwardBuffer[i-1];
            DownwardBuffer[i] = DownwardBuffer[i-1];
         }
         
         if(RangeFilterBuffer[i] < RangeFilterBuffer[i-1])
            DownwardBuffer[i] = DownwardBuffer[i-1] + 1.0;
         else if(RangeFilterBuffer[i] > RangeFilterBuffer[i-1])
         {
            DownwardBuffer[i] = 0.0;
            UpwardBuffer[i] = UpwardBuffer[i-1] + 1.0;
         }
      }
      
      //--- target bands
      HighTargetBuffer[i] = RangeFilterBuffer[i] + smrng;
      LowTargetBuffer[i] = RangeFilterBuffer[i] - smrng;
      
      //--- signal conditions
      bool longCond = false;
      bool shortCond = false;
      
      if(src > RangeFilterBuffer[i] && UpwardBuffer[i] > 0)
         longCond = true;
      
      if(src < RangeFilterBuffer[i] && DownwardBuffer[i] > 0)
         shortCond = true;
      
      //--- signal generation
      BuySignalBuffer[i] = 0.0;
      SellSignalBuffer[i] = 0.0;
      
      if(longCond && i > 0)
      {
         //--- check for condition change
         bool prev_long = (src > RangeFilterBuffer[i-1] && UpwardBuffer[i-1] > 0);
         if(!prev_long)
            BuySignalBuffer[i] = low[i] - (10 * _Point); // Buy signal below the bar
      }
      
      if(shortCond && i > 0)
      {
         //--- check for condition change
         bool prev_short = (src < RangeFilterBuffer[i-1] && DownwardBuffer[i-1] > 0);
         if(!prev_short)
            SellSignalBuffer[i] = high[i] + (10 * _Point); // Sell signal above the bar
      }
   }
   
   //--- return value of prev_calculated for next call
   return(rates_total);
}

//+------------------------------------------------------------------+
//| Get applied price                                                |
//+------------------------------------------------------------------+
double GetAppliedPrice(ENUM_APPLIED_PRICE applied_price, const double &open[], const double &high[], const double &low[], const double &close[], int index)
{
   switch(applied_price)
   {
      case PRICE_OPEN:   return open[index];
      case PRICE_HIGH:   return high[index];
      case PRICE_LOW:    return low[index];
      case PRICE_CLOSE:  return close[index];
      case PRICE_MEDIAN: return (high[index] + low[index]) / 2.0;
      case PRICE_TYPICAL: return (high[index] + low[index] + close[index]) / 3.0;
      case PRICE_WEIGHTED: return (high[index] + low[index] + close[index] + close[index]) / 4.0;
      default: return close[index];
   }
}