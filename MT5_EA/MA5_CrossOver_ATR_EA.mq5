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

input group "=== BOLLINGER BANDS ==="
input bool     InpUseBB            = true;         // Bollinger Bands Kullan
input int      InpBB_Period        = 20;           // BB Periyodu
input double   InpBB_Deviation     = 2.0;          // BB Standart Sapma
input bool     InpBB_Squeeze       = true;         // BB Sıkışma Filtresi

input group "=== MACD ==="
input bool     InpUseMACD          = true;         // MACD Kullan
input int      InpMACD_Fast        = 12;           // MACD Hızlı
input int      InpMACD_Slow        = 26;           // MACD Yavaş
input int      InpMACD_Signal      = 9;            // MACD Sinyal

input group "=== STOCHASTIC ==="
input bool     InpUseStoch         = true;         // Stochastic Kullan
input int      InpStoch_K          = 14;           // %K Periyodu
input int      InpStoch_D          = 3;            // %D Periyodu
input int      InpStoch_Slowing    = 3;            // Slowing
input int      InpStoch_Overbought = 80;           // Aşırı Alım
input int      InpStoch_Oversold   = 20;           // Aşırı Satım

input group "=== FIBONACCI ==="
input bool     InpUseFibo          = false;        // Fibonacci Kullan
input int      InpFibo_Lookback    = 50;           // Bakış Periyodu
input double   InpFibo_Level1      = 38.2;         // Fibo Seviye 1 (%)
input double   InpFibo_Level2      = 61.8;         // Fibo Seviye 2 (%)

input group "=== SUPPORT/RESISTANCE ==="
input bool     InpUseSR            = true;         // S/R Kullan
input int      InpSR_Lookback      = 100;          // S/R Bakış Periyodu
input int      InpSR_TouchCount    = 2;            // Min Dokunma Sayısı
input double   InpSR_Zone          = 0.0005;       // S/R Bölge Toleransı

input group "=== DRAWDOWN PROTECTION ==="
input bool     InpUseDD            = true;         // Drawdown Koruması Kullan
input double   InpMaxDD_Percent    = 10.0;         // Max Drawdown (%)
input double   InpDD_Recovery      = 50.0;         // Toparlanma Oranı (%)

input group "=== EQUITY CURVE TRADING ==="
input bool     InpUseEquity        = false;        // Equity Curve Filtresi
input int      InpEquity_MA        = 20;           // Equity MA Periyodu
input bool     InpEquity_AboveMA   = true;         // Sadece MA Üstünde İşlem

input group "=== TIME-BASED EXIT ==="
input bool     InpUseTimeExit      = true;         // Zaman Bazlı Çıkış
input int      InpMaxHoldHours     = 48;           // Max Pozisyon Süresi (saat)
input int      InpFridayExitHour   = 20;           // Cuma Çıkış Saati

input group "=== GRID TRADING ==="
input bool     InpUseGrid          = false;        // Grid Trading Kullan
input int      InpGrid_Levels      = 3;            // Grid Seviyeleri
input int      InpGrid_Distance    = 20;           // Grid Mesafesi (pips)
input double   InpGrid_LotMult     = 1.5;          // Grid Lot Çarpanı

input group "=== ADX TREND STRENGTH ==="
input bool     InpUseADX           = true;         // ADX Kullan
input int      InpADX_Period       = 14;           // ADX Periyodu
input int      InpADX_MinLevel     = 25;           // Min ADX Seviyesi
input bool     InpADX_DIFilter     = true;         // DI+/DI- Filtresi

input group "=== ICHIMOKU CLOUD ==="
input bool     InpUseIchimoku      = false;        // Ichimoku Kullan
input int      InpIchi_Tenkan      = 9;            // Tenkan-sen
input int      InpIchi_Kijun       = 26;           // Kijun-sen
input int      InpIchi_Senkou      = 52;           // Senkou Span B

input group "=== PARABOLIC SAR ==="
input bool     InpUseSAR           = true;         // Parabolic SAR Kullan
input double   InpSAR_Step         = 0.02;         // SAR Step
input double   InpSAR_Max          = 0.2;          // SAR Maximum

input group "=== CCI ==="
input bool     InpUseCCI           = true;         // CCI Kullan
input int      InpCCI_Period       = 20;           // CCI Periyodu
input int      InpCCI_Overbought   = 100;          // CCI Aşırı Alım
input int      InpCCI_Oversold     = -100;         // CCI Aşırı Satım

input group "=== WILLIAMS %R ==="
input bool     InpUseWilliams      = true;         // Williams %R Kullan
input int      InpWilliams_Period  = 14;           // Williams Periyodu
input int      InpWilliams_OB      = -20;          // Aşırı Alım
input int      InpWilliams_OS      = -80;          // Aşırı Satım

input group "=== MFI (Money Flow Index) ==="
input bool     InpUseMFI           = true;         // MFI Kullan
input int      InpMFI_Period       = 14;           // MFI Periyodu
input int      InpMFI_Overbought   = 80;           // MFI Aşırı Alım
input int      InpMFI_Oversold     = 20;           // MFI Aşırı Satım

input group "=== PIVOT POINTS ==="
input bool     InpUsePivot         = true;         // Pivot Points Kullan
input bool     InpPivot_Daily      = true;         // Günlük Pivot
input bool     InpPivot_Weekly     = false;        // Haftalık Pivot

input group "=== VOLATILITY BREAKOUT ==="
input bool     InpUseVolBreak      = true;         // Volatility Breakout Kullan
input double   InpVolBreak_Mult    = 1.5;          // ATR Çarpanı
input int      InpVolBreak_Period  = 5;            // Bakış Periyodu

input group "=== TRAILING TP ==="
input bool     InpUseTrailingTP    = true;         // Trailing TP Kullan
input double   InpTrailTP_ATRMult  = 0.5;          // TP Trailing ATR Çarpanı
input double   InpTrailTP_Step     = 0.3;          // TP Step (ATR)

input group "=== ACCOUNT PROTECTION ==="
input bool     InpUseAccProt       = true;         // Hesap Koruması Kullan
input double   InpMinBalance       = 50.0;         // Min Bakiye ($)
input double   InpMaxSpread        = 5.0;          // Max Spread (pips)
input bool     InpCheckMargin      = true;         // Marjin Kontrolü

input group "=== KELTNER CHANNEL ==="
input bool     InpUseKeltner       = true;         // Keltner Channel Kullan
input int      InpKeltner_Period   = 20;           // Keltner Periyodu
input double   InpKeltner_Mult     = 1.5;          // ATR Çarpanı

input group "=== DONCHIAN CHANNEL ==="
input bool     InpUseDonchian      = true;         // Donchian Channel Kullan
input int      InpDonchian_Period  = 20;           // Donchian Periyodu
input bool     InpDonchian_Break   = true;         // Breakout Modu

input group "=== AWESOME OSCILLATOR ==="
input bool     InpUseAO            = true;         // AO Kullan
input bool     InpAO_Saucer        = true;         // Saucer Pattern

input group "=== MOMENTUM ==="
input bool     InpUseMomentum      = true;         // Momentum Kullan
input int      InpMomentum_Period  = 14;           // Momentum Periyodu
input double   InpMomentum_Level   = 100.0;        // Nötr Seviye

input group "=== FORCE INDEX ==="
input bool     InpUseForce         = true;         // Force Index Kullan
input int      InpForce_Period     = 13;           // Force Periyodu

input group "=== OBV (On Balance Volume) ==="
input bool     InpUseOBV           = true;         // OBV Kullan
input int      InpOBV_MA           = 20;           // OBV MA Periyodu

input group "=== DIVERGENCE DETECTOR ==="
input bool     InpUseDivergence    = false;        // Divergence Kullan
input int      InpDiv_Lookback     = 14;           // Bakış Periyodu
input bool     InpDiv_RSI          = true;         // RSI Divergence
input bool     InpDiv_MACD         = true;         // MACD Divergence

input group "=== PATTERN RECOGNITION ==="
input bool     InpUsePattern       = true;         // Pattern Kullan
input bool     InpPattern_Engulf   = true;         // Engulfing
input bool     InpPattern_Doji     = true;         // Doji
input bool     InpPattern_Hammer   = true;         // Hammer/Shooting Star

input group "=== AUTO LOT CALCULATOR ==="
input bool     InpUseAutoLot       = true;         // Auto Lot Kullan
input double   InpAutoLot_Risk     = 2.0;          // Risk Yüzdesi
input double   InpAutoLot_Max      = 5.0;          // Max Lot

input group "=== TRADE JOURNAL ==="
input bool     InpUseJournal       = true;         // Journal Kullan
input bool     InpJournal_File     = true;         // Dosyaya Kaydet
input bool     InpJournal_Alert    = true;         // Trade Alert

input group "=== HEIKIN ASHI ==="
input bool     InpUseHeikin        = true;         // Heikin Ashi Kullan
input int      InpHeikin_Confirm   = 2;            // Onay Bar Sayısı

input group "=== RENKO FILTER ==="
input bool     InpUseRenko         = false;        // Renko Kullan
input int      InpRenko_BoxSize    = 10;           // Box Size (pips)
input int      InpRenko_Confirm    = 3;            // Onay Box Sayısı

input group "=== ZIGZAG ==="
input bool     InpUseZigZag        = true;         // ZigZag Kullan
input int      InpZZ_Depth         = 12;           // ZigZag Depth
input int      InpZZ_Deviation     = 5;            // ZigZag Deviation
input int      InpZZ_Backstep      = 3;            // ZigZag Backstep

input group "=== FRACTAL ==="
input bool     InpUseFractal       = true;         // Fractal Kullan
input int      InpFractal_Bars     = 3;            // Fractal Bar Sayısı

input group "=== ALLIGATOR ==="
input bool     InpUseAlligator     = true;         // Alligator Kullan
input int      InpAlli_Jaw         = 13;           // Jaw Periyodu
input int      InpAlli_Teeth       = 8;            // Teeth Periyodu
input int      InpAlli_Lips        = 5;            // Lips Periyodu

input group "=== GATOR OSCILLATOR ==="
input bool     InpUseGator         = false;        // Gator Kullan
input bool     InpGator_Awake      = true;         // Sadece Uyanık

input group "=== MARKET PROFILE ==="
input bool     InpUseProfile       = false;        // Market Profile Kullan
input int      InpProfile_Period   = 24;           // Bakış Periyodu (bar)
input double   InpProfile_VAPerc   = 70.0;         // Value Area (%)

input group "=== CORRELATION FILTER ==="
input bool     InpUseCorrelation   = false;        // Korelasyon Kullan
input string   InpCorr_Symbol      = "EURUSD";     // Korelasyon Sembolü
input int      InpCorr_Period      = 20;           // Korelasyon Periyodu
input double   InpCorr_Threshold   = 0.7;          // Min Korelasyon

input group "=== SEASONAL FILTER ==="
input bool     InpUseSeasonal      = false;        // Seasonal Kullan
input bool     InpSeasonal_Month   = true;         // Ay Bazlı
input string   InpSeasonal_Good    = "3,4,10,11";  // İyi Aylar

input group "=== ML SCORE ==="
input bool     InpUseML            = false;        // ML Score Kullan
input double   InpML_MinScore      = 0.6;          // Min Score (0-1)
input int      InpML_Features      = 10;           // Feature Sayısı

input group "=== VWAP ==="
input bool     InpUseVWAP          = true;         // VWAP Kullan
input bool     InpVWAP_Daily       = true;         // Günlük VWAP
input double   InpVWAP_Deviation   = 1.0;          // Standart Sapma Çarpanı

input group "=== SUPER TREND ==="
input bool     InpUseSuperTrend    = true;         // Super Trend Kullan
input int      InpST_Period        = 10;           // ATR Periyodu
input double   InpST_Multiplier    = 3.0;          // Çarpan

input group "=== CHAIKIN OSCILLATOR ==="
input bool     InpUseChaikin       = true;         // Chaikin Kullan
input int      InpChaikin_Fast     = 3;            // Hızlı Periyot
input int      InpChaikin_Slow     = 10;           // Yavaş Periyot

input group "=== ELDER RAY ==="
input bool     InpUseElderRay      = true;         // Elder Ray Kullan
input int      InpElder_Period     = 13;           // EMA Periyodu

input group "=== AROON ==="
input bool     InpUseAroon         = true;         // Aroon Kullan
input int      InpAroon_Period     = 25;           // Aroon Periyodu
input int      InpAroon_Level      = 70;           // Güçlü Trend Seviyesi

input group "=== CHANDELIER EXIT ==="
input bool     InpUseChandelier    = true;         // Chandelier Kullan
input int      InpChand_Period     = 22;           // ATR Periyodu
input double   InpChand_Mult       = 3.0;          // ATR Çarpanı

input group "=== HULL MA ==="
input bool     InpUseHullMA        = true;         // Hull MA Kullan
input int      InpHull_Period      = 20;           // Hull Periyodu

input group "=== SQUEEZE MOMENTUM ==="
input bool     InpUseSqueeze       = true;         // Squeeze Kullan
input int      InpSqueeze_BB       = 20;           // BB Periyodu
input int      InpSqueeze_KC       = 20;           // KC Periyodu
input double   InpSqueeze_BBMult   = 2.0;          // BB Çarpanı
input double   InpSqueeze_KCMult   = 1.5;          // KC Çarpanı

input group "=== RANGE FILTER ==="
input bool     InpUseRange         = true;         // Range Filter Kullan
input int      InpRange_Period     = 50;           // Bakış Periyodu
input double   InpRange_Mult       = 2.0;          // Range Çarpanı

input group "=== NEWS CALENDAR ==="
input bool     InpUseNewsAPI       = false;        // News API Kullan
input int      InpNews_Impact      = 2;            // Min Impact (1-3)
input int      InpNews_Before      = 60;           // Önce (dakika)
input int      InpNews_After       = 30;           // Sonra (dakika)

input group "=== TRIX ==="
input bool     InpUseTRIX          = true;         // TRIX Kullan
input int      InpTRIX_Period      = 18;           // TRIX Periyodu
input int      InpTRIX_Signal      = 9;            // Signal Periyodu

input group "=== DPO (Detrended Price) ==="
input bool     InpUseDPO           = true;         // DPO Kullan
input int      InpDPO_Period       = 20;           // DPO Periyodu

input group "=== KST (Know Sure Thing) ==="
input bool     InpUseKST           = true;         // KST Kullan
input int      InpKST_ROC1         = 10;           // ROC 1
input int      InpKST_ROC2         = 15;           // ROC 2
input int      InpKST_ROC3         = 20;           // ROC 3
input int      InpKST_ROC4         = 30;           // ROC 4

input group "=== COPPOCK CURVE ==="
input bool     InpUseCoppock       = false;        // Coppock Kullan
input int      InpCopp_WMA         = 10;           // WMA Periyodu
input int      InpCopp_Long        = 14;           // Long ROC
input int      InpCopp_Short       = 11;           // Short ROC

input group "=== MASS INDEX ==="
input bool     InpUseMass          = true;         // Mass Index Kullan
input int      InpMass_Period      = 25;           // Periyot
input double   InpMass_Bulge       = 27.0;         // Bulge Seviyesi

input group "=== VORTEX INDICATOR ==="
input bool     InpUseVortex        = true;         // Vortex Kullan
input int      InpVortex_Period    = 14;           // Periyot

input group "=== ULTIMATE OSCILLATOR ==="
input bool     InpUseUltimate      = true;         // Ultimate Kullan
input int      InpUlt_Period1      = 7;            // Periyot 1
input int      InpUlt_Period2      = 14;           // Periyot 2
input int      InpUlt_Period3      = 28;           // Periyot 3

input group "=== ACCUMULATION/DISTRIBUTION ==="
input bool     InpUseAD            = true;         // A/D Kullan
input int      InpAD_MA            = 20;           // A/D MA Periyodu

input group "=== RANDOM FOREST SCORE ==="
input bool     InpUseRF            = false;        // Random Forest Kullan
input int      InpRF_Trees         = 5;            // Ağaç Sayısı
input double   InpRF_MinScore      = 0.6;          // Min Score

input group "=== MONTE CARLO RISK ==="
input bool     InpUseMonteCarlo    = false;        // Monte Carlo Kullan
input int      InpMC_Simulations   = 100;          // Simülasyon Sayısı
input double   InpMC_Confidence    = 95.0;         // Güven Aralığı (%)

input group "=== SCHAFF TREND CYCLE ==="
input bool     InpUseSTC           = true;         // STC Kullan
input int      InpSTC_Period       = 10;           // STC Periyodu
input int      InpSTC_Fast         = 23;           // Fast Cycle
input int      InpSTC_Slow         = 50;           // Slow Cycle

input group "=== WOODIES CCI ==="
input bool     InpUseWoodies       = true;         // Woodies CCI Kullan
input int      InpWoodies_CCI      = 14;           // CCI Periyodu
input int      InpWoodies_TCCI     = 6;            // Turbo CCI

input group "=== CONNORS RSI ==="
input bool     InpUseConnors       = true;         // Connors RSI Kullan
input int      InpConnors_RSI      = 3;            // RSI Periyodu
input int      InpConnors_Streak   = 2;            // Streak Periyodu
input int      InpConnors_Rank     = 100;          // Rank Periyodu

input group "=== RVI (Relative Vigor) ==="
input bool     InpUseRVI           = true;         // RVI Kullan
input int      InpRVI_Period       = 10;           // RVI Periyodu

input group "=== SMI (Stochastic Momentum) ==="
input bool     InpUseSMI           = true;         // SMI Kullan
input int      InpSMI_K            = 13;           // %K Periyodu
input int      InpSMI_D            = 25;           // %D Periyodu
input int      InpSMI_Signal       = 2;            // Signal

input group "=== TMF (Trend Momentum Force) ==="
input bool     InpUseTMF           = true;         // TMF Kullan
input int      InpTMF_Period       = 21;           // TMF Periyodu

input group "=== McGINLEY DYNAMIC ==="
input bool     InpUseMcGinley      = true;         // McGinley Kullan
input int      InpMcG_Period       = 14;           // Periyot
input double   InpMcG_Constant     = 0.6;          // McGinley Constant

input group "=== ALMA (Arnaud Legoux) ==="
input bool     InpUseALMA          = true;         // ALMA Kullan
input int      InpALMA_Period      = 9;            // ALMA Periyodu
input double   InpALMA_Offset      = 0.85;         // Offset
input double   InpALMA_Sigma       = 6.0;          // Sigma

input group "=== KAUFMAN EFFICIENCY ==="
input bool     InpUseKaufman       = true;         // Kaufman Kullan
input int      InpKauf_Period      = 10;           // Periyot
input double   InpKauf_Threshold   = 0.5;          // Efficiency Threshold

input group "=== EHLERS FISHER TRANSFORM ==="
input bool     InpUseEhlers        = true;         // Ehlers Kullan
input int      InpEhlers_Period    = 10;           // Periyot

input group "=== CMO (Chande Momentum) ==="
input bool     InpUseCMO           = true;         // CMO Kullan
input int      InpCMO_Period       = 9;            // CMO Periyodu
input int      InpCMO_Overbought   = 50;           // Aşırı Alım
input int      InpCMO_Oversold     = -50;          // Aşırı Satım

input group "=== KVO (Klinger Volume) ==="
input bool     InpUseKVO           = true;         // KVO Kullan
input int      InpKVO_Fast         = 34;           // Fast EMA
input int      InpKVO_Slow         = 55;           // Slow EMA
input int      InpKVO_Signal       = 13;           // Signal

input group "=== TWIGGS MONEY FLOW ==="
input bool     InpUseTwiggs        = true;         // Twiggs Kullan
input int      InpTwiggs_Period    = 21;           // Periyot

input group "=== LINEAR REGRESSION CHANNEL ==="
input bool     InpUseLRC           = true;         // LRC Kullan
input int      InpLRC_Period       = 100;          // Periyot
input double   InpLRC_Deviation    = 2.0;          // Deviation

input group "=== STANDARD ERROR BANDS ==="
input bool     InpUseSEB           = true;         // SEB Kullan
input int      InpSEB_Period       = 21;           // Periyot
input double   InpSEB_Mult         = 2.0;          // Multiplier

input group "=== PERCENT B (%B) ==="
input bool     InpUsePercentB      = true;         // %B Kullan
input int      InpPercentB_Period  = 20;           // BB Periyodu
input double   InpPercentB_Dev     = 2.0;          // BB Deviation

input group "=== ELDER IMPULSE SYSTEM ==="
input bool     InpUseElderImpulse  = true;         // Elder Impulse Kullan
input int      InpElder_EMA        = 13;           // EMA Periyodu

input group "=== TTM TREND ==="
input bool     InpUseTTM           = true;         // TTM Trend Kullan
input int      InpTTM_Period       = 5;            // Periyot

input group "=== SQUEEZE PRO ==="
input bool     InpUseSqueezePro    = true;         // Squeeze Pro Kullan
input int      InpSqPro_BB         = 20;           // BB Periyodu
input double   InpSqPro_BBMult     = 2.0;          // BB Çarpanı
input double   InpSqPro_KC1        = 1.0;          // KC1 Çarpanı
input double   InpSqPro_KC2        = 1.5;          // KC2 Çarpanı
input double   InpSqPro_KC3        = 2.0;          // KC3 Çarpanı

input group "=== NEURAL NETWORK SCORE ==="
input bool     InpUseNeural        = false;        // Neural Net Kullan
input int      InpNN_Layers        = 3;            // Hidden Layers
input int      InpNN_Neurons       = 10;           // Neurons per Layer
input double   InpNN_MinScore      = 0.7;          // Min Score

input group "=== DEMA (Double EMA) ==="
input bool     InpUseDEMA          = true;         // DEMA Kullan
input int      InpDEMA_Period      = 21;           // DEMA Periyodu

input group "=== TEMA (Triple EMA) ==="
input bool     InpUseTEMA          = true;         // TEMA Kullan
input int      InpTEMA_Period      = 21;           // TEMA Periyodu

input group "=== T3 MOVING AVERAGE ==="
input bool     InpUseT3            = true;         // T3 Kullan
input int      InpT3_Period        = 5;            // T3 Periyodu
input double   InpT3_VFactor       = 0.7;          // Volume Factor

input group "=== FRAMA (Fractal Adaptive) ==="
input bool     InpUseFRAMA         = true;         // FRAMA Kullan
input int      InpFRAMA_Period     = 16;           // FRAMA Periyodu

input group "=== VIDYA (Variable Index) ==="
input bool     InpUseVIDYA         = true;         // VIDYA Kullan
input int      InpVIDYA_CMO        = 9;            // CMO Periyodu
input int      InpVIDYA_MA         = 12;           // MA Periyodu

input group "=== ZERO LAG EMA ==="
input bool     InpUseZeroLag       = true;         // Zero Lag Kullan
input int      InpZL_Period        = 21;           // Periyot

