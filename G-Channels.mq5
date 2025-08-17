//+------------------------------------------------------------------+
//|                                                   G-Channels.mq5 |
//|                                  Copyright 2025, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2025, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property version   "1.10"
#property description "G-Channels - Dynamic channel system with adaptive upper and lower bounds"
#property indicator_chart_window
#property indicator_buffers 3
#property indicator_plots   3

//--- plot Upper
#property indicator_label1  "Upper Channel"
#property indicator_type1   DRAW_LINE
#property indicator_color1  clrDodgerBlue
#property indicator_style1  STYLE_SOLID
#property indicator_width1  2

//--- plot Average
#property indicator_label2  "Middle Line"
#property indicator_type2   DRAW_LINE
#property indicator_color2  clrOrange
#property indicator_style2  STYLE_DOT
#property indicator_width2  1

//--- plot Lower
#property indicator_label3  "Lower Channel"
#property indicator_type3   DRAW_LINE
#property indicator_color3  clrDodgerBlue
#property indicator_style3  STYLE_SOLID
#property indicator_width3  2

//--- input parameters
input int    InpLength = 100;                    // Channel Length (10-500)
input double InpSensitivity = 1.0;              // Channel Sensitivity (0.1-3.0)
input ENUM_APPLIED_PRICE InpPrice = PRICE_CLOSE; // Applied Price
input bool   InpShowMiddle = true;               // Show Middle Line

//--- indicator buffers
double UpperBuffer[];
double AverageBuffer[];
double LowerBuffer[];

//--- global variables for optimization
int min_rates_total;

