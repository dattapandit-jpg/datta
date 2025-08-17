//+------------------------------------------------------------------+
//|                                        RangeFilter_Improved.mq5 |
//|                                  Copyright 2024, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2024, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property version   "1.00"
#property indicator_chart_window
#property indicator_buffers 5
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

//--- Range Filter object
CRangeFilter   *rangeFilter;

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
   
   //--- setting accuracy
   IndicatorSetInteger(INDICATOR_DIGITS, _Digits);
   
   //--- setting first bar from what index will be drawn
   IndicatorSetInteger(INDICATOR_FIRST, Period);
   
   //--- name of DataWindow and indicator subwindow label
   IndicatorSetString(INDICATOR_SHORTNAME, "Range Filter");
   
   //--- create Range Filter object
   rangeFilter = new CRangeFilter(Period, Multiplier, Source);
   
   //--- initialization done
   return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//| Custom indicator deinitialization function                      |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
   //--- delete Range Filter object
   if(rangeFilter != NULL)
      delete rangeFilter;
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
      
      //--- initialize Range Filter object
      rangeFilter.Initialize(rates_total);
   }
   else
      start = prev_calculated - 1;
   
   //--- the main loop of calculations
   for(int i = start; i < rates_total; i++)
   {
      //--- get source price
      double src = GetAppliedPrice(Source, open, high, low, close, i);
      double src_prev = GetAppliedPrice(Source, open, high, low, close, i-1);
      
      //--- calculate Range Filter components
      rangeFilter.CalculateBar(src, src_prev, i);
      
      //--- get values
      RangeFilterBuffer[i] = rangeFilter.GetRangeFilter(i);
      
      //--- get target bands
      double highBand, lowBand;
      rangeFilter.GetTargetBands(i, highBand, lowBand);
      HighTargetBuffer[i] = highBand;
      LowTargetBuffer[i] = lowBand;
      
      //--- signal generation
      BuySignalBuffer[i] = 0.0;
      SellSignalBuffer[i] = 0.0;
      
      //--- check for buy condition
      if(rangeFilter.IsBuyCondition(src, i) && i > 0)
      {
         //--- check for condition change
         bool prev_long = rangeFilter.IsBuyCondition(src_prev, i-1);
         if(!prev_long)
            BuySignalBuffer[i] = low[i] - (10 * _Point); // Buy signal below the bar
      }
      
      //--- check for sell condition
      if(rangeFilter.IsSellCondition(src, i) && i > 0)
      {
         //--- check for condition change
         bool prev_short = rangeFilter.IsSellCondition(src_prev, i-1);
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