/************************************************************************
   SAMPLE EXPERT
   
   
                                  
************************************************************************/
#property copyright "Enrico Lambino"
#property link      "www.cyberforexworks.com"

#include <traderjet\core\expert.mqh>

#include <traderjet\component\virtualstop\var.mqh>
#include <traderjet\common\signal\var.mqh>

extern double  Lots = 0.1;
extern double  StopLoss = 200;
extern double  TakeProfit = 200;
extern double  SlippageEntry = 5;
extern double  SlippageExit = 5;

#include <traderjet\param\nopending.mqh>

extern int     Magic   = 12345;
extern int     TradeRetryMax = 1;

int     TradeSleepSuccess = 500;
int     TradeSleepError = 500;

extern int     TimeFrame = 0;
extern string  TradeComment = "";
extern int     TradeMax = 20;
extern bool    TradeLongEnabled = true;
extern bool    TradeShortEnabled = true;

extern double MinProfit = 10; //$10
extern string CurrencyPairList = "EURUSD,GBPUSD,USDJPY,NZDJPY"; //$10

color   TradeArrowColorLong = Blue;
color   TradeArrowColorShort = Red;
color   TradeArrowColorLongMod = CLR_NONE;
color   TradeArrowColorShortMod = CLR_NONE;
color   TradeArrowColorLongExit = CLR_NONE;
color   TradeArrowColorShortExit = CLR_NONE;

extern bool    SignalModeReverse = false;
extern bool    SignalModeEveryTick = true;
extern bool    SignalModeTradeOncePerBar = false;
extern bool    SignalExitOpposite = true;
extern int     SignalShift = 1;

extern int     StealthModeStopLoss = 1;
extern int     StealthModeTakeProfit = 1;

extern double  TrailingStopLossValue = 10;
extern double  TrailingStopLossStart = 10;
extern double  TrailingStopLossStep = 10;

int      dashCorner = 0;
int      dashX = 5,
         dashY = 25,     
         dashXSpacing = 0,
         dashYSpacing = 15;
int      dashFontSize = 8,
         dashXOffset = 150;
string   dashFont = "Arial";
color    dashTermColor = Gray,
         dashValueColor = Gray;
               
#include <traderjet\common\signal\methods.mqh>
#include <traderjet\component\virtualstop\methods.mqh>
#include <traderjet\module\trailingstop\methods.mqh>
#include <traderjet\module\dash_ea\methods.mqh>

string curr[20];
/************************************************************************
   EXPERT EVENTS                                 
************************************************************************/
int onInit()   {
   TraderJet();
   symbolSet();
   #include <traderjet\config\var\default.mqh>   
   #include <traderjet\config\init\default.mqh>   
   vstopInit(StealthModeStopLoss,StealthModeTakeProfit);
   dashEACreate(); 
   Print("Currencies to trade on: ",CurrencyPairList);
   stringToArray(CurrencyPairList,curr);   
}

int onDeInit() {
   #include <traderjet\config\deinit\default.mqh>
   return(0);
}

int onTick()   {
   symbolGet();
   int signalEntry = signalEntry();   
   int signalExit = signalExit();   
   signalManage(signalEntry,signalExit);  
   dashEAMainAdd();    
   tradeExit(signalExit);
   
   //tradeOpen(signalEntry);   
   
   for (int i=0;i<ArraySize(curr);i++) {
      string s = curr[i];
      if (s=="") continue;      
      symbolSet(s);
      symbolGet();
      tradeOpen(signalEntry);
   }
   
   orderLoop(Magic,CMD_ALL);
   orderLoopHistory(3);
   dashEAUpdate();
   return(lastError);
}

int onTrade()  {
   Print("onTrade(): ","trade entered: #"+orderTicket);
   return(0);
}

int onTradeModify()  {
   Print("onTradeModify(): ","trade entered: #"+orderTicket);
   return(0);
}

int onTradeClose()  {
   Print("onTradeClose(): ","trade exited: #"+orderTicket);
   return(0);
}

int onTradeReverse()  {
   Print("onTradeReverse(): ","position reversed");
   return(0);
}