input group "=== SMOOTHED RSI ==="
input bool     InpUseSmoothRSI     = true;         // Smooth RSI Kullan
input int      InpSRSI_Period      = 14;           // RSI Periyodu
input int      InpSRSI_Smooth      = 3;            // Smoothing

input group "=== STOCHASTIC RSI ==="
input bool     InpUseStochRSI      = true;         // StochRSI Kullan
input int      InpStRSI_Period     = 14;           // RSI Periyodu
input int      InpStRSI_K          = 3;            // %K
input int      InpStRSI_D          = 3;            // %D

input group "=== ADR (Average Directional Rating) ==="
input bool     InpUseADR           = true;         // ADR Kullan
input int      InpADR_Period       = 14;           // Periyot

input group "=== TRADE OPTIMIZATION ==="
input bool     InpUseTradeOpt      = false;        // Trade Opt Kullan
input int      InpOpt_Lookback     = 500;          // Backtest Bars
input double   InpOpt_MinWinRate   = 0.55;         // Min Win Rate

input group "=== ENVELOPES ==="
input bool     InpUseEnvelopes     = true;         // Envelopes Kullan
input int      InpEnv_Period       = 20;           // MA Periyodu
input double   InpEnv_Deviation    = 0.1;          // Deviation (%)

input group "=== PRICE CHANNEL ==="
input bool     InpUsePriceChannel  = true;         // Price Channel Kullan
input int      InpPC_Period        = 20;           // Periyot

input group "=== AO DIVERGENCE ==="
input bool     InpUseAODiv         = true;         // AO Divergence Kullan
input int      InpAODiv_Bars       = 20;           // Lookback Bars

input group "=== WILLIAMS DIVERGENCE ==="
input bool     InpUseWillDiv       = true;         // Williams Div Kullan
input int      InpWillDiv_Bars     = 20;           // Lookback Bars

input group "=== CSI (Commodity Selection) ==="
input bool     InpUseCSI           = false;        // CSI Kullan
input int      InpCSI_Period       = 14;           // Periyot
input double   InpCSI_Min          = 50.0;         // Min CSI

input group "=== TRADE STATISTICS ==="
input bool     InpUseTradeStats    = true;         // Trade Stats Kullan
input int      InpStats_MinTrades  = 10;           // Min İşlem Sayısı
input double   InpStats_MinWin     = 0.50;         // Min Win Rate

input group "=== EQUITY GUARD ==="
input bool     InpUseEquityGuard   = true;         // Equity Guard Kullan
input double   InpEG_MaxDD         = 10.0;         // Max Drawdown (%)
input double   InpEG_DailyMax      = 5.0;          // Günlük Max DD (%)

input group "=== SMART EXIT ==="
input bool     InpUseSmartExit     = true;         // Smart Exit Kullan
input double   InpSE_TrailATR      = 2.0;          // Trailing ATR Multiple
input double   InpSE_BreakEven     = 1.0;          // BreakEven ATR

input group "=== TSI (True Strength Index) ==="
input bool     InpUseTSI           = true;         // TSI Kullan
input int      InpTSI_Long         = 25;           // Long Periyot
input int      InpTSI_Short        = 13;           // Short Periyot
input int      InpTSI_Signal       = 7;            // Signal

input group "=== FINAL OPTIMIZER ==="
input bool     InpUseFinalOpt      = false;        // Final Opt Kullan
input int      InpFO_Period        = 1000;         // Optimization Period
input bool     InpFO_AutoAdjust    = true;         // Oto Ayarlama

input group "=== KAMA (Kaufman AMA) ==="
input bool     InpUseKAMA          = true;         // KAMA Kullan
input int      InpKAMA_Period      = 10;           // Periyot
input int      InpKAMA_Fast        = 2;            // Fast SC
input int      InpKAMA_Slow        = 30;           // Slow SC

input group "=== RMI (Relative Momentum) ==="
input bool     InpUseRMI           = true;         // RMI Kullan
input int      InpRMI_Period       = 14;           // Periyot
input int      InpRMI_Momentum     = 4;            // Momentum

input group "=== SMI ERGODIC ==="
input bool     InpUseSMIErg        = true;         // SMI Ergodic Kullan
input int      InpSMIErg_R         = 5;            // R Periyot
input int      InpSMIErg_S         = 20;           // S Periyot
input int      InpSMIErg_U         = 5;            // U Periyot

input group "=== CHOPPINESS INDEX ==="
input bool     InpUseChop          = true;         // Choppiness Kullan
input int      InpChop_Period      = 14;           // Periyot
input double   InpChop_High        = 61.8;         // Range Threshold
input double   InpChop_Low         = 38.2;         // Trend Threshold

input group "=== QQE (Quantitative Qualitative) ==="
input bool     InpUseQQE           = true;         // QQE Kullan
input int      InpQQE_RSI          = 14;           // RSI Periyot
input double   InpQQE_SF           = 5.0;          // Smoothing Factor

input group "=== SSL CHANNEL ==="
input bool     InpUseSSL           = true;         // SSL Kullan
input int      InpSSL_Period       = 10;           // Periyot

input group "=== HALF TREND ==="
input bool     InpUseHalfTrend     = true;         // HalfTrend Kullan
input int      InpHT_Amplitude     = 2;            // Amplitude
input int      InpHT_Channel       = 0;            // Channel Deviation

input group "=== WADDAH ATTAR ==="
input bool     InpUseWaddah        = true;         // Waddah Kullan
input int      InpWaddah_Fast      = 20;           // Fast MA
input int      InpWaddah_Slow      = 40;           // Slow MA
input double   InpWaddah_Sens      = 150.0;        // Sensitivity

input group "=== RISK/REWARD CALCULATOR ==="
input bool     InpUseRR            = true;         // R/R Kullan
input double   InpRR_MinRatio      = 1.5;          // Min R/R Ratio

input group "=== ULTIMATE TRADING SCORE ==="
input bool     InpUseUltScore      = false;        // Ultimate Score Kullan
input double   InpUS_MinScore      = 70.0;         // Min Score (0-100)


// New module handles
int handleRSI;
int handleVolume;
int handleMTF_MA1, handleMTF_MA5;

// NEW 10 MODULE HANDLES
int handleBB;
int handleMACD;
int handleStoch;

// NEW v3 HANDLES
int handleADX;
int handleIchimoku;
int handleSAR;
int handleCCI;
int handleWilliams;
int handleMFI;

// MA Values
double ma1[], ma2[], ma3[], ma4[], ma5[];
double atr[];

// New module values
double rsi[];
double volume[], volumeMA[];
double mtf_ma1[], mtf_ma5[];

// NEW 10 MODULE VALUES
double bbUpper[], bbMiddle[], bbLower[];
double macdMain[], macdSignal[], macdHist[];
double stochK[], stochD[];
double fiboHigh = 0, fiboLow = 0;
double supportLevel = 0, resistanceLevel = 0;
double equityHistory[];
int gridLevel = 0;

// NEW v3 VALUES
double adxValue[], diPlus[], diMinus[];
double ichiTenkan[], ichiKijun[], ichiSpanA[], ichiSpanB[];
double sarValue[];
double cciValue[];
double williamsValue[];
double mfiValue[];
double pivotP = 0, pivotR1 = 0, pivotR2 = 0, pivotS1 = 0, pivotS2 = 0;

// NEW v4 HANDLES
int handleAO;
int handleMomentum;
int handleForce;
int handleOBV;

// NEW v4 VALUES
double aoValue[];
double momentumValue[];
double forceValue[];
double obvValue[], obvMA[];
double keltnerUpper[], keltnerLower[], keltnerMiddle[];
double donchianHigh = 0, donchianLow = 0;

// Trade Journal
int journalFileHandle = INVALID_HANDLE;
int totalJournalEntries = 0;

// NEW v5 HANDLES
int handleZigZag;
int handleFractal;
int handleAlligator;
int handleGator;

// NEW v5 VALUES
double zigzagValue[];
double fractalUp[], fractalDown[];
double alliJaw[], alliTeeth[], alliLips[];
double gatorUp[], gatorDown[];
double heikinOpen[], heikinClose[], heikinHigh[], heikinLow[];
double mlScore = 0;
double profilePOC = 0, profileVAH = 0, profileVAL = 0;

// NEW v6 HANDLES
int handleChaikin;
int handleBullPower;
int handleBearPower;

// NEW v6 VALUES
double vwapValue = 0, vwapUpper = 0, vwapLower = 0;
double superTrendValue = 0;
bool superTrendUp = true;
double chaikinValue[];
double bullPower[], bearPower[];
double aroonUp[], aroonDown[];
double chandelierLong = 0, chandelierShort = 0;
double hullMA = 0, hullMAPrev = 0;
bool squeezeOn = false;
double rangeFilter = 0, rangeFilterPrev = 0;

// NEW v7 HANDLES
int handleTRIX;
int handleAD;

// NEW v7 VALUES
double trixValue[], trixSignal[];
double dpoValue = 0;
double kstValue = 0, kstSignal = 0;
double coppockValue = 0;
double massIndex = 0;
double viPlus[], viMinus[];
double ultimateOsc = 0;
double adValue[], adMA[];
double rfScore = 0;
double mcVaR = 0, mcExpectedReturn = 0;

// NEW v8 HANDLES
int handleRVI;

// NEW v8 VALUES
double stcValue = 0;
double woodiesCCI = 0, woodiesTCCI = 0;
double connorsRSI = 0;
double rviValue[], rviSignal[];
double smiValue = 0;
double tmfValue = 0;
double mcGinleyValue = 0, mcGinleyPrev = 0;
double almaValue = 0;
double kaufmanER = 0;
double fisherValue = 0, fisherPrev = 0;

// NEW v9 VALUES
double cmoValue = 0;
double kvoValue = 0, kvoSignal = 0;
double twiggsValue = 0;
double lrcMiddle = 0, lrcUpper = 0, lrcLower = 0;
double sebMiddle = 0, sebUpper = 0, sebLower = 0;
double percentB = 0;
int elderImpulse = 0; // 1=Green, -1=Red, 0=Blue
bool ttmTrend = true;
int squeezeProLevel = 0; // 0=No squeeze, 1-3=Squeeze levels
double nnScore = 0;

// Statistics
double dailyProfit = 0;
double dailyStartBalance = 0;
datetime lastDayCheck = 0;
int totalTrades = 0;
int winTrades = 0;
int lossTrades = 0;

// NEW v10 VALUES
double demaValue = 0, demaPrev = 0;
double temaValue = 0, temaPrev = 0;
double t3Value = 0, t3Prev = 0;
double framaValue = 0, framaPrev = 0;
double vidyaValue = 0, vidyaPrev = 0;
double zeroLagValue = 0, zeroLagPrev = 0;
double smoothRSI = 0;
double stochRSIK = 0, stochRSID = 0;
double adrValue = 0;
double optWinRate = 0;

// NEW v11 VALUES - FINAL 10
double envUpper = 0, envLower = 0, envMiddle = 0;
double pcHigh = 0, pcLow = 0;
bool aoDiv = false, willDiv = false;
double csiValue = 0;
int statsWins = 0, statsLosses = 0;
double egDailyDD = 0;
double tsiValue = 0, tsiSignal = 0;
double finalOptScore = 0;

// NEW v12 VALUES - SUPER 10
double kamaValue = 0, kamaPrev = 0;
double rmiValue = 0;
double smiErgValue = 0, smiErgSignal = 0;
double chopIndex = 0;
double qqeValue = 0, qqeLine = 0;
double sslUp = 0, sslDown = 0;
bool htTrend = true;
double waddahValue = 0, waddahExp = 0;
double rrRatio = 0;
double ultScore = 0;

// Drawdown tracking
double peakBalance = 0;
double currentDrawdown = 0;
bool ddRecoveryMode = false;

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
//|              YENI 10 MODÜL FONKSIYONLARI                         |
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//| Bollinger Bands Filter                                           |
//+------------------------------------------------------------------+
bool CheckBBFilter(ENUM_SIGNAL_TYPE signal)
{
    if(!InpUseBB)
        return true;
    
    if(CopyBuffer(handleBB, 0, 0, 3, bbMiddle) < 3) return true;
    if(CopyBuffer(handleBB, 1, 0, 3, bbUpper) < 3) return true;
    if(CopyBuffer(handleBB, 2, 0, 3, bbLower) < 3) return true;
    
    double close = iClose(_Symbol, PERIOD_CURRENT, 0);
    double bbWidth = (bbUpper[0] - bbLower[0]) / bbMiddle[0];
    double avgWidth = (bbUpper[1] - bbLower[1]) / bbMiddle[1];
    
    // Squeeze detection (bands narrowing)
    if(InpBB_Squeeze && bbWidth < avgWidth * 0.8)
    {
        return false; // Wait for expansion
    }
    
    if(signal == SIGNAL_BUY)
    {
        // Price near lower band for buy
        if(close > bbUpper[0])
            return false;
    }
    else if(signal == SIGNAL_SELL)
    {
        // Price near upper band for sell
        if(close < bbLower[0])
            return false;
    }
    
    return true;
}

//+------------------------------------------------------------------+
//| MACD Filter                                                      |
//+------------------------------------------------------------------+
bool CheckMACDFilter(ENUM_SIGNAL_TYPE signal)
{
    if(!InpUseMACD)
        return true;
    
    if(CopyBuffer(handleMACD, 0, 0, 3, macdMain) < 3) return true;
    if(CopyBuffer(handleMACD, 1, 0, 3, macdSignal) < 3) return true;
    
    double hist0 = macdMain[0] - macdSignal[0];
    double hist1 = macdMain[1] - macdSignal[1];
    
    if(signal == SIGNAL_BUY)
    {
        // MACD should be bullish (histogram positive or rising)
        if(hist0 < 0 && hist0 < hist1)
            return false;
    }
    else if(signal == SIGNAL_SELL)
    {
        // MACD should be bearish
        if(hist0 > 0 && hist0 > hist1)
            return false;
    }
    
    return true;
}

//+------------------------------------------------------------------+
//| Stochastic Filter                                                |
//+------------------------------------------------------------------+
bool CheckStochFilter(ENUM_SIGNAL_TYPE signal)
{
    if(!InpUseStoch)
        return true;
    
    if(CopyBuffer(handleStoch, 0, 0, 3, stochK) < 3) return true;
    if(CopyBuffer(handleStoch, 1, 0, 3, stochD) < 3) return true;
    
    if(signal == SIGNAL_BUY)
    {
        // For buy: Stoch should not be overbought
        if(stochK[0] > InpStoch_Overbought)
            return false;
        // K crossing above D is bullish
        if(stochK[0] < stochD[0] && stochK[1] > stochD[1])
            return false;
    }
    else if(signal == SIGNAL_SELL)
    {
        // For sell: Stoch should not be oversold
        if(stochK[0] < InpStoch_Oversold)
            return false;
        // K crossing below D is bearish
        if(stochK[0] > stochD[0] && stochK[1] < stochD[1])
            return false;
    }
    
    return true;
}

//+------------------------------------------------------------------+
//| Calculate Fibonacci Levels                                       |
//+------------------------------------------------------------------+
void CalculateFiboLevels()
{
    if(!InpUseFibo)
        return;
    
    double highest = 0, lowest = 999999;
    
    for(int i = 0; i < InpFibo_Lookback; i++)
    {
        double high = iHigh(_Symbol, PERIOD_CURRENT, i);
        double low = iLow(_Symbol, PERIOD_CURRENT, i);
        
        if(high > highest) highest = high;
        if(low < lowest) lowest = low;
    }
    
    fiboHigh = highest;
    fiboLow = lowest;
}

bool CheckFiboFilter(ENUM_SIGNAL_TYPE signal)
{
    if(!InpUseFibo)
        return true;
    
    CalculateFiboLevels();
    
    double range = fiboHigh - fiboLow;
    double level1 = fiboLow + range * (InpFibo_Level1 / 100.0);
    double level2 = fiboLow + range * (InpFibo_Level2 / 100.0);
    double close = iClose(_Symbol, PERIOD_CURRENT, 0);
    
    if(signal == SIGNAL_BUY)
    {
        // Buy near Fibo support levels
        if(close > level2)
            return false;
    }
    else if(signal == SIGNAL_SELL)
    {
        // Sell near Fibo resistance levels
        if(close < level1)
            return false;
    }
    
    return true;
}

//+------------------------------------------------------------------+
//| Calculate Support/Resistance Levels                              |
//+------------------------------------------------------------------+
void CalculateSRLevels()
{
    if(!InpUseSR)
        return;
    
    double prices[];
    ArrayResize(prices, InpSR_Lookback);
    
    for(int i = 0; i < InpSR_Lookback; i++)
    {
        prices[i] = iClose(_Symbol, PERIOD_CURRENT, i);
    }
    
    double close = iClose(_Symbol, PERIOD_CURRENT, 0);
    supportLevel = 0;
    resistanceLevel = 999999;
    
    // Find nearest support and resistance
    for(int i = 0; i < InpSR_Lookback; i++)
    {
        double level = prices[i];
        int touches = 0;
        
        for(int j = 0; j < InpSR_Lookback; j++)
        {
            if(MathAbs(prices[j] - level) <= InpSR_Zone)
                touches++;
        }
        
        if(touches >= InpSR_TouchCount)
        {
            if(level < close && level > supportLevel)
                supportLevel = level;
            if(level > close && level < resistanceLevel)
                resistanceLevel = level;
        }
    }
}

bool CheckSRFilter(ENUM_SIGNAL_TYPE signal)
{
    if(!InpUseSR)
        return true;
    
    CalculateSRLevels();
    
    double close = iClose(_Symbol, PERIOD_CURRENT, 0);
    
    if(signal == SIGNAL_BUY)
    {
        // Don't buy too close to resistance
        if(resistanceLevel > 0 && MathAbs(close - resistanceLevel) < atr[0])
            return false;
    }
    else if(signal == SIGNAL_SELL)
    {
        // Don't sell too close to support
        if(supportLevel > 0 && MathAbs(close - supportLevel) < atr[0])
            return false;
    }
    
    return true;
}

//+------------------------------------------------------------------+
//| Drawdown Protection                                              |
//+------------------------------------------------------------------+
bool CheckDrawdownProtection()
{
    if(!InpUseDD)
        return true;
    
    double balance = AccountInfoDouble(ACCOUNT_BALANCE);
    
    // Update peak balance
    if(balance > peakBalance)
    {
        peakBalance = balance;
        ddRecoveryMode = false;
    }
    
    // Calculate current drawdown
    if(peakBalance > 0)
        currentDrawdown = ((peakBalance - balance) / peakBalance) * 100;
    
    // Check if max DD exceeded
    if(currentDrawdown >= InpMaxDD_Percent)
    {
        ddRecoveryMode = true;
        Print("⛔ Max Drawdown aşıldı: ", DoubleToString(currentDrawdown, 2), "%");
        return false;
    }
    
    // Recovery mode: wait until recovered
    if(ddRecoveryMode)
    {
        double recovery = ((peakBalance - balance) / peakBalance) * 100;
        if(recovery > InpMaxDD_Percent * (1 - InpDD_Recovery / 100))
        {
            return false;
        }
        ddRecoveryMode = false;
    }
    
    return true;
}

//+------------------------------------------------------------------+
//| Equity Curve Trading                                             |
//+------------------------------------------------------------------+
bool CheckEquityCurveFilter()
{
    if(!InpUseEquity)
        return true;
    
    double equity = AccountInfoDouble(ACCOUNT_EQUITY);
    
    // Add to history
    int size = ArraySize(equityHistory);
    if(size >= InpEquity_MA)
    {
        for(int i = 0; i < size - 1; i++)
            equityHistory[i] = equityHistory[i + 1];
        equityHistory[size - 1] = equity;
    }
    else
    {
        ArrayResize(equityHistory, size + 1);
        equityHistory[size] = equity;
    }
    
    // Calculate equity MA
    if(ArraySize(equityHistory) < InpEquity_MA)
        return true;
    
    double sum = 0;
    for(int i = 0; i < InpEquity_MA; i++)
        sum += equityHistory[ArraySize(equityHistory) - 1 - i];
    double equityMA = sum / InpEquity_MA;
    
    // Only trade if equity is above MA (winning streak)
    if(InpEquity_AboveMA && equity < equityMA)
    {
        Print("⚠️ Equity MA altında, işlem engellendi");
        return false;
    }
    
    return true;
}

//+------------------------------------------------------------------+
//| Time-Based Exit Management                                       |
//+------------------------------------------------------------------+
void CheckTimeBasedExit()
{
    if(!InpUseTimeExit)
        return;
    
    MqlDateTime dt;
    TimeCurrent(dt);
    
    for(int i = PositionsTotal() - 1; i >= 0; i--)
    {
        if(!posInfo.SelectByIndex(i))
            continue;
        
        if(posInfo.Symbol() != _Symbol || posInfo.Magic() != InpMagicNumber)
            continue;
        
        datetime openTime = posInfo.Time();
        int hoursHeld = (int)((TimeCurrent() - openTime) / 3600);
        
        // Max hold time exit
        if(hoursHeld >= InpMaxHoldHours)
        {
            trade.PositionClose(posInfo.Ticket());
            Print("⏰ Zaman aşımı kapatma: ", posInfo.Ticket(), " (", hoursHeld, " saat)");
            continue;
        }
        
        // Friday exit
        if(dt.day_of_week == 5 && dt.hour >= InpFridayExitHour)
        {
            trade.PositionClose(posInfo.Ticket());
            Print("📅 Cuma kapatma: ", posInfo.Ticket());
        }
    }
}

//+------------------------------------------------------------------+
//| Grid Trading Management                                          |
//+------------------------------------------------------------------+
void CheckGridTrading(ENUM_SIGNAL_TYPE signal)
{
    if(!InpUseGrid)
        return;
    
    if(CountOpenPositions() == 0)
    {
        gridLevel = 0;
        return;
    }
    
    if(gridLevel >= InpGrid_Levels)
        return;
    
    // Check if we need to add grid position
    double lastPrice = 0;
    ENUM_POSITION_TYPE lastType = POSITION_TYPE_BUY;
    
    for(int i = PositionsTotal() - 1; i >= 0; i--)
    {
        if(!posInfo.SelectByIndex(i))
            continue;
        
        if(posInfo.Symbol() != _Symbol || posInfo.Magic() != InpMagicNumber)
            continue;
        
        if(posInfo.Time() > (datetime)lastPrice)
        {
            lastPrice = posInfo.PriceOpen();
            lastType = posInfo.PositionType();
        }
    }
    
    double currentPrice = SymbolInfoDouble(_Symbol, SYMBOL_BID);
    double point = SymbolInfoDouble(_Symbol, SYMBOL_POINT);
    double gridDistance = InpGrid_Distance * point * 10;
    
    // Check if price moved grid distance against us
    bool addGrid = false;
    if(lastType == POSITION_TYPE_BUY && currentPrice <= lastPrice - gridDistance)
        addGrid = true;
    if(lastType == POSITION_TYPE_SELL && currentPrice >= lastPrice + gridDistance)
        addGrid = true;
    
    if(addGrid)
    {
        double baseLot = CalculateLotSize();
        double gridLot = baseLot * MathPow(InpGrid_LotMult, gridLevel);
        
        double sl, tp;
        ENUM_SIGNAL_TYPE gridSignal = lastType == POSITION_TYPE_BUY ? SIGNAL_BUY : SIGNAL_SELL;
        CalculateSL_TP(gridSignal, sl, tp);
        
        if(PlaceMarketOrder(gridSignal, gridLot, sl, tp))
        {
            gridLevel++;
            Print("📊 Grid pozisyon eklendi: Level ", gridLevel);
        }
    }
}

