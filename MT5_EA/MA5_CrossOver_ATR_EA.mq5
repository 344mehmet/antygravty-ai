//+------------------------------------------------------------------+
//|                          MA5_CrossOver_ATR_EA.mq5                |
//|                        344Mehmet LLM Ordusu                      |
//|                  $100 to $1,000,000 Challenge EA                 |
//+------------------------------------------------------------------+
#property copyright "344Mehmet LLM Ordusu"
#property link      "https://github.com/344mehmet"
#property version   "1.00"
#property description "5 MA Kesişim + ATR Yön Bulan EA"
#property description "$100'dan $1,000,000 Hedefli Mikro Lot Sistemi"
#property strict

#include <Trade\Trade.mqh>
#include <Trade\PositionInfo.mqh>
#include <Trade\OrderInfo.mqh>

//--- Enum definitions
enum ENUM_MA_METHOD_EXT { MA_SMA=0, MA_EMA=1, MA_SMMA=2, MA_LWMA=3 };
enum ENUM_SIGNAL_TYPE { SIGNAL_NONE=0, SIGNAL_BUY=1, SIGNAL_SELL=2 };
enum ENUM_ORDER_TYPE_EXT { ORDER_MARKET=0, ORDER_PENDING=1, ORDER_BOTH=2 };

//+------------------------------------------------------------------+
//| INPUT PARAMETERS                                                  |
//+------------------------------------------------------------------+
input group "=== HEDEF AYARLARI ==="
input double   InpStartBalance     = 100.0;        // Başlangıç Bakiyesi ($)
input double   InpTargetBalance    = 1000000.0;    // Hedef Bakiye ($)
input double   InpDailyTarget      = 5.0;          // Günlük Hedef (%)
input double   InpMaxDailyLoss     = 3.0;          // Max Günlük Kayıp (%)

input group "=== MA AYARLARI ==="
input int      InpMA1_Period       = 5;            // MA1 Periyodu (En Hızlı)
input int      InpMA2_Period       = 10;           // MA2 Periyodu
input int      InpMA3_Period       = 20;           // MA3 Periyodu
input int      InpMA4_Period       = 50;           // MA4 Periyodu
input int      InpMA5_Period       = 100;          // MA5 Periyodu (En Yavaş)
input ENUM_MA_METHOD_EXT InpMA_Method = MA_EMA;    // MA Metodu
input ENUM_APPLIED_PRICE InpMA_Price = PRICE_CLOSE; // Uygulanan Fiyat

input group "=== ATR AYARLARI ==="
input int      InpATR_Period       = 14;           // ATR Periyodu
input double   InpATR_Multiplier   = 1.5;          // ATR Çarpanı (SL için)
input double   InpATR_TP_Multiplier = 2.5;         // ATR TP Çarpanı

input group "=== RİSK YÖNETİMİ ==="
input double   InpRiskPercent      = 1.0;          // Risk Yüzdesi (%)
input double   InpMinLot           = 0.01;         // Minimum Lot
input double   InpMaxLot           = 10.0;         // Maximum Lot
input int      InpMaxOrders        = 5;            // Max Açık Emir Sayısı
input int      InpMaxPendingOrders = 3;            // Max Bekleyen Emir

input group "=== BEKLEYEN EMİR AYARLARI ==="
input ENUM_ORDER_TYPE_EXT InpOrderType = ORDER_PENDING; // Emir Tipi
input int      InpPendingDistance  = 10;           // Bekleyen Emir Mesafesi (pips)
input int      InpPendingExpiry    = 240;          // Emir Geçerlilik Süresi (dakika)

input group "=== İŞLEM AYARLARI ==="
input int      InpMagicNumber      = 344001;       // Magic Number
input int      InpSlippage         = 3;            // Slippage (pips)
input string   InpComment          = "MA5_ATR";    // Emir Yorumu
input bool     InpShowPanel        = true;         // Panel Göster
input bool     InpShowSignals      = true;         // Sinyal Göster
input bool     InpEnableAlerts     = true;         // Alarm Etkin

input group "=== RSI FİLTRESİ ==="
input bool     InpUseRSI           = true;         // RSI Filtresi Kullan
input int      InpRSI_Period       = 14;           // RSI Periyodu
input int      InpRSI_Overbought   = 70;           // Aşırı Alım Seviyesi
input int      InpRSI_Oversold     = 30;           // Aşırı Satım Seviyesi
input bool     InpRSI_Confirmation = true;         // RSI Yön Doğrulaması

input group "=== VOLUME FİLTRESİ ==="
input bool     InpUseVolume        = true;         // Volume Filtresi Kullan
input int      InpVolume_Period    = 20;           // Volume MA Periyodu
input double   InpVolume_Multiplier = 1.5;         // Min Volume Çarpanı

input group "=== SESSION FİLTRESİ ==="
input bool     InpUseSession       = true;         // Session Filtresi Kullan
input int      InpSession_StartHour = 8;           // Başlangıç Saati (Server)
input int      InpSession_EndHour   = 20;          // Bitiş Saati (Server)
input bool     InpTradeFriday      = true;         // Cuma İşlem Yap
input int      InpFridayCloseHour  = 18;           // Cuma Kapanış Saati

input group "=== NEWS FİLTRESİ ==="
input bool     InpUseNews          = false;        // News Filtresi Kullan (Manuel)
input int      InpNewsMinutesBefore = 30;          // Haber Öncesi Bekle (dk)
input int      InpNewsMinutesAfter  = 15;          // Haber Sonrası Bekle (dk)

input group "=== MARTİNGALE ==="
input bool     InpUseMartingale    = false;        // Martingale Kullan
input bool     InpAntiMartingale   = false;        // Anti-Martingale (Kazançta artır)
input double   InpMartingaleMultiplier = 2.0;      // Lot Çarpanı
input int      InpMartingaleMaxLevel = 3;          // Max Martingale Seviyesi

input group "=== MULTI-TIMEFRAME ==="
input bool     InpUseMTF           = true;         // Multi-Timeframe Kullan
input ENUM_TIMEFRAMES InpMTF_Higher = PERIOD_H4;   // Üst Zaman Dilimi
input bool     InpMTF_TrendFilter  = true;         // Trend Filtresi (Üst TF)

input group "=== HEDGE MODU ==="
input bool     InpUseHedge         = false;        // Hedge Modu Kullan
input double   InpHedgeLossPercent = 1.0;          // Hedge Tetikleme Kaybı (%)
input double   InpHedgeLotRatio    = 0.5;          // Hedge Lot Oranı

input group "=== PARTIAL CLOSE ==="
input bool     InpUsePartialClose  = true;         // Kısmi Kapanış Kullan
input double   InpPartial1_Percent = 50.0;         // 1. Kapanış Yüzdesi
input double   InpPartial1_ATRMult = 1.0;          // 1. Kapanış ATR Çarpanı
input double   InpPartial2_Percent = 30.0;         // 2. Kapanış Yüzdesi
input double   InpPartial2_ATRMult = 1.5;          // 2. Kapanış ATR Çarpanı

//+------------------------------------------------------------------+
//| GLOBAL VARIABLES                                                  |
//+------------------------------------------------------------------+
CTrade         trade;
CPositionInfo  posInfo;
COrderInfo     orderInfo;

// MA Handles
int handleMA1, handleMA2, handleMA3, handleMA4, handleMA5;
int handleATR;

// New module handles
int handleRSI;
int handleVolume;
int handleMTF_MA1, handleMTF_MA5;

// MA Values
double ma1[], ma2[], ma3[], ma4[], ma5[];
double atr[];

// New module values
double rsi[];
double volume[], volumeMA[];
double mtf_ma1[], mtf_ma5[];

// Statistics
double dailyProfit = 0;
double dailyStartBalance = 0;
datetime lastDayCheck = 0;
int totalTrades = 0;
int winTrades = 0;
int lossTrades = 0;

// Signal tracking
ENUM_SIGNAL_TYPE lastSignal = SIGNAL_NONE;
datetime lastSignalTime = 0;

// Martingale tracking
int consecutiveLosses = 0;
int consecutiveWins = 0;
int martingaleLevel = 0;
double lastLotSize = 0;

// Partial close tracking
datetime lastPartialClose1[];
datetime lastPartialClose2[];