//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
{
   //--- input validation
   if(InpLength < 10 || InpLength > 500)
   {
      Print("Error: Channel Length must be between 10 and 500. Current value: ", InpLength);
      return(INIT_PARAMETERS_INCORRECT);
   }
   
   if(InpSensitivity < 0.1 || InpSensitivity > 3.0)
   {
      Print("Error: Channel Sensitivity must be between 0.1 and 3.0. Current value: ", InpSensitivity);
      return(INIT_PARAMETERS_INCORRECT);
   }
   
   //--- indicator buffers mapping
   SetIndexBuffer(0, UpperBuffer, INDICATOR_DATA);
   SetIndexBuffer(1, AverageBuffer, INDICATOR_DATA);
   SetIndexBuffer(2, LowerBuffer, INDICATOR_DATA);
   
   //--- set precision
   IndicatorSetInteger(INDICATOR_DIGITS, _Digits);
   
   //--- sets first bar from what index will be drawn
   PlotIndexSetInteger(0, PLOT_DRAW_BEGIN, InpLength);
   PlotIndexSetInteger(1, PLOT_DRAW_BEGIN, InpLength);
   PlotIndexSetInteger(2, PLOT_DRAW_BEGIN, InpLength);
   
   //--- hide middle line if not needed
   if(!InpShowMiddle)
      PlotIndexSetInteger(1, PLOT_DRAW_TYPE, DRAW_NONE);
   
   //--- set labels
   PlotIndexSetString(0, PLOT_LABEL, "G-Upper(" + string(InpLength) + ")");
   PlotIndexSetString(1, PLOT_LABEL, "G-Middle(" + string(InpLength) + ")");
   PlotIndexSetString(2, PLOT_LABEL, "G-Lower(" + string(InpLength) + ")");
   
   //--- name for DataWindow and indicator subwindow label
   IndicatorSetString(INDICATOR_SHORTNAME, "G-Channels(" + string(InpLength) + "," + DoubleToString(InpSensitivity, 1) + ")");
   
   //--- calculate minimum bars needed
   min_rates_total = InpLength + 1;
   
   //--- initialization done
   return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//| Get applied price value                                          |
//+------------------------------------------------------------------+
double GetAppliedPrice(const int index,
                      const double &open[],
                      const double &high[],
                      const double &low[],
                      const double &close[])
{
   switch(InpPrice)
   {
      case PRICE_OPEN:     return open[index];
      case PRICE_HIGH:     return high[index];
      case PRICE_LOW:      return low[index];
      case PRICE_CLOSE:    return close[index];
      case PRICE_MEDIAN:   return (high[index] + low[index]) / 2.0;
      case PRICE_TYPICAL:  return (high[index] + low[index] + close[index]) / 3.0;
      case PRICE_WEIGHTED: return (high[index] + low[index] + close[index] + close[index]) / 4.0;
      default:             return close[index];
   }
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
   if(rates_total < min_rates_total)
      return(0);
      
   //--- set array indexing as time series (false = left to right indexing)
   ArraySetAsSeries(UpperBuffer, false);
   ArraySetAsSeries(AverageBuffer, false);
   ArraySetAsSeries(LowerBuffer, false);
   
   //--- determine starting position for calculations
   int start_pos = 0;
   if(prev_calculated == 0)
   {
      //--- first calculation - initialize first values
      start_pos = 0;
      
      //--- initialize first bar with source price
      double first_src = GetAppliedPrice(0, open, high, low, close);
      UpperBuffer[0] = first_src;
      LowerBuffer[0] = first_src;
      AverageBuffer[0] = first_src;
      
      start_pos = 1;
   }
   else
   {
      //--- recalculate last bar to handle real-time updates
      start_pos = MathMax(1, prev_calculated - 1);
   }
   
   //--- main calculation loop
   for(int i = start_pos; i < rates_total; i++)
   {
      //--- get current source price
      double src = GetAppliedPrice(i, open, high, low, close);
      
      //--- get previous channel values
      double prev_upper = UpperBuffer[i-1];
      double prev_lower = LowerBuffer[i-1];
      
      //--- calculate channel width decay factor
      double channel_width = prev_upper - prev_lower;
      double decay_factor = (channel_width * InpSensitivity) / InpLength;
      
      //--- calculate new upper channel bound
      // Upper bound expands when price is above previous upper, contracts otherwise
      double new_upper;
      if(src > prev_upper)
      {
         new_upper = src; // Price breakout - expand upper bound immediately
      }
      else
      {
         new_upper = prev_upper - decay_factor; // Contract upper bound gradually
         new_upper = MathMax(new_upper, src); // But don't go below current price
      }
      
      //--- calculate new lower channel bound  
      // Lower bound expands when price is below previous lower, contracts otherwise
      double new_lower;
      if(src < prev_lower)
      {
         new_lower = src; // Price breakout - expand lower bound immediately
      }
      else
      {
         new_lower = prev_lower + decay_factor; // Contract lower bound gradually
         new_lower = MathMin(new_lower, src); // But don't go above current price
      }
      
      //--- ensure minimum channel width to prevent convergence
      double min_width = _Point * 10; // Minimum width of 10 points
      if((new_upper - new_lower) < min_width)
      {
         double mid_point = (new_upper + new_lower) / 2.0;
         new_upper = mid_point + min_width / 2.0;
         new_lower = mid_point - min_width / 2.0;
      }
      
      //--- store calculated values in buffers
      UpperBuffer[i] = new_upper;
      LowerBuffer[i] = new_lower;
      AverageBuffer[i] = (new_upper + new_lower) / 2.0;
   }
   
   //--- return value of prev_calculated for next call
   return(rates_total);
}

//+------------------------------------------------------------------+
//| Timer function                                                   |
//+------------------------------------------------------------------+
void OnTimer()
{
   //--- Timer functionality can be added here if needed
   //--- For example: alert conditions, notifications, etc.
}

//+------------------------------------------------------------------+
//| ChartEvent function                                              |
//+------------------------------------------------------------------+
void OnChartEvent(const int id,
                  const long &lparam,
                  const double &dparam,
                  const string &sparam)
{
   //--- Handle chart events if needed
   //--- For example: mouse clicks, key presses, object modifications
}