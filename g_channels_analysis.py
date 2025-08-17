"""
G-Channels Indicator Analysis and Python Implementation

Original Pine Script Analysis:
==============================

The G-Channels indicator creates dynamic upper and lower channels that adapt to price movement:

1. Input Parameters:
   - length: Period for the channel calculation (default: 100)
   - src: Source data (default: close price)

2. Algorithm:
   - 'a' (Upper Channel): Tracks the maximum value with decay
     - Takes the max of current price and previous 'a' value
     - Subtracts a fraction of the channel width (a-b) divided by length
   
   - 'b' (Lower Channel): Tracks the minimum value with expansion  
     - Takes the min of current price and previous 'b' value
     - Adds a fraction of the channel width (a-b) divided by length
   
   - 'avg': Simple average of upper and lower channels

3. Visual Output:
   - Blue upper and lower channel lines
   - Orange average line
   - All lines have width=2 and no transparency

The indicator creates adaptive channels that:
- Expand when price moves beyond current boundaries
- Contract slowly when price stays within boundaries
- Provide dynamic support/resistance levels
"""

import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
from typing import Union, List


class GChannels:
    """
    Python implementation of the G-Channels indicator from Pine Script
    """
    
    def __init__(self, length: int = 100):
        """
        Initialize G-Channels indicator
        
        Args:
            length: Period for channel calculation (default: 100)
        """
        self.length = length
        self.reset()
    
    def reset(self):
        """Reset indicator state"""
        self.a_prev = 0.0  # Previous upper channel value
        self.b_prev = 0.0  # Previous lower channel value
        
    def calculate(self, prices: Union[List[float], pd.Series, np.ndarray]) -> pd.DataFrame:
        """
        Calculate G-Channels for a series of prices
        
        Args:
            prices: Price data (typically close prices)
            
        Returns:
            DataFrame with columns: upper, lower, average
        """
        if isinstance(prices, (list, np.ndarray)):
            prices = pd.Series(prices)
            
        results = []
        self.reset()
        
        for price in prices:
            # Calculate upper channel (a)
            # a := max(src, nz(a[1])) - nz(a[1] - b[1]) / length
            a_current = max(price, self.a_prev) - (self.a_prev - self.b_prev) / self.length
            
            # Calculate lower channel (b) 
            # b := min(src, nz(b[1])) + nz(a[1] - b[1]) / length
            b_current = min(price, self.b_prev) + (self.a_prev - self.b_prev) / self.length
            
            # Calculate average
            avg_current = (a_current + b_current) / 2
            
            results.append({
                'upper': a_current,
                'lower': b_current, 
                'average': avg_current
            })
            
            # Update previous values for next iteration
            self.a_prev = a_current
            self.b_prev = b_current
            
        return pd.DataFrame(results)
    
    def plot(self, prices: Union[List[float], pd.Series, np.ndarray], 
             title: str = "G-Channels Indicator"):
        """
        Calculate and plot G-Channels
        
        Args:
            prices: Price data
            title: Chart title
        """
        channels = self.calculate(prices)
        
        plt.figure(figsize=(12, 8))
        
        # Plot price data
        plt.plot(prices, label='Price', color='black', linewidth=1, alpha=0.7)
        
        # Plot channels (matching Pine Script styling)
        plt.plot(channels['upper'], label='Upper Channel', color='blue', linewidth=2)
        plt.plot(channels['average'], label='Average', color='orange', linewidth=2)
        plt.plot(channels['lower'], label='Lower Channel', color='blue', linewidth=2)
        
        # Fill area between channels
        plt.fill_between(range(len(channels)), 
                        channels['upper'], channels['lower'], 
                        alpha=0.1, color='blue')
        
        plt.title(title)
        plt.xlabel('Time Period')
        plt.ylabel('Price')
        plt.legend()
        plt.grid(True, alpha=0.3)
        plt.tight_layout()
        plt.show()


def demo_g_channels():
    """
    Demonstration of G-Channels with sample data
    """
    # Generate sample price data (sine wave with trend and noise)
    np.random.seed(42)
    periods = 300
    trend = np.linspace(100, 120, periods)
    cycle = 10 * np.sin(np.linspace(0, 4*np.pi, periods))
    noise = np.random.normal(0, 2, periods)
    sample_prices = trend + cycle + noise
    
    # Create and test G-Channels with different lengths
    lengths = [50, 100, 200]
    
    fig, axes = plt.subplots(len(lengths), 1, figsize=(12, 4*len(lengths)))
    if len(lengths) == 1:
        axes = [axes]
    
    for i, length in enumerate(lengths):
        g_channels = GChannels(length=length)
        channels = g_channels.calculate(sample_prices)
        
        axes[i].plot(sample_prices, label='Price', color='black', linewidth=1, alpha=0.7)
        axes[i].plot(channels['upper'], label='Upper Channel', color='blue', linewidth=2)
        axes[i].plot(channels['average'], label='Average', color='orange', linewidth=2) 
        axes[i].plot(channels['lower'], label='Lower Channel', color='blue', linewidth=2)
        axes[i].fill_between(range(len(channels)), 
                           channels['upper'], channels['lower'], 
                           alpha=0.1, color='blue')
        
        axes[i].set_title(f'G-Channels (Length={length})')
        axes[i].set_xlabel('Time Period')
        axes[i].set_ylabel('Price')
        axes[i].legend()
        axes[i].grid(True, alpha=0.3)
    
    plt.tight_layout()
    plt.show()


if __name__ == "__main__":
    print("G-Channels Indicator - Python Implementation")
    print("=" * 50)
    
    # Run demonstration
    demo_g_channels()
    
    print("\nExample usage:")
    print("g_channels = GChannels(length=100)")
    print("channels = g_channels.calculate(your_price_data)")
    print("g_channels.plot(your_price_data)")