// News filter (manual input via global variable)
datetime newsEventTime = 0;

// Chart objects
string panelName = "MA5_Panel";
string signalArrowPrefix = "Signal_";

//+------------------------------------------------------------------+
//| Expert initialization function                                    |
//+------------------------------------------------------------------+
int OnInit()
{
    // Initialize trade object
    trade.SetExpertMagicNumber(InpMagicNumber);
    trade.SetDeviationInPoints(InpSlippage);
    trade.SetTypeFilling(ORDER_FILLING_IOC);
    trade.SetAsyncMode(false);
    
    // Create indicator handles
    ENUM_MA_METHOD maMethod = (ENUM_MA_METHOD)InpMA_Method;
    
    handleMA1 = iMA(_Symbol, PERIOD_CURRENT, InpMA1_Period, 0, maMethod, InpMA_Price);
    handleMA2 = iMA(_Symbol, PERIOD_CURRENT, InpMA2_Period, 0, maMethod, InpMA_Price);
    handleMA3 = iMA(_Symbol, PERIOD_CURRENT, InpMA3_Period, 0, maMethod, InpMA_Price);
    handleMA4 = iMA(_Symbol, PERIOD_CURRENT, InpMA4_Period, 0, maMethod, InpMA_Price);
    handleMA5 = iMA(_Symbol, PERIOD_CURRENT, InpMA5_Period, 0, maMethod, InpMA_Price);
    handleATR = iATR(_Symbol, PERIOD_CURRENT, InpATR_Period);
    
    // NEW MODULE INDICATORS
    // RSI
    if(InpUseRSI)
        handleRSI = iRSI(_Symbol, PERIOD_CURRENT, InpRSI_Period, PRICE_CLOSE);
    
    // Volume
    if(InpUseVolume)
        handleVolume = iMA(_Symbol, PERIOD_CURRENT, InpVolume_Period, 0, MODE_SMA, VOLUME_TICK);
    
    // Multi-Timeframe
    if(InpUseMTF)
    {
        handleMTF_MA1 = iMA(_Symbol, InpMTF_Higher, InpMA1_Period, 0, maMethod, InpMA_Price);
        handleMTF_MA5 = iMA(_Symbol, InpMTF_Higher, InpMA5_Period, 0, maMethod, InpMA_Price);
    }
    
    if(handleMA1 == INVALID_HANDLE || handleMA2 == INVALID_HANDLE || 
       handleMA3 == INVALID_HANDLE || handleMA4 == INVALID_HANDLE || 
       handleMA5 == INVALID_HANDLE || handleATR == INVALID_HANDLE)
    {
        Print("❌ İndikatör yüklenemedi!");
        return INIT_FAILED;
    }
    
    // Set arrays as series
    ArraySetAsSeries(ma1, true);
    ArraySetAsSeries(ma2, true);
    ArraySetAsSeries(ma3, true);
    ArraySetAsSeries(ma4, true);
    ArraySetAsSeries(ma5, true);
    ArraySetAsSeries(atr, true);
    ArraySetAsSeries(rsi, true);
    ArraySetAsSeries(volume, true);
    ArraySetAsSeries(volumeMA, true);
    ArraySetAsSeries(mtf_ma1, true);
    ArraySetAsSeries(mtf_ma5, true);
    
    // Initialize daily tracking
    dailyStartBalance = AccountInfoDouble(ACCOUNT_BALANCE);
    lastDayCheck = TimeCurrent();
    
    // Create panel
    if(InpShowPanel)
        CreatePanel();
    
    Print("✅ MA5 CrossOver ATR EA v2.0 başlatıldı");
    Print("📊 Hedef: $", InpStartBalance, " -> $", InpTargetBalance);
    Print("🔧 Modüller: RSI=", InpUseRSI, " Vol=", InpUseVolume, " MTF=", InpUseMTF, 
          " Session=", InpUseSession, " Hedge=", InpUseHedge, " Partial=", InpUsePartialClose);
    
    return INIT_SUCCEEDED;
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                                  |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
    // Release indicator handles
    IndicatorRelease(handleMA1);
    IndicatorRelease(handleMA2);
    IndicatorRelease(handleMA3);
    IndicatorRelease(handleMA4);
    IndicatorRelease(handleMA5);
    IndicatorRelease(handleATR);
    
    // Delete chart objects
    ObjectsDeleteAll(0, panelName);
    ObjectsDeleteAll(0, signalArrowPrefix);
    
    Print("🔴 EA durduruldu. Toplam Trade: ", totalTrades, " Win: ", winTrades, " Loss: ", lossTrades);
}

//+------------------------------------------------------------------+
//| Expert tick function                                              |
//+------------------------------------------------------------------+
void OnTick()
{
    // Check for new day
    CheckNewDay();
    
    // Check daily limits
    if(!CheckDailyLimits())
        return;
    
    // Check if target reached
    if(CheckTargetReached())
        return;
    
    // Session filter - don't trade outside hours
    if(!CheckSessionFilter())
        return;
    
    // Update indicators
    if(!UpdateIndicators())
        return;
    
    // Get signal
    ENUM_SIGNAL_TYPE signal = GetSignal();
    
    // Process signal with all filters
    if(signal != SIGNAL_NONE)
    {
        // Apply all module filters
        if(ApplyAllFilters(signal))
        {
            ProcessSignal(signal);
        }
    }
    
    // Manage open positions
    ManagePositions();
    
    // Check pending orders expiry
    CheckPendingOrders();
    
    // NEW MODULE MANAGEMENT
    // Hedge management
    CheckHedgeManagement();
    
    // Partial close management
    CheckPartialClose();
    
    // Update panel
    if(InpShowPanel)
        UpdatePanel();
}

//+------------------------------------------------------------------+
//| Update indicator values                                           |
//+------------------------------------------------------------------+
bool UpdateIndicators()
{
    if(CopyBuffer(handleMA1, 0, 0, 3, ma1) < 3) return false;
    if(CopyBuffer(handleMA2, 0, 0, 3, ma2) < 3) return false;
    if(CopyBuffer(handleMA3, 0, 0, 3, ma3) < 3) return false;
    if(CopyBuffer(handleMA4, 0, 0, 3, ma4) < 3) return false;
    if(CopyBuffer(handleMA5, 0, 0, 3, ma5) < 3) return false;
    if(CopyBuffer(handleATR, 0, 0, 3, atr) < 3) return false;
    return true;
}

//+------------------------------------------------------------------+
//| Get trading signal                                                |
//+------------------------------------------------------------------+
ENUM_SIGNAL_TYPE GetSignal()
{
    // Get ATR direction
    bool atrUp = IsATRDirectionUp();
    
    // Check MA crossover
    bool bullishCross = CheckBullishCrossover();
    bool bearishCross = CheckBearishCrossover();
    
    // Check MA alignment
    bool bullishAlignment = CheckBullishAlignment();
    bool bearishAlignment = CheckBearishAlignment();
    
    // Generate signal
    if(bullishCross && bullishAlignment && atrUp)
    {
        if(lastSignal != SIGNAL_BUY || TimeCurrent() - lastSignalTime > 3600)
        {
            lastSignal = SIGNAL_BUY;
            lastSignalTime = TimeCurrent();
            DrawSignalArrow(SIGNAL_BUY);
            if(InpEnableAlerts)
                Alert("🟢 ALIŞ SİNYALİ! ", _Symbol, " @ ", SymbolInfoDouble(_Symbol, SYMBOL_BID));
            return SIGNAL_BUY;
        }
    }
    else if(bearishCross && bearishAlignment && !atrUp)
    {
        if(lastSignal != SIGNAL_SELL || TimeCurrent() - lastSignalTime > 3600)
        {
            lastSignal = SIGNAL_SELL;
            lastSignalTime = TimeCurrent();
            DrawSignalArrow(SIGNAL_SELL);
            if(InpEnableAlerts)
                Alert("🔴 SATIŞ SİNYALİ! ", _Symbol, " @ ", SymbolInfoDouble(_Symbol, SYMBOL_ASK));
            return SIGNAL_SELL;
        }
    }
    
    return SIGNAL_NONE;
}