//+------------------------------------------------------------------+
//| Initialize New Indicators in OnInit                              |
//+------------------------------------------------------------------+
void InitNewIndicators()
{
    ENUM_MA_METHOD maMethod = (ENUM_MA_METHOD)InpMA_Method;
    
    if(InpUseBB)
        handleBB = iBands(_Symbol, PERIOD_CURRENT, InpBB_Period, 0, InpBB_Deviation, PRICE_CLOSE);
    
    if(InpUseMACD)
        handleMACD = iMACD(_Symbol, PERIOD_CURRENT, InpMACD_Fast, InpMACD_Slow, InpMACD_Signal, PRICE_CLOSE);
    
    if(InpUseStoch)
        handleStoch = iStochastic(_Symbol, PERIOD_CURRENT, InpStoch_K, InpStoch_D, InpStoch_Slowing, MODE_SMA, STO_LOWHIGH);
    
    // Set arrays as series
    ArraySetAsSeries(bbUpper, true);
    ArraySetAsSeries(bbMiddle, true);
    ArraySetAsSeries(bbLower, true);
    ArraySetAsSeries(macdMain, true);
    ArraySetAsSeries(macdSignal, true);
    ArraySetAsSeries(stochK, true);
    ArraySetAsSeries(stochD, true);
    
    peakBalance = AccountInfoDouble(ACCOUNT_BALANCE);
}

//+------------------------------------------------------------------+
//| Apply All 10 New Filters                                         |
//+------------------------------------------------------------------+
bool ApplyNew10Filters(ENUM_SIGNAL_TYPE signal)
{
    if(!CheckBBFilter(signal))
        return false;
    
    if(!CheckMACDFilter(signal))
        return false;
    
    if(!CheckStochFilter(signal))
        return false;
    
    if(!CheckFiboFilter(signal))
        return false;
    
    if(!CheckSRFilter(signal))
        return false;
    
    if(!CheckDrawdownProtection())
        return false;
    
    if(!CheckEquityCurveFilter())
        return false;
    
    return true;
}

//+------------------------------------------------------------------+
//|              YENI v3 MODÜL FONKSIYONLARI (10 MODUL)              |
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//| ADX Trend Strength Filter                                        |
//+------------------------------------------------------------------+
bool CheckADXFilter(ENUM_SIGNAL_TYPE signal)
{
    if(!InpUseADX)
        return true;
    
    if(CopyBuffer(handleADX, 0, 0, 3, adxValue) < 3) return true;
    if(CopyBuffer(handleADX, 1, 0, 3, diPlus) < 3) return true;
    if(CopyBuffer(handleADX, 2, 0, 3, diMinus) < 3) return true;
    
    // ADX must be above minimum level (trending market)
    if(adxValue[0] < InpADX_MinLevel)
        return false;
    
    // DI filter
    if(InpADX_DIFilter)
    {
        if(signal == SIGNAL_BUY && diPlus[0] < diMinus[0])
            return false;
        if(signal == SIGNAL_SELL && diMinus[0] < diPlus[0])
            return false;
    }
    
    return true;
}

//+------------------------------------------------------------------+
//| Ichimoku Cloud Filter                                            |
//+------------------------------------------------------------------+
bool CheckIchimokuFilter(ENUM_SIGNAL_TYPE signal)
{
    if(!InpUseIchimoku)
        return true;
    
    if(CopyBuffer(handleIchimoku, 0, 0, 3, ichiTenkan) < 3) return true;
    if(CopyBuffer(handleIchimoku, 1, 0, 3, ichiKijun) < 3) return true;
    if(CopyBuffer(handleIchimoku, 2, 0, 3, ichiSpanA) < 3) return true;
    if(CopyBuffer(handleIchimoku, 3, 0, 3, ichiSpanB) < 3) return true;
    
    double close = iClose(_Symbol, PERIOD_CURRENT, 0);
    double cloudTop = MathMax(ichiSpanA[0], ichiSpanB[0]);
    double cloudBottom = MathMin(ichiSpanA[0], ichiSpanB[0]);
    
    if(signal == SIGNAL_BUY)
    {
        // Price should be above cloud
        if(close < cloudTop)
            return false;
        // Tenkan above Kijun
        if(ichiTenkan[0] < ichiKijun[0])
            return false;
    }
    else if(signal == SIGNAL_SELL)
    {
        // Price should be below cloud
        if(close > cloudBottom)
            return false;
        // Tenkan below Kijun
        if(ichiTenkan[0] > ichiKijun[0])
            return false;
    }
    
    return true;
}

//+------------------------------------------------------------------+
//| Parabolic SAR Filter                                             |
//+------------------------------------------------------------------+
bool CheckSARFilter(ENUM_SIGNAL_TYPE signal)
{
    if(!InpUseSAR)
        return true;
    
    if(CopyBuffer(handleSAR, 0, 0, 3, sarValue) < 3) return true;
    
    double close = iClose(_Symbol, PERIOD_CURRENT, 0);
    
    if(signal == SIGNAL_BUY)
    {
        // SAR should be below price (uptrend)
        if(sarValue[0] > close)
            return false;
    }
    else if(signal == SIGNAL_SELL)
    {
        // SAR should be above price (downtrend)
        if(sarValue[0] < close)
            return false;
    }
    
    return true;
}

//+------------------------------------------------------------------+
//| CCI Filter                                                       |
//+------------------------------------------------------------------+
bool CheckCCIFilter(ENUM_SIGNAL_TYPE signal)
{
    if(!InpUseCCI)
        return true;
    
    if(CopyBuffer(handleCCI, 0, 0, 3, cciValue) < 3) return true;
    
    if(signal == SIGNAL_BUY)
    {
        // Don't buy if overbought
        if(cciValue[0] > InpCCI_Overbought)
            return false;
    }
    else if(signal == SIGNAL_SELL)
    {
        // Don't sell if oversold
        if(cciValue[0] < InpCCI_Oversold)
            return false;
    }
    
    return true;
}

//+------------------------------------------------------------------+
//| Williams %R Filter                                               |
//+------------------------------------------------------------------+
bool CheckWilliamsFilter(ENUM_SIGNAL_TYPE signal)
{
    if(!InpUseWilliams)
        return true;
    
    if(CopyBuffer(handleWilliams, 0, 0, 3, williamsValue) < 3) return true;
    
    if(signal == SIGNAL_BUY)
    {
        // Don't buy if overbought
        if(williamsValue[0] > InpWilliams_OB)
            return false;
    }
    else if(signal == SIGNAL_SELL)
    {
        // Don't sell if oversold
        if(williamsValue[0] < InpWilliams_OS)
            return false;
    }
    
    return true;
}

//+------------------------------------------------------------------+
//| MFI (Money Flow Index) Filter                                    |
//+------------------------------------------------------------------+
bool CheckMFIFilter(ENUM_SIGNAL_TYPE signal)
{
    if(!InpUseMFI)
        return true;
    
    if(CopyBuffer(handleMFI, 0, 0, 3, mfiValue) < 3) return true;
    
    if(signal == SIGNAL_BUY)
    {
        if(mfiValue[0] > InpMFI_Overbought)
            return false;
    }
    else if(signal == SIGNAL_SELL)
    {
        if(mfiValue[0] < InpMFI_Oversold)
            return false;
    }
    
    return true;
}

//+------------------------------------------------------------------+
//| Calculate Pivot Points                                           |
//+------------------------------------------------------------------+
void CalculatePivotPoints()
{
    if(!InpUsePivot)
        return;
    
    ENUM_TIMEFRAMES tf = InpPivot_Daily ? PERIOD_D1 : PERIOD_W1;
    
    double high = iHigh(_Symbol, tf, 1);
    double low = iLow(_Symbol, tf, 1);
    double close = iClose(_Symbol, tf, 1);
    
    pivotP = (high + low + close) / 3.0;
    pivotR1 = 2 * pivotP - low;
    pivotR2 = pivotP + (high - low);
    pivotS1 = 2 * pivotP - high;
    pivotS2 = pivotP - (high - low);
}

bool CheckPivotFilter(ENUM_SIGNAL_TYPE signal)
{
    if(!InpUsePivot)
        return true;
    
    CalculatePivotPoints();
    
    double close = iClose(_Symbol, PERIOD_CURRENT, 0);
    
    if(signal == SIGNAL_BUY)
    {
        // Don't buy too close to resistance
        if(MathAbs(close - pivotR1) < atr[0] * 0.5 || MathAbs(close - pivotR2) < atr[0] * 0.5)
            return false;
    }
    else if(signal == SIGNAL_SELL)
    {
        // Don't sell too close to support
        if(MathAbs(close - pivotS1) < atr[0] * 0.5 || MathAbs(close - pivotS2) < atr[0] * 0.5)
            return false;
    }
    
    return true;
}

//+------------------------------------------------------------------+
//| Volatility Breakout Filter                                       |
//+------------------------------------------------------------------+
bool CheckVolatilityBreakout(ENUM_SIGNAL_TYPE signal)
{
    if(!InpUseVolBreak)
        return true;
    
    double highestHigh = 0, lowestLow = 999999;
    
    for(int i = 1; i <= InpVolBreak_Period; i++)
    {
        double high = iHigh(_Symbol, PERIOD_CURRENT, i);
        double low = iLow(_Symbol, PERIOD_CURRENT, i);
        if(high > highestHigh) highestHigh = high;
        if(low < lowestLow) lowestLow = low;
    }
    
    double close = iClose(_Symbol, PERIOD_CURRENT, 0);
    double breakoutThreshold = atr[0] * InpVolBreak_Mult;
    
    if(signal == SIGNAL_BUY)
    {
        // Price breaks above range
        if(close < highestHigh - breakoutThreshold)
            return false;
    }
    else if(signal == SIGNAL_SELL)
    {
        // Price breaks below range
        if(close > lowestLow + breakoutThreshold)
            return false;
    }
    
    return true;
}

//+------------------------------------------------------------------+
//| Trailing Take Profit                                             |
//+------------------------------------------------------------------+
void CheckTrailingTP()
{
    if(!InpUseTrailingTP)
        return;
    
    double atrValue = atr[0];
    
    for(int i = PositionsTotal() - 1; i >= 0; i--)
    {
        if(!posInfo.SelectByIndex(i))
            continue;
        
        if(posInfo.Symbol() != _Symbol || posInfo.Magic() != InpMagicNumber)
            continue;
        
        double currentTP = posInfo.TakeProfit();
        double openPrice = posInfo.PriceOpen();
        int digits = (int)SymbolInfoInteger(_Symbol, SYMBOL_DIGITS);
        
        if(posInfo.PositionType() == POSITION_TYPE_BUY)
        {
            double currentPrice = SymbolInfoDouble(_Symbol, SYMBOL_BID);
            double newTP = currentPrice + atrValue * InpTrailTP_ATRMult;
            
            // Only move TP if in profit and new TP is higher
            if(currentPrice > openPrice + atrValue * InpTrailTP_Step)
            {
                if(currentTP == 0 || newTP > currentTP)
                {
                    newTP = NormalizeDouble(newTP, digits);
                    trade.PositionModify(posInfo.Ticket(), posInfo.StopLoss(), newTP);
                }
            }
        }
        else
        {
            double currentPrice = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
            double newTP = currentPrice - atrValue * InpTrailTP_ATRMult;
            
            if(currentPrice < openPrice - atrValue * InpTrailTP_Step)
            {
                if(currentTP == 0 || newTP < currentTP)
                {
                    newTP = NormalizeDouble(newTP, digits);
                    trade.PositionModify(posInfo.Ticket(), posInfo.StopLoss(), newTP);
                }
            }
        }
    }
}

//+------------------------------------------------------------------+
//| Account Protection                                               |
//+------------------------------------------------------------------+
bool CheckAccountProtection()
{
    if(!InpUseAccProt)
        return true;
    
    double balance = AccountInfoDouble(ACCOUNT_BALANCE);
    
    // Min balance check
    if(balance < InpMinBalance)
    {
        Print("⛔ Min bakiye altında: $", balance);
        return false;
    }
    
    // Spread check
    double spread = SymbolInfoInteger(_Symbol, SYMBOL_SPREAD) * SymbolInfoDouble(_Symbol, SYMBOL_POINT) * 10;
    if(spread > InpMaxSpread)
    {
        Print("⚠️ Spread çok yüksek: ", spread, " pips");
        return false;
    }
    
    // Margin check
    if(InpCheckMargin)
    {
        double freeMargin = AccountInfoDouble(ACCOUNT_MARGIN_FREE);
        double marginLevel = AccountInfoDouble(ACCOUNT_MARGIN_LEVEL);
        
        if(marginLevel > 0 && marginLevel < 200)
        {
            Print("⚠️ Margin seviyesi düşük: ", marginLevel, "%");
            return false;
        }
    }
    
    return true;
}

//+------------------------------------------------------------------+
//| Initialize v3 Indicators                                         |
//+------------------------------------------------------------------+
void InitV3Indicators()
{
    if(InpUseADX)
        handleADX = iADX(_Symbol, PERIOD_CURRENT, InpADX_Period);
    
    if(InpUseIchimoku)
        handleIchimoku = iIchimoku(_Symbol, PERIOD_CURRENT, InpIchi_Tenkan, InpIchi_Kijun, InpIchi_Senkou);
    
    if(InpUseSAR)
        handleSAR = iSAR(_Symbol, PERIOD_CURRENT, InpSAR_Step, InpSAR_Max);
    
    if(InpUseCCI)
        handleCCI = iCCI(_Symbol, PERIOD_CURRENT, InpCCI_Period, PRICE_TYPICAL);
    
    if(InpUseWilliams)
        handleWilliams = iWPR(_Symbol, PERIOD_CURRENT, InpWilliams_Period);
    
    if(InpUseMFI)
        handleMFI = iMFI(_Symbol, PERIOD_CURRENT, InpMFI_Period, VOLUME_TICK);
    
    // Set arrays as series
    ArraySetAsSeries(adxValue, true);
    ArraySetAsSeries(diPlus, true);
    ArraySetAsSeries(diMinus, true);
    ArraySetAsSeries(ichiTenkan, true);
    ArraySetAsSeries(ichiKijun, true);
    ArraySetAsSeries(ichiSpanA, true);
    ArraySetAsSeries(ichiSpanB, true);
    ArraySetAsSeries(sarValue, true);
    ArraySetAsSeries(cciValue, true);
    ArraySetAsSeries(williamsValue, true);
    ArraySetAsSeries(mfiValue, true);
}

//+------------------------------------------------------------------+
//| Apply All v3 Filters                                             |
//+------------------------------------------------------------------+
bool ApplyV3Filters(ENUM_SIGNAL_TYPE signal)
{
    if(!CheckADXFilter(signal))
        return false;
    
    if(!CheckIchimokuFilter(signal))
        return false;
    
    if(!CheckSARFilter(signal))
        return false;
    
    if(!CheckCCIFilter(signal))
        return false;
    
    if(!CheckWilliamsFilter(signal))
        return false;
    
    if(!CheckMFIFilter(signal))
        return false;
    
    if(!CheckPivotFilter(signal))
        return false;
    
    if(!CheckVolatilityBreakout(signal))
        return false;
    
    if(!CheckAccountProtection())
        return false;
    
    return true;
}

//+------------------------------------------------------------------+
//|              YENI v4 MODÜL FONKSIYONLARI (10 MODUL)              |
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//| Keltner Channel Filter                                           |
//+------------------------------------------------------------------+
bool CheckKeltnerFilter(ENUM_SIGNAL_TYPE signal)
{
    if(!InpUseKeltner)
        return true;
    
    // Calculate Keltner Channel manually
    double ema = 0;
    for(int i = 0; i < InpKeltner_Period; i++)
        ema += iClose(_Symbol, PERIOD_CURRENT, i);
    ema /= InpKeltner_Period;
    
    double atrKelt = atr[0] * InpKeltner_Mult;
    double upper = ema + atrKelt;
    double lower = ema - atrKelt;
    
    double close = iClose(_Symbol, PERIOD_CURRENT, 0);
    
    if(signal == SIGNAL_BUY)
    {
        // Price should not be above upper band
        if(close > upper)
            return false;
    }
    else if(signal == SIGNAL_SELL)
    {
        // Price should not be below lower band
        if(close < lower)
            return false;
    }
    
    return true;
}

//+------------------------------------------------------------------+
//| Donchian Channel Filter                                          |
//+------------------------------------------------------------------+
bool CheckDonchianFilter(ENUM_SIGNAL_TYPE signal)
{
    if(!InpUseDonchian)
        return true;
    
    // Calculate Donchian Channel
    donchianHigh = 0;
    donchianLow = 999999;
    
    for(int i = 1; i <= InpDonchian_Period; i++)
    {
        double high = iHigh(_Symbol, PERIOD_CURRENT, i);
        double low = iLow(_Symbol, PERIOD_CURRENT, i);
        if(high > donchianHigh) donchianHigh = high;
        if(low < donchianLow) donchianLow = low;
    }
    
    double close = iClose(_Symbol, PERIOD_CURRENT, 0);
    
    if(InpDonchian_Break)
    {
        if(signal == SIGNAL_BUY && close < donchianHigh)
            return false;
        if(signal == SIGNAL_SELL && close > donchianLow)
            return false;
    }
    
    return true;
}

//+------------------------------------------------------------------+
//| Awesome Oscillator Filter                                        |
//+------------------------------------------------------------------+
bool CheckAOFilter(ENUM_SIGNAL_TYPE signal)
{
    if(!InpUseAO)
        return true;
    
    if(CopyBuffer(handleAO, 0, 0, 3, aoValue) < 3) return true;
    
    if(signal == SIGNAL_BUY)
    {
        // AO should be positive or rising
        if(aoValue[0] < 0 && aoValue[0] < aoValue[1])
            return false;
        
        // Saucer pattern (green bar after two red)
        if(InpAO_Saucer && aoValue[0] > 0)
        {
            if(aoValue[0] < aoValue[1]) return false;
        }
    }
    else if(signal == SIGNAL_SELL)
    {
        if(aoValue[0] > 0 && aoValue[0] > aoValue[1])
            return false;
    }
    
    return true;
}

//+------------------------------------------------------------------+
//| Momentum Filter                                                  |
//+------------------------------------------------------------------+
bool CheckMomentumFilter(ENUM_SIGNAL_TYPE signal)
{
    if(!InpUseMomentum)
        return true;
    
    if(CopyBuffer(handleMomentum, 0, 0, 3, momentumValue) < 3) return true;
    
    if(signal == SIGNAL_BUY)
    {
        if(momentumValue[0] < InpMomentum_Level)
            return false;
    }
    else if(signal == SIGNAL_SELL)
    {
        if(momentumValue[0] > InpMomentum_Level)
            return false;
    }
    
    return true;
}

//+------------------------------------------------------------------+
//| Force Index Filter                                               |
//+------------------------------------------------------------------+
bool CheckForceFilter(ENUM_SIGNAL_TYPE signal)
{
    if(!InpUseForce)
        return true;
    
    if(CopyBuffer(handleForce, 0, 0, 3, forceValue) < 3) return true;
    
    if(signal == SIGNAL_BUY)
    {
        if(forceValue[0] < 0 && forceValue[0] < forceValue[1])
            return false;
    }
    else if(signal == SIGNAL_SELL)
    {
        if(forceValue[0] > 0 && forceValue[0] > forceValue[1])
            return false;
    }
    
    return true;
}

//+------------------------------------------------------------------+
//| OBV Filter                                                       |
//+------------------------------------------------------------------+
bool CheckOBVFilter(ENUM_SIGNAL_TYPE signal)
{
    if(!InpUseOBV)
        return true;
    
    if(CopyBuffer(handleOBV, 0, 0, InpOBV_MA + 1, obvValue) < InpOBV_MA) return true;
    
    // Calculate OBV MA
    double obvSum = 0;
    for(int i = 0; i < InpOBV_MA; i++)
        obvSum += obvValue[i];
    double obvMAVal = obvSum / InpOBV_MA;
    
    if(signal == SIGNAL_BUY)
    {
        if(obvValue[0] < obvMAVal)
            return false;
    }
    else if(signal == SIGNAL_SELL)
    {
        if(obvValue[0] > obvMAVal)
            return false;
    }
    
    return true;
}

//+------------------------------------------------------------------+
//| Divergence Detector                                              |
//+------------------------------------------------------------------+
bool CheckDivergence(ENUM_SIGNAL_TYPE signal)
{
    if(!InpUseDivergence)
        return true;
    
    // Simple divergence check
    double price0 = iClose(_Symbol, PERIOD_CURRENT, 0);
    double price1 = iClose(_Symbol, PERIOD_CURRENT, InpDiv_Lookback);
    
    bool bullishDiv = false, bearishDiv = false;
    
    if(InpDiv_RSI && ArraySize(rsi) >= 3)
    {
        if(CopyBuffer(handleRSI, 0, InpDiv_Lookback, 1, rsi) >= 1)
        {
            double rsiOld = rsi[0];
            if(CopyBuffer(handleRSI, 0, 0, 1, rsi) >= 1)
            {
                // Bullish divergence: price lower, RSI higher
                if(price0 < price1 && rsi[0] > rsiOld)
                    bullishDiv = true;
                // Bearish divergence: price higher, RSI lower
                if(price0 > price1 && rsi[0] < rsiOld)
                    bearishDiv = true;
            }
        }
    }
    
    if(signal == SIGNAL_BUY && !bullishDiv)
        return false;
    if(signal == SIGNAL_SELL && !bearishDiv)
        return false;
    
    return true;
}

