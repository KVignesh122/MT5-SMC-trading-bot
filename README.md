> **Looking for stabilized versions of my live trading strategies/bots?**
>
> Check out **SkyBlue HorizonEdge** series (**HE Alex** and **HE Realm**): [skybluefin.tech/HorizonEdge](https://skybluefin.tech/HorizonEdge)
>
> Setup instructions: [skybluefin.tech/HE-Setup](https://skybluefin.tech/HE-Setup)
>
> After setup, message me so I can guide you on configuring the stop-loss killswitch.

# SMC Unified Expert Advisor Trading Bot for MetaTrader5 ✨

**Order Blocks • Fair Value Gaps • Break of Structure • Adaptive Filters • Equity Bagging**

This EA automates Smart Money Concepts (SMC) trading with adaptive ATR/session/regime filters, equity protection, and multiple strategy modes — designed for research and learning in algorithmic trading.

![Untitled](https://github.com/user-attachments/assets/9e1ad074-7a95-41ea-8c04-45ff1c1e01ec)
<p align="center">
  <strong>🚀 60%+ to 300%+ RETURNS Yearly on XAUUSD CFDs with proper finetuned parameters!! 💰🔥</strong>
</p>

## How is this possible ❓

Institutions move markets with massive orders, but retail traders like us can still spot their footprints and ride along for some smart profits 😉:

💡 𝗢𝗿𝗱𝗲𝗿 𝗕𝗹𝗼𝗰𝗸𝘀: Financial institutions split their huge orders into smaller chunks so that they get their orders filled at better prices. Price of the asset often revisits these levels, giving us a chance to enter.

💡 𝗙𝗮𝗶𝗿 𝗩𝗮𝗹𝘂𝗲 𝗚𝗮𝗽𝘀 (𝗙𝗩𝗚𝘀): The sudden price jump from such large orders create a hole in the market that price has to come back and “fill” – a repeatable edge.

💡 𝗕𝗿𝗲𝗮𝗸 𝗼𝗳 𝗦𝘁𝗿𝘂𝗰𝘁𝘂𝗿𝗲 (𝗕𝗢𝗦): When price smashes through a key order block zone, it often signals the start of a new trend.

## ✨ Features

* **3 Strategy Modes**: Order Blocks (OB), Fair Value Gaps (FVG), Break of Structure (BOS), or Auto (combines all).
* **Adaptive Volatility Filters**: ATR-driven displacement & FVG sizing.
* **Session Filter**: Skips Asian session, focuses on London & New York.
* **Regime Detection**: ADX or Efficiency Ratio to trade only in trending markets.
* **Equity Bagging System**: Automatically locks profits and caps losses at account equity levels.
* **Flexible Risk Management**: Position sizing per \$1,000 balance, ATR-based SL/TP.

## ⚡ Getting Started

### 1. Open a Trading Account

To run the EA, you’ll need a **MetaTrader 5 broker account**. Recommended broker, click signup with my referral link:

* [Pepperstone MT5](https://trk.pepperstonepartners.com/aff_c?offer_id=367&aff_id=41491)
_**Choose Pepperstone Razor Account type for optimal bot functionality and low spreads.**_

Pepperstone is a trusted CFD broker regulated in multiple jurisdictions, offering low spreads and reliable execution. 

### 2. Download MetaTrader 5

* [Download MT5 from Official Website](https://www.metatrader5.com/en/download)

### 3. Install the EA

1. Open MT5 → Go to **File → Open Data Folder**
2. Navigate to **MQL5 → Experts**
3. Save `EA_Script.mq5` here
4. Or open **MetaEditor** (MT5 IDE), create a new Expert Advisor with desired name, and copy-paste the code.
5. Click **Compile** → EA is now ready under *Navigator → Expert Advisors*.

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

## ⚠️ Disclaimer

CFD trading is **high risk** and not suitable for all investors. This EA is provided **for educational and research purposes only**. It is **not financial advice** and past performance does not guarantee future results. Use at your own discretion and risk.

## 💼 Hire Me / Consulting

<i>If this project caught your eye — this is just the beginning. This SMC trading bot is one of over half a dozen algorithmic strategies I’ve researched, tested, and built from scratch, which all have the potential of giving jaw-dropping returns. 🤑</i>

✌🏾 I’m **Vig**, a FinTech innovator and data-driven engineer from Singapore, who has built production-ready Expert Advisor trading bots, [ML-powered market insights platforms](https://www.insaights.fyi), and scalable data systems. I’m now looking to bring my skills to the institutional side of trading and data engineering:

📊 Handling larger, more complex datasets and infrastructures

🏦 Learning from seasoned experts in professional finance & technology

🚀 Applying my creativity and quantitative mindset to contribute to impactful solutions

**If you’re an institution, hedge fund, fintech, or quant team and are impressed by this work, let’s connect.** Whether it’s a full-time role or consulting collaboration, I’d love to discuss how I can bring value to your team.

📬 Reach me here: 

 • [LinkedIn](https://www.linkedin.com/in/kvignesh122)
 
 • ✉️ vig.kvel@gmail.com

---

## 📜 License

This project is pioneered by **SkyBlue Fintech (Singapore)** and licensed under the **Apache-2.0 License**.
See the [LICENSE](LICENSE) file for details.

<img width="190" height="55" alt="Skyblue_Horizontal_Full Color (Light BG)" src="https://github.com/user-attachments/assets/c4c7dde4-0281-406b-9031-a673ce607a0a" />