//+------------------------------------------------------------------+
//| Check if ATR direction is up                                      |
//+------------------------------------------------------------------+
bool IsATRDirectionUp()
{
    double close0 = iClose(_Symbol, PERIOD_CURRENT, 0);
    double close1 = iClose(_Symbol, PERIOD_CURRENT, 1);
    double atrValue = atr[0];
    
    // Price change relative to ATR determines direction
    double priceChange = close0 - close1;
    
    // If price is moving up and above ATR threshold -> uptrend
    if(priceChange > atrValue * 0.3)
        return true;
    // If price is moving down and below ATR threshold -> downtrend
    if(priceChange < -atrValue * 0.3)
        return false;
    
    // Use MA1 > MA5 as secondary direction
    return ma1[0] > ma5[0];
}

//+------------------------------------------------------------------+
//| Check for bullish crossover                                       |
//+------------------------------------------------------------------+
bool CheckBullishCrossover()
{
    // MA1 crosses above MA2 (fast crosses above slow)
    bool cross1_2 = ma1[1] <= ma2[1] && ma1[0] > ma2[0];
    // MA2 crosses above MA3
    bool cross2_3 = ma2[1] <= ma3[1] && ma2[0] > ma3[0];
    // MA3 crosses above MA4
    bool cross3_4 = ma3[1] <= ma4[1] && ma3[0] > ma4[0];
    // MA4 crosses above MA5
    bool cross4_5 = ma4[1] <= ma5[1] && ma4[0] > ma5[0];
    
    // At least 2 crossovers for signal
    int crossCount = 0;
    if(cross1_2) crossCount++;
    if(cross2_3) crossCount++;
    if(cross3_4) crossCount++;
    if(cross4_5) crossCount++;
    
    return crossCount >= 2;
}

//+------------------------------------------------------------------+
//| Check for bearish crossover                                       |
//+------------------------------------------------------------------+
bool CheckBearishCrossover()
{
    // MA1 crosses below MA2
    bool cross1_2 = ma1[1] >= ma2[1] && ma1[0] < ma2[0];
    // MA2 crosses below MA3
    bool cross2_3 = ma2[1] >= ma3[1] && ma2[0] < ma3[0];
    // MA3 crosses below MA4
    bool cross3_4 = ma3[1] >= ma4[1] && ma3[0] < ma4[0];
    // MA4 crosses below MA5
    bool cross4_5 = ma4[1] >= ma5[1] && ma4[0] < ma5[0];
    
    int crossCount = 0;
    if(cross1_2) crossCount++;
    if(cross2_3) crossCount++;
    if(cross3_4) crossCount++;
    if(cross4_5) crossCount++;
    
    return crossCount >= 2;
}

//+------------------------------------------------------------------+
//| Check bullish alignment (MA1 > MA2 > MA3 > MA4 > MA5)            |
//+------------------------------------------------------------------+
bool CheckBullishAlignment()
{
    return ma1[0] > ma2[0] && ma2[0] > ma3[0] && ma3[0] > ma4[0] && ma4[0] > ma5[0];
}

//+------------------------------------------------------------------+
//| Check bearish alignment (MA1 < MA2 < MA3 < MA4 < MA5)            |
//+------------------------------------------------------------------+
bool CheckBearishAlignment()
{
    return ma1[0] < ma2[0] && ma2[0] < ma3[0] && ma3[0] < ma4[0] && ma4[0] < ma5[0];
}

//+------------------------------------------------------------------+
//| Process trading signal                                            |
//+------------------------------------------------------------------+
void ProcessSignal(ENUM_SIGNAL_TYPE signal)
{
    // Check max orders
    if(CountOpenPositions() >= InpMaxOrders)
    {
        Print("⚠️ Max emir sayısına ulaşıldı: ", InpMaxOrders);
        return;
    }
    
    if(CountPendingOrders() >= InpMaxPendingOrders)
    {
        Print("⚠️ Max bekleyen emir sayısına ulaşıldı: ", InpMaxPendingOrders);
        return;
    }
    
    // Calculate lot size
    double lotSize = CalculateLotSize();
    
    // Calculate SL and TP
    double sl, tp;
    CalculateSL_TP(signal, sl, tp);
    
    // Place orders
    if(InpOrderType == ORDER_MARKET || InpOrderType == ORDER_BOTH)
    {
        PlaceMarketOrder(signal, lotSize, sl, tp);
    }
    
    if(InpOrderType == ORDER_PENDING || InpOrderType == ORDER_BOTH)
    {
        PlacePendingOrder(signal, lotSize, sl, tp);
    }
}

//+------------------------------------------------------------------+
//| Calculate dynamic lot size based on risk                          |
//+------------------------------------------------------------------+
double CalculateLotSize()
{
    double balance = AccountInfoDouble(ACCOUNT_BALANCE);
    double riskAmount = balance * (InpRiskPercent / 100.0);
    
    double atrValue = atr[0];
    double slPoints = atrValue * InpATR_Multiplier;
    double tickValue = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE);
    double tickSize = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE);
    double point = SymbolInfoDouble(_Symbol, SYMBOL_POINT);
    
    if(tickValue == 0 || slPoints == 0)
        return InpMinLot;
    
    // Calculate lot size based on risk
    double slInTicks = slPoints / tickSize;
    double lotSize = riskAmount / (slInTicks * tickValue);
    
    // Apply progressive lot sizing for $100 to $1M challenge
    double progressMultiplier = CalculateProgressMultiplier(balance);
    lotSize *= progressMultiplier;
    
    // Normalize lot size
    double minLot = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
    double maxLot = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MAX);
    double lotStep = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);
    
    lotSize = MathMax(minLot, MathMin(maxLot, lotSize));
    lotSize = MathMax(InpMinLot, MathMin(InpMaxLot, lotSize));
    lotSize = NormalizeDouble(MathFloor(lotSize / lotStep) * lotStep, 2);
    
    return lotSize;
}

//+------------------------------------------------------------------+
//| Calculate progress multiplier for compound growth                 |
//+------------------------------------------------------------------+
double CalculateProgressMultiplier(double balance)
{
    // Progressive phases for $100 to $1M
    if(balance < 500)        return 0.5;   // Conservative phase
    if(balance < 1000)       return 0.7;   // Building phase
    if(balance < 5000)       return 0.9;   // Growth phase
    if(balance < 10000)      return 1.0;   // Standard phase
    if(balance < 50000)      return 1.1;   // Acceleration phase
    if(balance < 100000)     return 1.2;   // Advanced phase
    if(balance < 500000)     return 1.3;   // Pro phase
    return 1.5;                             // Final push phase
}

//+------------------------------------------------------------------+
//| Calculate Stop Loss and Take Profit                               |
//+------------------------------------------------------------------+
void CalculateSL_TP(ENUM_SIGNAL_TYPE signal, double &sl, double &tp)
{
    double atrValue = atr[0];
    double price = signal == SIGNAL_BUY ? 
                   SymbolInfoDouble(_Symbol, SYMBOL_ASK) : 
                   SymbolInfoDouble(_Symbol, SYMBOL_BID);
    
    double slDistance = atrValue * InpATR_Multiplier;
    double tpDistance = atrValue * InpATR_TP_Multiplier;
    
    int digits = (int)SymbolInfoInteger(_Symbol, SYMBOL_DIGITS);
    
    if(signal == SIGNAL_BUY)
    {
        sl = NormalizeDouble(price - slDistance, digits);
        tp = NormalizeDouble(price + tpDistance, digits);
    }
    else // SELL
    {
        sl = NormalizeDouble(price + slDistance, digits);
        tp = NormalizeDouble(price - tpDistance, digits);
    }
}

//+------------------------------------------------------------------+
//| Place market order                                                |
//+------------------------------------------------------------------+
bool PlaceMarketOrder(ENUM_SIGNAL_TYPE signal, double lot, double sl, double tp)
{
    double price = signal == SIGNAL_BUY ? 
                   SymbolInfoDouble(_Symbol, SYMBOL_ASK) : 
                   SymbolInfoDouble(_Symbol, SYMBOL_BID);
    
    ENUM_ORDER_TYPE orderType = signal == SIGNAL_BUY ? ORDER_TYPE_BUY : ORDER_TYPE_SELL;
    
    string comment = InpComment + "_M_" + TimeToString(TimeCurrent(), TIME_MINUTES);
    
    bool result = trade.PositionOpen(_Symbol, orderType, lot, price, sl, tp, comment);
    
    if(result)
    {
        totalTrades++;
        Print("✅ Market emir açıldı: ", EnumToString(orderType), " Lot: ", lot, 
              " SL: ", sl, " TP: ", tp);
        
        // Draw order on chart
        DrawOrderLine(price, sl, tp, signal);
    }
    else
    {
        Print("❌ Emir hatası: ", trade.ResultRetcodeDescription());
    }
    
    return result;
}