//+------------------------------------------------------------------+
//| Pattern Recognition                                              |
//+------------------------------------------------------------------+
bool CheckPatternFilter(ENUM_SIGNAL_TYPE signal)
{
    if(!InpUsePattern)
        return true;
    
    double open0 = iOpen(_Symbol, PERIOD_CURRENT, 0);
    double close0 = iClose(_Symbol, PERIOD_CURRENT, 0);
    double high0 = iHigh(_Symbol, PERIOD_CURRENT, 0);
    double low0 = iLow(_Symbol, PERIOD_CURRENT, 0);
    
    double open1 = iOpen(_Symbol, PERIOD_CURRENT, 1);
    double close1 = iClose(_Symbol, PERIOD_CURRENT, 1);
    double high1 = iHigh(_Symbol, PERIOD_CURRENT, 1);
    double low1 = iLow(_Symbol, PERIOD_CURRENT, 1);
    
    double body0 = MathAbs(close0 - open0);
    double body1 = MathAbs(close1 - open1);
    double range0 = high0 - low0;
    
    bool patternFound = false;
    
    // Engulfing
    if(InpPattern_Engulf)
    {
        if(signal == SIGNAL_BUY)
        {
            if(close1 < open1 && close0 > open0 && close0 > open1 && open0 < close1)
                patternFound = true;
        }
        else if(signal == SIGNAL_SELL)
        {
            if(close1 > open1 && close0 < open0 && close0 < open1 && open0 > close1)
                patternFound = true;
        }
    }
    
    // Doji
    if(InpPattern_Doji && body0 < range0 * 0.1)
    {
        patternFound = true;
    }
    
    // Hammer / Shooting Star
    if(InpPattern_Hammer)
    {
        double upperWick = signal == SIGNAL_BUY ? high0 - MathMax(open0, close0) : 0;
        double lowerWick = signal == SIGNAL_BUY ? MathMin(open0, close0) - low0 : high0 - MathMax(open0, close0);
        
        if(lowerWick > body0 * 2 && signal == SIGNAL_BUY)
            patternFound = true;
        if(upperWick > body0 * 2 && signal == SIGNAL_SELL)
            patternFound = true;
    }
    
    return patternFound || !InpUsePattern;
}

//+------------------------------------------------------------------+
//| Auto Lot Calculator                                              |
//+------------------------------------------------------------------+
double CalculateAutoLot()
{
    if(!InpUseAutoLot)
        return InpMinLot;
    
    double balance = AccountInfoDouble(ACCOUNT_BALANCE);
    double riskAmount = balance * (InpAutoLot_Risk / 100.0);
    
    double atrValue = atr[0];
    double slPoints = atrValue * InpATR_Multiplier;
    double tickValue = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE);
    double tickSize = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE);
    
    if(tickValue == 0 || slPoints == 0)
        return InpMinLot;
    
    double slInTicks = slPoints / tickSize;
    double lot = riskAmount / (slInTicks * tickValue);
    
    // Normalize
    double minLot = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
    double maxLot = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MAX);
    double lotStep = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);
    
    lot = MathMax(minLot, MathMin(InpAutoLot_Max, lot));
    lot = NormalizeDouble(MathFloor(lot / lotStep) * lotStep, 2);
    
    return lot;
}

//+------------------------------------------------------------------+
//| Trade Journal - Log Trade                                        |
//+------------------------------------------------------------------+
void LogTradeToJournal(string action, double lot, double price, double sl, double tp)
{
    if(!InpUseJournal)
        return;
    
    string entry = TimeToString(TimeCurrent(), TIME_DATE|TIME_MINUTES) + " | " +
                   action + " | " + _Symbol + " | Lot: " + DoubleToString(lot, 2) +
                   " | Price: " + DoubleToString(price, 5) +
                   " | SL: " + DoubleToString(sl, 5) +
                   " | TP: " + DoubleToString(tp, 5);
    
    Print("📝 Journal: ", entry);
    
    if(InpJournal_File)
    {
        if(journalFileHandle == INVALID_HANDLE)
        {
            string filename = "TradeJournal_" + _Symbol + "_" + 
                             TimeToString(TimeCurrent(), TIME_DATE) + ".csv";
            journalFileHandle = FileOpen(filename, FILE_WRITE|FILE_CSV|FILE_ANSI);
        }
        
        if(journalFileHandle != INVALID_HANDLE)
        {
            FileWrite(journalFileHandle, entry);
            totalJournalEntries++;
        }
    }
    
    if(InpJournal_Alert)
        Alert("Trade: ", action, " ", _Symbol, " @ ", price);
}

//+------------------------------------------------------------------+
//| Initialize v4 Indicators                                         |
//+------------------------------------------------------------------+
void InitV4Indicators()
{
    if(InpUseAO)
        handleAO = iAO(_Symbol, PERIOD_CURRENT);
    
    if(InpUseMomentum)
        handleMomentum = iMomentum(_Symbol, PERIOD_CURRENT, InpMomentum_Period, PRICE_CLOSE);
    
    if(InpUseForce)
        handleForce = iForce(_Symbol, PERIOD_CURRENT, InpForce_Period, MODE_SMA, VOLUME_TICK);
    
    if(InpUseOBV)
        handleOBV = iOBV(_Symbol, PERIOD_CURRENT, VOLUME_TICK);
    
    // Set arrays as series
    ArraySetAsSeries(aoValue, true);
    ArraySetAsSeries(momentumValue, true);
    ArraySetAsSeries(forceValue, true);
    ArraySetAsSeries(obvValue, true);
}

//+------------------------------------------------------------------+
//| Apply All v4 Filters                                             |
//+------------------------------------------------------------------+
bool ApplyV4Filters(ENUM_SIGNAL_TYPE signal)
{
    if(!CheckKeltnerFilter(signal))
        return false;
    
    if(!CheckDonchianFilter(signal))
        return false;
    
    if(!CheckAOFilter(signal))
        return false;
    
    if(!CheckMomentumFilter(signal))
        return false;
    
    if(!CheckForceFilter(signal))
        return false;
    
    if(!CheckOBVFilter(signal))
        return false;
    
    if(!CheckPatternFilter(signal))
        return false;
    
    return true;
}

//+------------------------------------------------------------------+
//|              YENI v5 MODÜL FONKSIYONLARI (10 MODUL)              |
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//| Heikin Ashi Filter                                               |
//+------------------------------------------------------------------+
bool CheckHeikinAshiFilter(ENUM_SIGNAL_TYPE signal)
{
    if(!InpUseHeikin)
        return true;
    
    // Calculate Heikin Ashi candles
    double haClose[5], haOpen[5];
    
    for(int i = 0; i < 5; i++)
    {
        double open = iOpen(_Symbol, PERIOD_CURRENT, i);
        double high = iHigh(_Symbol, PERIOD_CURRENT, i);
        double low = iLow(_Symbol, PERIOD_CURRENT, i);
        double close = iClose(_Symbol, PERIOD_CURRENT, i);
        
        haClose[i] = (open + high + low + close) / 4.0;
        
        if(i == 0)
            haOpen[i] = (open + close) / 2.0;
        else
            haOpen[i] = (haOpen[i-1] + haClose[i-1]) / 2.0;
    }
    
    // Check for confirmation candles
    int bullishCount = 0, bearishCount = 0;
    
    for(int i = 0; i < InpHeikin_Confirm; i++)
    {
        if(haClose[i] > haOpen[i]) bullishCount++;
        if(haClose[i] < haOpen[i]) bearishCount++;
    }
    
    if(signal == SIGNAL_BUY && bullishCount < InpHeikin_Confirm)
        return false;
    if(signal == SIGNAL_SELL && bearishCount < InpHeikin_Confirm)
        return false;
    
    return true;
}

//+------------------------------------------------------------------+
//| ZigZag Filter                                                    |
//+------------------------------------------------------------------+
bool CheckZigZagFilter(ENUM_SIGNAL_TYPE signal)
{
    if(!InpUseZigZag)
        return true;
    
    if(CopyBuffer(handleZigZag, 0, 0, 100, zigzagValue) < 50) return true;
    
    double lastSwing = 0, prevSwing = 0;
    int swingCount = 0;
    
    for(int i = 0; i < 100 && swingCount < 2; i++)
    {
        if(zigzagValue[i] != 0)
        {
            if(swingCount == 0)
                lastSwing = zigzagValue[i];
            else
                prevSwing = zigzagValue[i];
            swingCount++;
        }
    }
    
    double close = iClose(_Symbol, PERIOD_CURRENT, 0);
    
    if(signal == SIGNAL_BUY)
    {
        // Last swing should be low (buying at bottom)
        if(lastSwing > prevSwing)
            return false;
    }
    else if(signal == SIGNAL_SELL)
    {
        // Last swing should be high
        if(lastSwing < prevSwing)
            return false;
    }
    
    return true;
}

//+------------------------------------------------------------------+
//| Fractal Filter                                                   |
//+------------------------------------------------------------------+
bool CheckFractalFilter(ENUM_SIGNAL_TYPE signal)
{
    if(!InpUseFractal)
        return true;
    
    if(CopyBuffer(handleFractal, 0, 0, 20, fractalUp) < 10) return true;
    if(CopyBuffer(handleFractal, 1, 0, 20, fractalDown) < 10) return true;
    
    double lastFractalUp = 0, lastFractalDown = 0;
    
    for(int i = 0; i < 20; i++)
    {
        if(fractalUp[i] != EMPTY_VALUE && lastFractalUp == 0)
            lastFractalUp = fractalUp[i];
        if(fractalDown[i] != EMPTY_VALUE && lastFractalDown == 0)
            lastFractalDown = fractalDown[i];
    }
    
    double close = iClose(_Symbol, PERIOD_CURRENT, 0);
    
    if(signal == SIGNAL_BUY)
    {
        if(lastFractalDown > 0 && close < lastFractalDown)
            return false;
    }
    else if(signal == SIGNAL_SELL)
    {
        if(lastFractalUp > 0 && close > lastFractalUp)
            return false;
    }
    
    return true;
}

//+------------------------------------------------------------------+
//| Alligator Filter                                                 |
//+------------------------------------------------------------------+
bool CheckAlligatorFilter(ENUM_SIGNAL_TYPE signal)
{
    if(!InpUseAlligator)
        return true;
    
    if(CopyBuffer(handleAlligator, 0, 0, 5, alliJaw) < 3) return true;
    if(CopyBuffer(handleAlligator, 1, 0, 5, alliTeeth) < 3) return true;
    if(CopyBuffer(handleAlligator, 2, 0, 5, alliLips) < 3) return true;
    
    // Check alligator is awake (lines separating)
    bool awake = MathAbs(alliJaw[0] - alliTeeth[0]) > atr[0] * 0.2;
    
    if(signal == SIGNAL_BUY)
    {
        // Bullish: Lips > Teeth > Jaw
        if(alliLips[0] < alliTeeth[0] || alliTeeth[0] < alliJaw[0])
            return false;
    }
    else if(signal == SIGNAL_SELL)
    {
        // Bearish: Lips < Teeth < Jaw
        if(alliLips[0] > alliTeeth[0] || alliTeeth[0] > alliJaw[0])
            return false;
    }
    
    return true;
}

//+------------------------------------------------------------------+
//| Gator Oscillator Filter                                          |
//+------------------------------------------------------------------+
bool CheckGatorFilter(ENUM_SIGNAL_TYPE signal)
{
    if(!InpUseGator)
        return true;
    
    if(CopyBuffer(handleGator, 0, 0, 5, gatorUp) < 3) return true;
    if(CopyBuffer(handleGator, 1, 0, 5, gatorDown) < 3) return true;
    
    // Check if Gator is awake
    if(InpGator_Awake)
    {
        bool awake = (gatorUp[0] > gatorUp[1]) || (MathAbs(gatorDown[0]) > MathAbs(gatorDown[1]));
        if(!awake)
            return false;
    }
    
    return true;
}

//+------------------------------------------------------------------+
//| Market Profile Filter                                            |
//+------------------------------------------------------------------+
bool CheckProfileFilter(ENUM_SIGNAL_TYPE signal)
{
    if(!InpUseProfile)
        return true;
    
    // Calculate simple POC (Point of Control)
    double prices[];
    int priceCount[];
    ArrayResize(prices, InpProfile_Period);
    ArrayResize(priceCount, InpProfile_Period);
    
    for(int i = 0; i < InpProfile_Period; i++)
    {
        prices[i] = iClose(_Symbol, PERIOD_CURRENT, i);
        priceCount[i] = 1;
    }
    
    // Find POC (most traded price)
    double poc = prices[0];
    int maxCount = 0;
    
    for(int i = 0; i < InpProfile_Period; i++)
    {
        int count = 0;
        for(int j = 0; j < InpProfile_Period; j++)
        {
            if(MathAbs(prices[i] - prices[j]) < atr[0] * 0.1)
                count++;
        }
        if(count > maxCount)
        {
            maxCount = count;
            poc = prices[i];
        }
    }
    
    profilePOC = poc;
    double close = iClose(_Symbol, PERIOD_CURRENT, 0);
    
    if(signal == SIGNAL_BUY && close > poc + atr[0])
        return false;
    if(signal == SIGNAL_SELL && close < poc - atr[0])
        return false;
    
    return true;
}

//+------------------------------------------------------------------+
//| Correlation Filter                                               |
//+------------------------------------------------------------------+
bool CheckCorrelationFilter(ENUM_SIGNAL_TYPE signal)
{
    if(!InpUseCorrelation)
        return true;
    
    double prices1[], prices2[];
    ArrayResize(prices1, InpCorr_Period);
    ArrayResize(prices2, InpCorr_Period);
    
    for(int i = 0; i < InpCorr_Period; i++)
    {
        prices1[i] = iClose(_Symbol, PERIOD_CURRENT, i);
        prices2[i] = iClose(InpCorr_Symbol, PERIOD_CURRENT, i);
    }
    
    // Calculate correlation
    double sum1 = 0, sum2 = 0, sum12 = 0, sum11 = 0, sum22 = 0;
    
    for(int i = 0; i < InpCorr_Period; i++)
    {
        sum1 += prices1[i];
        sum2 += prices2[i];
        sum12 += prices1[i] * prices2[i];
        sum11 += prices1[i] * prices1[i];
        sum22 += prices2[i] * prices2[i];
    }
    
    double n = InpCorr_Period;
    double numerator = n * sum12 - sum1 * sum2;
    double denominator = MathSqrt((n * sum11 - sum1 * sum1) * (n * sum22 - sum2 * sum2));
    
    double correlation = denominator != 0 ? numerator / denominator : 0;
    
    // If highly correlated, check if correlated symbol agrees
    if(MathAbs(correlation) >= InpCorr_Threshold)
    {
        double corrChange = prices2[0] - prices2[1];
        if(signal == SIGNAL_BUY && correlation > 0 && corrChange < 0)
            return false;
        if(signal == SIGNAL_SELL && correlation > 0 && corrChange > 0)
            return false;
    }
    
    return true;
}

//+------------------------------------------------------------------+
//| Seasonal Filter                                                  |
//+------------------------------------------------------------------+
bool CheckSeasonalFilter()
{
    if(!InpUseSeasonal)
        return true;
    
    MqlDateTime dt;
    TimeCurrent(dt);
    
    if(InpSeasonal_Month)
    {
        int currentMonth = dt.mon;
        
        // Parse good months from string
        string goodMonths = InpSeasonal_Good;
        bool isGoodMonth = false;
        
        if(StringFind(goodMonths, IntegerToString(currentMonth)) >= 0)
            isGoodMonth = true;
        
        if(!isGoodMonth)
            return false;
    }
    
    return true;
}

//+------------------------------------------------------------------+
//| ML Score Filter (Simple implementation)                          |
//+------------------------------------------------------------------+
bool CheckMLFilter(ENUM_SIGNAL_TYPE signal)
{
    if(!InpUseML)
        return true;
    
    // Simple ML-like scoring based on multiple features
    double score = 0.5;
    int features = 0;
    
    // Feature 1: MA alignment
    if(ma1[0] > ma2[0] && ma2[0] > ma3[0])
        score += 0.1;
    else if(ma1[0] < ma2[0] && ma2[0] < ma3[0])
        score -= 0.1;
    features++;
    
    // Feature 2: RSI position
    if(ArraySize(rsi) > 0)
    {
        if(rsi[0] > 50 && rsi[0] < 70) score += 0.05;
        else if(rsi[0] < 50 && rsi[0] > 30) score -= 0.05;
        features++;
    }
    
    // Feature 3: ATR condition
    double avgATR = 0;
    for(int i = 0; i < 10; i++) avgATR += atr[i];
    avgATR /= 10;
    if(atr[0] > avgATR) score += 0.05;
    features++;
    
    // Feature 4: Price momentum
    double priceChange = iClose(_Symbol, PERIOD_CURRENT, 0) - iClose(_Symbol, PERIOD_CURRENT, 5);
    if(priceChange > 0) score += 0.1;
    else score -= 0.1;
    features++;
    
    // Feature 5: Volume
    if(InpUseVolume && CheckVolumeFilter())
        score += 0.05;
    features++;
    
    mlScore = score;
    
    if(signal == SIGNAL_BUY && score < InpML_MinScore)
        return false;
    if(signal == SIGNAL_SELL && score > (1 - InpML_MinScore))
        return false;
    
    return true;
}

//+------------------------------------------------------------------+
//| Initialize v5 Indicators                                         |
//+------------------------------------------------------------------+
void InitV5Indicators()
{
    if(InpUseZigZag)
        handleZigZag = iCustom(_Symbol, PERIOD_CURRENT, "Examples\\ZigZag", InpZZ_Depth, InpZZ_Deviation, InpZZ_Backstep);
    
    if(InpUseFractal)
        handleFractal = iFractals(_Symbol, PERIOD_CURRENT);
    
    if(InpUseAlligator)
        handleAlligator = iAlligator(_Symbol, PERIOD_CURRENT, InpAlli_Jaw, 8, InpAlli_Teeth, 5, InpAlli_Lips, 3, MODE_SMMA, PRICE_MEDIAN);
    
    if(InpUseGator)
        handleGator = iGator(_Symbol, PERIOD_CURRENT, InpAlli_Jaw, 8, InpAlli_Teeth, 5, InpAlli_Lips, 3, MODE_SMMA, PRICE_MEDIAN);
    
    ArraySetAsSeries(zigzagValue, true);
    ArraySetAsSeries(fractalUp, true);
    ArraySetAsSeries(fractalDown, true);
    ArraySetAsSeries(alliJaw, true);
    ArraySetAsSeries(alliTeeth, true);
    ArraySetAsSeries(alliLips, true);
    ArraySetAsSeries(gatorUp, true);
    ArraySetAsSeries(gatorDown, true);
}

//+------------------------------------------------------------------+
//| Apply All v5 Filters                                             |
//+------------------------------------------------------------------+
bool ApplyV5Filters(ENUM_SIGNAL_TYPE signal)
{
    if(!CheckHeikinAshiFilter(signal))
        return false;
    
    if(!CheckZigZagFilter(signal))
        return false;
    
    if(!CheckFractalFilter(signal))
        return false;
    
    if(!CheckAlligatorFilter(signal))
        return false;
    
    if(!CheckGatorFilter(signal))
        return false;
    
    if(!CheckProfileFilter(signal))
        return false;
    
    if(!CheckCorrelationFilter(signal))
        return false;
    
    if(!CheckSeasonalFilter())
        return false;
    
    if(!CheckMLFilter(signal))
        return false;
    
    return true;
}

//+------------------------------------------------------------------+
//|              YENI v6 MODÜL FONKSIYONLARI (10 MODUL)              |
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//| VWAP Filter                                                      |
//+------------------------------------------------------------------+
bool CheckVWAPFilter(ENUM_SIGNAL_TYPE signal)
{
    if(!InpUseVWAP)
        return true;
    
    // Calculate VWAP
    double sumPV = 0, sumV = 0, sumPV2 = 0;
    int period = InpVWAP_Daily ? PeriodSeconds(PERIOD_D1) / PeriodSeconds(PERIOD_CURRENT) : 100;
    
    for(int i = 0; i < period && i < 500; i++)
    {
        double typical = (iHigh(_Symbol, PERIOD_CURRENT, i) + 
                         iLow(_Symbol, PERIOD_CURRENT, i) + 
                         iClose(_Symbol, PERIOD_CURRENT, i)) / 3.0;
        long vol = iVolume(_Symbol, PERIOD_CURRENT, i);
        
        sumPV += typical * vol;
        sumV += vol;
        sumPV2 += typical * typical * vol;
    }
    
    if(sumV == 0) return true;
    
    vwapValue = sumPV / sumV;
    double variance = (sumPV2 / sumV) - (vwapValue * vwapValue);
    double stdDev = MathSqrt(MathAbs(variance));
    
    vwapUpper = vwapValue + stdDev * InpVWAP_Deviation;
    vwapLower = vwapValue - stdDev * InpVWAP_Deviation;
    
    double close = iClose(_Symbol, PERIOD_CURRENT, 0);
    
    if(signal == SIGNAL_BUY && close > vwapUpper)
        return false;
    if(signal == SIGNAL_SELL && close < vwapLower)
        return false;
    
    return true;
}

//+------------------------------------------------------------------+
//| Super Trend Filter                                               |
//+------------------------------------------------------------------+
bool CheckSuperTrendFilter(ENUM_SIGNAL_TYPE signal)
{
    if(!InpUseSuperTrend)
        return true;
    
    // Calculate SuperTrend
    double atrVal = 0;
    for(int i = 0; i < InpST_Period; i++)
        atrVal += iHigh(_Symbol, PERIOD_CURRENT, i) - iLow(_Symbol, PERIOD_CURRENT, i);
    atrVal /= InpST_Period;
    
    double close = iClose(_Symbol, PERIOD_CURRENT, 0);
    double hl2 = (iHigh(_Symbol, PERIOD_CURRENT, 0) + iLow(_Symbol, PERIOD_CURRENT, 0)) / 2.0;
    
    double upperBand = hl2 + InpST_Multiplier * atrVal;
    double lowerBand = hl2 - InpST_Multiplier * atrVal;
    
    // Determine trend
    if(close > superTrendValue)
    {
        superTrendUp = true;
        superTrendValue = lowerBand;
    }
    else
    {
        superTrendUp = false;
        superTrendValue = upperBand;
    }
    
    if(signal == SIGNAL_BUY && !superTrendUp)
        return false;
    if(signal == SIGNAL_SELL && superTrendUp)
        return false;
    
    return true;
}

//+------------------------------------------------------------------+
//| Chaikin Oscillator Filter                                        |
//+------------------------------------------------------------------+
bool CheckChaikinFilter(ENUM_SIGNAL_TYPE signal)
{
    if(!InpUseChaikin)
        return true;
    
    if(CopyBuffer(handleChaikin, 0, 0, 3, chaikinValue) < 3) return true;
    
    if(signal == SIGNAL_BUY)
    {
        if(chaikinValue[0] < 0 && chaikinValue[0] < chaikinValue[1])
            return false;
    }
    else if(signal == SIGNAL_SELL)
    {
        if(chaikinValue[0] > 0 && chaikinValue[0] > chaikinValue[1])
            return false;
    }
    
    return true;
}