/************************************************************************
   EXPERT INITIALIZATION FUNCTION                                  
************************************************************************/
int init()  {
   onInit(); 
   return(0);
  }
/************************************************************************
   EXPERT DEINITIALIZATION FUNCTION                               
************************************************************************/
int deinit()  {
   onDeInit();   
   return(0);
  }
/************************************************************************
   EXPERT START FUNCTION                                   
************************************************************************/
int start()  {
   static int run = true;   
   if (!run) return(0);
   if  (errorCheckCritical(onTick()))  {
      Print("errorCheckCritical(): ","critical error "+lastError);
      run = false;
   }     
   return(0);
  }
/************************************************************************
   EXPERT TRADE FUNCTIONS                                   
************************************************************************/
void tradeInit(int& cmd)  {
   return;
}

void tradeDeInit(int& cmd,int& ticket)   {
   return;   
}

int tradeOpen(int signal) {
   if (signal<=0) return;
   int ticket,total = orderCount();   
   if (!signalIsEnabled(signal)) return(ticket);
   int cmd = signalToCMD(signal);
   int cmdreverse = cmdReverse(cmd);   
   tradeInit(cmd); 
   if (SignalExitOpposite && total>0) {
      string direction = signalText(signal,true);      
      Print("SignalExitOpposite(): ","preparing to close "+direction+" orders");
      orderCloseAll(signalReverse(signal));
      onTradeReverse();
   }   
   
   if (serverEntryEnabled)   {
      total = orderCount();    
      if (TradeMax>total) 
         ticket = cOrderSend(cmd,Lots,TradePrice,StopLoss,TakeProfit,TradeComment,TradeExpiration);      
   } 
   tradeDeInit(cmd,ticket);
   return(ticket);
}
//**************************************************************************
void tradeExit(int signal) {
   if (signal==0) return;
   string direction = signalText(signal,true);
   Print("tradeExit(): ","preparing to close "+direction+" orders");
   orderCloseAll(signalReverse(signal));
}
//**************************************************************************
int signalExit()   {   
   filterInit(filterExitNum);
   int signal = CMD_NEUTRAL;
   signal = signalFilter(signalExitArray);
   return(signal); 
}

int filterProfitGlobal()   {
   int signal = CMD_NEUTRAL;   
   int total = ordersTotal();
   double profit;
   for (int i=0;i<total;i++)  {
      if (!cOrderSelect(i)) continue;
      profit += orderProfit();
   }
   
   if (profit>=MinProfit) signal = CMD_SHORT;  
   
   //dashEAAdd("exit filter","exit filter",signalText(signal)); 
   dashEAAdd("orders profit","orders profit",doubleToStr(profit,2)); 
   return(signal);
}

//**************************************************************************
int signalEntry()   {   
   filterInit(filterEntryNum);
   int signal = CMD_VOID;
   if (true) filterAdd(filterEnt(),signalEntryArray,filterEntryNum);
   signal = signalFilter(signalEntryArray);
   return(signal); 
}

int filterEnt()   {
   int signal = CMD_VOID;   
   int rand = mathRandS();
   //Print(rand," ",orderCount());
   if (orderCount()==0) {      
      if (rand<32767/2) signal = CMD_LONG;
      else signal = CMD_SHORT;
   }
   dashEAAdd("entry","entry",signalText(signal)); 
   return(signal);
}
//**************************************************************************
void loopOrderTasks() {  
   orderCheckEntry();
   vstopSet(vstopStandardName,StopLoss,TakeProfit);   
   trailingStopLoss(vstopStandardName,TrailingStopLossStart,TrailingStopLossStep,TrailingStopLossValue);   
   vstopAdjust(vstopStandardName);
   vstopCheck(vstopStandardName);      
   //vstopSet("p1",50,50);
   //vstopCheck("p1",0.1);   
   //vstopSet("p2",100,100);
   //vstopCheck("p2",0.1);
}

void loopOrderHistoryTasks()  {   
   orderCheckClose();
   vstopClean(vstopStandardName);
   //vstopClean("p1");
   //vstopClean("p2");
}
//**************************************************************************