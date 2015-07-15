//#include "..\include\BO_Const.ch"

#include "hbclass.ch"
#include "bo_const.ch"

#include "cWindow.ch"
#include "inkey.ch"

#define _TAXID     1
#define _CALCRL    2
#define _MODBS     3
#define _STRID     4
#define _RTDEF     5
#define _RTRATE    6
#define _SYSNUM    7
#define _PRIOR_    8
#define _OUTF      9
#define _INF       10
#define _TAXCODE_  11
#define _PRICEIN   12
#define _SUMUSE    13

#define _NOMSTR_      1
#define _NAME_TOV_    2
#define _OKEY_        3
#define _QUANTITY_    4
#define _PRICE_       5
#define _COST_NOT_TAX 6
#define _COST_ALL_    7
#define _LNDS_        8
#define _NDS_RATE_    9
#define _ID_NDS_RATE_ 10
#define _LA_          11
#define _A_RATE_      12
#define _ID_A_RATE    13
#define _NDS_SUM_     14
#define _A_SUM_       15
#define _COUNTRY_     16
#define _GTD_         17
#define _SF_STR_ID_   18
#define _STR_TP_      19
#define _GROUP_       20
#define _NOM_NUM_     21
#define _PART_        22
#define _STR_FROM_    23
#define _COMMENT_     24

MEMVAR CURR_MAIN
MEMVAR cMarker
//MEMVAR S_F_EX
MEMVAR cCodeFormat
Static aFileOut := {}


//Проверка на купленность подсистемы
//Получает код подсистемы (Арм)
// Код возврата Т - приобретена
Function CheckSubSystem(cSybSystem)
Local cGuid := "",lRet := .F.,n := 0,k := 0
Local cAl := ""
Static aSybSys := {}

  n := aScan(aSybSys,cSybSystem)

  if n > 0
    Return aSybSys[n][2]
  endif
  Do case
    case cSybSystem == "00"
      if PublicVars():DBType == "J"
        lRet := AccessibleSubSystem("{63898E88-24E6-49C4-AA1F-1877EB53E4CA}")
      else
        lRet := AccessibleSubSystem("{53898E88-24E6-49C4-AA1F-1877EB53E4CA}")
      endif
      //lRet := AccessibleSubSystem("{53898E88-24E6-49C4-AA1F-1877EB53E4CA}") ;
      //        .Or. AccessibleSubSystem("{63898E88-24E6-49C4-AA1F-1877EB53E4CA}")
    case cSybSystem == "01"
      lRet := AccessibleSubSystem("{A123E571-68CC-41CC-89EF-2353D9FF54AA}")
    case cSybSystem == "02"
      lRet := AccessibleSubSystem("{E71A1FA8-C649-4D58-B845-CD4EEEA1F9A3}")
    case cSybSystem == "03"
      if PublicVars():DBType $ "R,Y"
        lRet := AccessibleSubSystem("{9D3EE8FB-96BD-4A38-A07F-EF955FB7DAF4}")
      else
        lRet := AccessibleSubSystem("{EBEBFA8C-4F98-4CA7-B4A9-B04440F12B6D}") ;
                .Or. AccessibleSubSystem("{3F2FC6BE-8739-44DD-85EC-0CB5663A4FFB}")

      endif
      //lRet := AccessibleSubSystem("{EBEBFA8C-4F98-4CA7-B4A9-B04440F12B6D}") ;
      //        .Or. AccessibleSubSystem("{3F2FC6BE-8739-44DD-85EC-0CB5663A4FFB}") ;
      //        .Or. AccessibleSubSystem("{9D3EE8FB-96BD-4A38-A07F-EF955FB7DAF4}")
    case cSybSystem == "05"
      lRet := AccessibleSubSystem("{31E95A2F-4FDA-4F3E-8BB0-93B564FCECAC}")
    case cSybSystem == "09"
      lRet := AccessibleSubSystem("{2683BADF-CDB4-4EDC-B74B-122E6C61BB86}")
    case cSybSystem == "14"
      lRet := AccessibleSubSystem("{F56EED6D-64A4-4634-8BC4-1D9BC79593FE}") ;
              .Or. AccessibleSubSystem("{C265E860-A0F9-4444-8C1A-3473CEDB34A2}")
    case cSybSystem == "15"
      lRet := AccessibleSubSystem("{475AE452-D14D-4FC0-859C-ADB382731268}")
    case cSybSystem == "TZ"
      if PublicVars():DBType $ "R,Y"
        lRet := AccessibleSubSystem("{28CF621B-FD6A-4430-96FC-C270FCB1C7B2}")
      else
        lRet := AccessibleSubSystem("{FBFFEF99-4756-4AFE-B50D-EF4F112DF075}") ;
              .Or. AccessibleSubSystem("{351387C8-ED33-43E3-8690-C20E23B4E06F}")
      endif

      //lRet := AccessibleSubSystem("{FBFFEF99-4756-4AFE-B50D-EF4F112DF075}") ;
      //        .Or. AccessibleSubSystem("{28CF621B-FD6A-4430-96FC-C270FCB1C7B2}") ;
      //        .Or. AccessibleSubSystem("{351387C8-ED33-43E3-8690-C20E23B4E06F}")
    case cSybSystem == "TV"
      lRet := AccessibleSubSystem("{E8E035E5-80E5-42D4-B90D-D95B6A2A1E09}")
    case cSybSystem == "MF"
      lRet := AccessibleSubSystem("{9843C3DD-35B6-41F6-B121-F1E0C1CDD961}")
    case cSybSystem == "AU"
      lRet := AccessibleSubSystem("{584C28EB-31F3-4CE0-A191-78AB3FF87F2C}")
    case cSybSystem == "17"
      lRet := AccessibleSubSystem("{9F51AB68-5922-4EF3-AE8A-7F3000558CD2}")
    case cSybSystem == "20"
      lRet := AccessibleSubSystem("{53088AF7-5C14-41BC-BD02-C769E0CC7E43}")
    /*
    case cSybSystem == "SR"
      lRet := AccessibleSubSystem("{CAD5A1E8-391C-4C59-8C46-FCAB47CD28E9}")
    case cSybSystem == "ZR"
      lRet := AccessibleSubSystem("{D8891F67-9805-401F-9546-3D2D3E8BCEC8}")
    */
    case cSybSystem == "16"
      lRet := AccessibleSubSystem("{1C63A1EF-105A-4BE0-A41F-61C4B78944B0}")
    case cSybSystem == "SP"
      lRet := AccessibleSubSystem("{2AE4B0B3-FF2A-4CC8-B121-90FEA60B4DE8}")
    case cSybSystem == "SZ"
      lRet := AccessibleSubSystem("{14386515-707F-439B-A7E0-1200888A19EE}")
    /*
    case cSybSystem == "SR"
      lRet := AccessibleSubSystem("{9082188F-EADC-4610-AB65-52A89AC603F2}")
    */
    case cSybSystem == "AP"
      lRet := AccessibleSubSystem("{0177B716-ED48-4F2C-B2F2-38182191B4B0}")
    case cSybSystem == "PM"  // Учет денежных средств
      /*
      if FILE(B6_DBF_PATH + "PAY\FIN_PRM.Dbf")
        if _DbAreaOpen(B6_DBF_PATH+"PAY\FIN_PRM.Dbf",@cAl,)
          (cAl)->(DbGoTop())
          if (cAl)->(Eof())
            lRet := .F.
          else
            if Empty((cAl)->Per_BEG)
              lRet := .F.
            else
              lRet := .T.
            endif
          endif
          _DbAreaClose(cAl)
        else
          lRet := .F.
        endif
      else
        lRet := .F.
      endif
      */
      lRet := AccessibleSubSystem("{AEDC3A3D-D176-4209-82F7-E3449EBBD62B}") .Or.;
              AccessibleSubSystem("{D8499146-94E6-4E51-BC1C-938AC645C4E9}")

    case cSybSystem == "BD"  // Учет денежных средств в банках
      lRet := AccessibleSubSystem("{12FCC662-FB77-495B-BCF3-F34A9305C400}")
    case cSybSystem == "ND"  // Учет денежных средств наличные
      lRet := AccessibleSubSystem("{32EEF9C0-B1FF-4F7D-AA7B-B9D6BA65BF13}")
    case cSybSystem == "PP" // Расчеты с сотрудниками
      lRet := AccessibleSubSystem("{F1E38210-AA9D-4136-B048-677DEAC10572}")
    otherwise
      messagebox("CheckSubSystem. Не верно указан код подсистемы!",TITLEAPP,48)

  endcase
  AADD(aSybSys,{cSybSystem,lRet})

RETURN lRet
/* Изменения постановки - пока нет дополняющих записей
/////////////////////////
// PG
// Получение суммы дополняющих записей и сумму записей в книгу
// для книги покупок
// Получает объект - Книгу
// Код возврата Т - успешное выполнение
////////////////////////////////
Function CalkDopRecTaxBook(oBook)
local oErr,DS,oSfBook,aDopRecTp,aTp,nS,nO,i
 begin sequence
 oBook:mSumDopPay  := 0
 oBook:mSumDopOp := 0
 oBook:mSumDopPut := 0
 DS := oBook:DS
 aDopRecTp :={}
 // Определяем дополняющие записи
 //altd()
 do case
   case ((DS:SF_MOVE == "ЗК") .Or. (DS:SF_MOVE == "БП"))
     do case
       case DS:REC_TP == "ПЛ"
         aDopRecTp := {{"ОП",0},{"СМ",0}}
       case DS:REC_TP == "ОП" .Or. DS:REC_TP == "СМ"
         aDopRecTp := {{"ПЛ",0}}
     endcase
   case DS:SF_MOVE == "КС"
     do case
       case DS:REC_TP == "ПЛ"
         aDopRecTp := {{"ОП",0},{"АМ",0}}
       case DS:REC_TP == "ОП"
         aDopRecTp := {{"ПЛ",0},{"АМ",0}}
       case DS:REC_TP == "АМ"
         aDopRecTp := {{"ПЛ",0},{"ОП",0}}
     endcase
   case DS:SF_MOVE == "СЗ"
     do case
       case DS:REC_TP == "ВЗ" .Or. DS:REC_TP == "СП"
         aDopRecTp := {{"ОП",0}}
       case DS:REC_TP == "ОП"
         aDopRecTp := {{"ВЗ",0},{"СП",0}}
     endcase
 endcase
 oSfBook := oBook:SF:BOOK
 oSfBook:MoveFirst()
 // Формируем массив видов дополняющих записей
 aTp := {}
 for i := 1 to len(aDopRecTp)
    AADD(aTp,aDopRecTp[i][1])
 next
 // Определяем сумму дополняющих записей и регистрации
 nO := 0
 //altd()
 Do while !oSfBook:Eof()
 //!!!работаем с записями по дату текущей включительно исключая текущую запись
 //  if ((oSfBook:SRC_DATE <= DS:SRC_DATE) .And. (oSfBook:BOOK_ID != DS:BOOK_ID))
 // работаем со всеми записями мсключая текущую - хронологию обеспечиваем при создании записей
   if !(oSfBook:BOOK_ID == DS:BOOK_ID)
     nO := nO + oSfBook:REC_SUM
     if oSfBook:REC_TP $ aTp // отбираем дополняющие записи
       for i := 1 to len(aDopRecTp)
         if oSfBook:REC_TP ==   aDopRecTp[i][1]
           aDopRecTp[i][2] := aDopRecTp[i][2] + oSfBook:SRC_SUM
         endif
       next
     endif
   endif
   oSfBook:MoveNext()
 enddo
 nS := 0
 //altd()
 if len(aDopRecTp) > 0
   nS := aDopRecTp[1][2]
 endif
 if len(aDopRecTp) > 1
   for i:= 2 to len(aDopRecTp)
     if !(DS:SF_MOVE == "КС")
       nS := nS + aDopRecTp[i][2] // для сторно С-Ф и "ВЗ" и "СП" регистрация платежа
          // для валютного С_Ф и СМ и ОП - регистрация оприходования
     else // Выбираем c минимальным значением
       if abs(nS) > abs(aDopRecTp[i][2])
         nS := aDopRecTp[i][2]
       endif
     endif
   next
 endif
 for i:= 1 to len(aDopRecTp)
   do case
     case aDopRecTp[i][1] $ {"ОП","СМ"}
       oBook:mSumDopOp := oBook:mSumDopOp + aDopRecTp[i][2]
     case aDopRecTp[i][1] $ {"ПЛ","ВЗ","СП"}
       oBook:mSumDopPay  := oBook:mSumDopPay + aDopRecTp[i][2]
     case aDopRecTp[i][1] == "АМ"
       oBook:mSumDopPut := oBook:mSumDopPut + aDopRecTp[i][2]
   endcase
 next
 //altd()
 oBook:mSumDop := nS
 oBook:mOSZ := nO
 recover using oErr
  if valtype(oErr) == "L"
     return oErr
   else
     return .F.
  endif
 end sequence
Return .T.
*/
*************************
** Ф-ция получает
** TI_CTG - категория 1 - закупкиб 2 - продажи
** Вид С-ф дФм - если Т - авансовая иначе обычная
** lBook - да - ДЛЯ КНИГИ иначе для С_Ф
** возвращает массив параметров -
** 1 объединять одноименные позиции
** 2 - соблюдать хронологию,
** 3 - обычная или отрицательная С_Ф при возвратах
** 4 - ID налоговой модели
** 5 - собственное предприятие
** 6 - собственное как грузополучатель
** 7 - учетная политика
** 8 - тип документа для групповых с-ф
** 9 - можно или нет создавать валютные с-ф
** 10 - дата начала работы подсистемы
** 11 - налоговый период (0-месяц, 1-квартал)
** 12 - запись в книгу по закупкам по запросу 1 автоматически; 2 по запросуIN_QUE
** 13 - создание авансового с-ф из банка 0 - не создавать 1 по запросу 2 автоматически
** 14 - создание авансового с-ф из кассы 0 - не создавать 1 по запросу 2 автоматически
** 15 - Т - переносить примечание из документов
** 16 - Т - переносить комментарий из документов
** 17 - T проверяем уникальность на закупках по партнеру
** 18 - T - из документа  Наименование авансового счета-фактуры
** 19 - Текст наименования
** 20 - T - из документа  Дополнение авансового счета-фактуры
** 21 - Т - из документа Комментарий авансового счета-фактуры
** 22 - T - можно изменить собственное предприятие
** 23 - T - использовать доп номер
** 24 - инициировать доп номер значкением
** 25 - T - использовать доп номер из грузоотправителя
***********************************
Function GetParamIni(TI_CTG,lAv,aParamIni,lBook)
local  oErr,a
Local tb,IsBook,la, cTbName := "Tax\Tax_ParIni.Dbf"
 begin sequence
 If ValType(lBook) =="L"
   IsBook := lBook
 else
   IsBook := .F.
 endif
  If ValType(lAv) =="L"
   la := lAv
 else
   la := .F.
 endif
  //altd()
  tb:=CreateDbRecord(B6_DBF_PATH + cTbName)
  if tb:Eof() .Or. tb:Bof()
    if !CreatePrmIni(tb)
      Break(.F.)
    endif
  endif
  //ap-- 28.07.2007
  //25205 Из настройки параметров убираем группу полей Типовая операция.
  //Ни у из таблицы поля тоже ( лишние лучше сразу убрать.)
  // pg 29377 - добавим типовую операцию
  if IsBook
    a := Array(12)
    if TI_CTG == "1"
      a[1] := ''//tb:OPER_DEFB //AADD(aParamIni,tb:OPER_DEFB)
      a[2] := tb:IN_CNT //AADD(aParamIni,tb:IN_CNT)
      a[9] := tb:IN_TOPA
      a[10] := tb:OUT_TOPC
      a[12] := tb:CA_RECLC // вскидывается на закладке продажи
    else
      a[1] := ''//tb:OPER_DEFS //AADD(aParamIni,tb:OPER_DEFS)
      a[2] := tb:OUT_CNT //AADD(aParamIni,tb:OUT_CNT)
      a[9] := tb:OUT_TOPA
      a[10] := tb:IN_TOPC
      a[12] := tb:CY_RECLC // вскидывается на закладке закупка
    endif
    a[3] := tb:OUT_PL //AADD(aParamIni,tb:OUT_PL) // учетная политика
    if la
      a[4] := tb:MOD_DEF_F //AADD(aParamIni,tb:MOD_DEF_F)
    else
      a[4] := tb:MOD_DEF //AADD(aParamIni,tb:MOD_DEF)
    endif
    a[5] := tb:DATE_BEG
    a[6] := tb:TAX_PERIOD
    a[7] := tb:IN_TOP
    a[8] := tb:OUT_TOP
    a[11] := tb:PART_RATE
  else
    a := array(25)
    if TI_CTG == "1"
      a[1] := tb:IN_SM_PS //AADD(aParamIni,tb:IN_SM_PS)
      a[2] := tb:IN_CNT //AADD(aParamIni,tb:IN_CNT)
      a[3] := .T. //tb:RET_BUY //AADD(aParamIni,tb:RET_BUY)
      a[9] := tb:IN_SFCUR
      a[12] := tb:IN_QUE
      a[13] := tb:BANK_AV_B
      a[14] := tb:CASH_AV_B
      a[23] := tb:B_DNUM_USE
      a[24] := tb:B_DNUM_INI
      a[25] := .F.
    else
      a[1] := tb:OUT_SM_PS //AADD(aParamIni,tb:OUT_SM_PS)
      a[2] := tb:OUT_CNT //AADD(aParamIni,tb:OUT_CNT)
      a[3] := .T. //tb:RET_SALE //AADD(aParamIni,tb:RET_SALE)
      a[9] := tb:OUT_SFCUR
      a[12] := tb:OUT_QUE
      a[13] := tb:BANK_AV
      a[14] := tb:CASH_AV
      a[23] := tb:S_DNUM_USE
      a[24] := tb:S_DNUM_INI
      a[25] := tb:S_DNUM_RUL
    endif
    if la
      a[4] := tb:MOD_DEF_F //AADD(aParamIni,tb:MOD_DEF_F)
      if TI_CTG == "1"
        a[8] := tb:DOC_BUYAV
      else
        a[8] := tb:DOC_AVTP
      endif
    else
      //a[4] := tb:MOD_DEF //AADD(aParamIni,tb:MOD_DEF)
      if TI_CTG == "1"
        a[8] := tb:DOC_BUYTP
        a[4] := tb:MOD_DEF //AADD(aParamIni,tb:MOD_DEF)
      else
        a[8] := tb:DOC_TP
        a[4] := tb:MOD_DEF_S
      endif
    endif
    a[5] := tb:ENT_ID //AADD(aParamIni,tb:ENT_ID)
    a[6] := tb:ENT_ADDRID //AADD(aParamIni,tb:ENT_ADDRID)
    a[7] := tb:OUT_PL //AADD(aParamIni,tb:OUT_PL)
    //if la
   //   AADD(aParamIni,tb:DOC_AVTP)
    //else
   //   AADD(aParamIni,tb:DOC_TP)
   // endif
    a[10] := tb:DATE_BEG
    a[11] := tb:TAX_PERIOD

    a[15] := tb:DopSf
    a[16] := tb:Com_cf
    a[17] := tb:IN_NUM
    a[18] := tb:NM_AV
    a[19] := tb:NM_AV_TXT
    a[20] := tb:DOP_AV
    a[21] := tb:COM_AV
    a[22] := tb:ENT_SEL
  endif
  aParamIni := a
  tb:Destroy()
 recover using oErr

  if tb != nil
    tb:Destroy()
  endif
  if valtype(oErr) == "L"
     return oErr
   else
     return .F.
  endif
 end sequence

Return .T.
***********************
** Ф-ция по имени параметра возвращает его значение
*********
Function  GetTaxParamIni(cNameParam,RetValue)
local  oErr
local tb,cTbName := "Tax\TAX_PARINI.DBF"
 begin sequence
 tb:=CreateDbRecord(B6_DBF_PATH + cTbName)
 if tb:Eof() .Or. tb:Bof()
   if !CreatePrmIni(tb)
     Break(.F.)
   endif
 endif
 RetValue := tb:tbEval(cNameParam)
 tb:destroy()
 recover using oErr

  if tb != nil
    tb:destroy()
  endif
  if valtype(oErr) == "L"
     return oErr
   else
     return .F.
  endif
 end sequence

Return .T.

************
*** получаем таблицу документов и название поля отметки с-ф
***  в массиве возвращает записи имеющие отметку использования в с-ф
****
/*
Function SetCheckedForSelect(tb,aRecNo,aChecked)//SetCheckedForSelect(tb,cFieldName,aChecked)
local  oErr
 begin sequence
 //altd()
 aChecked := {}
 tb:MoveFirst()
 Do While !tb:EOF()
   if tb:RecNo $ aRecNo
     AADD(aChecked,{tb:RecNo,.T.})
   else
     AADD(aChecked,{tb:RecNo,.F.})
   endif
   tb:MoveNext()
 enddo
 recover using oErr

  if valtype(oErr) == "L"
     return oErr
   else
     return .F.
  endif
 end sequence

Return .T.
 */
***********************
** получаем таблицу документов, уникальный индекс
** массив отмеченных записей
** возвращаем массив значений ключей для записи
************************
/*
Function GetKeyForSelectDoc(tb,cTag,aChecked,aKey)
local  oErr
local valKey,cKey,i
 begin sequence

 tb:SetOrder(cTag)
 cKey := tb:OrdKey(cTag)
 for i := 1 to len(aChecked)
   if aChecked[i][2]
     tb:Goto(aChecked[i][1])
     valKey := tb:TbEval(cKey)
     AADD(aKey,valKey)
   endif
 next

 recover using oErr

  if valtype(oErr) == "L"
     return oErr
   else
     return .F.
  endif
 end sequence

Return .T.
  */
*********
**  получает вид движения
**  в строке возвращает направление имеющее связь с закупками (продажами)
** в зависимости от параметра возвраты поставщику
*********

Function GetMovesType(Vid,lSclad,cType,lNegativeSF)
local  oErr
local  tb,cTbName,s := "",a := {},lN := .F.
 begin sequence
  //altd()
 if !Empty(lNegativeSF)
   lN := lNegativeSF
 endif
 cType := ""
 cTbName := IIF (lSclad,"Sclad\Moves.DBF","Zapas\Moves.DBF")
 tb := CreateDbRecord(B6_DBF_PATH + cTbName)
 if Vid == "1"
   s := " Vid == '1' .And. YESTV == .T. "
 else
   if  lSclad
     s := " Vid == '2' .And. YESDOP == .T. "
   else
     s := " Vid == '2' .And. YESDOP == .T. "
   endif
 endif
 tb:Filter(s)
 tb:MoveFirst()
 do while !tb:Eof()
   if Vid == "1"
     if !(tb:type == "4")  .And. !(tb:type=='?' .And. !Empty(tb:typeex))
       cType := cType + tb:Type + "," //"'" + tb:Type + "',"//" Type == '" + tb:Type + "' .Or."
     endif
   else
     if lN
       a := {"4","6","%","+","5"}
     else
       a := {"4","6","%","+"}
     endif
     if !(tb:type $ a) .And. !(tb:type=='?' .And. !Empty(tb:typeex))
       cType := cType + tb:Type + "," //"'" + tb:Type + "',"//+ " Type == '" + tb:Type + "' .Or."
     endif
   endif
   tb:MoveNext()
 enddo

 if !Empty(cType)
   cType := Left(cType,len(cType)-1)//4)
 endif

 tb:destroy()
 recover using oErr

  if tb != nil
    tb:destroy()
  endif
  if valtype(oErr) == "L"
     return oErr
   else
     return .F.
  endif
 end sequence

Return .T.
// получить учетную политику
// при успешном выполнении в переменной возвращает
// значение учентой политики "0"  -  по оплате "1" по отгрузке
Function GetTaking(lRet,cPay)
local  oErr
Local tb, cTbName := "Tax\Tax_ParIni.Dbf"
 begin sequence
  //altd()
  lRet := .F.
  tb:=CreateDbRecord(B6_DBF_PATH + cTbName)
  cPay := tb:Out_Pl
  lRet := .T.
  tb:Destroy()
 recover using oErr

  if tb != nil
    tb:Destroy()
  endif
  if valtype(oErr) == "L"
     return oErr
   else
     return .F.
  endif
 end sequence
Return .T.

//групповое формирование С-Ф  на продажу , закупку
Function CreateGroupSFOnSale(FunctionParam,lNegativeSF,lPartner,lBuy,newRecNo)
local oErr
Local nJrn,cTbName,cTagName := "Tag_ForSf"
Local sDateB := DTOS(FunctionParam[2])
Local sDateE := DTOS(FunctionParam[3])
Local aSf := {}//,aSchAn := {}  //cSfId,nSum,
Local lSclad := .F.,cType := "",cMess,cArm,cStrTp,lAll := .F.
Local aType := {},tb,i,n,/*cKey,cPartner,*/cIdPartner
Local RetValue := {},cName := {"code","shortname"},lRet
Local cTmpFileName,cTmpFileNameCdx
Local tbDoc,aDocForSF := {},ParamForReg := Array(6),aParam := {}
Local cIndexName := "", cOrdKey := "", cOrdFor := ""
Local aPartner := {},k
Local cVid
//Local tbAnalit,tbPartner
  begin sequence
  if  lBuy
    cVid := "1"
  else
    cVid := "2"
  endif
  ParamForReg[2] := FunctionParam[2]
  ParamForReg[3] := FunctionParam[3]
  ParamForReg[4] := Array(2)
  ParamForReg[5] := {1,1}
  ParamForReg[6] := FunctionParam[6]
  if !(ValType(lPartner) == "L")
    lPartner := .F.
  endif
  //Получаем счета по аналитике которых можно идентифицировать партнера

  /*if ValType(aSchetAnalit) == "A" //"O"
    aSchAn := aSchetAnalit
  else
    if !GetSchetForPartner(@aSchAn)
      Break(.T.)
    endif
    if len(aSchAn) < 1
      messagebox("Нет документов для регистрации!",TITLEAPP,48)
      Break(.T.)
    endif
  endif
  */
  do case
   case FunctionParam[5][1] == 1  // для документов склада
     nJrn := "0301"
     cTbName := "SCLAD\MDOC"
     lSclad := .T.
     cArm := " складу. "
     cStrTp := "2"
   case FunctionParam[5][1] == 2  // для документов запасов
     nJrn := "0901"
     cTbName := "ZAPAS\MDOC"
     cStrTp := "3"
     cArm := " запасам. "
   case FunctionParam[5][1] == 3  // для актов на продажу
     if cVid == "1"
       nJrn := "TV01"
       cTbName := "TOVAR\ACT"
     else
       nJrn := "0501"
       cTbName := "REAL\ACT"
     endif
     cStrTp := "4"
 endcase
 if !(nJrn $ {"0501","TV01"})
    if !GetMovesType(cVid/*"2"*/,lSclad,@cType,lNegativeSF)
     Break(.F.)
   endif
   if Empty(cType)
      cMess := "Выбор документов по" + cArm +" Нет операций связанных"
      cMess := cMess + " с продажами!"
      Messagebox(cMess,TITLEAPP,48)
      Break(.F.)
   endif
   aType := StrSplit(cType,",")
 endif
 // Если передали партнера - определяем его код и название
 if ValType(FunctionParam[4]) == "A" .And. !Empty(FunctionParam[4][1])
   //lAll := .T.
   //if Len(FunctionParam[4]) > 0
   //  if !Empty(FunctionParam[4][1])
       cIdPartner := FunctionParam[4][1]
   //    if !lPartner
   //      if GetAnalitCodeForPartner(aSchAn,cIdPartner)

   //      else
   //        Break(.T.)
   //      endif
   //    endif
       ParamForReg[4][1] := FunctionParam[4][1]
       ParamForReg[4][2] := FunctionParam[4][2]
       lAll := .F.
   //  endif
   //endif
 else
   lAll := .T.
 endif
 tb:=CreateDbRecord(B6_DBF_PATH + cTbName,cTagName)
 tb:SetOrder(cTagName)
 if !FILE( cTmpFileName )
    cTmpFileName :=  GetTempFile()
    cTmpFileNameCdx := cTmpFileName + ".Cdx"
    cTmpFileName :=  cTmpFileName + ".Dbf"
 endif
 if !(nJrn $ {"0501","TV01"})
   if !lAll
     aDocForSF := {}
     lRet := .F.
     //                   1         2    3     4        5 6
     selectdocforbook( cTmpFileName,.T.,nJrn,cIdPartner, , ,;
                       ;//7     8     9       10     11 12 13 14
                       sDateB,sDateE,cVid/*"2"*/,lNegativeSF, ,  ,  ,@lRet,ParamForReg[6])
     if lRet
        tbDoc := CreateDbRecord( cTmpFileName )
        tbDoc:GoTop()
        do while !tbDoc:Eof()
           AADD(aDocForSF,{tbDoc:FieldValue("nRec"),tbDoc:FieldValue("KOP_NDS")+tbDoc:FieldValue("KOP_NNDS")+tbDoc:FieldValue("KOP_NDS0")+tbDoc:FieldValue("KOP_AG_NDS"),{tbDoc:FieldValue("KOP_NDS"),tbDoc:FieldValue("KOP_NNDS"),tbDoc:FieldValue("KOP_NDS0"),tbDoc:FieldValue("KOP_AG_NDS")}})
           tbDoc:Skip(1)
        enddo
      else
      //   messagebox("Нет документов для регистрации!",TITLEAPP,48)
         Break(.F.)
      endif
      if len(aDocForSF) > 0
        if CreateGroupSF(aDocForSF,cStrTp,FunctionParam[3],cIdPartner,cVid,@newRecNo)
          /* 06-11-2006 нет регистрации пладежей
          if RegistrationPaymentForBook(.F.,ParamForReg)
          endif
          */
        endif
      else
        //messagebox("Нет документов для регистрации!",TITLEAPP,48)
        Break(.F.)
      endif
   else
     for n := 1 to len(aType)
       cOrdKey := "Part_Id"
       cOrdFor := "!Empty(Part_id).And.Empty(Oper_Fact)" +;
                  ".And.DTOS(DATE)>='" + sDateB + "'" +;
                  ".And.DTOS(DATE)<='" + sDateE + "'" +;
                  ".And.VID = '"+cVid+"'.And.Type=='" + aType[n] + "'" +;
                  ".And.!Deleted().And.!Arxiv"
       if !tb:CreateMyTMPIndex(5,{},/*cIndexName*/, cOrdKey, cOrdFor,,,,,)
         Break(.F.)
       endif

       tb:GoTop()
       cIdPartner := ""
       do while !tb:Eof()
         cIdPartner := tb:FieldValue("PART_ID")
         k := len(aPartner)
         if k < 1
           AADD(aPartner,cIdPartner)
         endif
         for i := 1 to k
           if cIdPartner == aPartner[i]
             Exit
           endif
           if i == k
             AADD(aPartner,cIdPartner)
           endif
         next

         tb:Skip(1)
       enddo
       tb:ClearMyTMPIndex(5)
     next
     /*
       for i := 1 to  len(aSchAn)

         cKey := "2" + Upper(aType[n] + aSchAn[i][1])
         tb:Scope(cKey,cKey,cTagName)
         tb:GoTop()
         do while !tb:Eof()
           if !Empty(tb:FieldValue("agentcode"))
             cPartner := tb:FieldValue("agentcode")
             cPartner := Upper(SubStr(cPartner,aSchAn[i][2],aSchAn[i][3]))
             cIdPartner := ""
             if aSchAn[i][5] // аналитика системная
                if LookUpSeek("Partner","FULLCODE",@lRet,cPartner,"Part_ID",@cIdPartner)
                  if !lRet
                    cIdPartner := ""
                  endif
                endif
             else
               if GetAnalitByPartner(aSchAn[i][5],"",cPartner,@lRet,@cPartner,.F.,@cIdPartner)
                 if !lRet
                   cIdPartner := ""
                 endif
               endif
             endif
             if !Empty(cIdPartner)
               if GetAnalitCodeForPartner(aSchAn,cIdPartner)
                  aParam := {;
                    FunctionParam[1],;
                    FunctionParam[2],;
                    FunctionParam[3],;
                    {cIdPartner,cPartner},;
                    FunctionParam[5];
                  }

                  if !CreateGroupSFOnSale(aParam,lNegativeSF,aSchAn,.T.)
                    tb:Skip(1)
                    Loop
                  endif
               endif
             endif
             tb:GoTop()
             Loop
           endif
           tb:Skip(1)
         enddo
       next
       */
     //next
   endif
   for i := 1 to len(aPartner)
     aParam := {;
                 FunctionParam[1],;
                 FunctionParam[2],;
                 FunctionParam[3],;
                 {aPartner[i],},;
                FunctionParam[5],;
                FunctionParam[6];
              }

     CreateGroupSFOnSale(aParam,lNegativeSF,/*aSchAn,*/.T.,lBuy,@newRecNo)
   next

 else
   if !lAll
         aDocForSF := {}
         lRet := .F.
        //                   1         2    3     4        5 6
         selectdocforbook( cTmpFileName,.T.,nJrn,cIdPartner, , ,;
                          ;//7     8     9       10     11 12 13 14
                           sDateB,sDateE,cVid/*"2"*/,lNegativeSF, ,  ,  ,@lRet,ParamForReg[6])
         if lRet
           tbDoc := CreateDbRecord( cTmpFileName )
           tbDoc:GoTop()
           do while !tbDoc:Eof()
             AADD(aDocForSF,{tbDoc:FieldValue("nRec"),tbDoc:FieldValue("KOP_NDS")+tbDoc:FieldValue("KOP_NNDS")+tbDoc:FieldValue("KOP_NDS0")+tbDoc:FieldValue("KOP_AG_NDS"),{tbDoc:FieldValue("KOP_NDS"),tbDoc:FieldValue("KOP_NNDS"),tbDoc:FieldValue("KOP_NDS0"),tbDoc:FieldValue("KOP_AG_NDS")}})
             tbDoc:Skip(1)
           enddo
         else
           //messagebox("Нет документов для регистрации!",TITLEAPP,48)
           Break(.F.)
         endif
         if len(aDocForSF) > 0
           if CreateGroupSF(aDocForSF,cStrTp,FunctionParam[3],cIdPartner,cVid,@newRecNo)
             /* 06_11_2006 - изменение в регистрации
                нет регистрации платежей
             if RegistrationPaymentForBook(.F.,ParamForReg)
             endif
             */
           endif
         else
           //messagebox("Нет документов для регистрации!",TITLEAPP,48)
           Break(.F.)
         endif
   else
     //for i := 1 to  len(aSchAn)
       //cIndexName := "TmpTag"
       cOrdKey := "Part_Id"
       cOrdFor := "!Empty(Part_id).And.Empty(Oper_Fact)" +;
                  ".And.DTOS(Tek_Data)>='" + sDateB + "'" +;
                  ".And.DTOS(Tek_Data)<='" + sDateE + "'" +;
                  ".And.!Deleted().And.!Arxiv"
       if !tb:CreateMyTMPIndex(5,{},/*cIndexName*/, cOrdKey, cOrdFor,,,,,)
         Break(.F.)
       endif
       //tb:Scope(cKey,cKey,cTagName)
       //tb:SetOrder(cIndexName)
       tb:GoTop()
       cIdPartner := ""
       do while !tb:Eof()
         if !(cIdPartner == tb:FieldValue("PART_ID"))
           cIdPartner := tb:FieldValue("PART_ID")
           AADD(aPartner,cIdPartner)
         endif
         tb:Skip(1)
       enddo
       tb:ClearMyTMPIndex(5)
     for i := 1 to len(aPartner)
       aParam := {;
                   FunctionParam[1],;
                   FunctionParam[2],;
                   FunctionParam[3],;
                   {aPartner[i],},;
                   FunctionParam[5],;
                   FunctionParam[6];
                  }

       CreateGroupSFOnSale(aParam,lNegativeSF,/*aSchAn,*/.T.,lBuy,@newRecNo)
     next
   endif
 endif
 Break(.T.)
 recover using oErr
 If ValType(tbDoc) == "O"
    tbDoc:Destroy()
    tbDoc := nil
  endif
  If ValType(tb) == "O"
    tb:Destroy()
    tb := nil
  endif
  if FILE( cTmpFileName )
    FERASE( cTmpFileName )
  endif
  if FILE( cTmpFileNameCdx  )
    FERASE( cTmpFileNameCdx  )
  endif

  if valtype(oErr) == "L"
     return oErr
   else
     return .F.
  endif
 end sequence
Return .T.



// для каждого партнера формируем С-Ф
Function CreateGroupSF(aParamDocForSf,cStrTp,dDate,nKey,cVid,newRecNo)
local  oErr ,cMsg
local oObjSf, aParamIni := {}, nDocType := 0
local aParam,aRet ,nRec := newRecNo
local aParamForSf := {} ,i,m,lAdd := .T.,cMvTp := ""
 begin sequence
 if cVid == "1"
   cMvTp := "ЗК"
 else
   cMvTp := "ОТ"
 endif
 if !GetParamIni(cVid/*"2"*/,.F.,@aParamIni)
   Break(.F.)
 endif
 nDocType := aParamIni[8]
 if Empty(nDocType)
   cMsg := "В настройке подсистемы не определен тип документов" + chr(13) + chr(10)
   if cVid == "1"
     cMsg += "на закупку"
   else
     cMsg += "на продажу"
   endif
   messagebox(cMsg,TITLEAPP,48)
   Break(.F.)
 endif
 //altd()
 for i := 1 to len(aParamDocForSf)

   lAdd := .T.
   for m := 1 to len(aParamForSf)
     if (Empty(aParamDocForSf[i][3][1]) .Or. Empty(aParamForSf[m][1][1]) .Or. (aParamDocForSf[i][3][1] == aParamForSf[m][1][1])) .And.;
        (Empty(aParamDocForSf[i][3][2]) .Or. Empty(aParamForSf[m][1][2]) .Or. (aParamDocForSf[i][3][2] == aParamForSf[m][1][2]))  .And. ;
        (Empty(aParamDocForSf[i][3][3]) .Or. Empty(aParamForSf[m][1][3]) .Or. (aParamDocForSf[i][3][3] == aParamForSf[m][1][3]))
     // У окумента нет кодов - может быть с любым другим - добавим к первомуже
       if Empty(aParamForSf[m][1][1])
         aParamForSf[m][1][1] := aParamDocForSf[i][3][1]
       endif
       if Empty(aParamForSf[m][1][2])
         aParamForSf[m][1][2] := aParamDocForSf[i][3][2]
       endif
       if Empty(aParamForSf[m][1][3])
         aParamForSf[m][1][3] := aParamDocForSf[i][3][3]
       endif
       AADD(aParamForSf[m][2],aParamDocForSf[i][1])
       lAdd := .F.
       exit
     endif

   next
   if lAdd
     AADD(aParamForSf,{aParamDocForSf[i][3],{aParamDocForSf[i][1]}})
   endif
 next

 for i := 1 to len(aParamForSf)

   oObjSf := clsTax_Inv():NEW()
   oObjSf:Open()
 /*  тип документа для групповой С-Ф внесен в настройку
 if GetSFDocType(@lRet,"2",@nDocType)
   if !lRet
     Break(.F.)
   endif
 else
  Break(.F.)
 endif
 */

    if !oObjSf:BeforeAppend(cVid/*"2"*/, cMvTp, "",; //0,;
                         nDocType,aParamIni[5],aParamIni[6],.T. )
      Break(.F.)
    endif
    if !oObjSf:Append()
      Break(.F.)
    endif
    oObjSf:DOC_DATE := dDate
    oObjSf:REG_DATE := dDate
    oObjSf:PRT_ID := nKey
    oObjSf:PRT_ADDRID := nKey
    if !oObjSf:CreateStrForDoc(aParamForSf[i][2],cStrTp)
      Break(.F.)
    endif

    if !oObjSf:Save()
  // Стартонем форму

      newRecNo := (oObjSf:cWa)->(RecNo())
      aParam := Array(10)
      aParam[1] := 1
      aParam[2] := oObjSf:DS:DOC_ID
      aParam[3] := .F.
      aParam[4] := oObjSf:DS:TI_CTG
      aParam[5] := oObjSf:DS:MOVE_TP
      aParam[7] := ""
      aParam[8] := oObjSf
      aParam[9] := 1
      aParam[10] := .T.

      aRet :=  RunForm('tax\frmTaxInv',.T.,aParam,,.T. )
      if Len(aRet) == 0
        newRecNo := nRec
        Break(.F.)
      endif
      if aRet[2] // форму нормально закрыли
        oObjSf := nil
      else
        if aRet[1]
          oObjSf := nil
        endif
        newRecNo := nRec
        Break(.F.)
      endif
    else
      newRecNo := (oObjSf:cWa)->(RecNo())
    endif
    if ValType(oObjSf) == "O"
      oObjSf:Destroy()
      oObjSf := nil
    endif
  next

  //Break(.T.)
 recover using oErr
  if ValType(oObjSf) == "O"
    oObjSf:Destroy()
    oObjSf := nil
  endif
  if valtype(oErr) == "L"
     return oErr
   else
     return .F.
  endif
 end sequence
Return .T.
// Нет регистрацтт платежей
//Function RegistrationPaymentForBook(lBuy,FunctionParam)
//local  oErr
//local tb,tb1,cTbName := "TAX\TAX_INV.Dbf",cTagName := "TAG_PART"
//Local cKey := "",cKey1 := "",s := "",nRec,cIdPartner,aPartner := {}
//Local sDateB := DTOS(FunctionParam[2])
//Local sDateE := DTOS(FunctionParam[3])
//Local aSf := {},cSfId,nSum,aSchAn := {}

//   begin sequence
//   if !GetSchetForPartner(@aSchAn)
//     Break(.T.)
//   endif
//   if len(aSchAn) < 1
//     messagebox("Нет документов для регистрации!",TITLEAPP,48)
//     Break(.T.)
//   endif
//   if lBuy
//     cKey := "1"
//     s := /*s + " '1') .And. */  " (MOVE_TP == 'ЗК' .Or. MOVE_TP == 'КС') "
//   else
//     cKey := "2"
//     s := /* s + " '2') .And. */ " (MOVE_TP == 'ОТ') "
//   endif
//   tb:=CreateDbRecord(PublicVars():LoadPath() + cTbName,cTagName)
//   cIdPartner := FunctionParam[4][1]
//   if !Empty(FunctionParam[4][1])//передан партнер
//     cKey  := cKey + FunctionParam[4][1]//str(FunctionParam[4][1],10)
//     cKey1 := cKey + sDateE //DTOS(FunctionParam[3])
//     cKey  := cKey + sDateB //DTOS(FunctionParam[2])
//     tb:Scope(cKey,cKey1,cTagName)
//     tb:GoTop()
//     do while !tb:Eof()
//       if tb:TbEval(s)
//         cSfId := tb:FieldValue("DOC_ID")
//         nSum := tb:FieldValue("SUM_A") - tb:FieldValue("SUM_PAY")
//         AADD(aSf,{cSfId,nSum,.F.})
//       endif
//       tb:Skip(1)
//     enddo
//     if len(aSf) > 0
        // Заполним аналитиками для партнера
//        if GetAnalitCodeForPartner(aSchAn,cIdPartner)
//           if GetSfForRaz(lBuy,cIdPartner,FunctionParam,aSf,aSchAn)
//           endif
//       endif
//      endif
//   else // Партнер не определен - работаем со всеми
//     tb:Scope(cKey,cKey,cTagName)
//     tb:GoTop()
//     If !tb:Eof()
//       tb1 := CreateDbRecord(PublicVars():LoadPath() + cTbName,cTagName)
//       do while !tb:Eof()
//         if cIdPartner == tb:FieldValue("PRT_ID")
//           tb:Skip(1)
//           Loop
//         endif
//         cIdPartner := tb:FieldValue("PRT_ID")
//         if  AScan(aPartner,cIdPartner) < 1
//           AADD(aPartner,cIdPartner)
//         endif
///         tb1:Scope(cKey + cIdPartner,cKey + cIdPartner,cTagName)
//         tb1:GoBottom()
//         nRec := tb1:RecNo
//         cKey1 := cKey + cIdPartner
//         tb1:Scope(cKey1 + sDateB,cKey1 + sDateE,cTagName)
//         aSf := {}
//         do while !tb1:Eof()
//           if tb1:TbEval(s)
//             cSfId := tb:FieldValue("DOC_ID")
//             nSum := tb:FieldValue("SUM_A") - tb:FieldValue("SUM_PAY")
//             AADD(aSf,{cSfId,nSum,.F.})
//           endif
//           tb1:Skip(1)
//         enddo
//         if len(aSf) > 0
           // Заполним аналитиками для партнера
//           if GetAnalitCodeForPartner(aSchAn,cIdPartner)
//             if GetSfForRaz(lBuy,cIdPartner,FunctionParam,aSf,aSchAn)
//             endif
//           endif
//         endif
//         tb:GoTo(nRec)
//         tb:Skip(1)
//       enddo
//     endif
//   endif
   /*
   if !lBuy // для продаж для не разнесенных платежных документов
   // нужно создать авансовые счета-фактуры
      if !CreateSfForAllPay(aPartner,FunctionParam[5],aSchAn,FunctionParam[5])
      endif
   endif
   */
//   recover using oErr
//   if valType(tb1) == "O"
//     tb1:Destroy()
//   endif
//   tb1 := nil
//   if valType(tb) == "O"
//     tb:Destroy()
//   endif
//   tb := nil
//  if valtype(oErr) == "L"
//     return oErr
//   else
//     return .F.
//  endif
// end sequence
//Return .T.
/*
Function GetSfForRaz(lBuy,cIdPartner,FunctionParam,aSf,aSchAn)
local  oErr,aJrnDoc := {},i,cVid,lReturn,tbDoc,aParam,n
Local cTmpFileName,cTmpFileNameCdx,nSumReg, lAv := .F.,aDocForSF := {},StrTp
Static ObjBook
  if lBuy
    cVid := "1"
    aParam := {0,"1","ПЛ"}
  else
    cVid := "2"
    aParam := {0,"2","ПЛ"}
  endif

  begin sequence
  if FunctionParam[5][1] == 1
    AADD(aJrnDoc,101)
  endif
  if FunctionParam[5][2] == 1
    AADD(aJrnDoc,201)
  endif
  if !FILE( cTmpFileName )
    cTmpFileName :=  GetTempFile()
    cTmpFileNameCdx := cTmpFileName + ".Cdx"
    cTmpFileName :=  cTmpFileName + ".Dbf"
  endif
  //Для каждого журнала разносим платежи
  for i := 1 to len(aJrnDoc)
    if ValType(tbDoc) == "O"
      tbDoc:Destroy()
      tbDoc := nil
    endif
    selectdocforbook( cTmpFileName,.F.,aJrnDoc[i],aSchAn,,;
                     ,DTOS(FunctionParam[3]),cVid,,,,,@lReturn)

    if lReturn
      tbDoc := CreateDbRecord( cTmpFileName )
      tbDoc:OrdCreate("TAG_DOC","SRC_DATE")
      tbDoc:SetOrder("TAG_DOC")
      tbDoc:GoTop()
      if tbDoc:Eof()
         tbDoc:Destroy()
         tbDoc := nil
         Loop
      endif
      if !(ValType(ObjBook) == "O")
        ObjBook := clsTax_Book():New()
        ObjBook:Open()
      endif

      do while !tbDoc:Eof()
        nSumReg := tbDoc:FieldValue("SRC_SUM") - tbDoc:FieldValue("SUM_REG")
        //lAv := .T.
        For n := 1 to len(aSf)
          //lAv := .F.
          if !aSf[n][3]
            if !ObjBook:BeforeAppend(aParam)
              Break(.F.)
            endif
            if !ObjBook:Append()
              Break(.F.)
            endif
            ObjBook:SF_ID := aSf[n][1]
            ObjBook:DS:JRN_ID := tbDoc:FieldValue("JRN_ID") //tbDoc:JRN_ID
            ObjBook:SRC_ID := tbDoc:FieldValue("SRC_ID")  //tbDoc:SRC_ID
            ObjBook:Save()
            //Если зарегистрили на всю сумму - переходит на следующую с-ф
            if nSumReg > aSf[n][2]
              aSf[n][3] := .T.
              nSumReg := nSumReg - aSf[n][2]
              //lAv := .T.
              Loop//Exit
            else // если зарегистрирован весь платеж - переходим на следующий платеж
              //nSumReg := nSumReg - aSf[n][2]
              aSf[n][2] := aSf[n][2] - nSumReg
              if aSf[n][2] == 0
                aSf[n][3] := .T.
              endif
              Exit //LOOP
            endif
          //else
          //  lAv := .T.
          endif
        next

        tbDoc:Skip(1)
      enddo
    endif
  next
   //Для каждого журнала создаем авансовые записи
  if !lBuy
    if ValType(tbDoc) == "O"
      tbDoc:Destroy()
      tbDoc := nil
    endif
    for i := 1 to len(aJrnDoc)

        aDocForSF := {}
        selectdocforbook( cTmpFileName,.T.,aJrnDoc[i],aSchAn,,;
                         ,DTOS(FunctionParam[3]),"2",,,,,@lReturn)

        if lReturn
          tbDoc := CreateDbRecord( cTmpFileName )
          do while !tbDoc:Eof()
            AADD(aDocForSF,tbDoc:FieldValue("nRec"))
            tbDoc:Skip(1)
          enddo

        endif
        if Len(aDocForSF) > 0
          if aJrnDoc[i] == 101
            StrTp := "0"
          elseif aJrnDoc[i] == 201
            StrTp := "1"
          endif  //
          CreateRecAvSF(StrTp,aDocForSF,FunctionParam[3] ,cIdPartner)
          aDocForSF := {}
        endif

      if ValType(tbDoc) == "O"
        tbDoc:Destroy()
        tbDoc := nil
      endif
    next
  endif
  if ValType(tbDoc) == "O"
    tbDoc:Destroy()
    tbDoc := nil
  endif
  if FILE( cTmpFileName )
    FERASE( cTmpFileName )
  endif
  if FILE( cTmpFileNameCdx  )
    FERASE( cTmpFileNameCdx  )
  endif

  recover using oErr
  if valtype(oErr) == "L"
     return oErr
   else
     return .F.
  endif
 end sequence
Return .T.
*/



Function  CreateRecAvSF(StrTp,aDocForSF,dDate,nPartner)
local  oErr
local cStrTp := ""
local DocType := 0
local oObjSf,aParamIni
 begin sequence
 //altd()
 cStrTp := StrTp

 //получить параметры по умолчанию
 aParamIni := {}
 If !GetParamIni("2",.T.,@aParamIni)
   Break(.F.)
 endif
 DocType := aParamIni[8]
 oObjSf := clsTax_Inv():New()
 oObjSf:Open()
 if !oObjSf:BeforeAppend("2", "ПР", "7", "", DocType,aParamIni[5],aParamIni[6],.T. )
   Break(.F.)
 endif
 if !oObjSf:Append()
   Break(.F.)
 endif
 oObjSf:DOC_DATE  := dDate
 oObjSf:REG_DATE  := dDate
 oObjSf:PRT_ID := nPartner
 oObjSf:PRT_ADDRID := nPartner
 oObjSf:CreateStrForDoc(aDocForSF,cStrTp)
 oObjSf:Save()
 oObjSf:Destroy()
 oObjSf := nil
 recover using oErr
  if ValType(oObjSf) == "O"
    oObjSf:Destroy()
  endif
  oObjSf := nil
  if valtype(oErr) == "L"
     return oErr
   else
     return .F.
  endif
 end sequence
Return .T.

Function  GetFindPartner(objDoc,s,cField)
local  oErr
local nAn := 0 ,nAnalitSys := 0, nLenSys := 0,sAlg := "",sRas := ""
local cLefr := "", cRight := "" ,lFirst := .T.,nDimId := "",cKey := ""  //nDimId := 0
local cFieldName := "PART_ID",  cTagName := "FULLCODE" ,lRet := .F.,lPartner := .F.
local cAnalitSys := "",cTbName := "Partner.DBF",nPartnerId := "",nPID := 0  //nPartnerId := 0
 begin sequence
 //altd()
 objDoc:SCHSEG:MoveFirst()
 If objDoc:SCHSEG:EOF()
   s := {"","","",""} //{"","","",0}
   Break(.T.)
 endif


 do while !objDoc:SCHSEG:EOF()
    nAn := nAn + objDoc:SCHSEG:DIMLEN
    if objDoc:SCHSEG:DIM:SYS_ID == "0000000000000000000003" //3

       if objDoc:SCHSEG:DIM:ISSYSTEM  .Or. lFirst // системная аналитика перетирает остальные
          sAlg := objDoc:SCHSEG:DIM:ALG_CODE
          nAnalitSys := nAn
          nLenSys := objDoc:SCHSEG:DIMLEN
          if objDoc:SCHSEG:DIM_ID == '0000000000000000001003'
            nDimId := "" //0
          else
            nDimId := objDoc:SCHSEG:DIM_ID
          endif
          lFirst := .F.
        endif
        /*
        if lFirst
          sAlg := objDoc:SCHSEG:DIM:ALG_CODE
          nLenSys := objDoc:SCHSEG:DIMLEN
          nAnalitSys := nAn
          nDimId := objDoc:SCHSEG:DIM_ID
          lFirst := .F.
        endif
        */
        lPartner := .T.
    endif
    nAn := nAn + 1
    objDoc:SCHSEG:MoveNext()
 enddo
 if lPartner
   cLefr := alltrim(str(nAnalitSys))
   cRight :=  alltrim(str(nLenSys))
   cAnalitSys := objDoc:CANALIT
   cAnalitSys := Right(Left(cAnalitSys,nAnalitSys),nLenSys)
   cKey := cAnalitSys
   if nDimId != 0
     cTbName := "DIM_ANL.DBF"
     cFieldName := "SYSREC_ID"
     cTagName := "CODE"
     //???????????????????????????
     cKey := STR(nDimId,10,0)+UPPER(cAnalitSys)
   endif
   if LookUpSeek(cTbName,cTagName,@lRet,cKey,cFieldName,@nPartnerId)
     if lRet
       nPID := nPartnerId
     endif
   endif
   sRas := " Right(Left(" + cField + "," + cLefr + ")," + cRight +")"
   s := {sRas,sAlg,cAnalitSys,nPID}
 else
    //altd()
   s := {"","","",""}
 endif
 recover using oErr

  if valtype(oErr) == "L"
     return oErr
   else
     return .F.
  endif
 end sequence

Return .T.

Function GetSFDocType(lRet,SFCTG,DocType)
local  oErr
local tb, cTbName := "Doc_Type.Dbf"
 begin sequence
 lRet := .F.
 tb := CreateDbRecord(B6_DBF_PATH + cTbName)
 tb:Scope("1601"+SFCTG,"1601"+SFCTG,"TAG_MOVE")
 tb:MoveFirst()
 if tb:Eof()
   lRet := .T.
   DocType := ""
   Break(.T.)
 endif
 DocType := tb:IDDOCTYPE
 lRet := .T.
 tb:Destroy()
 tb := nil
 recover using oErr
  if ValType(tb) == "O"
   tb:destroy()
  endif
  tb := nil
  if valtype(oErr) == "L"
     return oErr
   else
     return .F.
  endif
 end sequence
Return .T.
/*
проверка на последнюю запись для данного С_Ф
передаем nSFId - идентификатор С-Ф,nBookId - идентификатор записи
lDel -  если Т - это для удаления - игонорируем записи на суммовую разницу
возвращаем - lRet - Т - запись последняя
nRec -  идентификатор последней записи
dDate - дата регистрации последней записи
*/
Function CheckSequencesEntering(nSFId,nBookId,lRet,nRec,lDel,dDate)
local  oErr
local tb,s := ""// cTbName := "Tax\Book.Dbf", cTagName := "TAG_SFBK" ,cKey
 begin sequence
 //altd()
 lRet := .F.
 s := " Select RecNo() as nRec,BOOK_ID,SRC_DATE "
 s += " From Tax_Book "
 s += " Where SF_ID == '" + nSFId + "'"
 if pCount() == 5
   if lDel
     s += " .And. !(REC_TP == 'СМ')"
   endif
 endif
 s += " order by nRec desc "
 tb := CreateDbRecord(s)
 if empty(tb)
   Break(.F.)
 endif
 tb:GoTop()
 if tb:Eof() // для данного С-Ф нет записей в книге
   lRet := .T.
   nRec := ""
   Break(.T.)
 else
   nRec := tb:FieldValue("BOOK_ID")
   dDate := tb:FieldValue("SRC_DATE")
   if !Empty(nBookId)
     if nBookId == nRec
       lRet := .T.
     endif
   endif
 endif
 /*
 tb := CreateDbRecord(PublicVars():LoadPath() + cTbName,cTagName)
 cKey := nSFId//STR(nSFId,10)
 tb:Scope(cKey,cKey,cTagName)
 tb:GoTop()
 if tb:Eof() // для данного С-Ф нет записей в книге
   lRet := .T.
   nRec := 0
   Break(.T.)
 endif
 if pCount() == 5
   if lDel
     s := " !(REC_TP == 'СМ')"
     tb:Filter(s)
   endif
 endif
 tb:MoveLast()
 nRec := tb:Book_Id
 dDate := tb:SRC_DATE
 if Empty(nBookId)
   Break(.T.)
 endif
 if nBookId >= nRec
   lRet := .T.
 endif
 */
 tb:Destroy()
 tb := nil
 recover using oErr
  if valtype(tb) == "O"
    tb:destroy()
  endif
  tb := nil
  if valtype(oErr) == "L"
     return oErr
   else
     return .F.
  endif
 end sequence
Return .T.

Function CreatePrmIni(DS)
local oErr, cAl := DS:Alias , nRec
 begin sequence

 if DS:Append()
   DS:FieldValue("MOD_DEF",Space(22))
   DS:FieldValue("MOD_DEF_F",Space(22))
   DS:FieldValue("ENT_ID",Space(22))
   DS:FieldValue("ENT_ADDRID",Space(22))
   DS:FieldValue("IN_SM_PS",.F.)
   //DS:FieldValue("IN_SM_COM",'Закупки. При формировании счета-фактуры по документам - источникам объединять одноименные позиции: ДА/НЕТ')
   DS:FieldValue("IN_CNT",.F.)
   //DS:FieldValue("IN_CNT_COM",'Закупки. При формировании книги покупок контролировать хронологию записей: ДА/НЕТ')
   //DS:FieldValue("RET_BUY",.T.)
   DS:FieldValue("OUT_SM_PS",.F.)
   //DS:FieldValue("OUT_SM_COM",'Продажи. При формировании счета-фактуры по документам - источникам объединять одноименные позиции: ДА/НЕТ')
   DS:FieldValue("OUT_CNT",.F.)
   //DS:FieldValue("OUT_CN_COM",'Продажи. При формировании книги покупок контролировать хронологию записей: ДА/НЕТ')
   //DS:FieldValue("RET_SALE",.T.)
   DS:FieldValue("OUT_PL","1")
   //нет полей
   //DS:FieldValue("OPER_DEFS",Space(22))
   //DS:FieldValue("OPER_DEFB",Space(22))
   DS:FieldValue("DOC_TP",Space(22))
   DS:FieldValue("DOC_AVTP",Space(22))
   DS:FieldValue("OUT_SFCUR",.F.)
   DS:FieldValue("IN_SFCUR",.F.)
   DS:FieldValue("DATE_BEG",CTOD(""))
   DS:FieldValue("TRANS_DATE",CTOD(""))
   DS:FieldValue("TRANS_OK",.F.)
   DS:FieldValue("TAX_PERIOD","1")
   DS:FieldValue("DOC_BUYTP",Space(22))
   DS:FieldValue("IN_QUE","2")
   DS:FieldValue("OUT_QUE","2")
   DS:FieldValue("IN_TOP",Space(22))
   DS:FieldValue("OUT_TOP",Space(22))
   DS:FieldValue("OUT_TOPA",Space(22))
   DS:FieldValue("OUT_TOPC",Space(22))
   DS:FieldValue("BANK_AV","2")
   DS:FieldValue("CASH_AV","2")
   DS:FieldValue("DopSf",.T.)
   DS:FieldValue("COM_CF",.F.)
   DS:FieldValue("NM_RULE","1")
   DS:FieldValue("DOC_BUYAV",Space(22))
   DS:FieldValue("IN_TOPA",Space(22))
   DS:FieldValue("BANK_AV_B","1")
   DS:FieldValue("CASH_AV_B","1")
   DS:FieldValue("PART_RATE","1")
   DS:FieldValue("NM_AV",.F.)
   DS:FieldValue("NM_AV_TXT","Авансовый платеж")
   DS:FieldValue("DOP_AV",.F.)
   DS:FieldValue("COM_AV",.F.)
   DS:FieldValue("IN_NUM",.T.)

   DS:FieldValue("ID","{D1A81E1D-0D1B-4068-B1F0-BDBA6FB81C20}")
   nRec := (cAl)->(RecNo())
 else
   Break(.F.)
 endif
 (cAl)->(DbGoTop())
 Do While !(cAl)->(Eof())
   if (cAl)->(RecNo()) != nRec
     (cAl)->(DbGoTo(nRec))
     (cAl)->(DbDelete())
     exit
   endif
   (cAl)->(DbSkip(1))
 enddo

 recover using oErr
  if valtype(oErr) == "L"
     return oErr
   else
     return .F.
  endif
 end sequence
Return .T.

*******************************************************************************
* Формируем темповую таблицу из записей документов согласно переданного журнала
* которые могут использоваться для создания с_ф или
* регистрации в книге покупок/продаж
* с отметкой использования при создании с_ф - Поле Oper_Fact (Sf_Id) == cSf
* cDbPath      - полный путь к базе, например C:\best\Best53\SERVER\bin\hbsp.bdll
* cTmpFileName - полный путь к TMP таблице, куда положить результат выборки
* lSF          - Т - выборка для С_Ф иначе для регистрации в книгу
* nJrn         - числовой идентификатор журнала, в котором выбираем записи
* cPartner     - GUID22 - ID партнера , под которого делается выборка
* cCntDocId    - Идентификатор документа основания - параметр не обязательный, если передпли, то д-ты фильтруем по этому документу основания
* cValDoc       - валюта по которой нужно фильтровать документы,
*если не передали - фильтр по валюте не накладывается
* cVid         - выд движения
* lNegativeSF  - .t. отрицательные СФ
* lStorno - Т - сторнирующая запись
* ------ определит журнал lSclad       - признак АРМа  Склад(.Т.) / Запасы(.F.)
* cSF          - GUID22 - ID счет-фактуры
* - для книги - идентификатор зарегистрированного документа
* aInsDoc         - массив выбранных записей
* если не передали или пустой - отмечаем по cSF в базе
* lReturn      - результат выполнения процедуры
* cDivCode - код подразделения
* cDocId - идентификатор сязанного д-та
* aKOP - массив кодов операций НДС 1 - KOP_NDS,2 - KOP_NNDS,3 - KOP_NDS0,4 - KOP_AG_NDS
*******************************************************************************
FUNCTION selectdocforbook(cTmpFileName,lSF,nJrnDoc,;
                          cPartner,cCntDocId,cValDoc,;
                          sDateBeg,sDateEnd,;
                          cVid,lNegativeSF,lStorno,;
                          cSF,aInsDoc,lReturn,cDivCode,cDocId,aKOP)
  Memvar /*aAnalit,*/cKey,cKey1,lS,cVal,cTagName,/*aField,*/aStru,cSfId,nJrn,laIns,aIns
  Memvar sDateB,sDateE,lpStorno,lpSf
  MemVar obj,tbTmp,cCDocId,cDivAll,lpNoDiv,lpKOPNDS ,aKOPNDS
  local cType//,cSchet //sSql,
  local i, oError
  local  cTbName := "",aType := {},cArm,cKeyGr,cMsg //tbMove,cMoveName := ""
  local cDiv,cMove,nCount,cMoveP := "",cMoveR := "",lNoMove := .F.
  Private lpStorno,lpSf,lpNoDiv := .F.
  Private sDateB := sDateBeg, sDateE := sDateEnd
  Private /*aAnalit,*/cKey,cKey1,lS,cVal,cTagName,/*aField,*/aStru,cSfId,nJrn,laIns,aIns
  Private /*tbDoc,*/tbTmp
  Private obj,cCDocId // класс документа движения
  Private cDivAll := ""
  Private lpKOPNDS := .F. // нет фильтра на коды
  //ScopeGrantV(cArm, cTypeAction)
  // Проверим на права на просмотр
  if !(ValType(cDivCode) == "C")
    cDivCode := Space(6)
  endif
  if !(ValType(cDocId) == "C")
    cDocId := Space(22)
  endif
  //не будем проверять на совпадение кодов
  //для документа по с-ф
  aKOPNDS := aKOP

  If ValType(aKOPNDS) == "A"
    for i := 1 to len(aKOPNDS)
      if !Empty(aKOPNDS[i])
        lpKOPNDS := .T.
        exit
      endif
    next


  endif


  Do case
    case nJrnDoc == "0101"
      cKeyGr := "1101"
      cArm := "01"
      cDiv := "01"
      nCount := 16
    case nJrnDoc == "0201"
      cKeyGr := "1102"
      cArm := "02"
      cDiv := "02"
      nCount := 16
    case nJrnDoc == "0301"
      cKeyGr := "1103"
      cArm := "03"
      cDiv := "05"
      cMove := "07"
      nCount := 6
    case nJrnDoc $ "0901,0904"
      cKeyGr := "1109"
      cArm := "09"
      cDiv := "06"
      cMove := "08"
      nCount := 6
    case nJrnDoc == "0501"
      cKeyGr := "1105"
      cArm := "05"
    case nJrnDoc == "TV01"
      cKeyGr := "11TV"
      cArm := "TV"
    case nJrnDoc $ "PM01,PM02"
      cKeyGr := "11PM"
      cArm := "PM"
    case nJrnDoc == "1701"
      cKeyGr := "1117"
      cArm := "17"
  endcase
  //// !!!!!!!!!!!! Права доступа для новых денег пока обходим !!!!!!!!!!!!!!
  /// !(nJrnDoc $ "PM01,PM02") .And.

  if  !ScopeGrantV(cArm,cKeyGr)  // Нет прав на подсистему
    lReturn := .F.
    Return .T.
  endif
  if !(nJrnDoc $ {"0501","TV01","PM01","PM02","1701"})
    if !ScopeGrantV(cArm,cDiv,.T.)
      if Empty(cDivCode)
        lpNoDiv := .T.
      else
      // если передали подразделение и доступны все
      // будем проверять только на это
        cDivAll := Upper(cDivCode)
      endif
    else
      if !ScopeGrantV(cArm,cDiv)  // Нет прав на подсистему
        lReturn := .F.
        Return .T.
      endif

      cDivCode := Upper(cDivCode)
      do while !NAL_GRANTV->(Eof())
        cDiv := Upper(SubStr( NAL_GRANTV->VKEY, 3, nCount))
        if !Empty(cDivCode)
          if (cDiv $ cDivCode)
            cDivAll += cDiv + ","
          endif
        else
          cDivAll += cDiv + ","
        endif

        NAL_GRANTV->(DbSkip(1))
      enddo
      /*
      if !Empty(cDivCode)
        cDivAll :="'" + cDivAll + "'"
        // если переданное подразделение не входит в доступные - сваливаем
        if !(Upper(cDivCode) $ Upper(cDivAll))
          lReturn := .F.
          Return .T.
        endif
        cDivAll := Upper(cDivCode)
      endif
      */
    endif
  endif

  if nJrnDoc $ {"0301","0901","0904"}
    if !ScopeGrantV(cArm,cMove,.T.)
      lNoMove := .T.
    else
      if !ScopeGrantV(cArm,cMove)  // Нет прав на подсистему
        lReturn := .F.
        Return .T.
      endif
      do while !NAL_GRANTV->(Eof())
        cMove := Alltrim(SubStr( NAL_GRANTV->VKEY, 3))
        if cMove[1] == "1"
          cMove := SubStr( cMove, 2)
          cMoveP += "'" + cMove + "',"
        else
          cMove := SubStr( cMove, 2)
          cMoveR += "'" + cMove + "',"
        endif
        NAL_GRANTV->(DbSkip(1))
      enddo
    endif
  endif

  if nJrnDoc == "1701"
  //Права доступа на виды движения   cVid
    if !ScopeGrantV("17","19",.T.)
    // Доступны все виды для оборотных
      if  cVid == "1"
        cMoveP := "01,1a,"  //07
      else
        cMoveP := "07,"
      endif
    else
      if !ScopeGrantV("17","19")
      // Все не доступны
        cMoveP := ""
      else
        do while !NAL_GRANTV->(Eof())
          cMove := SubStr( NAL_GRANTV->VKEY, 5,2)
          if  cVid == "1"
            if cMove $ "01,1a,"
              cMoveP += "'" + cMove + "',"
            endif
          else
            if cMove == "07,"
              cMoveP += "'" + cMove + "',"
            endif
          endif
          NAL_GRANTV->(DbSkip(1))
        enddo
      endif
    endif
    if !ScopeGrantV("17","20",.T.)
    // Доступны все виды для оборотных
      if  cVid == "1"
        cMoveR := "11,"   //24
      else
        cMoveR := "24,"
      endif
    else
      if !ScopeGrantV("17","20")
      // Все не доступны
        cMoveR := ""
      else
        do while !NAL_GRANTV->(Eof())
          cMove := SubStr( NAL_GRANTV->VKEY, 5,2)
          if  cVid == "1"
            if cMove == "11"
              cMoveR += "'" + cMove + "',"
            endif
          else
            if cMove == "24"
              cMoveR += "'" + cMove + "',"
            endif
          endif
          NAL_GRANTV->(DbSkip(1))
        enddo
      endif
    endif
    if Empty(cMoveP) .And. Empty(cMoveR)
      lReturn := .F.
      Return .T.
    endif
    aType := StrSplit(cMoveP + cMoveR,",")
  endif
  // создадим массив доступных счетов, цехов, видов движения....

  cVal := cValDoc
  nJrn := nJrnDoc
  aIns := aInsDoc
  cCDocId := cCntDocId
  lReturn := .F.
  BEGIN SEQUENCE
  if !(ValType(lSf) == "L")
    lpSf := .F.
  else
    lpSf := lSf
  endif

  if Empty(cSF)
    cSfId := Space(22)//"NOT"
  else
    cSfId := cSf
  endif

  if ((ValType(aIns)== "A") .And. (Len(aIns) > 0 ))
    laIns := .T.
  else
    laIns := .F.
  endif
  // Если не передали идентификатор партнера - нечего искать
  /*
  if len(aSchAn) < 0 //Empty(cPartner) .And. !lAllPartner
    Break(.T.)
  endif
  aAnalit := aSchAn
  */
  /*
  if Empty(cPartner)
    Break(.T.)
  endif
  */
// Формируем в зависимости от переданного журнала
  DO case
    CASE nJrn ==  "0101" // Банк
      //cTbName := "BANK\Doc51"
      obj := clsTaxForDoc51():New()
    CASE nJrn ==  "0201" // Касса
      //cTbName := "CASH\K_ORDER"
      obj := clsTaxForK_ORDER():New()
    CASE nJrn ==  "0301" // Склад
      //cTbName := "SCLAD\MDOC"
      //cMoveName := "SCLAD\MOVES"
      obj := clsTaxForMDoc():New()
    CASE nJrn ==  "0501" // Акты на продажу
      //cTbName := "REAL\ACT"
      obj := clsTaxForRealAct():New()
    CASE nJrn $  "0901,0904" // Запасы
      //cTbName := "ZAPAS\MDOC"
      //cMoveName := "ZAPAS\MOVES"
      obj := clsTaxForZapasMDoc():New()
    CASE nJrn == "TV01" //1201// Акты на закупку
      //cTbName := "TOVAR\ACT"
      obj := clsTaxForTovarAct():New()
    CASE nJrn == "1701"
      obj := clsTaxForAssets():New()
    case nJrn $ "PM01,PM02"
      obj := clsTaxForFinDoc():New()
    OTHERWISE // Не верно передали журнал
      messagebox("Selectdocforbook. Не верно передан журнал документов!",TITLEAPP,48)
      Break(.F.)
  END case
  //tbDoc := CreateDbRecord(B6_DBF_PATH + cTbName)
  //if !Empty(cMoveName)
  //  tbMove := CreateDbRecord(publicVars():LoadPath + cMoveName)
  //endif
    obj:Open()

    if .not.(ValType(lNegativeSF)=="L")
      lNegativeSF := .F.
    endif

    if .not.(ValType(lStorno)=="L")
      lpStorno := .F.
    else
      lpStorno := lStorno
    endif

    aStru := { {"JRN_ID",     "C",4,0}, ;  // Идентификатор журнала
               {"SRC_TP",     "C", 3,0}, ; // Код типа документа
               {"SRC_ID",     "C",22,0}, ;  //Идентификатор документа
               {"SRC_NUM",    "C", 6,0}, ; //Номер документа
               {"SRC_DATE",   "D", 8,0}, ; //Дата документа
               ;//{"SRC_SCH",    "C",16,0}, ;
               ;//{"SRC_CODE",   "C",60,0}, ;
               {"SRC_PartN",  "C",30,0}, ;
               {"SRC_PartId", "C",22,0}, ;
               {"SRC_VCODE",  "C", 3,0}, ;
               {"SRC_DRate",  "N",19,5}, ;
               {"SRC_SUM"    ,"N",19,4}, ;
               {"SUM_REG"    ,"N",19,4}, ;
               {"SRC_Centr",  "C",30,0}, ;
               {"KOP_NDS",  "C",2,0}, ;
               {"KOP_NNDS",  "C",7,0}, ;
               {"KOP_NDS0",  "C",7,0}, ;
               {"KOP_AG_NDS",  "C",7,0}, ;
               {"nRec",       "N",10,0},;
               {"IsChecked",  "l", 1,0},;
               {"RecType",    "C", 1,0} } //Для возврата платежей - 0 - документ основания совпадает с основанием 1 - не совпадает или не передавали

    //if lpSf
    //  AADD(aStru,{"IsChecked",  "l", 1,0})  // отметка об использовании - по полю SF или по переданному массиву
    //endif

    if FILE( cTmpFileName )
      FERASE( cTmpFileName )
    endif
    DBCREATE(cTmpFileName, aStru,"DBFCDX")
    tbTmp := CreateDbRecord( cTmpFileName )

      //n := Len(aSchAn)
      if lpSf // Для с_ф выбирем записи по идентификатору с-ф
        if !Empty(cSfId) //.And. (Len(cSfId) == 22)
          Obj:SetOrder("TAG_SF")
          Obj:Scope(cSfId,cSfId,"TAG_SF")
          Obj:GoTop()
          Do while !Obj:Eof()
          // если передали коды - проверим и их
          // у с-ф могли их изменить - и теперь они не будут совпадать с первоначальным д-том
            if lpKOPNDS
              if ( Empty(Obj:KOP_NDS) .Or. Obj:KOP_NDS ==  aKOPNDS[1]) .And. ;
                 ( Empty(Obj:KOP_NNDS) .Or. Obj:KOP_NNDS ==  aKOPNDS[2]) .And. ;
                 ( Empty(Obj:KOP_NDS0) .Or. Obj:KOP_NDS0 ==  aKOPNDS[3]) .And. ;
                 ( Empty(Obj:KOP_AG_NDS) .Or. Obj:KOP_AG_NDS ==  aKOPNDS[4])
                   WriteToTmp()
              endif
            else
              WriteToTmp()
            endif
            Obj:Skip(1)
          enddo
        endif
      Else // для книги вытираем запись которая зарегистрена в книге
        if !Empty(cDocId)
          if nJrn $ "PM01,PM02,1701"
            cTagName := "TAG_ID"
          else
            cTagName := "TAG_OPER"
          endif
          if Obj:Seek(cSfId,.T.,cTagName)
            if Obj:SRC_RST <= 0
              // если передали коды - проверим и их
              // могли их изменить - и теперь они не будут совпадать с первоначальным д-том
              //if lpKOPNDS
              //  if ( Empty(Obj:KOP_NDS) .Or. Obj:KOP_NDS ==  aKOPNDS[1]) .And. ;
              //     ( Empty(Obj:KOP_NNDS) .Or. Obj:KOP_NNDS ==  aKOPNDS[2]) .And. ;
              //     ( Empty(Obj:KOP_NDS0) .Or. Obj:KOP_NDS0 ==  aKOPNDS[3]) .And. ;
              //     ( Empty(Obj:KOP_AG_NDS) .Or. Obj:KOP_AG_NDS ==  aKOPNDS[4])
              //       WriteToTmp()
              //   endif
              //else
                WriteToTmp()
              //endif
            endif
          endif
        endif
      Endif

      // Для всех кроме склада и запасов
      // для каждого счета формируем скоп
      if lpSf
        if Empty(cPartner)
          cTagName := "Tag_ForSf"
        else
          cTagName := "Tag_ForSfP"
        endif
      else
        cTagName := "Tag_BOOK"
      endif
      if !(nJrn $ {"0301","0901","0904","1701"})

        //for i := 1 to n
          //lS := .F.
          cKey := "" //cPartner
          cKey1 := ""
          do case
          //Для денег сторно -возврат денег
            case nJrn == "0101"
              //if lpStorno
              //  cKey += iif(cVid == "1","0","1")
              //  cKey1 += iif(cVid == "1","0","1")
              //else
                cKey += iif(cVid == "1","1","0")
                cKey1 += iif(cVid == "1","1","0")
              //endif

            case nJrn == "0201"
              //if lpStorno
              //  cKey += iif(cVid == "1","П/О","Р/О")
              //  cKey1 += iif(cVid == "1","П/О","Р/О")
              //else
                cKey += iif(cVid == "1","Р/О","П/О")
                cKey1 += iif(cVid == "1","Р/О","П/О")
              //endif
           case nJrn == "PM01"
             cKey += "1" + iif(cVid == "1","2","1")
             cKey1 += "1" + iif(cVid == "1","2","1")
           case nJrn == "PM02"
             cKey += "2" + iif(cVid == "1","2","1")
             cKey1 += "2" + iif(cVid == "1","2","1")
          end case
          if !Empty(cPartner)
            cKey += cPartner
            cKey1 += cPartner
          endif

          if Empty(sDateB)
            cKey += "19000101"
          else
            cKey += sDateB
          endif
          if Empty(sDateE)
            cKey1 += "21000101"
          else
            cKey1 += sDateE
          endif



          //if aAnalit[i][2] == 1
          //   cKey += aAnalit[i][4]
             //lS := .T. // аналитическое измерение первое - можно наложить и на него скоп
          //endif
          //if lpSf // отсечем документы у которых есть с-ф
          //  cKey += Space(22)
          //endif
          SelectionDoc(/*i*/)
        //next
      elseif nJrn == "1701"
        if cVid == "1"
          cTagName := "TAG_MVPRTS"
        else
          cTagName := "TAG_MVPRT"
        endif
        for i := 1 to len(aType)
          if Empty(aType[i])
            exit
          endif
          cKey   := UPPER(aType[i])
          cKey1  := UPPER(aType[i])
          if !Empty(cPartner)
            cKey += cPartner
            cKey1 += cPartner
          endif
          if Empty(sDateB)
            cKey += "19000101"
          else
            cKey += sDateB
          endif
          if Empty(sDateE)
            cKey1 += "21000101"
          else
            cKey1 += sDateE
          endif
          SelectionDoc()

        next
      elseif  nJrn $ {"0301","0901","0904"}// Sclad,Zapas
        /*
        // определим  Vid и type соответствующий закупкам продажам в таблице Moves
        sSql := "" //"{|| "
        if lpStorno
          IF cVid == "1"
            sSql += " Vid=='2'.And. type=='5' "
          else
            sSql += " Vid=='1'.And. type=='5' "
          endif
        else
          IF cVid == "1"
            sSql += " Vid=='1'.And.YESTV==.T. "
            if lNegativeSF
              sSql += " .And. .not.(type=='4'.or.type=='5') " //!inlist(type,'4','5') "

            else
              sSql += " .And. .not.type=='4' "//!inlist(type,'4') "
            endif
          ELSE
            sSql += " Vid=='2'.And.YESDOP==.T. "
            if lNegativeSF
              sSql += ".And. .not.type$'4;6;%;+;5;'" //!inlist(type,'4','6','%','+','5') "
            else
              sSql += ".And. .not.type$'4;6;%;+'"//!inlist(type,'4','6','%','+') "
            endif
          ENDIF
        endif
        sSql += " .And. .not.(type=='?' .And. !Empty(typeex)) "
        //sSql += " }"

        tbMove:Filter(sSql)
        tbMove:GoTop()
        */
        aType := {}
        if !GetMovesType(cVid/*"2"*/,if(nJrn ==  "0301",.T.,.F.),@cType,lNegativeSF)
          Break(.F.)
        endif
        if Empty(cType)
          cArm := iif(nJrn ==  "0301"," складу. "," запасам. ")
          cMsg := "Выбор документов по" + cArm +" Нет операций связанных"
          if cVid == "1"
             cMsg := cMsg + " с закупками!"
          else
             cMsg := cMsg + " с продажами!"
          endif
          Messagebox(cMsg)
          Break(.F.)
        else
          aType := StrSplit(cType,",")
        endif
        //Do while !tbMove:Eof()
        for i := 1 to len(aType)
        //для каждой записи , удовлетворяющей MOVES...
          //for n:=1 to len(aAnalit)
           // lS := .F.
            //if Empty( aAnalit[n,4] )
              //tbMove:Skip(1)
              //Loop
            //endif
            cType  := Upper(aType[i]) //Upper(tbMove:FieldValue("TYPE"))
            if cVid == "1"
              if !lNoMove
                if AT(cType,cMoveP) < 1
                  loop
                endif
              endif
            else
              if !lNoMove
                if AT(cType,cMoveR) < 1
                  loop
                endif
              endif
            endif
            //cSchet := aAnalit[n,1]
            cKey   := UPPER(cVid)+ cType  //UPPER(cSchet)
            cKey1   := UPPER(cVid)+ cType
            if !Empty(cPartner)
              cKey += cPartner
              cKey1 += cPartner
            endif
            if Empty(sDateB)
              cKey += "19000101"
            else
              cKey += sDateB
            endif
            if Empty(sDateE)
              cKey1 += "21000101"
            else
              cKey1 += sDateE
            endif


            //if aAnalit[n,2] == 1
            //  cKey += UPPER(aAnalit[n,4])
            //  lS := .T.
            //endif
            SelectionDoc(/*n*/)
          //next
        next
        //  tbMove:Skip(1)
        //enddo
      endif

    lReturn:= .T.
  RECOVER USING oError
     if valtype(oError) == "L"
       lReturn := oError
     endif
  END SEQUENCE

  if ValType(obj) == "O"
    obj:Destroy()
    obj := nil
  endif
  //if ValType(tbMove) == "O"
  //  tbMove:Destroy()
  //  tbMove := nil
  //endif
  if ValType(tbTmp) == "O"
    tbTmp:Destroy()
    tbTmp := nil
  endif

RETURN lReturn



*******************************************************************************
* Первично совпадение по имени
* lSys - Т - передали системную ищем в аналитиках
* иначе - (по умолчанию) передали из аналитического справочника - ищем в системном                                                                             *
*******************************************************************************
Function GetAnalitByPartner(cDim,cPartnerName,cPartnerCode,lRet,cCode,lSys,cIdPartner)
Local tbPartner,tbAnalit
local xCode,lS
local oErr
 begin sequence
  tbPartner := CreateDbRecord(B6_DBF_PATH + "Partner.Dbf")
  tbAnalit := CreateDbRecord(B6_DBF_PATH + "Analit_Seg.Dbf")
  if ValType(lSys) == "L"
    lS := lSys
  else
    lS := .F.
  endif
  lRet := .F.
  cCode := ""
  if !lS
    xCode := Upper(StrTran( cPartnerName,CHR(255),CHR(32) ))
    tbPartner:SetOrder("FullName")
    if tbPartner:Seek( xCode,.T.,"FullName")
      cCode := tbPartner:FieldValue("Code") // Перепишем если найдем совпадение и названия и кода
      cIdPartner := tbPartner:FieldValue("Part_Id")
      lRet := .T.
       do while xCode == Upper(StrTran(tbPartner:FieldValue("Name"),CHR(255),CHR(32) ))
        if UPPER(AllTrim(tbPartner:FieldValue("Code") )) == UPPER(Alltrim(cPartnerCode))
          cCode := tbPartner:FieldValue("Code")
          cIdPartner := tbPartner:FieldValue("Part_Id")
          Exit
        endif
        tbPartner:Skip(1)
      enddo
    endif
  else
    xCode := PADR(cPartnerName,100," ")
    tbAnalit:SetOrder("NAME")
    if tbAnalit:Seek(cDim+UPPER(xCode),.T.,"NAME")
      cCode := tbAnalit:FieldValue("Code") // Перепишем если найдем совпадение и названия и кода
      lRet := .T.
      do while xCode == Upper(Left(tbAnalit:FieldValue("Name"),100)) .and. tbAnalit:FieldValue("DIM_ID") == cDim
        if UPPER(AllTrim(tbAnalit:FieldValue("CODE"),6)) == UPPER(ALLTRIM(cPartnerCode))
          cCode := tbAnalit:FieldValue("Code")
          Exit
        endif
        tbAnalit:Skip(1)
      enddo
    endif
  endif
  Break(.T.)
recover using oErr
  if ValType(tbPartner) == "O"
    tbPartner:Destroy()
    tbPartner := nil
  endif
  if ValType(tbAnalit) == "O"
    tbAnalit:Destroy()
    tbAnalit := nil
  endif
  if valtype(oErr) == "L"
     return oErr
   else
     return .F.
  endif
 end sequence
Return .T.

****************************
* Pg
* Запись из документа в темповую таблицу
******************************
Static Function WriteToTmp(cRecTp)
Memvar aStru,aField,nJrn,cSfId,laIns,aIns,lpStorno
Memvar tbTmp,Obj,lpSf,lpKOPNDS ,aKOPNDS//tbDoc//waSCH_SEG ,waDIM_ANL ,waANALIT_SEG ,waPARTNER,waDoc ,waMOVES
local lWrite := .T.
local cAlias := tbTmp:Alias()

  if lpKOPNDS .And. !(Obj:JRN_ID == "1701")
  // Проверяем на коды
    lWrite := .F.
    if !lpSf .And. Obj:OPER_FACT == cSfId
      //if (Obj:KOP_NDS ==  aKOPNDS[1]) .And. ;
     //    (Obj:KOP_NNDS ==  aKOPNDS[2]) .And. ;
     //    (Obj:KOP_NDS0 ==  aKOPNDS[3]) .And. ;
     //    (Obj:KOP_AG_NDS ==  aKOPNDS[4])
           lWrite := .T.
     // endif
    else
      if ( Empty(Obj:KOP_NDS) .Or. Obj:KOP_NDS ==  aKOPNDS[1]) .And. ;
         ( Empty(Obj:KOP_NNDS) .Or. Obj:KOP_NNDS ==  aKOPNDS[2]) .And. ;
         ( Empty(Obj:KOP_NDS0) .Or. Obj:KOP_NDS0 ==  aKOPNDS[3]) .And. ;
         ( Empty(Obj:KOP_AG_NDS) .Or. Obj:KOP_AG_NDS ==  aKOPNDS[4])
           lWrite := .T.
      endif
    endif
  endif

  if !lWrite
    Return .T.
  endif

  if Empty(cRecTp)
    cRecTp := ""
  endif
  tbTmp:Append()
  (cAlias)->JRN_ID := Obj:JRN_ID
  (cAlias)->SRC_TP := Obj:SRC_TP
  (cAlias)->SRC_ID := Obj:SRC_ID
  (cAlias)->SRC_NUM := Obj:SRC_NUM
  (cAlias)->SRC_DATE := Obj:SRC_DATE
  (cAlias)->SRC_VCODE := Obj:SRC_VCODE
  (cAlias)->SRC_DRate := Obj:SRC_DRate
  if nJrn $ "0101,0201,PM01,PM02" .And. lpStorno
    (cAlias)->SRC_SUM := Obj:SRC_RST
  else
    (cAlias)->SRC_SUM := Obj:SRC_SUMALL
  endif
  (cAlias)->SUM_REG := Obj:SUM_REG
  (cAlias)->SRC_Centr := Obj:SRC_Centr
  (cAlias)->SRC_PartN := Obj:SRC_PartN
  (cAlias)->SRC_PartId := Obj:SRC_PartId
  (cAlias)->KOP_NDS := Obj:KOP_NDS()
  (cAlias)->KOP_NNDS := Obj:KOP_NNDS()
  (cAlias)->KOP_NDS0 := Obj:KOP_NDS0()
  (cAlias)->KOP_AG_NDS := Obj:KOP_AG_NDS()
  (cAlias)->nRec := Obj:RecNo()
  (cAlias)->RecType := cRecTp
  if lpSf
    if laIns
      if ascan(aIns,Obj:RecNo()) > 0
        tbTmp:FieldValue("IsChecked",.T.)
      else
        tbTmp:FieldValue("IsChecked",.F.)
      endif
    endif
  else
    if !(Obj:JRN_ID == "1701") .And. Obj:OPER_FACT == cSfId
      (cAlias)->IsChecked := .T.
    else
      (cAlias)->IsChecked := .F.
    endif
  endif

Return .T.

************************
* PG
* Выбор документов соответствующих условиям отбора
************************
Static Function SelectionDoc()
Memvar aAnalit,cKey,cKey1,cVal,cTagName,aField,aStru,cSfId,nJrn,laIns,aIns
MemVar sDateB,sDateE,lpStorno,lpSf,Obj,cCDocId,cDivAll,lpNoDiv,lpKOPNDS ,aKOPNDS
Local lDocCnt,cRecTp

//!!!!!!!!!!!! Права доступа новые деньги !!!!!!!!!

  if nJrn $ {"0101","0201","0301","0901","0904"/*,"PM01","PM02"*/}
    if !lpNoDiv .And. Empty(cDivAll)
      Return .T.
    endif
  endif
  cKey := Upper(cKey)
  cKey1 := Upper(cKey1)

  Obj:SetOrder(cTagName)
  Obj:Scope(cKey,cKey1,cTagName)
  Obj:GoTop()
  // Все что могли отсечь на постоянных индексах - отсекли
  cKey := ""
  if !Empty(cVal) // если передали валюту - то выбираем по валюте
    if !Empty(cKey)
      cKey += " .And. "
    endif
    cKey += " Upper(" + Obj:FNameVal + ") == '" + Upper(cVal) + "'"
  endif
  lDocCnt := !Empty(cCDocId)
  if  lpStorno
    if nJrn $ {"0101","0201"}
    // Пока это только для возврата денег в книге
      if !Empty(cKey)
        cKey += " .And. "
      endif
      cKey += " TYPE_4 == .T. "
      if !lpSf
      //  cKey += " .And. Empty(SF_ID) "
        cKey += " .And. (Obj:SRC_RST >0 )"
      endif
    elseif nJrn $ {"PM01","PM02"}
      if !Empty(cKey)
        cKey += " .And. "
      endif
      if !lpSf
        if nJrn  == "PM01"
          cKey += " Upper(AllTrim(MV_CODE)) $ {'02','10'} "
        else
          cKey += " Upper(AllTrim(MV_CODE)) $ {'21','27'} "
        endif
      endif
    endif
  else
  // Для платежей возвратов - документ основание не вводим в фильтр
    if nJrn $ {"PM01","PM02"}
      if !Empty(cKey)
        cKey += " .And. "
      endif
      if !lpSf
        if nJrn  == "PM01"
          cKey += " Upper(AllTrim(MV_CODE)) $ {'01','03','09','16'} "
        else
          cKey += " Upper(AllTrim(MV_CODE)) $ {'20','26'} "
        endif
      endif
    endif
    if lDocCnt/*!Empty(cCDocId)*/ .And.  !nJrn $ {"PM01","PM02"}
      if !Empty(cKey)
        cKey += " .And. "
      endif
      cKey +=  Obj:FNameCntDoc + " == '" + cCDocId + "' "
    endif
  endif
  if nJrn $ {"0101","0201","0301","0901","0904"} .And. !lpNoDiv
    if !Empty(cKey)
      cKey += " .And. "
    endif
    cKey +=  'Upper(Obj:SRC_Centr) $ '  +'"' + cDivAll + '"'
  endif


  do while !Obj:Eof()
    if  nJrn $ {"PM01","PM02"}
      // Если передали документ основание - то фильтруем и оп нему
      // для с-ф на предоплату - не возврат и не документы финансирования
      if lpStorno
      // Для документов возврата - пишем документ основания
        if Obj:SRC_STORNO .And. Empty(Obj:OPER_FACT) .And. Obj:SRC_RST > 0
          if (Empty(cKey) .Or. Obj:DS:TbEval(cKey)) .And. !Obj:IsFin
            if lDocCnt
              if Obj:SRC_CNTDOCID == cCDocId
                cRecTp := "0"
              else
                cRecTp := "1"
              endif
            else
              cRecTp := "0"
            endif
            WriteToTmp(cRecTp)
          endif
        endif
      else
        if lDocCnt
          if (Empty(cKey) .Or. Obj:DS:TbEval(cKey)) .And. (Obj:SRC_CNTDOCID == cCDocId ) .And. !Obj:IsFin
            if lpSf
              if !Obj:SRC_STORNO
                WriteToTmp()
              endif
            else
              if Empty(Obj:OPER_FACT) .Or. (Obj:OPER_FACT == cSfId)
                WriteToTmp()
              endif
            endif
          endif
        else
          if (Empty(cKey) .Or. Obj:DS:TbEval(cKey)) .And. !Obj:IsFin
            if lpSf
              if !Obj:SRC_STORNO
                WriteToTmp()
              endif
            else
              if Empty(Obj:OPER_FACT) .Or. (Obj:OPER_FACT == cSfId)
                WriteToTmp()
              endif
            endif
          endif
        endif
      endif
    elseif nJrn == "1701"
    // получим суммы по строкам
      if (Empty(cKey) .Or. Obj:DS:TbEval(cKey))
        if Obj:SRC_RST > 0
          WriteToTmp()
        endif
      endif
    elseif nJrn $ {"0101","0201"}
      if (Empty(cKey) .Or. Obj:DS:TbEval(cKey))
        if lpStorno
          if lDocCnt
            if Obj:SRC_CNTDOCID == cCDocId
              cRecTp := "0"
            else
              cRecTp := "1"
            endif
          else
            cRecTp := "0"
          endif
          WriteToTmp(cRecTp)
        else
          if lpSf
            WriteToTmp()
          else
            if Empty(Obj:OPER_FACT) .Or. (Obj:OPER_FACT == cSfId)
              WriteToTmp()
            endif
          endif
        endif
      endif
    else
      if (Empty(cKey) .Or. Obj:DS:TbEval(cKey))
        if lpSf
          WriteToTmp()
        else
          if Empty(Obj:OPER_FACT) .Or. (Obj:OPER_FACT == cSfId)
            WriteToTmp()
          endif
        endif
      endif
    endif
    Obj:Skip(1)
  enddo

Return .T.

************************
* PG
* Выбор документов соответствующих условиям отбора
* для всех партнеров кроме переданных aPartner
************************
//Static Function CreateSfForAllPay(aPartner,aDoc,aSchAn,dDate)
//Static aPartner := {}
//Local /*lcKey := Upper(cKey),*/tb,cParnter,lRet,cIdPartner,aJrnDoc := {}
//Local /*cNameSys,*/cAnalit,aKey := Array(2),i,n,cTagName := "Tag_BOOK"
//Local aFieldAn := Array(2),aPartPay := {},aJrn := Array(2),cTmpFileName
//Local tbDoc,aDocForSF := {},aStrTp := {},cKey,lReturn
//  if aDoc[1] == 1
//    aJrnDoc[1] := CreateDbRecord(B6_DBF_PATH + "BANK\Doc51")
//    aKey[1] := "0"
//    aFieldAn[1] := "SCR"
//    aJrn[1] := 101
//    aStrTp[1] := "0"
//  endif
//  if aDoc[2] == 1
//    aJrnDoc[2] := CreateDbRecord(B6_DBF_PATH + "CASH\K_ORDER")
//    aKey[2] := "П/О"
//    aFieldAn[2] := "AN_KSCHET"
//    aJrn[2] := 201
//    aStrTp[2] := "1"
//  endif
//  for i := 1 to len(aSchAn)
//    for n := 1 to 2
//      if !ValType(aJrnDoc[n]) == "O"
//        loop
//      endif
//      cKey := Upper(aKey[n] + aSchAn[i][1])
//      tb:SetOrder(cTagName)
//      tb:Scope(cKey,cKey,cTagName)
//      tb:GoTop()
//      cAnalit := ""
//      Do While !tb:Eof()
//        if !(cAnalit == tb:FieldValue(aFieldAn[n]))
//          if !Empty(cAnalit)
//            cParnter := SubStr(cAnalit,aSchAn[i][2],aSchAn[i][3])
//            if !Empty(cParnter)
            // Пробуем получить идентификатор партнера
//              cIdPartner := ""
//              cParnter := Upper(cParnter)
//              if aSchAn[i][5] // аналитика системная
//                if LookUpSeek("Partner","FULLCODE",@lRet,cParnter,"Part_ID",@cIdPartner)
//                  if !lRet
//                    cIdPartner := ""
//                  endif
//                endif
//              else
//                if GetAnalitByPartner(aSchAn[i][5],"",cParnter,@lRet,@cParnter,.F.,@cIdPartner)
//                  if !lRet
//                    cIdPartner := ""
//                  endif
//                endif
//              endif
//            endif
//          endif
//          if !Empty(cIdPartner) .And. aScan(aPartner,cIdPartner) < 1
//            if aScan(aPartPay,cIdPartner) < 1
//            // Заполним аналитиками для партнера
//              if GetAnalitCodeForPartner(aSchAn,cIdPartner)
//                if !FILE( cTmpFileName )
//                  cTmpFileName :=  GetTempFile()
//                  //cTmpFileNameCdx := cTmpFileName + ".Cdx"
//                  cTmpFileName :=  cTmpFileName + ".Dbf"
//                endif
//                lReturn := .F.
//                selectdocforbook( cTmpFileName,.F.,aJrn[i],aSchAn,,;
//                                 ,dDate,"2",,,,,@lReturn)
//                if lReturn
//                  tbDoc := CreateDbRecord( cTmpFileName )
//                  tbDoc:GoTop()
//                  do while !tbDoc:Eof()
//                    AADD(aDocForSF,tbDoc:FieldValue("nRec"))
//                    tbDoc:Skip(1)
//                  enddo
//                  if Len(aDocForSF) > 0
//                    CreateRecAvSF(aStrTp[i],aDocForSF,dDate,cIdPartner)
//                    aDocForSF := {}
//                  endif
//                endif
//              endif
//              AADD(aPartPay,cIdPartner)

//            endif
//          endif
//        endif
//        tb:Skip(1)
//      enddo
//    next
//  next


//Return .T.
// 18.05.2006 pg получение счетов на которых
// есть аналитика по партнеру и праметров сегмента
// по которому идентифицируем партнера в аналитике
// в переданной переменной возвращает массив
// 1 - код счета
// 2 - начало сегмента в аналитике
// 3 - длинна сегмента
Function GetSchetForPartner(aSchAn)
local oErr
Local tbSeg,tbDim,cDimId,a:= {},aSchet := {},i,nPos,nAn
Local cSchet := "",lFirstAnalit,aTmp := {},aAnalit := {}
Local cSysId := "0000000000000000000003"
Static aSchetAnalit := {},lFirst := .T.
 begin sequence
 aSchAn := {}
 if lFirst
   lFirst := .F.
   tbSeg := CreateDbRecord(B6_DBF_PATH + "Sch_Seg.Dbf")
   tbDim := CreateDbRecord(B6_DBF_PATH + "Dim_Anl.Dbf")
   tbSeg:SetOrder("DIM_ID")
   tbDim:SetOrder("SYS_ID")
   tbDim:Scope(cSysId,cSysId,"SYS_ID")
   tbDim:GoTop()
   do while !tbDim:Eof()
     cDimId := tbDim:FieldValue("DIM_ID")
     tbSeg:Scope(cDimId,.T.,"DIM_ID")
     tbSeg:GoTop()
     Do While !tbSeg:Eof()
       if AScan(aSchet,tbSeg:FieldValue("SCHET")) < 1
         aadd(aSchet, UPPER(tbSeg:FieldValue("SCHET")))
       endif
       tbSeg:Skip(1)
     enddo
     tbDim:Skip(1)
   Enddo
   if len(aSchet) < 1
     Break(.T.)
   endif

   for i:=1 to len(aSchet)
     if cSchet == aSchet[i]
        LOOP
     endif
     nPos   := 1
     nAn    := 0
     lFirstAnalit := .T.
     aTmp := {}
     cSchet := aSchet[i]
     tbSeg:Scope(Upper(cSchet),Upper(cSchet),"SCHET")
     tbSeg:GoTop()
     Do While !tbSeg:Eof()
       cDimId := tbSeg:FieldValue("DIM_ID")
       if tbDim:Seek(cDimId,.T.,"ID")
         nAn := tbDim:FieldValue("Len")
         if tbDim:FieldValue("Sys_Id") == cSysId ;
            .And. (tbDim:FieldValue("ISSYSTEM") .or. lFirst)
            if tbDim:FieldValue("ISSYSTEM") // Системный справочник-партнеры
              aTmp := {cSchet, nPos, nAn, "",.T.,cDimId,.T.}
              Exit
            else
              aTmp := {cSchet, nPos, nAn, "",.F.,cDimId,.T.}
            endif
         endif
         nPos = nPos + nAn + 1 // Длина разделителя
       endif
       tbSeg:Skip(1)
     enddo
     if len( aTmp ) > 0
       aadd(aAnalit,aTmp)
     endif
   Next
   aSchetAnalit := aAnalit
 endif
 aSchAn := aSchetAnalit
 recover using oErr
  if ValType(tbSeg) == "O"
    tbSeg:Destroy()
    tbSeg := nil
  endif
  if ValType(tbDim) == "O"
    tbDim:Destroy()
    tbDim := nil
  endif
  if valtype(oErr) == "L"
     if !oErr
       lFirst := .T.
     endif
     return oErr
   else
     return .F.
  endif
 end sequence
Return .T.
// Получение сегментов аналитики для переданного партнера
Function GetAnalitCodeForPartner(aSchet,cIdPartner)
local oErr,i,lFirst := .T.,cSysCode,cSysName,lRet := .F.,n
Local RetValue := {},cName := {"code","shortname"},aDim := {}
Local cDim,cCode
 begin sequence
 if !LookUpSeek("Partner","TAG_ID",@lRet,cIdPartner,cName,@RetValue)
   Break(.F.)
 endif
 if !lRet
   Break(.F.)
 endif
 cSysCode := RetValue[1]
 cSysName := RetValue[2]

 for i := 1 to len(aSchet)
   if aSchet[i][5]
     aSchet[i][4] := cSysCode
   else
     cDim := aSchet[i][6]
     n := AScan(aDim,cDim)
     if n < 1
       // Получаем по системному -аналитическое
       lRet := .F.
       cCode := ""
       if GetAnalitByPartner(cDim,cSysName,cSysCode,@lRet,@cCode,.T.)
         if lRet
           aSchet[i][4] := cCode
         else
           aSchet[i][7] := .F.
         endif
       endif
       AADD(aDim,{cDim,cCode})
     else
       if !Empty(aDim[n][2])
         aSchet[i][4] := aDim[n][2]
       else
         aSchet[i][7] := .F.
       endif
     endif
   endif
 next

 recover using oErr
  if valtype(oErr) == "L"
     return oErr
   else
     return .F.
  endif
 end sequence
Return .T.


// Ф-ция по переносу старых с-ф в новое приложение
Function UpgradeSf()
MemVar caPrm,caSFR,caSFT,caBookR,caBookT,caBookNew
MemVar caSMDOC,caSMDOCM,caZMDOC,caZMDOCM
MemVar caRAct,caRActOp,caTAct,caTActOp
MemVar caSFNEW,caSFSTR,caPartner,caMod,caModStr,caSFDOC
MemVar caTax,caNDS,caSFSUM
local oErr
Local cTbName := "",cMsg := "",lRet := .F.
Local caDocType := ""
Local caUser := ""
Local dTrans,dBeg,dReal,dTovar,dMax
Local cTempIndex,cTagName := "TMP_TAG",bFor,cFor,cMsgT,cMsgR
Local cEtrId := "",cEntAddrId := "",cValId := "",cModDef := ""
Local cDocType2 := "",cDocType1 := "",cKey := "",cDocTypeAv := "", cModDefAv := ""
Local aAlias := {},i,aMod := {},lAv := .F.
Local cDocCode1 := "",cDocCode2 := "", cDocCodeAv := ""
Private caPrm := "", caSFR := "", caSFT := "", caBookR := "", caBookT := "", caBookNew := ""
Private caSMDOC := "", caSMDOCM := "", caZMDOC := "", caZMDOCM := ""
Private caRAct := "", caRActOp := "", caTAct := "", caTActOp := ""
Private caSFNEW := "", caSFSTR := "",caSFDOC := "",caPartner := "",caMod := "",caModStr := ""
Private caTax := "",caNDS := "",caSFSUM := ""
 begin sequence
 cTbName := B6_DBF_PATH + "Tax\TAX_PARINI.DBF"
 if !OpenDbf(  cTbName ; //1 имя таблицv с путем
              , ; //2 TAG которvй установить, по умолчаниі 1й
              , ; //3 вvражение фильтра после открvтия
              , ; //4
              , ; //5
              , ; //6 эксклізивное открvтие , по умолчаниі .F.
              , ;//7 открvтие для чтения , по умолчаниі .T.
              , @caPrm)
   Break(.F.)
 endif
 AADD(aAlias,caPrm)
 if (caPrm)->trans_ok
   messagebox("Переход уже совершен.",,48)
   Break(.F.)
 endif
 dTrans := (caPrm)->trans_date
 if Empty(dTrans)
   messagebox("Не задана дата перехода!",,48)
   Break(.F.)
 endif
 dBeg := (caPrm)->date_beg
 if Empty(dBeg)
   messagebox("Не задана дата начала работы подсистемы книга покупок/продаж!",,48)
   Break(.F.)
 endif

 if !OpenDbf(  B6_DBF_PATH + "Sclad\User.DBF",,,,,.T.,.F., @caUser)
   Break(.F.)
 endif
 AADD(aAlias,caUser)
 (caUser) -> (DbGoTop())
 do while !(caUser)->(Eof())
   if Upper(Alltrim((caUser)->ident)) == "SCL_RBEG"
     dReal := CTOD(Alltrim((caUser)->xval))
     Exit
   endif
   (caUser)->(DbSkip(1))
 enddo
 (caUser) ->(DbCloseArea())
 if Empty(dReal)
   messagebox("Не определена дата начала периода в приложении 'Учет продаж'.",TITLEAPP,48)
   Break(.F.)
 endif

 if !OpenDbf(  B6_DBF_PATH + "Tovar\User.DBF",,,,,.T.,.F., @caUser)
   Break(.F.)
 endif
 (caUser) -> (DbGoTop())
 do while !(caUser)->(Eof())
   if Upper(Alltrim((caUser)->ident)) == "SCL_TBEG"
     dTovar := CTOD(Alltrim((caUser)->xval))
     Exit
   endif
   (caUser)->(DbSkip(1))
 enddo
 (caUser) ->(DbCloseArea())
 if Empty(dTovar)
   messagebox("Не определена дата начала периода в приложении 'Учет закупок'.",TITLEAPP,48)
   Break(.F.)
 endif
 cMsg :=                '       Переход возможен только с ' + CRLF
 if dReal == dTovar
   dMax := dReal
   cMsg += DTOC(dMax) + ' - даты начала периода в приложениях "Учет закупок" и  "Учет продаж" '
 elseif dReal > dTovar
   dMax := dReal
   cMsg += DTOC(dMax) + ' - даты начала периода в приложении "Учет закупок" '
 else
   dMax := dTovar
   cMsg += DTOC(dMax) + ' - даты начала периода в приложении "Учет продаж" '
 endif

 if (dTrans  < dMax)
   messagebox(cMsg,TITLEAPP,48)
   Break(.F.)
 endif


 if (dTrans  > dTovar) .Or.  (dTrans > dReal)
   cMsg := ''
   cMsg += ' Для перехода со старой версии необходимо закрыть период' + CRLF
   cMsg += 'в приложениях "Учет закупок" и  "Учет продаж" на одну дату ' + CRLF
   cMsg += '              - дату перехода ' + DTOC(dTrans) + CRLF
   cMsg += '     Начало периода в "Учет закупок" ' + DTOC(dTovar) + CRLF
   cMsg += '     Начало периода в "Учет продаж"  ' + DTOC(dReal) + CRLF
   messagebox(cMsg,TITLEAPP,48)
   Break(.F.)
 endif

 //
 if !OpenDbf(  B6_DBF_PATH + "Real\sh_fact.DBF","TAG_DATAR",,,;
              ,.T.,, @caSFR)
   Break(.F.)
 endif
 AADD(aAlias,caSFR)
 (caSFR)->(DbGoTop())
 if !OpenDbf(  B6_DBF_PATH + "Real\Book.DBF","TAG_NUMB",,,;
              ,.T.,, @caBookR)
   Break(.F.)
 endif
 AADD(aAlias,caBookR)
 (caBookR)->(DbGoTop())
 if !OpenDbf(  B6_DBF_PATH + "Tovar\sh_fact.DBF",,,,,.T.,, @caSFT)
   Break(.F.)
 endif
 AADD(aAlias,caSFT)
 (caSFT)->(DbGoTop())
 if !OpenDbf(  B6_DBF_PATH + "Tovar\Book.DBF","TAG_NUMB",,,;
              ,.T.,, @caBookT)
   Break(.F.)
 endif
 AADD(aAlias,caBookT)
 (caBookT)->(DbGoTop())
 if ((caSFR)->(Eof()) .Or. (caSFR)->(Bof())) .And.;
    ((caBookR)->(Eof()) .Or. (caBookR)->(Bof())) .And.;
    ((caSFT)->(Eof()) .Or. (caSFT)->(Bof())) .And.;
    ((caBookT)->(Eof()) .Or. (caBookT)->(Bof()))
    // Нет старых с-ф  и записей в книгу
    (caPrm)->trans_ok := .T.
    Break(.T.)
 Endif
 lRet := .F.
 cMsg := ''
 cMsg += 'В приложениях :' + CRLF
 (caBookT)->(OrdScope( 0, DTOS(dTrans) ))
 (caBookT)->(DbGoTop())
 cMsgT := ""
 if !(caBookT)->(Eof())
   cMsgT += ' "Учет закупок"  есть записи в книгу '
   lRet := .T.
 endif

 cTempIndex:= GetTempFile("CDX")
 cFor := " DTOS(tek_data) >= '" + DTOS(dTrans) + "' .And. !Deleted() .And. !Arxiv "
 bFor := "{||" + cFor + " }"
 bFor := &bFor
 (caSFT) -> (OrdCondSet( cFor,bFor,,,,,RECNO(),,.T.,,.T.,,,,,,,) )
 (caSFT) -> (ordCreate((cTempIndex),(cTagName),"tek_data"))
 (caSFT) -> (OrdListAdd( (cTempIndex),(cTagName) ))
 (caSFT) -> (OrdSetFocus(cTagName))
 (caSFT) -> (DbGoTop())
 if !((caSFT) -> (Eof()))
   if Empty(cMsgT)
     cMsgT += ' "Учет закупок"  есть счета-фактуры '
   else
     cMsgT += ' есть счета-фактуры '
   endif
   lRet := .T.
 endif
 (caSFT) -> (OrdListClear())
 if File(cTempIndex)
   FErase(cTempIndex)
 endif

 (caBookR)->(OrdScope( 0, DTOS(dTrans) ))
 (caBookR)->(DbGoTop())
 cMsgR := ""
 if !(caBookR)->(Eof())
   cMsgR += ' "Учет продаж"  есть записи в книгу '
   lRet := .T.
 endif

 cTempIndex:= GetTempFile("CDX")
 (caSFR) -> (OrdCondSet(cFor,bFor,,,,,RECNO(),,.T.,,.T.,,,,,,,))
 (caSFR) -> (ordCreate((cTempIndex),"Tag_Date","tek_data"))
 (caSFR) -> (OrdListAdd( (cTempIndex),"Tag_Date" ))
 (caSFR) -> (OrdSetFocus("Tag_Date"))
 (caSFR) -> (DbGoTop())
 if !((caSFR) -> (Eof()))
   if Empty(cMsgR)
     cMsgR += ' "Учет продаж"  есть счета-фактуры '
   else
     cMsgR += ' есть счета-фактуры '
   endif
   lRet := .T.
 endif
 (caSFR) -> (OrdListClear())
 if File(cTempIndex)
   FErase(cTempIndex)
 endif
 if lRet
    cMsg += cMsgT + CRLF + cMsgR + CRLF
    cMsg += " после даты перехода. Удалите их или измените дату перехода!"
    messagebox(cMsg,TITLEAPP,48)
    Break(.F.)
 endif

 // Проверка заполнения обязательных параметров настройки подсистемы
  cMsg := ""
  cMsg := "В настройке подсистемы Книга Покупок/Продаж " + CRLF
  cMsg := cMsg + " не определено: " + CRLF
  lRet := .F.

  //  Тип документа, ?если есть авансовые с-ф - налоговую модель и тип д-та для аванса

  if !OpenDbf(  B6_DBF_PATH + "doc_type.DBF","TAG_MOVE",,,,,, @caDocType)
    Break(.F.)
  endif
  AADD(aAlias,caDocType)
  (caDocType)->(OrdSetFocus("TAG_MOVE"))
  (caSFR)->(OrdScope())
  (caSFR)->(OrdSetFocus(1))
  (caSFR)->(DbGoTop())
  if !((caSFR)->(Eof()) .Or. (caSFR)->(Bof()))
    cKey := "1601" + "2"
    (caDocType)->(OrdScope(0,cKey))
    (caDocType)->(OrdScope(1,cKey))
    (caDocType)->(dbGoTop())
    Do While !(caDocType)->(Eof())
      if !(caDocType)->isclosed
        cDocType2 := (caDocType)->iddoctype
        cDocCode2 := (caDocType)->codedt
        Exit
      endif
      (caDocType)->(DbSkip(1))
    Enddo
    if Empty(cDocType2)
      cMsg := cMsg + " Тип документа на продажу." + CRLF
      lRet := .T.
    endif
    Do while !(caSFR)->(Eof())
      if (caSFR)->TYPE_ST == "2" .And. (caSFR)->Summa_Fact > (caSFR)->Summa_Stn .And. !(caSFR)->(Deleted()) .And. !(caSFR)->Arxiv
        lAv := .T.
        exit
      endif
    enddo
  endif
  (caSFT)->(OrdScope())
  (caSFT)->(OrdSetFocus(1))
  (caSFT)->(DbGoTop())
  if !((caSFT)->(Eof()) .Or. (caSFT)->(Bof()))
    cKey := "1601" + "1"
    (caDocType)->(OrdScope(0,cKey))
    (caDocType)->(OrdScope(1,cKey))
    (caDocType)->(dbGoTop())
    Do While !(caDocType)->(Eof())
      if !(caDocType)->isclosed
        cDocType1 := (caDocType)->iddoctype
        cDocCode1 := (caDocType)->codedt
        Exit
      endif
      (caDocType)->(DbSkip(1))
    Enddo
    if Empty(cDocType1)
      cMsg := cMsg + " Тип документа на закупку." + CRLF
      lRet := .T.
    endif
  Endif

  // Проверка заполнения обязательных параметров настройки подсистемы

  cEtrId := (caPrm)->ent_id
  if Empty(cEtrId)
    cMsg := cMsg + " Собственное предприятие " + CRLF
    lRet := .T.
  endif
  cEntAddrId := (caPrm)->ent_addrid
  if Empty(cEntAddrId)
    cMsg := cMsg + " Собственное предприятие как грузополучатель " + CRLF
    lRet := .T.
  endif
  cModDef := (caPrm)->mod_def
  if Empty(cModDef)
    cMsg := cMsg + " Налоговая модель " + CRLF
    lRet := .T.
  endif

  if lAv
    cModDefAv := (caPrm)->MOD_DEF_F
    if Empty(cModDefAv)
      cMsg := cMsg + " Налоговая модель для авансового счета-фактуры " + CRLF
      lRet := .T.
    endif
    cDocTypeAv := (caPrm)->DOC_AVTP
    if Empty(cDocTypeAv)
      cMsg := cMsg + " Тип документа для авансового счета-фактуры " + CRLF
      lRet := .T.
    else
      (caDocType)->(OrdSetFocus("TAG_ID"))
      if (caDocType)->(DbSeek(cDocTypeAv,.T.,"TAG_ID"))
        cDocCodeAv := (caDocType)->codedt
      endif
    endif
  endif

  if lRet
    messagebox(cMsg,TITLEAPP,48)
    Break(.F.)
  endif





  if !GetCurrParam(@cValId,,,,.T.)
    messagebox("Ошибка определения основной валюты.",TITLEAPP,48)
    Break(.F.)
  endif

// caSMDOC := "", caSMDOCM := "", caZMDOC := "", caZMDOCM := ""
// caRAct := "", caRActOp := "", caTAct := "", caTActOp := "",
 // Открываем таблицы в которых есть ссылки на счета-фактуры
  if !OpenDbf(  B6_DBF_PATH + "Sclad\Mdoc.DBF","TAG_SF",,,,,, @caSMDOC)
    Break(.F.)
  endif
  AADD(aAlias,caSMDOC)
  if !OpenDbf(  B6_DBF_PATH + "Sclad\MdocM.DBF","TAG_FACT",,,,,, @caSMDOCM)
    Break(.F.)
  endif
  AADD(aAlias,caSMDOCM)
    if !OpenDbf(  B6_DBF_PATH + "ZAPAS\Mdoc.DBF","TAG_SF",,,,,, @caZMDOC)
    Break(.F.)
  endif
  AADD(aAlias,caZMDOC)
  if !OpenDbf(  B6_DBF_PATH + "ZAPAS\MdocM.DBF","TAG_FACT",,,,,, @caZMDOCM)
    Break(.F.)
  endif
  AADD(aAlias,caZMDOCM)
  if !OpenDbf(  B6_DBF_PATH + "Real\Act.DBF","TAG_SF",,,,,, @caRAct)
    Break(.F.)
  endif
  AADD(aAlias,caRAct)
  if !OpenDbf(  B6_DBF_PATH + "Real\Act_Op.DBF","TAG_FACT",,,,,, @caRActOp)
    Break(.F.)
  endif
  AADD(aAlias,caRActOp)
  if !OpenDbf(  B6_DBF_PATH + "Tovar\Act.DBF","TAG_SF",,,,,, @caTAct)
    Break(.F.)
  endif
  AADD(aAlias,caTAct)
  if !OpenDbf(  B6_DBF_PATH + "Tovar\Act_Op.DBF","TAG_FACT",,,,,, @caTActOp)
    Break(.F.)
  endif
  AADD(aAlias,caTActOp)
  if !OpenDbf(  B6_DBF_PATH + "Partner.DBF","FULLCODE",,,,,, @caPartner)
    Break(.F.)
  endif
  AADD(aAlias,caPartner)
  if !OpenDbf(  B6_DBF_PATH + "Tax\tax_mod.DBF","TAG_ID",,,,,, @caMod)
    Break(.F.)
  endif
  AADD(aAlias,caMod)
  if !(caMod)->(DbSeek(cModDef))
    messagebox("В справочнике налоговых моделей не найдена налоговая модель из настройки приложения.",TITLEAPP,48)
    Break(.F.)
  else
    if !OpenDbf(  B6_DBF_PATH + "Tax\mod_str.DBF","TAG_PRIOR",,,,,, @caModStr)
      Break(.F.)
    endif
    AADD(aAlias,caModStr)
    (caModStr)->(OrdScope( 0,(caMod)->mod_id))
    (caModStr)->(OrdScope( 1,(caMod)->mod_id))
    (caModStr)->(DbGoTop())
    if (caModStr)->(eof())
      messagebox("Для налоговой модели не определены строки.",TITLEAPP,48)
      Break(.F.)
    endif
    if !OpenDbf(  B6_DBF_PATH + "Tax\tax_tp.DBF","TAG_ID",,,,,, @caTax)
      Break(.F.)
    endif
    AADD(aAlias,caTax)
    //caTax,caNDS
    do while !(caModStr)->(eof())
      if (caTax)->(DbSeek((caModStr)->tax_id))
        if Alltrim((caTax)->sys_num) $ {"2","1"}
          AADD(aMod,{Alltrim((caTax)->sys_num),(caTax)->tax_id,;
                     (caTax)->tax_code,(caModStr)->mod_id,;
                     (caModStr)->str_id,(caModStr)->calc_rl,;
                     (caModStr)->mod_bs})
        endif
      endif

      (caModStr)->(DbSkip(1))
    enddo
  endif
  if !OpenDbf(  B6_DBF_PATH + "spr_nds.DBF","TAG_OPER",,,,,, @caNDS)
    Break(.F.)
  endif
  AADD(aAlias,caNDS)
  if !OpenDbf(  B6_DBF_PATH + "Tax\tax_inv.DBF",,,,,,, @caSFNEW)
    Break(.F.)
  endif
  AADD(aAlias,caSFNEW)
  if !OpenDbf(  B6_DBF_PATH + "Tax\tax_str.DBF",,,,,,, @caSFSTR)
    Break(.F.)
  endif
  AADD(aAlias,caSFSTR)
  if !OpenDbf(  B6_DBF_PATH + "Tax\tax_sum.DBF",,,,,,, @caSFSUM)
    Break(.F.)
  endif
  AADD(aAlias,caSFSUM)
  if !OpenDbf(  B6_DBF_PATH + "Tax\Book.DBF",,,,,,, @caBookNew)
    Break(.F.)
  endif
  AADD(aAlias,caBookNew)
  if !OpenDbf(  B6_DBF_PATH + "Tax\SFDOC.DBF",,,,,,, @caSFDOC)
    Break(.F.)
  endif
  AADD(aAlias,caSFDOC)


  // Перенос закупок
  (caSFNEW) -> (OrdListClear())
  (caSFSTR) -> (OrdListClear())
  if !UpdateSF(1,cEtrId,/*cEntAddrId,*/cDocType1,cDocCode1,cModDef,cDocTypeAv,cDocCodeAv,cModDefAv,cValId,aMod)
    Break(.F.)
  endif
  if !UpdateSF(2,cEtrId,/*cEntAddrId,*/cDocType2,cDocCode2,cModDef,cDocTypeAv,cDocCodeAv,cModDefAv,cValId,aMod)
    Break(.F.)
  endif
 Break(.T.)
 recover using oErr   //
  for i := 1 to len(aAlias)
    if Select(aAlias[i]) > 0
      (aAlias[i])->(DbCloseArea())
    endif
  next

  if File(cTempIndex)
    FErase(cTempIndex)
  endif
  if valtype(oErr) == "L"
     return oErr
   else
     return .F.
  endif
 end sequence
Return .T.

Function UpdateSF(nVid,cEtrId,/*cEntAddrId,*/cDocType,cDocCode,cModDef,cDocTypeAv,cDocCodeAv,cModDefAv,cValId,aMod)
MemVar caPrm,caSFR,caSFT,caBookR,caBookT,caBookNew
MemVar caSMDOC,caSMDOCM,caZMDOC,caZMDOCM
MemVar caRAct,caRActOp,caTAct,caTActOp
MemVar caSFNEW,caSFSTR,caSFDOC,caPartner
MemVar caTax,caNDS,caSFSUM
local oErr,i,j,cIdSf,cType := "",cTypeNew := "",n := 0,aStrDoc := {}
Local caSKRED :="",caSfOp := "",aAlias := {},aDel := {},aNds := {},aAcz := {}
Local cDocId := "",cStrId := "",cIdRate := "",nRate := 0,lAdd := .F.
Local lAcz := .F.,nSHP := 0,nRecSum := 0, aAczR := {},caStr := "",nR := 0
Local caSF := "",lUpd := .F.,lStr := .F.,cCtg := "", cMove := "",lAv := .F.
Local aSfForDoc := {} , aSfDoc := {}
 begin sequence
 //(caSFT)->(OrdSetFocus("TAG_DATA"))
 if nVid == 1
   caSF := caSFT
   cCtg := "1"
   cMove := "ЗК"
 else
   caSF := caSFR
   cCtg := "2"
   cMove := "ОТ"
 endif
 (caSF)->(OrdListClear())
 (caSF)->(DbGoTo(1))
 if (caSF)->(Eof())
   Break(.T.)
 endif
 if nVid = 1
   if !OpenDbf(  B6_DBF_PATH + "Tovar\s_kredit","TAG_OPER",,,,,, @caSKRED)
      Break(.F.)
   endif
   AADD(aAlias,caSKRED)
   if !OpenDbf(  B6_DBF_PATH + "Tovar\sh_op","TAG_NNOPER",,,,.T.,, @caSfOp)
      Break(.F.)
   endif
   AADD(aAlias,caSfOp)
 else
  if !OpenDbf(  B6_DBF_PATH + "Real\sh_op","TAG_NNOPER",,,,.T.,, @caSfOp)
      Break(.F.)
   endif
   AADD(aAlias,caSfOp)
 endif
 Do While !(caSF)->(Eof())
 //формируем только для разнесенных не на полную сумму
   if nVid == 1
     lAv := .F.
     lUpd := (caSF)->Summa_Fact > (caSF)->Summa_St .And. !(caSF)->(Deleted()) .And. !(caSF)->Arxiv
   else
     if (caSF)->TYPE_ST == "2" // Как определить Авансовые
       lAv := .T.
       cMove := "ПР"
       lUpd := (caSF)->Summa_Fact > (caSF)->Summa_Stn .And. !(caSF)->(Deleted()) .And. !(caSF)->Arxiv
     else
       lAv := .F.
       cMove := "ОТ"
       lUpd := (caSF)->Summa_Fact > (caSF)->Summa_St .And. !(caSF)->(Deleted()) .And. !(caSF)->Arxiv
     endif
   endif
   if lUpd //(caSFT)->Summa_Fact > (caSFT)->Summa_St .And. !(caSFT)->(Deleted()) .And. !(caSFT)->Arxiv
     if nVid = 1
       lStr := (caSKRED)->(DbSeek((caSF)->oper_kred)) .And. (caSfOp)->(DbSeek((caSF)->nnoper))
     else
       lStr := (caSfOp)->(DbSeek((caSF)->nnoper))
     endif
     if lStr //(caSKRED)->(DbSeek((caSFT)->oper_kred)) .And. (caSfOp)->(DbSeek((caSFT)->nnoper))
       cIdSf := (caSF)->nnoper
       aNds := {}
       aAcz := {}
       nSHP := 0
       if if(nVid = 1,(caPartner)->(DbSeek((caSKRED)->ag_code)),(caPartner)->(DbSeek((caSF)->ag_code)))
         (caSFNEW)->(DbAppend())
         cDocId                := XGuid()
         (caSFNEW)->DOC_ID     := cDocId
         (caSFNEW)->TI_CTG     := cCtg  //"1"
         (caSFNEW)->MOVE_TP    := cMove //"ЗК"
         if lAv // Для авансовых ищем сначала в настройке подсистемы
           (caSFNEW)->DOC_TP     := cDocTypeAv
           (caSFNEW)->CODE_TP    := cDocCodeAv
         else
           (caSFNEW)->DOC_TP     := cDocType
           (caSFNEW)->CODE_TP    := cDocCode
         endif
         (caSFNEW)->DOC_NUM    := (caSF)->TEK_NOMER
         (caSFNEW)->DOC_DATE   := (caSF)->TEK_DATA
         (caSFNEW)->REG_DATE   := (caSF)->REG_DATA
         (caSFNEW)->REG_NUM    := (caSF)->REG_NOMER
         (caSFNEW)->ENT_ID     := cEtrId
         (caSFNEW)->PRT_ID     := (caPartner)->PART_ID
         if nVid = 1
           if (caPartner)->(DbSeek((caSF)->otp_code))
             (caSFNEW)->PRT_ADDRID:= (caPartner)->PART_ID
           endif
           if (caPartner)->(DbSeek((caSF)->pol_code))
             (caSFNEW)->ENT_ADDRID := (caPartner)->PART_ID
           endif
           (caSFNEW)->ENT_LOC := (caSF)->IdAdGpol
           (caSFNEW)->PRT_LOC := (caSF)->IdAdGotp
         else
           if (caPartner)->(DbSeek((caSF)->pol_code))
             (caSFNEW)->PRT_ADDRID:= (caPartner)->PART_ID
           endif
           if (caPartner)->(DbSeek((caSF)->otp_code))
             (caSFNEW)->ENT_ADDRID := (caPartner)->PART_ID
           endif
           (caSFNEW)->ENT_LOC := (caSF)->IdAdGotp
           (caSFNEW)->PRT_LOC := (caSF)->IdAdGpol
         endif
         (caSFNEW)->VAL_ID      := cValId
         (caSFNEW)->VAL_RATE    := 1
         (caSFNEW)->SUM_NNDS    := (caSF)->SUMMA
         (caSFNEW)->SUM_NDS     := (caSF)->SUMMA_NDS
         (caSFNEW)->SUM_A       := (caSF)->SUMMA_FACT
         (caSFNEW)->SUM_BOOK    := (caSF)->Summa_St
         if nVid == 1
           (caSFNEW)->SUM_PAY     := (caSF)->Summa_St
           (caSFNEW)->ST_SUM      := 0
           (caSFNEW)->ACNT_ID     := (caSKRED)->Schet
           (caSFNEW)->ANALIT      := (caSKRED)->Code
         else
           (caSFNEW)->ST_SUM      := (caSF)->Summa_Stn
           if lAv // авансовая
             (caSFNEW)->SUM_PAY := (caSF)->Summa_St
             (caSFNEW)->SUM_SHP := 0
           else
           /*
             if (caPrm)->OUT_PL  == "0" // оплата
               (caSFNEW)->SUM_PAY := (caSF)->Summa_St
               (caSFNEW)->SUM_SHP := 0
             else
               (caSFNEW)->SUM_PAY     := 0
               (caSFNEW)->SUM_SHP := (caSF)->Summa_St
             endif
             */
             // сей час учетная политика по отгрузке
             (caSFNEW)->SUM_PAY     := 0
             (caSFNEW)->SUM_SHP := (caSF)->Summa_St
           endif
         endif
         (caSFNEW)->SUM_USE     := 0
         (caSFNEW)->ISTRANS     := .T.

         do while (caSfOp)->nnoper_ == cIdSf
           AADD(aDel,(caSfOp)->(RecNo()) )
           (caSFSTR)->(DbAppend())
           cStrId                := XGuid()
           (caSFSTR)->STR_ID     := cStrId
           (caSFSTR)->DOC_ID     := cDocId
           (caSFSTR)->STR_SRC := .T.
           if lAv
             (caSFSTR)->MOD_ID     := cModDefAv //?авансовый
             (caSFSTR)->STR_TP := (caSF)->Cash
           else
             (caSFSTR)->MOD_ID     := cModDef
             cType :=  (caSfOp)->type
             if cType = "1"
               cTypeNew := "2"
             elseif cType = "2"
               cTypeNew := "3"
             elseif cType = "3"
               cTypeNew := "4"
             elseif cType = "4"
               cTypeNew := "6"
             endif
             (caSFSTR)->STR_TP  := cTypeNew

             (caSFSTR)->GROUP_CODE := (caSfOp)->GRUP
             (caSFSTR)->NNUM       := (caSfOp)->NNUM
             (caSFSTR)->NNAME      := (caSfOp)->NAME
             (caSFSTR)->PRT_CODE   := (caSfOp)->PARTIA
             (caSFSTR)->UNIT       := (caSfOp)->ED
             (caSFSTR)->QNTY       := (caSfOp)->KOL
             ///?(caSFSTR)->R :=
             (caSFSTR)->PRICE      := (caSfOp)->CENA
           endif
           (caSFSTR)->SUM_NNDS   := (caSfOp)->SUMMA
           (caSFSTR)->SUM_NDS    := (caSfOp)->SUMMA_NDS
           (caSFSTR)->SUM_A      := (caSfOp)->SUMMA_FACT
           n := 0
           lAcz := .F.
           for i := 1 to len(aMod)
           // Создаем для каждой строки и в целом для документа
             if aMod[i][1] == "1" .And. (caSfOp)->SUMMA_ACZ <= 0//AK
               // Для Акциза не создаем строки с 0 суммой
               Loop
             endif
             (caSFSUM)->(DbAppend())
             (caSFSUM)->idtaxsum  := XGuid()
             (caSFSUM)->DOC_ID    := cDocId
             (caSFSUM)->STR_ID    := cStrId
             (caSFSUM)->MOD_ID    := aMod[i][4]
             (caSFSUM)->MOD_STRID := aMod[i][5]
             (caSFSUM)->TAX_ID    := aMod[i][2]
             if aMod[i][1] == "2"
               cIdRate := (caSfOp)->Oper_NDS
               if !Empty(cIdRate)
                 if (caNDS)->(DbSeek(cIdRate))
                   (caSFSUM)->TAX_RATE  := (caNDS)->NDS
                 endif
               endif
               (caSFSUM)->TAX_SUM   := (caSfOp)->SUMMA_NDS
               (caSFSUM)->TAX_BASE  := (caSfOp)->SUMMA
                lAdd := .T.
                for j := 1 to len(aNds)
                  if aNds[j][1] == cIdRate
                    lAdd := .F.
                    aNds[j][4] := aNds[j][4] + (caSfOp)->SUMMA_NDS
                    aNds[j][5] := aNds[j][5] + (caSfOp)->SUMMA
                  endif
                next
                if lAdd
                  //          Id ставки  Id налога
                  AADD(aNds,{cIdRate,    aMod[i][2],(caSFSUM)->TAX_RATE,;
                             (caSfOp)->SUMMA_NDS,(caSfOp)->SUMMA})
                endif
             else
               // По
               lAcz := .T.
               nRecSum := (caSFSUM)->(RecNo())
               (caSFSUM)->TAX_SUM   := (caSfOp)->SUMMA_ACZ
               (caSFSUM)->TAX_BASE  := (caSfOp)->SUMMA - (caSfOp)->SUMMA_ACZ
               lAdd := .T.
               if cType == "1"
                 caStr := caSMDOCM
               elseif cType == "2"
                 caStr := caZMDOCM
               endif
               if (caStr)->(DbSeek((caSfOp)->nnoper))
                 for j := 1 to len(aAczR)
                   if (caStr)->PA == aAczR[j][2]
                     nR := j
                     lAdd := .F.
                   endif
                 next
                 if lAdd
                   if !CheckIdRateForRate(,(caStr)->PA,@cIdRate,,"1")
                     Break(.F.)
                   endif
                   if Empty(cIdRate)
                     if !CreateApRate((caStr)->PA,@cIdRate)
                       Break(.F.)
                     endif
                   endif
                   for j := 1 to len(aAczR)
                     if cIdRate == aAczR[j][1]
                       nR := j
                       lAdd := .F.
                     endif
                   next
                   if lAdd
                     AADD(aAczR,{cIdRate,(caStr)->PA})
                     nR := Len(aAczR)
                   endif
                 else
                   for j := 1 to len(aAczR)
                     if Empty(aAczR[j][1])
                       nR := j
                       lAdd := .F.
                     endif
                   next
                   if lAdd
                     AADD(aAczR,{Space(22),0})
                     nR := Len(aAczR)
                   endif
                 endif
               else
                 for j := 1 to len(aAczR)
                   if Empty(aAczR[j][1])
                     nR := j
                     lAdd := .F.
                   endif
                 next
                 if lAdd
                   AADD(aAczR,{Space(22),0})
                   nR := Len(aAczR)
                 endif
               endif
               (caSFSUM)->TAX_IDRT  := aAczR[nR][1]
               (caSFSUM)->TAX_RATE  := aAczR[nR][2]
               lAdd := .T.
               for j := 1 to len(aNds)
                  if aNds[j][1] == aAczR[nR][1]
                    aAcz[j][4] := aAcz[j][4] + (caSfOp)->SUMMA_ACZ
                    aAcz[j][5] := aAcz[j][5] + ((caSfOp)->SUMMA - (caSfOp)->SUMMA_ACZ)
                    lAdd := .F.
                  endif
               next
               if lAdd
                 AADD(aNds,{aAczR[nR][1],aMod[i][2],aAczR[nR][2],;
                            (caSfOp)->SUMMA_NDS,(caSfOp)->SUMMA - (caSfOp)->SUMMA_ACZ})
               endif
             endif

             (caSFSUM)->CALC_RL   := aMod[i][6]
             (caSFSUM)->MOD_BS    := aMod[i][7]
             (caSFSUM)->PRIOR     := n

             n := n + 1
           next
           //Определяем суммы оприходования и меняем отметки в документах
           //на идентификаторы новых строк
           if !lAv // Для авансовых ни чего не надо делать
             aSfForDoc := {cDocId,cStrId,,,} // массив для формирования таблицы SfDoc - связи с-ф с д-тами
             //             1    2     3   4            5           6     7      8      9
             if !UpdateDoc(nVid,cType,.F.,cIdSf,(caSfOp)->nnoper,cDocId,cStrId,@nSHP,@aSfForDoc)
               Break(.F.)
             endif
             if !Empty(aSfForDoc[3])
               AADD(aSfDoc,aSfForDoc)
             endif
           endif
           if lAcz
             (caSFSUM)->(DbGoTo(nRecSum))
             (caSFSUM)->TAX_IDRT  := cIdRate
             (caSFSUM)->TAX_RATE  := nRate
           endif
           (caSfOp)->(dbSkip(1))
         enddo
         if nVid == 1
           (caSFNEW)->SUM_SHP := nSHP
         endif
         aStrDoc := {}
         if Len(aNds) >0
           AADD(aStrDoc,aNds)
         elseif Len(aAcz) > 0
           AADD(aStrDoc,aAcz)
         endif
         for j := 1 to len(aStrDoc)
           for i := 1 to len(aStrDoc[j])
             (caSFSUM)->(DbAppend())
             (caSFSUM)->IDTAXSUM  := XGuid()
             (caSFSUM)->DOC_ID    := cDocId
             (caSFSUM)->STR_ID    := cDocId
             (caSFSUM)->MOD_ID    := Space(22)
             (caSFSUM)->MOD_STRID := Space(22)
             (caSFSUM)->TAX_ID    := aStrDoc[j][i][2]
             (caSFSUM)->TAX_RATE  := aStrDoc[j][i][3]
             (caSFSUM)->CALC_RL   := .F.
             (caSFSUM)->MOD_BS    := .F.
             (caSFSUM)->PRIOR     := 0
             (caSFSUM)->TAX_SUM   := aStrDoc[j][i][4]
             (caSFSUM)->TAX_BASE  := aStrDoc[j][i][5]
           next
         next

         For i := 1 to Len(aDel)
           (caSfOp)->(DbGoTo(aDel[i]))
           (caSfOp)->(DbDelete())
         next
       endif
     endif
   endif
   if !lAv
   //               1   2  3   4    5   6     78    9
     if !UpdateDoc(nVid, ,.T.,cIdSf, ,cDocId, , ,@aSfDoc)
        Break(.F.)
     endif

     for i := 1 to len(aSfDoc)
       (caSFDOC)->(DbAppend())
       (caSFDOC)->sfdoc_id  := XGuid()
       (caSFDOC)->sf_id     := aSfForDoc[i][1]
       (caSFDOC)->sfstr_id  := aSfForDoc[i][2]
       (caSFDOC)->doc_id    := aSfForDoc[i][3]
       (caSFDOC)->docstr_id := aSfForDoc[i][4]
       (caSFDOC)->jrn_id    := aSfForDoc[i][5]
     next
   endif
   (caSF)->(DbDelete())
   (caSF)->(DbSkip(1))
 Enddo

 Break(.T.)
 recover using oErr
  for i := 1 to len(aAlias)
    if Select(aAlias[i]) > 0
      (aAlias[i])->(DbCloseArea())
    endif
  next
  if valtype(oErr) == "L"
     return oErr
   else
     return .F.
  endif
 end sequence
Return .T.
// Определяет сумму оприходования по строкам
// создается запись в книгу
// изменяются ссылки в документах и их строках
// Первый проход делаем по строкам с-ф - изменяем отметки в строках документов
// и создаем массив документов к которым пренадлежат строки с суммами
// При втором проходе - уже после обработки всех строк - lDoc - Т
// уже если есть записи в массиве д-тов - изменяем ссылки в самих документах
Function UpdateDoc(nVid,;     // Вид с-ф(книги) 1 - закупка, 2 - продажа
                   cType,;    // тип строки старой с-ф
                   lDoc,;     // Т - для шапки д-та, иначе для его строк
                   cIdSf,;    // идентификатор старого с-ф
                   cIdSfOp,;  // идентификатор строки старого с-ф
                   cIdSfNew,; // идентификатор нового с-ф
                   cIdSfStr,; // идентификатор строки нового с-ф
                   nSHP,;     // сумма оприходования для нового с-ф
                   aSfForDoc) // масив идентификаторов связи с-ф и д-та для заполнения таблицы SfDoc
MemVar caPrm,caSFR,caSFT,caBookR,caBookT,caBookNew
MemVar caSMDOC,caSMDOCM,caZMDOC,caZMDOCM
MemVar caRAct,caRActOp,caTAct,caTActOp
MemVar caSFNEW,caSFSTR,caPartner
MemVar caTax,caNDS,caSFSUM
Static aSfDoc := {}//,aSfNoDoc := {}
local oErr,caDoc := "",caStr := "",caSf := "",lYesDoc := .F.,cField := ""
Local lAdd := .T., i ,aDataOpr := {}// Массив документов под с-ф
Local nJrn := 0,nSumDoc := 0,aVal := {},cIdCurr := "",nOpr := 0,lOpr := .F.
Local cSrcTp,cSrcNum,cSrcDate,cSrcVal,cSrcRate,cSrcRst,cBookId := ""
Local cIdDoc := ""
//Local cNumOpr, dDateOpr
 begin sequence
   if nVid = 1
     caSf := caSFR
   else
     caSf := caSFR
   endif
   if lDoc
     for i := 1 to len(aSfDoc)
     //Для каждого документа создадим запись в книге на оприходование
       /*
        if nVid == 1
          if !CreateRecInNewBook(nVid,.T.,aSfDoc[i])
            Break(.F.)
          endif
        endif
        */
        (aSfDoc[i][10])->(DbGoTo(aSfDoc[i][11]))
        if (aSfDoc[i][10])->(DbRLock())
          (aSfDoc[i][10])->SUM_REG :=  (aSfDoc[i][10])->SUM_REG + aSfDoc[i][2]
          (aSfDoc[i][10])->Oper_Fact := cIdSfNew
          AADD(aSfForDoc,{cIdSfNew,cIdSfNew,aSfDoc[i][1],aSfDoc[i][1],aSfDoc[i][9]})
        else
          Break(.F.)
        endif
     next
     aSfDoc := {}
     /*
     if nVid == 1
       for i := 1 to Len(aSfNoDoc)
       //создаем одну запись без ссылки на документ
          if !CreateRecInNewBook(nVid,.F.,aSfNoDoc[i])
            Break(.F.)
          endif
       next
     endif

     aSfNoDoc := {}
     */
   else
     lYesDoc := .T.
     if !(cType $ {"1","2","3"}) // мущество без ссылки на документ
       lYesDoc := .F.
     else
       do case
         case  cType == "1"
           caDoc := caSMDOC
           caStr := caSMDOCM
           cField := "SUMOUTR"
           nJrn := "0301"
           cSrcTp := "CODEDOC"
           cSrcNum := "NUMDOC"
           cSrcDate := "DATE"
           cSrcVal := "CODEVAL"
           cSrcRate := "CENAVAL"
           cSrcRst := "(SUMOUT - SUM_REG)"
         case  cType == "2"
           caDoc := caZMDOC
           caStr := caZMDOCM
           cField := "SUMOUTR"
           nJrn := "0901"
           cSrcTp := "CODEDOC"
           cSrcNum := "NUMDOC"
           cSrcDate := "DATE"
           cSrcVal := "CODEVAL"
           cSrcRate := "CENAVAL"
           cSrcRst := "(SUMOUT - SUM_REG)"
         case  cType == "3"
           if nVid == 1
             caDoc := caTAct
             caStr := caTActOp
             cField := "SUMMA"
             nJrn := "0501"
             cSrcTp := "TYPE_P"
             cSrcNum := "TEK_NOMER"
             cSrcDate := "TEK_DATA"
             cSrcVal := "CODEVAL"
             cSrcRate := "CURS"
             cSrcRst := "(SUMMA - SUM_REG)"
           else
             caDoc := caRAct
             caStr := caRActOp
             cField := "SUMMA"
             nJrn := "TV01"//1201
             cSrcTp := "TYPE_P"
             cSrcNum := "TEK_NOMER"
             cSrcDate := "TEK_DATA"
             cSrcVal := "CODEVAL"
             cSrcRate := "CURS"
             cSrcRst := "(SUMMA - SUM_REG)"
           endif
       endcase
       if lYesDoc .And. (caDoc)->(DbSeek(cIdSf)) // Есть отметка в документе для данной с-ф
         cIdDoc := (caDoc)->nnoper
         lYesDoc := .T.
         Do While  (caDoc)->Oper_Fact == cIdSf
           lAdd := .T.
           For i := 1 to Len(aVal)
             if (caDoc)->&cSrcVal == aVal[i][1]
               cIdCurr := aVal[i][2]
               lAdd := .F.
             endif
           next
           if lAdd
             if !GetCurrParam(@cIdCurr,,,(caDoc)->&cSrcVal)
               Break(.F.)
             endif
             AADD(aVal,{(caDoc)->&cSrcVal,cIdCurr})
           endif
           lAdd := .T.
           for i := 1 to len(aSfDoc)
             if aSfDoc[i][1] == (caDoc)->nnoper
               lAdd := .F.
             endif
           next
           if lAdd
             AADD(aSfDoc,{(caDoc)->nnoper,; //1
                           0,;                //2
                          (caDoc)->&cSrcTp,;  //3
                          (caDoc)->&cSrcNum,; //4
                          (caDoc)->&cSrcDate,;//5
                          cIdCurr           ,; //6
                          (caDoc)->&cSrcRate,;//7
                          (caDoc)->&cSrcRst,; //8
                          nJrn             ,; //9
                          caDoc,;             //10
                          (caDoc)->(RecNo()); //11
                                   })
           endif
           (caDoc)->(dbSkip(1))
         Enddo
       else
         lYesDoc := .F.
       endif
     endif

     if lYesDoc
       if !(caStr)->(DbSeek(cIdSfOp))
         Break(.T.)
       endif

       nSumDoc :=  (caStr)->&cField
       if !(caDoc)->L_NDS
         nSumDoc := nSumDoc + (caStr)->SUM_NDS
       endif
       if !(caDoc)->L_ACZ
         nSumDoc := nSumDoc + (caStr)->SUM_ACZ
       endif
       nSHP := nSHP + nSumDoc
       for i := 1 to len(aSfDoc)
         if aSfDoc[i][1] == (caStr)->nnoper_
           aSfDoc[i][2] := aSfDoc[i][2] + nSumDoc
         endif
       next

       if  (caStr)->(dbRlock())
         (caStr)->Oper_Fact := cIdSfStr
         aSfForDoc[3] := cIdDoc
         aSfForDoc[4] := (caStr)->nnoper
         aSfForDoc[5] := nJrn
       else
         Break(.F.)
       endif

     /*  запись в книгу создавать не нужно
     else
       aDataOpr := {}
       nOpr := 0
       lOpr := .F.
       if ValType((caStr)->DATA_OPR) == "A"
         aDataOpr := (caStr)->DATA_OPR
         if Len(aDataOpr) > 0
           if ValType(aDataOpr[1]) == "A"
             if Len(aDataOpr[1]) >= 21
               nOpr := aDataOpr[1][16] - aDataOpr[1][20] - aDataOpr[1][21]
               cNumOpr :=  aDataOpr[1][8]
               dDateOpr := If(ValType(aDataOpr[1][7]) == "D",aDataOpr[1][7],(caSf)->DOC_DATE)
               lOpr := .T.
             endif
           endif
         endif
       endif
       if !lOpr
         nSumDoc :=  (caStr)->&cField
         if !(caDoc)->L_NDS
           nSumDoc := nSumDoc + (caStr)->SUM_NDS
         endif
         if !(caDoc)->L_ACZ
           nSumDoc := nSumDoc + (caStr)->SUM_ACZ
         endif
         nOpr := nSumDoc
         cNumOpr := ""
         dDateOpr :=   (caSf)->DOC_DATE
       endif
       */
       /*
       lAdd := .T.
       for i := 1 to len(aSfNoDoc)
         if aSfNoDoc[i][1] == cNumOpr .And. aSfNoDoc[i][2] == dDateOpr
           aSfNoDoc[i][3] := aSfNoDoc[i][3] + nOpr
           lAdd := .F.
         endif
       next
       if lAdd
         AADD(aSfNoDoc,{cNumOpr,dDateOpr,nOpr,cIdCurr})
       endif
        */
     endif
   endif

 recover using oErr
  if valtype(oErr) == "L"
     return oErr
   else
     return .F.
  endif
 end sequence
Return .T.
// Создание записи в книгу на оприходование
Function CreateRecInNewBook(nVid,lDoc,aDoc)
MemVar caPrm,caSFR,caSFT,caBookR,caBookT,caBookNew
MemVar caSMDOC,caSMDOCM,caZMDOC,caZMDOCM
MemVar caRAct,caRActOp,caTAct,caTActOp
MemVar caSFNEW,caSFSTR,caPartner
MemVar caTax,caNDS,caSFSUM
local oErr,cBookId := "",cCtg := Alltrim(Str(nVid))
 begin sequence
   (caBookNew)->(DbAppend())
   cBookId                 := XGuid()
   (caBookNew)->BOOK_ID     := cBookId
   (caBookNew)->BOOK_CTG   := cCtg
   //?(caBookNew)->NUM()
   (caBookNew)->SF_ID      := (caSFNEW)->DOC_ID
   (caBookNew)->SF_MOVE    := (caSFNEW)->MOVE_TP
   (caBookNew)->SF_TP      := (caSFNEW)->DOC_TP
   (caBookNew)->SF_NUM     := (caSFNEW)->DOC_NUM
   (caBookNew)->SF_DATEREG := (caSFNEW)->REG_DATE
   (caBookNew)->SF_VALID   := (caSFNEW)->VAL_ID
   //(caBookNew)->SF_RST     //:= (caSFT)->
   //(caBookNew)->SF_RSTB()
   (caBookNew)->PRT_ID     := (caSFNEW)->PRT_ID
   //(caBookNew)->GTD()
   //(caBookNew)->COUNTRY()
   (caBookNew)->REC_TP     := "ОП" // "ОТ"

   if lDoc
     (caBookNew)->JRN_ID    := aDoc[9]
     (caBookNew)->SRC_ID    := aDoc[1]
     (caBookNew)->SRC_TP    := aDoc[3]
     (caBookNew)->SRC_NUM   := aDoc[4]
     (caBookNew)->SRC_DATE  := aDoc[5]
     (caBookNew)->SRC_VALID := aDoc[6]
     (caBookNew)->SRC_RST   := aDoc[8]
     (caBookNew)->SRC_RATE  := aDoc[7]
     (caBookNew)->SRC_SUM   := aDoc[2]
     (caBookNew)->SRC_SV    := aDoc[2]
   else
     (caBookNew)->SRC_NUM   := aDoc[1]
     (caBookNew)->SRC_DATE  := aDoc[2]
     (caBookNew)->SRC_VALID := aDoc[4]
     (caBookNew)->SRC_RATE  := 1
     (caBookNew)->SRC_SUM   := aDoc[3]
     (caBookNew)->SRC_SV    := aDoc[3]
   endif
   (caBookNew)->ISTRANS     := .T.
 recover using oErr
  if valtype(oErr) == "L"
     return oErr
   else
     return .F.
  endif
 end sequence
Return .T.

*
* получение выражения периода по дате <dDate> и настройке месяц <per>==0 /квартал <per>==1
* возвращает в форме <YYYYPP> , где PP месяц или квартал
function taxGetPeriod( dDate, per )
  local s
  s := str(year(dDate),4,0)
  if per == 0
    s += str(month(dDate),2,0)
  else
    s += str(quarter(dDate),2,0)
  endif
return s

// Получить адресс партнера
// cPartId - идентификатор партнера
// lPol Т - грузополучатель
Function  GetPartnerAdd(cPartId,lPol)
Local cAl := "",cRet := "",n := -1,i //k,lw  //tb,
Local aType ,cFirst := ""
 begin sequence
 if !_DbAreaOpen(B6_DBF_PATH+"prt_addr.Dbf",@cAl,"TAG_PART")
   Break
 endif
 (cAl)->(OrdScope(0,cPartId))
 (cAl)->(OrdScope(1,cPartId))
 (cAl)->(DbGoTop())
 //Сначала поищем активные грузополуч, грузоотпр
 cFirst := (cAl)->rec_id

 if lPol
   aType := {3,1,2}
 else
   aType := {4,1,2}
 endif
 cRet := ""
 for i :=  1 to len(aType)
   (cAl)->(DbGoTop())
   Do While  !(cAl)->(Eof())
     if (cAl)->ADR_TYPE == aType[i]
       if Empty(cRet)
         cRet := (cAl)->rec_id
       endif
       if (cAl)->IS_ACTIVE
         cRet := (cAl)->rec_id
         Exit
       endif
     endif
     (cAl)->(DbSkip(1))
   enddo
   if !Empty(cRet)
     Exit
   endif
 next

 if Empty(cRet)
   cRet := cFirst
 endif

 /*
 tb := CreateDbRecord(B6_DBF_PATH + "prt_addr.Dbf")
 tb:SetOrder("TAG_PART")
 tb:Scope(cPartId,cPartId,"TAG_PART")
 tb:GoTop()
 if tb:Eof()
   Break
 endif
 cRet := tb:FieldValue("rec_id")
 n := tb:FieldValue("ADR_TYPE")
 if lPol .And. n == 3
   Break
 elseif !lPol .And. n == 4
   Break
 endif
 lw := .F.
 Do While !tb:Eof()
   if  lPol
     k := tb:FieldValue("ADR_TYPE")
     if k == 3
       cRet := tb:FieldValue("rec_id")
       Exit
     endif
   else
     k := tb:FieldValue("ADR_TYPE")
     if k == 4
       cRet := tb:FieldValue("rec_id")
       Exit
     endif
   endif
   if k $ {1,2}
     if k == 1 .And. n != 1
       n := 1
       cRet := tb:FieldValue("rec_id")
     elseif k == 2 .And. !(n $ {1,2})
       n := 2
       cRet := tb:FieldValue("rec_id")
     endif
   endif
   tb:Skip(1)
 enddo
 recover
   cRet := ""
 end sequence
 if ValType(tb) == "O"
   tb:Destroy()
   tb := nil
 endif
 */
  recover
    cRet := ""
  end sequence
  _DbAreaClose(cAl)
Return cRet

/*********************************************************/
//пересчет количества qnty в единице unit в единицу unitnew в запасах
// ищет в таблице mlabel
// Изменено - Всегда работаем от коэффициента в mLabel
function Calc_KolForNewUnit(grup,nnum,qnty,unit,unitnew,cAlias,newR,cJrn,cMDim)
 local nSelectArea:=select(), nKol:=0, bBlock, bBlock1, cAlg:=''
 LOCAL nOrd,cLabelName, lOpen := .F., cR := newR
 Local n,i,cKartName,cAlKart := ""
 Local cRep, cOnRep

 if Empty(cAlias) .And. Empty(cJrn)
   messagebox("Функция Calc_KolForNewUnit - не переданы параметры!")
   Return 0
 endif
 if !(ValType(cMDim) == "C")
   cMDim := ""
 endif
 if Empty(cAlias)
   do case
     case cJrn == "0301"
       cLabelName := "Sclad\MLabel.dbf"
     case cJrn $ "0901,0904"
       cLabelName := "Zapas\MLabel.dbf"
     case cJrn == "0501"
       cLabelName := "TOVAR\MLabel.dbf"
     case cJrn == "TV01"
       cLabelName := "TOVAR\MLabel.dbf"
   endcase
   if ! _DbAreaOpen(B6_DBF_PATH + cLabelName, @cAlias,"MLABEL")
     Return 0
   endif
   lOpen := .T.
 endif

 /*
 if ValType(newR) == "N"
   cR := Alltrim(str(newR))
 elseif ValType(newR) == "C"
   cR := Alltrim(newR)
 endif
 */
 nOrd:=(cAlias)->(ordsetfocus('mlabel'))
 /*
 if ValType(newR) == "N"
   cR := Alltrim(str(newR))
 endif
 */
if (cAlias)->(dbseek(upper(grup+nnum)))
   if unitnew==unit
     nkol:=qnty
   else
     do case
       case unit==(cAlias)->ed
         cAlg:='Q'
       case unit==(cAlias)->ed1 .and. !empty((cAlias)->Algo1)
         cAlg:=strtran((cAlias)->Algo1,'R',cAlias+'->R1')
       case unit==(cAlias)->ed2 .and. !empty((cAlias)->Algo2)
         cAlg:=strtran((cAlias)->Algo2,'R',cAlias+'->R2')
       case unit==(cAlias)->ed3 .and. !empty((cAlias)->Algo3)
         cAlg:=strtran((cAlias)->Algo3,'R',cAlias+'->R3')
       otherwise
         cAlg:='Q'
     endcase
     // Проверим на наличие ф-ции GetVolDim(nSegment)

     n := AT(Upper("GetVolDimCode"),Upper(cAlg))
     if n > 0
       cRep :="GetVolDimCode"
       cOnRep := "GetVolDimCodeGr"
     else
       n := AT(Upper("GetVolDim"),Upper(cAlg))
       cRep :="GetVolDim"
       cOnRep := "GetVolDimGr"
     endif
     if n >0
       //Заменим на ф-цию GetVolDimGr и добавим параметры
       //
       n := n + len(cRep)//len("GetVolDim")
       for i := n to len(cAlg)
         if cAlg[i] = ")"
         // Закрывающая скобка ф-ции
           cAlg := STUFF(cAlg,i,0,",cAlias,cAlKart,cMDim")
           Exit
         endif
       next
       do case
         case cJrn == "0301"
           cKartName := "Sclad\MKart.dbf"
         case cJrn $ "0901,0904"
           cKartName := "Zapas\MKart.dbf"
       endcase
       if ! _DbAreaOpen(B6_DBF_PATH + cKartName, @cAlKart,"MKart")
         Return 0
       endif

       //cAlg := STRTRAN(Upper(cAlg),Upper("GetVolDim"),"GetVolDimGr")
       cAlg := STRTRAN(Upper(cAlg),Upper(cRep),cOnRep)
     endif
     bBlock := &("{|cAlias,cAlKart,cMDim|"+strtran(cAlg,'Q',str(qnty,19,4))+"}")
     do case
       case unitnew==(cAlias)->ed
         cAlg:='Q'
       case unitnew==(cAlias)->ed1 .and. !empty((cAlias)->Algo1)
         cAlg:=strtran((cAlias)->Algo1,'R',cAlias+'->R1'/*cR*/)
       case unitnew==(cAlias)->ed2 .and. !empty((cAlias)->Algo2)
         cAlg:=strtran((cAlias)->Algo2,'R',cAlias+'->R2'/*cR*/)
       case unitnew==(cAlias)->ed3 .and. !empty((cAlias)->Algo3)
         cAlg:=strtran((cAlias)->Algo3,'R',cAlias+'->R3'/*cR*/)
       otherwise

         cAlg := 'Q'
     endcase
     // Проверим на наличие ф-ции GetVolDim(nSegment)
     //n := AT(Upper("GetVolDim"),Upper(cAlg))
     n := AT(Upper("GetVolDimCode"),Upper(cAlg))
     if n > 0
       cRep :="GetVolDimCode"
       cOnRep := "GetVolDimCodeGr"
     else
       n := AT(Upper("GetVolDim"),Upper(cAlg))
       cRep :="GetVolDim"
       cOnRep := "GetVolDimGr"
     endif
     if n >0
       //Заменим на ф-цию GetVolDimGr и добавим параметры
       //
       n := n + len(cRep)//len("GetVolDim")
       for i := n to len(cAlg)
         if cAlg[i] = ")"
         // Закрывающая скобка ф-ции
           cAlg := STUFF(cAlg,i,0,",cAlias,cAlKart,cMDim")
           Exit
         endif
       next
       if Select(cAlKart) <1
         do case
           case cJrn == "0301"
             cKartName := "Sclad\MKart.dbf"
           case cJrn $ "0901,0904"
             cKartName := "Zapas\MKart.dbf"
         endcase
         if ! _DbAreaOpen(B6_DBF_PATH + cKartName, @cAlKart,"MKart")
           Return 0
         endif
       endif
       //cAlg := STRTRAN(Upper(cAlg),Upper("GetVolDim"),"GetVolDimGr")
       cAlg := STRTRAN(Upper(cAlg),Upper(cRep),cOnRep)
     endif
     bBlock1:= &("{|cAlias,cAlKart,cMDim|"+strtran(cAlg,'Q','1')+"}")
     nkol:=iif(eval(bBlock1,cAlias,cAlKart,cMDim)=0,0,eval(bBlock,cAlias,cAlKart,cMDim)/eval(bBlock1,cAlias,cAlKart,cMDim))
   endif
 else
   sayandwait(No_Irina("#89: ")+"Группа "+grup+" ном.№ "+nnum+" не найден!")
 endif
 (cAlias)->(ordsetfocus(nOrd))
 dbselectarea(nSelectArea)

return nkol

/*********************************************************/
//пересчет количества qnty в основной единице в единицу unitnew в запасах
// ищет в таблице mlabel, Коэффициент пересчета передается
function Calc_KolFromEd(grup,nnum,qnty,unitnew,cAlias,newR,cJrn,cMDim)
 local  nKol:=0, bBlock1, cAlg:=''
 LOCAL  nOrd,cR,nK,lOpen := .F.,cLabelName
 Local n,i,cKartName,cAlKart := ""
 Local cRep, cOnRep

 if Empty(cAlias) .And. Empty(cJrn)
   messagebox("Функция Calc_KolFromEd - не переданы параметры!")
   Return 0
 endif

 if !(ValType(cMDim) == "C")
   cMDim := ""
 endif

 if Empty(cAlias)
   do case
     case cJrn == "0301"
       cLabelName := "Sclad\MLabel.dbf"
     case cJrn $ "0901,0904"
       cLabelName := "Zapas\MLabel.dbf"
     case cJrn == "0501"
       cLabelName := "TOVAR\MLabel.dbf"
     case cJrn == "TV01"
       cLabelName := "TOVAR\MLabel.dbf"
   endcase
   if ! _DbAreaOpen(B6_DBF_PATH + cLabelName, @cAlias,"MLABEL")
     Return 0
   endif
   lOpen := .T.
 endif

 nOrd:=(cAlias)->(ordsetfocus('mlabel'))
 if ValType(newR) == "N"
   cR := Alltrim(str(newR))
 elseif ValType(newR) == "C"
   cR := Alltrim(newR)
 endif
 if (cAlias)->(dbseek(upper(grup+nnum)))

     do case
       case unitnew==(cAlias)->ed
         cAlg:='Q'
       case unitnew==(cAlias)->ed1 .and. !empty((cAlias)->Algo1)
         cAlg:=strtran((cAlias)->Algo1,'R',cR)
       case unitnew==(cAlias)->ed2 .and. !empty((cAlias)->Algo2)
         cAlg:=strtran((cAlias)->Algo2,'R',cR)
       case unitnew==(cAlias)->ed3 .and. !empty((cAlias)->Algo3)
         cAlg:=strtran((cAlias)->Algo3,'R',cR)
       otherwise
         messagebox("Группа "+(cAlias)->grup+" ном.№ "+(cAlias)->nnum+"- ЕИ "+unitnew+" не найдена!")
         cAlg:='0'
     endcase
     // Проверим на наличие ф-ции GetVolDim(nSegment)
     //n := AT(Upper("GetVolDim"),Upper(cAlg))
     n := AT(Upper("GetVolDimCode"),Upper(cAlg))
     if n > 0
       cRep :="GetVolDimCode"
       cOnRep := "GetVolDimCodeGr"
     else
       n := AT(Upper("GetVolDim"),Upper(cAlg))
       cRep :="GetVolDim"
       cOnRep := "GetVolDimGr"
     endif
     if n >0
       //Заменим на ф-цию GetVolDimGr и добавим параметры
       //
       n := n + len(cRep)//len("GetVolDim")
       for i := n to len(cAlg)
         if cAlg[i] = ")"
         // Закрывающая скобка ф-ции
           cAlg := STUFF(cAlg,i,0,",cAlias,cAlKart,cMDim")
           Exit
         endif
       next
       do case
         case cJrn == "0301"
           cKartName := "Sclad\MKart.dbf"
         case cJrn $ "0901,0904"
           cKartName := "Zapas\MKart.dbf"
       endcase
       if ! _DbAreaOpen(B6_DBF_PATH + cKartName, @cAlKart,"MKart")
         Return 0
       endif

       //cAlg := STRTRAN(Upper(cAlg),Upper("GetVolDim"),"GetVolDimGr")
       cAlg := STRTRAN(Upper(cAlg),Upper(cRep),cOnRep)
     endif
     bBlock1:= &("{|cAlias,cAlKart,cMDim|"+strtran(cAlg,'Q','1')+"}")
     nK :=  eval(bBlock1,cAlias,cAlKart,cMDim)
     if nK != 0
       nkol := qnty/nK
     endif

 else
   messagebox("Группа "+(cAlias)->grup+" ном.№ "+(cAlias)->nnum+" не найден!")
 endif
 (cAlias)->(ordsetfocus(nOrd))
 if lOpen
   _DbAreaClose(cAlias)
 endif
 _DbAreaClose(cAlKart)
 /* Пока не делаем округление
 IF MGRUP->(dbSeek(UPPER(cGrup)))
    n := MGRUP->KOL_
ELSE
    n := 6
ENDIF
*/
return nkol

//возвращает числовое значение кода сегмента аналитики номенклатуры
FUNCTION GetVolDimCodeGr(nSegment,cAlGr,cAlKart,cMDim)
RETURN GetVolDimGr(nSegment,cAlGr,cAlKart,cMDim,.T.)

///////////////////////
//возвращает числовое значение из наименования или кода сегмента аналитики номенклатуры
FUNCTION GetVolDimGr(nSegment,cAlGr,cAlKart,cMDim,lCode)//возвращает числовое значение сегмента аналитики номенклатуры
//nSegment-номер сегмента (по умолчанию 1)
//lCode - если присутствует - то возвращаем число из кода аналитики,
//иначе из наименования аналитики

LOCAL aMDim,nRet:=1
//LOCAL cMDim //:=IF(TYPE("pMDim")=="C",m->pMDim,IF(!EMPTY(SELECT(cSelKart)).AND.iMKART->(UPPER(GRUP+NNUM))==iMLABEL->(UPPER(GRUP+NNUM)),iMKART->MDIM,""))

//LOCAL nRec,nOrd,nOrd1,nOrd2
Local cAlMDim := "",cAlMDimGr  := "" ,lRet ,bCodeExists
if Empty(cMDIM)
  if (cAlKart)->(DbSeek(Upper((cAlGr)->GRUP,(cAlGr)->NNUM)))
    cMDIM := (cAlKart)->MDIM
  endif
endif

IF !EMPTY(cMDIM)
   IF EMPTY(nSegment)
      nSegment:=1
   ENDIF
   IF "-"$cMDIM
      aMDim:=LineToArray(cMDim,"-")
      IF LEN(aMDIm)>=nSegment
         cMDim:=aMDim[nSegment]
      ENDIF
   ENDIF
   IF !EMPTY(cMDim).AND.!EMPTY(lCode)
      nRet:=VAL(STRTRAN(cMDim,',','.'))
   ELSEIF !EMPTY(cMDim)
   //IF !EMPTY(cMDim)
      if ! _DbAreaOpen(B6_DBF_PATH + "MDIM", @cAlMDim,"Tag_ID")
        Return 1
      endif
      IF FILE('MDimGrup.dbf')
         if ! _DbAreaOpen(B6_DBF_PATH + "MDIMGRUP", @cAlMDimGr,"Grup_ID")
           Return 1
         endif
      ENDIF

      //NAL_Dim_anl

      if (cAlMDim)->(dbSEEK((cAlGr)->MDIM))
        IF (cAlMDim)->FORMAT=="S"
           (cAlMDimGr)->(DBSEEK((cAlMDim)->MDIM_ID+STR(nSegment,2,0)))
           (cAlMDim)->(DBSEEK((cAlMDimGr)->MDIM_ID,,"TAG_ID"))
        ENDIF
        IF NAL_Dim_anl->(DBSEEK((cAlMDim)->MDim_ID))
           //SeekCodeAnalit(MDim->MDim_ID,PADR(cMDIM,MDim->LEN),@cMDim,,.F.)
           lRet := .F.
           if GetAnalitNameByCode((cAlMDim)->MDim_ID,cMDim,@cMDim,@lRet,@bCodeExists,.F.)
             if lRet
               IF VALTYPE(cMDim)!="C"
                 cMDim:=""
               ENDIF
             else
               cMDim:=""
             endif
           else
             cMDim:=""
           endif
        ENDIF
      endif
      _DbAreaClose(cAlMDim)
      _DbAreaClose(cAlMDimGr)
      nRet:=VAL(STRTRAN(cMDim,',','.'))//VAL(cMDim)
   ENDIF
ENDIF
RETURN IF(EMPTY(nRet),1,nRet)

///////////////////////



// Статр формы книги при ошибке сохранения
// при создании из с-ф
Function  StartFrmBook(oObjBook)
local oErr
Local p := array(10)
  begin sequence
  p[1] := 2
  p[2] := oObjBook:BOOK_ID
  p[3] := .F. //стартуем с реестра документов
  p[4] := oObjBook:BOOK_CTG
  p[5] := oObjBook:Rec_Tp
  p[6] := oObjBook:SF_ID
  p[7] := 1
  p[8] := oObjBook
  p[9] := 1 // чтобы отменить циклический ввод
  if p[5] == "СА"
    if (p[4] == "2") .And. (oObjBook:SF:MOVE_TP $ {"ОТ","БП"})
       p[10] := .T.
     endif
  endif
  if RunForm('tax\frmTaxBook',.T.,p, ,.T.) == nil
    Break(.F.)
  endif
  recover using oErr
    if valtype(oErr) == "L"
      return oErr
     else
      return .F.
    endif
 end sequence
Return .T.

Function CreateArModStr(maModStr,cAl,cAlTaxTp,cAlSprNds,cModId, aMsgErr)
local oErr,lOpen := .F.,cTag,cTagSpr,s := "",n := 1,cCode := "",cAlTaxMod := ""
Local cSumUse := "", bMsgErr
 begin sequence
 if ! _DbAreaOpen(B6_DBF_PATH + "Tax\TAX_MOD.dbf", @cAlTaxMod,"TAG_ID")
   Break(.F.)
 endif
 bMsgErr := !( valtype(aMsgErr) == 'A' )
 if !(cAlTaxMod)->(DbSeek(cModId))
   if bMsgErr
     messagebox("Проверьте установленные в настройке приложения Книга покупок/продаж налоговые модели!")
   else
     aadd(aMsgErr, "Проверьте установленные в настройке приложения Книга покупок/продаж налоговые модели!")
   endif
   Break(.F.)
 endif
 maModStr := {}
 cSumUse := (cAlTaxMod)->SUM_USE
 if Empty(cAl)
   lOpen := .T.
   if ! _DbAreaOpen(B6_DBF_PATH + "Tax\TAX_TP.dbf", @cAlTaxTp,"TAG_ID")
      Break(.F.)
    endif
    if ! _DbAreaOpen(B6_DBF_PATH + "Tax\MOD_STR.dbf", @cAl,"TAG_ID")
      Break(.F.)
    endif
    if ! _DbAreaOpen(B6_DBF_PATH + "SPR_NDS.Dbf", @cAlSprNds,"TAG_ID")
      Break(.F.)
    endif
 endif

 cTag := (cAl)->(OrdSetFocus("TAG_PRIOR"))
 cTagSpr := (cAlSprNds)->(OrdSetFocus("TAG_OPER"))
 (cAl)->(OrdScope(0,cModId))
 (cAl)->(OrdScope(1,cModId))
 (cAl)->(DbGoTop())
 if (cAl)->(Eof())
   if bMsgErr
     messagebox("Не определены строки налоговой модели!")
   else
     aadd(aMsgErr, "Не определены строки налоговой модели!" )
   endif
   Break(.F.)
 endif
 do while !(cAl)->(Eof())
   if (cAlTaxTp)->(DbSeek((cAl)->TAX_ID))
     s := (cAlTaxTp)->SYS_NUM
     cCode := (cAlTaxTp)->tax_code
   endif
   if (cAlSprNds)->(DbSeek((cAl)->RT_DEF))
     n := (cAlSprNds)->NDS
   endif
   AADD(maModStr, {(cAl)->TAX_ID,;
                   (cAl)->CALC_RL,;
                   (cAl)->MOD_BS,;
                   (cAl)->STR_ID,;
                   (cAl)->RT_DEF,;
                    n,;
                    s,;
                   (cAl)->PRIOR,;
                   "'" + Alltrim((cAl)->OUT_F) + "'",;
                   "'" + Alltrim((cAl)->IN_F) + "'",;
                   cCode,;
                   (cAl)->PRICE_IN,;
                   cSumUse;
                     })
   (cAl)->(DbSkip(1))
 enddo
 (cAl)->(OrdSetFocus(cTag))
 (cAlSprNds)->(OrdSetFocus(cTagSpr))
 Break(.T.)
 recover using oErr
  _DbAreaClose(cAlTaxMod)
  if lOpen
    _DbAreaClose(cAl)
    _DbAreaClose(cAlTaxTp)
    _DbAreaClose(cAlSprNds)
  endif
  if valtype(oErr) == "L"
     return oErr
   else
     return .F.
  endif
 end sequence
Return .T.

///////////////////////////
//PG
// в переменной  cValue возвращает код или название
// партнера по идентификатору записи в справчнике партнеров
// и типу партнеров
// lCode Т - код иначе название
// lPart Т - только партнеры
// cAliasPeople - рабочая область на справочник сотрудников
//////////////////////
Function GetPartnerCodeName(nIdPartner,lCode,cValue,lPart,cPartTp,cAliasPeople)
local  oErr
 begin sequence
 if cPartTp == "2" .And. !lPart  //::mTbPeople
   if (cAliasPeople)->(DbSeek(nIdPartner,.T.,"TAG_IDP"))
     if lCode
       cValue := (cAliasPeople)->CODE
     else
       cValue := (cAliasPeople)->SHORTNAME
     endif
   else
     Break(.F.)
   endif
 else
   if (DIC_PARTNER)->(DbSeek(nIdPartner,.T.,"TAG_ID"))
     if lCode
       cValue := (DIC_PARTNER)->CODE
     else
       cValue := (DIC_PARTNER)->SHORTNAME
     endif
   else
     Break(.F.)
   endif
 endif
 recover using oErr
   if valtype(oErr) == "L"
     return oErr
   else
     return .F.
  endif
 end sequence
Return .T.

Function GetPartnerFieldValue(nIdPartner,cField,cValue,lPart,cPartTp,cAliasPeople)
local  oErr
 begin sequence
 if cPartTp == "2" .And. !lPart  //::mTbPeople
   if (cAliasPeople)->(DbSeek(nIdPartner,.T.,"TAG_IDP"))
      cValue := (cAliasPeople)->&(cField)
   else
     Break(.F.)
   endif
 else
   if (DIC_PARTNER)->(DbSeek(nIdPartner,.T.,"TAG_ID"))
       cValue := (DIC_PARTNER)->&(cField)
   else
     Break(.F.)
   endif
 endif
 recover using oErr
   if valtype(oErr) == "L"
     return oErr
   else
     return .F.
  endif
 end sequence
Return .T.

Function CheckTaxStorno()
Local aSfOtg := {}
Local aSfAv  := {}
Local i,j,k,m,cKey := "",n
Local nSumSt := 0
Local aSfSum := {}, aBookSum := {} , aBkTax := {}
Local TAX_INV := "", TAX_SUM := "", TAX_BOOK := "", BK_TAX := ""
Local nSumB := 0, nSumSHP := 0, nTp2 := 0, nTp3 := 0, nTp4 := 0, nTp5 := 0
Local SrcSum := 0,RecSum := 0
Local nRate, oBook
Local lRet := .T.

//Local nh, cFile:=DISKNAME()+':'+DIRNAME()  + "\tax.log"

/*  if !File(cFile)

    if (nh :=fcreate(cFile)) < 0
      messageBox( "Cannot create file : " + cFile )
      return .f.
    endif
  else
    nh :=fopen(cFile,1)
  endif
 */
  if ! _DbAreaOpen(B6_DBF_PATH + "TAX\TAX_INV.DBF", @TAX_INV,"TAG_ID")
    RETURN .F.
  endif
  if ! _DbAreaOpen(B6_DBF_PATH + "TAX\TAX_SUM.DBF", @TAX_SUM,"TAG_DOCED")
    RETURN .F.
  endif
  if ! _DbAreaOpen(B6_DBF_PATH + "TAX\BOOK.DBF", @TAX_BOOK,"TAG_RECTP")
    RETURN .F.
  endif
  if ! _DbAreaOpen(B6_DBF_PATH + "TAX\BK_TAX.DBF", @BK_TAX,"TAG_BOOK")
    RETURN .F.
  endif
  if !OpenDictionary()
    RETURN .F.
  endif

  begin sequence
  // проверим суммы регистрации по отгрузочным с-ф
  (TAX_INV)->(OrdSetFocus("TAG_MOVE"))
  (TAX_INV)->(OrdScope(0,"2"))
  (TAX_INV)->(OrdScope(1,"2"))
  (TAX_INV)->(DbGoTop())
  (TAX_BOOK)->(OrdSetFocus("TAG_SFRT"))
  Do While !(TAX_INV)->(Eof())
    if (TAX_INV)->MOVE_TP $ "ОТ,БП"
      cKey := (TAX_INV)->DOC_ID + "ОТ"
      (TAX_BOOK)->(OrdScope(0,cKey))
      (TAX_BOOK)->(OrdScope(1,cKey))
      (TAX_BOOK)->(DbGoTop())
      nSumB := 0
      nSumSHP := 0
      nTp2 := 0
      nTp3 := 0
      nTp4 := 0
      nTp5 := 0

     //FWRITE(nH,"1;" + str((TAX_INV)->Sum_Book)+ ":" + str((TAX_INV)->sum_shp)+ ":"  + str((TAX_INV)->shp_tp2)+ ":" + str((TAX_INV)->shp_tp3)+ ":" + str((TAX_INV)->shp_tp4)+ ":" + str((TAX_INV)->shp_tp5)+ ":"  +  CRLF)
      DO While !(TAX_BOOK)->(EOF())
        nRate := iif(Empty((TAX_BOOK)->SRC_RATE),1,(TAX_BOOK)->SRC_RATE)
        SrcSum := (TAX_BOOK)->SRC_Sum/nRate
        RecSum := (TAX_BOOK)->Rec_Sum/nRate
        nSumB += RecSum
        nSumSHP += SrcSum
        if !Empty((TAX_BOOK)->SRC_ID)
          do case
            case (TAX_BOOK)->JRN_ID == "0301"
              nTp2 += (TAX_BOOK)->SRC_SUM/nRate
            case (TAX_BOOK)->JRN_ID $ "0901,0904"
              nTp3 += (TAX_BOOK)->SRC_SUM/nRate
            case (TAX_BOOK)->JRN_ID == "0501" .Or. (TAX_BOOK)->JRN_ID == "TV01" //1201
              nTp4 += (TAX_BOOK)->SRC_SUM/nRate
            case (TAX_BOOK)->JRN_ID == "1701"
              nTp5 += (TAX_BOOK)->SRC_SUM/nRate
          endcase
        endif
        (TAX_BOOK)->(DbSkip(1))
      EndDo
      if (TAX_INV)->(DbRLock((TAX_INV)->(RecNo())))
        (TAX_INV)->Sum_Book := nSumB
        if (TAX_INV)->Sum_A == nSumB
          (TAX_INV)->Is_Full := .T.
        else
          (TAX_INV)->Is_Full := .F.
        endif
        (TAX_INV)->sum_shp := nSumSHP
        (TAX_INV)->shp_tp2 := nTp2
        (TAX_INV)->shp_tp3 := nTp3
        (TAX_INV)->shp_tp4 := nTp4
        (TAX_INV)->shp_tp5 := nTp5


        (TAX_INV)->(DbRUnLock((TAX_INV)->(RecNo())))
      endif
      //FWRITE(nH,"2;" + str((TAX_INV)->Sum_Book)+ ":" + str((TAX_INV)->sum_shp)+ ":"  + str((TAX_INV)->shp_tp2)+ ":" + str((TAX_INV)->shp_tp3)+ ":" + str((TAX_INV)->shp_tp4)+ ":" + str((TAX_INV)->shp_tp5)+ ":"  +  CRLF)
    endif
    (TAX_INV)->(DbSkip(1))
  enddo

  // Пройдемся по всем сторно записям в книге
  (TAX_BOOK)->(OrdSetFocus("TAG_RECTP"))
  (TAX_BOOK)->(OrdScope(0,"1СА"))
  (TAX_BOOK)->(OrdScope(1,"1СА"))
  (TAX_BOOK)->(DbGoTop())
  DO While !(TAX_BOOK)->(EOF())
    if AScan(aSfOtg,(TAX_BOOK)->SF_ID) = 0
      AADD(aSfOtg,(TAX_BOOK)->SF_ID)
    endif
    if AScan(aSfAv,(TAX_BOOK)->st_sf) = 0
      AADD(aSfAv,(TAX_BOOK)->st_sf)
    endif
    (TAX_BOOK)->(DbSkip(1))
  EndDo

  (TAX_BOOK)->(OrdSetFocus("TAG_SFRT"))
  (TAX_INV)->(OrdSetFocus("TAG_ID"))
  (BK_TAX)->(OrdSetFocus("TAG_BOOK"))
  For i := 1 to Len(aSfOtg)
    cKey := aSfOtg[i]
    if (TAX_INV)->(DbSeek(cKey))
      cKey := cKey + "СА"
      (TAX_BOOK)->(OrdScope(0,cKey))
      (TAX_BOOK)->(OrdScope(1,cKey))
      (TAX_BOOK)->(DbGoTop())
      nSumSt := 0
      DO While !(TAX_BOOK)->(EOF())
        nSumSt += (TAX_BOOK)->rec_sum
        (TAX_BOOK)->(DbSkip(1))
      EndDo
      if !((TAX_INV)->ST_SUM == nSumSt)
      //FWRITE(nH,"3;" + str((TAX_INV)->ST_SUM)  +  CRLF)
        if (TAX_INV)->(DbRLock((TAX_INV)->(RecNo())))
          (TAX_INV)->ST_SUM := nSumSt
          (TAX_INV)->(DbRUnLock((TAX_INV)->(RecNo())))
        endif
      //FWRITE(nH,"4;" + str((TAX_INV)->ST_SUM)  +  CRLF)
      endif
    endif
  next

  (TAX_BOOK)->(OrdSetFocus("TAG_SFST"))
  (TAX_SUM)->(OrdSetFocus("TAG_DOCED"))
  // Если сумма записи в книгу по с-ф рана сумме записи в книгу
  // налоги
  For i := 1 to Len(aSfAv)
    cKey := aSfAv[i]
    if (TAX_INV)->(DbSeek(cKey))
      (TAX_SUM)->(OrdScope(0,cKey))
      (TAX_SUM)->(OrdScope(1,cKey))
      (TAX_SUM)->(DbGoTop())
      aSfSum := {}
      DO While !(TAX_SUM)->(EOF())
        AADD(aSfSum,{(TAX_SUM)->tax_id,;
                     (TAX_SUM)->tax_rate,;
                     (TAX_SUM)->tax_base,;
                     (TAX_SUM)->tax_sum})
        (TAX_SUM)->(DbSkip(1))
      EndDo

      (TAX_BOOK)->(OrdScope(0,cKey))
      (TAX_BOOK)->(OrdScope(1,cKey))
      (TAX_BOOK)->(DbGoTop())
      nSumSt := 0
      n := 0
      aBookSum := {}
      DO While !(TAX_BOOK)->(EOF())
        nSumSt += (TAX_BOOK)->rec_sum
        n += 1
        (BK_TAX)->(OrdScope(0,(TAX_BOOK)->BOOK_ID))
        (BK_TAX)->(OrdScope(1,(TAX_BOOK)->BOOK_ID))
        (BK_TAX)->(DbGoTop())
        do while !(BK_TAX)->(Eof())
          AADD(aBookSum,{(BK_TAX)->tax_id,;
                         (BK_TAX)->tax_rate,;
                         (BK_TAX)->tax_base,;
                         (BK_TAX)->tax_sum ,;
                         (TAX_BOOK)->(RecNo())})
          (BK_TAX)->(DbSkip(1))
        enddo

        (TAX_BOOK)->(DbSkip(1))
      EndDo

      if n > 1
        j := 0
      //Пороверим если записей в книгу ольше чем 1
      // и в какойто строке сумма равна сумме по с-ф
      // в этой строке откорректируем налоги

        aBkTax := {}
        for k := 1 to len(aBookSum)
          if aSfSum[1][1] = aBookSum[k][1] .And. aSfSum[1][2] = aBookSum[k][2]
            if aSfSum[1][3] = aBookSum[k][3] .And. aSfSum[1][4] = aBookSum[k][4]
              j := aBookSum[k][5] // строка для которой перенеслись все налоги
            endif
          endif
        next
        if j > 0
          // Откорректируем записи налогов
          if !(ValType(oBook) == "O")
            oBook := clsTax_Book():New()
            oBook:Open()
          endif
          for m := 1 to len(aBookSum)
            if !(aBookSum[m][5] == j)
              for k := 1 to len(aSfSum)
                if aSfSum[k][1] = aBookSum[m][1] .And. aSfSum[k][2] = aBookSum[m][2]
                  aSfSum[k][3] -= aBookSum[m][3]
                  aSfSum[k][4] -= aBookSum[m][4]
                endif
              next
            endif
          next
          oBook:DS:GoTo(j)

          if oBook:Edit()
            oBook:BKTAX:GoTop()
            do while !oBook:BKTAX:Eof()
              for k := 1 to len(aSfSum)
                if aSfSum[k][1] = oBook:BKTAX:TAX_ID .And. aSfSum[k][2] = oBook:BKTAX:tax_rate
                  //FWRITE(nH,"7;" + str(oBook:BKTAX:DS:FieldValue("TAX_BASE")) + ";" + str(oBook:BKTAX:DS:FieldValue("TAX_SUM")) +  CRLF)
                  oBook:BKTAX:DS:FieldValue("TAX_BASE",if(aSfSum[k][3]<0,0,aSfSum[k][3]))
                  oBook:BKTAX:DS:FieldValue("TAX_SUM", if(aSfSum[k][4]<0,0,aSfSum[k][4]))
                  //FWRITE(nH,"8;" + str(oBook:BKTAX:DS:FieldValue("TAX_BASE")) + ";" + str(oBook:BKTAX:DS:FieldValue("TAX_SUM")) +  CRLF)
                endif
              next
              oBook:BKTAX:Skip(1)
            enddo
            if !Empty(oBook:TENTRY_ID) .And. !oBook:main:Eof()
              if Create_TProvodka(oBook:TENTRY_ID, oBook, oBook:BKTAX, oBook:main, oBook:OPERT, 2, @oBook:aMainParamDocForProv)  == 2
                if !oBook:Save()
                  oBook:Cancel()
                endif
              else
                oBook:Cancel()
              endif
            else
              if !oBook:Save()
                  oBook:Cancel()
              endif
            endif
          endif

        endif
      endif


      //for j := 1 to len(aBookSum)
      //next
      // могло быть отсторнировано больше чем  записано в книгу при регистрации авансового с-ф
      //if (TAX_INV)->SUM_BOOK < nSumSt

      //endif
      // Если сумма отсторнированных записей не равна ST_SUM
      // перепишем ST_SUM
      if !((TAX_INV)->ST_SUM == nSumSt)
        //FWRITE(nH,"5;" + str((TAX_INV)->ST_SUM)  +  CRLF)
        if (TAX_INV)->(DbRLock((TAX_INV)->(RecNo())))
          (TAX_INV)->ST_SUM := nSumSt
          (TAX_INV)->(DbRUnLock((TAX_INV)->(RecNo())))
        endif
        //FWRITE(nH,"6;" + str((TAX_INV)->ST_SUM)  +  CRLF)
      endif
    endif
  next
  recover
    lRet := .F.
  end sequence

  if ValType(oBook) == "O"
    oBook:Destroy()
    oBook := nil
  endif
  CloseDictionary()
  _DbAreaCloseA({TAX_INV,;
                 TAX_SUM,;
                 TAX_BOOK,;
                 BK_TAX})

Return lRet

// Удаляем строки и налоги у которых нет шапок
// Если рабочие области не переданы - открываем
Function CheckStrSumForSF(Tax_Inv,Tax_Str,Tax_Sum)
Local lRet := .T.
Local lOpen := .F.
 begin sequence
   if !(ValType(Tax_Inv) == "C" .And. Select(Tax_Inv) > 0)
     Tax_Inv := ""
     Tax_Str := ""
     Tax_Sum := ""
     lOpen := .T.
     if ! _DbAreaOpen(B6_DBF_PATH + "TAX\TAX_INV.DBF", @Tax_Inv,"TAG_ID")
       Break(.F.)
     endif
    if ! _DbAreaOpen(B6_DBF_PATH + "TAX\TAX_STR.DBF", @Tax_Str,"TAG_DOC_ID")
      Break(.F.)
    endif
    if ! _DbAreaOpen(B6_DBF_PATH + "TAX\TAX_SUM.DBF", @Tax_Sum,"TAG_DOCED")
      Break(.F.)
    endif
   endif
   // Проверяем наличие лишних строк - без связи со с-ф
  // и лишних записей с суммах под с-ф
    (Tax_Str)->(OrdSetFocus(0))
    (Tax_Str)->(DbGoTop())
    (Tax_Inv)->(OrdSetFocus("TAG_ID"))
    (Tax_Inv)->(OrdScope(0,nil))
    (Tax_Inv)->(OrdScope(1,nil))
    (Tax_Sum)->(OrdSetFocus("TAG_STR"))
    (Tax_Sum)->(OrdScope(0,nil))
    (Tax_Sum)->(OrdScope(1,nil))
    Do While !(Tax_Str)->(Eof())
      if !(Tax_Inv)->(DbSeek((Tax_Str)->doc_id))
        if (Tax_Sum)->(DbSeek((Tax_Str)->str_id))
          do while (Tax_Sum)->str_id == (Tax_Str)->str_id
            if (Tax_Sum)->(DbRLock((Tax_Sum)->(RecNo())))
              (Tax_Sum)->(DbDelete())
            endif
            (Tax_Sum)->(DbSkip(1))
          enddo
        endif
        if (Tax_Str)->(DbRLock((Tax_Str)->(RecNo())))
           (Tax_Str)->(DbDelete())
        endif
      endif
      (Tax_Str)->(dbSkip())
    enddo
    // Удалим зависшие строки сумм налогов
    (Tax_Str)->(OrdSetFocus("TAG_ID"))
    (Tax_Str)->(OrdScope(0,nil))
    (Tax_Str)->(OrdScope(1,nil))
    (Tax_Sum)->(OrdSetFocus(0))
    (Tax_Sum)->(DbGoTop())
    do while !(Tax_Sum)->(Eof())
      if !(Tax_Inv)->(DbSeek((Tax_Sum)->doc_id))
        if (Tax_Sum)->(DbRLock((Tax_Sum)->(RecNo())))
           (Tax_Sum)->(DbDelete())
        endif
      endif
      if !((Tax_Sum)->str_id == (Tax_Sum)->Doc_id)
        if !(Tax_Str)->(DbSeek((Tax_Sum)->str_id))
          if (Tax_Sum)->(DbRLock((Tax_Sum)->(RecNo())))
             (Tax_Sum)->(DbDelete())
          endif
        endif
      endif
      (Tax_Sum)->(DbSkip(1))
   enddo

 recover
   lRet := .F.
 end sequence
 if lOpen
  _DbAreaCloseA({Tax_Inv,;
                 Tax_Str,;
                 Tax_Sum })
 endif
Return lRet
// Найдем с-ф без строк
Function CheckSFWithSt(Tax_Inv,Tax_Str,Tax_Sum,DOC_TYPE,aNoStr,aNoSum)
Local lRet := .T. , Tax_InvMDID := ""
Local lOpen := .F.,cDocType := ""
 begin sequence
   if !(ValType(Tax_Inv) == "C" .And. Select(Tax_Inv) > 0)
     Tax_Inv := ""
     Tax_Str := ""
     lOpen := .T.
     if ! _DbAreaOpen(B6_DBF_PATH + "TAX\TAX_INV.DBF", @Tax_Inv,"TAG_ID")
       Break(.F.)
     endif
    if ! _DbAreaOpen(B6_DBF_PATH + "TAX\TAX_STR.DBF", @Tax_Str,"TAG_DOC_ID")
      Break(.F.)
    endif
    if ! _DbAreaOpen(B6_DBF_PATH + "TAX\TAX_SUM.DBF", @Tax_Sum,"TAG_DOCED")
      Break(.F.)
    endif
    if ! _DbAreaOpen(B6_DBF_PATH + "Doc_Type.dbf", @DOC_TYPE,"TAG_ID")
      Break(.F.)
    endif

   endif
   if ! _DbAreaOpen(B6_DBF_PATH + "TAX\TAX_INV.DBF", @Tax_InvMDID,"TAG_ID")
     Break(.F.)
   endif
   // Проверяем наличие с-ф без строк
   (Tax_Inv)->(OrdSetFocus(""))
   (Tax_Inv)->(DbGoTop())
   (Tax_Str)->(OrdSetFocus("TAG_STRTP"))
   (Tax_Str)->(OrdScope(0,nil))
   (Tax_Str)->(OrdScope(1,nil))
   (Tax_Sum)->(OrdSetFocus("TAG_DOC"))
   Do While !(Tax_Inv)->(Eof())
     if !Empty((Tax_Inv)->SFMD_ID)
       if (Tax_InvMDID)->(DbSeek((Tax_Inv)->SFMD_ID))
         if (Tax_InvMDID)->(DbRLock((Tax_InvMDID)->(RecNo())))
           (Tax_InvMDID)->SFD_ID := (Tax_Inv)->SFD_ID
           (Tax_InvMDID)->(DbRUnLock((Tax_InvMDID)->(RecNo())))
         endif
       endif
     endif
     if !(Tax_Str)->(DbSeek((Tax_Inv)->Doc_Id))
     // под с-ф нет строк  DOC_TP
       if (DOC_TYPE)->(DbSeek((Tax_Inv)->DOC_TP))
         cDocType := (DOC_TYPE)->CODEDT
       else
         cDocType := Space(3)
       endif
       AADD(aNoStr,{"Вид " + (Tax_Inv)->MOVE_TP + " с-ф вид " + cDocType + " №" + (Tax_Inv)->REG_NUM + " от "  + DTOC((Tax_Inv)->REG_DATE),(Tax_Inv)->DOC_ID })
       // удалим если есть налоги под с-ф
       (Tax_Sum)->(OrdScope(0,(Tax_Inv)->DOC_ID))
       (Tax_Sum)->(OrdScope(1,(Tax_Inv)->DOC_ID))
       (Tax_Sum)->(DbGoTop())
       do while !(Tax_Sum)->(Eof())
         if (Tax_Sum)->(DbRlock((Tax_Sum)->(RecNo())))
           (Tax_Sum)->(DbDelete())
         endif
         (Tax_Sum)->(DbSkip(1))
       enddo
     else
       (Tax_Sum)->(OrdScope(0,nil))
       (Tax_Sum)->(OrdScope(1,nil))
       (Tax_Sum)->(OrdSetFocus("TAG_DOC"))
       if !(Tax_Sum)->(DbSeek((Tax_Inv)->Doc_Id))
     // под с-ф нет строк  DOC_TP
         if (DOC_TYPE)->(DbSeek((Tax_Inv)->DOC_TP))
           cDocType := (DOC_TYPE)->CODEDT
         else
           cDocType := Space(3)
         endif
         AADD(aNoSum,{"Вид " + (Tax_Inv)->MOVE_TP + " с-ф вид " + cDocType + " №" + (Tax_Inv)->REG_NUM + " от "  + DTOC((Tax_Inv)->REG_DATE),(Tax_Inv)->DOC_ID })
       endif
     endif
     (Tax_Inv)->(DbSkip(1))
   enddo

 recover
   lRet := .F.
 end sequence
 if lOpen
  _DbAreaCloseA({Tax_Inv,;
                 Tax_Str,;
                 Tax_Sum,;
                 DOC_TYPE })
 endif
 _DbAreaClose(Tax_InvMDID)
Return lRet

Function ReMakeTaxMod()
Local lRet := .T.
Local TAX_INV := "", TAX_TP := "",TAX_MOD := "",MOD_STR := "",TAX_STR := "",TAX_SUM := ""
Local cIdNDS := " "
Local aTaxMod := {},lMod := .F., aSf := {}
Local i,lNo0 := .F.,cIdA := " ",nSum := 0
 begin sequence
 if ! _DbAreaOpen(B6_DBF_PATH + "TAX\TAX_INV.DBF", @TAX_INV,"TAG_ID")
   Break(nil)
 endif
 if ! _DbAreaOpen(B6_DBF_PATH + "TAX\TAX_STR.DBF", @TAX_STR,"TAG_STRTP")
   Break(nil)
 endif
 if ! _DbAreaOpen(B6_DBF_PATH + "TAX\TAX_SUM.DBF", @Tax_Sum,"TAG_DOCED")
      Break(nil)
    endif
 if ! _DbAreaOpen(B6_DBF_PATH + "TAX\TAX_TP.DBF", @TAX_TP,"tag_code")
   Break(nil)
 endif
 if ! _DbAreaOpen(B6_DBF_PATH + "TAX\TAX_MOD.DBF", @TAX_MOD,"TAG_ID")
   Break(nil)
 endif
 if ! _DbAreaOpen(B6_DBF_PATH + "TAX\MOD_STR.DBF", @MOD_STR,"TAG_TAX")
   Break(nil)
 endif

 (TAX_TP)->(DbGoTop())
 Do While !(TAX_TP)->(Eof())
   if Upper(Alltrim((TAX_TP)->sys_num)) == "2" //НДС
     cIdNDS := (TAX_TP)->tax_id
   endif
   if Upper(Alltrim((TAX_TP)->sys_num)) == "1" //НДС
     cIdA := (TAX_TP)->tax_id
   endif
   (TAX_TP)->(DbSkip(1))
 Enddo

 (MOD_STR)->(OrdScope(0,cIdNDS))
 (MOD_STR)->(OrdScope(1,cIdNDS))
 (MOD_STR)->(DbGoTop())
 Do While !(MOD_STR)->(Eof())
   // Извлекать
   if (MOD_STR)->CALC_RL
     if (TAX_MOD)->(DbSeek((MOD_STR)->mod_id))
       if !((TAX_MOD)->sum_use == "2")
         if (TAX_MOD)->(DbRLock((TAX_MOD)->(RecNo())))
           AADD(aTaxMod,(MOD_STR)->mod_id)
           (TAX_MOD)->sum_use := "2"
           (TAX_MOD)->(DbRUnLock((TAX_MOD)->(RecNo())))
         endif
       endif
     endif
   endif
   (MOD_STR)->(DbSkip(1))
 Enddo

 if !len(aTaxMod) > 0
   Break(nil)
 endif

 // если в налоговой модели есть акциз - проверим вхождение в цену
 (MOD_STR)->(OrdSetFocus("TAG_MOD"))
 for i = 1 to len(aTaxMod)
   (MOD_STR)->(OrdScope(0,aTaxMod[i]))
   (MOD_STR)->(OrdScope(1,aTaxMod[i]))
   (MOD_STR)->(DbGoTop())
   Do while !(MOD_STR)->(Eof())
     if (MOD_STR)->tax_id == cIdA
       if (MOD_STR)->CALC_RL
         if (MOD_STR)->(DbRLock((MOD_STR)->(RecNo())))
           (MOD_STR)->price_in := .T.
           (MOD_STR)->(DbRUnLock((MOD_STR)->(RecNo())))
         endif
       endif
     endif
     (MOD_STR)->(DbSkip(1))
   enddo
 next

 (Tax_Inv)->(OrdSetFocus(""))
 (Tax_Inv)->(DbGoTop())
 (Tax_Str)->(OrdSetFocus("TAG_STRTP"))
 (Tax_Sum)->(OrdSetFocus("TAG_STR"))
 Do While !(Tax_Inv)->(Eof())
   lMod := .F.
   for i := 1 to len(aTaxMod)
     if aTaxMod[i] == (Tax_Inv)->mod_id
       lMod := .T.
       exit
     endif
   next
   if lMod
     (Tax_Str)->(OrdScope(0,(Tax_Inv)->Doc_Id))
     (Tax_Str)->(OrdScope(1,(Tax_Inv)->Doc_Id))
     (Tax_Str)->(DbGoTop())
     Do while !(Tax_Str)->(Eof())
       (Tax_Sum)->(OrdScope(0,(Tax_Inv)->DOC_ID))
       (Tax_Sum)->(OrdScope(1,(Tax_Inv)->DOC_ID))
       (Tax_Sum)->(DbGoTop())
       lNo0 := .F.
       do while !(Tax_Sum)->(Eof())
         if (Tax_Sum)->tax_id == cIdNDS
           if (Tax_Sum)->tax_rate > 0
             lNo0 := .T.
             nSum := (Tax_Sum)->tax_sum
             exit
           endif
         endif
         (Tax_Sum)->(DbSkip(1))
       enddo
       if lNo0
         if (Tax_Str)->sum_nnds == (Tax_Str)->sum_a
           if (Tax_Str)->(DbRLock((Tax_Str)->(RecNo())))
             (Tax_Str)->sum_nnds := (Tax_Str)->sum_a - nSum
             (Tax_Str)->(DbRUnLock((Tax_Str)->(RecNo())))
           endif
           if (Tax_Inv)->(DbRLock((Tax_Inv)->(RecNo())))
             (Tax_Inv)->sum_nnds := (Tax_Inv)->sum_nnds - nSum
             (Tax_Inv)->(DbRUnLock((Tax_Inv)->(RecNo())))
           endif
         endif
       endif
       (Tax_Str)->(DbSkip(1))
     enddo
   endif
   (Tax_Inv)->(DbSkip(1))
 enddo

 recover
   lRet := .F.
 end sequence

  _DbAreaCloseA({TAX_INV,;
                 TAX_STR,;
                 TAX_SUM,;
                 TAX_TP,;
                 TAX_MOD,;
                 MOD_STR })
Return lRet
// Удаляем ссылки на документ из кгиги
Function ClearDocInBook(TAX_BOOK)
local oErr
 begin sequence
 if (TAX_BOOK)->(DbRLock((TAX_BOOK)->(RecNo())))

    (TAX_BOOK)->JRN_ID   := ""
    (TAX_BOOK)->SRC_ID   := ""
    (TAX_BOOK)->SRC_TP   := ""
    (TAX_BOOK)->SRC_NUM  := ""
    (TAX_BOOK)->SRC_VALID:= ""
    (TAX_BOOK)->SRC_RST  := 0
    (TAX_BOOK)->SRC_RATE := 1

   (TAX_BOOK)->(DbRUnLock((TAX_BOOK)->(RecNo())))
 endif

 recover using oErr
  if valtype(oErr) == "L"
     return oErr
   else
     return .F.
  endif
 end sequence
Return .T.

// Получает
// Идентификатор партнера
// тип партнера 1 - поставщик 2 - покупатель
// Сумму - считаем что это всегда сумма от которой расчитывается налоговая модель
//       для
//       Модель  применяется к полю стоимость  - это количество * цена
//       модель   применяется к полю сумма с налогами - это сумма с НДС
// дату - чтобы при отсутствии ставки в налоговой модели можно было найти действующую ставку налого
//        в истории
// группу -   по группе если нет ставки в налоговой модели
//   пробуем получить ставку по группе
// Если передали налоговую модель - не ищем по партнеру
// Возвращаем в переданной переменной массив - по к-ву налогов
// элемент массива - есть или нет ставки для налога Т -  есть, иначе
//                   ни чего не расчитывали - заполнили суммы 0
//                   код налога,
//                   идентификатор,
//                   сумма,
//                   входит или нет в цену,
//                   идентификатор ставкиб
//                   ставка
//                   Т извлекается или начисляется
//                   Т модифицирует базовую сумму
//                   "1" от стоимости "2"  от суммы с НДС - это относится к налоговой модели
// cArm - арм- для того чтобы искать по группе если нет ставки в налоговой модели
// Код возврата -  Т - ф-ция стпешно отработала иначе - была ошибка

Function GetTaxSumForMod(IdPartner,nType, nSum, dDate, cGroup, aTax, cArm, cModId, aMsgErr)
local oErr
Local cNameTag := "",RetValue := "",i,lAdd,cAlPartener2 := ""
Local aArrMod := {}, cType , nTaxBase := 0,nTaxRate := 1,nTax := 0,cIdTaxRate := ""
Local nRound := 2, bMsgErr

Static aMod := {},s , lYesTax := .F.
 aTax := {}
 begin sequence
 //
 bMsgErr := !( valtype(aMsgErr) == 'A' )
 if Empty(cModId)
   if nType = 1
     cNameTag := "TAG_PV"
     cType := " поставщик."
   else
     cNameTag := "TAG_PC"
     cType := " покупатель."
   endif
   if ! _DbAreaOpen(B6_DBF_PATH + "PARTNER2.dbf", @cAlPartener2,cNameTag)
     Break(.F.)
   endif
   // Получим налоговую модель
   if  !(cAlPartener2)->(DbSeek(IdPartner))
     if bMsgErr
       messagebox("Расчет налоговой модели. Партнер не определен как" + cType,TITLEAPP,48)
     else
       aadd(aMsgErr, "Расчет налоговой модели. Партнер не определен как" + cType)
     endif
     Break(.F.)
   endif
   RetValue := (cAlPartener2)->TAXMODEL
 else
   RetValue := cModId
 endif

 // налоговая модель не определена
 if Empty(RetValue)
   Break(.T.)
 endif

 // Получим массив параметров налоговой модели
 lAdd := .T.
 GetCurrParam(, , @nRound, , .T.)
 if len(aMod) < 1
   if !CreateArModStr(@aArrMod,,,,RetValue, @aMsgErr)
     Break(.F.)
   endif
   AADD(aMod,{RetValue,aArrMod})
 else
   for i :=1 to len(aMod)
     if aMod[i][1] == RetValue
       aArrMod := aMod[i][2]
       lAdd := .F.
       exit
     endif
   next
   if lAdd
     if !CreateArModStr(@aArrMod,,,,RetValue, @aMsgErr)
       Break(.F.)
     endif
     AADD(aMod,{RetValue,aArrMod})
   endif
 endif


 nTaxBase := nSum

 For i := 1 to len(aArrMod)
   if aArrMod[i][_CALCRL]
     s := aArrMod[i][_OUTF]
     if s == "''"
       if bMsgErr
         messagebox("Нет правил расчета сумм в налоговой модели!",TITLEAPP,48)
       else
         aadd(aMsgErr, "Нет правил расчета сумм в налоговой модели!" )
       endif
       Break(.F.)
     endif
   else //налог сверху
     s := aArrMod[i][_INF]
     if s == "''"
       if bMsgErr
         messagebox("Нет правил расчета сумм в налоговой модели!",TITLEAPP,48)
       else
         aadd(aMsgErr, "Нет правил расчета сумм в налоговой модели!" )
       endif
       Break(.F.)
     endif
   endif
   lYesTax := .T.
   if Empty(aArrMod[i][_RTDEF])
   // В налоговой модели нет ставки
     // Попробуем получить по группе
     if cArm $ "03,09,05,TV"
       if !GetRateFromArm(cGroup,aArrMod[i][_TAXID],dDate,@nTaxRate,@cIdTaxRate,cArm,aArrMod[i][_SYSNUM], @aMsgErr)
          Break(.F.)
       endif
     else
       lYesTax := .F.
       cIdTaxRate := ""
       nTaxRate :=  0 //aArrMod[i][_RTRATE]
     endif
   else
     nTaxRate :=  aArrMod[i][_RTRATE]
     cIdTaxRate := aArrMod[i][_RTDEF]
   endif

   if lYesTax
     s := "{|TAX_BASE,TAX_RATE|" + &s + "}"
     s := &s
     nTax := Eval(s,nTaxBase,nTaxRate)
     nTax := BS_ROUND(nTax,nRound)
     if aArrMod[i][_MODBS]
       if aArrMod[i][_CALCRL]
         nTaxBase := nTaxBase - nTax
       else
         nTaxBase := nTaxBase + nTax
       endif
     else
       nTaxBase := nTaxBase
     endif
   else
     nTax := 0
   endif
   //есть или нет под налог ставка Т - есть,код налога, идентификатор, сумма, входит или нет в цену, идентификатор ставки,ставка
   AADD(aTax,{lYesTax,;
              aArrMod[i][_TAXCODE_],;
              aArrMod[i][_TAXID],;
              nTax,;
              aArrMod[i][_PRICEIN],;
              cIdTaxRate,;
              nTaxRate,;
              aArrMod[i][_CALCRL],;
              aArrMod[i][_MODBS],;
              aArrMod[i][_SUMUSE];
              })
 next

 /*
 #define _TAXID     1
#define _CALCRL    2
#define _MODBS     3
#define _STRID     4
#define _RTDEF     5
#define _RTRATE    6
#define _SYSNUM    7
#define _PRIOR_    8
#define _OUTF      9
#define _INF       10
#define _TAXCODE_  11
#define _PRICEIN   12
#define _SUMUSE    13*/

 Break(.T.)
 recover using oErr
  _DbAreaClose(cAlPartener2)
  if valtype(oErr) == "L"
     return oErr
   else
     return .F.
  endif
 end sequence
Return .T.

/////////////////////////////////
// PG
// Получение актуальной на дату ставки и идентификатора ставки
// Получаем cGrup - группу товаров(запасов, услуг(
//          TaxId - идентификатор налога
//          dDate - дату на которую ищем
// Возвращаем TaxRate ставку и TaxIdRate идентификатор ставки
// В случае успешного выполнения возвращаем Т
////////////////////////////////
Function GetRateFromArm(cGrup,TaxId,dDate,TaxRate,TaxIdRate,cArm,cSysNum, aMsgErr)
local  oErr
local cTbName,cTbNameHistory,Key
local   lSprNds := .F.
local lRet := .F.,RetValue := "",cName := "", s := ""
local tbGrup,tbTaxGrup,bMsgErr
 TaxRate := 0
 TaxIdRate := Space(22)
 bMsgErr := !( valtype(aMsgErr) == 'A' )
 begin sequence

 do case
   case cArm == "03"
     cTbName := "SCLAD\MGRUP.DBF"
     cTbNameHistory := "SCLAD\MTAXGRP.DBF"
   case cArm $ "09,AU"
     cTbName := "ZAPAS\MGRUP.DBF"
     cTbNameHistory := "ZAPAS\MTAXGRP.DBF"
   case  cArm $ "05,TV"
     cTbName := "TOVAR\MGRUP.DBF"
     cTbNameHistory := "TOVAR\MTAXGRP.DBF"
   otherwise
     lSprNds := .T.
 endcase

 if lSprNds // Для  такого сочитания нет ставок кроме справочника SPR_NDS
   if bMsgErr
     Messagebox("Для такого сочетания нет ставок, кроме справочника SPR_NDS")
   else
     aadd(aMsgErr, "Для такого сочетания нет ставок, кроме справочника SPR_NDS")
   endif
   Break(.F.)
 endif
 if !lSprNds .And. Empty(cGrup)
   if bMsgErr
     messagebox("Строка налогов. Не передано название группы ")
   else
     aadd(aMsgErr, "Строка налогов. Не передано название группы ")
   endif
   Break(.F.)
 endif
 tbGrup := CreateDbRecord(PublicVars():LoadPath() + cTbName,"MGRUP")
 if !tbGrup:Seek(Upper(cGrup),.T.,"MGRUP")
   if bMsgErr
     Messagebox("Группа " + cGrup + " не найдена в справочнике!")
   else
     aadd(aMsgErr, "Группа " + cGrup + " не найдена в справочнике!")
   endif
   Break(.F.)
 endif
 if Empty(TaxId)
   if bMsgErr
     Messagebox("Ф-ция GetRateFromArm. Не передан идентификатор налога!")
   else
     aadd(aMsgErr, "Ф-ция GetRateFromArm. Не передан идентификатор налога!")
   endif
   Break(.F.)
 endif
 /*
 if !(::mTAX_TP)->(DbSeek(TaxId))
   Break(.F.)
 endif
 RetValue := (::mTAX_TP)->SYS_NUM
 */
 do case
   case alltrim(cSysNum) == "1" .And. !(cArm $ "05,TV")// акциз
     cName := "NNOPER"
     lRet := .F.
     RetValue := ""
     if Empty(tbGrup:PA) // в группе не орпеделен
     //акциз - получаем из SPR_NDS первый по дате
      // ??? Если ставка уже какая нибудь есть - может оставить ее??
      // 27544 - ставки нет не ставим
      // ::GetRT(dDate,TaxId,cGrup,@TaxRate,@TaxIdRate,.F.,.T.)
     else
       Key := TaxId + str(tbGrup:PA,19,5)
       if !LookUpSeek("SPR_NDS","TAG_IDNDS",@lRet,Key,cName,@RetValue)
         Break(.F.)
       endif
       if lRet
         TaxRate := tbGrup:PA
         TaxIdRate := RetValue
       else
         RetValue := ""
         if !CreateApRate(tbGrup:PA, @RetValue, @aMsgErr)
           Break(.F.)
         endif
         TaxRate := tbGrup:PA
         TaxIdRate := RetValue
       endif
     endif
   case alltrim(cSysNum) == "2" // НДС
     if tbGrup:is_history
       tbTaxGrup := CreateDbRecord(PublicVars():LoadPath() + cTbNameHistory)
       s := ""
       s := " ( date_beg <= CTOD('" + DTOC(dDate) + "')"
       s := s + " .And. ( date_end >= CTOD('" + DTOC(dDate) + "') .Or. Empty(date_end)))"
       tbTaxGrup:Filter(s)
       tbTaxGrup:MoveFirst()
       If tbTaxGrup:Eof()
       //48794
       // в таблице MTAXGRP записей по данной ставке НЕТ. В этом случае ставку надо брать так, как будть истории нет -т.н. из поля OPER_NDS
         TaxRate := tbGrup:NDS
         TaxIdRate := tbGrup:oper_nds
       else
         TaxRate := tbTaxGrup:Tax
         TaxIdRate := tbTaxGrup:Tax_Id
       endif
     else
       TaxRate := tbGrup:NDS
       TaxIdRate := tbGrup:oper_nds
     endif
   otherwise
     Break(.F.)
 endcase

 if valType(tbGrup) == "O"
   tbGrup:Destroy()
 endif
 tbGrup := nil
 if valType(tbTaxGrup) == "O"
   tbTaxGrup:Destroy()
 endif
 tbTaxGrup := nil
 recover using oErr
  if valType(tbGrup) == "O"
    tbGrup:Destroy()
  endif
  tbGrup := nil
  if valType(tbTaxGrup) == "O"
    tbTaxGrup:Destroy()
  endif
  tbTaxGrup := nil
  if valtype(oErr) == "L"
     return oErr
   else
     return .F.
  endif
 end sequence
Return .T.

Function  CreateDocForSf(cJrn,obj,cTagName)
local oErr
 begin sequence
 do case
   case cJrn = "0101"
     obj := clsTaxForDoc51():New()
     cTagName := "TAG_OPER"
   case cJrn = "0201"
     obj := clsTaxForK_ORDER():New()
     cTagName := "TAG_OPER"
   case cJrn = "0301"
     obj := clsTaxForMDoc():New()
     cTagName := "TAG_OPER"
   case cJrn = "0501"
     obj := clsTaxForRealAct():New()
     cTagName := "TAG_OPER"
   case cJrn $ "0901,0904"
     obj := clsTaxForZapasMDoc():New()
     cTagName := "TAG_OPER"
   case cJrn = "TV01"
     obj := clsTaxForTovarAct():New()
     cTagName := "TAG_OPER"
   case cJrn = "1701"
     obj := clsTaxForAssets():New()
     cTagName := "TAG_ID"
   case cJrn = "PM01"
     obj := clsTaxForFinDoc():New()
     cTagName := "TAG_ID"
   case cJrn = "PM02"
     obj := clsTaxForFinDoc():New()
     cTagName := "TAG_ID"
   otherwise
     messagebox("Не верно передан журнал документа для создания счет-фактуры!",TITLEAPP,48)
     break(.F.)
 endcase
   obj:Open()

 recover using oErr
  obj := nil
  if valtype(oErr) == "L"
     return oErr
   else
     return .F.
  endif
 end sequence
Return .T.

Function ReplaceLenDocNum()
Local Tax_MemDat := "",cKey := "SFDOC"
  if ! _DbAreaOpen(B6_DBF_PATH + "TAX\MEMDAT.DBF", @Tax_MemDat,"TAG_IDENT")
    Break(.F.)
  endif
  (Tax_MemDat)->(OrdScope(0,cKey))
  (Tax_MemDat)->(OrdScope(1,cKey))
  (Tax_MemDat)->(DbGoTop())
  Do While !(Tax_MemDat)->(Eof())
    if (Tax_MemDat)->(DbRLock((Tax_MemDat)->(RecNo())))
      (Tax_MemDat)->Len := 24
      (Tax_MemDat)->(DbRUnLock((Tax_MemDat)->(RecNo())))
    endif
    (Tax_MemDat)->(DbSkip(1))
  Enddo
  _DbAreaClose(Tax_MemDat)
Return .T.

Function GetNumObl(cIdObl)
Local s := ""
Local lRet := .F. ,RetValue
  if LookUpSeek("CNTR\Obligate","TAG_OPER", @lRet, cIdObl, "lNum", @RetValue)
    if lRet
      s := str(RetValue,6,0)
    endif
  endif
Return s


Function ReplaceDocSFInBook()
Local cKey
Local TAX_INV := "", BOOK := ""
  if ! _DbAreaOpen(B6_DBF_PATH + "TAX\TAX_INV.DBF", @TAX_INV,"TAG_ID")
    Break(.F.)
  endif
  if ! _DbAreaOpen(B6_DBF_PATH + "TAX\BOOK.DBF", @BOOK,"TAG_SF")
    Break(.F.)
  endif
  (TAX_INV)->(DbGoTop())
  Do While !(TAX_INV)->(Eof())
    cKey := (TAX_INV)->DOC_ID
    (BOOK)->(OrdSetFocus("TAG_SF"))
    (BOOK)->(OrdScope(0,cKey))
    (BOOK)->(OrdScope(1,cKey))
    (BOOK)->(DbGoTop())

    Do While !(BOOK)->(Eof())
      if !((BOOK)->SF_NUM ==  (TAX_INV)->DOC_NUM)
        if (BOOK)->(DbRLock((BOOK)->(RecNo())))
          (BOOK)->SF_NUM :=  (TAX_INV)->DOC_NUM
          (BOOK)->(DbRUnLock((BOOK)->(RecNo())))
        endif
      endif
      (BOOK)->(DbSkip(1))
    Enddo
    (BOOK)->(OrdSetFocus("TAG_SFST"))
    (BOOK)->(OrdScope(0,cKey))
    (BOOK)->(OrdScope(1,cKey))
    (BOOK)->(DbGoTop())
    Do While !(BOOK)->(Eof())
      if !((BOOK)->ST_NUM ==  (TAX_INV)->DOC_NUM)
        if (BOOK)->(DbRLock((BOOK)->(RecNo())))
          (BOOK)->ST_NUM :=  (TAX_INV)->DOC_NUM
          (BOOK)->(DbRUnLock((BOOK)->(RecNo())))
        endif
      endif
      (BOOK)->(DbSkip(1))
    Enddo

    (TAX_INV)->(DbSkip(1))
  Enddo
  _DbAreaClose(TAX_INV)
  _DbAreaClose(BOOK)
Return .T.

// При создании, изменении, удалении д-тов
// проверяем их связь со строками с-ф и устанавливаем
// нужное значение STR_SRC
// Если передали документ - это пересоздаем для него - его строки могут быть
// уже удалены - с них не нужно снимать отметку создания
Function CheckedTaxStrForDoc(cSfId,cArm)
Local cTbName := "" ,cTagName := ""
LOCAL nKol , nType//, nKolFree := 0
Local TAX_INV := "", TAX_STR := "",CAlias := "" //,CAliasCom := ""
Local lRet := .T. //, TAX_COM := ""
  if !CheckSubSystem("16") .Or. Empty(cSfId)
    Return .T.
  endif
  begin sequence
    if !cArm $ {"03","09","AU","05","TV","17"}
      Break (.T.)
    endif
    if ! _DbAreaOpen(B6_DBF_PATH + "TAX\TAX_INV.DBF", @TAX_INV,"TAG_ID")
      Break(.F.)
    endif
    if ! _DbAreaOpen(B6_DBF_PATH + "TAX\TAX_STR.DBF", @TAX_STR,"TAG_DOC_ID")
      Break(.F.)
    endif
    //if ! _DbAreaOpen(B6_DBF_PATH + "TAX\COMMENTM.DBF", @TAX_COM,"TAG_OPER")
    //  Break(.F.)
    //endif
    if (TAX_INV)->(DbSeek(cSfId))
      do case
        case cArm == "03"
          cTbName := "Sclad\Mdocm.Dbf"
          cTagName :=  "TAG_FACT"
          nType := "2"
          //if ! _DbAreaOpen(B6_DBF_PATH + "Sclad\CommentM", @CAliasCom,"TAG_OPER")
          //  Break(.F.)
          //endif
        case cArm $ "09,AU"
          cTbName := "Zapas\Mdocm.Dbf"
          cTagName :=  "TAG_FACT"
          nType := "3"
          //if ! _DbAreaOpen(B6_DBF_PATH + "Zapas\CommentM", @CAliasCom,"TAG_OPER")
          //  Break(.F.)
          //endif
        case cArm == "05"
          cTbName := "Real\Act_Op.Dbf"
          cTagName :=  "TAG_FACT"
          nType := "4"
        case cArm == "TV"
          cTbName := "Tovar\Act_Op.Dbf"
          cTagName :=  "TAG_FACT"
          nType := "4"
        case cArm == "17"
          cTbName := "Assets\Res_Docs.Dbf"
          nType := "5"
          cTagName :=  "TSSRC_ID"
      endcase
      if ! _DbAreaOpen(B6_DBF_PATH + cTbName, @CAlias,cTagName)
        Break(.F.)
      endif

       if (TAX_STR)->(DbSeek(cSfId))
         do while (TAX_STR)->DOC_ID == cSfId
           (CAlias)->(OrdScope(0,(TAX_STR)->STR_ID))
           (CAlias)->(OrdScope(1,(TAX_STR)->STR_ID))
           (CAlias)->(DbGoTop())
           if (CAlias)->(Eof())
             if (TAX_STR)->STR_TP == nType
               if (TAX_STR)->(DbRLock((TAX_STR)->(RecNo())))
                 (TAX_STR)->Qnty_Shp := 0
                 (TAX_STR)->STR_SRC := .F.
                 (TAX_STR)->(DbRUnLock((TAX_STR)->(RecNo())))
               endif
             endif
           else
             nKol := 0
             //nKolFree := 0
             DO WHILE  !(CAlias)->(Eof())
                do case
                  case nType $ "2,3"
                    nKol += (cAlias)->Kol+(cAlias)->KolNed+(cAlias)->KolBr
                    //if (CAliasCom)->(DbSeek((cAlias)->NNOPERM))
                    //  nKolFree += (CAliasCom)->KOLFREE
                    //endif
                  case nType == "4"
                    nKol += (cAlias)->Kol
                  case nType == "5"
                    nKol += (cAlias)->QNTY
                endcase

               (CAlias)->(dbSKIP())
             ENDDO

             if (TAX_STR)->(DbRLock((TAX_STR)->(RecNo())))
                 (TAX_STR)->STR_TP := nType
                 if (TAX_STR)->QNTY_BAS < nKol
                   (TAX_STR)->Qnty_Shp := (TAX_STR)->QNTY_BAS
                 else
                   (TAX_STR)->Qnty_Shp := nKol
                 endif
                 /*
                 if (TAX_COM)->(DbSeek((TAX_STR)->STR_ID))
                   if nKolFree != (TAX_COM)->KOLFREE
                     if (TAX_COM)->(DbRLock((TAX_COM)->(RecNo())))
                       (TAX_COM)->KOLFREE := nKolFree
                       (TAX_COM)->(DbRUnLock((TAX_COM)->(RecNo())))
                     endif
                   endif
                 elseif nKolFree > 0
                   if !(TAX_COM)->(DbSeek((TAX_STR)->STR_ID))
                     (TAX_COM)->(DbAppend())
                     (TAX_COM)->NNOPERM := (TAX_STR)->STR_ID
                   endif
                   (TAX_COM)->KOLFREE := nKolFree
                 endif
                 */
                 (TAX_STR)->STR_SRC := .T.
                 (TAX_STR)->(DbRUnLock((TAX_STR)->(RecNo())))
             endif
           endif
           (TAX_STR)->(DbSkip(1))
         enddo
       endif
    endif
  recover
    lRet := .F.
  end sequence
  _DbAreaCloseA({CAlias, TAX_INV, TAX_STR})
Return lRet

Function  CheckNoAnulRec(oBo,oBoSt)
local lRet := .F. ,nRec := 0,cAlias := ""

 begin sequence
    nRec := oBo:RecNo()
    cAlias := oBo:cWa
    (cAlias)->(DbGoTop())
    lRet := .F.
    Do While !(cAlias)->(Eof())
      if !((cAlias)->CMP_TP $ "1,3")
        // Запись не анулирована
        lRet := .T.
        exit
      endif
      (cAlias)->(DbSkip(1))
    enddo
    (cAlias)->(DbGoTo(nRec))
    if !lRet
      nRec := oBoSt:RecNo()
      cAlias := oBoSt:cWa
      (cAlias)->(DbGoTop())
      lRet := .F.
      Do While !(cAlias)->(Eof())
        if !((cAlias)->CMP_TP $ "1,3")
          // Запись не анулирована
          lRet := .T.
          exit
        endif
        (cAlias)->(DbSkip(1))
      enddo
      (cAlias)->(DbGoTo(nRec))
    endif
    (cAlias)->(DbGoTo(nRec))

 recover
   lRet := .T.
   oBo:GoTop()
   oBoSt:GoTop()
 end sequence
Return lRet


// При пересоздании д-та - проверяем нет ли у него удаленных строк
// созданных по с-ф
Function CheckedTaxStrForDelDocStr(cSfId,cArm,cKey,cDocId, aDel)
Local cTbName := "" ,cTagName := ""
LOCAL nKol , nType
Local TAX_INV := "", TAX_STR := "",CAlias := ""
Local lRet := .T.
local SetDel:=Set(_SET_DELETED)
  aDel := {}
  begin sequence
    if !CheckSubSystem("16")
      Break (.T.)
    endif
    if !cArm $ {"03","09","AU","05","TV"}
      Break (.T.)
    endif
    if ! _DbAreaOpen(B6_DBF_PATH + "TAX\TAX_INV.DBF", @TAX_INV,"TAG_ID")
      Break(.F.)
    endif
    if ! _DbAreaOpen(B6_DBF_PATH + "TAX\TAX_STR.DBF", @TAX_STR,"TAG_DOC_ID")
      Break(.F.)
    endif
    if (TAX_INV)->(DbSeek(cSfId))
      do case
        case cArm == "03"
          cTbName := "Sclad\Mdocm.Dbf"
          cTagName :=  "TAG_DELETE"
          nType := "2"
        case cArm $ "09,AU"
          cTbName := "Zapas\Mdocm.Dbf"
          cTagName :=  "TAG_DELETE"
          nType := "3"
        case cArm == "05"
          cTbName := "Real\Act_Op.Dbf"
          cTagName :=  "TAG_DELETE"
          nType := "4"
        case cArm == "TV"
          cTbName := "Tovar\Act_Op.Dbf"
          cTagName :=  "TAG_DELETE"
          nType := "4"
      endcase
      if ! _DbAreaOpen(B6_DBF_PATH + cTbName, @CAlias,cTagName)
        Break(.F.)
      endif
      if cArm $ {"05","TV"}
        Set(_SET_DELETED,.F.)
      endif
       if (TAX_STR)->(DbSeek(cSfId))
         do while (TAX_STR)->DOC_ID == cSfId
           if  !(TAX_STR)->STR_SRC
             (CAlias)->(OrdScope(0,cKey))
             (CAlias)->(OrdScope(1,cKey))
             (CAlias)->(DbGoTop())
             nKol := 0
             DO WHILE  !(CAlias)->(Eof())
               if  ((CAlias)->NNOPER_ == cDocId) .And. ((CAlias)->OPER_FACT == (TAX_STR)->STR_ID)
                 do case
                    case nType $ "2,3"
                      nKol += (cAlias)->Kol+(cAlias)->KolNed+(cAlias)->KolBr
                    case nType == "4"
                      nKol += (cAlias)->Kol
                    case nType == "5"
                      nKol += (cAlias)->QNTY
                 endcase
               endif
               (CAlias)->(dbSKIP())
             ENDDO
             if nKol > 0
               if (TAX_STR)->QNTY_BAS == nKol
               // Все количество по удаленным строкам
                 AADD(aDel,(TAX_STR)->(RecNo()) )
               endif
             endif
           endif

           (TAX_STR)->(DbSkip(1))
         enddo
       endif
    endif
  recover
    lRet := .F.
  end sequence
  Set(_SET_DELETED,SetDel)
  _DbAreaCloseA({CAlias, TAX_INV, TAX_STR})
Return lRet

Function SetCheckPosDefaultValue(Ident,Value,Type)
local oErr
local skey := Ident + B6_USER_IDENT
 begin sequence
  do case
    case Type == "N"
      SetCheckPos2({Value},,,skey)
    case Type == "C"
      SetCheckPos2(,{Value},,skey)
    case Type == "D"
      SetCheckPos2(,,{Value},skey)
  endcase

 recover using oErr
  if valtype(oErr) == "L"
     return oErr
   else
     return .F.
  endif
 end sequence
Return .T.


Function GetCheckPosDefaultValue(Ident,Value,Type)
local lRet := .T.
local skey := Ident + B6_USER_IDENT
local a := {} , ValRet
 begin sequence
 do case
    case Type == "N"
      GetCheckPos2(@a,,,,skey)
      ValRet := 0
    case Type == "C"
      GetCheckPos2(,@a,,,skey)
      ValRet := ""
    case Type == "D"
      GetCheckPos2(,,@a,,skey)
      ValRet := CTOD("")
  endcase

 recover
   lRet := .F.
 end sequence
 if lRet
   if ValType(a) == "A" .And. len(a) >0
     ValRet := a[1]
   endif
 endif
 Value := ValRet
Return lRet

Function  StrTaxArr(IdTaxMod,IdVal,cAlDoc,cAl,lSZ,cGrup)
local a := {}, aModStr := {},i
local lAddMod := .T., lRet, key, RetValue
Local lAddNds, lAddA, lPrichod := .F.
Local mRound := 2 , nNds := 0, nAcz := 0
Local nBaseN := 0
Local nTaxN := 0
Local nBaseA := 0
Local nTaxA := 0
Local nSumOut := 0
Local nTaxSumBaseA := 0
Local nTaxSumBaseN := 0

Static aMod := {}
 begin sequence
  if (DIC_VALUTA)->(DbSeek(IdVal))
    mRound := (DIC_VALUTA)->ACCURACY
  endif
  if lSZ .And. (cAlDoc)->Vid == "1"  // по постановке для расходных документов - берем сумму налога
    lPrichod := .T.  // для приходных - рассчитываем
  endif

  for i := 1 to len(aMod)
    if aMod[i][1] == IdTaxMod
      aModStr := aMod[i][2]
      lAddMod := .F.
      exit
    endif
  next
  if lAddMod
    aModStr := {}
    if !CreateArModStr(@aModStr,,,,IdTaxMod)
       break
    endif
    AADD(aMod,{IdTaxMod,aModStr})
  endif

  (cAl)->(DbGoTop())
  Do While !(cAl)->(Eof())
    nNds := 0
    nAcz := 0
    lAddNds := .T.
    lAddA := lSZ
    nTaxN :=  BS_ROUND((cAl)->SUM_NDS,mRound)
    if lSZ
      if (cGrup)->(DbSeek(Upper((cAl)->GRUP)))
        if ((cGrup)->TYPE == "3")
          (cAl)->(DbSkip(1))
          loop
        endif
      endif
      nSumOut := BS_ROUND((cAl)->SUMOUTR,mRound)
      nTaxA := BS_ROUND((cAl)->SUM_ACZ,mRound)
    else
      nSumOut := BS_ROUND((cAl)->SUMMA,mRound)
    endif
    for i := 1 to len(a)
     if a[i][1] == "2"
       if lSZ
         if a[i][2] == (cAl)->NDS .AND. a[i][5] == (cAl)->NONDS // НДС
           //a[i][3] += nTaxN
           nNds := i
           lAddNds := .F.
         endif
       else
         if a[i][6] == (cAl)->OPER_NDS
           //a[i][3] += nTaxN
           nNds := i
           lAddNds := .F.
         endif
       endif
     elseif lSZ
       if a[i][2] == (cAl)->PA
         //a[i][3] += nTaxA
         nAcz := i
         lAddA := .F.
       endif
     endif
    next

    if lAddNds
      if lSZ
        AADD(a,{"2",(cAl)->NDS,0,0,(cAl)->NONDS,})
        nNds := len(a)
        lRet := .F.
        Key := "НДС"
        RetValue := ""
        if !LookUpSeek("TAX\TAX_TP","TAG_CODE",@lRet,Key,"TAX_ID",@RetValue)
          Break
        endif
        if lRet
          Key := STR((cAl)->NDS,19,5)+IIF((cAl)->NoNDS,'1','0')+RetValue
          lRet := .F.
          RetValue := ""
          if !LookUpSeek("SPR_NDS","TAG_NDS",@lRet,Key,"NNOPER",@RetValue)
            Break
          endif
          if lRet
            a[nNds][6] := RetValue
          endif
        else
          Break
        endif
      else
        AADD(a,{"2",,0,0,,(cAl)->OPER_NDS})
        nNds := len(a)
        if !empty((cAl)->OPER_NDS)
          lRet := .F.
          Key := (cAl)->OPER_NDS
          RetValue := ""
          if !LookUpSeek("SPR_NDS","TAG_OPER",@lRet,Key,"NDS",@RetValue)
            Break
          endif
          if lRet
            a[nNds][2] := RetValue
          endif
        endif
      endif

    endif

    if lAddA .And. (cAl)->PA >0
      AADD(a,{"1",(cAl)->PA,0,0,,Space(22)})
      nAcz := len(a)
      lRet := .F.
      Key := "АКЦ"
      RetValue := ""
      if !LookUpSeek("TAX\TAX_TP","TAG_CODE",@lRet,Key,"TAX_ID",@RetValue)
        Break
      endif
      if lRet
        Key := STR((cAl)->PA,19,5)+IIF((cAl)->NoNDS,'1','0')+RetValue
        lRet := .F.
        RetValue := ""
        if !LookUpSeek("SPR_NDS","TAG_NDS",@lRet,Key,"NNOPER",@RetValue)
          Break
        endif
        if lRet
          a[nAcz][6] := RetValue
        endif
      else
        Break
      endif
    endif

    // Определим налогооблагаемую сумму
    if (cAlDoc)->L_NDS
      nBaseN := nSumOut - nTaxN
      if lSZ
        if (cAlDoc)->L_ACZ
          // 28296 pg ставки у акциза может не быть
          if !Empty(nTaxA)
            nTaxA := nTaxA
          elseif Empty(nTaxA) .And. !Empty((cAl)->PA)
            nTaxA := (nBaseN * ((cAl)->PA)/(100+(cAl)->PA))
          elseif Empty((cAl)->PA)
            nTaxA := 0
          endif
          nTaxA :=  BS_ROUND(nTaxA,mRound)
          nBaseA := nBaseN - nTaxA
        else
          if lPrichod
            if !Empty(nTaxA)
              nTaxA := nTaxA
            elseif Empty(nTaxA) .And. !Empty((cAl)->PA)
              nTaxA := (nBaseN * ((cAl)->PA)/((cAl)->PA))
            elseif Empty((cAl)->PA)
              nTaxA := 0
            endif
          else
            nTaxA := nTaxA
          endif
          nTaxA :=  BS_ROUND(nTaxA,mRound)
          nBaseA := nBaseN
        endif
      endif
    else
      if !Empty(nTaxN) .And. !Empty(a[nNds][2])//!Empty((cAl)->NDS)
        nTaxN := nTaxN
      elseif Empty(nTaxN) .And. !Empty(a[nNds][2])//!Empty((cAl)->NDS)
        nTaxN := (nSumOut * (a[nNds][2]/(100+a[nNds][2])))//(nSumOut * ((cAl)->NDS)/(100+(cAl)->NDS))
      elseif Empty(a[nNds][2])//Empty((cAl)->NDS)
        nTaxN := 0
      endif
      nTaxN :=  BS_ROUND(nTaxN,mRound)
      nBaseN := nSumOut
      if lSZ
        if (cAlDoc)->L_ACZ
          if !Empty(nTaxA)
            nTaxA := nTaxA
          elseif Empty(nTaxA) .And. !Empty((cAl)->PA)
            nTaxA := (nSumOut * ((cAl)->PA)/(100+(cAl)->PA))
          elseif Empty((cAl)->PA)
            nTaxA := 0
          endif
          nTaxA :=  BS_ROUND(nTaxA,mRound)
          nBaseA := nBaseN - nTaxA
        else
          if lPrichod
            if !Empty(nTaxA)
              nTaxA := nTaxA
            elseif Empty(nTaxA) .And. !Empty((cAl)->PA)
              nTaxA := (nBaseN * ((cAl)->PA)/(100+(cAl)->PA))
            elseif Empty((cAl)->PA)
              nTaxA := 0
            endif
          else
            nTaxA := nTaxA
          endif
          nTaxA :=  BS_ROUND(nTaxA,mRound)
          nBaseA := nBaseN
        endif
      endif
    endif
    if nNds > 0
      a[nNds][3] += nTaxN
      //a[nNds][4] += nBaseN
    endif
    if nAcz > 0
      a[nAcz][3] += nTaxA
      //a[nAcz][4] += nBaseA
    endif

    for i := 1 to len(aModStr)
      //mTax := 0
      do case
        case ((Alltrim(aModStr[i][_SYSNUM]) == "1")  .And. !lSZ )

          if (cAlDoc)->L_ACZ
            if aModStr[i][_CALCRL] // Налог извлекатся
              nTaxSumBaseA := nBaseA  + nTaxA
            else
              nTaxSumBaseA := nBaseA
            endif
          else
            if aModStr[i][_CALCRL] // Налог извлекатся
              nTaxSumBaseA := nBaseA  + nTaxA
            else
              nTaxSumBaseA := nBaseA
            endif
          endif
          a[nAcz][4] += nTaxSumBaseA

        case Alltrim(aModStr[i][_SYSNUM]) == "2"
          if (cAlDoc)->L_NDS // в документе НДС в том числе
            if aModStr[i][_CALCRL] // Налог извлекатся
              nTaxSumBaseN := nBaseN  + nTaxN
            else
              nTaxSumBaseN := nBaseN
            endif
          else //кроме того
            if aModStr[i][_CALCRL] // Налог извлекатся
              nTaxSumBaseN := nBaseN + nTaxN
            else
              nTaxSumBaseN := nBaseN
            endif
          endif
          a[nNds][4] += nTaxSumBaseN
      endcase
    next

    (cAl)->(DbSkip(1))
  enddo

  recover
    a := {}
  end sequence


Return a

FUNCTION IMPORTAXINV(TiCtg)
local oErr , a := {} ,aFileXml := {} , aFileCsv := {}
local cAlPr, cAlKb, cMsg := "" , lErr := .F.
local aBase := {} , aFile, i , j,cFile, cFileName , cTiCtg
local fstr := "" , cPath := "", aMssg := {}, aMss := {} //elem
local nAll :=0 , nImport := 0,cErrorFile,nErrorTmp,cCode  //hxmldocs ,
local nXml := 0, nStr := 0
  if !CanCreate('16', .T.)
    Return .T.
  endif
  cErrorFile := TEMPFILE( PublicVars():GlobalTmpPath, "txt" )
  If ( nErrorTmp := FCREATE(cErrorFile) ) == -1
     messagebox( "Ошибка создания временного файла" )
     Return .T.
  Endif
//Private cFile , cFileName , cTiCtg
//m->cTiCtg := TiCtg
  cTiCtg := TiCtg
begin sequence

 if ! _DbAreaOpen(B6_DBF_PATH + "Tax\KB.dbf", @cAlKb,"TAG_TPCODE")
       Break(.F.)
 endif
 if ! _DbAreaOpen(B6_DBF_PATH + "Tax\TAX_PARINI.DBF", @cAlPr,"")
       Break(.F.)
 endif


 ShowBusyPanel('Импорт счетов-фактур....')

 (cAlPr)->(DbGoTop())
 cPath := AllTrim((cAlPr)->IM_DIR)

 IF EMPTY(cPath)
   ErrorMsg('Задайте папку для импорта счетов-фактур.'+CHR(13)+CHR(10)+'(Настройка приложения-Экспорт-Импорт.)')
   Break(.F.)
 ELSE
   if (AllTrim(cPath)) $ "\/"
     ErrorMsg('Задайте папку для импорта счетов-фактур.'+CHR(13)+CHR(10)+'(Настройка приложения-Экспорт-Импорт.)')
     Break(.F.)
   endif
   if !(Right(cPath,1,1) $ "\/")
     cPath := cPath + "\"
   endif
 ENDIF
 IF !IsDir(cPath)
   ErrorMsg('Ошибка в указании папки экспорта '+CHR(13)+CHR(10)+cPath)
   Break(.F.)
 ENDIF
 aFile := DIRECTORY(cpath)
 for i := 1 to len(aFile)
   if Upper(right(aFile[i][1],4)) == ".XML" .And.;
      Upper(left(aFile[i][1],9)) $ {"ON_SFAKT_","ON_KORSFAKT_"}
      AADD(aFileXml,aFile[i][1])
   endif
   if Upper(right(aFile[i][1],4)) == ".CSV"
     AADD(aFileCsv,aFile[i][1])
   endif
 next

 If len(aFileXml) < 1 .And. len(aFileCsv) < 1
   ErrorMsg('Нет файлов для импорта счетов-фактур.')
   Break(.T.)
 endif
 if (cAlKb)->(Eof())
   ErrorMsg('Укажите активную программу импорта счетов-фактур.')
   Break(.F.)
 endif
 Do while !(cAlKb)->(Eof())
   cCode := Upper((cAlKb)->PrgImport)
   if AT(Upper("CreateSfFromStr"),cCode) > 0
     nStr := (cAlKb)->(RecNo())
   endif
   if AT(Upper("__ImportTaxInvXml"),cCode) > 0
     nXml := (cAlKb)->(RecNo())
   endif
   cCode := (cAlKb)->HrbImport
   if AT(Upper("CreateSfFromStr"),cCode) > 0
     nStr := (cAlKb)->(RecNo())
   endif
   if AT(Upper("__ImportTaxInvXml"),cCode) > 0
     nXml := (cAlKb)->(RecNo())
   endif
   cCode := (cAlKb)->HrbImport
   (cAlKb)->(DbSkip(1))
 enddo

 if Empty(nStr) .And. Empty(nXml)
   ErrorMsg('Укажите активную программу импорта счетов-фактур.')
   Break(.F.)
 endif

 if len(aFileCsv) > 0
   if nStr > 0
     (cAlKb)->(DbGoTo(nStr))
     CreateSfFromCsv(cPath,aFileCsv,cAlKb)
   endif
 else
   if nStr > 0
     (cAlKb)->(DbGoTo(nStr))
     ErrorMsg('Нет файлов для импорта счетов-фактур для шаблона ' + chr(13) + chr(10) + (cAlKb)->CODEFORMAT + " " + AllTrim((cAlKb)->PRIM) )

   endif
 endif
 nAll := len(aFileXml)
 if nAll < 1
   if nXml > 0
     (cAlKb)->(DbGoTo(nXml))
     ErrorMsg('Нет файлов для импорта счетов-фактур для шаблона ' + chr(13) + chr(10) + (cAlKb)->CODEFORMAT + " " + AllTrim((cAlKb)->PRIM) )
   endif
 endif
 for i := 1 to len(aFileXml)
   if nXml > 0
     (cAlKb)->(DbGoTo(nXml))
   else
     nAll := 0
     exit
   endif
   //m->cFile := cPath+aFileXml[i]
   cFile := cPath+aFileXml[i]
   //m->cFileName := aFileXml[i]
   cFileName := aFileXml[i]
   if File(cFile)//File(m->cFile)
     (cAlKb)->(DbGoTo(nXml))
     IF EvalStr(cAlKb + "->PrgImport",,,cAlKb + "->HrbImport",.T.)
        aMss := {}
        lErr := .F.
        if __ImportTaxInvXml(cFile,cFileName,cTiCtg,@aMss)
          nImport ++
        else
          lErr := .T.
        endif
        if len(aMss) > 0
          if len(aMssg) = 0
            AADD(aMssg,"Импорт счетов-фактур" )
          endif
          if lErr
            AADD(aMssg, chr(13) + chr(10) +"Ошибка импорта файла " + cFileName + chr(13) + chr(10))
          else
            AADD(aMssg, chr(13) + chr(10) +"Файл " + cFileName + chr(13) + chr(10))
          endif
          for j:= 1 to len(aMss)
            AADD(aMssg,aMss[j])
          next
        endif
     ELSE
        messagebox("Ошибка выполнения программы импорта",TITLEAPP,48)
        Break(.T.)
     ENDIF
      /*
     if ValType(hxmldocs) == "O"
       hxmldocs := nil
     endif
     a := {}
     hxmldocs := HXMLDoc():new()
     hxmldocs:read(cFile)
     elem := hxmldocs:Find("Файл")
     ParsXmlDoc(elem,a)
     if !GetStructXmlDoc(a,aFileXml[i],cTiCtg)
       Break(.F.)
     endif
     */
   endif
 next

 if nAll > 0
   cMsg := "Импорт завершен" + chr(13) + chr(10)
   cMsg += "Из " + AllTrim(Str(nAll,10,0)) +   " имортировано " + AllTrim(Str(nImport,10,0)) + " счетов-фактур "
   messagebox(cMsg,TITLEAPP,48)
 endif

 if len(aMssg) > 0
    for i := 1 to len(aMssg)
      FWRITE(nErrorTmp,aMssg[i])
    next
    FCLOSE(nErrorTmp )
    VIEW  (cErrorFile)
 endif

 Break(.T.)
 recover using oErr
  IF !EMPTY(cErrorFile).AND.FILE(cErrorFile)
     FCLOSE(nErrorTmp )
     FERASE(cErrorFile)
  ENDIF
  HideBusyPanel()
  for i := 1 to len(aBase)
    _DbAreaClose(aBase[i][1])
  next
  _DbAreaClose(cAlPr)
  _DbAreaClose(cAlKb)
  if valtype(oErr) == "L"
     return oErr
   else
     return .F.
  endif
 end sequence
Return .T.


FUNCTION EXPORTAXINV(bo)
local oErr
LOCAL nArea:=SELECT()
Local nRec := bo:DS:RecNo()
Local nRecMark := bo:MarkFirst()
Local nKolTotal := 0 ,cPath := "", cMss := ""
Local cAlKb , cAlPr, lError := .F.
Local nKolEx := 0 ,i , xReturn , lNoProgramm := .F.
LOCAL aBase:={;
{"PARTNER",B6_DBF_PATH+"PARTNER","TAG_ID"},;
{"PRT_ADDR",B6_DBF_PATH+"PRT_ADDR","TAG_PART"},;
{"TAX_INV",B6_DBF_PATH+"TAX\TAX_INV","TAG_ID"},;
{"TAX_STR",B6_DBF_PATH+"TAX\TAX_STR","TAG_DOC_ID"},;
{"TAX_SUM",B6_DBF_PATH+"TAX\TAX_SUM","TAG_STR"},;
{"TAX_TP",B6_DBF_PATH+"TAX\TAX_TP","TAG_ID"},;
{"SPR_NDS",B6_DBF_PATH+"SPR_NDS","TAG_OPER"};
}

FIELD TAX_ID
PRIVATE CURR_MAIN:=CGlobalVars():CURR_MAIN
PRIVATE cMarker,cCodeFormat
  aFileOut = {}

 if ! _DbAreaOpen(B6_DBF_PATH + "Tax\KB.dbf", @cAlKb,"TAG_TPCODE")
      RETURN .F.
 endif
 if ! _DbAreaOpen(B6_DBF_PATH + "Tax\TAX_PARINI.DBF", @cAlPr,"")
      RETURN .F.
 endif
 if nRecMark == 0
   messagebox("Не отмечено ни одного документа!",TITLEAPP,48)
   bo:DS:Goto(nRec)
   return .T.
 endif
 begin sequence
 ShowBusyPanel('Экспорт счетов-фактур....')
 //SaveVarGray(@cPath, "TAXDIRIM", , , "TAX\MemDat.Dbf")
 //cPath:=GetCheckPosTaxDefaultFolderExIm("TAXDIREX")
 (cAlPr)->(DbGoTop())
 cPath := AllTrim((cAlPr)->EX_DIR)

 IF EMPTY(cPath)
   ErrorMsg('Задайте папку для экспорта счетов-фактур.'+CHR(13)+CHR(10)+'(Настройка приложения-Экспорт-Импорт.)')
   HideBusyPanel()
   Break(.F.)
 ELSE
   if (AllTrim(cPath)) $ "\/"
     ErrorMsg('Задайте папку для экспорта счетов-фактур.'+CHR(13)+CHR(10)+'(Настройка приложения-Экспорт-Импорт.)')
     HideBusyPanel()
     Break(.F.)
   endif
   if !(Right(cPath,1,1) $ "\/")
     cPath := cPath + "\"
   endif
 ENDIF
 IF !IsDir(cPath)
   ErrorMsg('Ошибка в указании папки экспорта '+CHR(13)+CHR(10)+cPath)
   HideBusyPanel()
   Break(.F.)
 ENDIF
 //SaveSFFile()

 AEVAL(aBase,{|x|NetUseOrd(x[1],x[2],x[3])})

 SELECT TAX_SUM
 SET RELATION TO TAX_ID INTO TAX_TP

 do while !(nRecMark == 0 )
    progressupdate(nKolTotal)
    bo:ds:goto(nRecMark)
    (cAlKb)->(DbGoTop())
    nKolTotal ++
    if !(cAlKb)->(EOF()) //(DbSeek("СЧФ"))
      if bo:TI_CTG == "1"
        cMarker := "SPR"
      else
        cMarker := "SRS"
      endif
      /*
      if ValType(S_F_EX) != "O"
        S_F_EX := clsTax_Inv():New()
        S_F_EX:Open()
      endif
      S_F_EX:GOTO(nRecMark)
      */
      TAX_INV->(DbGoTo(nRecMark))
      TAX_STR->(OrdScope(0,TAX_INV->DOC_ID))
      TAX_STR->(OrdScope(1,TAX_INV->DOC_ID))
      TAX_STR->(DbGoTop())
      cCodeFormat:=TRIM((cAlKb)->CodeFormat)
      lError := .F.
      //                  1           23        4               5  6  7   8
      IF EvalStr(cAlKb + "->PrgExport",,,cAlKb + "->HrbExport",.T., , ,@xReturn )
        if ValType(xReturn) == "O"
          bo:ds:x_isMark_ := .F.
          //nKolEx ++
        else
          lError := .T.
        endif
      ELSE
        lError := .T.
      ENDIF

    else
      lNoProgramm := .T.
      //bo:ds:x_isMark_ := .F.
    endif
    nRecMark := bo:MarkNext()
 enddo
 nKolEx := 0
 for i := 1 to len(aFileOut)
   if File(aFileOut[1])
     nKolEx ++
   endif
 next
 if lNoProgramm
   messagebox("Не определена программы экспорта!",TITLEAPP,48)
 else
   cMss := "Выгрузка завершена" + chr(13) + chr(10)
   cMss += "Из " + AllTrim(Str(nKolTotal,10,0)) +   " выгружено " + AllTrim(Str(nKolEx,10,0)) + " счетов-фактур "  + chr(13) + chr(10)
   if nKolEx = 1
     cMss += aFileOut[1]
   elseif nKolEx > 1
     cMss +="в каталог " + cPath
   endif
   messagebox(cMss,TITLEAPP,48)
 endif



 //messagebox("Экспорт счетов-фактур в работе.")
 Break(.T.)
 recover using oErr
  HideBusyPanel()
  progresshide()
  aFileOut := {}
  for i := 1 to len(aBase)
    _DbAreaClose(aBase[i][1])
  next
  _DbAreaClose(cAlPr)
  _DbAreaClose(cAlKb)
  /*
  if ValType(S_F_EX) == "O"
    S_F_EX:Destroy()
  endif
  */
  if valtype(oErr) == "L"
     return oErr
   else
     return .F.
  endif
 end sequence
Return .T.

function SetCheckPosTaxDefaultFolderExIm(cFile,cKey)
local skey := cKey + B6_USER_IDENT + B6_ROLE_GUID
  SetCheckPos2(,{cFile},,skey)
return .t.

function GetCheckPosTaxDefaultFolderExIm(cKey)
local skey := cKey + B6_USER_IDENT + B6_ROLE_GUID
local a := {}
  GetCheckPos2(,@a,,,skey)
return if(len(a) > 0, a[1], "")

/************
PROCEDURE SaveSFFile(cHead,s,cFile,cFoot,cPath,cCodeOrg,cMarker)
STATIC sBuffer,sHead,sFile,sFoot
LOCAL hFile,dDate:=DATE()
altd()

IF s==NIL.AND.cPath==NIL.AND.cFoot==nil
   sBuffer:=""
   sHead:=""
   sFoot:=""
   sFile:=NIL
ELSEIF cPath==NIL
   IF RIGHT(s,2)!=CHR(13)+CHR(10)
     s+=CHR(13)+CHR(10)
   ENDIF
   sBuffer+=s

   IF cHead!=NIL
      sHead:=cHead
   ENDIF
   IF cFoot!=NIL
      sFoot:=cFoot
   ENDIF
   IF cFile!=NIL
      sFile:=cFile
   ENDIF
ELSE
   IF RIGHT(cPath,1)!="\"
      cPath+="\"
   ENDIF
   IF sFile==NIL
//      cFile:=cPath+PADR(cCodeOrg,5)+Hex31(DAY(dDate))+"00."+cMarker+Hex31(MONTH(dDate),.T.)
   ELSE
      cFile:=cPath+sFile
   ENDIF
   IF !FILE(cFile) .OR. ReplaceFile(@cFile)
      FERASE(cFile)
      IF (hFile := FCreate(cFile))==-1
         ErrorMsg("Не могу создать файл "+cFile)
      ELSE
         fWrite(hFile,sHead+IF(EMPTY(sHead).OR.RIGHT(sHead,2)==CHR(13)+CHR(10),"",CHR(13)+CHR(10))+sBuffer+;
         IF(EMPTY(sFoot),"",IF(RIGHT(sBuffer,2)==CHR(13)+CHR(10),"",CHR(13)+CHR(10))+sFoot))
         fClose(hFile)
         messagebox("Файл: "+cFile+ " записан!")
         sBuffer:=""
         cFile:=NIL
      ENDIF
   ENDIF
ENDIF
RETURN

STATIC FUNCTION ReplaceFile(cFile)
LOCAL nRet:=2
altd()
IF !FILE(NextFile(cFile))
   nRet := D_CUSTOMMSG("Внимание","Файл: "+cFile+" существует!","'Заменить' 1 'Сформировать следующий' 2 'Отмена' 0")
ENDIF
IF nRet==2
   WHILE FILE(cFile:=NEXTFILE(cFile))
   ENDDO
ENDIF
RETURN nRet>0

STATIC FUNCTION NextFile(cFile)
LOCAL nPos:=RAT(".",cFile)-2
LOCAL cc:=SUBSTR(cFile,nPos,2)
cc:=STRTRAN(STR(VAL(cc)+1,2,0)," ","0")
cFile:=STUFF(cFile,nPos,2,cc)
RETURN cFile
*********************************************/


FUNCTION OutPath()
LOCAL cc := "" //:=GetCheckPosTaxDefaultFolderExIm("TAXDIREX")
//altd()
  DO CASE
    CASE TYPE("cPayOutPath") = 'C'  // ("|EXPORTKB|" $ UPPER('|'+ProcName(4)+'|'+ProcName(5)+'|'+ProcName(6)+'|'))
      IF !(FIN_OBJ->(EOF()))
        cc := ALLTRIM(FIN_OBJ->OUT_DIR)
        IF !(RIGHT(cc, 1) == '\')
          cc := cc + '\'
        ENDIF
        m->cPplOutPath := cc
      ENDIF
    CASE TYPE("cPplOutPath") = 'C'  // ("|PPLEXPORTKB|" $ UPPER('|'+ProcName(4)+'|'+ProcName(5)+'|'+ProcName(6)+'|'))
      IF !(PPL_OBJ->(EOF()))
        cc := ALLTRIM(PPL_OBJ->OUT_DIR)
        IF !(RIGHT(cc, 1) == '\')
          cc := cc + '\'
        ENDIF
        m->cPayOutPath := cc
      ENDIF
    OTHERWISE
      GetTaxParamIni("EX_DIR",@cc)
  ENDCASE
RETURN cc

Function SetFileName(cFile)
  if !Empty(cFile) .And. ValType(cFile) == "C"
    AADD(aFileOut,cFile)
  endif
Return nil

Function GetDopParamForStr(cTbName,a,cKeyNNum)
local lRet := .T.,cLanelTb,aField := {},aRetVal := {},aKeys := {}
 begin sequence
 a := {}
 cLanelTb :=  cTbName + "MLabel.dbf"
 cTbName += "USER.dbf"
 aKeys := {;
           {"","MAIN","QMDocDC1"},;
           {"","MAIN","WQMDocDC1"},;
           {"","MAIN","QMDocDC2"},;
           {"","MAIN","WQMDocDC2"},;
           {"","MAIN","QMDocDC3"},;
           {"","MAIN","QMDocDC4"},;
           {"","MAIN","QMDocDN1"},;
           {"","MAIN","QMDocDN2"},;
           {"","MAIN","QMDocDD1"},;
           {"","MAIN","QMDocDD2"},;
           {"","MAIN","QMDocDC0"};
          }
 aKeys := GetParamsIsTbUserFieldXVal(cTbName, aKeys)
 if !Empty(aKeys[1]) .Or. !Empty(aKeys[3])
   aField := {"REFER1","REFER2"}
   aRetVal := {}
   if LookUpSeek(cLanelTb,"MLabel",@lRet,cKeyNNum,aField,@aRetVal)
      if lRet
        if !Empty(aRetVal[1])
          aKeys[2] := aRetVal[1]
        endif
        if !Empty(aRetVal[2])
          aKeys[4] := aRetVal[2]
        endif
      else
        Break(nil)
      endif
   else
     Break(nil)
   endif
 endif
 a := aKeys
 recover
  a := {}
  lRet := .F.
 end sequence
Return lRet

Function GenNameAnalit(cDimId,cKey)
local s := "" , lRet
Local cSys,cTag,cTbName,cAlg ,cAlgName
 begin sequence
 if (DIC_Dim_anl)->(DbSeek(cDimId))
   if Empty((DIC_Dim_anl)->SYS_ID)
   // Это справочник аналитик
     LookUpSeek("ANALIT_SEG","CODE",@lRet,Upper(cDimId+cKey),"NAME",@s)
   else
     if ! _DbAreaOpen(B6_DBF_PATH + "SYS_OBJ.dbf", @cSys,"ID")
       Break(nil)
     endif
     if (cSys)->(DbSeek((DIC_Dim_anl)->SYS_ID))
       cTbName := AllTrim((cSys)->PATHDBF) + AllTrim((cSys)->NAMEDBF)
       cTag := AllTrim((cSys)->CODETAG)
       cAlg := AllTrim((cSys)->ALG_SEEK)
       cAlgName := AllTrim((DIC_Dim_anl)->Alg_Name)
       if !Empty(cAlg)
         cAlg := &cAlg
         cKey := Eval(cAlg,cKey)
       endif
       LookUpSeek(B6_DBF_PATH + cTbName,cTag,@lRet,Upper(cKey),cAlgName,@s)
     endif
   endif
 endif

 recover
  s := ""
 end sequence
Return s

Function  StornoKorr(/*cAlSf*/)
local oErr
 begin sequence

 recover using oErr
  if valtype(oErr) == "L"
     return oErr
   else
     return .F.
  endif
 end sequence
Return .T.

Function ChechRegKorrForSt(o,cBookId)
local oErr, nSum := 0, oBook,cAl
 begin sequence

  oBook := o:BOOK
  cAl := oBook:cWa
  (cAl)->(DbGoTop())
  Do While !(cAl)->(Eof())
    if Empty(cBookId) .Or. !(cBookId == (cAl)->BOOK_ID)
      if (cAl)->REC_TP $ "ОТ,ОП,ВС,ВЧ,АВ,АУ,ПЛ"
        if !((cAl)->CMP_TP $ "1,3")
          if (cAl)->REC_TP $ "ОТ,ОП,АВ,АУ,ПЛ"
            nSum += (cAl)->REC_SUM
          else
            nSum -= (cAl)->REC_SUM
          endif
        endif
       endif
    endif
    (cAl)->(DbSkip())
  enddo
  oBook := o:BOOKST
  cAl := oBook:cWa
  (cAl)->(DbGoTop())
  Do While !(cAl)->(Eof())
    if Empty(cBookId) .Or. !(cBookId == (cAl)->BOOK_ID)
      if (cAl)->REC_TP $ "СА,ВЗ,СУ,ВУ"
        if !((cAl)->CMP_TP $ "1,3")
          nSum -= (cAl)->REC_SUM
        endif
      endif
    endif
    (cAl)->(DbSkip())
  enddo
 recover using oErr
   nSum := 0
 end sequence
Return Round(nSum,5)

//Определяет извлекается или начисляется налог от базовой суммы
Function TaxCalcRl(TaxId,aModStr, cIdMod)
local  k
  if ValType(aModStr) != "A" .Or. len(aModStr) == 0
    if Empty(cIdMod)
      messagebox("Ф-ция TaxCalcRl - не правильные параметры" )
      Return .T.
    endif
    if !CreateArModStr(@aModStr,,,,cIdMod)
      messagebox("Ф-ция TaxCalcRl - не правильные параметры" )
      Return .T.
    endif
  endif
  for k := 1 to len(aModStr)
    if  TaxId == aModStr[k][_TAXID]
      Return aModStr[k][_CALCRL]
    endif
  next
Return .T.

Function SetBaseBook()
local cTaxInv, cTaxSum, cBook, cBkTax, cModStr, cTaxArcInv
local cKey,nBaseSum,nBaseSumSt
local cKeyBook, cKeyMod
 if !File(B6_DBF_PATH + "Tax\TAX_INV.dbf")
   Return .T.
 endif
 if !File(B6_DBF_PATH + "Tax\ARC\TAX_INV.dbf")
   Return .T.
 endif
 if !File(B6_DBF_PATH + "Tax\TAX_SUM.dbf")
   Return .T.
 endif
 if !File(B6_DBF_PATH + "Tax\BOOK.dbf")
   Return .T.
 endif
 if !File(B6_DBF_PATH + "Tax\BK_TAX.dbf")
   Return .T.
 endif
 if !File(B6_DBF_PATH + "Tax\MOD_STR.dbf")
   Return .T.
 endif
 begin sequence
 _DbAreaOpen(B6_DBF_PATH + "Tax\TAX_INV.dbf", @cTaxInv,"TAG_ID")
 _DbAreaOpen(B6_DBF_PATH + "Tax\ARC\TAX_INV.dbf", @cTaxArcInv,"TAG_ID")
 _DbAreaOpen(B6_DBF_PATH + "Tax\TAX_SUM.dbf", @cTaxSum,"TAG_DOCED")
 _DbAreaOpen(B6_DBF_PATH + "Tax\BOOK.dbf", @cBook,"TAG_SF")
 _DbAreaOpen(B6_DBF_PATH + "Tax\BK_TAX.dbf", @cBkTax,"TAG_BOOK")
 _DbAreaOpen(B6_DBF_PATH + "Tax\MOD_STR.dbf", @cModStr,"TAG_ID")
 (cTaxInv)->(DbGoTop())
 Do while !(cTaxInv)->(Eof())
   if (cTaxInv)->SUM_BOOK > 0
     cKey := (cTaxInv)->DOC_ID
     (cTaxSum)->(OrdScope(0,cKey))
     (cTaxSum)->(OrdScope(1,cKey))
     (cTaxSum)->(DbGoTop())
     do while !(cTaxSum)->(Eof())
       nBaseSum := 0
       nBaseSumSt := 0
       if (cTaxInv)->SUM_BOOK == (cTaxInv)->SUM_A
         nBaseSum := (cTaxSum)->TAX_BASE
       else
         if (cTaxSum)->TAX_BASE > 0
           if (cTaxSum)->TAX_SUM > 0 .And. (cTaxSum)->TAX_SUM == (cTaxSum)->TAX_BOOK
             nBaseSum := (cTaxSum)->TAX_BASE
           else
             (cBook)->(OrdSetFocus("TAG_SF"))
             (cBook)->(OrdScope(0,cKey))
             (cBook)->(OrdScope(1,cKey))
             (cBook)->(DbGoTop())
             do while !(cBook)->(Eof())
               cKeyBook := (cBook)->BOOK_ID
               (cBkTax)->(OrdScope(0,cKeyBook))
               (cBkTax)->(OrdScope(1,cKeyBook))
               (cBkTax)->(DbGoTop())
               do while !(cBkTax)->(Eof())
                 if (cTaxSum)->TAX_ID == (cBkTax)->TAX_ID .And.;
                    (cTaxSum)->TAX_IDRT == (cBkTax)->TAX_IDRATE .And.;
                    (cTaxSum)->TAX_RATE == (cBkTax)->TAX_RATE
                    if (cBook)->REC_TP $ {"СА","СУ"}//?? Нужно учитывать налоговую модель
                      if (cTaxInv)->MOD_ID == (cBook)->MOD_ID
                        nBaseSumSt += (cBkTax)->TAX_BASE
                      else
                        cKeyMod := (cTaxInv)->MOD_ID
                        (cModStr)->(OrdScope(0,cKeyMod))
                        (cModStr)->(OrdScope(1,cKeyMod))
                        (cModStr)->(DbGoTop())
                        Do while !(cModStr)->(Eof())
                          if (cTaxSum)->TAX_ID == (cModStr)->TAX_ID
                            if (cModStr)->CALC_RL
                              nBaseSumSt += (cBkTax)->TAX_BASE
                            else
                              nBaseSumSt += (cBkTax)->TAX_BASE - (cBkTax)->TAX_SUM
                            endif
                            exit
                          endif
                          (cModStr)->(DbSkip(1))
                        enddo
                      endif
                    else
                      if (cBook)->REC_TP $ "ВЗ,ВУ"
                        nBaseSumSt += (cBkTax)->TAX_BASE
                      elseif (cBook)->REC_TP $ "ВС,ВЧ"
                        nBaseSum -=  (cBkTax)->TAX_BASE
                      else
                        nBaseSum += (cBkTax)->TAX_BASE
                      endif
                    endif
                    exit
                 endif
                 (cBkTax)->(DbSkip(1))
               enddo
               (cBook)->(DbSkip(1))
             enddo
           endif

         endif
       endif
       if (cTaxInv)->SUM_BOOK == (cTaxInv)->ST_SUM
         nBaseSumSt := nBaseSum
       else
         if (cTaxInv)->ST_SUM > 0 .And. (cTaxSum)->TAX_BASE > 0
           if (cTaxSum)->TAX_ST > 0 .And. (cTaxSum)->TAX_ST == (cTaxSum)->TAX_SUM
             nBaseSumSt := nBaseSum
           else
             (cBook)->(OrdSetFocus("TAG_SFST"))
             (cBook)->(OrdScope(0,cKey))
             (cBook)->(OrdScope(1,cKey))
             (cBook)->(DbGoTop())
             do while !(cBook)->(Eof())
               cKeyBook := (cBook)->BOOK_ID
               (cBkTax)->(OrdScope(0,cKeyBook))
               (cBkTax)->(OrdScope(1,cKeyBook))
               (cBkTax)->(DbGoTop())
               do while !(cBkTax)->(Eof())
                 if (cTaxSum)->TAX_ID == (cBkTax)->TAX_ID .And.;
                    (cTaxSum)->TAX_IDRT == (cBkTax)->TAX_IDRATE .And.;
                    (cTaxSum)->TAX_RATE == (cBkTax)->TAX_RATE
                    nBaseSumSt += (cBkTax)->TAX_BASE
                    exit
                 endif
                 (cBkTax)->(DbSkip(1))
               enddo
               (cBook)->(DbSkip(1))
             enddo
           endif

         endif
       endif
       if nBaseSum >0 .Or. nBaseSumSt > 0
         if (cTaxSum)->(DbRLock((cTaxSum)->(RecNo())))
           (cTaxSum)->BASE_BOOK := nBaseSum
           (cTaxSum)->BASE_ST   := nBaseSumSt
           (cTaxSum)->(DbRUnLock((cTaxSum)->(RecNo())))
         endif
       endif
       (cTaxSum)->(DbSkip(1))
     enddo

   endif
   if Empty((cTaxInv)->MET_FORM)
     if (cTaxInv)->(DbRLock((cTaxInv)->(RecNo())))
        (cTaxInv)->MET_FORM := "1"
        (cTaxInv)->(DbRUnLock((cTaxInv)->(RecNo())))
     endif
   endif
   (cTaxInv)->(DbSkip(1))
 enddo

 (cTaxArcInv)->(DbGoTop())
 Do while !(cTaxArcInv)->(Eof())
   if Empty((cTaxArcInv)->MET_FORM)
     if (cTaxArcInv)->(DbRLock((cTaxArcInv)->(RecNo())))
       (cTaxArcInv)->MET_FORM := "1"
       (cTaxArcInv)->(DbRUnLock((cTaxArcInv)->(RecNo())))
     endif
   endif
   (cTaxArcInv)->(DbSkip(1))
 enddo

 end sequence
 _DbAreaClose(cTaxInv)
 _DbAreaClose(cTaxArcInv)
 _DbAreaClose(cTaxSum)
 _DbAreaClose(cBook)
 _DbAreaClose(cBkTax)
 _DbAreaClose(cModStr)
Return .T.

Function CheckTaxModStr()
Local cAlMod, cAlStr
  if !File(B6_DBF_PATH + "Tax\TAX_MOD.dbf")
    Return .T.
   endif
   if !File(B6_DBF_PATH + "Tax\MOD_STR.dbf")
     Return .T.
   endif
   begin sequence
   _DbAreaOpen(B6_DBF_PATH + "Tax\TAX_MOD.dbf", @cAlMod,"TAG_ID")
   _DbAreaOpen(B6_DBF_PATH + "Tax\MOD_STR.dbf", @cAlStr,"TAG_MOD")
   (cAlMod)->(DbGoTop())
   do while !(cAlMod)->(Eof())
     if (cAlMod)->SUM_USE == "1"
       (cAlStr)->(OrdScope(0,(cAlMod)->MOD_ID))
       (cAlStr)->(OrdScope(1,(cAlMod)->MOD_ID))
       (cAlStr)->(DbGoTop())
       do while !(cAlStr)->(Eof())
         if (cAlStr)->(DbRLock((cAlStr)->(RecNo())))
           (cAlStr)->PRICE_IN := (cAlStr)->CALC_RL
           (cAlStr)->(DbRUnLock((cAlStr)->(RecNo())))
         endif
         (cAlStr)->(DbSkip(1))
       enddo
     endif
     (cAlMod)->(DbSkip(1))
   enddo
   end sequence
 _DbAreaClose(cAlMod)
 _DbAreaClose(cAlStr)
Return .T.

Function ParsXmlDoc(elem,a,cTitle)
local aAtr := elem:AATTR
local aItem := elem:AITEMS
local i , CurrentTitle := ""
  if __objHasData(elem,"title")
    CurrentTitle := elem:title
  endif
  if ValType(cTitle) != "C"
    cTitle := ""
  endif
  for i := 1 to len(aAtr)
    if ValType(aAtr[i]) == "O"
      ParsXmlDoc(aAtr[i],a)
    elseif ValType(aAtr[i]) == "A"
      if Upper(AllTrim(aAtr[i][1])) == Upper("Идентиф") .And.;
         i < len(aAtr) .And. Upper(AllTrim(aAtr[i+1][1])) == Upper("Значение")
         AADD(a,{aAtr[i][2],aAtr[i+1][2],cTitle + "-" + CurrentTitle })
         i++
      else
        AADD(a,{aAtr[i][1],aAtr[i][2],cTitle + "-" + CurrentTitle})
      endif
    endif
  next
  for i := 1 to len(aItem)
    if ValType(aItem[i]) == "O"
      ParsXmlDoc(aItem[i],a,cTitle + "-" + CurrentTitle)
    elseif ValType(aItem[i]) == "A"
      AADD(a,{aItem[i][1],aItem[i][2],cTitle + "-" + CurrentTitle})
    else
      AADD(a,{CurrentTitle,aItem[i],cTitle + "-" + CurrentTitle})
    endif
  next
return .T.
/*
Function GetStructXmlDoc(arr,cFile,cTiCtg)
local a := {},aStr := {},i
local cParam,Value
local idOtprav := "" , IdGrOtprav := "", cSobsName := "" , cGrOtpravName := ""
local idPoluch := "" , idGrPoluch := "" ,cPoluchName := "" , cGrPoluchName := ""
Local IsKor := .F.
local cDocNum := "" , dDocDate := CTOD("") , cMoveTp := "", cValId := ""
local lRet ,lNoNds
local cMsg := ''
local cDocNumDef := "", cDocNumKor := "",  dDocDateDef := CTOD(""),dDocDateKor := CTOD("")
local cDocNumKorSfDef := "",cDateNumKorSfDef := CTOD("") //Исправительный к корректируемому - в корректировочном
local IsDef := .F. , IsDefKorSf
local IsBest5 := .F. , sTextInf := "" ,sTextInfStr := ""
local idOper := "", nLen
local cSfId := "", cSfDefId := ""
local lAdd := .F.
Local nNomStr := 0,cNameTov := "", cOKEY := "",nQuan := 0,nPrice := 0
local nCostNotTax := 0, nCostAll := 0,nTaxNdsRate := 0, IdTaxNdsRate := "",lA := .F.
local nTaxARate := 0, IdTaxARate := "", nNdsSum := 0, nASum := 0, lNds := .T.
local cCountry := "", cGTD := "", lStA := .F. , nRate := 0, IdRate := ""
local cSfStrId := "",cStrTp := "",cGroup := "",cNomNum := "",cPart := "",cStrFrom := "", cComment := ""
local aAns ,aIniValue , nSumSfNNds := 0, nSumSfNds := 0 , nSumSfA := 0  ,lNoNdsSf := .F.
local cSfKorrId := "", IdPosred := "", cSfPosredId := ""
local cKOP_NDS := "",cKOP_AST := "", cKOP_NNDS := "",cKOP_NDS0 := "",cKOP_AG_NDS := ""
local dCUST_DATE := CTOD(""),dCONF_DATE := CTOD(""),cCompl_M := ""
  for i := 1 to len(arr)
    cParam := Upper(AllTrim(arr[i][1]))
    Value := Upper(AllTrim(arr[i][2]))
    DO CASE
      CASE cParam == Upper("ИдФайл")
        if AllTrim(Upper(Value + ".xml")) != Upper(AllTrim(cFile))
           if (6 != messagebox("Имя файла не соответствует имени в параметре 'ИдФайл'. Продолжить? ",TITLEAPP,68))
             Return .F.
           Endif
        endif
        if "ON_KORSFAKT_" $ Value
          IsKor := .T.
        endif
      CASE cParam == Upper("ВерсПрог")
        if Value == Upper("БЭСТ-5")
          IsBest5 := .T.
        endif
      CASE cParam == Upper("ВерсФорм")
        if Value != Upper(AllTrim("5.02"))
           if (6 != messagebox("Версия формата " +  Value +". Продолжить? ",TITLEAPP,68))
             Return .F.
           Endif
        endif
      CASE cParam == Upper("ИдОтпр")
        if Empty(Value)
          ErrorMsg('Для отправителя не определен код участника электронного документооборота')
          Return .F.
        endif
        idOtprav := Value

      CASE cParam == Upper("ИдПок")
        if Empty(Value)
          ErrorMsg('Для покупателя не определен код участника электронного документооборота')
          Return .F.
        endif
        idPoluch := Value

      CASE cParam == Upper("КНД")
        lRet := .T.
        If IsKor
          if Value != "1115108"
            lRet := .F.
          endif
        else
          if Value != "1115101"
            lRet := .F.
          endif
        endif
        if !lRet
          if (6 != messagebox("Код формы по КНД:  " +  Value +". Продолжить? ",TITLEAPP,68))
             Return .F.
           Endif
        endif
     CASE cParam == Upper("ИдЭДО")
       idOper := Value
       if Empty(idOper)
         ErrorMsg('Для отправителя не определен идентификатор оператора электронного документооборота')
         Return .F.
       endif
       nLen := len(idOper)
       idOtprav := SubStr(idOtprav,nLen + 1)
       if Empty(idOtprav) .Or. !(DIC_PARTNER)->(DbSeek(idOtprav,.T.,"TAG_UCHEDO"))
         ErrorMsg('Для отправителя не определен код участника электронного документооборота')
         Return .F.
       else
         idOtprav := (DIC_PARTNER)->PART_ID
       endif
       idPoluch := SubStr(idPoluch,nLen + 1)
       if Empty(idPoluch) .Or. !(DIC_PARTNER)->(DbSeek(idPoluch,.T.,"TAG_UCHEDO"))
         ErrorMsg('Для отправителя не определен код участника электронного документооборота')
         Return .F.
       else
         idPoluch := (DIC_PARTNER)->PART_ID
       endif

     CASE cParam == Upper("ИННЮЛ")
       if Upper("СвУчДокОбор") $ Upper(AllTrim(arr[i][3]))
         if !CheckPartnerForInn(Value,.T.)
           ErrorMsg('Не определен оператор электронного документооборота')
           Return .F.
         endif
       endif
     CASE cParam == Upper("НаимОрг")
       if Upper("СвСчФакт-СвПрод-ИдСв-СвЮЛ") $ Upper(AllTrim(arr[i][3]))
         cSobsName := Value
       endif
       if Upper("СвСчФакт-СвПокуп-ИдСв-СвЮЛ") $ Upper(AllTrim(arr[i][3]))
         cPoluchName := Value
       endif
       if Upper("СвСчФакт-ГрузОт-ГрузОтпр-НаимГОП") $ Upper(AllTrim(arr[i][3]))
         cGrOtpravName := Value
       endif
       if Upper("СвСчФакт-ГрузПолуч-НаимГОП") $ Upper(AllTrim(arr[i][3]))
         cGrPoluchName := Value
       endif
     CASE cParam == Upper("ОнЖе")
        IdGrOtprav := IdOtprav
     CASE cParam == Upper("ИННФЛ")
       if Upper("СвСчФакт-ГрузОт-ГрузОтпр-НаимГОП") $ Upper(AllTrim(arr[i][3]))
         if !CheckPartnerForInn(Value,.F.,@IdGrOtprav)
           IdGrOtprav := ""
           //не определен грузоотправитель
         endif
       endif
       if Upper("СвСчФакт-ГрузПолуч-НаимГОП") $ Upper(AllTrim(arr[i][3]))
         if !CheckPartnerForInn(Value,.F.,@IdGrPoluch)
           IdGrPoluch := ""
           //не определен грузоотправитель
         endif
       endif
   ENDCASE
  next
  //Не можем определить адресса
  if !Empty(cGrOtpravName)
    if cGrOtpravName == cSobsName
      IdGrOtprav := idOtprav
    else
       //не определен грузоотправитель
    endif
  endif

  if !Empty(cGrPoluchName)
    if cGrPoluchName == cPoluchName
      IdGrPoluch := idPoluch
    else
      //не определен грузополучатель
    endif
  endif


  for i := 1 to len(arr)
    cParam := Upper(AllTrim(arr[i][1]))
    Value := Upper(AllTrim(arr[i][2]))
    DO CASE
      CASE cParam == Upper("НомерСчФ")
        cDocNum := AllTrim(arr[i][2])
        if len(cDocNum) > 24
          cMsg := ''
          cMsg += ' Номер счета-фактурв больше 24 символов.' + CRLF
          cMsg += 'При записи будет урезан до 24 символов. Продолжить? '
          if (6 != messagebox(cMsg,TITLEAPP,68))
             Return .F.
          Endif
          cDocNum := PADR(AllTrim(arr[i][2]),24)
        endif
      CASE cParam == Upper("ДатаСчФ")
        if !conversionDateFromXml(@Value)
          cMsg := ''
          cMsg += ' Не верно передана дата счета-фактуры.' + CRLF
          cMsg += 'При записи будет изменена на текущую. Продолжить? '
          if (6 != messagebox(cMsg,TITLEAPP,68))
             Return .F.
          Endif
          dDocDate := date()
        else
          dDocDate := Value
        endif
      CASE cParam == Upper("КодОКВ")
        if Empty(Value) .Or. !CheckValutaFromXml(@Value)
          cMsg := ''
          cMsg += ' Не верно передана валюта счета-фактуры.' + CRLF
          cMsg += 'При записи будет установлена основная валюта. Продолжить? '
          if (6 != messagebox(cMsg,TITLEAPP,68))
             Return .F.
          Endif
          GetCurrParam(@cValId,,,,.T.)
        else
          cValId := Value
        endif
      CASE cParam == Upper("НомИспрСчФ")
        if !Empty(Value)
          IsDef := .T.
        endif
        cDocNumDef := AllTrim(arr[i][2])
        if len(cDocNumDef) > 24
          cMsg := ''
          cMsg += ' Номер счета-фактурв больше 24 символов.' + CRLF
          cMsg += 'При записи будет урезан до 24 символов. Продолжить? '
          if (6 != messagebox(cMsg,TITLEAPP,68))
             Return .F.
          Endif
          cDocNum := PADR(AllTrim(arr[i][2]),24)
        endif
      CASE cParam == Upper("ДатаИспрСчФ")
        if !conversionDateFromXml(@Value)
          cMsg := ''
          cMsg += ' Не верно передана дата счета-фактуры.' + CRLF
          cMsg += 'При записи будет изменена на текущую. Продолжить? '
          if (6 != messagebox(cMsg,TITLEAPP,68))
             Return .F.
          Endif
          dDocDateDef := date()
        else
          dDocDateDef := Value
        endif
      CASE cParam == Upper("НомерКСчФ")
        cDocNumKor := AllTrim(arr[i][2])
        if len(cDocNumKor) > 24
          cMsg := ''
          cMsg += ' Номер счета-фактурв больше 24 символов.' + CRLF
          cMsg += 'При записи будет урезан до 24 символов. Продолжить? '
          if (6 != messagebox(cMsg,TITLEAPP,68))
             Return .F.
          Endif
          cDocNumKor := PADR(AllTrim(arr[i][2]),24)
        endif
      CASE cParam == Upper("ДатаКСчФ")
        if !conversionDateFromXml(@Value)
          cMsg := ''
          cMsg += ' Не верно передана дата счета-фактуры.' + CRLF
          cMsg += 'При записи будет изменена на текущую. Продолжить? '
          if (6 != messagebox(cMsg,TITLEAPP,68))
             Return .F.
          Endif
          dDocDateKor := date()
        else
          dDocDateKor := Value
        endif
      CASE cParam == Upper("НомИспрКСчФ")
        if !Empty(Value)
          IsDefKorSf := .T.
        endif
        cDocNumKorSfDef := AllTrim(arr[i][2])
        if len(cDocNumKorSfDef) > 24
          cMsg := ''
          cMsg += ' Номер счета-фактурв больше 24 символов.' + CRLF
          cMsg += 'При записи будет урезан до 24 символов. Продолжить? '
          if (6 != messagebox(cMsg,TITLEAPP,68))
             Return .F.
          Endif
          cDocNumKorSfDef := PADR(AllTrim(arr[i][2]),24)
        endif
      CASE cParam == Upper("ДатаИспрКСчФ")
        if !conversionDateFromXml(@Value)
          cMsg := ''
          cMsg += ' Не верно передана дата счета-фактуры.' + CRLF
          cMsg += 'При записи будет изменена на текущую. Продолжить? '
          if (6 != messagebox(cMsg,TITLEAPP,68))
             Return .F.
          Endif
          cDateNumKorSfDef := date()
        else
          cDateNumKorSfDef := Value
        endif
      CASE Upper("ИнфПол-ТекстИнф") $ Upper(AllTrim(arr[i][3]))

          Do case
            case  cParam == Upper("ИД_СФ")
              cSfId := Value
            case  cParam == Upper("TI_CTG")
              if !Empty(Value) .And. Value $ "12"
                cTiCtg := Value
              endif
            case  cParam == Upper("MOVE_TP")
              cMoveTp := Value
            case  cParam == Upper("DEF")
              if Value == "T"
                isDef := .T.
              endif
            case  cParam == Upper("SFD_ID")
              cSfDefId := Value
            case  cParam == Upper("ИД_Грузоотпр")
              if !Empty(Value) .And. (DIC_PARTNER)->(DbSeek(Value,.T.,"TAG_UCHEDO"))
                IdGrOtprav := (DIC_PARTNER)->PART_ID
              endif
            case  cParam == Upper("ИД_Грузопол")
              if !Empty(Value) .And. (DIC_PARTNER)->(DbSeek(Value,.T.,"TAG_UCHEDO"))
                idGrPoluch := (DIC_PARTNER)->PART_ID
              endif
            case  cParam == Upper("KORR")
              if Value == "T"
                IsKor := .T.
              endif
            case  cParam == Upper("ИД_ПОСРЕД")
              if !Empty(Value) .And. (DIC_PARTNER)->(DbSeek(Value,.T.,"TAG_UCHEDO"))
                IdPosred := (DIC_PARTNER)->PART_ID
              endif
            case  cParam == Upper("ИД_ПОСР_ОСНОВ")
              cSfPosredId := Value
            case  cParam == Upper("КОД_ОПЕР_СФ")
              cKOP_NDS := Value
            case  cParam == Upper("КОД_НДС0")
              cKOP_NDS0 := Value
            case  cParam == Upper("КОД_НЕТ_НДС")
              cKOP_NNDS := Value
            case  cParam == Upper("КОД_АГЕНТА")
              cKOP_AG_NDS := Value
            case  cParam == Upper("КОД_НЕДВ")
              cKOP_AST := Value
            case  cParam == Upper("ДАТА_ТАМОЖ")
              if !Empty(!conversionDateFromXml(@Value))
                dCUST_DATE := Value
              endif
            case  cParam == Upper("ДАТА_ПОДТВ")
              if !Empty(!conversionDateFromXml(@Value))
                dCONF_DATE := Value
              endif
            case  cParam == Upper("Коммент_сф")
              cCompl_M := Value

            OTHERWISE
              if Empty(sTextInf)
                sTextInf := "Параметры дополнительной информации от " + cSobsName + " :" + CRLF
              endif
              sTextInf += "Имя: " + Upper(AllTrim(arr[i][1])) + " Значение: " + Upper(AllTrim(arr[i][2])) + CRLF
          endcase

      CASE cParam == Upper("СтТовБезНДСВсего")
        nSumSfNNds := Val(Value)
      CASE cParam == Upper("СтТовУчНалВсего")
        nSumSfA := Val(Value)
      CASE Upper("ВсегоОпл-СумНалВсего") $ Upper(AllTrim(arr[i][3]))
        do case
          CASE cParam == Upper("СумНДС")
            nSumSfNds := Val(Value)
          CASE cParam == Upper("БезНДС")
            lNoNdsSf := .T.
        endcase
      CASE cParam == Upper("НомСтр") .Or. i == len(arr) - 1
        lAdd := .F.
        if cParam != Upper("НомСтр") .And. nNomStr != 0
          lAdd := .T.
        else
          if nNomStr != Val(Value)
            if  nNomStr != 0
              lAdd := .T.
            endif
            nNomStr := Val(Value)
          endif
        endif
        if lAdd
          if !Empty(nASum) .And. Empty(IdTaxARate)
             if !CheckRateA(nCostNotTax,nASum,@nTaxARate,@IdTaxARate,dDocDate)
               ErrorMsg('Не удалось определить ставку Акциза.')
               Return .F.
             endif
          endif
          AADD(astr,{nNomStr,cNameTov,cOKEY,nQuan,nPrice,nCostNotTax,nCostAll,;
                     lNds,nTaxNdsRate,IdTaxNdsRate,lA,nTaxARate,IdTaxARate,;
                     nNdsSum,nASum,cCountry,cGTD,cSfStrId,cStrTp,cGroup,;
                     cNomNum,cPart,cStrFrom,cComment})


          cNameTov := ""
          cOKEY := ""
          nQuan := 0
          nPrice := 0
          nCostNotTax := 0
          nCostAll := 0
          nTaxNdsRate := 0
          IdTaxNdsRate := ""
          lA := .F.
          nTaxARate := 0
          IdTaxARate := ""
          nNdsSum := 0
          nASum := 0
          lNds := .T.
          cCountry := ""
          cGTD := ""
          cSfStrId := ""
          cStrTp := ""
          cGroup := ""
          cNomNum := ""
          cPart := ""
          cStrFrom := ""
          cComment := ""
        endif
      CASE cParam == Upper("НаимТов")
        cNameTov := Value
      CASE cParam == Upper("ОКЕИ_Тов")
        cOKEY := Value
      CASE cParam == Upper("КолТов")
        nQuan := Val(Value)
      CASE cParam == Upper("ЦенаТов")
        nPrice := Val(Value)
      CASE cParam == Upper("СтТовБезНДС")
        nCostNotTax := Val(Value)
      CASE cParam == Upper("СтТовУчНал")
        nCostAll := Val(Value)
      CASE cParam == Upper("НалСт")
        lNoNds := .F.
        if Upper("без") $ Value
          lNoNds := .T.
          Value := 0
        elseif AT("/",Value) > 0
          Value := Val(SubStr(1,AT("/",Value)-1))
        elseif AT("%",Value) > 0
          Value := Val(SubStr(1,AT("%",Value)-1))
        else
          Value := Val(Value)
        endif
        if !CheckTax(Value,lNoNds,@IdRate,@lStA,dDocDate)
          ErrorMsg('Ставка НДС - " + Str(Value,10,5) + "%  отсутствует в справочнике')
          Return .F.
        endif
        if  lStA
          nTaxARate := Value
          IdTaxARate := IdRate
        else
          nTaxNdsRate := Value
          IdTaxNdsRate := IdRate
          lNds := !lNoNds
        endif


      CASE cParam == Upper("БезАкциз")
        lA := .F.
      CASE cParam == Upper("СумАкциз")
        nASum := Val(Value)
      CASE cParam == Upper("СумНДС")
        nNdsSum := Val(Value)
      CASE cParam == Upper("КодПроисх")
        cCountry := Value
      CASE cParam == Upper("НомерТД")
        cGTD := Value

      CASE Upper("ТаблСчФакт-СведТов-ИнфПолСтр") $ Upper(AllTrim(arr[i][3]))

          Do case
            case  cParam == Upper("STR_ID")
              cSfStrId := Value
            case  cParam == Upper("STR_TP")
              if !Empty(Value) .And. Value $ "01234567"
                cStrTp := Value
              endif
            case  cParam == Upper("ГРУППА")
              cGroup := Value
            case  cParam == Upper("НОМ_НОМЕР")
              cNomNum := Padr(Value,13)
            case  cParam == Upper("НОМ_ПАРТИЯ")
              cPart := Value
            case  cParam == Upper("Тип_СТРОКИ")
              cStrFrom := Value
            case  cParam == Upper("КОММЕНТ_СТРОКИ")
              cComment := Value
            OTHERWISE
              if Empty(sTextInfStr)
                sTextInfStr := "Параметры дополнительной информации по строкам от " + cSobsName + " :" + CRLF
              endif
              sTextInfStr += "Имя: " + Upper(AllTrim(arr[i][1])) + " Значение: " + Upper(AllTrim(arr[i][2])) + CRLF
          endcase

    ENDCASE
  next

  If !Empty(sTextInf)
    cMsg := sTextInf + CRLF
    cMsg := "не обработаны программой импорта. Продолжить?  " + CRLF
    if (6 != messagebox(cMsg,TITLEAPP,68))
       messagebox("В работе")
    Endif
  endif

  If !Empty(sTextInfStr)
    cMsg := sTextInfStr + CRLF
    cMsg += 'не обработаны программой импорта. Продолжить? ' + CRLF
    if (6 != messagebox(cMsg,TITLEAPP,68))
       Return .F.
    Endif
  endif

  if len(astr)==0
    cMsg := " У импортируемого счета-фактуры нет строк"
    cMsg += 'продолжить импорт?' + CRLF
    if (6 != messagebox(cMsg,TITLEAPP,68))
       Return .F.
    Endif
  endif

  if ValType(cTiCtg) != "C" .Or. Empty(cTiCtg) .Or. !(cTiCtg $ "1,2")
    aAns:={'Закупка','Продажа default'}
    aIniValue := {{'Категория счета-фактуры',aAns}}
    a := DialogGr('Укажите категория', aIniValue)
   IF Len(A)=0
      Messagebox("Выполнение программы прервано пользователем.")
      RETURN .F.
   ELSE
      IF !EMPTY(a[1])
        if Upper(AllTrim(a[1])) == Upper('Закупка')
          cTiCtg := "1"
        else
          cTiCtg := "2"
        endif
      ENDIF
   ENDIF
  endif

  if Empty(cMoveTp) .Or. ValType(cMoveTp) != "C" .Or. !(cMoveTp $ "ЗК,БП,ПР,ОТ,ПП")
    if cTiCtg == "1"
      aAns:={'Закупка ТМЦ default','Безвоздмездное получение','Предоплата'}
    else
      aAns:={'Отгрузка default','Безвозмездная передача','Предоплата','Поступление прочих денежных средств'}
    endif
    aIniValue := {{'Вид движения счета-фактуры',aAns}}

   a := DialogGr('Вид движения счета-фактуры', aIniValue)
   IF Len(A)=0
      Messagebox("Выполнение программы прервано пользователем.")
      RETURN .T.
   ELSE
      IF !EMPTY(a[1])
        cMoveTp := Upper(AllTrim(a[1]))
        do case
          case cMoveTp  == Upper('Закупка ТМЦ')
            cMoveTp := "ЗК"
          case cMoveTp  == Upper('Безвоздмездное получение')
            cMoveTp := "БП"
          case cMoveTp  == Upper('Предоплата')
            cMoveTp := "ПР"
          case cMoveTp  == Upper('Отгрузка')
            cMoveTp := "ОТ"
          case cMoveTp  == Upper('Поступление прочих денежных средств')
            cMoveTp := "ПП"
        endcase
      ENDIF
   ENDIF

    //Запросить вид двидения
  endif
  if cMoveTp $ "ОТ,БП,ЗК"
    if !CheckStr(astr)
      Return .F.
    endif
  endif

  If !CreateSfFromXml(cTiCtg,cMoveTp,cValId,;
                      idOtprav,IdGrOtprav,idPoluch,idGrPoluch,;
                      IsKor,IsDef,cDocNum,dDocDate,;
                      cDocNumKor,dDocDateKor,cDocNumDef,dDocDateDef,;
                      cDocNumKorSfDef,,cDateNumKorSfDef,;
                      cSfId,cSfDefId,IsBest5,;
                      cKOP_NDS,cKOP_AST,cKOP_NNDS,cKOP_NDS0,cKOP_AG_NDS,;
                      dCUST_DATE,dCONF_DATE,cCompl_M,;
                      astr)
    Return .F.
  endif

return .T.

Function conversionDateFromXml(cDate)
local a,s
  if len(cDate) != 10
    Return .F.
  endif
  a := StrSplit(cDate,".")
  if len(a) != 3
    Return .F.
  endif
  s := a[3]+a[2]+a[1]
  cDate := STOD(s)
  if Empty(cDate)
    Return .F.
  endif
return .T.

function CheckValutaFromXml(Value)
local lRet := .F.
  (DIC_VALUTA)->(DbGoTop())
  Do While !(DIC_VALUTA)->(Eof())
    if Value == Upper(AllTrim((DIC_VALUTA)->NCODE))
      Value := (DIC_VALUTA)->VAL_ID
      lRet := .T.
      exit
    endif
    (DIC_VALUTA)->(DbSkip(1))
  Enddo
return lRet

Function CheckPartnerForInn(INN,NotFiz,IdPartner)
  if NotFiz
    if !(DIC_PARTNER)->(DbSeek(" " + INN,.T.,"S_TAG_INN"))
      if !(DIC_PARTNER)->(DbSeek("2" + INN,.T.,"S_TAG_INN"))
        Return .F.
      endif
    endif
  else
    if !(DIC_PARTNER)->(DbSeek("1" + INN,.T.,"S_TAG_INN"))
      Return .F.
    endif
  endif
  IdPartner := (DIC_PARTNER)->PART_ID
Return .T.

function CheckTax(nTaxNdsRate,lNoNds,IdTaxNdsRate,lStA,dDocDate)
local cAl,lRet := .T., cAlTaxTp , aKey,i ,cKey
  begin sequence
  if ! _DbAreaOpen(B6_DBF_PATH + "SPR_NDS.dbf", @cAl,"TAG_NDS")
     Break(.F.)
  endif
  if ! _DbAreaOpen(B6_DBF_PATH + "TAX\TAX_TP.dbf", @cAlTaxTp,"TAG_CODE")
     Break(.F.)
  endif
  if lNoNds
    aKey := {"НДС"}
  else
    aKey := {"НДС","АКЦ"}
  endif
  for i := 1 to len(aKey)
    if !(cAlTaxTp)->(DbSeek(aKey[i]))
      Break(.F.)
    endif
    if lNoNds
      cKey := STR(0,19,5)+'1'+(cAlTaxTp)->TAX_ID
    else
      cKey := STR(nTaxNdsRate,19,5)+'0'+(cAlTaxTp)->TAX_ID
    endif
    (cAl)->(OrdScope(0,cKey))
    (cAl)->(OrdScope(1,cKey))
    (cAl)->(DbGoTop())
    Do while !(cAl)->(Eof())
      if dDocDate >= (cAl)->DATE_BEG
        if Empty((cAl)->DATE_END) .Or. dDocDate <= (cAl)->DATE_BEG
          IdTaxNdsRate := (cAl)->NNOPER
          lStA := (aKey[i] == "АКЦ")
        endif
      endif
      (cAl)->(DbSkip(1))
    enddo
    if !Empty(IdTaxNdsRate)
      exit
    endif
  next
  if Empty(IdTaxNdsRate)
    Break(.F.)
  endif
  recover
    lRet := .F.
  end sequence
  _DbAreaClose(cAl)
  _DbAreaClose(cAlTaxTp)
return lRet

function CheckRateA(nCostNotTax,nASum,nTaxARate,IdTaxARate,dDocDate)
local nRate := Round(100*nASum/(nCostNotTax - nASum),5)
local lStA
  if !CheckTax(nRate,.F.,@IdTaxARate,@lStA,dDocDate)
    return .F.
  else
    if !lStA
      return .F.
    endif
    nTaxARate := nRate
  endif
return .T.

function CheckStr(astr)
Local i , value ,aAns,aIniValue,a
local tbName , tagName , group, nnum,name,cAl , lAdd := .F.
local cMsg , aEd := {}
  for i := 1 to len(astr)
    if Empty(astr[i][_NAME_TOV_])
      Messagebox("Не указано наименование товара.")
      RETURN .F.
    endif
    value := astr[i][_STR_TP_]
    if ValType(value) != "C" .Or. Empty(value) .Or. !(value $ "2,3,4,5,6,7")
        aAns:={'Товары default','Запасы','Услуги','Имущество'}
        aIniValue := {{"Категория для товара: " +  astr[i][_NAME_TOV_] ,aAns}}
        a := DialogGr('Укажите категория', aIniValue)
        IF Len(A)=0
          Messagebox("Выполнение программы прервано пользователем.")
          RETURN .F.
        endif
        IF !EMPTY(a[1])
          value := Upper(AllTrim(a[1]))
          do case
            case value  == Upper('Товары')
              value := "2"
            case value  == Upper('Запасы')
              value := "3"
            case value  == Upper('Услуги')
              value := "4"
            case value  == Upper('Имущество')
              value := "5"
          endcase
          astr[i][_STR_TP_] := value
        ENDIF
    endif
    lAdd := .F.

    tbName := B6_DBF_PATH
    value := astr[i][_STR_TP_]
    group := astr[i][_GROUP_]
    nnum :=  PADR(astr[i][_NOM_NUM_],13)
    name := astr[i][_NAME_TOV_]
    do case
      case value == "2"
        tbName +="Sclad\MLabel.dbf"
        tagName := "MLabel"
        group := PADR(group,5)
        name := left(name,30)
      case value == "3"
        tbName +="Zapas\MLabel.dbf"
        tagName := "MLabel"
        group := PADR(group,5)
        name := left(name,30)
      case value == "4"
        tbName +="TOVAR\MLabel.dbf"
        tagName := "MLabel"
        group := PADR(group,5)
        name := left(name,30)
      case value == "5"
        tbName +="Assets\res_lbl.dbf"
        tagName := "TAG_CODE"
        group := PADR(group,6)
    endcase
    if ! _DbAreaOpen(tbName, @cAl,tagName)
      RETURN .F.
    endif
    if Empty(group) .Or. Empty(nnum)
      lAdd := .T.
    else
      If !(cAl)->(DbSeek(Upper(group + nnum )))
        lAdd := .T.
      else
        if astr[i][_NAME_TOV_] != Upper(AllTrim((cAl)->Name))
          cMsg := " У товара: " + astr[i][_NAME_TOV_]   + CRLF
          cMsg += "группа и номенклатурный номер" + CRLF
          cMsg += "не соответствуют переданным в параметрах." + CRLF
          cMsg += "Изменить название товара на соответствующее параметрам?"
          if (6 != messagebox(cMsg,TITLEAPP,68))
            lAdd := .T.
          Endif
        endif
      endif
    endif
    if lAdd
      If !(cAl)->(DbSeek(Upper(name),.T.,"TAG_NAME"))
        Messagebox("Не найдено соответствие товара из счета-фактуры в номенклатурном справочнике.")
        _DbAreaClose(cAl)
        RETURN .F.
      else
        if value == "5"
          astr[i][_GROUP_] := (cAl)->GROUP
          astr[i][_NOM_NUM_] := (cAl)->NNUM
        else
          astr[i][_GROUP_] := (cAl)->GRUP
          astr[i][_NOM_NUM_] := (cAl)->NNUM
        endif
      endif
    endif
    if value == "5"
      aEd := {Upper(AllTrim((cAl)->UNIT))}
    elseif value == "4"
      aEd := {Upper(AllTrim((cAl)->ED))}
    else
      aEd := {Upper(AllTrim((cAl)->ED))}
      if !Empty((cAl)->ED1)
        AADD(aEd,Upper(AllTrim((cAl)->ED1)))
      endif
      if !Empty((cAl)->ED2)
        AADD(aEd,Upper(AllTrim((cAl)->ED2)))
      endif
      if !Empty((cAl)->ED3)
        AADD(aEd,Upper(AllTrim((cAl)->ED3)))
      endif

    endif
    _DbAreaClose(cAl)
    if Empty(astr[i][_OKEY_])
      if len(aEd) = 1
        cMsg := " У товара: " + astr[i][_NAME_TOV_]  + CRLF
        cMsg += "не определена еденица измерения." + CRLF
        cMsg += "Изменить на основную из номенклатурного справочника?"
        if (6 != messagebox(cMsg,TITLEAPP,68))
          Messagebox("Выполнение программы прервано пользователем.")
          RETURN .F.
        Endif
        astr[i][_OKEY_] := aEd[1]
      else
        aAns := array(len(aEd) )
        for i := 1 to len(aEd)
          aAns[i] := aEd[i]
          if i == 1
            aAns[i] += "default"
          endif
        next
        aIniValue := {{"Единица измерения для товара: " +  astr[i][_NAME_TOV_] ,aAns}}
        a := DialogGr('Укажите единицу измерения', aIniValue)
        IF Len(A)=0
          Messagebox("Выполнение программы прервано пользователем.")
          RETURN .F.
        endif
        IF !EMPTY(a[1])
          astr[i][_OKEY_] := Upper(AllTrim(a[1]))
        ENDIF
      endif
    endif

  next
return .T.
*/

function CheckUnitFromXml(Value)
local lRet := .F. , cEd := ""
  if LookUpSeek("UNITS","OKEI",@lRet,Value,"ED",@cEd)
    if lRet
      cEd := AllTrim(cEd)
      if RAT(";",cEd ) == len(cEd)
        cEd := Left(cEd,len(cEd)-1)
      endif
      Value := cEd
      Return .T.
    endif
  endif
  Value := ""
return .T.

function CreateSfFromXml(cTiCtg,cMoveTp,cValId,;
                         idOtprav,IdGrOtprav,idPoluch,idGrPoluch,;
                         IsKor,IsDef,cDocNum,dDocDate,;
                         cDocNumKor,dDocDateKor,cDocNumDef,dDocDateDef,;
                         cDocNumKorSfDef,cDateNumKorSfDef,;
                         cSfId,cSfDefId,IsBest5,;
                         cKOP_NDS,cKOP_AST,cKOP_NNDS,cKOP_NDS0,cKOP_AG_NDS,;
                         dCUST_DATE,dCONF_DATE,cCompl_M,;
                         cDocDopNum,cDocDopNumKor,cDocDopNumDef,cDocDopNumKorSfDef,cSchet,;
                         astr,aMssg)
local aParamIni, lRet := .T.,n
local cCurId,nMulty,nRound,cCurCod,nRate,cMsg
local lAv := cMoveTp $ "ПП,ПР",oObjSf,oObjBook, cAl, cStrTp
local aMod ,oStr, oSum, idNds := "", idA := "",aParam
local cEntId, cEntAddrId,cPrtId, cPatAddrId
local RetValue , lRetSf := .F.,cDocId := "",a
// параметры пока не обрабатываются
//что бы не было предупреждений
CDOCNUMKOR := CDOCNUMKOR
DDOCDATEKOR := DDOCDATEKOR
CDOCNUMDEF := CDOCNUMDEF
DDOCDATEDEF := DDOCDATEDEF
CDOCNUMKORSFDEF := CDOCNUMKORSFDEF
CDATENUMKORSFDEF := CDATENUMKORSFDEF
CSFDEFID := CSFDEFID
ISBEST5 := ISBEST5
CDOCDOPNUMKOR := CDOCDOPNUMKOR
CDOCDOPNUMDEF := CDOCDOPNUMDEF
CDOCDOPNUMKORSFDEF := CDOCDOPNUMKORSFDEF

begin sequence
  if cTiCtg == "1"
    cEntId := idPoluch
    cEntAddrId := idGrPoluch
    cPrtId := idOtprav
    cPatAddrId := IdGrOtprav
  else
    cEntId := idOtprav
    cEntAddrId := IdGrOtprav
    cPrtId := idPoluch
    cPatAddrId := idGrPoluch
  endif
  aParamIni := {}
  if !GetParamIni(cTiCtg,lAv,@aParamIni)
    AADD(aMssg,"Не удалось инициализировать параметры настройки для Счетов-Фактур!")
    break(.F.)
  endif
  if Empty(aParamIni[10])
     AADD(aMssg,"Приложение книга покупок-продаж." + CRLF + "Не определена дата начала расчетного периода.")
     Break(.F.)
   endif
  cCurId := ""
  nMulty := 1
  nRound := 2
  cCurCod := ""
  nRate := 1
  if !GetCurrParam(@cCurId,@nMulty,@nRound,@cCurCod,.T.)
    AADD(aMssg,"Не удалось получить параметры для основной валюты.")
    break(.F.)
  endif
  if cCurId != cValId
    AADD(aMssg,"Валюта счета-фактуры не является основной валютой.")
    break(.F.)
  endif

  // Проверка параметров из настройки подсистемы
  cMsg := ""
  cMsg := "В настройке подсистемы Книга Покупок/Продаж " + CRLF
  cMsg := cMsg + " не определено: " + CRLF
  lRet := .F.
  for n := 4 to len(aParamIni)
    if n $ {4,5,6,8}
      if Empty(aParamIni[n])
         do case
           case n == 4
             cMsg := cMsg + " Налоговая модель " + CRLF
             lRet := .T.
           case n == 5
             cMsg := cMsg + " Собственное предприятие " + CRLF
             lRet := .T.
           case n == 6
             cMsg := cMsg + " Собственное предприятие как грузополучатель " + CRLF
             lRet := .T.
           case n == 8
             cMsg := cMsg + " Тип документа для Счета-Фактуры  " + CRLF
            lRet := .T.
         endcase
      endif
    endif
  next
  if lRet
    AADD(aMssg,cMsg)
    Break(.F.)
  endif
  lRet := .T.

  oObjSf := clsTax_Inv():New()
  oObjSf:Open()
  cAl := oObjSf:cWa
  if !Empty(cSfId) .And. (cAl)->(DbSeek(cSfId,.T., "TAG_ID"))
    aMssg := {}
    AADD(aMssg,"Счет-фактура с данным идентификатором уже импортирован")
    Break(.F.)
  endif
  oObjSf:BeforeAppend( cTiCtg,cMoveTp,   ,aParamIni[8],cEntId,cEntAddrId,,,dDocDate,IsKor,IsDef )
  if !oObjSf:Append()
    Break(.F.)
  endif
  cAl := oObjSf:cWa
  if (cAl)->(DbRLock( (cAl)->(RecNo()) ) )
    if !Empty(cSfId)
      (cAl)->DOC_ID := cSfId
    endif  
    (cAl)->DOC_NUM := cDocNum
    (cAl)->DNUM := cDocDopNum
    (cAl)->PRT_ID := cPrtId
    (cAl)->ENT_LOC := cEntAddrId
    (cAl)->PRT_LOC := cPatAddrId
    if !Empty(cKOP_NDS)
      (cAl)->KOP_NDS := cKOP_NDS
    endif
    if !Empty(cKOP_AST)
      (cAl)->KOP_AST := cKOP_AST
    endif
    if !Empty(cKOP_NNDS)
      (cAl)->KOP_NNDS := cKOP_NNDS
    endif
    if !Empty(cKOP_NDS0)
      (cAl)->KOP_NDS0 := cKOP_NDS0
    endif
    if !Empty(cKOP_AG_NDS)
      (cAl)->KOP_AG_NDS := cKOP_AG_NDS
    endif
    if !Empty(dCUST_DATE)
      (cAl)->CUST_DATE := dCUST_DATE
    endif
    if !Empty(dCONF_DATE)
      (cAl)->CONF_DATE := dCONF_DATE
    endif
    if !Empty(cCompl_M)
      (cAl)->Compl_M := cCompl_M
    endif
    if !Empty(cSchet)
      oObjSf:ACNT_ID := cSchet
    endif

    (cAl)->(DbRUnLock((cAl)->(RecNo()) ))
  endif
  cDocId := (cAl)->DOC_ID

  aMod := oObjSf:TAX_STR:TAXSTRSUM:maModStr
  for n := 1 to len(aMod)
    if AllTrim(aMod[n][_SYSNUM]) == "1"
      idA := aMod[n][_TAXID]
    elseif  AllTrim(aMod[n][_SYSNUM]) == "2"
      idNds := aMod[n][_TAXID]
    endif
  next

  for n := 1 to len(astr)
    cStrTp := astr[n][_STR_TP_]
    if !oObjSf:TAX_STR:BeforAppend(cStrTp,.F.)
      Break(.F.)
    endif
    if !oObjSf:TAX_STR:Append()
      Break(.F.)
    endif
    oStr := oObjSf:TAX_STR
    if cStrTp $ "2,3,4,5"
      oStr:DS:FieldValue("GROUP_CODE",astr[n][_GROUP_])
      oStr:DS:FieldValue("NNUM",astr[n][_NOM_NUM_])
      oStr:DS:FieldValue("NNAME",astr[n][_NAME_TOV_])
      oStr:DS:FieldValue("PRT_CODE",astr[n][_PART_])
      oStr:DS:FieldValue("QNTY",astr[n][_QUANTITY_])
      oStr:DS:FieldValue("GTD",astr[n][_GTD_])
      oStr:DS:FieldValue("COUNTRY",astr[n][_COUNTRY_])
    endif
    oStr:UNIT := astr[n][_OKEY_]
    oSum := oObjSf:TAX_STR:TAXSTRSUM
    oSum:GoTop()
    do while !oSum:Eof()
      if oSum:TAX_ID == idA
        oSum:DS:FieldValue("TAX_IDRT",astr[n][_ID_A_RATE])
        oSum:DS:FieldValue("TAX_RATE",astr[n][_A_RATE_])
      elseif  oSum:TAX_ID == idNds
        oSum:DS:FieldValue("TAX_IDRT",astr[n][_ID_NDS_RATE_])
        oSum:DS:FieldValue("TAX_RATE",astr[n][_NDS_RATE_])
      endif
      oSum:Skip(1)
    enddo
    if aMod[1][_SUMUSE] == "2"
      oStr:SUM_A := astr[n][_COST_ALL_]
    else
      oStr:SUM_NNDS := astr[n][_COST_NOT_TAX]
    endif

    oSum:GoTop()
    do while !oSum:Eof()
      oSum:DS:FieldValue("IS_HAND",.F.)
      oSum:Skip(1)
    enddo
    oStr:DS:FieldValue("IS_HANDN",.F.)
    oStr:DS:FieldValue("IS_HANDA",.F.)

  next
  oObjSf:CreateTaxForSF()
  oStr:GoTop()

  oObjSf:mlFromDoc := .T.
  oObjSf:lMsgErrShow := .F.
  if !oObjSf:Save()
    a := oObjSf:aMsqNotSave
    if GetTaxParamIni("SHOW_SF",@lRet)
      if lRet
        Msg_s():arrShow(a,.T.)
        oObjSf:lMsgErrShow := .T.
        aParam := Array(10)
        aParam[1] := 2
        aParam[2] := oObjSf:DOC_ID
        aParam[3] := .F.
        aParam[4] := cTiCtg
        aParam[5] := cMoveTp
        aParam[6] := ""
        aParam[7] := ""
        aParam[8] := oObjSf
        aParam[9] := 1
        aParam[10] := .T.
        RunForm('tax\frmTaxInv',.T.,aParam,,.T.)
      else
        oObjSf:Cancel()
      endif
    endif

  endif
  if Empty(cDocId)
    Break (.F.)
  else
    //не записали в базу
    RetValue := {}
    if !LookUpSeek("Tax\Tax_Inv.dbf","TAG_ID",@lRetSf,cDocId,{"DOC_DATE","SUM_BOOK"},@RetValue)
      Break (.F.)
    else
      if !lRetSf
        if len(a) > 0
          aMssg := {}
          for n := 1 to len(a)
            AADD(aMssg,a[n] + Chr(13) +chr(10) )
          next
        endif
        Break(.F.)
      endif
    endif
  endif
  if GetTaxParamIni("IMP_BOOK",@lRet)
    if lRet

       //Проверим сохранили или нет с-ф
      //if LookUpSeek("Tax\Tax_Inv.dbf","TAG_ID",@lRetSf,cDocId,{"DOC_DATE","SUM_BOOK"},@RetValue) .And. lRetSf
      //зарегистрируем с-ф

       if RetValue[2] == 0
         oObjBook := clsTax_Book():New()
         oObjBook:Open()
         if cMoveTp $ {"ПП","ПР"}
           if cMoveTp == "ПР"
              if  cTiCtg == "1"
                aParam := {0,cTiCtg,"АУ"}
              else
                aParam := {0,cTiCtg,"АВ"}
              endif
           else
             aParam := {0,cTiCtg,"ПЛ"}
           endif
         else
           if cTiCtg == "1"
             aParam := {0,"1","ОП"}
           else
             aParam := {0,"2","ОТ"}
           endif
         endif
         if !oObjBook:BeforeAppend(aParam)
           Break(.F.)
         endif
         if !oObjBook:Append()
           Break(.F.)
         endif
         oObjBook:SF_ID := cDocId
         oObjBook:SRC_DATE := RetValue[1]
         oObjBook:SRC_SUM :=  oObjBook:SF_RST
         if !oObjBook:save()
           if !StartFrmBook(oObjBook)
             //
             Break(nil)
           endif
         endif
       endif

      //endif
    endif
  endif

recover
    lRet := .F.
  end sequence

  if ValType(oObjSf) == "O"

    if __ObjHasMethod(oObjSf,"Destroy")
      oObjSf:Destroy()
    endif
  endif
  oObjSf := nil
  if ValType(oObjBook) == "O"

    if __ObjHasMethod(oObjBook,"Destroy")
      oObjBook:Destroy()
    endif
  endif
  oObjBook := nil

return lRetSf

Function CreateSfFromCsv(cPath,aFileCsv,CALKB)
local cFile, i ,nHandle := -1 , s := "",nSize , j,n , a := {}
local cErrorFile, lVIEW := .F. ,nErrorTmp , cPrintFile := ""
local aParamIni,asf,aMssg , imp := 0, all := 0
  if !CheckParamSfIni("2",.F.,@aParamIni)
    Return .F.
  endif
  cErrorFile := TEMPFILE( PublicVars():GlobalTmpPath, "txt" )
  If ( nErrorTmp := FCREATE(cErrorFile) ) == -1
     messagebox( "Ошибка создания временного файла" )
     Return .T.
  Endif
  for i := 1 to len(aFileCsv)
    cFile := cPath + aFileCsv[i]
    if File(cFile)
      nHandle = FOPEN(cFile,10)
      IF nHandle < 0
        //не удалось открыть файл
        loop
      Endif
      nSize =  FSEEK(nHandle, 0, 2)
      IF nSize > 0
        s := SPACE(nSize)
        FSEEK(nHandle, 0, 0)
        FREAD(nHandle, @s, nSize)
      ENDIF
      FCLOSE(nHandle)
      a := StrSplit(s,Chr(13))
      if len(a) > 0
        (cAlKb)->(DbGoTop())
        IF !EvalStr(cAlKb + "->PrgImport",,,cAlKb + "->HrbImport",.T.)
          messagebox("Ошибка выполнения программы импорта",TITLEAPP,48)
        ENDIF
      endif
      for j := 1 to len(a)
        asf :=  StrSplit(a[j],";")
        if len(asf) = 9
          all ++
          aMssg := {}
          if !CreateSfFromStr(asf,aParamIni,@aMssg,@imp)
            if ValType(aMssg) == "A" .And. Len(aMssg) > 0
              if cPrintFile !=  cFile
                cPrintFile :=  cFile
                FWRITE(nErrorTmp,chr(13) + chr(10) + "Для файла иморта " + cPrintFile )
              endif
              FWRITE(nErrorTmp,chr(13) + chr(10) + "Не правильные данные для импорта:"+ chr(13) + chr(10))
              FWRITE(nErrorTmp,a[j] + chr(13) + chr(10))
              for n := 1 to len(aMssg)
                FWRITE(nErrorTmp,aMssg[n]+ chr(13) + chr(10))
                lVIEW := .T.
              next
            endif
          endif
        else
          if len(asf) > 1 .Or. !Empty(asf[1])
            if cPrintFile !=  cFile
              cPrintFile :=  cFile
              FWRITE(nErrorTmp,chr(13) + chr(10) + "Для файла иморта " + cPrintFile )
            endif
          //не верная структура строки для импорта с-ф
            FWRITE(nErrorTmp,"Не правильная структура для импорта:"+ chr(13) + chr(10))
            FWRITE(nErrorTmp,a[j] + chr(13) + chr(10))
            lVIEW := .T.
          endif
        endif
      next
    endif
  next
  if !Empty(all)
    if all > imp   //64
      messagebox("Из "  + AllTrim(Str(all,5,0)) +  " импортировано " + AllTrim(Str(imp,5,0)) + " счетов-фактур",TITLEAPP,64 )
    else
      messagebox("Импортировано " + AllTrim(Str(all,5,0)) + " счетов-фактур",TITLEAPP,64 )
    endif
  endif
  If lVIEW
    FCLOSE(nErrorTmp )
    VIEW  (cErrorFile)
  Endif
  IF !EMPTY(cErrorFile).AND.FILE(cErrorFile)
     FCLOSE(nErrorTmp )
     FERASE(cErrorFile)
  ENDIF
Return .T.
/*
Function CheckParamFromCsv(asf,aParamIni,oObjSf,aMsg,aNds,aNom)
Local lRet := .T. , cAl, RetValue, cDate,cKey

begin sequence
  If Empty(asf[1])
    AADD(aMsg,"Не определен номер.")
  endif
  If !Empty(STOD(asf[2]))
    cDate := left(asf[2],4)
    asf[2] := STOD(asf[2])
  else
      AADD(aMsg,"Не определена дата.")
  endif
  if LookUpSeek("Partner","FULLCODE",@lRet,asf[3],"Part_ID",@RetValue) .And. lRet
     asf[3] := RetValue
  else
    AADD(aMsg,"Не определен покупатель.")
  endif
  if LookUpSeek("Partner","FULLCODE",@lRet,asf[4],"Part_ID",@RetValue) .And. lRet
     asf[4] := RetValue
  else
    AADD(aMsg,"Не определен продавец.")
  endif
  cAl := oObjSf:cWa
  cKey := Upper(aParamIni[8] + cDate + asf[1])
  if (cAl)->(DbSeek(cKey,.T., "TAG_NUM"))
    AADD(aMsg,"Счет-фактура с данным номером уже импортирован.")
  endif
  if LookUpSeek("TOVAR\MGRUP.dbf","MGRUP",@lRet,Upper(asf[5]),"{OPER_NDS,NDS}",@RetValue) .And. lRet
     if Empty(RetValue[1]) .Or. Empty(RetValue[2])
       AADD(aMsg,"В группе услуг " + asf[5] + " не определена ставка НДС." )
     else
       aNds := {RetValue[1],RetValue[2]}
     endif
  else
    AADD(aMsg,"Не определена группа услуг.")
  endif
  if LookUpSeek("TOVAR\MLabel.dbf","MLabel",@lRet,Upper(asf[5]+asf[6]),"{ED,NAME}",@RetValue) .And. lRet
     aNom := {RetValue[1],RetValue[2]}
  else
    AADD(aMsg,"Не определена номенклатура услуг.")
  endif

recover
 lRet := .F.
end sequence
  if len(aMsg) > 0
    lRet := .F.
  endif
Return lRet
*/
function CheckParamSfIni(cTiCtg,lAv,aParam)
local aParamIni, lRet := .F.,cMsg , n
  aParamIni := {}
  if !GetParamIni(cTiCtg,lAv,@aParamIni)
    messagebox("Не удалось инициализировать параметры настройки для Счетов-Фактур!",TITLEAPP,48)
    Return .F.
  endif
  if Empty(aParamIni[10])
     messagebox("Приложение книга покупок-продаж." + CRLF + "Не определена дата начала расчетного периода.","БЭСТ-5",48)
     Return .F.
   endif
   // Проверка параметров из настройки подсистемы
  cMsg := ""
  cMsg := "В настройке подсистемы Книга Покупок/Продаж " + CRLF
  cMsg := cMsg + " не определено: " + CRLF
  lRet := .F.
  for n := 4 to len(aParamIni)
    if n $ {4,5,6,8}
      if Empty(aParamIni[n])
         do case
           case n == 4
             cMsg := cMsg + " Налоговая модель " + CRLF
             lRet := .T.
           case n == 5
             cMsg := cMsg + " Собственное предприятие " + CRLF
             lRet := .T.
           case n == 6
             cMsg := cMsg + " Собственное предприятие как грузополучатель " + CRLF
             lRet := .T.
           case n == 8
             cMsg := cMsg + " Тип документа для Счета-Фактуры  " + CRLF
            lRet := .T.
         endcase
      endif
    endif
  next
  if lRet
    messagebox(cMsg,TITLEAPP,48)
    Return .F.
  endif
  aParam := aParamIni
Return .T.
 /*
function CreateSfFromStr(asf,aParamIni,aMssg)
local  lRet := .F., cKey := "", aNds,aNom,cStrTp
local oObjSf,oStr, oSum, aMod ,aParam ,cAl,n ,idA,idNds
local oObjBook , RetValue := {}
begin sequence

  oObjSf := clsTax_Inv():New()
  oObjSf:Open()
  if !CheckParamFromCsv(asf,aParamIni,oObjSf,@aMssg,@aNds,@aNom)
    Break(.F.)
  endif

  oObjSf:BeforeAppend( "2","ОТ",   ,aParamIni[8],asf[4],,,,asf[2] )
  if !oObjSf:Append()
    Break(.F.)
  endif
  cAl := oObjSf:cWa
  if (cAl)->(DbRLock( (cAl)->(RecNo()) ) )
    (cAl)->DOC_NUM := asf[1]
    (cAl)->PRT_ID := asf[3]
    (cAl)->DOC_DATE := asf[2]
    oObjSf:REG_DATE := asf[2]
    (cAl)->(DbRUnLock((cAl)->(RecNo()) ))
  endif

  aMod := oObjSf:TAX_STR:TAXSTRSUM:maModStr
  for n := 1 to len(aMod)
    if AllTrim(aMod[n][_SYSNUM]) == "1"
      idA := aMod[n][_TAXID]
    elseif  AllTrim(aMod[n][_SYSNUM]) == "2"
      idNds := aMod[n][_TAXID]
    endif
  next

  cStrTp := "4"
  if !oObjSf:TAX_STR:BeforAppend(cStrTp,.F.)
    Break(.F.)
  endif
  if !oObjSf:TAX_STR:Append()
    Break(.F.)
  endif
  oStr := oObjSf:TAX_STR
  oStr:DS:FieldValue("GROUP_CODE",asf[5])
  oStr:DS:FieldValue("NNUM",asf[6])
  oStr:DS:FieldValue("NNAME",aNom[2])
  oStr:DS:FieldValue("QNTY",val(asf[7]))
  oStr:UNIT := aNom[1]
  oSum := oObjSf:TAX_STR:TAXSTRSUM
  oSum:GoTop()
  do while !oSum:Eof()
    if oSum:TAX_ID == idA
        oSum:DS:FieldValue("TAX_IDRT","")
        oSum:DS:FieldValue("TAX_RATE",0)
    elseif  oSum:TAX_ID == idNds
        oSum:DS:FieldValue("TAX_IDRT",aNds[1])
        oSum:DS:FieldValue("TAX_RATE",aNds[2])
    endif
    oSum:Skip(1)
  enddo
  if aMod[1][_SUMUSE] == "2"
    oStr:SUM_A := Val(asf[8]) + Val(asf[9])
  else
    oStr:SUM_NNDS := Val(asf[8])
  endif

  oSum:GoTop()
  do while !oSum:Eof()
    oSum:DS:FieldValue("IS_HAND",.F.)
    oSum:Skip(1)
  enddo
  oStr:DS:FieldValue("IS_HANDN",.F.)
  oStr:DS:FieldValue("IS_HANDA",.F.)


  oObjSf:CreateTaxForSF()
  oStr:GoTop()

  oObjSf:mlFromDoc := .T.
  aParam := Array(10)
  aParam[1] := 2
  aParam[2] := oObjSf:DOC_ID
  aParam[3] := .F.
  aParam[4] := "2"
  aParam[5] := "ОТ"
  aParam[6] := ""
  aParam[7] := ""
  aParam[8] := oObjSf
  aParam[9] := 1
  aParam[10] := .T.
  if !oObjSf:save()
    RunForm('tax\frmTaxInv',.T.,aParam,,.T.)
  endif
  //Проверим сохранили или нет с-ф
  if LookUpSeek("Tax\Tax_Inv.dbf","TAG_ID",@lRet,aParam[2],{"DOC_DATE","SUM_BOOK"},@RetValue) .And. lRet
  //зарегистрируем с-ф
    if RetValue[2] == 0
      oObjBook := clsTax_Book():New()
      oObjBook:Open()
      if !oObjBook:BeforeAppend({0,"2","ОТ"})
        Break(.F.)
      endif
      if !oObjBook:Append()
        Break(.F.)
      endif
      oObjBook:SF_ID := aParam[2]  //SRC_SUM  SRC_DATE
      oObjBook:SRC_DATE := RetValue[1]
      oObjBook:SRC_SUM :=  oObjBook:SF_RST
      if !oObjBook:save()
        if !StartFrmBook(oObjBook)
          //
          Break(nil)
        endif
      endif
    endif

  endif
recover
    lRet := .F.
  end sequence

  if ValType(oObjSf) == "O"

    if __ObjHasMethod(oObjSf,"Destroy")
      oObjSf:Destroy()
    endif
  endif
  oObjSf := nil

  if ValType(oObjBook) == "O"

    if __ObjHasMethod(oObjBook,"Destroy")
      oObjBook:Destroy()
    endif
  endif
  oObjBook := nil
return lRet
*/

 /*
#define _TAXID     1
#define _CALCRL    2
#define _MODBS     3
#define _STRID     4
#define _RTDEF     5
#define _RTRATE    6
#define _SYSNUM    7
#define _PRIOR_    8
#define _OUTF      9
#define _INF       10
#define _TAXCODE_  11
#define _PRICEIN   12
#define _SUMUSE    13

#define _NOMSTR_      1
#define _NAME_TOV_    2
#define _OKEY_        3
#define _QUANTITY_    4
#define _PRICE_       5
#define _COST_NOT_TAX 6
#define _COST_ALL_    7
#define _LNDS_        8
#define _NDS_RATE_    9
#define _ID_NDS_RATE_ 10
#define _LA_          11
#define _A_RATE_      12
#define _ID_A_RATE    13
#define _NDS_SUM_     14
#define _A_SUM_       15
#define _COUNTRY_     16
#define _GTD_         17
#define _SF_STR_ID_   18
#define _STR_TP_      19
#define _GROUP_       20
#define _NOM_NUM_     21
#define _PART_        22
#define _STR_FROM_    23
#define _COMMENT_     24
*/

//Function GetPartnerForOrgName(cGrOtpravName,IdGrOtprav)
//Return .T.

/*
Function
local oErr
 begin sequence

 recover using oErr
  if valtype(oErr) == "L"
     return oErr
   else
     return .F.
  endif
 end sequence
Return .T.
*/