//+------------------------------------------------------------------+
//| Elder Ray Filter                                                 |
//+------------------------------------------------------------------+
bool CheckElderRayFilter(ENUM_SIGNAL_TYPE signal)
{
    if(!InpUseElderRay)
        return true;
    
    if(CopyBuffer(handleBullPower, 0, 0, 3, bullPower) < 3) return true;
    if(CopyBuffer(handleBearPower, 0, 0, 3, bearPower) < 3) return true;
    
    if(signal == SIGNAL_BUY)
    {
        // Bull power should be positive, Bear power negative but rising
        if(bullPower[0] < 0)
            return false;
    }
    else if(signal == SIGNAL_SELL)
    {
        // Bear power should be negative, Bull power positive but falling
        if(bearPower[0] > 0)
            return false;
    }
    
    return true;
}

//+------------------------------------------------------------------+
//| Aroon Filter                                                     |
//+------------------------------------------------------------------+
bool CheckAroonFilter(ENUM_SIGNAL_TYPE signal)
{
    if(!InpUseAroon)
        return true;
    
    // Calculate Aroon manually
    int highestBar = 0, lowestBar = 0;
    double highestHigh = 0, lowestLow = 999999;
    
    for(int i = 0; i < InpAroon_Period; i++)
    {
        double high = iHigh(_Symbol, PERIOD_CURRENT, i);
        double low = iLow(_Symbol, PERIOD_CURRENT, i);
        
        if(high > highestHigh) { highestHigh = high; highestBar = i; }
        if(low < lowestLow) { lowestLow = low; lowestBar = i; }
    }
    
    double aroonUpVal = ((InpAroon_Period - highestBar) * 100.0) / InpAroon_Period;
    double aroonDownVal = ((InpAroon_Period - lowestBar) * 100.0) / InpAroon_Period;
    
    if(signal == SIGNAL_BUY)
    {
        if(aroonUpVal < InpAroon_Level || aroonUpVal < aroonDownVal)
            return false;
    }
    else if(signal == SIGNAL_SELL)
    {
        if(aroonDownVal < InpAroon_Level || aroonDownVal < aroonUpVal)
            return false;
    }
    
    return true;
}

//+------------------------------------------------------------------+
//| Chandelier Exit Filter                                           |
//+------------------------------------------------------------------+
bool CheckChandelierFilter(ENUM_SIGNAL_TYPE signal)
{
    if(!InpUseChandelier)
        return true;
    
    double highestHigh = 0, lowestLow = 999999;
    double atrSum = 0;
    
    for(int i = 0; i < InpChand_Period; i++)
    {
        double high = iHigh(_Symbol, PERIOD_CURRENT, i);
        double low = iLow(_Symbol, PERIOD_CURRENT, i);
        
        if(high > highestHigh) highestHigh = high;
        if(low < lowestLow) lowestLow = low;
        
        atrSum += iHigh(_Symbol, PERIOD_CURRENT, i) - iLow(_Symbol, PERIOD_CURRENT, i);
    }
    
    double chandATR = atrSum / InpChand_Period;
    chandelierLong = highestHigh - InpChand_Mult * chandATR;
    chandelierShort = lowestLow + InpChand_Mult * chandATR;
    
    double close = iClose(_Symbol, PERIOD_CURRENT, 0);
    
    if(signal == SIGNAL_BUY && close < chandelierLong)
        return false;
    if(signal == SIGNAL_SELL && close > chandelierShort)
        return false;
    
    return true;
}

//+------------------------------------------------------------------+
//| Hull MA Filter                                                   |
//+------------------------------------------------------------------+
bool CheckHullMAFilter(ENUM_SIGNAL_TYPE signal)
{
    if(!InpUseHullMA)
        return true;
    
    // Calculate Hull MA: WMA(2*WMA(n/2) - WMA(n), sqrt(n))
    int halfPeriod = InpHull_Period / 2;
    int sqrtPeriod = (int)MathSqrt(InpHull_Period);
    
    double wma1 = 0, wma2 = 0, wma3 = 0;
    double sum1 = 0, sum2 = 0, sum3 = 0;
    double weight1 = 0, weight2 = 0, weight3 = 0;
    
    for(int i = 0; i < halfPeriod; i++)
    {
        double w = halfPeriod - i;
        sum1 += iClose(_Symbol, PERIOD_CURRENT, i) * w;
        weight1 += w;
    }
    wma1 = sum1 / weight1;
    
    for(int i = 0; i < InpHull_Period; i++)
    {
        double w = InpHull_Period - i;
        sum2 += iClose(_Symbol, PERIOD_CURRENT, i) * w;
        weight2 += w;
    }
    wma2 = sum2 / weight2;
    
    double rawHull = 2 * wma1 - wma2;
    hullMAPrev = hullMA;
    hullMA = rawHull; // Simplified
    
    if(signal == SIGNAL_BUY && hullMA < hullMAPrev)
        return false;
    if(signal == SIGNAL_SELL && hullMA > hullMAPrev)
        return false;
    
    return true;
}

//+------------------------------------------------------------------+
//| Squeeze Momentum Filter                                          |
//+------------------------------------------------------------------+
bool CheckSqueezeFilter(ENUM_SIGNAL_TYPE signal)
{
    if(!InpUseSqueeze)
        return true;
    
    // Calculate BB and KC bands
    double bbSum = 0, kcSum = 0;
    
    for(int i = 0; i < InpSqueeze_BB; i++)
        bbSum += iClose(_Symbol, PERIOD_CURRENT, i);
    double bbMid = bbSum / InpSqueeze_BB;
    
    double stdDev = 0;
    for(int i = 0; i < InpSqueeze_BB; i++)
    {
        double diff = iClose(_Symbol, PERIOD_CURRENT, i) - bbMid;
        stdDev += diff * diff;
    }
    stdDev = MathSqrt(stdDev / InpSqueeze_BB);
    
    double bbUpper = bbMid + InpSqueeze_BBMult * stdDev;
    double bbLower = bbMid - InpSqueeze_BBMult * stdDev;
    
    double atrKC = atr[0];
    double kcUpper = bbMid + InpSqueeze_KCMult * atrKC;
    double kcLower = bbMid - InpSqueeze_KCMult * atrKC;
    
    // Squeeze is ON when BB is inside KC
    squeezeOn = (bbLower > kcLower && bbUpper < kcUpper);
    
    if(squeezeOn)
        return false; // Don't trade during squeeze
    
    return true;
}

//+------------------------------------------------------------------+
//| Range Filter                                                     |
//+------------------------------------------------------------------+
bool CheckRangeFilter(ENUM_SIGNAL_TYPE signal)
{
    if(!InpUseRange)
        return true;
    
    double sum = 0;
    for(int i = 0; i < InpRange_Period; i++)
        sum += iClose(_Symbol, PERIOD_CURRENT, i);
    double avg = sum / InpRange_Period;
    
    double range = 0;
    for(int i = 0; i < InpRange_Period; i++)
        range += MathAbs(iClose(_Symbol, PERIOD_CURRENT, i) - avg);
    range = range / InpRange_Period * InpRange_Mult;
    
    rangeFilterPrev = rangeFilter;
    double close = iClose(_Symbol, PERIOD_CURRENT, 0);
    
    if(close > avg + range)
        rangeFilter = avg + range;
    else if(close < avg - range)
        rangeFilter = avg - range;
    else
        rangeFilter = rangeFilterPrev;
    
    if(signal == SIGNAL_BUY && close < rangeFilter)
        return false;
    if(signal == SIGNAL_SELL && close > rangeFilter)
        return false;
    
    return true;
}

//+------------------------------------------------------------------+
//| News Calendar API Filter                                         |
//+------------------------------------------------------------------+
bool CheckNewsAPIFilter()
{
    if(!InpUseNewsAPI)
        return true;
    
    // MQL5 Calendar integration
    MqlCalendarValue values[];
    datetime from = TimeCurrent() - InpNews_Before * 60;
    datetime to = TimeCurrent() + InpNews_After * 60;
    
    if(CalendarValueHistory(values, from, to))
    {
        for(int i = 0; i < ArraySize(values); i++)
        {
            MqlCalendarEvent event;
            if(CalendarEventById(values[i].event_id, event))
            {
                if((int)event.importance >= InpNews_Impact)
                {
                    Print("📰 Major news event detected: ", event.name);
                    return false;
                }
            }
        }
    }
    
    return true;
}

//+------------------------------------------------------------------+
//| Initialize v6 Indicators                                         |
//+------------------------------------------------------------------+
void InitV6Indicators()
{
    if(InpUseChaikin)
        handleChaikin = iChaikin(_Symbol, PERIOD_CURRENT, InpChaikin_Fast, InpChaikin_Slow, MODE_EMA, VOLUME_TICK);
    
    if(InpUseElderRay)
    {
        handleBullPower = iBullsPower(_Symbol, PERIOD_CURRENT, InpElder_Period);
        handleBearPower = iBearsPower(_Symbol, PERIOD_CURRENT, InpElder_Period);
    }
    
    ArraySetAsSeries(chaikinValue, true);
    ArraySetAsSeries(bullPower, true);
    ArraySetAsSeries(bearPower, true);
    ArraySetAsSeries(aroonUp, true);
    ArraySetAsSeries(aroonDown, true);
}

//+------------------------------------------------------------------+
//| Apply All v6 Filters                                             |
//+------------------------------------------------------------------+
bool ApplyV6Filters(ENUM_SIGNAL_TYPE signal)
{
    if(!CheckVWAPFilter(signal))
        return false;
    
    if(!CheckSuperTrendFilter(signal))
        return false;
    
    if(!CheckChaikinFilter(signal))
        return false;
    
    if(!CheckElderRayFilter(signal))
        return false;
    
    if(!CheckAroonFilter(signal))
        return false;
    
    if(!CheckChandelierFilter(signal))
        return false;
    
    if(!CheckHullMAFilter(signal))
        return false;
    
    if(!CheckSqueezeFilter(signal))
        return false;
    
    if(!CheckRangeFilter(signal))
        return false;
    
    if(!CheckNewsAPIFilter())
        return false;
    
    return true;
}

//+------------------------------------------------------------------+
//|              YENI v7 MODÜL FONKSIYONLARI (10 MODUL)              |
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//| TRIX Filter                                                      |
//+------------------------------------------------------------------+
bool CheckTRIXFilter(ENUM_SIGNAL_TYPE signal)
{
    if(!InpUseTRIX)
        return true;
    
    if(CopyBuffer(handleTRIX, 0, 0, 3, trixValue) < 3) return true;
    if(CopyBuffer(handleTRIX, 1, 0, 3, trixSignal) < 3) return true;
    
    if(signal == SIGNAL_BUY)
    {
        if(trixValue[0] < trixSignal[0])
            return false;
    }
    else if(signal == SIGNAL_SELL)
    {
        if(trixValue[0] > trixSignal[0])
            return false;
    }
    
    return true;
}

//+------------------------------------------------------------------+
//| DPO (Detrended Price Oscillator) Filter                          |
//+------------------------------------------------------------------+
bool CheckDPOFilter(ENUM_SIGNAL_TYPE signal)
{
    if(!InpUseDPO)
        return true;
    
    // Calculate DPO
    double sma = 0;
    for(int i = 0; i < InpDPO_Period; i++)
        sma += iClose(_Symbol, PERIOD_CURRENT, i);
    sma /= InpDPO_Period;
    
    int shift = InpDPO_Period / 2 + 1;
    dpoValue = iClose(_Symbol, PERIOD_CURRENT, 0) - sma;
    
    if(signal == SIGNAL_BUY && dpoValue < 0)
        return false;
    if(signal == SIGNAL_SELL && dpoValue > 0)
        return false;
    
    return true;
}

//+------------------------------------------------------------------+
//| KST (Know Sure Thing) Filter                                     |
//+------------------------------------------------------------------+
bool CheckKSTFilter(ENUM_SIGNAL_TYPE signal)
{
    if(!InpUseKST)
        return true;
    
    // Calculate KST
    double roc1 = (iClose(_Symbol, PERIOD_CURRENT, 0) - iClose(_Symbol, PERIOD_CURRENT, InpKST_ROC1)) / iClose(_Symbol, PERIOD_CURRENT, InpKST_ROC1) * 100;
    double roc2 = (iClose(_Symbol, PERIOD_CURRENT, 0) - iClose(_Symbol, PERIOD_CURRENT, InpKST_ROC2)) / iClose(_Symbol, PERIOD_CURRENT, InpKST_ROC2) * 100;
    double roc3 = (iClose(_Symbol, PERIOD_CURRENT, 0) - iClose(_Symbol, PERIOD_CURRENT, InpKST_ROC3)) / iClose(_Symbol, PERIOD_CURRENT, InpKST_ROC3) * 100;
    double roc4 = (iClose(_Symbol, PERIOD_CURRENT, 0) - iClose(_Symbol, PERIOD_CURRENT, InpKST_ROC4)) / iClose(_Symbol, PERIOD_CURRENT, InpKST_ROC4) * 100;
    
    kstValue = roc1 * 1 + roc2 * 2 + roc3 * 3 + roc4 * 4;
    
    if(signal == SIGNAL_BUY && kstValue < 0)
        return false;
    if(signal == SIGNAL_SELL && kstValue > 0)
        return false;
    
    return true;
}

//+------------------------------------------------------------------+
//| Coppock Curve Filter                                             |
//+------------------------------------------------------------------+
bool CheckCoppockFilter(ENUM_SIGNAL_TYPE signal)
{
    if(!InpUseCoppock)
        return true;
    
    // Calculate Coppock (simplified)
    double rocLong = (iClose(_Symbol, PERIOD_CURRENT, 0) - iClose(_Symbol, PERIOD_CURRENT, InpCopp_Long)) / iClose(_Symbol, PERIOD_CURRENT, InpCopp_Long) * 100;
    double rocShort = (iClose(_Symbol, PERIOD_CURRENT, 0) - iClose(_Symbol, PERIOD_CURRENT, InpCopp_Short)) / iClose(_Symbol, PERIOD_CURRENT, InpCopp_Short) * 100;
    
    coppockValue = rocLong + rocShort;
    
    // Coppock is primarily a buy signal indicator
    if(signal == SIGNAL_BUY && coppockValue < 0)
        return false;
    
    return true;
}

//+------------------------------------------------------------------+
//| Mass Index Filter                                                |
//+------------------------------------------------------------------+
bool CheckMassIndexFilter(ENUM_SIGNAL_TYPE signal)
{
    if(!InpUseMass)
        return true;
    
    // Calculate Mass Index
    double emaSum = 0;
    for(int i = 0; i < InpMass_Period; i++)
    {
        double range = iHigh(_Symbol, PERIOD_CURRENT, i) - iLow(_Symbol, PERIOD_CURRENT, i);
        emaSum += range;
    }
    massIndex = emaSum; // Simplified
    
    // Mass Index bulge indicates potential reversal
    if(massIndex > InpMass_Bulge)
        return false; // Wait for reversal confirmation
    
    return true;
}

//+------------------------------------------------------------------+
//| Vortex Indicator Filter                                          |
//+------------------------------------------------------------------+
bool CheckVortexFilter(ENUM_SIGNAL_TYPE signal)
{
    if(!InpUseVortex)
        return true;
    
    // Calculate Vortex
    double vmPlus = 0, vmMinus = 0, tr = 0;
    
    for(int i = 0; i < InpVortex_Period; i++)
    {
        double high = iHigh(_Symbol, PERIOD_CURRENT, i);
        double low = iLow(_Symbol, PERIOD_CURRENT, i);
        double highPrev = iHigh(_Symbol, PERIOD_CURRENT, i + 1);
        double lowPrev = iLow(_Symbol, PERIOD_CURRENT, i + 1);
        double closePrev = iClose(_Symbol, PERIOD_CURRENT, i + 1);
        
        vmPlus += MathAbs(high - lowPrev);
        vmMinus += MathAbs(low - highPrev);
        tr += MathMax(high - low, MathMax(MathAbs(high - closePrev), MathAbs(low - closePrev)));
    }
    
    double viPlusVal = tr > 0 ? vmPlus / tr : 0;
    double viMinusVal = tr > 0 ? vmMinus / tr : 0;
    
    if(signal == SIGNAL_BUY && viPlusVal < viMinusVal)
        return false;
    if(signal == SIGNAL_SELL && viMinusVal < viPlusVal)
        return false;
    
    return true;
}

//+------------------------------------------------------------------+
//| Ultimate Oscillator Filter                                       |
//+------------------------------------------------------------------+
bool CheckUltimateFilter(ENUM_SIGNAL_TYPE signal)
{
    if(!InpUseUltimate)
        return true;
    
    // Calculate Ultimate Oscillator
    double bp1 = 0, tr1 = 0;
    double bp2 = 0, tr2 = 0;
    double bp3 = 0, tr3 = 0;
    
    for(int i = 0; i < InpUlt_Period1; i++)
    {
        double close = iClose(_Symbol, PERIOD_CURRENT, i);
        double low = iLow(_Symbol, PERIOD_CURRENT, i);
        double closePrev = iClose(_Symbol, PERIOD_CURRENT, i + 1);
        
        bp1 += close - MathMin(low, closePrev);
        tr1 += MathMax(iHigh(_Symbol, PERIOD_CURRENT, i), closePrev) - MathMin(low, closePrev);
    }
    
    for(int i = 0; i < InpUlt_Period2; i++)
    {
        double close = iClose(_Symbol, PERIOD_CURRENT, i);
        double low = iLow(_Symbol, PERIOD_CURRENT, i);
        double closePrev = iClose(_Symbol, PERIOD_CURRENT, i + 1);
        
        bp2 += close - MathMin(low, closePrev);
        tr2 += MathMax(iHigh(_Symbol, PERIOD_CURRENT, i), closePrev) - MathMin(low, closePrev);
    }
    
    for(int i = 0; i < InpUlt_Period3; i++)
    {
        double close = iClose(_Symbol, PERIOD_CURRENT, i);
        double low = iLow(_Symbol, PERIOD_CURRENT, i);
        double closePrev = iClose(_Symbol, PERIOD_CURRENT, i + 1);
        
        bp3 += close - MathMin(low, closePrev);
        tr3 += MathMax(iHigh(_Symbol, PERIOD_CURRENT, i), closePrev) - MathMin(low, closePrev);
    }
    
    double avg1 = tr1 > 0 ? bp1 / tr1 : 0;
    double avg2 = tr2 > 0 ? bp2 / tr2 : 0;
    double avg3 = tr3 > 0 ? bp3 / tr3 : 0;
    
    ultimateOsc = 100 * (4 * avg1 + 2 * avg2 + avg3) / 7;
    
    if(signal == SIGNAL_BUY && ultimateOsc < 30)
        return false;
    if(signal == SIGNAL_SELL && ultimateOsc > 70)
        return false;
    
    return true;
}

//+------------------------------------------------------------------+
//| Accumulation/Distribution Filter                                 |
//+------------------------------------------------------------------+
bool CheckADFilter(ENUM_SIGNAL_TYPE signal)
{
    if(!InpUseAD)
        return true;
    
    if(CopyBuffer(handleAD, 0, 0, InpAD_MA + 1, adValue) < InpAD_MA) return true;
    
    // Calculate A/D MA
    double adSum = 0;
    for(int i = 0; i < InpAD_MA; i++)
        adSum += adValue[i];
    double adMAVal = adSum / InpAD_MA;
    
    if(signal == SIGNAL_BUY && adValue[0] < adMAVal)
        return false;
    if(signal == SIGNAL_SELL && adValue[0] > adMAVal)
        return false;
    
    return true;
}

//+------------------------------------------------------------------+
//| Random Forest Score Filter                                       |
//+------------------------------------------------------------------+
bool CheckRandomForestFilter(ENUM_SIGNAL_TYPE signal)
{
    if(!InpUseRF)
        return true;
    
    // Simulate Random Forest with multiple decision trees
    double votes = 0;
    
    for(int tree = 0; tree < InpRF_Trees; tree++)
    {
        double treeScore = 0;
        
        // Each tree uses different features
        int feature = tree % 5;
        
        switch(feature)
        {
            case 0: // MA trend
                if(ma1[0] > ma3[0]) treeScore = 1;
                else treeScore = -1;
                break;
            case 1: // RSI
                if(ArraySize(rsi) > 0 && rsi[0] > 50) treeScore = 1;
                else treeScore = -1;
                break;
            case 2: // ATR momentum
                if(atr[0] > atr[1]) treeScore = 0.5;
                else treeScore = -0.5;
                break;
            case 3: // Price momentum
                if(iClose(_Symbol, PERIOD_CURRENT, 0) > iClose(_Symbol, PERIOD_CURRENT, 5)) treeScore = 1;
                else treeScore = -1;
                break;
            case 4: // Volume
                if(InpUseVolume && CheckVolumeFilter()) treeScore = 0.5;
                break;
        }
        
        votes += treeScore;
    }
    
    rfScore = (votes / InpRF_Trees + 1) / 2; // Normalize to 0-1
    
    if(signal == SIGNAL_BUY && rfScore < InpRF_MinScore)
        return false;
    if(signal == SIGNAL_SELL && rfScore > (1 - InpRF_MinScore))
        return false;
    
    return true;
}

//+------------------------------------------------------------------+
//| Monte Carlo Risk Filter                                          |
//+------------------------------------------------------------------+
bool CheckMonteCarloFilter(ENUM_SIGNAL_TYPE signal)
{
    if(!InpUseMonteCarlo)
        return true;
    
    // Simple Monte Carlo simulation
    double returns[];
    ArrayResize(returns, InpMC_Simulations);
    
    // Generate random returns based on historical volatility
    double avgReturn = (iClose(_Symbol, PERIOD_CURRENT, 0) - iClose(_Symbol, PERIOD_CURRENT, 20)) / iClose(_Symbol, PERIOD_CURRENT, 20);
    double volatility = atr[0] / iClose(_Symbol, PERIOD_CURRENT, 0);
    
    for(int i = 0; i < InpMC_Simulations; i++)
    {
        // Random walk simulation
        double random = (MathRand() / 32767.0 - 0.5) * 2;
        returns[i] = avgReturn + random * volatility;
    }
    
    // Sort returns
    ArraySort(returns);
    
    // Calculate VaR at confidence level
    int varIndex = (int)((100 - InpMC_Confidence) / 100.0 * InpMC_Simulations);
    mcVaR = returns[varIndex];
    
    // Calculate expected return
    double sum = 0;
    for(int i = 0; i < InpMC_Simulations; i++)
        sum += returns[i];
    mcExpectedReturn = sum / InpMC_Simulations;
    
    // Don't trade if expected return is negative
    if(signal == SIGNAL_BUY && mcExpectedReturn < 0)
        return false;
    if(signal == SIGNAL_SELL && mcExpectedReturn > 0)
        return false;
    
    return true;
}

