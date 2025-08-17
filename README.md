# Range Filter Indicator for MetaTrader 5

This is a conversion of the Pine Script "Range Filter Buy and Sell 5min" indicator to MQL5 for MetaTrader 5.

## Files Description

### 1. `RangeFilter.mq5` - Basic Version
- Standalone indicator file
- All logic contained in one file
- Suitable for basic usage

### 2. `RangeFilter.mqh` - Header File
- Contains the `CRangeFilter` class
- Can be included in other MQL5 files
- Provides reusable Range Filter functionality

### 3. `RangeFilter_Improved.mq5` - Improved Version
- Uses the class-based approach from the header file
- Better organized and maintainable
- Recommended for production use

## Installation

1. Copy the desired `.mq5` file to your MetaTrader 5 `MQL5/Indicators` folder
2. If using the improved version, also copy `RangeFilter.mqh` to your `MQL5/Include` folder
3. Restart MetaTrader 5 or refresh the Navigator
4. The indicator will appear in the "Custom Indicators" section

## Parameters

- **Source**: Price source (Close, Open, High, Low, etc.)
- **Period**: Sampling period for calculations (default: 100)
- **Multiplier**: Range multiplier (default: 3.0)

## Features

- **Range Filter Line**: Dynamic support/resistance that adapts to market volatility
- **Target Bands**: Upper and lower boundaries for price targets
- **Buy/Sell Signals**: Arrow indicators for entry points
- **Direction Detection**: Tracks upward and downward momentum
- **Multiple Price Sources**: Supports various price inputs

## How It Works

1. **Smooth Range Calculation**: Uses EMA to calculate dynamic range boundaries
2. **Range Filter**: Creates a moving filter that adapts to market conditions
3. **Signal Generation**: 
   - Buy signals when price > filter + upward momentum
   - Sell signals when price < filter + downward momentum
4. **Visual Indicators**: Color-coded lines and arrows for easy interpretation

## Usage

- **Trend Following**: Use the filter line direction to identify trend
- **Entry Points**: Look for buy/sell arrows at key levels
- **Target Levels**: Use the target bands for profit targets
- **Risk Management**: The filter line can serve as dynamic support/resistance

## Optimization

The indicator is optimized for 5-minute charts but can be used on any timeframe. Adjust the Period and Multiplier parameters based on your trading instrument and timeframe.

## Notes

- This is a trend-following indicator
- Works best in trending markets
- May generate false signals in choppy/sideways markets
- Always use with proper risk management and confirmation from other indicators

## Support

For questions or issues, refer to the original Pine Script or consult MQL5 documentation.