//+------------------------------------------------------------------+
//| Place pending order                                               |
//+------------------------------------------------------------------+
bool PlacePendingOrder(ENUM_SIGNAL_TYPE signal, double lot, double sl, double tp)
{
    double price = signal == SIGNAL_BUY ? 
                   SymbolInfoDouble(_Symbol, SYMBOL_ASK) : 
                   SymbolInfoDouble(_Symbol, SYMBOL_BID);
    
    double point = SymbolInfoDouble(_Symbol, SYMBOL_POINT);
    int digits = (int)SymbolInfoInteger(_Symbol, SYMBOL_DIGITS);
    double pendingDistance = InpPendingDistance * point * 10; // Convert pips
    
    ENUM_ORDER_TYPE orderType;
    double pendingPrice;
    
    if(signal == SIGNAL_BUY)
    {
        // Buy Limit (below current price) and Buy Stop (above)
        orderType = ORDER_TYPE_BUY_LIMIT;
        pendingPrice = NormalizeDouble(price - pendingDistance, digits);
        
        // Adjust SL/TP for new entry price
        sl = pendingPrice - (price - sl);
        tp = pendingPrice + (tp - price);
    }
    else // SELL
    {
        orderType = ORDER_TYPE_SELL_LIMIT;
        pendingPrice = NormalizeDouble(price + pendingDistance, digits);
        
        sl = pendingPrice + (sl - price);
        tp = pendingPrice - (price - tp);
    }
    
    sl = NormalizeDouble(sl, digits);
    tp = NormalizeDouble(tp, digits);
    
    datetime expiry = TimeCurrent() + InpPendingExpiry * 60;
    string comment = InpComment + "_P_" + TimeToString(TimeCurrent(), TIME_MINUTES);
    
    bool result = trade.OrderOpen(_Symbol, orderType, lot, 0, pendingPrice, sl, tp, 
                                   ORDER_TIME_SPECIFIED, expiry, comment);
    
    if(result)
    {
        Print("✅ Bekleyen emir açıldı: ", EnumToString(orderType), 
              " @ ", pendingPrice, " Lot: ", lot);
        
        DrawPendingOrderLine(pendingPrice, sl, tp, signal);
    }
    else
    {
        Print("❌ Bekleyen emir hatası: ", trade.ResultRetcodeDescription());
    }
    
    return result;
}

//+------------------------------------------------------------------+
//| Manage open positions                                             |
//+------------------------------------------------------------------+
void ManagePositions()
{
    for(int i = PositionsTotal() - 1; i >= 0; i--)
    {
        if(!posInfo.SelectByIndex(i))
            continue;
        
        if(posInfo.Symbol() != _Symbol || posInfo.Magic() != InpMagicNumber)
            continue;
        
        // Trailing stop with ATR
        TrailingStopATR(posInfo.Ticket());
        
        // Break even
        MoveToBreakEven(posInfo.Ticket());
    }
}

//+------------------------------------------------------------------+
//| ATR-based trailing stop                                           |
//+------------------------------------------------------------------+
void TrailingStopATR(ulong ticket)
{
    if(!posInfo.SelectByTicket(ticket))
        return;
    
    double atrValue = atr[0];
    double trailingDistance = atrValue * InpATR_Multiplier * 0.7;
    double point = SymbolInfoDouble(_Symbol, SYMBOL_POINT);
    int digits = (int)SymbolInfoInteger(_Symbol, SYMBOL_DIGITS);
    
    double currentPrice, newSL;
    double currentSL = posInfo.StopLoss();
    double openPrice = posInfo.PriceOpen();
    
    if(posInfo.PositionType() == POSITION_TYPE_BUY)
    {
        currentPrice = SymbolInfoDouble(_Symbol, SYMBOL_BID);
        newSL = NormalizeDouble(currentPrice - trailingDistance, digits);
        
        // Only trail if in profit and new SL is higher
        if(currentPrice > openPrice + trailingDistance && newSL > currentSL)
        {
            trade.PositionModify(ticket, newSL, posInfo.TakeProfit());
        }
    }
    else // SELL
    {
        currentPrice = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
        newSL = NormalizeDouble(currentPrice + trailingDistance, digits);
        
        if(currentPrice < openPrice - trailingDistance && (currentSL == 0 || newSL < currentSL))
        {
            trade.PositionModify(ticket, newSL, posInfo.TakeProfit());
        }
    }
}

//+------------------------------------------------------------------+
//| Move to break even                                                |
//+------------------------------------------------------------------+
void MoveToBreakEven(ulong ticket)
{
    if(!posInfo.SelectByTicket(ticket))
        return;
    
    double atrValue = atr[0];
    double breakEvenTrigger = atrValue * 0.8;
    double point = SymbolInfoDouble(_Symbol, SYMBOL_POINT);
    int digits = (int)SymbolInfoInteger(_Symbol, SYMBOL_DIGITS);
    
    double openPrice = posInfo.PriceOpen();
    double currentSL = posInfo.StopLoss();
    double spread = SymbolInfoInteger(_Symbol, SYMBOL_SPREAD) * point;
    
    if(posInfo.PositionType() == POSITION_TYPE_BUY)
    {
        double currentPrice = SymbolInfoDouble(_Symbol, SYMBOL_BID);
        double profit = currentPrice - openPrice;
        
        if(profit >= breakEvenTrigger && currentSL < openPrice)
        {
            double newSL = NormalizeDouble(openPrice + spread + point, digits);
            trade.PositionModify(ticket, newSL, posInfo.TakeProfit());
            Print("🔒 Break-even: Ticket ", ticket);
        }
    }
    else
    {
        double currentPrice = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
        double profit = openPrice - currentPrice;
        
        if(profit >= breakEvenTrigger && (currentSL == 0 || currentSL > openPrice))
        {
            double newSL = NormalizeDouble(openPrice - spread - point, digits);
            trade.PositionModify(ticket, newSL, posInfo.TakeProfit());
            Print("🔒 Break-even: Ticket ", ticket);
        }
    }
}

//+------------------------------------------------------------------+
//| Check and clean expired pending orders                            |
//+------------------------------------------------------------------+
void CheckPendingOrders()
{
    for(int i = OrdersTotal() - 1; i >= 0; i--)
    {
        if(!orderInfo.SelectByIndex(i))
            continue;
        
        if(orderInfo.Symbol() != _Symbol || orderInfo.Magic() != InpMagicNumber)
            continue;
        
        // Orders with expiry are auto-deleted, but check for manual cleanup
        datetime orderTime = orderInfo.TimeSetup();
        if(TimeCurrent() - orderTime > InpPendingExpiry * 60 + 60)
        {
            trade.OrderDelete(orderInfo.Ticket());
            Print("🗑️ Süresi dolan emir silindi: ", orderInfo.Ticket());
        }
    }
}

//+------------------------------------------------------------------+
//| Count open positions                                              |
//+------------------------------------------------------------------+
int CountOpenPositions()
{
    int count = 0;
    for(int i = PositionsTotal() - 1; i >= 0; i--)
    {
        if(posInfo.SelectByIndex(i))
        {
            if(posInfo.Symbol() == _Symbol && posInfo.Magic() == InpMagicNumber)
                count++;
        }
    }
    return count;
}

//+------------------------------------------------------------------+
//| Count pending orders                                              |
//+------------------------------------------------------------------+
int CountPendingOrders()
{
    int count = 0;
    for(int i = OrdersTotal() - 1; i >= 0; i--)
    {
        if(orderInfo.SelectByIndex(i))
        {
            if(orderInfo.Symbol() == _Symbol && orderInfo.Magic() == InpMagicNumber)
                count++;
        }
    }
    return count;
}