//+------------------------------------------------------------------+
//| Initialize v7 Indicators                                         |
//+------------------------------------------------------------------+
void InitV7Indicators()
{
    if(InpUseTRIX)
        handleTRIX = iTriX(_Symbol, PERIOD_CURRENT, InpTRIX_Period, PRICE_CLOSE);
    
    if(InpUseAD)
        handleAD = iAD(_Symbol, PERIOD_CURRENT, VOLUME_TICK);
    
    ArraySetAsSeries(trixValue, true);
    ArraySetAsSeries(trixSignal, true);
    ArraySetAsSeries(viPlus, true);
    ArraySetAsSeries(viMinus, true);
    ArraySetAsSeries(adValue, true);
}

//+------------------------------------------------------------------+
//| Apply All v7 Filters                                             |
//+------------------------------------------------------------------+
bool ApplyV7Filters(ENUM_SIGNAL_TYPE signal)
{
    if(!CheckTRIXFilter(signal))
        return false;
    
    if(!CheckDPOFilter(signal))
        return false;
    
    if(!CheckKSTFilter(signal))
        return false;
    
    if(!CheckCoppockFilter(signal))
        return false;
    
    if(!CheckMassIndexFilter(signal))
        return false;
    
    if(!CheckVortexFilter(signal))
        return false;
    
    if(!CheckUltimateFilter(signal))
        return false;
    
    if(!CheckADFilter(signal))
        return false;
    
    if(!CheckRandomForestFilter(signal))
        return false;
    
    if(!CheckMonteCarloFilter(signal))
        return false;
    
    return true;
}

//+------------------------------------------------------------------+
//|              YENI v8 MODÜL FONKSIYONLARI (10 MODUL)              |
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//| Schaff Trend Cycle Filter                                        |
//+------------------------------------------------------------------+
bool CheckSTCFilter(ENUM_SIGNAL_TYPE signal)
{
    if(!InpUseSTC)
        return true;
    
    // Simplified STC calculation
    double macdVal = 0;
    for(int i = 0; i < InpSTC_Fast; i++)
        macdVal += iClose(_Symbol, PERIOD_CURRENT, i);
    macdVal /= InpSTC_Fast;
    
    double slowMA = 0;
    for(int i = 0; i < InpSTC_Slow; i++)
        slowMA += iClose(_Symbol, PERIOD_CURRENT, i);
    slowMA /= InpSTC_Slow;
    
    double diff = macdVal - slowMA;
    stcValue = 50 + (diff / atr[0]) * 10; // Normalized
    stcValue = MathMax(0, MathMin(100, stcValue));
    
    if(signal == SIGNAL_BUY && stcValue < 25)
        return false;
    if(signal == SIGNAL_SELL && stcValue > 75)
        return false;
    
    return true;
}

//+------------------------------------------------------------------+
//| Woodies CCI Filter                                               |
//+------------------------------------------------------------------+
bool CheckWoodiesFilter(ENUM_SIGNAL_TYPE signal)
{
    if(!InpUseWoodies)
        return true;
    
    // Calculate CCI
    double typicalPrice = (iHigh(_Symbol, PERIOD_CURRENT, 0) + 
                          iLow(_Symbol, PERIOD_CURRENT, 0) + 
                          iClose(_Symbol, PERIOD_CURRENT, 0)) / 3.0;
    
    double sma = 0, meanDev = 0;
    for(int i = 0; i < InpWoodies_CCI; i++)
    {
        double tp = (iHigh(_Symbol, PERIOD_CURRENT, i) + 
                    iLow(_Symbol, PERIOD_CURRENT, i) + 
                    iClose(_Symbol, PERIOD_CURRENT, i)) / 3.0;
        sma += tp;
    }
    sma /= InpWoodies_CCI;
    
    for(int i = 0; i < InpWoodies_CCI; i++)
    {
        double tp = (iHigh(_Symbol, PERIOD_CURRENT, i) + 
                    iLow(_Symbol, PERIOD_CURRENT, i) + 
                    iClose(_Symbol, PERIOD_CURRENT, i)) / 3.0;
        meanDev += MathAbs(tp - sma);
    }
    meanDev /= InpWoodies_CCI;
    
    woodiesCCI = meanDev != 0 ? (typicalPrice - sma) / (0.015 * meanDev) : 0;
    
    if(signal == SIGNAL_BUY && woodiesCCI < 0)
        return false;
    if(signal == SIGNAL_SELL && woodiesCCI > 0)
        return false;
    
    return true;
}

//+------------------------------------------------------------------+
//| Connors RSI Filter                                               |
//+------------------------------------------------------------------+
bool CheckConnorsFilter(ENUM_SIGNAL_TYPE signal)
{
    if(!InpUseConnors)
        return true;
    
    // Calculate short-term RSI
    double gains = 0, losses = 0;
    for(int i = 0; i < InpConnors_RSI; i++)
    {
        double change = iClose(_Symbol, PERIOD_CURRENT, i) - iClose(_Symbol, PERIOD_CURRENT, i + 1);
        if(change > 0) gains += change;
        else losses -= change;
    }
    
    double rsi1 = losses == 0 ? 100 : 100 - (100 / (1 + gains / losses));
    
    // Streak counting
    int streak = 0;
    for(int i = 0; i < 10; i++)
    {
        double change = iClose(_Symbol, PERIOD_CURRENT, i) - iClose(_Symbol, PERIOD_CURRENT, i + 1);
        if(change > 0) streak++;
        else break;
    }
    
    connorsRSI = (rsi1 + streak * 5 + 50) / 3; // Simplified composite
    
    if(signal == SIGNAL_BUY && connorsRSI < 25)
        return false;
    if(signal == SIGNAL_SELL && connorsRSI > 75)
        return false;
    
    return true;
}

//+------------------------------------------------------------------+
//| RVI (Relative Vigor Index) Filter                                |
//+------------------------------------------------------------------+
bool CheckRVIFilter(ENUM_SIGNAL_TYPE signal)
{
    if(!InpUseRVI)
        return true;
    
    if(CopyBuffer(handleRVI, 0, 0, 3, rviValue) < 3) return true;
    if(CopyBuffer(handleRVI, 1, 0, 3, rviSignal) < 3) return true;
    
    if(signal == SIGNAL_BUY && rviValue[0] < rviSignal[0])
        return false;
    if(signal == SIGNAL_SELL && rviValue[0] > rviSignal[0])
        return false;
    
    return true;
}

//+------------------------------------------------------------------+
//| SMI (Stochastic Momentum Index) Filter                           |
//+------------------------------------------------------------------+
bool CheckSMIFilter(ENUM_SIGNAL_TYPE signal)
{
    if(!InpUseSMI)
        return true;
    
    // Calculate SMI
    double highest = 0, lowest = 999999;
    for(int i = 0; i < InpSMI_K; i++)
    {
        double high = iHigh(_Symbol, PERIOD_CURRENT, i);
        double low = iLow(_Symbol, PERIOD_CURRENT, i);
        if(high > highest) highest = high;
        if(low < lowest) lowest = low;
    }
    
    double close = iClose(_Symbol, PERIOD_CURRENT, 0);
    double midpoint = (highest + lowest) / 2.0;
    double range = highest - lowest;
    
    smiValue = range != 0 ? ((close - midpoint) / (range / 2.0)) * 100 : 0;
    
    if(signal == SIGNAL_BUY && smiValue < -40)
        return false;
    if(signal == SIGNAL_SELL && smiValue > 40)
        return false;
    
    return true;
}

//+------------------------------------------------------------------+
//| TMF (Trend Momentum Force) Filter                                |
//+------------------------------------------------------------------+
bool CheckTMFFilter(ENUM_SIGNAL_TYPE signal)
{
    if(!InpUseTMF)
        return true;
    
    // Calculate composite TMF
    double sumTrend = 0, sumMomentum = 0;
    
    for(int i = 0; i < InpTMF_Period; i++)
    {
        double close = iClose(_Symbol, PERIOD_CURRENT, i);
        double closePrev = iClose(_Symbol, PERIOD_CURRENT, i + 1);
        
        sumTrend += close - closePrev;
        sumMomentum += MathAbs(close - closePrev);
    }
    
    tmfValue = sumMomentum != 0 ? (sumTrend / sumMomentum) * 100 : 0;
    
    if(signal == SIGNAL_BUY && tmfValue < 0)
        return false;
    if(signal == SIGNAL_SELL && tmfValue > 0)
        return false;
    
    return true;
}

//+------------------------------------------------------------------+
//| McGinley Dynamic Filter                                          |
//+------------------------------------------------------------------+
bool CheckMcGinleyFilter(ENUM_SIGNAL_TYPE signal)
{
    if(!InpUseMcGinley)
        return true;
    
    double close = iClose(_Symbol, PERIOD_CURRENT, 0);
    
    // McGinley Dynamic formula
    if(mcGinleyValue == 0)
        mcGinleyValue = close;
    
    mcGinleyPrev = mcGinleyValue;
    double ratio = close / mcGinleyValue;
    mcGinleyValue = mcGinleyValue + (close - mcGinleyValue) / 
                    (InpMcG_Period * MathPow(ratio, 4));
    
    if(signal == SIGNAL_BUY && close < mcGinleyValue)
        return false;
    if(signal == SIGNAL_SELL && close > mcGinleyValue)
        return false;
    
    return true;
}

//+------------------------------------------------------------------+
//| ALMA (Arnaud Legoux Moving Average) Filter                       |
//+------------------------------------------------------------------+
bool CheckALMAFilter(ENUM_SIGNAL_TYPE signal)
{
    if(!InpUseALMA)
        return true;
    
    // Calculate ALMA
    double sum = 0, wSum = 0;
    int m = (int)(InpALMA_Offset * (InpALMA_Period - 1));
    double s = InpALMA_Period / InpALMA_Sigma;
    
    for(int i = 0; i < InpALMA_Period; i++)
    {
        double w = MathExp(-1.0 * (i - m) * (i - m) / (2 * s * s));
        sum += iClose(_Symbol, PERIOD_CURRENT, InpALMA_Period - 1 - i) * w;
        wSum += w;
    }
    
    almaValue = wSum != 0 ? sum / wSum : iClose(_Symbol, PERIOD_CURRENT, 0);
    double close = iClose(_Symbol, PERIOD_CURRENT, 0);
    
    if(signal == SIGNAL_BUY && close < almaValue)
        return false;
    if(signal == SIGNAL_SELL && close > almaValue)
        return false;
    
    return true;
}

//+------------------------------------------------------------------+
//| Kaufman Efficiency Ratio Filter                                  |
//+------------------------------------------------------------------+
bool CheckKaufmanFilter(ENUM_SIGNAL_TYPE signal)
{
    if(!InpUseKaufman)
        return true;
    
    // Calculate Kaufman Efficiency Ratio
    double change = MathAbs(iClose(_Symbol, PERIOD_CURRENT, 0) - 
                           iClose(_Symbol, PERIOD_CURRENT, InpKauf_Period));
    
    double volatility = 0;
    for(int i = 0; i < InpKauf_Period; i++)
        volatility += MathAbs(iClose(_Symbol, PERIOD_CURRENT, i) - 
                             iClose(_Symbol, PERIOD_CURRENT, i + 1));
    
    kaufmanER = volatility != 0 ? change / volatility : 0;
    
    // Only trade when market is efficient (trending)
    if(kaufmanER < InpKauf_Threshold)
        return false;
    
    return true;
}

//+------------------------------------------------------------------+
//| Ehlers Fisher Transform Filter                                   |
//+------------------------------------------------------------------+
bool CheckEhlersFilter(ENUM_SIGNAL_TYPE signal)
{
    if(!InpUseEhlers)
        return true;
    
    // Calculate Fisher Transform
    double highest = 0, lowest = 999999;
    for(int i = 0; i < InpEhlers_Period; i++)
    {
        double high = iHigh(_Symbol, PERIOD_CURRENT, i);
        double low = iLow(_Symbol, PERIOD_CURRENT, i);
        if(high > highest) highest = high;
        if(low < lowest) lowest = low;
    }
    
    double close = iClose(_Symbol, PERIOD_CURRENT, 0);
    double range = highest - lowest;
    double value = range != 0 ? 2.0 * ((close - lowest) / range - 0.5) : 0;
    value = MathMax(-0.999, MathMin(0.999, value));
    
    fisherPrev = fisherValue;
    fisherValue = 0.5 * MathLog((1 + value) / (1 - value)) + 0.5 * fisherPrev;
    
    if(signal == SIGNAL_BUY && fisherValue < fisherPrev)
        return false;
    if(signal == SIGNAL_SELL && fisherValue > fisherPrev)
        return false;
    
    return true;
}

//+------------------------------------------------------------------+
//| Initialize v8 Indicators                                         |
//+------------------------------------------------------------------+
void InitV8Indicators()
{
    if(InpUseRVI)
        handleRVI = iRVI(_Symbol, PERIOD_CURRENT, InpRVI_Period);
    
    ArraySetAsSeries(rviValue, true);
    ArraySetAsSeries(rviSignal, true);
}

//+------------------------------------------------------------------+
//| Apply All v8 Filters                                             |
//+------------------------------------------------------------------+
bool ApplyV8Filters(ENUM_SIGNAL_TYPE signal)
{
    if(!CheckSTCFilter(signal))
        return false;
    
    if(!CheckWoodiesFilter(signal))
        return false;
    
    if(!CheckConnorsFilter(signal))
        return false;
    
    if(!CheckRVIFilter(signal))
        return false;
    
    if(!CheckSMIFilter(signal))
        return false;
    
    if(!CheckTMFFilter(signal))
        return false;
    
    if(!CheckMcGinleyFilter(signal))
        return false;
    
    if(!CheckALMAFilter(signal))
        return false;
    
    if(!CheckKaufmanFilter(signal))
        return false;
    
    if(!CheckEhlersFilter(signal))
        return false;
    
    return true;
}

//+------------------------------------------------------------------+
//|              YENI v9 MODÜL FONKSIYONLARI (10 MODUL)              |
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//| CMO (Chande Momentum Oscillator) Filter                          |
//+------------------------------------------------------------------+
bool CheckCMOFilter(ENUM_SIGNAL_TYPE signal)
{
    if(!InpUseCMO)
        return true;
    
    double sumUp = 0, sumDown = 0;
    for(int i = 0; i < InpCMO_Period; i++)
    {
        double change = iClose(_Symbol, PERIOD_CURRENT, i) - iClose(_Symbol, PERIOD_CURRENT, i + 1);
        if(change > 0) sumUp += change;
        else sumDown -= change;
    }
    
    cmoValue = (sumUp + sumDown) != 0 ? 100 * (sumUp - sumDown) / (sumUp + sumDown) : 0;
    
    if(signal == SIGNAL_BUY && cmoValue > InpCMO_Overbought)
        return false;
    if(signal == SIGNAL_SELL && cmoValue < InpCMO_Oversold)
        return false;
    
    return true;
}

//+------------------------------------------------------------------+
//| KVO (Klinger Volume Oscillator) Filter                           |
//+------------------------------------------------------------------+
bool CheckKVOFilter(ENUM_SIGNAL_TYPE signal)
{
    if(!InpUseKVO)
        return true;
    
    // Simplified KVO calculation
    double trend = 0;
    double hlc = (iHigh(_Symbol, PERIOD_CURRENT, 0) + iLow(_Symbol, PERIOD_CURRENT, 0) + iClose(_Symbol, PERIOD_CURRENT, 0)) / 3.0;
    double hlcPrev = (iHigh(_Symbol, PERIOD_CURRENT, 1) + iLow(_Symbol, PERIOD_CURRENT, 1) + iClose(_Symbol, PERIOD_CURRENT, 1)) / 3.0;
    
    if(hlc > hlcPrev) trend = 1;
    else trend = -1;
    
    double dm = iHigh(_Symbol, PERIOD_CURRENT, 0) - iLow(_Symbol, PERIOD_CURRENT, 0);
    kvoValue = trend * dm * iVolume(_Symbol, PERIOD_CURRENT, 0);
    
    if(signal == SIGNAL_BUY && kvoValue < 0)
        return false;
    if(signal == SIGNAL_SELL && kvoValue > 0)
        return false;
    
    return true;
}

//+------------------------------------------------------------------+
//| Twiggs Money Flow Filter                                         |
//+------------------------------------------------------------------+
bool CheckTwiggsFilter(ENUM_SIGNAL_TYPE signal)
{
    if(!InpUseTwiggs)
        return true;
    
    // Simplified Twiggs MF
    double trh = MathMax(iHigh(_Symbol, PERIOD_CURRENT, 0), iClose(_Symbol, PERIOD_CURRENT, 1));
    double trl = MathMin(iLow(_Symbol, PERIOD_CURRENT, 0), iClose(_Symbol, PERIOD_CURRENT, 1));
    double tr = trh - trl;
    
    double adv = ((iClose(_Symbol, PERIOD_CURRENT, 0) - trl) - (trh - iClose(_Symbol, PERIOD_CURRENT, 0))) / (tr != 0 ? tr : 1);
    twiggsValue = adv * iVolume(_Symbol, PERIOD_CURRENT, 0);
    
    if(signal == SIGNAL_BUY && twiggsValue < 0)
        return false;
    if(signal == SIGNAL_SELL && twiggsValue > 0)
        return false;
    
    return true;
}

//+------------------------------------------------------------------+
//| Linear Regression Channel Filter                                 |
//+------------------------------------------------------------------+
bool CheckLRCFilter(ENUM_SIGNAL_TYPE signal)
{
    if(!InpUseLRC)
        return true;
    
    // Calculate Linear Regression
    double sumX = 0, sumY = 0, sumXY = 0, sumX2 = 0;
    
    for(int i = 0; i < InpLRC_Period; i++)
    {
        sumX += i;
        sumY += iClose(_Symbol, PERIOD_CURRENT, i);
        sumXY += i * iClose(_Symbol, PERIOD_CURRENT, i);
        sumX2 += i * i;
    }
    
    double n = InpLRC_Period;
    double slope = (n * sumXY - sumX * sumY) / (n * sumX2 - sumX * sumX);
    double intercept = (sumY - slope * sumX) / n;
    
    lrcMiddle = intercept;
    
    // Calculate standard deviation
    double sumErr = 0;
    for(int i = 0; i < InpLRC_Period; i++)
    {
        double predicted = intercept + slope * i;
        sumErr += MathPow(iClose(_Symbol, PERIOD_CURRENT, i) - predicted, 2);
    }
    double stdDev = MathSqrt(sumErr / n);
    
    lrcUpper = lrcMiddle + stdDev * InpLRC_Deviation;
    lrcLower = lrcMiddle - stdDev * InpLRC_Deviation;
    
    double close = iClose(_Symbol, PERIOD_CURRENT, 0);
    
    if(signal == SIGNAL_BUY && close > lrcUpper)
        return false;
    if(signal == SIGNAL_SELL && close < lrcLower)
        return false;
    
    return true;
}

//+------------------------------------------------------------------+
//| Standard Error Bands Filter                                      |
//+------------------------------------------------------------------+
bool CheckSEBFilter(ENUM_SIGNAL_TYPE signal)
{
    if(!InpUseSEB)
        return true;
    
    // Calculate SEB
    double sum = 0;
    for(int i = 0; i < InpSEB_Period; i++)
        sum += iClose(_Symbol, PERIOD_CURRENT, i);
    sebMiddle = sum / InpSEB_Period;
    
    double sumErr = 0;
    for(int i = 0; i < InpSEB_Period; i++)
        sumErr += MathPow(iClose(_Symbol, PERIOD_CURRENT, i) - sebMiddle, 2);
    
    double stdErr = MathSqrt(sumErr / InpSEB_Period);
    
    sebUpper = sebMiddle + stdErr * InpSEB_Mult;
    sebLower = sebMiddle - stdErr * InpSEB_Mult;
    
    double close = iClose(_Symbol, PERIOD_CURRENT, 0);
    
    if(signal == SIGNAL_BUY && close > sebUpper)
        return false;
    if(signal == SIGNAL_SELL && close < sebLower)
        return false;
    
    return true;
}

//+------------------------------------------------------------------+
//| Percent B (%B) Filter                                            |
//+------------------------------------------------------------------+
bool CheckPercentBFilter(ENUM_SIGNAL_TYPE signal)
{
    if(!InpUsePercentB)
        return true;
    
    // Calculate Bollinger Bands %B
    double sum = 0;
    for(int i = 0; i < InpPercentB_Period; i++)
        sum += iClose(_Symbol, PERIOD_CURRENT, i);
    double middle = sum / InpPercentB_Period;
    
    double sumDev = 0;
    for(int i = 0; i < InpPercentB_Period; i++)
        sumDev += MathPow(iClose(_Symbol, PERIOD_CURRENT, i) - middle, 2);
    
    double stdDev = MathSqrt(sumDev / InpPercentB_Period);
    double upper = middle + stdDev * InpPercentB_Dev;
    double lower = middle - stdDev * InpPercentB_Dev;
    
    double close = iClose(_Symbol, PERIOD_CURRENT, 0);
    percentB = (upper - lower) != 0 ? (close - lower) / (upper - lower) : 0.5;
    
    if(signal == SIGNAL_BUY && percentB > 1.0)
        return false;
    if(signal == SIGNAL_SELL && percentB < 0.0)
        return false;
    
    return true;
}

//+------------------------------------------------------------------+
//| Elder Impulse System Filter                                      |
//+------------------------------------------------------------------+
bool CheckElderImpulseFilter(ENUM_SIGNAL_TYPE signal)
{
    if(!InpUseElderImpulse)
        return true;
    
    // Calculate EMA
    double ema0 = 0, ema1 = 0;
    double mult = 2.0 / (InpElder_EMA + 1);
    
    for(int i = InpElder_EMA - 1; i >= 0; i--)
    {
        if(i == InpElder_EMA - 1)
            ema0 = iClose(_Symbol, PERIOD_CURRENT, i);
        else
            ema0 = iClose(_Symbol, PERIOD_CURRENT, i) * mult + ema0 * (1 - mult);
    }
    
    for(int i = InpElder_EMA; i >= 1; i--)
    {
        if(i == InpElder_EMA)
            ema1 = iClose(_Symbol, PERIOD_CURRENT, i);
        else
            ema1 = iClose(_Symbol, PERIOD_CURRENT, i) * mult + ema1 * (1 - mult);
    }
    
    bool emaUp = ema0 > ema1;
    bool macdUp = ArraySize(macdHist) > 1 ? macdHist[0] > macdHist[1] : true;
    
    if(emaUp && macdUp) elderImpulse = 1;      // Green
    else if(!emaUp && !macdUp) elderImpulse = -1; // Red
    else elderImpulse = 0;                      // Blue
    
    if(signal == SIGNAL_BUY && elderImpulse == -1)
        return false;
    if(signal == SIGNAL_SELL && elderImpulse == 1)
        return false;
    
    return true;
}

