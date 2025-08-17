# G-Channels Indicator

A Python implementation of the G-Channels technical analysis indicator, originally written in Pine Script for TradingView.

## Overview

The G-Channels indicator creates dynamic upper and lower channels that adapt to price movement. It provides adaptive support and resistance levels that expand when price moves beyond current boundaries and contract slowly when price stays within boundaries.

## Algorithm

The indicator uses two key variables:

- **Upper Channel (a)**: Tracks the maximum value with decay
  - `a := max(src, nz(a[1])) - nz(a[1] - b[1])/length`
  
- **Lower Channel (b)**: Tracks the minimum value with expansion
  - `b := min(src, nz(b[1])) + nz(a[1] - b[1])/length`

- **Average**: Simple average of upper and lower channels

## Installation

```bash
pip install -r requirements.txt
```

## Usage

### Basic Usage

```python
from g_channels_analysis import GChannels
import pandas as pd

# Create indicator with default length of 100
g_channels = GChannels(length=100)

# Calculate channels for your price data
channels = g_channels.calculate(your_price_data)

# Plot the results
g_channels.plot(your_price_data, title="My Stock G-Channels")
```

### Advanced Usage

```python
# Use different lengths for different timeframes
short_term = GChannels(length=50)
long_term = GChannels(length=200)

# Calculate channels
short_channels = short_term.calculate(prices)
long_channels = long_term.calculate(prices)

# Access individual channel values
upper_channel = channels['upper']
lower_channel = channels['lower']
average_line = channels['average']
```

## Demo

Run the demonstration to see G-Channels with sample data:

```bash
python g_channels_analysis.py
```

This will show the indicator with different length parameters (50, 100, 200) applied to synthetic price data.

## Parameters

- **length** (int, default=100): Period for the channel calculation. Higher values create smoother, slower-moving channels. Lower values create more responsive channels.

## Output

The `calculate()` method returns a pandas DataFrame with three columns:

- `upper`: Upper channel values
- `lower`: Lower channel values  
- `average`: Average of upper and lower channels

## Original Pine Script

```pinescript
//@version=4
study("G-Channels",overlay=true)
length = input(100),src = input(close)
//----
a = 0.,b = 0.
a := max(src,nz(a[1])) - nz(a[1] - b[1])/length
b := min(src,nz(b[1])) + nz(a[1] - b[1])/length
avg = avg(a,b)
//----
plot(a,"Upper",color=color.blue,linewidth=2,transp=0)
plot(avg,"Average",color=color.orange,linewidth=2,transp=0)
plot(b,"Lower",color=color.blue,linewidth=2,transp=0)
```

## Use Cases

- **Support/Resistance**: The upper and lower channels act as dynamic support and resistance levels
- **Trend Following**: The average line can be used as a trend indicator
- **Breakout Detection**: Price breaking above/below channels may signal potential breakouts
- **Mean Reversion**: Price returning to the average line after touching channel boundaries