//+------------------------------------------------------------------+
//| Check new day                                                     |
//+------------------------------------------------------------------+
void CheckNewDay()
{
    MqlDateTime now, last;
    TimeCurrent(now);
    TimeToStruct(lastDayCheck, last);
    
    if(now.day != last.day)
    {
        dailyStartBalance = AccountInfoDouble(ACCOUNT_BALANCE);
        dailyProfit = 0;
        lastDayCheck = TimeCurrent();
        Print("📅 Yeni gün başladı. Başlangıç bakiyesi: $", dailyStartBalance);
    }
}

//+------------------------------------------------------------------+
//| Check daily limits                                                |
//+------------------------------------------------------------------+
bool CheckDailyLimits()
{
    double currentBalance = AccountInfoDouble(ACCOUNT_BALANCE);
    dailyProfit = ((currentBalance - dailyStartBalance) / dailyStartBalance) * 100;
    
    // Check if daily target reached
    if(dailyProfit >= InpDailyTarget)
    {
        Print("🎯 Günlük hedef ulaşıldı: ", DoubleToString(dailyProfit, 2), "%");
        return false;
    }
    
    // Check if max daily loss exceeded
    if(dailyProfit <= -InpMaxDailyLoss)
    {
        Print("⛔ Günlük kayıp limiti aşıldı: ", DoubleToString(dailyProfit, 2), "%");
        return false;
    }
    
    return true;
}

//+------------------------------------------------------------------+
//| Check if target balance reached                                   |
//+------------------------------------------------------------------+
bool CheckTargetReached()
{
    double currentBalance = AccountInfoDouble(ACCOUNT_BALANCE);
    
    if(currentBalance >= InpTargetBalance)
    {
        Print("🏆🏆🏆 HEDEF ULAŞILDI! $", InpStartBalance, " -> $", currentBalance, " 🏆🏆🏆");
        if(InpEnableAlerts)
            Alert("TEBRIKLER! $1,000,000 HEDEFINE ULASTINIZ!");
        
        // Draw celebration on chart
        DrawTargetReached(currentBalance);
        
        return true;
    }
    
    return false;
}

//+------------------------------------------------------------------+
//| Create info panel on chart                                        |
//+------------------------------------------------------------------+
void CreatePanel()
{
    int x = 10, y = 30;
    int width = 280, height = 400;
    
    // Background
    ObjectCreate(0, panelName + "_BG", OBJ_RECTANGLE_LABEL, 0, 0, 0);
    ObjectSetInteger(0, panelName + "_BG", OBJPROP_XDISTANCE, x);
    ObjectSetInteger(0, panelName + "_BG", OBJPROP_YDISTANCE, y);
    ObjectSetInteger(0, panelName + "_BG", OBJPROP_XSIZE, width);
    ObjectSetInteger(0, panelName + "_BG", OBJPROP_YSIZE, height);
    ObjectSetInteger(0, panelName + "_BG", OBJPROP_BGCOLOR, clrMidnightBlue);
    ObjectSetInteger(0, panelName + "_BG", OBJPROP_BORDER_TYPE, BORDER_FLAT);
    ObjectSetInteger(0, panelName + "_BG", OBJPROP_BORDER_COLOR, clrGold);
    ObjectSetInteger(0, panelName + "_BG", OBJPROP_CORNER, CORNER_LEFT_UPPER);
    ObjectSetInteger(0, panelName + "_BG", OBJPROP_BACK, false);
    
    // Title
    CreateLabel(panelName + "_Title", x + 10, y + 10, "🤖 MA5 CrossOver ATR EA", clrGold, 12);
    CreateLabel(panelName + "_Subtitle", x + 10, y + 30, "$100 → $1,000,000 Challenge", clrWhite, 9);
    
    // Separator
    CreateLabel(panelName + "_Sep1", x + 10, y + 50, "════════════════════════", clrDarkGray, 8);
    
    // Account Info
    CreateLabel(panelName + "_AccLabel", x + 10, y + 70, "📊 HESAP DURUMU", clrCyan, 10);
    CreateLabel(panelName + "_Balance", x + 10, y + 90, "Bakiye: $0.00", clrWhite, 9);
    CreateLabel(panelName + "_Equity", x + 10, y + 110, "Equity: $0.00", clrWhite, 9);
    CreateLabel(panelName + "_Profit", x + 10, y + 130, "Kar/Zarar: $0.00", clrWhite, 9);
    CreateLabel(panelName + "_Progress", x + 10, y + 150, "İlerleme: 0.00%", clrLime, 9);
    
    // Separator
    CreateLabel(panelName + "_Sep2", x + 10, y + 170, "════════════════════════", clrDarkGray, 8);
    
    // MA Status
    CreateLabel(panelName + "_MALabel", x + 10, y + 190, "📈 MA DURUMU", clrCyan, 10);
    CreateLabel(panelName + "_MA1", x + 10, y + 210, "MA5:  0.00000", clrWhite, 9);
    CreateLabel(panelName + "_MA2", x + 10, y + 225, "MA10: 0.00000", clrWhite, 9);
    CreateLabel(panelName + "_MA3", x + 10, y + 240, "MA20: 0.00000", clrWhite, 9);
    CreateLabel(panelName + "_MA4", x + 10, y + 255, "MA50: 0.00000", clrWhite, 9);
    CreateLabel(panelName + "_MA5", x + 10, y + 270, "MA100: 0.00000", clrWhite, 9);
    CreateLabel(panelName + "_ATR", x + 10, y + 285, "ATR: 0.00000", clrYellow, 9);
    
    // Separator
    CreateLabel(panelName + "_Sep3", x + 10, y + 305, "════════════════════════", clrDarkGray, 8);
    
    // Signal and Trade Info
    CreateLabel(panelName + "_SigLabel", x + 10, y + 325, "🎯 SİNYAL & İŞLEM", clrCyan, 10);
    CreateLabel(panelName + "_Signal", x + 10, y + 345, "Sinyal: BEKLE", clrWhite, 9);
    CreateLabel(panelName + "_Direction", x + 10, y + 360, "ATR Yön: -", clrWhite, 9);
    CreateLabel(panelName + "_Orders", x + 10, y + 375, "Açık: 0 | Bekleyen: 0", clrWhite, 9);
    CreateLabel(panelName + "_Daily", x + 10, y + 390, "Günlük: 0.00%", clrWhite, 9);
}

//+------------------------------------------------------------------+
//| Create label helper                                               |
//+------------------------------------------------------------------+
void CreateLabel(string name, int x, int y, string text, color clr, int fontSize)
{
    ObjectCreate(0, name, OBJ_LABEL, 0, 0, 0);
    ObjectSetInteger(0, name, OBJPROP_XDISTANCE, x);
    ObjectSetInteger(0, name, OBJPROP_YDISTANCE, y);
    ObjectSetString(0, name, OBJPROP_TEXT, text);
    ObjectSetInteger(0, name, OBJPROP_COLOR, clr);
    ObjectSetInteger(0, name, OBJPROP_FONTSIZE, fontSize);
    ObjectSetString(0, name, OBJPROP_FONT, "Arial");
    ObjectSetInteger(0, name, OBJPROP_CORNER, CORNER_LEFT_UPPER);
}