//+------------------------------------------------------------------+
//| TTM Trend Filter                                                 |
//+------------------------------------------------------------------+
bool CheckTTMFilter(ENUM_SIGNAL_TYPE signal)
{
    if(!InpUseTTM)
        return true;
    
    // Calculate TTM Trend
    double avgHigh = 0, avgLow = 0;
    for(int i = 0; i < InpTTM_Period; i++)
    {
        avgHigh += iHigh(_Symbol, PERIOD_CURRENT, i);
        avgLow += iLow(_Symbol, PERIOD_CURRENT, i);
    }
    avgHigh /= InpTTM_Period;
    avgLow /= InpTTM_Period;
    double avgHL = (avgHigh + avgLow) / 2.0;
    
    double close = iClose(_Symbol, PERIOD_CURRENT, 0);
    ttmTrend = close > avgHL;
    
    if(signal == SIGNAL_BUY && !ttmTrend)
        return false;
    if(signal == SIGNAL_SELL && ttmTrend)
        return false;
    
    return true;
}

//+------------------------------------------------------------------+
//| Squeeze Pro Filter                                               |
//+------------------------------------------------------------------+
bool CheckSqueezeProFilter(ENUM_SIGNAL_TYPE signal)
{
    if(!InpUseSqueezePro)
        return true;
    
    // Calculate BB and KC for Squeeze Pro
    double sum = 0;
    for(int i = 0; i < InpSqPro_BB; i++)
        sum += iClose(_Symbol, PERIOD_CURRENT, i);
    double bbMid = sum / InpSqPro_BB;
    
    double sumDev = 0;
    for(int i = 0; i < InpSqPro_BB; i++)
        sumDev += MathPow(iClose(_Symbol, PERIOD_CURRENT, i) - bbMid, 2);
    double bbDev = MathSqrt(sumDev / InpSqPro_BB);
    
    double bbUpper = bbMid + bbDev * InpSqPro_BBMult;
    double bbLower = bbMid - bbDev * InpSqPro_BBMult;
    
    double atrVal = atr[0];
    double kc1Upper = bbMid + atrVal * InpSqPro_KC1;
    double kc2Upper = bbMid + atrVal * InpSqPro_KC2;
    double kc3Upper = bbMid + atrVal * InpSqPro_KC3;
    
    // Determine squeeze level
    squeezeProLevel = 0;
    if(bbLower > bbMid - atrVal * InpSqPro_KC1) squeezeProLevel = 1;
    if(bbLower > bbMid - atrVal * InpSqPro_KC2) squeezeProLevel = 2;
    if(bbLower > bbMid - atrVal * InpSqPro_KC3) squeezeProLevel = 3;
    
    // Don't trade during high squeeze
    if(squeezeProLevel >= 2)
        return false;
    
    return true;
}

//+------------------------------------------------------------------+
//| Neural Network Score Filter                                      |
//+------------------------------------------------------------------+
bool CheckNeuralFilter(ENUM_SIGNAL_TYPE signal)
{
    if(!InpUseNeural)
        return true;
    
    // Simulated Neural Network with multi-layer perceptron
    double inputs[10];
    
    // Input features
    inputs[0] = ma1[0] > ma3[0] ? 1.0 : -1.0;
    inputs[1] = ArraySize(rsi) > 0 ? (rsi[0] - 50) / 50.0 : 0;
    inputs[2] = atr[0] / iClose(_Symbol, PERIOD_CURRENT, 0) * 100;
    inputs[3] = (iClose(_Symbol, PERIOD_CURRENT, 0) - iClose(_Symbol, PERIOD_CURRENT, 5)) / atr[0];
    inputs[4] = InpUseVolume && CheckVolumeFilter() ? 1.0 : -1.0;
    inputs[5] = ArraySize(macdHist) > 0 ? macdHist[0] > 0 ? 1.0 : -1.0 : 0;
    inputs[6] = kaufmanER;
    inputs[7] = connorsRSI / 100.0;
    inputs[8] = smiValue / 100.0;
    inputs[9] = fisherValue;
    
    // Simple feed-forward network simulation
    double hidden[10];
    for(int j = 0; j < InpNN_Neurons && j < 10; j++)
    {
        hidden[j] = 0;
        for(int i = 0; i < 10; i++)
            hidden[j] += inputs[i] * (0.1 + 0.1 * (i * j % 5)); // Pseudo-weights
        hidden[j] = MathTanh(hidden[j]); // Activation
    }
    
    // Output layer
    nnScore = 0;
    for(int j = 0; j < InpNN_Neurons && j < 10; j++)
        nnScore += hidden[j] * (0.2 + 0.1 * (j % 3));
    nnScore = (MathTanh(nnScore) + 1) / 2; // Normalize to 0-1
    
    if(signal == SIGNAL_BUY && nnScore < InpNN_MinScore)
        return false;
    if(signal == SIGNAL_SELL && nnScore > (1 - InpNN_MinScore))
        return false;
    
    return true;
}

//+------------------------------------------------------------------+
//| Apply All v9 Filters                                             |
//+------------------------------------------------------------------+
bool ApplyV9Filters(ENUM_SIGNAL_TYPE signal)
{
    if(!CheckCMOFilter(signal))
        return false;
    
    if(!CheckKVOFilter(signal))
        return false;
    
    if(!CheckTwiggsFilter(signal))
        return false;
    
    if(!CheckLRCFilter(signal))
        return false;
    
    if(!CheckSEBFilter(signal))
        return false;
    
    if(!CheckPercentBFilter(signal))
        return false;
    
    if(!CheckElderImpulseFilter(signal))
        return false;
    
    if(!CheckTTMFilter(signal))
        return false;
    
    if(!CheckSqueezeProFilter(signal))
        return false;
    
    if(!CheckNeuralFilter(signal))
        return false;
    
    return true;
}

//+------------------------------------------------------------------+
//|              YENI v10 MODÜL FONKSIYONLARI (10 MODUL)             |
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//| DEMA (Double EMA) Filter                                         |
//+------------------------------------------------------------------+
bool CheckDEMAFilter(ENUM_SIGNAL_TYPE signal)
{
    if(!InpUseDEMA)
        return true;
    
    // Calculate DEMA = 2*EMA - EMA(EMA)
    double mult = 2.0 / (InpDEMA_Period + 1);
    double ema1 = 0, ema2 = 0;
    
    for(int i = InpDEMA_Period * 2; i >= 0; i--)
    {
        if(i == InpDEMA_Period * 2)
            ema1 = iClose(_Symbol, PERIOD_CURRENT, i);
        else
            ema1 = iClose(_Symbol, PERIOD_CURRENT, i) * mult + ema1 * (1 - mult);
    }
    
    for(int i = InpDEMA_Period * 2; i >= 0; i--)
    {
        if(i == InpDEMA_Period * 2)
            ema2 = ema1;
        else
            ema2 = ema1 * mult + ema2 * (1 - mult);
    }
    
    demaPrev = demaValue;
    demaValue = 2 * ema1 - ema2;
    double close = iClose(_Symbol, PERIOD_CURRENT, 0);
    
    if(signal == SIGNAL_BUY && close < demaValue)
        return false;
    if(signal == SIGNAL_SELL && close > demaValue)
        return false;
    
    return true;
}

//+------------------------------------------------------------------+
//| TEMA (Triple EMA) Filter                                         |
//+------------------------------------------------------------------+
bool CheckTEMAFilter(ENUM_SIGNAL_TYPE signal)
{
    if(!InpUseTEMA)
        return true;
    
    // Calculate TEMA = 3*EMA - 3*EMA(EMA) + EMA(EMA(EMA))
    double mult = 2.0 / (InpTEMA_Period + 1);
    double ema1 = 0, ema2 = 0, ema3 = 0;
    
    for(int i = InpTEMA_Period * 3; i >= 0; i--)
    {
        double close = iClose(_Symbol, PERIOD_CURRENT, i);
        if(i == InpTEMA_Period * 3)
        {
            ema1 = close;
            ema2 = close;
            ema3 = close;
        }
        else
        {
            ema1 = close * mult + ema1 * (1 - mult);
            ema2 = ema1 * mult + ema2 * (1 - mult);
            ema3 = ema2 * mult + ema3 * (1 - mult);
        }
    }
    
    temaPrev = temaValue;
    temaValue = 3 * ema1 - 3 * ema2 + ema3;
    double close = iClose(_Symbol, PERIOD_CURRENT, 0);
    
    if(signal == SIGNAL_BUY && close < temaValue)
        return false;
    if(signal == SIGNAL_SELL && close > temaValue)
        return false;
    
    return true;
}

//+------------------------------------------------------------------+
//| T3 Moving Average Filter                                         |
//+------------------------------------------------------------------+
bool CheckT3Filter(ENUM_SIGNAL_TYPE signal)
{
    if(!InpUseT3)
        return true;
    
    double v = InpT3_VFactor;
    double c1 = -v * v * v;
    double c2 = 3 * v * v + 3 * v * v * v;
    double c3 = -6 * v * v - 3 * v - 3 * v * v * v;
    double c4 = 1 + 3 * v + v * v * v + 3 * v * v;
    
    double mult = 2.0 / (InpT3_Period + 1);
    double e1 = 0, e2 = 0, e3 = 0, e4 = 0, e5 = 0, e6 = 0;
    
    for(int i = InpT3_Period * 6; i >= 0; i--)
    {
        double close = iClose(_Symbol, PERIOD_CURRENT, i);
        if(i == InpT3_Period * 6)
        {
            e1 = e2 = e3 = e4 = e5 = e6 = close;
        }
        else
        {
            e1 = close * mult + e1 * (1 - mult);
            e2 = e1 * mult + e2 * (1 - mult);
            e3 = e2 * mult + e3 * (1 - mult);
            e4 = e3 * mult + e4 * (1 - mult);
            e5 = e4 * mult + e5 * (1 - mult);
            e6 = e5 * mult + e6 * (1 - mult);
        }
    }
    
    t3Prev = t3Value;
    t3Value = c1 * e6 + c2 * e5 + c3 * e4 + c4 * e3;
    double close = iClose(_Symbol, PERIOD_CURRENT, 0);
    
    if(signal == SIGNAL_BUY && t3Value < t3Prev)
        return false;
    if(signal == SIGNAL_SELL && t3Value > t3Prev)
        return false;
    
    return true;
}

//+------------------------------------------------------------------+
//| FRAMA (Fractal Adaptive MA) Filter                               |
//+------------------------------------------------------------------+
bool CheckFRAMAFilter(ENUM_SIGNAL_TYPE signal)
{
    if(!InpUseFRAMA)
        return true;
    
    int halfPeriod = InpFRAMA_Period / 2;
    
    // Calculate fractal dimension
    double n1 = 0, n2 = 0, n3 = 0;
    double highest1 = 0, lowest1 = 999999;
    double highest2 = 0, lowest2 = 999999;
    double highest3 = 0, lowest3 = 999999;
    
    for(int i = 0; i < halfPeriod; i++)
    {
        double high = iHigh(_Symbol, PERIOD_CURRENT, i);
        double low = iLow(_Symbol, PERIOD_CURRENT, i);
        if(high > highest1) highest1 = high;
        if(low < lowest1) lowest1 = low;
    }
    n1 = (highest1 - lowest1) / halfPeriod;
    
    for(int i = halfPeriod; i < InpFRAMA_Period; i++)
    {
        double high = iHigh(_Symbol, PERIOD_CURRENT, i);
        double low = iLow(_Symbol, PERIOD_CURRENT, i);
        if(high > highest2) highest2 = high;
        if(low < lowest2) lowest2 = low;
    }
    n2 = (highest2 - lowest2) / halfPeriod;
    
    for(int i = 0; i < InpFRAMA_Period; i++)
    {
        double high = iHigh(_Symbol, PERIOD_CURRENT, i);
        double low = iLow(_Symbol, PERIOD_CURRENT, i);
        if(high > highest3) highest3 = high;
        if(low < lowest3) lowest3 = low;
    }
    n3 = (highest3 - lowest3) / InpFRAMA_Period;
    
    double dimen = (n1 > 0 && n2 > 0 && (n1 + n2) > 0 && n3 > 0) ? 
                   (MathLog(n1 + n2) - MathLog(n3)) / MathLog(2) : 1;
    double alpha = MathExp(-4.6 * (dimen - 1));
    alpha = MathMax(0.01, MathMin(1, alpha));
    
    framaPrev = framaValue;
    if(framaValue == 0) framaValue = iClose(_Symbol, PERIOD_CURRENT, 0);
    framaValue = alpha * iClose(_Symbol, PERIOD_CURRENT, 0) + (1 - alpha) * framaValue;
    double close = iClose(_Symbol, PERIOD_CURRENT, 0);
    
    if(signal == SIGNAL_BUY && close < framaValue)
        return false;
    if(signal == SIGNAL_SELL && close > framaValue)
        return false;
    
    return true;
}

//+------------------------------------------------------------------+
//| VIDYA (Variable Index Dynamic Average) Filter                    |
//+------------------------------------------------------------------+
bool CheckVIDYAFilter(ENUM_SIGNAL_TYPE signal)
{
    if(!InpUseVIDYA)
        return true;
    
    // Calculate CMO for VIDYA
    double sumUp = 0, sumDown = 0;
    for(int i = 0; i < InpVIDYA_CMO; i++)
    {
        double change = iClose(_Symbol, PERIOD_CURRENT, i) - iClose(_Symbol, PERIOD_CURRENT, i + 1);
        if(change > 0) sumUp += change;
        else sumDown -= change;
    }
    
    double cmo = (sumUp + sumDown) != 0 ? MathAbs(sumUp - sumDown) / (sumUp + sumDown) : 0;
    double sc = 2.0 / (InpVIDYA_MA + 1);
    double alpha = sc * cmo;
    
    vidyaPrev = vidyaValue;
    if(vidyaValue == 0) vidyaValue = iClose(_Symbol, PERIOD_CURRENT, 0);
    vidyaValue = alpha * iClose(_Symbol, PERIOD_CURRENT, 0) + (1 - alpha) * vidyaValue;
    double close = iClose(_Symbol, PERIOD_CURRENT, 0);
    
    if(signal == SIGNAL_BUY && close < vidyaValue)
        return false;
    if(signal == SIGNAL_SELL && close > vidyaValue)
        return false;
    
    return true;
}

//+------------------------------------------------------------------+
//| Zero Lag EMA Filter                                              |
//+------------------------------------------------------------------+
bool CheckZeroLagFilter(ENUM_SIGNAL_TYPE signal)
{
    if(!InpUseZeroLag)
        return true;
    
    // Calculate Zero Lag EMA
    double mult = 2.0 / (InpZL_Period + 1);
    int lag = (InpZL_Period - 1) / 2;
    
    double ema = 0;
    for(int i = InpZL_Period * 2; i >= 0; i--)
    {
        double close = iClose(_Symbol, PERIOD_CURRENT, i);
        double closeLag = iClose(_Symbol, PERIOD_CURRENT, i + lag);
        double src = 2 * close - closeLag;
        
        if(i == InpZL_Period * 2)
            ema = src;
        else
            ema = src * mult + ema * (1 - mult);
    }
    
    zeroLagPrev = zeroLagValue;
    zeroLagValue = ema;
    double close = iClose(_Symbol, PERIOD_CURRENT, 0);
    
    if(signal == SIGNAL_BUY && close < zeroLagValue)
        return false;
    if(signal == SIGNAL_SELL && close > zeroLagValue)
        return false;
    
    return true;
}

//+------------------------------------------------------------------+
//| Smoothed RSI Filter                                              |
//+------------------------------------------------------------------+
bool CheckSmoothRSIFilter(ENUM_SIGNAL_TYPE signal)
{
    if(!InpUseSmoothRSI)
        return true;
    
    // Calculate RSI values and smooth them
    double rsiValues[];
    ArrayResize(rsiValues, InpSRSI_Smooth);
    
    for(int j = 0; j < InpSRSI_Smooth; j++)
    {
        double gains = 0, losses = 0;
        for(int i = j; i < InpSRSI_Period + j; i++)
        {
            double change = iClose(_Symbol, PERIOD_CURRENT, i) - iClose(_Symbol, PERIOD_CURRENT, i + 1);
            if(change > 0) gains += change;
            else losses -= change;
        }
        rsiValues[j] = losses == 0 ? 100 : 100 - (100 / (1 + gains / losses));
    }
    
    smoothRSI = 0;
    for(int j = 0; j < InpSRSI_Smooth; j++)
        smoothRSI += rsiValues[j];
    smoothRSI /= InpSRSI_Smooth;
    
    if(signal == SIGNAL_BUY && smoothRSI > 70)
        return false;
    if(signal == SIGNAL_SELL && smoothRSI < 30)
        return false;
    
    return true;
}

//+------------------------------------------------------------------+
//| Stochastic RSI Filter                                            |
//+------------------------------------------------------------------+
bool CheckStochRSIFilter(ENUM_SIGNAL_TYPE signal)
{
    if(!InpUseStochRSI)
        return true;
    
    // Calculate RSI values
    double rsiVals[];
    ArrayResize(rsiVals, InpStRSI_Period);
    
    for(int j = 0; j < InpStRSI_Period; j++)
    {
        double gains = 0, losses = 0;
        for(int i = j; i < InpStRSI_Period + j; i++)
        {
            double change = iClose(_Symbol, PERIOD_CURRENT, i) - iClose(_Symbol, PERIOD_CURRENT, i + 1);
            if(change > 0) gains += change;
            else losses -= change;
        }
        rsiVals[j] = losses == 0 ? 100 : 100 - (100 / (1 + gains / losses));
    }
    
    // Find highest/lowest RSI
    double highestRSI = 0, lowestRSI = 100;
    for(int j = 0; j < InpStRSI_Period; j++)
    {
        if(rsiVals[j] > highestRSI) highestRSI = rsiVals[j];
        if(rsiVals[j] < lowestRSI) lowestRSI = rsiVals[j];
    }
    
    stochRSIK = (highestRSI - lowestRSI) != 0 ? 
                (rsiVals[0] - lowestRSI) / (highestRSI - lowestRSI) * 100 : 50;
    stochRSID = stochRSIK; // Simplified
    
    if(signal == SIGNAL_BUY && stochRSIK > 80)
        return false;
    if(signal == SIGNAL_SELL && stochRSIK < 20)
        return false;
    
    return true;
}

//+------------------------------------------------------------------+
//| ADR (Average Directional Rating) Filter                          |
//+------------------------------------------------------------------+
bool CheckADRFilter(ENUM_SIGNAL_TYPE signal)
{
    if(!InpUseADR)
        return true;
    
    // Calculate ADR (combined ADX metric)
    double sumDX = 0;
    
    for(int i = 0; i < InpADR_Period; i++)
    {
        double plusDM = iHigh(_Symbol, PERIOD_CURRENT, i) - iHigh(_Symbol, PERIOD_CURRENT, i + 1);
        double minusDM = iLow(_Symbol, PERIOD_CURRENT, i + 1) - iLow(_Symbol, PERIOD_CURRENT, i);
        double tr = MathMax(iHigh(_Symbol, PERIOD_CURRENT, i) - iLow(_Symbol, PERIOD_CURRENT, i),
                   MathMax(MathAbs(iHigh(_Symbol, PERIOD_CURRENT, i) - iClose(_Symbol, PERIOD_CURRENT, i + 1)),
                          MathAbs(iLow(_Symbol, PERIOD_CURRENT, i) - iClose(_Symbol, PERIOD_CURRENT, i + 1))));
        
        if(plusDM < 0) plusDM = 0;
        if(minusDM < 0) minusDM = 0;
        
        double plusDI = tr != 0 ? plusDM / tr * 100 : 0;
        double minusDI = tr != 0 ? minusDM / tr * 100 : 0;
        double diSum = plusDI + minusDI;
        double dx = diSum != 0 ? MathAbs(plusDI - minusDI) / diSum * 100 : 0;
        
        sumDX += dx;
    }
    
    adrValue = sumDX / InpADR_Period;
    
    // Only trade when ADR shows strong trend
    if(adrValue < 25)
        return false;
    
    return true;
}

//+------------------------------------------------------------------+
//| Trade Optimization Filter                                        |
//+------------------------------------------------------------------+
bool CheckTradeOptFilter(ENUM_SIGNAL_TYPE signal)
{
    if(!InpUseTradeOpt)
        return true;
    
    // Calculate recent win rate
    int wins = 0, total = 0;
    
    // Simulate backtest
    for(int i = 1; i < InpOpt_Lookback; i++)
    {
        double close1 = iClose(_Symbol, PERIOD_CURRENT, i);
        double close0 = iClose(_Symbol, PERIOD_CURRENT, i - 1);
        
        // Simple MA crossover simulation
        double ma1_1 = 0, ma1_2 = 0;
        for(int j = 0; j < 20; j++)
        {
            ma1_1 += iClose(_Symbol, PERIOD_CURRENT, i + j);
            ma1_2 += iClose(_Symbol, PERIOD_CURRENT, i + 1 + j);
        }
        ma1_1 /= 20;
        ma1_2 /= 20;
        
        if(close1 > ma1_1 && close0 > close1) // Simulated buy
        {
            total++;
            if(close0 > close1) wins++;
        }
    }
    
    optWinRate = total > 0 ? (double)wins / total : 0.5;
    
    if(optWinRate < InpOpt_MinWinRate)
        return false;
    
    return true;
}

//+------------------------------------------------------------------+
//| Apply All v10 Filters                                            |
//+------------------------------------------------------------------+
bool ApplyV10Filters(ENUM_SIGNAL_TYPE signal)
{
    if(!CheckDEMAFilter(signal))
        return false;
    
    if(!CheckTEMAFilter(signal))
        return false;
    
    if(!CheckT3Filter(signal))
        return false;
    
    if(!CheckFRAMAFilter(signal))
        return false;
    
    if(!CheckVIDYAFilter(signal))
        return false;
    
    if(!CheckZeroLagFilter(signal))
        return false;
    
    if(!CheckSmoothRSIFilter(signal))
        return false;
    
    if(!CheckStochRSIFilter(signal))
        return false;
    
    if(!CheckADRFilter(signal))
        return false;
    
    if(!CheckTradeOptFilter(signal))
        return false;
    
    return true;
}

//+------------------------------------------------------------------+
//|        FINAL v11 MODÜL FONKSIYONLARI (10 MODUL) - 108 TOTAL      |
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//| Envelopes Filter                                                 |
//+------------------------------------------------------------------+
bool CheckEnvelopesFilter(ENUM_SIGNAL_TYPE signal)
{
    if(!InpUseEnvelopes)
        return true;
    
    double sum = 0;
    for(int i = 0; i < InpEnv_Period; i++)
        sum += iClose(_Symbol, PERIOD_CURRENT, i);
    envMiddle = sum / InpEnv_Period;
    
    envUpper = envMiddle * (1 + InpEnv_Deviation / 100);
    envLower = envMiddle * (1 - InpEnv_Deviation / 100);
    
    double close = iClose(_Symbol, PERIOD_CURRENT, 0);
    
    if(signal == SIGNAL_BUY && close > envUpper)
        return false;
    if(signal == SIGNAL_SELL && close < envLower)
        return false;
    
    return true;
}

