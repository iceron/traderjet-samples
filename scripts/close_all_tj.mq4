//+------------------------------------------------------------------+
//|                                                 close_all_tj.mq4 |
//|                        Copyright 2013, MetaQuotes Software Corp. |
//|                                        http://www.metaquotes.net |
//+------------------------------------------------------------------+
#property copyright "Copyright 2013, MetaQuotes Software Corp."
#property link      "http://www.metaquotes.net"

#include <traderjet\core\script.mqh>
#include <traderjet\common\trade\open.mqh>
#include <traderjet\common\trade\close.mqh>

//+------------------------------------------------------------------+
//| script program start function                                    |
//+------------------------------------------------------------------+
int start()
  {
//----
   orderCloseAll();
//----
   return(0);
  }
//+------------------------------------------------------------------+