//+------------------------------------------------------------------+
//| Update panel information                                          |
//+------------------------------------------------------------------+
void UpdatePanel()
{
    double balance = AccountInfoDouble(ACCOUNT_BALANCE);
    double equity = AccountInfoDouble(ACCOUNT_EQUITY);
    double profit = AccountInfoDouble(ACCOUNT_PROFIT);
    double progress = ((balance - InpStartBalance) / (InpTargetBalance - InpStartBalance)) * 100;
    progress = MathMax(0, MathMin(100, progress));
    
    int digits = (int)SymbolInfoInteger(_Symbol, SYMBOL_DIGITS);
    
    // Update account info
    ObjectSetString(0, panelName + "_Balance", OBJPROP_TEXT, 
        "Bakiye: $" + DoubleToString(balance, 2));
    ObjectSetString(0, panelName + "_Equity", OBJPROP_TEXT, 
        "Equity: $" + DoubleToString(equity, 2));
    
    color profitColor = profit >= 0 ? clrLime : clrRed;
    ObjectSetString(0, panelName + "_Profit", OBJPROP_TEXT, 
        "Kar/Zarar: $" + DoubleToString(profit, 2));
    ObjectSetInteger(0, panelName + "_Profit", OBJPROP_COLOR, profitColor);
    
    ObjectSetString(0, panelName + "_Progress", OBJPROP_TEXT, 
        "İlerleme: " + DoubleToString(progress, 2) + "% → $1M");
    
    // Update MA values
    ObjectSetString(0, panelName + "_MA1", OBJPROP_TEXT, 
        "MA" + IntegerToString(InpMA1_Period) + ":  " + DoubleToString(ma1[0], digits));
    ObjectSetString(0, panelName + "_MA2", OBJPROP_TEXT, 
        "MA" + IntegerToString(InpMA2_Period) + ": " + DoubleToString(ma2[0], digits));
    ObjectSetString(0, panelName + "_MA3", OBJPROP_TEXT, 
        "MA" + IntegerToString(InpMA3_Period) + ": " + DoubleToString(ma3[0], digits));
    ObjectSetString(0, panelName + "_MA4", OBJPROP_TEXT, 
        "MA" + IntegerToString(InpMA4_Period) + ": " + DoubleToString(ma4[0], digits));
    ObjectSetString(0, panelName + "_MA5", OBJPROP_TEXT, 
        "MA" + IntegerToString(InpMA5_Period) + ": " + DoubleToString(ma5[0], digits));
    ObjectSetString(0, panelName + "_ATR", OBJPROP_TEXT, 
        "ATR(" + IntegerToString(InpATR_Period) + "): " + DoubleToString(atr[0], digits));
    
    // Update signal info
    string signalText = "Sinyal: ";
    color signalColor = clrWhite;
    if(lastSignal == SIGNAL_BUY)
    {
        signalText += "🟢 ALIŞ";
        signalColor = clrLime;
    }
    else if(lastSignal == SIGNAL_SELL)
    {
        signalText += "🔴 SATIŞ";
        signalColor = clrRed;
    }
    else
    {
        signalText += "⚪ BEKLE";
    }
    ObjectSetString(0, panelName + "_Signal", OBJPROP_TEXT, signalText);
    ObjectSetInteger(0, panelName + "_Signal", OBJPROP_COLOR, signalColor);
    
    // ATR Direction
    bool atrUp = IsATRDirectionUp();
    string dirText = atrUp ? "ATR Yön: ⬆️ YUKARI" : "ATR Yön: ⬇️ AŞAĞI";
    color dirColor = atrUp ? clrLime : clrRed;
    ObjectSetString(0, panelName + "_Direction", OBJPROP_TEXT, dirText);
    ObjectSetInteger(0, panelName + "_Direction", OBJPROP_COLOR, dirColor);
    
    // Orders count
    ObjectSetString(0, panelName + "_Orders", OBJPROP_TEXT, 
        "Açık: " + IntegerToString(CountOpenPositions()) + 
        " | Bekleyen: " + IntegerToString(CountPendingOrders()));
    
    // Daily profit
    color dailyColor = dailyProfit >= 0 ? clrLime : clrRed;
    ObjectSetString(0, panelName + "_Daily", OBJPROP_TEXT, 
        "Günlük: " + DoubleToString(dailyProfit, 2) + "%");
    ObjectSetInteger(0, panelName + "_Daily", OBJPROP_COLOR, dailyColor);
}

//+------------------------------------------------------------------+
//| Draw signal arrow on chart                                        |
//+------------------------------------------------------------------+
void DrawSignalArrow(ENUM_SIGNAL_TYPE signal)
{
    if(!InpShowSignals)
        return;
    
    string name = signalArrowPrefix + TimeToString(TimeCurrent(), TIME_DATE|TIME_MINUTES);
    datetime time = TimeCurrent();
    double price = signal == SIGNAL_BUY ? 
                   SymbolInfoDouble(_Symbol, SYMBOL_BID) : 
                   SymbolInfoDouble(_Symbol, SYMBOL_ASK);
    
    int arrowCode = signal == SIGNAL_BUY ? 233 : 234; // Arrow up/down
    color arrowColor = signal == SIGNAL_BUY ? clrLime : clrRed;
    
    ObjectCreate(0, name, OBJ_ARROW, 0, time, price);
    ObjectSetInteger(0, name, OBJPROP_ARROWCODE, arrowCode);
    ObjectSetInteger(0, name, OBJPROP_COLOR, arrowColor);
    ObjectSetInteger(0, name, OBJPROP_WIDTH, 3);
    ObjectSetInteger(0, name, OBJPROP_ANCHOR, signal == SIGNAL_BUY ? ANCHOR_TOP : ANCHOR_BOTTOM);
}

//+------------------------------------------------------------------+
//| Draw order lines on chart                                         |
//+------------------------------------------------------------------+
void DrawOrderLine(double entry, double sl, double tp, ENUM_SIGNAL_TYPE signal)
{
    string prefix = "Order_" + TimeToString(TimeCurrent(), TIME_DATE|TIME_MINUTES) + "_";
    datetime time = TimeCurrent();
    datetime futureTime = time + PeriodSeconds(PERIOD_CURRENT) * 20;
    
    color entryColor = signal == SIGNAL_BUY ? clrDodgerBlue : clrOrangeRed;
    
    // Entry line
    ObjectCreate(0, prefix + "Entry", OBJ_TREND, 0, time, entry, futureTime, entry);
    ObjectSetInteger(0, prefix + "Entry", OBJPROP_COLOR, entryColor);
    ObjectSetInteger(0, prefix + "Entry", OBJPROP_WIDTH, 2);
    ObjectSetInteger(0, prefix + "Entry", OBJPROP_STYLE, STYLE_SOLID);
    ObjectSetInteger(0, prefix + "Entry", OBJPROP_RAY_RIGHT, false);
    
    // SL line
    ObjectCreate(0, prefix + "SL", OBJ_TREND, 0, time, sl, futureTime, sl);
    ObjectSetInteger(0, prefix + "SL", OBJPROP_COLOR, clrRed);
    ObjectSetInteger(0, prefix + "SL", OBJPROP_WIDTH, 1);
    ObjectSetInteger(0, prefix + "SL", OBJPROP_STYLE, STYLE_DOT);
    ObjectSetInteger(0, prefix + "SL", OBJPROP_RAY_RIGHT, false);
    
    // TP line
    ObjectCreate(0, prefix + "TP", OBJ_TREND, 0, time, tp, futureTime, tp);
    ObjectSetInteger(0, prefix + "TP", OBJPROP_COLOR, clrLime);
    ObjectSetInteger(0, prefix + "TP", OBJPROP_WIDTH, 1);
    ObjectSetInteger(0, prefix + "TP", OBJPROP_STYLE, STYLE_DOT);
    ObjectSetInteger(0, prefix + "TP", OBJPROP_RAY_RIGHT, false);
    
    // Labels
    ObjectCreate(0, prefix + "SL_Label", OBJ_TEXT, 0, futureTime, sl);
    ObjectSetString(0, prefix + "SL_Label", OBJPROP_TEXT, "SL: " + DoubleToString(sl, (int)SymbolInfoInteger(_Symbol, SYMBOL_DIGITS)));
    ObjectSetInteger(0, prefix + "SL_Label", OBJPROP_COLOR, clrRed);
    ObjectSetInteger(0, prefix + "SL_Label", OBJPROP_FONTSIZE, 8);
    
    ObjectCreate(0, prefix + "TP_Label", OBJ_TEXT, 0, futureTime, tp);
    ObjectSetString(0, prefix + "TP_Label", OBJPROP_TEXT, "TP: " + DoubleToString(tp, (int)SymbolInfoInteger(_Symbol, SYMBOL_DIGITS)));
    ObjectSetInteger(0, prefix + "TP_Label", OBJPROP_COLOR, clrLime);
    ObjectSetInteger(0, prefix + "TP_Label", OBJPROP_FONTSIZE, 8);
}

