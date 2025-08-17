//+------------------------------------------------------------------+
//|                                              RangeFilter.mqh |
//|                                  Copyright 2024, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2024, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property version   "1.00"

//+------------------------------------------------------------------+
//| Range Filter Class                                               |
//+------------------------------------------------------------------+
class CRangeFilter
{
private:
   double            m_period;
   double            m_multiplier;
   ENUM_APPLIED_PRICE m_source;
   
   // Buffers
   double            m_smoothRange[];
   double            m_rangeFilter[];
   double            m_upward[];
   double            m_downward[];
   
public:
   // Constructor
   CRangeFilter(int period = 100, double multiplier = 3.0, ENUM_APPLIED_PRICE source = PRICE_CLOSE)
   {
      m_period = (double)period;
      m_multiplier = multiplier;
      m_source = source;
      
      ArrayResize(m_smoothRange, 0);
      ArrayResize(m_rangeFilter, 0);
      ArrayResize(m_upward, 0);
      ArrayResize(m_downward, 0);
   }
   
   // Destructor
   ~CRangeFilter() {}
   
   // Initialize buffers
   void Initialize(int size)
   {
      ArrayResize(m_smoothRange, size);
      ArrayResize(m_rangeFilter, size);
      ArrayResize(m_upward, size);
      ArrayResize(m_downward, size);
      
      ArrayInitialize(m_smoothRange, 0.0);
      ArrayInitialize(m_rangeFilter, 0.0);
      ArrayInitialize(m_upward, 0.0);
      ArrayInitialize(m_downward, 0.0);
   }
   
   // Calculate smooth range
   double CalculateSmoothRange(double price, double prevPrice, int index)
   {
      if(index == 0)
         return MathAbs(price - prevPrice);
      
      double absDiff = MathAbs(price - prevPrice);
      double alpha = 2.0 / (m_period + 1.0);
      
      return (absDiff * alpha) + (m_smoothRange[index-1] * (1.0 - alpha));
   }
   
   // Calculate range filter
   double CalculateRangeFilter(double price, double smoothRange, int index)
   {
      if(index == 0)
         return price;
      
      double prevFilter = m_rangeFilter[index-1];
      
      if(price > prevFilter)
      {
         if(price - smoothRange < prevFilter)
            return prevFilter;
         else
            return price - smoothRange;
      }
      else
      {
         if(price + smoothRange > prevFilter)
            return prevFilter;
         else
            return price + smoothRange;
      }
   }
   
   // Calculate direction
   void CalculateDirection(int index)
   {
      if(index == 0)
      {
         m_upward[index] = 0.0;
         m_downward[index] = 0.0;
         return;
      }
      
      if(m_rangeFilter[index] > m_rangeFilter[index-1])
      {
         m_upward[index] = m_upward[index-1] + 1.0;
         m_downward[index] = 0.0;
      }
      else if(m_rangeFilter[index] < m_rangeFilter[index-1])
      {
         m_upward[index] = 0.0;
         m_downward[index] = m_downward[index-1] + 1.0;
      }
      else
      {
         m_upward[index] = m_upward[index-1];
         m_downward[index] = m_downward[index-1];
      }
   }
   
   // Get values
   double GetSmoothRange(int index) { return m_smoothRange[index]; }
   double GetRangeFilter(int index) { return m_rangeFilter[index]; }
   double GetUpward(int index) { return m_upward[index]; }
   double GetDownward(int index) { return m_downward[index]; }
   
   // Set values
   void SetSmoothRange(int index, double value) { m_smoothRange[index] = value; }
   void SetRangeFilter(int index, double value) { m_rangeFilter[index] = value; }
   
   // Calculate all components for one bar
   void CalculateBar(double price, double prevPrice, int index)
   {
      // Calculate smooth range
      double smoothRange = CalculateSmoothRange(price, prevPrice, index);
      SetSmoothRange(index, smoothRange);
      
      // Calculate range filter
      double rangeFilter = CalculateRangeFilter(price, smoothRange * m_multiplier, index);
      SetRangeFilter(index, rangeFilter);
      
      // Calculate direction
      CalculateDirection(index);
   }
   
   // Check buy condition
   bool IsBuyCondition(double price, int index)
   {
      return (price > m_rangeFilter[index] && m_upward[index] > 0);
   }
   
   // Check sell condition
   bool IsSellCondition(double price, int index)
   {
      return (price < m_rangeFilter[index] && m_downward[index] > 0);
   }
   
   // Get target bands
   void GetTargetBands(int index, double &highBand, double &lowBand)
   {
      double smoothRange = m_smoothRange[index] * m_multiplier;
      highBand = m_rangeFilter[index] + smoothRange;
      lowBand = m_rangeFilter[index] - smoothRange;
   }
};

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