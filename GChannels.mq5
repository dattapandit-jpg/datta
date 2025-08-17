//+------------------------------------------------------------------+
//|                                                    GChannels.mq5 |
//|                                  Copyright 2024, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2024, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property version   "1.00"
#property indicator_chart_window
#property indicator_buffers 3
#property indicator_plots   3

//--- plot Upper
#property indicator_label1  "Upper"
#property indicator_type1   DRAW_LINE
#property indicator_color1  clrBlue
#property indicator_style1  STYLE_SOLID
#property indicator_width1  2

//--- plot Average
#property indicator_label2  "Average"
#property indicator_type2   DRAW_LINE
#property indicator_color2  clrOrange
#property indicator_style2  STYLE_SOLID
#property indicator_width2  2

//--- plot Lower
#property indicator_label3  "Lower"
#property indicator_type3   DRAW_LINE
#property indicator_color3  clrBlue
#property indicator_style3  STYLE_SOLID
#property indicator_width3  2

//--- input parameters
input int      Length = 100;        // Length parameter
input ENUM_APPLIED_PRICE AppliedPrice = PRICE_CLOSE; // Applied Price

//--- indicator buffers
double UpperBuffer[];
double AverageBuffer[];
double LowerBuffer[];

//--- global variables
double prev_a = 0.0;
double prev_b = 0.0;

//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
{
   //--- indicator buffers mapping
   SetIndexBuffer(0, UpperBuffer, INDICATOR_DATA);
   SetIndexBuffer(1, AverageBuffer, INDICATOR_DATA);
   SetIndexBuffer(2, LowerBuffer, INDICATOR_DATA);
   
   //--- set indicator properties
   IndicatorSetString(INDICATOR_SHORTNAME, "G-Channels(" + IntegerToString(Length) + ")");
   IndicatorSetInteger(INDICATOR_DIGITS, _Digits);
   
   //--- set drawing begin
   PlotIndexSetInteger(0, PLOT_DRAW_BEGIN, 1);
   PlotIndexSetInteger(1, PLOT_DRAW_BEGIN, 1);
   PlotIndexSetInteger(2, PLOT_DRAW_BEGIN, 1);
   
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
   //--- check for minimum bars
   if(rates_total < 2)
      return(0);
   
   //--- determine start position
   int start = prev_calculated;
   if(start == 0)
   {
      start = 1;
      // Initialize first values
      prev_a = 0.0;
      prev_b = 0.0;
   }
   
   //--- main calculation loop
   for(int i = start; i < rates_total; i++)
   {
      double src = GetAppliedPrice(AppliedPrice, i, open, high, low, close);
      
      // Get previous values
      double prev_a_val = (i > 0) ? UpperBuffer[i-1] : prev_a;
      double prev_b_val = (i > 0) ? LowerBuffer[i-1] : prev_b;
      
      // Handle NZ (null-zero) function equivalent
      if(prev_a_val == EMPTY_VALUE || prev_a_val == 0.0)
         prev_a_val = 0.0;
      if(prev_b_val == EMPTY_VALUE || prev_b_val == 0.0)
         prev_b_val = 0.0;
      
      // Calculate a and b values (equivalent to Pine Script logic)
      double a = MathMax(src, prev_a_val) - (prev_a_val - prev_b_val) / Length;
      double b = MathMin(src, prev_b_val) + (prev_a_val - prev_b_val) / Length;
      
      // Calculate average
      double avg = (a + b) / 2.0;
      
      // Store values in buffers
      UpperBuffer[i] = a;
      LowerBuffer[i] = b;
      AverageBuffer[i] = avg;
   }
   
   //--- return value of prev_calculated for next call
   return(rates_total);
}

//+------------------------------------------------------------------+
//| Get applied price value                                          |
//+------------------------------------------------------------------+
double GetAppliedPrice(ENUM_APPLIED_PRICE applied_price, int index,
                      const double &open[], const double &high[],
                      const double &low[], const double &close[])
{
   switch(applied_price)
   {
      case PRICE_OPEN:     return open[index];
      case PRICE_HIGH:     return high[index];
      case PRICE_LOW:      return low[index];
      case PRICE_CLOSE:    return close[index];
      case PRICE_MEDIAN:   return (high[index] + low[index]) / 2.0;
      case PRICE_TYPICAL:  return (high[index] + low[index] + close[index]) / 3.0;
      case PRICE_WEIGHTED: return (high[index] + low[index] + 2 * close[index]) / 4.0;
      default:             return close[index];
   }
}

//+------------------------------------------------------------------+