//+------------------------------------------------------------------+
//| Draw pending order lines                                          |
//+------------------------------------------------------------------+
void DrawPendingOrderLine(double entry, double sl, double tp, ENUM_SIGNAL_TYPE signal)
{
    string prefix = "Pending_" + TimeToString(TimeCurrent(), TIME_DATE|TIME_MINUTES) + "_";
    datetime time = TimeCurrent();
    datetime futureTime = time + PeriodSeconds(PERIOD_CURRENT) * 20;
    
    color entryColor = signal == SIGNAL_BUY ? clrCyan : clrOrange;
    
    // Entry line (dashed for pending)
    ObjectCreate(0, prefix + "Entry", OBJ_TREND, 0, time, entry, futureTime, entry);
    ObjectSetInteger(0, prefix + "Entry", OBJPROP_COLOR, entryColor);
    ObjectSetInteger(0, prefix + "Entry", OBJPROP_WIDTH, 2);
    ObjectSetInteger(0, prefix + "Entry", OBJPROP_STYLE, STYLE_DASH);
    ObjectSetInteger(0, prefix + "Entry", OBJPROP_RAY_RIGHT, false);
    
    // Label
    string labelText = signal == SIGNAL_BUY ? "BEKLEYEN ALIŞ" : "BEKLEYEN SATIŞ";
    ObjectCreate(0, prefix + "Label", OBJ_TEXT, 0, time, entry);
    ObjectSetString(0, prefix + "Label", OBJPROP_TEXT, labelText + " @ " + DoubleToString(entry, (int)SymbolInfoInteger(_Symbol, SYMBOL_DIGITS)));
    ObjectSetInteger(0, prefix + "Label", OBJPROP_COLOR, entryColor);
    ObjectSetInteger(0, prefix + "Label", OBJPROP_FONTSIZE, 9);
}

//+------------------------------------------------------------------+
//| Draw target reached celebration                                   |
//+------------------------------------------------------------------+
void DrawTargetReached(double balance)
{
    string name = "TargetReached";
    
    // Big celebration text
    ObjectCreate(0, name + "_Title", OBJ_LABEL, 0, 0, 0);
    ObjectSetInteger(0, name + "_Title", OBJPROP_XDISTANCE, 100);
    ObjectSetInteger(0, name + "_Title", OBJPROP_YDISTANCE, 100);
    ObjectSetString(0, name + "_Title", OBJPROP_TEXT, "🏆🏆🏆 HEDEF ULAŞILDI! 🏆🏆🏆");
    ObjectSetInteger(0, name + "_Title", OBJPROP_COLOR, clrGold);
    ObjectSetInteger(0, name + "_Title", OBJPROP_FONTSIZE, 24);
    ObjectSetString(0, name + "_Title", OBJPROP_FONT, "Arial Black");
    
    ObjectCreate(0, name + "_Amount", OBJ_LABEL, 0, 0, 0);
    ObjectSetInteger(0, name + "_Amount", OBJPROP_XDISTANCE, 100);
    ObjectSetInteger(0, name + "_Amount", OBJPROP_YDISTANCE, 140);
    ObjectSetString(0, name + "_Amount", OBJPROP_TEXT, "$100 → $" + DoubleToString(balance, 2));
    ObjectSetInteger(0, name + "_Amount", OBJPROP_COLOR, clrLime);
    ObjectSetInteger(0, name + "_Amount", OBJPROP_FONTSIZE, 18);
    
    ObjectCreate(0, name + "_Congrats", OBJ_LABEL, 0, 0, 0);
    ObjectSetInteger(0, name + "_Congrats", OBJPROP_XDISTANCE, 100);
    ObjectSetInteger(0, name + "_Congrats", OBJPROP_YDISTANCE, 180);
    ObjectSetString(0, name + "_Congrats", OBJPROP_TEXT, "TEBRİKLER! $1,000,000 HEDEFİNE ULAŞTINIZ!");
    ObjectSetInteger(0, name + "_Congrats", OBJPROP_COLOR, clrWhite);
    ObjectSetInteger(0, name + "_Congrats", OBJPROP_FONTSIZE, 14);
}
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//|                    YENI MODÜLLER                                  |
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//| RSI Filter - Check if RSI allows trading                         |
//+------------------------------------------------------------------+
bool CheckRSIFilter(ENUM_SIGNAL_TYPE signal)
{
    if(!InpUseRSI)
        return true;
    
    if(CopyBuffer(handleRSI, 0, 0, 3, rsi) < 3)
        return true;
    
    double rsiValue = rsi[0];
    
    if(signal == SIGNAL_BUY)
    {
        // For BUY: RSI should not be overbought
        if(rsiValue > InpRSI_Overbought)
            return false;
        
        // RSI confirmation: RSI should be rising
        if(InpRSI_Confirmation && rsi[0] < rsi[1])
            return false;
    }
    else if(signal == SIGNAL_SELL)
    {
        // For SELL: RSI should not be oversold
        if(rsiValue < InpRSI_Oversold)
            return false;
        
        // RSI confirmation: RSI should be falling
        if(InpRSI_Confirmation && rsi[0] > rsi[1])
            return false;
    }
    
    return true;
}

//+------------------------------------------------------------------+
//| Volume Filter - Check if volume is sufficient                    |
//+------------------------------------------------------------------+
bool CheckVolumeFilter()
{
    if(!InpUseVolume)
        return true;
    
    // Get current volume
    long currentVolume = iVolume(_Symbol, PERIOD_CURRENT, 0);
    
    // Get average volume
    if(CopyBuffer(handleVolume, 0, 0, 1, volumeMA) < 1)
        return true;
    
    double avgVolume = volumeMA[0];
    
    // Volume should be higher than average * multiplier
    return currentVolume >= avgVolume * InpVolume_Multiplier;
}

//+------------------------------------------------------------------+
//| Session Filter - Check if current time is within trading hours   |
//+------------------------------------------------------------------+
bool CheckSessionFilter()
{
    if(!InpUseSession)
        return true;
    
    MqlDateTime dt;
    TimeCurrent(dt);
    
    int hour = dt.hour;
    int dayOfWeek = dt.day_of_week;
    
    // Weekend check (Saturday=6, Sunday=0)
    if(dayOfWeek == 0 || dayOfWeek == 6)
        return false;
    
    // Friday special handling
    if(dayOfWeek == 5)
    {
        if(!InpTradeFriday)
            return false;
        if(hour >= InpFridayCloseHour)
            return false;
    }
    
    // Regular session hours
    if(hour < InpSession_StartHour || hour >= InpSession_EndHour)
        return false;
    
    return true;
}

//+------------------------------------------------------------------+
//| News Filter - Check if there's upcoming news                     |
//+------------------------------------------------------------------+
bool CheckNewsFilter()
{
    if(!InpUseNews)
        return true;
    
    if(newsEventTime == 0)
        return true;
    
    datetime now = TimeCurrent();
    int minutesToNews = (int)((newsEventTime - now) / 60);
    int minutesAfterNews = (int)((now - newsEventTime) / 60);
    
    // Before news
    if(minutesToNews >= 0 && minutesToNews <= InpNewsMinutesBefore)
        return false;
    
    // After news
    if(minutesAfterNews >= 0 && minutesAfterNews <= InpNewsMinutesAfter)
        return false;
    
    return true;
}

//+------------------------------------------------------------------+
//| Multi-Timeframe Filter - Check higher TF trend                   |
//+------------------------------------------------------------------+
bool CheckMTFFilter(ENUM_SIGNAL_TYPE signal)
{
    if(!InpUseMTF || !InpMTF_TrendFilter)
        return true;
    
    if(CopyBuffer(handleMTF_MA1, 0, 0, 1, mtf_ma1) < 1)
        return true;
    if(CopyBuffer(handleMTF_MA5, 0, 0, 1, mtf_ma5) < 1)
        return true;
    
    bool htfUptrend = mtf_ma1[0] > mtf_ma5[0];
    
    if(signal == SIGNAL_BUY && !htfUptrend)
        return false;
    if(signal == SIGNAL_SELL && htfUptrend)
        return false;
    
    return true;
}