//+------------------------------------------------------------------+
//| Price Channel Filter                                             |
//+------------------------------------------------------------------+
bool CheckPriceChannelFilter(ENUM_SIGNAL_TYPE signal)
{
    if(!InpUsePriceChannel)
        return true;
    
    pcHigh = 0;
    pcLow = 999999;
    
    for(int i = 0; i < InpPC_Period; i++)
    {
        if(iHigh(_Symbol, PERIOD_CURRENT, i) > pcHigh) pcHigh = iHigh(_Symbol, PERIOD_CURRENT, i);
        if(iLow(_Symbol, PERIOD_CURRENT, i) < pcLow) pcLow = iLow(_Symbol, PERIOD_CURRENT, i);
    }
    
    double close = iClose(_Symbol, PERIOD_CURRENT, 0);
    double middle = (pcHigh + pcLow) / 2;
    
    if(signal == SIGNAL_BUY && close < middle)
        return false;
    if(signal == SIGNAL_SELL && close > middle)
        return false;
    
    return true;
}

//+------------------------------------------------------------------+
//| AO Divergence Filter                                             |
//+------------------------------------------------------------------+
bool CheckAODivFilter(ENUM_SIGNAL_TYPE signal)
{
    if(!InpUseAODiv)
        return true;
    
    // Check for divergence between price and AO
    double priceHigh1 = 0, priceHigh2 = 0;
    double aoHigh1 = 0, aoHigh2 = 0;
    
    for(int i = 0; i < InpAODiv_Bars / 2; i++)
        if(iHigh(_Symbol, PERIOD_CURRENT, i) > priceHigh1) priceHigh1 = iHigh(_Symbol, PERIOD_CURRENT, i);
    
    for(int i = InpAODiv_Bars / 2; i < InpAODiv_Bars; i++)
        if(iHigh(_Symbol, PERIOD_CURRENT, i) > priceHigh2) priceHigh2 = iHigh(_Symbol, PERIOD_CURRENT, i);
    
    // Simplified AO calculation
    aoHigh1 = (iHigh(_Symbol, PERIOD_CURRENT, 0) + iLow(_Symbol, PERIOD_CURRENT, 0)) / 2 - 
              (iHigh(_Symbol, PERIOD_CURRENT, 5) + iLow(_Symbol, PERIOD_CURRENT, 5)) / 2;
    aoHigh2 = (iHigh(_Symbol, PERIOD_CURRENT, InpAODiv_Bars/2) + iLow(_Symbol, PERIOD_CURRENT, InpAODiv_Bars/2)) / 2 - 
              (iHigh(_Symbol, PERIOD_CURRENT, InpAODiv_Bars/2 + 5) + iLow(_Symbol, PERIOD_CURRENT, InpAODiv_Bars/2 + 5)) / 2;
    
    // Bearish divergence: price higher high, AO lower high
    aoDiv = (priceHigh1 > priceHigh2 && aoHigh1 < aoHigh2);
    
    if(signal == SIGNAL_BUY && aoDiv)
        return false;
    
    return true;
}

//+------------------------------------------------------------------+
//| Williams Divergence Filter                                       |
//+------------------------------------------------------------------+
bool CheckWillDivFilter(ENUM_SIGNAL_TYPE signal)
{
    if(!InpUseWillDiv)
        return true;
    
    // Simple Williams %R divergence check
    double priceLow1 = 999999, priceLow2 = 999999;
    
    for(int i = 0; i < InpWillDiv_Bars / 2; i++)
        if(iLow(_Symbol, PERIOD_CURRENT, i) < priceLow1) priceLow1 = iLow(_Symbol, PERIOD_CURRENT, i);
    
    for(int i = InpWillDiv_Bars / 2; i < InpWillDiv_Bars; i++)
        if(iLow(_Symbol, PERIOD_CURRENT, i) < priceLow2) priceLow2 = iLow(_Symbol, PERIOD_CURRENT, i);
    
    // Bullish divergence: price lower low, indicator higher low
    willDiv = (priceLow1 < priceLow2);
    
    if(signal == SIGNAL_SELL && willDiv)
        return false;
    
    return true;
}

//+------------------------------------------------------------------+
//| CSI (Commodity Selection Index) Filter                           |
//+------------------------------------------------------------------+
bool CheckCSIFilter(ENUM_SIGNAL_TYPE signal)
{
    if(!InpUseCSI)
        return true;
    
    // CSI = ADXR * ATR(14) / sqrt(margin)
    double adxr = adrValue; // Using ADR as proxy
    double atrVal = atr[0];
    
    csiValue = adxr * (atrVal / iClose(_Symbol, PERIOD_CURRENT, 0)) * 1000;
    
    if(csiValue < InpCSI_Min)
        return false;
    
    return true;
}

//+------------------------------------------------------------------+
//| Trade Statistics Filter                                          |
//+------------------------------------------------------------------+
bool CheckTradeStatsFilter(ENUM_SIGNAL_TYPE signal)
{
    if(!InpUseTradeStats)
        return true;
    
    // Use global win/loss tracking
    int totalStats = statsWins + statsLosses;
    
    if(totalStats < InpStats_MinTrades)
        return true; // Not enough data
    
    double currentWinRate = (double)statsWins / totalStats;
    
    if(currentWinRate < InpStats_MinWin)
        return false;
    
    return true;
}

//+------------------------------------------------------------------+
//| Equity Guard Filter                                              |
//+------------------------------------------------------------------+
bool CheckEquityGuardFilter()
{
    if(!InpUseEquityGuard)
        return true;
    
    double equity = AccountInfoDouble(ACCOUNT_EQUITY);
    double balance = AccountInfoDouble(ACCOUNT_BALANCE);
    
    double dd = balance > 0 ? (balance - equity) / balance * 100 : 0;
    
    // Check daily drawdown
    MqlDateTime dt;
    TimeCurrent(dt);
    static int lastDay = -1;
    static double dayStartEquity = 0;
    
    if(dt.day != lastDay)
    {
        lastDay = dt.day;
        dayStartEquity = equity;
    }
    
    egDailyDD = dayStartEquity > 0 ? (dayStartEquity - equity) / dayStartEquity * 100 : 0;
    
    if(dd > InpEG_MaxDD || egDailyDD > InpEG_DailyMax)
        return false;
    
    return true;
}

//+------------------------------------------------------------------+
//| Smart Exit Management                                            |
//+------------------------------------------------------------------+
void ApplySmartExit()
{
    if(!InpUseSmartExit)
        return;
    
    for(int i = PositionsTotal() - 1; i >= 0; i--)
    {
        if(posInfo.SelectByIndex(i))
        {
            if(posInfo.Symbol() == _Symbol && posInfo.Magic() == InpMagicNumber)
            {
                double profit = posInfo.Profit();
                double openPrice = posInfo.PriceOpen();
                double currentPrice = posInfo.PriceCurrent();
                double atrVal = atr[0];
                
                // Move to breakeven
                if(profit > 0 && posInfo.StopLoss() == 0)
                {
                    if(posInfo.PositionType() == POSITION_TYPE_BUY)
                    {
                        if(currentPrice - openPrice > atrVal * InpSE_BreakEven)
                            trade.PositionModify(posInfo.Ticket(), openPrice, posInfo.TakeProfit());
                    }
                    else
                    {
                        if(openPrice - currentPrice > atrVal * InpSE_BreakEven)
                            trade.PositionModify(posInfo.Ticket(), openPrice, posInfo.TakeProfit());
                    }
                }
            }
        }
    }
}

//+------------------------------------------------------------------+
//| TSI (True Strength Index) Filter                                 |
//+------------------------------------------------------------------+
bool CheckTSIFilter(ENUM_SIGNAL_TYPE signal)
{
    if(!InpUseTSI)
        return true;
    
    // Calculate TSI
    double pcSum = 0, apcSum = 0;
    
    for(int i = 0; i < InpTSI_Long; i++)
    {
        double change = iClose(_Symbol, PERIOD_CURRENT, i) - iClose(_Symbol, PERIOD_CURRENT, i + 1);
        pcSum += change;
        apcSum += MathAbs(change);
    }
    
    tsiValue = apcSum != 0 ? (pcSum / apcSum) * 100 : 0;
    tsiSignal = tsiValue * 0.8; // Simplified signal
    
    if(signal == SIGNAL_BUY && tsiValue < tsiSignal)
        return false;
    if(signal == SIGNAL_SELL && tsiValue > tsiSignal)
        return false;
    
    return true;
}

//+------------------------------------------------------------------+
//| Final Optimizer Filter                                           |
//+------------------------------------------------------------------+
bool CheckFinalOptFilter(ENUM_SIGNAL_TYPE signal)
{
    if(!InpUseFinalOpt)
        return true;
    
    // Calculate composite optimization score
    double scores[10];
    int scoreCount = 0;
    
    // Score based on various indicators
    scores[scoreCount++] = ma1[0] > ma3[0] ? 1.0 : 0.0;
    scores[scoreCount++] = ArraySize(rsi) > 0 && rsi[0] > 50 ? 1.0 : 0.0;
    scores[scoreCount++] = atr[0] > atr[1] ? 1.0 : 0.0;
    scores[scoreCount++] = kaufmanER > 0.5 ? 1.0 : 0.0;
    scores[scoreCount++] = tsiValue > 0 ? 1.0 : 0.0;
    
    finalOptScore = 0;
    for(int i = 0; i < scoreCount; i++)
        finalOptScore += scores[i];
    finalOptScore /= scoreCount;
    
    if(signal == SIGNAL_BUY && finalOptScore < 0.5)
        return false;
    if(signal == SIGNAL_SELL && finalOptScore > 0.5)
        return false;
    
    return true;
}

//+------------------------------------------------------------------+
//| Apply All v11 Filters                                            |
//+------------------------------------------------------------------+
bool ApplyV11Filters(ENUM_SIGNAL_TYPE signal)
{
    if(!CheckEnvelopesFilter(signal))
        return false;
    
    if(!CheckPriceChannelFilter(signal))
        return false;
    
    if(!CheckAODivFilter(signal))
        return false;
    
    if(!CheckWillDivFilter(signal))
        return false;
    
    if(!CheckCSIFilter(signal))
        return false;
    
    if(!CheckTradeStatsFilter(signal))
        return false;
    
    if(!CheckEquityGuardFilter())
        return false;
    
    if(!CheckTSIFilter(signal))
        return false;
    
    if(!CheckFinalOptFilter(signal))
        return false;
    
    return true;
}

//+------------------------------------------------------------------+
//|        SUPER v12 MODÜL FONKSIYONLARI (10 MODUL) - 118 TOTAL      |
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//| KAMA (Kaufman Adaptive MA) Filter                                |
//+------------------------------------------------------------------+
bool CheckKAMAFilter(ENUM_SIGNAL_TYPE signal)
{
    if(!InpUseKAMA)
        return true;
    
    // Calculate Efficiency Ratio
    double change = MathAbs(iClose(_Symbol, PERIOD_CURRENT, 0) - 
                           iClose(_Symbol, PERIOD_CURRENT, InpKAMA_Period));
    
    double volatility = 0;
    for(int i = 0; i < InpKAMA_Period; i++)
        volatility += MathAbs(iClose(_Symbol, PERIOD_CURRENT, i) - 
                             iClose(_Symbol, PERIOD_CURRENT, i + 1));
    
    double er = volatility != 0 ? change / volatility : 0;
    
    // Calculate smoothing constant
    double fastSC = 2.0 / (InpKAMA_Fast + 1);
    double slowSC = 2.0 / (InpKAMA_Slow + 1);
    double sc = MathPow(er * (fastSC - slowSC) + slowSC, 2);
    
    kamaPrev = kamaValue;
    if(kamaValue == 0) kamaValue = iClose(_Symbol, PERIOD_CURRENT, 0);
    kamaValue = kamaValue + sc * (iClose(_Symbol, PERIOD_CURRENT, 0) - kamaValue);
    
    double close = iClose(_Symbol, PERIOD_CURRENT, 0);
    
    if(signal == SIGNAL_BUY && close < kamaValue)
        return false;
    if(signal == SIGNAL_SELL && close > kamaValue)
        return false;
    
    return true;
}

//+------------------------------------------------------------------+
//| RMI (Relative Momentum Index) Filter                             |
//+------------------------------------------------------------------+
bool CheckRMIFilter(ENUM_SIGNAL_TYPE signal)
{
    if(!InpUseRMI)
        return true;
    
    double gains = 0, losses = 0;
    
    for(int i = 0; i < InpRMI_Period; i++)
    {
        double change = iClose(_Symbol, PERIOD_CURRENT, i) - 
                       iClose(_Symbol, PERIOD_CURRENT, i + InpRMI_Momentum);
        if(change > 0) gains += change;
        else losses -= change;
    }
    
    rmiValue = (gains + losses) != 0 ? 
               100 * gains / (gains + losses) : 50;
    
    if(signal == SIGNAL_BUY && rmiValue < 30)
        return false;
    if(signal == SIGNAL_SELL && rmiValue > 70)
        return false;
    
    return true;
}

//+------------------------------------------------------------------+
//| SMI Ergodic Filter                                               |
//+------------------------------------------------------------------+
bool CheckSMIErgFilter(ENUM_SIGNAL_TYPE signal)
{
    if(!InpUseSMIErg)
        return true;
    
    // Calculate SMI Ergodic (simplified)
    double sumPC = 0, sumAPC = 0;
    
    for(int i = 0; i < InpSMIErg_R; i++)
    {
        double pc = iClose(_Symbol, PERIOD_CURRENT, i) - iClose(_Symbol, PERIOD_CURRENT, i + 1);
        sumPC += pc;
        sumAPC += MathAbs(pc);
    }
    
    smiErgValue = sumAPC != 0 ? (sumPC / sumAPC) * 100 : 0;
    smiErgSignal = smiErgValue * 0.8;
    
    if(signal == SIGNAL_BUY && smiErgValue < smiErgSignal)
        return false;
    if(signal == SIGNAL_SELL && smiErgValue > smiErgSignal)
        return false;
    
    return true;
}

//+------------------------------------------------------------------+
//| Choppiness Index Filter                                          |
//+------------------------------------------------------------------+
bool CheckChopFilter(ENUM_SIGNAL_TYPE signal)
{
    if(!InpUseChop)
        return true;
    
    // Calculate Choppiness Index
    double sumATR = 0;
    double highest = 0, lowest = 999999;
    
    for(int i = 0; i < InpChop_Period; i++)
    {
        double tr = MathMax(iHigh(_Symbol, PERIOD_CURRENT, i) - iLow(_Symbol, PERIOD_CURRENT, i),
                   MathMax(MathAbs(iHigh(_Symbol, PERIOD_CURRENT, i) - iClose(_Symbol, PERIOD_CURRENT, i + 1)),
                          MathAbs(iLow(_Symbol, PERIOD_CURRENT, i) - iClose(_Symbol, PERIOD_CURRENT, i + 1))));
        sumATR += tr;
        
        if(iHigh(_Symbol, PERIOD_CURRENT, i) > highest) highest = iHigh(_Symbol, PERIOD_CURRENT, i);
        if(iLow(_Symbol, PERIOD_CURRENT, i) < lowest) lowest = iLow(_Symbol, PERIOD_CURRENT, i);
    }
    
    double range = highest - lowest;
    chopIndex = range > 0 ? 100 * MathLog10(sumATR / range) / MathLog10(InpChop_Period) : 50;
    
    // High chop = range, low chop = trend
    if(chopIndex > InpChop_High)
        return false; // Don't trade in choppy market
    
    return true;
}

//+------------------------------------------------------------------+
//| QQE (Quantitative Qualitative Estimation) Filter                 |
//+------------------------------------------------------------------+
bool CheckQQEFilter(ENUM_SIGNAL_TYPE signal)
{
    if(!InpUseQQE)
        return true;
    
    // Calculate RSI
    double gains = 0, losses = 0;
    for(int i = 0; i < InpQQE_RSI; i++)
    {
        double change = iClose(_Symbol, PERIOD_CURRENT, i) - iClose(_Symbol, PERIOD_CURRENT, i + 1);
        if(change > 0) gains += change;
        else losses -= change;
    }
    double rsiVal = losses == 0 ? 100 : 100 - (100 / (1 + gains / losses));
    
    qqeValue = rsiVal;
    qqeLine = 50 + (rsiVal - 50) * 0.5;
    
    if(signal == SIGNAL_BUY && qqeValue < qqeLine)
        return false;
    if(signal == SIGNAL_SELL && qqeValue > qqeLine)
        return false;
    
    return true;
}

//+------------------------------------------------------------------+
//| SSL Channel Filter                                               |
//+------------------------------------------------------------------+
bool CheckSSLFilter(ENUM_SIGNAL_TYPE signal)
{
    if(!InpUseSSL)
        return true;
    
    // Calculate SSL Channel (SMA High/Low)
    double smaHigh = 0, smaLow = 0;
    
    for(int i = 0; i < InpSSL_Period; i++)
    {
        smaHigh += iHigh(_Symbol, PERIOD_CURRENT, i);
        smaLow += iLow(_Symbol, PERIOD_CURRENT, i);
    }
    smaHigh /= InpSSL_Period;
    smaLow /= InpSSL_Period;
    
    double close = iClose(_Symbol, PERIOD_CURRENT, 0);
    
    if(close > smaHigh)
    {
        sslUp = smaHigh;
        sslDown = smaLow;
    }
    else if(close < smaLow)
    {
        sslUp = smaLow;
        sslDown = smaHigh;
    }
    
    if(signal == SIGNAL_BUY && close < sslUp)
        return false;
    if(signal == SIGNAL_SELL && close > sslDown)
        return false;
    
    return true;
}

//+------------------------------------------------------------------+
//| Half Trend Filter                                                |
//+------------------------------------------------------------------+
bool CheckHalfTrendFilter(ENUM_SIGNAL_TYPE signal)
{
    if(!InpUseHalfTrend)
        return true;
    
    double atrVal = atr[0] * InpHT_Amplitude;
    double close = iClose(_Symbol, PERIOD_CURRENT, 0);
    double prevClose = iClose(_Symbol, PERIOD_CURRENT, 1);
    
    // Simplified Half Trend
    double avgHL = (iHigh(_Symbol, PERIOD_CURRENT, 0) + iLow(_Symbol, PERIOD_CURRENT, 0)) / 2.0;
    
    if(close > avgHL + atrVal) htTrend = true;
    else if(close < avgHL - atrVal) htTrend = false;
    
    if(signal == SIGNAL_BUY && !htTrend)
        return false;
    if(signal == SIGNAL_SELL && htTrend)
        return false;
    
    return true;
}

//+------------------------------------------------------------------+
//| Waddah Attar Explosion Filter                                    |
//+------------------------------------------------------------------+
bool CheckWaddahFilter(ENUM_SIGNAL_TYPE signal)
{
    if(!InpUseWaddah)
        return true;
    
    // Calculate MACD-style explosion
    double fastMA = 0, slowMA = 0;
    
    for(int i = 0; i < InpWaddah_Fast; i++)
        fastMA += iClose(_Symbol, PERIOD_CURRENT, i);
    fastMA /= InpWaddah_Fast;
    
    for(int i = 0; i < InpWaddah_Slow; i++)
        slowMA += iClose(_Symbol, PERIOD_CURRENT, i);
    slowMA /= InpWaddah_Slow;
    
    waddahValue = (fastMA - slowMA) * InpWaddah_Sens;
    waddahExp = atr[0] * InpWaddah_Sens / 10;
    
    // Explosion condition
    if(MathAbs(waddahValue) < waddahExp)
        return false; // No explosion
    
    if(signal == SIGNAL_BUY && waddahValue < 0)
        return false;
    if(signal == SIGNAL_SELL && waddahValue > 0)
        return false;
    
    return true;
}

//+------------------------------------------------------------------+
//| Risk/Reward Calculator Filter                                    |
//+------------------------------------------------------------------+
bool CheckRRFilter(ENUM_SIGNAL_TYPE signal)
{
    if(!InpUseRR)
        return true;
    
    double close = iClose(_Symbol, PERIOD_CURRENT, 0);
    double atrVal = atr[0];
    
    double potentialReward = atrVal * InpAtr_SL_Mult * 2; // Assuming 2x TP
    double potentialRisk = atrVal * InpAtr_SL_Mult;
    
    rrRatio = potentialRisk > 0 ? potentialReward / potentialRisk : 0;
    
    if(rrRatio < InpRR_MinRatio)
        return false;
    
    return true;
}

//+------------------------------------------------------------------+
//| Ultimate Trading Score Filter                                    |
//+------------------------------------------------------------------+
bool CheckUltScoreFilter(ENUM_SIGNAL_TYPE signal)
{
    if(!InpUseUltScore)
        return true;
    
    // Calculate comprehensive trading score (0-100)
    double score = 50;
    int factors = 0;
    
    // Trend factors
    if(ma1[0] > ma3[0]) score += 5; else score -= 5; factors++;
    if(kamaValue > kamaPrev) score += 5; else score -= 5; factors++;
    
    // Momentum factors
    if(ArraySize(rsi) > 0 && rsi[0] > 50) score += 5; else score -= 5; factors++;
    if(rmiValue > 50) score += 5; else score -= 5; factors++;
    if(tsiValue > 0) score += 5; else score -= 5; factors++;
    
    // Volatility factors
    if(chopIndex < InpChop_High) score += 5; else score -= 5; factors++;
    if(atr[0] > atr[1]) score += 3; else score -= 3; factors++;
    
    // Volume/Flow factors
    if(smiErgValue > smiErgSignal) score += 5; else score -= 5; factors++;
    
    // Trend confirmation
    if(htTrend && signal == SIGNAL_BUY) score += 5; factors++;
    if(!htTrend && signal == SIGNAL_SELL) score += 5; factors++;
    
    ultScore = MathMax(0, MathMin(100, score));
    
    if(signal == SIGNAL_BUY && ultScore < InpUS_MinScore)
        return false;
    if(signal == SIGNAL_SELL && ultScore < InpUS_MinScore)
        return false;
    
    return true;
}

//+------------------------------------------------------------------+
//| Apply All v12 Filters                                            |
//+------------------------------------------------------------------+
bool ApplyV12Filters(ENUM_SIGNAL_TYPE signal)
{
    if(!CheckKAMAFilter(signal))
        return false;
    
    if(!CheckRMIFilter(signal))
        return false;
    
    if(!CheckSMIErgFilter(signal))
        return false;
    
    if(!CheckChopFilter(signal))
        return false;
    
    if(!CheckQQEFilter(signal))
        return false;
    
    if(!CheckSSLFilter(signal))
        return false;
    
    if(!CheckHalfTrendFilter(signal))
        return false;
    
    if(!CheckWaddahFilter(signal))
        return false;
    
    if(!CheckRRFilter(signal))
        return false;
    
    if(!CheckUltScoreFilter(signal))
        return false;
    
    return true;
}
//+------------------------------------------------------------------+
