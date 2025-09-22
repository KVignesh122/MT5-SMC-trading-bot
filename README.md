# SMC Unified Expert Advisor Trading Bot for MetaTrader5 ✨

**Order Blocks • Fair Value Gaps • Break of Structure • Adaptive Filters • Equity Bagging**

This EA automates Smart Money Concepts (SMC) trading with adaptive ATR/session/regime filters, equity protection, and multiple strategy modes — designed for research and learning in algorithmic trading.

![Untitled](https://github.com/user-attachments/assets/9e1ad074-7a95-41ea-8c04-45ff1c1e01ec)
<p align="center">
  <strong>🚀 60%+ to 300%+ RETURNS Yearly on XAUUSD CFDs with proper finetuned parameters!! 💰🔥</strong>
</p>


---

## ✨ Features

* **3 Strategy Modes**: Order Blocks (OB), Fair Value Gaps (FVG), Break of Structure (BOS), or Auto (combines all).
* **Adaptive Volatility Filters**: ATR-driven displacement & FVG sizing.
* **Session Filter**: Skips Asian session, focuses on London & New York.
* **Regime Detection**: ADX or Efficiency Ratio to trade only in trending markets.
* **Equity Bagging System**: Automatically locks profits and caps losses at account equity levels.
* **Flexible Risk Management**: Position sizing per \$1,000 balance, ATR-based SL/TP.

---

## ⚡ Getting Started

### 1. Open a Trading Account

To run the EA, you’ll need a **MetaTrader 5 broker account**. Recommended brokers:

* [Pepperstone MT5](https://pepperstone.com/en/) *(Please mention my email vignesh.k@skybluefin.tech or k_vignesh@hotmail.com in the 'How did you hear of us' section under ‘account preferences’ when signing up to enjoy 20 commission-free trades.)*
* [IC Markets MT5](https://www.icmarkets.com/global/en/) 

Both are trusted CFD brokers offering low spreads and reliable execution.

### 2. Download MetaTrader 5

* [Download MT5 from Official Website](https://www.metatrader5.com/en/download)

### 3. Install the EA

1. Open MT5 → Go to **File → Open Data Folder**
2. Navigate to **MQL5 → Experts**
3. Save `EA_Script.mq5` here
4. Or open **MetaEditor** (MT5 IDE), create a new Expert Advisor with desired name, and copy-paste the code.
5. Click **Compile** → EA is now ready under *Navigator → Expert Advisors*.

---

## ⚙️ Input Parameters

| Parameter                    | Description                                    |
| ---------------------------- | ---------------------------------------------- |
| **Strategy**                 | Choose OB / FVG / BOS / AUTO                   |
| **MagicNumber / HedgeMagic** | Unique IDs for EA trades                       |
| **OneTradePerBar**           | Ensures no duplicate trades on the same candle |
| **LotPerK**                  | Lot size per \$1,000 balance                   |
| **BagProfitPercent**         | Close all trades when equity ≥ X% profit       |
| **BagLossPercent**           | Close all trades when equity ≤ X% loss         |
| **UseSessionFilter**         | Trade only London & NY, skip Asia              |
| **UseATRFilters**            | Adaptive thresholds based on volatility        |
| **UseRegimeFilter**          | Trade BOS only in trending markets             |
| **RegimeMethod**             | ADX or Efficiency Ratio                        |
| **ATR\_Period**              | ATR length for volatility filters              |
| **SwingBars**                | Lookback period for swing highs/lows           |
| **FibRetraceLevel**          | Order Block entry retracement (e.g. 61.8%)     |
| **DisplacementMin**          | Minimum displacement multiplier (auto if 0)    |
| **MaxSpreadPoints**          | Max spread allowed (in points)                 |

---

## 📊 Backtesting & Deployment

1. Open **MT5 Strategy Tester** → Select `EA_Script` or the name you saved your EA as.
2. Choose symbol (e.g., **XAUUSD, EURUSD**) & timeframe.
3. Select **Every Tick** for best accuracy.
4. Configure parameters → Run backtest → View reports & graphs.
5. Once satisfied, drag the EA onto a live or demo chart to deploy.

*(Tip: Always start on a demo account before going live!)*

---

## ⚠️ Disclaimer

CFD trading is **high risk** and not suitable for all investors. This EA is provided **for educational and research purposes only**. It is **not financial advice** and past performance does not guarantee future results. Use at your own discretion and risk.

---

## 📜 License

This project is pioneered by **SkyBlue Fintech (Singapore)** and licensed under the **Apache-2.0 License**.
See the [LICENSE](LICENSE) file for details.

<img width="190" height="55" alt="Skyblue_Horizontal_Full Color (Light BG)" src="https://github.com/user-attachments/assets/c4c7dde4-0281-406b-9031-a673ce607a0a" />