//+------------------------------------------------------------------+
//| Calculate Martingale Lot Size                                    |
//+------------------------------------------------------------------+
double CalculateMartingaleLot(double baseLot)
{
    if(!InpUseMartingale && !InpAntiMartingale)
        return baseLot;
    
    double lot = baseLot;
    
    if(InpUseMartingale)
    {
        // Classic Martingale: double after loss
        if(consecutiveLosses > 0 && martingaleLevel < InpMartingaleMaxLevel)
        {
            lot = baseLot * MathPow(InpMartingaleMultiplier, martingaleLevel);
        }
    }
    else if(InpAntiMartingale)
    {
        // Anti-Martingale: increase after win, reset after loss
        if(consecutiveWins > 0 && martingaleLevel < InpMartingaleMaxLevel)
        {
            lot = baseLot * MathPow(InpMartingaleMultiplier, martingaleLevel);
        }
    }
    
    // Normalize lot
    double minLot = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
    double maxLot = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MAX);
    double lotStep = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);
    
    lot = MathMax(minLot, MathMin(maxLot, lot));
    lot = MathMax(InpMinLot, MathMin(InpMaxLot, lot));
    lot = NormalizeDouble(MathFloor(lot / lotStep) * lotStep, 2);
    
    lastLotSize = lot;
    return lot;
}

//+------------------------------------------------------------------+
//| Update Martingale Level after trade close                        |
//+------------------------------------------------------------------+
void UpdateMartingaleLevel(bool isWin)
{
    if(!InpUseMartingale && !InpAntiMartingale)
        return;
    
    if(isWin)
    {
        winTrades++;
        consecutiveWins++;
        consecutiveLosses = 0;
        
        if(InpUseMartingale)
            martingaleLevel = 0; // Reset on win
        else if(InpAntiMartingale)
            martingaleLevel = MathMin(martingaleLevel + 1, InpMartingaleMaxLevel);
    }
    else
    {
        lossTrades++;
        consecutiveLosses++;
        consecutiveWins = 0;
        
        if(InpUseMartingale)
            martingaleLevel = MathMin(martingaleLevel + 1, InpMartingaleMaxLevel);
        else if(InpAntiMartingale)
            martingaleLevel = 0; // Reset on loss
    }
}

//+------------------------------------------------------------------+
//| Hedge Management - Open opposite position if needed              |
//+------------------------------------------------------------------+
void CheckHedgeManagement()
{
    if(!InpUseHedge)
        return;
    
    for(int i = PositionsTotal() - 1; i >= 0; i--)
    {
        if(!posInfo.SelectByIndex(i))
            continue;
        
        if(posInfo.Symbol() != _Symbol || posInfo.Magic() != InpMagicNumber)
            continue;
        
        double profit = posInfo.Profit();
        double lotSize = posInfo.Volume();
        double lossPercent = MathAbs(profit) / AccountInfoDouble(ACCOUNT_BALANCE) * 100;
        
        // Check if loss exceeds threshold
        if(profit < 0 && lossPercent >= InpHedgeLossPercent)
        {
            // Check if hedge position already exists
            bool hasHedge = false;
            ENUM_POSITION_TYPE posType = posInfo.PositionType();
            
            for(int j = PositionsTotal() - 1; j >= 0; j--)
            {
                CPositionInfo tempPos;
                if(tempPos.SelectByIndex(j))
                {
                    if(tempPos.Symbol() == _Symbol && 
                       tempPos.Magic() == InpMagicNumber &&
                       tempPos.PositionType() != posType &&
                       tempPos.Comment() == "HEDGE")
                    {
                        hasHedge = true;
                        break;
                    }
                }
            }
            
            if(!hasHedge)
            {
                // Open hedge position
                double hedgeLot = NormalizeDouble(lotSize * InpHedgeLotRatio, 2);
                hedgeLot = MathMax(SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN), hedgeLot);
                
                ENUM_ORDER_TYPE hedgeType = posType == POSITION_TYPE_BUY ? 
                                           ORDER_TYPE_SELL : ORDER_TYPE_BUY;
                double hedgePrice = hedgeType == ORDER_TYPE_BUY ?
                                   SymbolInfoDouble(_Symbol, SYMBOL_ASK) :
                                   SymbolInfoDouble(_Symbol, SYMBOL_BID);
                
                if(trade.PositionOpen(_Symbol, hedgeType, hedgeLot, hedgePrice, 0, 0, "HEDGE"))
                {
                    Print("🛡️ Hedge açıldı: ", EnumToString(hedgeType), " Lot: ", hedgeLot);
                }
            }
        }
    }
}

//+------------------------------------------------------------------+
//| Partial Close - Take partial profits                             |
//+------------------------------------------------------------------+
void CheckPartialClose()
{
    if(!InpUsePartialClose)
        return;
    
    double atrValue = atr[0];
    
    for(int i = PositionsTotal() - 1; i >= 0; i--)
    {
        if(!posInfo.SelectByIndex(i))
            continue;
        
        if(posInfo.Symbol() != _Symbol || posInfo.Magic() != InpMagicNumber)
            continue;
        
        ulong ticket = posInfo.Ticket();
        double openPrice = posInfo.PriceOpen();
        double currentPrice;
        double lotSize = posInfo.Volume();
        double profit;
        
        if(posInfo.PositionType() == POSITION_TYPE_BUY)
        {
            currentPrice = SymbolInfoDouble(_Symbol, SYMBOL_BID);
            profit = currentPrice - openPrice;
        }
        else
        {
            currentPrice = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
            profit = openPrice - currentPrice;
        }
        
        // First partial close at ATR * Mult1
        double partial1Target = atrValue * InpPartial1_ATRMult;
        if(profit >= partial1Target)
        {
            // Check if already done
            bool alreadyClosed = false;
            for(int j = ArraySize(lastPartialClose1) - 1; j >= 0; j--)
            {
                if(lastPartialClose1[j] == (datetime)ticket)
                {
                    alreadyClosed = true;
                    break;
                }
            }
            
            if(!alreadyClosed)
            {
                double closeVolume = NormalizeDouble(lotSize * InpPartial1_Percent / 100.0, 2);
                closeVolume = MathMax(SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN), closeVolume);
                
                if(trade.PositionClosePartial(ticket, closeVolume))
                {
                    ArrayResize(lastPartialClose1, ArraySize(lastPartialClose1) + 1);
                    lastPartialClose1[ArraySize(lastPartialClose1) - 1] = (datetime)ticket;
                    Print("💰 Kısmi kar alındı (1): Ticket ", ticket, " Volume: ", closeVolume);
                }
            }
        }
        
        // Second partial close at ATR * Mult2
        double partial2Target = atrValue * InpPartial2_ATRMult;
        if(profit >= partial2Target)
        {
            bool alreadyClosed = false;
            for(int j = ArraySize(lastPartialClose2) - 1; j >= 0; j--)
            {
                if(lastPartialClose2[j] == (datetime)ticket)
                {
                    alreadyClosed = true;
                    break;
                }
            }
            
            if(!alreadyClosed)
            {
                double closeVolume = NormalizeDouble(lotSize * InpPartial2_Percent / 100.0, 2);
                closeVolume = MathMax(SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN), closeVolume);
                
                if(trade.PositionClosePartial(ticket, closeVolume))
                {
                    ArrayResize(lastPartialClose2, ArraySize(lastPartialClose2) + 1);
                    lastPartialClose2[ArraySize(lastPartialClose2) - 1] = (datetime)ticket;
                    Print("💰 Kısmi kar alındı (2): Ticket ", ticket, " Volume: ", closeVolume);
                }
            }
        }
    }
}

//+------------------------------------------------------------------+
//| Apply All Filters to Signal                                      |
//+------------------------------------------------------------------+
bool ApplyAllFilters(ENUM_SIGNAL_TYPE signal)
{
    if(!CheckRSIFilter(signal))
    {
        Print("⚠️ RSI filtresi sinyali engelledi");
        return false;
    }
    
    if(!CheckVolumeFilter())
    {
        Print("⚠️ Volume filtresi sinyali engelledi");
        return false;
    }
    
    if(!CheckSessionFilter())
    {
        Print("⚠️ Session filtresi sinyali engelledi");
        return false;
    }
    
    if(!CheckNewsFilter())
    {
        Print("⚠️ News filtresi sinyali engelledi");
        return false;
    }
    
    if(!CheckMTFFilter(signal))
    {
        Print("⚠️ MTF filtresi sinyali engelledi");
        return false;
    }
    
    return true;
}
//+------------------------------------------------------------------+
